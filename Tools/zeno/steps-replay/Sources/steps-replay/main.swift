import Foundation
import SQLite3
import StrandAnalytics
import WhoopProtocol

// steps-replay: replay ZENO's hour-by-hour step merge (StepsHourMerge) over a COPY of the app's database, with
// no phone, strap or app involved. It prints four reports:
//
//   1. How the strap stores motion: rows per recorded hour, seconds covered, walking minutes, the usual gap.
//   2. Calibration: the carried hours and the pace (steps per walking minute) learned from them.
//   3. The merge day by day: what each day shows without it, what the strap adds, and in which hours.
//   4. A hide-the-phone test: hide the phone's count for each carried hour in turn, let the strap fill it with a
//      pace learned without that day, and compare with what the phone counted.
//
// Usage: steps-replay <copy of whoop.sqlite> [--days 60] [--tz America/New_York]
//
// It uses the app's own StrandAnalytics functions for the walking detector, the calibration, the estimate and
// the merge rule, so its numbers are the app's. Open a copy: SQLite folds the -wal file into the database it
// opens.

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class SQLite {
    private var db: OpaquePointer?

    init(path: String) throws {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            throw Failure("Cannot open \(path): \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    deinit { sqlite3_close(db) }

    func query(_ sql: String, _ args: [Any] = []) throws -> [[Any?]] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw Failure("Query failed: \(String(cString: sqlite3_errmsg(db)))\n\(sql)")
        }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            let idx = Int32(i + 1)
            switch arg {
            case let v as Int: sqlite3_bind_int64(stmt, idx, Int64(v))
            case let v as Double: sqlite3_bind_double(stmt, idx, v)
            case let v as String: sqlite3_bind_text(stmt, idx, v, -1, sqliteTransient)
            default: sqlite3_bind_null(stmt, idx)
            }
        }
        var rows: [[Any?]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [Any?] = []
            for c in 0..<sqlite3_column_count(stmt) {
                switch sqlite3_column_type(stmt, c) {
                case SQLITE_INTEGER: row.append(Int(sqlite3_column_int64(stmt, c)))
                case SQLITE_FLOAT: row.append(sqlite3_column_double(stmt, c))
                case SQLITE_TEXT: row.append(String(cString: sqlite3_column_text(stmt, c)))
                default: row.append(nil)
                }
            }
            rows.append(row)
        }
        return rows
    }

    func hasColumn(_ table: String, _ column: String) -> Bool {
        ((try? query("PRAGMA table_info(\(table))")) ?? []).contains { ($0[1] as? String) == column }
    }
}

// MARK: - Arguments

var args = Array(CommandLine.arguments.dropFirst())
func option(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    let value = args[i + 1]
    args.removeSubrange(i...(i + 1))
    return value
}
let windowDays = Int(option("--days") ?? "") ?? 60
let zone = option("--tz").flatMap(TimeZone.init(identifier:)) ?? .current
guard let dbPath = args.first else {
    print("Usage: steps-replay <copy of whoop.sqlite> [--days 60] [--tz America/New_York]")
    exit(2)
}

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = zone

func fmt(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = Locale(identifier: "en_US")
    return f.string(from: NSNumber(value: n)) ?? String(n)
}
func pct(_ x: Double) -> String { String(format: "%.0f%%", x * 100) }
func signedPct(_ x: Double) -> String { String(format: "%+.1f%%", x * 100) }
func pad(_ s: String, _ w: Int, left: Bool = false) -> String {
    let n = max(0, w - s.count)
    return left ? s + String(repeating: " ", count: n) : String(repeating: " ", count: n) + s
}
func median(_ xs: [Double]) -> Double? {
    guard !xs.isEmpty else { return nil }
    let s = xs.sorted()
    return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
}
func offset(at ts: Int) -> Int { zone.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(ts))) }
func dayKey(_ ts: Int) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: TimeInterval(ts)))
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
}

do {
    let db = try SQLite(path: dbPath)
    let phoneId = "iphone-pedometer", healthId = "apple-health"

    // "Now" is the newest thing the copy knows, so a database copied hours after its last sync replays as of then.
    let newestGravity = (try db.query("SELECT MAX(ts) FROM gravitySample").first?[0] as? Int) ?? 0
    let newestHour = (try db.query("SELECT MAX(ts) FROM appleStepHour WHERE deviceId IN (?, ?)",
                                   [phoneId, healthId]).first?[0] as? Int).map { $0 + 3_599 } ?? 0
    let now = max(newestGravity, newestHour)
    guard now > 0 else { throw Failure("The database has no gravity rows and no step hours.") }
    let todayStart = Int(calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(now))).timeIntervalSince1970)
    var days: [String] = []
    for i in stride(from: windowDays - 1, through: 0, by: -1) {
        guard let d = calendar.date(byAdding: .day, value: -i, to: Date(timeIntervalSince1970: TimeInterval(todayStart)))
        else { continue }
        days.append(dayKey(Int(d.timeIntervalSince1970)))
    }
    guard let firstDay = days.first, let windowStart = StepsHourly.dayBounds(day: firstDay, calendar: calendar)?.start
    else { throw Failure("Could not build the day window.") }

    // The strap: the device with the most gravity rows in the window.
    let owners = try db.query("""
        SELECT deviceId, COUNT(*) FROM gravitySample WHERE ts >= ? AND ts <= ? GROUP BY deviceId ORDER BY 2 DESC
        """, [windowStart, now])
    guard let owner = owners.first?[0] as? String else { throw Failure("No gravity rows in the last \(windowDays) days.") }

    print("ZENO steps replay · \(URL(fileURLWithPath: dbPath).lastPathComponent) · \(windowDays) days to \(dayKey(now)) · \(zone.identifier)")
    print("Strap motion from \(owner): \(fmt((owners.first?[1] as? Int) ?? 0)) rows"
        + (owners.count > 1 ? " (also: \(owners.dropFirst().compactMap { $0[0] as? String }.joined(separator: ", ")))" : ""))

    // MARK: 1. How the strap stores motion

    var walkByHour: [Int: StepsHourMerge.HourWalk] = [:]
    struct DayDensity { let day: String; let rows: Int; let hours: Int; let rowsPerHour: Int; let covered: Double; let walking: Int; let medianGap: Int }
    var density: [DayDensity] = []
    var strapDays: Set<String> = []
    for day in days {
        guard let b = StepsHourly.dayBounds(day: day, calendar: calendar) else { continue }
        let rows = try db.query("SELECT ts, x, y, z FROM gravitySample WHERE deviceId = ? AND ts >= ? AND ts < ? ORDER BY ts",
                                [owner, b.start, b.end])
        let grav = rows.compactMap { r -> GravitySample? in
            guard let ts = r[0] as? Int, let x = r[1] as? Double, let y = r[2] as? Double, let z = r[3] as? Double
            else { return nil }
            return GravitySample(ts: ts, x: x, y: y, z: z)
        }
        guard !grav.isEmpty else { continue }
        let heart = try db.query("SELECT ts, bpm FROM hrSample WHERE deviceId = ? AND ts >= ? AND ts < ?",
                                 [owner, b.start, b.end]).compactMap { r -> HRSample? in
            guard let ts = r[0] as? Int, let bpm = r[1] as? Int else { return nil }
            return HRSample(ts: ts, bpm: bpm)
        }
        let hours = StepsHourMerge.walkingByHour(grav, heartRate: heart, offsetSec: offset(at: b.start))
        for (h, w) in hours { walkByHour[h] = w }
        strapDays.insert(day)
        var gaps: [Double] = []
        for i in 1..<max(1, grav.count) { gaps.append(Double(grav[i].ts - grav[i - 1].ts)) }
        density.append(DayDensity(day: day, rows: grav.count, hours: hours.values.filter { $0.rows > 0 }.count,
                                  rowsPerHour: StepsHourMerge.usualRows(Array(hours.values)),
                                  covered: Double(grav.count) / Double(b.end - b.start),
                                  walking: hours.values.reduce(0) { $0 + $1.walkingMinutes },
                                  medianGap: Int(median(gaps) ?? 0)))
    }
    let usualRows = StepsHourMerge.usualRows(Array(walkByHour.values))
    let minRows = StepsHourMerge.minCarriedRows(usualRows: usualRows)
    print("\n1. How your strap stores motion")
    let verdict = usualRows >= 2_400 ? "dense: about one reading every second while worn"
        : (usualRows >= 600 ? "partly dense: readings in long stretches with gaps" : "sparse: short bursts, far from every second")
    print("   Usual recorded hour: \(fmt(usualRows)) rows (\(verdict))")
    print("   A carried hour needs at least \(fmt(minRows)) rows.")
    print("   " + pad("day", 10, left: true) + pad("rows", 9) + pad("hours", 7) + pad("rows/hour", 11)
        + pad("covered", 9) + pad("walking", 9) + pad("gap", 6))
    for d in density {
        print("   " + pad(d.day, 10, left: true) + pad(fmt(d.rows), 9) + pad(String(d.hours), 7)
            + pad(fmt(d.rowsPerHour), 11) + pad(pct(d.covered), 9) + pad("\(d.walking) min", 9) + pad("\(d.medianGap)s", 6))
    }

    // MARK: Inputs for the merge

    func hourRows(_ device: String) throws -> [(ts: Int, steps: Int)] {
        try db.query("SELECT ts, steps FROM appleStepHour WHERE deviceId = ? AND ts >= ? AND ts <= ? ORDER BY ts",
                     [device, windowStart, now]).compactMap { r in
            guard let ts = r[0] as? Int, let steps = r[1] as? Int else { return nil }
            return (ts: ts, steps: steps)
        }
    }
    let phoneRows = try hourRows(phoneId)
    let healthRows = try hourRows(healthId)
    var phoneByHour: [Int: Int] = [:]
    for r in phoneRows + healthRows {
        let h = StepsHourMerge.hourStart(r.ts, offsetSec: offset(at: r.ts))
        phoneByHour[h] = max(phoneByHour[h] ?? 0, r.steps)
    }
    let phoneByDay = StepsHourMerge.bucketsByDay(phoneRows, calendar: calendar)
    let healthByDay = StepsHourMerge.bucketsByDay(healthRows, calendar: calendar)

    var blocked: [(start: Int, end: Int)] = []
    let sleepStart = db.hasColumn("sleepSession", "startTsAdjusted") ? "COALESCE(startTsAdjusted, startTs)" : "startTs"
    for r in try db.query("SELECT \(sleepStart), endTs FROM sleepSession WHERE deviceId LIKE '%-noop' AND endTs >= ? AND startTs <= ?",
                          [windowStart, now]) {
        if let s = r[0] as? Int, let e = r[1] as? Int { blocked.append((start: s, end: e)) }
    }
    var noFootWorkouts = 0
    for r in try db.query("SELECT startTs, endTs, sport FROM workout WHERE endTs >= ? AND startTs <= ?", [windowStart, now]) {
        guard let s = r[0] as? Int, let e = r[1] as? Int, let sport = r[2] as? String,
              StepsHourMerge.isNoFootfallSport(sport) else { continue }
        blocked.append((start: s, end: e))
        noFootWorkouts += 1
    }
    var openByHour: [Int: Double] = [:]
    for h in walkByHour.keys { openByHour[h] = 1 - StepsHourMerge.coveredFraction(hourStart: h, intervals: blocked) }

    // The phone side has finished counting everything but the newest hour of the copy.
    let settledUntil = now - 3_600
    func carriedHours(excluding excludedDay: String? = nil) -> [(hour: Int, cal: StepsHourMerge.CalibrationHour)] {
        walkByHour.compactMap { h, w in
            guard h + 3_600 <= settledUntil, excludedDay == nil || dayKey(h) != excludedDay else { return nil }
            let p = phoneByHour[h] ?? 0
            guard StepsHourMerge.isCarried(phoneSteps: p, walk: w, minRows: minRows,
                                           blockedFraction: 1 - (openByHour[h] ?? 1)) else { return nil }
            return (hour: h, cal: StepsHourMerge.CalibrationHour(walkingMinutes: w.walkingMinutes, steps: Double(p)))
        }
    }

    // MARK: 2. Calibration

    let carried = carriedHours()
    let cal = StepsHourMerge.calibrate(carried.map(\.cal))
    print("\n2. Calibration")
    print("   Carried hours: \(carried.count) (phone at least \(StepsHourMerge.carriedMinSteps) steps, strap saw walking, awake)")
    print("   Sleep sessions and no-footfall workouts set aside: \(blocked.count - noFootWorkouts) and \(noFootWorkouts)")
    if let cal {
        print(String(format: "   Your pace: %.1f steps per walking minute, confidence %.2f", cal.stepsPerMinute, cal.confidence))
    } else {
        print("   Pace: not yet (needs \(StepsHourMerge.minCalibrationHours) carried hours and a walking pace). Nothing would be filled.")
    }

    // MARK: 3. Day by day

    var phoneDayTotal: [String: (steps: Int, source: String)] = [:]
    for r in try db.query("SELECT day, steps FROM appleDaily WHERE deviceId = ? AND steps > 0", [healthId]) {
        if let d = r[0] as? String, let s = r[1] as? Int { phoneDayTotal[d] = (s, "Apple Health") }
    }
    for r in try db.query("SELECT day, value FROM metricSeries WHERE deviceId = ? AND key = 'steps' AND value > 0", [phoneId]) {
        if let d = r[0] as? String, let v = r[1] as? Double, phoneDayTotal[d] == nil { phoneDayTotal[d] = (Int(v.rounded()), "iPhone") }
    }
    func strapBuckets(_ day: String, pace: Double) -> [Int] {
        guard let b = StepsHourly.dayBounds(day: day, calendar: calendar) else { return Array(repeating: 0, count: 24) }
        var rows: [(ts: Int, steps: Int)] = []
        var h = b.start
        while h < b.end {
            if let w = walkByHour[h] {
                rows.append((ts: h, steps: StepsHourMerge.estimate(walkingMinutes: w.walkingMinutes, stepsPerMinute: pace,
                                                                   openFraction: openByHour[h] ?? 1)))
            }
            h += 3_600
        }
        return StepsHourly.buckets(rows: rows, day: day, calendar: calendar)
    }
    func settled(_ day: String) -> Int {
        guard let start = StepsHourly.dayBounds(day: day, calendar: calendar)?.start else { return 0 }
        return StepsHourMerge.settledHours(dayStart: start, settledUntil: settledUntil)
    }

    print("\n3. Day by day (days your strap recorded)")
    if let cal {
        print("   " + pad("day", 10, left: true) + pad("today", 9) + "  " + pad("source", 13, left: true)
            + pad("strap adds", 11) + pad("new total", 11) + "  filled hours")
        var adds: [Double] = []
        for day in days where strapDays.contains(day) {
            let base = phoneDayTotal[day] ?? (steps: 0, source: "nothing")
            let added = StepsHourMerge.addedByHour(phone: phoneByDay[day], health: healthByDay[day],
                                                   band: strapBuckets(day, pace: cal.stepsPerMinute), settledHours: settled(day))
            let total = added.reduce(0, +)
            let hoursText = added.enumerated().filter { $0.element > 0 }
                .map { "\($0.offset)h +\(fmt($0.element))" }.joined(separator: ", ")
            print("   " + pad(day, 10, left: true) + pad(fmt(base.steps), 9) + "  " + pad(base.source, 13, left: true)
                + pad(total > 0 ? "+" + fmt(total) : "-", 11) + pad(fmt(base.steps + total), 11) + "  " + hoursText)
            adds.append(Double(total))
        }
        if let m = median(adds) { print("   The strap adds a median \(fmt(Int(m.rounded()))) steps a day.") }
    } else {
        print("   Skipped: no pace yet.")
    }

    // MARK: 4. Hide-the-phone test

    // Each carried hour in turn: hide the phone's count for it, refit the pace without that day, and let the strap
    // fill. The score is what the strap put back against what the phone had counted, as a share of that day.
    print("\n4. Hide-the-phone test (each carried hour hidden in turn)")
    var dayErrors: [Double] = [], noFill: [Double] = [], hourErrors: [Double] = []
    var lines: [String] = []
    for (h, _) in carried.sorted(by: { $0.hour < $1.hour }) {
        let day = dayKey(h)
        guard let pace = StepsHourMerge.pace(carriedHours(excluding: day).map(\.cal)),
              let start = StepsHourly.dayBounds(day: day, calendar: calendar)?.start else { continue }
        let index = (h - start) / 3_600
        guard (0..<24).contains(index) else { continue }
        var phone = phoneByDay[day] ?? Array(repeating: 0, count: 24)
        var health = healthByDay[day] ?? Array(repeating: 0, count: 24)
        let truth = (0..<24).reduce(0) { $0 + max(phone[$1], health[$1]) }
        let hidden = max(phone[index], health[index])
        guard truth > 0, hidden > 0 else { continue }
        phone[index] = 0; health[index] = 0
        let strap = strapBuckets(day, pace: pace)
        let putBack = StepsHourMerge.addedByHour(phone: phone, health: health, band: strap, settledHours: 24)[index]
        let err = Double(putBack - hidden) / Double(truth)
        dayErrors.append(err)
        noFill.append(Double(-hidden) / Double(truth))
        hourErrors.append(Double(strap[index] - hidden) / Double(hidden))
        lines.append("   " + pad(day, 10, left: true) + pad("\(index)h", 5) + pad(fmt(hidden), 8) + pad(fmt(putBack), 10)
            + pad(fmt(truth), 9) + pad(signedPct(err), 9))
    }
    if dayErrors.isEmpty {
        print("   No carried hours to test yet.")
    } else {
        print("   " + pad("day", 10, left: true) + pad("hour", 5) + pad("hidden", 8) + pad("put back", 10)
            + pad("day", 9) + pad("error", 9))
        lines.forEach { print($0) }
        let absDay = dayErrors.map { abs($0) }
        let within = Double(absDay.filter { $0 <= 0.10 }.count) / Double(absDay.count)
        print("\n   \(dayErrors.count) hours tested. With the strap filling the hidden hour, the day total:")
        print("     median miss \(pct(median(absDay) ?? 0)), lean \(signedPct(dayErrors.reduce(0, +) / Double(dayErrors.count))), within 10% on \(pct(within)) of tests")
        print("   Without it (what ZENO showed before when the phone missed that hour):")
        print("     median miss \(pct(median(noFill.map { abs($0) }) ?? 0)), lean \(signedPct(noFill.reduce(0, +) / Double(noFill.count)))")
        if let m = median(hourErrors.map { abs($0) }), let lean = median(hourErrors) {
            print("   The strap's estimate for the hidden hours themselves: median miss \(pct(m)), median lean \(signedPct(lean))")
        }
        print("   Targets from the plan: median miss within 10% of the day, lean within 5%.")
    }
} catch {
    FileHandle.standardError.write(Data("steps-replay: \(error)\n".utf8))
    exit(1)
}
