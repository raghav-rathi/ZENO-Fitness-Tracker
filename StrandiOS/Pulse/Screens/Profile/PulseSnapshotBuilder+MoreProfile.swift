#if os(iOS)
import Foundation
import StrandDesign
import StrandAnalytics
import WhoopStore

// MARK: - Profile snapshot builder (WHOOP_UI_SPEC §3.30)
//
// One build for Profile, Levels, Achievements and Day Streak, off the main actor. It reads only what the
// shared readers already read for Home and the dives (the day list, the stored Sleep Performance series,
// the workout rows) plus the ZENO Age series the Health tab reads, so every figure here is a figure some
// other Pulse screen resolves the same way:
//   - the level counts the days whose row carries a Recovery;
//   - the streak is `StreakCalculator`'s current run anchored on `Repository.localDayKey(now)`, exactly
//     the Home pill's (`home(_:)`);
//   - Sleep Performance per night is `sleepPerformance(dayKey:rest:days:)`, the Sleep dial's resolver;
//   - Strain is the stored day on the 0–21 scale, the way the dives print it;
//   - ZENO Age is the newest Body Age point, as `health(_:)` reads it.
//
// Profile, Levels, Achievements, Day Streak and Achievement Details can be alive at once (each pushed on
// the last), and each asks for the snapshot when the store refreshes. The first build of a refresh is
// kept for the others (`ProfileSnapshotShelf`), so a refresh costs one pass over the history, not five.

/// The profile snapshots built during one refresh, by age, load state and day. A class held in the
/// builder's per-refresh cache, so it is dropped with that cache when the next refresh begins.
final class ProfileSnapshotShelf {
    var built: [String: ProfileSnapshot] = [:]
}

extension PulseSnapshotBuilder {

    /// Build the profile snapshot. `calendarAge` is the profile's age from its birthday and `storeLoaded`
    /// the repository's `loaded` when the request was made (both read on the main actor by the caller);
    /// a nil age leaves ZENO Age out.
    func profile(_ r: PulseRequest, calendarAge: Int?, storeLoaded: Bool) async -> ProfileSnapshot? {
        begin(r.seq)
        let shelf = await cached("moreprofile.snapshots") { ProfileSnapshotShelf() }
        let shelfKey = "\(calendarAge ?? -1)|\(storeLoaded)|\(Repository.localDayKey(r.now))"
        if let kept = shelf.built[shelfKey], kept.seq == r.seq { return kept }
        guard let built = await buildProfile(r, calendarAge: calendarAge, storeLoaded: storeLoaded) else { return nil }
        shelf.built[shelfKey] = built
        return built
    }

    private func buildProfile(_ r: PulseRequest, calendarAge: Int?, storeLoaded: Bool) async -> ProfileSnapshot? {
        let rest = await restSeries()
        let workouts = await workoutRows()
        let bodyAge = await cached("moreprofile.bodyAge") {
            await repo.exploreSeries(key: "body_age", source: "my-whoop")
        }
        guard isCurrent(r) else { return nil }

        let todayKey = Repository.localDayKey(r.now)
        let days = r.days.sorted { $0.day < $1.day }

        // Level: every scored Recovery in the history.
        let level = PulseLevels.progress(recoveries: PulseLevels.scoredRecoveries(days.map(\.recovery)))

        // Streak: the Home pill's rule, plus what the page draws around it.
        let dayKeys = days.map(\.day)
        let qualified = days.map { $0.recovery != nil }
        let streaks = StreakCalculator.streaks(dayKeys: dayKeys, qualified: qualified, today: todayKey)
        let run = PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: qualified, today: todayKey)
        let streak = ProfileStreak(current: streaks.current, longest: streaks.longest,
                                   startKey: streaks.current > 0 ? run?.startDay : nil,
                                   week: PulseDayStreak.week(dayKeys: dayKeys, qualified: qualified, today: todayKey,
                                                             firstDay: days.first?.day),
                                   milestone: PulseDayStreak.milestoneProgress(days: streaks.current))

        // One resolved row per day, shared by the badges and the highlights. Sleep Performance goes through
        // the Sleep dial's own resolver, handed only that day's points (looked up once, not scanned for per
        // day), so years of history stay one pass. The last point per day wins, as `last(where:)` resolves.
        var restByDay: [String: Double] = [:]
        for point in rest { restByDay[point.day] = point.value }
        var rowByDay: [String: DailyMetric] = [:]
        for row in r.days { rowByDay[row.day] = row }
        let resolved = days.map { d -> ProfileDay in
            let strain = d.strain.map { UnitFormatter.effortValue($0, scale: .whoop) }
            // The Strain target's band for the Recovery the dial prints, through the builder's own lookup of
            // CoupledView's bands (read once on the main actor, where that rule lives).
            let optimal = d.recovery.flatMap { optimalStrainRange(percent: PulseDisplay.displayedPercent($0)) }
            return ProfileDay(key: d.day,
                              sleepPerformance: sleepPerformance(dayKey: d.day,
                                                                 rest: restByDay[d.day].map { [(day: d.day, value: $0)] } ?? [],
                                                                 days: rowByDay[d.day].map { [$0] } ?? []),
                              asleepMinutes: d.totalSleepMin,
                              recovery: d.recovery, strain: strain, optimalStrain: optimal,
                              restingHR: d.restingHr, hrv: d.avgHrv)
        }
        let sessions = workouts.map { w -> ProfileSession in
            ProfileSession(key: Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs))),
                           sport: w.sport,
                           strain: w.strain.map { UnitFormatter.effortValue($0, scale: .whoop) },
                           maxHR: w.maxHr)
        }

        // ZENO Age beside the calendar age.
        var zeno: ProfileZenoAge?
        if let calendarAge, calendarAge > 0, let last = bodyAge.last, last.value.isFinite, last.value > 0 {
            zeno = ProfileZenoAge(zenoAge: last.value, calendarAge: calendarAge, dayKey: last.day)
        }

        let badges = PulseAchievements.evaluate(
            days: resolved.map {
                PulseAchievements.Day(day: $0.key, sleepPerformance: $0.sleepPerformance,
                                      asleepMinutes: $0.asleepMinutes, recovery: $0.recovery, strain: $0.strain,
                                      optimalStrain: $0.optimalStrain)
            },
            activities: sessions.map { PulseAchievements.Activity(day: $0.key, sport: $0.sport) },
            ageGap: zeno.map { PulseAchievements.AgeGap(yearsYounger: $0.yearsYounger, day: $0.dayKey) })

        var highlights: [ProfileWindow: ProfileHighlights] = [:]
        var activity: [ProfileWindow: ProfileActivitySummary] = [:]
        for window in ProfileWindow.allCases {
            let from = window.days.flatMap { PulseDisplay.dayKey(todayKey, offsetBy: -($0 - 1)) }
            let inWindow = resolved.filter { d in from.map { d.key >= $0 } ?? true && d.key <= todayKey }
            let windowSessions = sessions.filter { s in from.map { s.key >= $0 } ?? true && s.key <= todayKey }
            highlights[window] = Self.highlights(inWindow, sessions: windowSessions)
            activity[window] = Self.activitySummary(windowSessions)
        }

        guard isCurrent(r) else { return nil }
        return ProfileSnapshot(seq: r.seq, storeLoaded: storeLoaded, todayKey: todayKey, level: level,
                               streak: streak, badges: badges,
                               firstDayKey: days.first?.day, zenoAge: zeno, highlights: highlights,
                               activity: activity)
    }

    /// The First Week checklist's store facts (More › FIRST WEEK WITH ZENO).
    func firstWeek(_ r: PulseRequest) async -> FirstWeekSnapshot? {
        begin(r.seq)
        let workouts = await workoutRows()
        let hasJournal = await cached("moreprofile.anyJournal") { await anyNativeJournal(r) }
        guard isCurrent(r) else { return nil }
        return FirstWeekSnapshot(seq: r.seq, hasActivity: !workouts.isEmpty, hasJournal: hasJournal)
    }

    /// Whether any native journal entry exists, reading the last 30 days first: someone who journals has
    /// an entry there, so the whole history is read only when there is none (and then it is short).
    private func anyNativeJournal(_ r: PulseRequest) async -> Bool {
        let today = Repository.localDayKey(r.now)
        let recentFrom = PulseDisplay.dayKey(today, offsetBy: -29) ?? today
        if !(await repo.nativeJournalDays(from: recentFrom, to: today)).isEmpty { return true }
        guard let before = PulseDisplay.dayKey(recentFrom, offsetBy: -1) else { return false }
        return !(await repo.nativeJournalDays(from: "0000-01-01", to: before)).isEmpty
    }

    // MARK: Pieces

    private static func highlights(_ days: [ProfileDay], sessions: [ProfileSession]) -> ProfileHighlights {
        func longestRun(_ test: (ProfileDay) -> Bool) -> Int {
            StreakCalculator.streaks(dayKeys: days.map(\.key), qualified: days.map(test), today: "").longest
        }
        let recoveries = days.compactMap(\.recovery)
        let rhr = days.compactMap(\.restingHR)
        let hrv = days.compactMap(\.hrv)
        return ProfileHighlights(
            bestSleep: days.compactMap(\.sleepPerformance).max(),
            peakRecovery: recoveries.max(),
            maxStrain: days.compactMap(\.strain).max(),
            sleepStreak: longestRun { ($0.sleepPerformance ?? -1) >= 70 },
            greenStreak: longestRun { d in
                d.recovery.map { PulseDisplay.recoveryBand(percent: $0) == .green } ?? false
            },
            strainStreak: longestRun { ($0.strain ?? -1) >= 10 },
            lowestRHR: rhr.min(), highestRHR: rhr.max(),
            lowestHRV: hrv.min(), highestHRV: hrv.max(),
            maxHeartRate: sessions.compactMap(\.maxHR).max(),
            longestSleepMin: days.compactMap(\.asleepMinutes).max(),
            lowestRecovery: recoveries.min())
    }

    private static func activitySummary(_ sessions: [ProfileSession]) -> ProfileActivitySummary {
        var groups: [String: (token: String, count: Int, strains: [Double])] = [:]
        for s in sessions.sorted(by: { $0.key < $1.key }) {
            let token = s.sport.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = token.lowercased()
            guard !key.isEmpty else { continue }
            var entry = groups[key] ?? (token, 0, [])
            entry.count += 1
            if let strain = s.strain { entry.strains.append(strain) }
            groups[key] = entry
        }
        let sports = groups.map { key, entry in
            ProfileActivitySummary.Sport(
                id: key, name: WorkoutSource.displaySport(entry.token), symbol: sportSymbol(entry.token),
                count: entry.count,
                averageStrain: entry.strains.isEmpty ? nil : entry.strains.reduce(0, +) / Double(entry.strains.count))
        }
        .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
        return ProfileActivitySummary(total: sessions.count, sports: sports)
    }
}

/// One day as the profile build resolves it.
private struct ProfileDay {
    let key: String
    let sleepPerformance: Double?
    let asleepMinutes: Double?
    let recovery: Double?
    /// 0–21.
    let strain: Double?
    let optimalStrain: ClosedRange<Double>?
    let restingHR: Int?
    let hrv: Double?
}

/// One logged activity as the profile build resolves it.
private struct ProfileSession {
    let key: String
    let sport: String
    /// 0–21.
    let strain: Double?
    let maxHR: Int?
}
#endif
