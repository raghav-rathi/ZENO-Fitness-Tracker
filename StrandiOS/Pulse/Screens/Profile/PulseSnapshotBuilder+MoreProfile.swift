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

extension PulseSnapshotBuilder {

    /// Build the profile snapshot. `calendarAge` is the profile's age from its birthday and `storeLoaded`
    /// the repository's `loaded` when the request was made (both read on the main actor by the caller);
    /// a nil age leaves ZENO Age out.
    func profile(_ r: PulseRequest, calendarAge: Int?, storeLoaded: Bool) async -> ProfileSnapshot? {
        begin(r.seq)
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
                                   week: PulseDayStreak.week(dayKeys: dayKeys, qualified: qualified, today: todayKey),
                                   milestone: PulseDayStreak.milestoneProgress(days: streaks.current))

        // One resolved row per day, shared by the badges and the highlights.
        let resolved = days.map { d -> ProfileDay in
            let strain = d.strain.map { UnitFormatter.effortValue($0, scale: .whoop) }
            let optimal = d.recovery.flatMap { recovery -> ClosedRange<Double>? in
                let shown = Double(PulseDisplay.displayedPercent(recovery))
                return CoupledView.optimalStrainRange(recovery: shown).map { Double($0.lowerBound)...Double($0.upperBound) }
            }
            return ProfileDay(key: d.day,
                              sleepPerformance: sleepPerformance(dayKey: d.day, rest: rest, days: r.days),
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
        let journal = await repo.nativeJournalDays(from: "0000-01-01", to: "9999-12-31")
        guard isCurrent(r) else { return nil }
        return FirstWeekSnapshot(seq: r.seq, hasActivity: !workouts.isEmpty, hasJournal: !journal.isEmpty)
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
