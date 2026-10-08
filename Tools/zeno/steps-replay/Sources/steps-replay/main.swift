import Foundation
import SQLite3
import StrandAnalytics
import WhoopProtocol

// steps-replay: replay ZENO's hour-by-hour step merge (StepsHourMerge) over a COPY of the app's database, with
// no phone, band or app involved. It prints three reports:
//
//   1. How the band stores motion: rows per recorded hour, seconds covered, how often the reading changes.
//   2. The merge day by day: what each day shows today, what the band would add, and in which hours.
//   3. A hide-the-phone test: on days the phone was carried, hide its count for one to three walking hours, let
//      the band fill them with a factor learned without that day, and compare with what the phone counted.
//
// Usage: steps-replay <copy of whoop.sqlite> [--days 60] [--tz America/New_York]
//
// It uses the app's own StrandAnalytics functions for the hourly split, the calibration, the estimate and the
// merge rule, so its numbers are the app's. Open a copy: SQLite folds the -wal file into the database it opens.

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

    // The band: the device with the most gravity rows in the window.
    let owners = try db.query("""
        SELECT deviceId, COUNT(*) FROM gravitySample WHERE ts >= ? AND ts <= ? GROUP BY deviceId ORDER BY 2 DESC
        """, [windowStart, now])
    guard let owner = owners.first?[0] as? String else { throw Failure("No gravity rows in the last \(windowDays) days.") }

    print("ZENO steps replay · \(URL(fileURLWithPath: dbPath).lastPathComponent) · \(windowDays) days to \(dayKey(now)) · \(zone.identifier)")
    print("Band motion from \(owner): \(fmt((owners.first?[1] as? Int) ?? 0)) rows"
        + (owners.count > 1 ? " (also: \(owners.dropFirst().compactMap { $0[0] as? String }.joined(separator: ", ")))" : ""))

    // MARK: 1. How the band stores motion

    var motionByHour: [Int: StepsHourMerge.HourMotion] = [:]
    struct DayDensity { let day: String; let rows: Int; let hours: Int; let rowsPerHour: Int; let covered: Double; let changes: Double; let medianGap: Int }
    var density: [DayDensity] = []
    for day in days {
        guard let b = StepsHourly.dayBounds(day: day, calendar: calendar) else { continue }
        let rows = try db.query("SELECT ts, x, y, z FROM gravitySample WHERE deviceId = ? AND ts >= ? AND ts < ? ORDER BY ts",
                                [owner, b.start, b.end])
        let grav = rows.compactMap { r -> GravitySample? in
            guard let ts = r[0] as? Int, let x = r[1] as? Double, let y = r[2] as? Double, let z = r[3] as? Double
            else { return nil }
            return GravitySample(ts: ts, x: x, y: y, z: z)
        }
        let hours = StepsHourMerge.hourlyMotion(grav, offsetSec: offset(at: b.start))
        for (h, m) in hours { motionByHour[h] = m }
        var changes = 0, gaps: [Double] = []
        for i in 1..<max(1, grav.count) {
            let a = grav[i - 1], c = grav[i]
            if a.x != c.x || a.y != c.y || a.z != c.z { changes += 1 }
            gaps.append(Double(c.ts - a.ts))
        }
        let recorded = hours.values.filter { $0.rows > 0 }
        density.append(DayDensity(day: day, rows: grav.count, hours: recorded.count,
                                  rowsPerHour: StepsHourMerge.usualRows(Array(hours.values)),
                                  covered: Double(grav.count) / Double(b.end - b.start),
                                  changes: grav.count > 1 ? Double(changes) / Double(grav.count - 1) : 0,
                                  medianGap: Int(median(gaps) ?? 0)))
    }
    let usualRows = StepsHourMerge.usualRows(Array(motionByHour.values))
    let minRows = StepsHourMerge.minCarriedRows(usualRows: usualRows)
    print("\n1. How your band stores motion")
    let verdict = usualRows >= 2_400 ? "dense: about one reading every second while worn"
        : (usualRows >= 600 ? "partly dense: readings in long stretches with gaps" : "sparse: short bursts, far from every second")
    print("   Usual recorded hour: \(fmt(usualRows)) rows (\(verdict))")
    print("   A carried hour needs at least \(fmt(minRows)) rows.")
    print("   " + pad("day", 10, left: true) + pad("rows", 9) + pad("hours", 7) + pad("rows/hour", 11)
        + pad("covered", 9) + pad("changes", 9) + pad("gap", 6))
    for d in density where d.rows > 0 {
        print("   " + pad(d.day, 10, left: true) + pad(fmt(d.rows), 9) + pad(String(d.hours), 7)
            + pad(fmt(d.rowsPerHour), 11) + pad(pct(d.covered), 9) + pad(pct(d.changes), 9) + pad("\(d.medianGap)s", 6))
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
    for h in motionByHour.keys { openByHour[h] = 1 - StepsHourMerge.coveredFraction(hourStart: h, intervals: blocked) }

    // The phone side has finished counting everything but the newest hour of the copy.
    let settledUntil = now - 3_600
    func carriedHours(excluding excludedDay: String? = nil) -> [StepsHourMerge.CalibrationHour] {
        motionByHour.compactMap { h, m in
            guard h + 3_600 <= settledUntil, excludedDay == nil || dayKey(h) != excludedDay else { return nil }
            let p = phoneByHour[h] ?? 0
            guard StepsHourMerge.isCarried(phoneSteps: p, motion: m, minRows: minRows,
                                           blockedFraction: 1 - (openByHour[h] ?? 1)) else { return nil }
            return StepsHourMerge.CalibrationHour(motion: m.motion, steps: Double(p))
        }
    }

    // MARK: 2. Calibration

    // A manual coefficient lives in the app's settings, not in the database, so the replay always fits.
    let carried = carriedHours()
    let cal = StepsHourMerge.calibrate(carried)
    print("\n2. Calibration")
    print("   Carried hours: \(carried.count) (phone at least \(StepsHourMerge.carriedMinSteps) steps, band recording, awake)")
    print("   Sleep sessions and no-footfall workouts set aside: \(blocked.count - noFootWorkouts) and \(noFootWorkouts)")
    if let cal {
        print(String(format: "   Hourly factor: %.2f steps per motion unit, confidence %.2f", cal.coefficient, cal.confidence))
    } else {
        print("   Hourly factor: not yet (needs \(StepsHourMerge.minCalibrationHours) carried hours). Nothing would be filled.")
    }
    // Today's method for comparison: whole days, Health first then the iPhone.
    var dailyPoints: [StepsEstimateEngine.CalibrationPoint] = []
    var phoneDayTotal: [String: (steps: Int, source: String)] = [:]
    for r in try db.query("SELECT day, steps FROM appleDaily WHERE deviceId = ? AND steps > 0", [healthId]) {
        if let d = r[0] as? String, let s = r[1] as? Int { phoneDayTotal[d] = (s, "Apple Health") }
    }
    for r in try db.query("SELECT day, value FROM metricSeries WHERE deviceId = ? AND key = 'steps' AND value > 0", [phoneId]) {
        if let d = r[0] as? String, let v = r[1] as? Double, phoneDayTotal[d] == nil { phoneDayTotal[d] = (Int(v.rounded()), "iPhone") }
    }
    var dayMotion: [String: Double] = [:]
    for (h, m) in motionByHour { dayMotion[dayKey(h), default: 0] += m.motion }
    for day in days {
        if let p = phoneDayTotal[day], let m = dayMotion[day] { dailyPoints.append(.init(motion: m, steps: Double(p.steps))) }
    }
    if let daily = StepsEstimateEngine.calibrate(dailyPoints) {
        print(String(format: "   Today's day-level factor: %.2f from %d days (confidence %.2f)", daily.coefficient,
                     daily.sampleDays, daily.confidence))
    }

    // MARK: 3. Day by day

    func bandBuckets(_ day: String, k: Double) -> [Int] {
        guard let b = StepsHourly.dayBounds(day: day, calendar: calendar) else { return Array(repeating: 0, count: 24) }
        var rows: [(ts: Int, steps: Int)] = []
        var h = b.start
        while h < b.end {
            if let m = motionByHour[h] {
                rows.append((ts: h, steps: StepsHourMerge.estimate(motion: m.motion, coefficient: k, openFraction: openByHour[h] ?? 1)))
            }
            h += 3_600
        }
        return StepsHourly.buckets(rows: rows, day: day, calendar: calendar)
    }
    func settled(_ day: String) -> Int {
        guard let start = StepsHourly.dayBounds(day: day, calendar: calendar)?.start else { return 0 }
        return StepsHourMerge.settledHours(dayStart: start, settledUntil: settledUntil)
    }

    print("\n3. Day by day")
    if let cal {
        print("   " + pad("day", 10, left: true) + pad("today", 9) + "  " + pad("source", 13, left: true)
            + pad("band adds", 10) + pad("new total", 11) + "  filled hours")
        var addedShares: [Double] = []
        for day in days {
            guard let base = phoneDayTotal[day] else { continue }
            let added = StepsHourMerge.addedByHour(phone: phoneByDay[day], health: healthByDay[day],
                                                   band: bandBuckets(day, k: cal.coefficient), settledHours: settled(day))
            let total = added.reduce(0, +)
            let hoursText = added.enumerated().filter { $0.element > 0 }
                .map { "\($0.offset)h +\(fmt($0.element))" }.joined(separator: ", ")
            print("   " + pad(day, 10, left: true) + pad(fmt(base.steps), 9) + "  " + pad(base.source, 13, left: true)
                + pad(total > 0 ? "+" + fmt(total) : "-", 10) + pad(fmt(base.steps + total), 11) + "  " + hoursText)
            if base.steps >= 3_000 { addedShares.append(Double(total) / Double(base.steps)) }
        }
        if let m = median(addedShares) {
            let sorted = addedShares.sorted()
            let p90 = sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.9))]
            print("   On days with at least 3,000 phone steps the band adds a median \(pct(m)) (90th percentile \(pct(p90))).")
        }
    } else {
        print("   Skipped: no hourly factor yet.")
    }

    // MARK: 4. Hide-the-phone test

    // Each tested day hides the phone's count for one to three hours that start with a walk, refits the factor
    // without that day, and lets the band fill. The score is what the band put back in the hidden hours against
    // what the phone had counted there, as a share of the day. Fills in other hours are left out of it: on real
    // data they are either walks the phone really missed or false steps, and section 3 lists them.
    print("\n4. Hide-the-phone test")
    var fillErrors: [Double] = [], noFillErrors: [Double] = [], walkHourErrors: [Double] = []
    var lines: [String] = []
    for day in days.dropLast() {
        var phone = phoneByDay[day] ?? Array(repeating: 0, count: 24)
        var health = healthByDay[day] ?? Array(repeating: 0, count: 24)
        let sideBySide = (0..<24).map { max(phone[$0], health[$0]) }
        let truth = sideBySide.reduce(0, +)
        let walking = (0..<24).filter { sideBySide[$0] >= StepsHourMerge.carriedMinSteps }
        guard truth >= 3_000, walking.count >= 2 else { continue }
        // A fixed, day-seeded choice of 1-3 consecutive hours starting at a walking hour.
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        for c in day.unicodeScalars { seed = seed &* 6_364_136_223_846_793_005 &+ UInt64(c.value) }
        seed ^= seed >> 29
        let start = walking[Int(seed % UInt64(walking.count))]
        let length = 1 + Int((seed >> 17) % 3)
        let stretch = Array(start..<min(24, start + length))
        let hidden = stretch.reduce(0) { $0 + sideBySide[$1] }
        for h in stretch { phone[h] = 0; health[h] = 0 }
        guard let k = StepsHourMerge.calibrate(carriedHours(excluding: day))?.coefficient else { continue }
        let band = bandBuckets(day, k: k)
        let added = StepsHourMerge.addedByHour(phone: phone, health: health, band: band, settledHours: 24)
        let putBack = stretch.reduce(0) { $0 + added[$1] }
        let err = Double(putBack - hidden) / Double(truth)
        fillErrors.append(err)
        noFillErrors.append(Double(-hidden) / Double(truth))
        for h in stretch where sideBySide[h] >= StepsHourMerge.carriedMinSteps {
            walkHourErrors.append(Double(band[h] - sideBySide[h]) / Double(sideBySide[h]))
        }
        lines.append("   " + pad(day, 10, left: true) + pad("\(stretch.first ?? 0)-\((stretch.last ?? 0) + 1)h", 8)
            + pad(fmt(hidden), 8) + pad(fmt(putBack), 10) + pad(fmt(truth), 9) + pad(signedPct(err), 9))
    }
    if fillErrors.isEmpty {
        print("   No day had enough phone-carried walking to test (needs 3,000 steps and two walking hours).")
    } else {
        print("   " + pad("day", 10, left: true) + pad("hidden", 8) + pad("steps", 8) + pad("band", 10)
            + pad("phone", 9) + pad("day", 9))
        print("   " + pad("", 10, left: true) + pad("hours", 8) + pad("hidden", 8) + pad("put back", 10)
            + pad("day", 9) + pad("error", 9))
        lines.forEach { print($0) }
        let absFill = fillErrors.map { abs($0) }, absNo = noFillErrors.map { abs($0) }
        let within = Double(absFill.filter { $0 <= 0.10 }.count) / Double(absFill.count)
        print("\n   \(fillErrors.count) days tested. With the band filling the hidden hours, the day total:")
        print("     median miss \(pct(median(absFill) ?? 0)), lean \(signedPct(fillErrors.reduce(0, +) / Double(fillErrors.count))), within 10% on \(pct(within)) of days")
        print("   Without it (what ZENO shows today when the phone misses those hours):")
        print("     median miss \(pct(median(absNo) ?? 0)), lean \(signedPct(noFillErrors.reduce(0, +) / Double(noFillErrors.count)))")
        if let m = median(walkHourErrors.map { abs($0) }), let lean = median(walkHourErrors) {
            print("   The band's estimate for the hidden walking hours themselves: median miss \(pct(m)), median lean \(signedPct(lean))")
        }
        print("   Targets from the plan: median miss within 10%, lean within 5%.")
    }
} catch {
    FileHandle.standardError.write(Data("steps-replay: \(error)\n".utf8))
    exit(1)
}
