#if os(iOS)
import Foundation
import StrandAnalytics
import WhoopStore

// MARK: - Weekly Plan builds (off the main actor)
//
// Run through `PulseModel.build(dayOffset: 0)`: `r.day.key` is today. A plan week is Monday to Sunday on
// local day keys (the keys every daily row and journal answer carries). Each goal reads ONE source, the one
// the rest of Pulse shows for that number:
//   - Sleep Performance: `sleepPerformance(dayKey:)`, the resolver Home's dial and the Sleep dive read;
//   - Sleep Consistency: the stored `sleep_consistency` series;
//   - Day Strain: the stored day (0–21), and today's live score the way Home's dial computes it;
//   - Steps: `Repository.resolvedStepDays`, the one steps resolver;
//   - activities and zone minutes: the workout rows (imported zone percentages, else the workout's own
//     heart rate against the profile's zones);
//   - behaviours: journal answers, imported ∪ native, folded per behaviour like Behavior Insights.
// A day before the plan began is not counted, and a plan that begins mid-week is not asked for more days
// than the week has left.

extension PulseSnapshotBuilder {

    func planWeek(_ r: PulseRequest, plan: PulsePlan, weekOffset: Int = 0) async -> PlanWeekSnapshot? {
        begin(r.seq)
        let today = r.day.key
        guard let thisMonday = WeeklyPlanProgress.weekStart(of: today),
              let monday = PulseDisplay.dayKey(thisMonday, offsetBy: 7 * weekOffset) else { return nil }
        let days = WeeklyPlanProgress.days(ofWeekStarting: monday)
        guard let sunday = days.last else { return nil }
        let thisWeek = weekOffset == 0
        let covered = days.filter { $0 >= plan.startedOn }
        let kinds = Set(plan.goals.map(\.kind))

        // Sleep.
        var performance: [String: Double] = [:]
        if kinds.contains(.sleepPerformance) {
            let rest = await restSeries()
            for d in days where d <= today {
                if let p = sleepPerformance(dayKey: d, rest: rest, days: r.days) { performance[d] = p }
            }
        }
        var consistency: [String: Double] = [:]
        if kinds.contains(.sleepConsistency) {
            let series = await cached("plan.sleepConsistency") {
                await repo.exploreSeries(key: "sleep_consistency", source: "my-whoop", days: 120)
            }
            for p in series where days.contains(p.day) && p.value.isFinite { consistency[p.day] = p.value }
        }

        // Strain: the stored day, today's live score where it is higher (Home's never-drop rule).
        var strain: [String: Double] = [:]
        if kinds.contains(.dayStrain) {
            for d in r.days where days.contains(d.day) {
                if let s = d.strain { strain[d.day] = UnitFormatter.effortValue(s, scale: .whoop) }
            }
            if thisWeek {
                let window = await dayWindow(r)
                let hr = await heartRate(dayKey: r.day.key, from: window.from, to: window.to, isToday: true)
                if let live = strainValue(r, row: displayRow(r), hr: hr) { strain[today] = live }
            }
        }

        // Steps.
        var steps: [String: Double] = [:]
        if kinds.contains(.steps) {
            for s in await repo.resolvedStepDays(from: monday, to: sunday).days where days.contains(s.day) {
                steps[s.day] = Double(s.steps)
            }
        }

        // Activities in the plan's part of the week.
        let activityKinds: Set<PulsePlanGoal.Kind> = [.hrZones45, .hrZones13, .strengthTime, .anyActivity,
                                                      .strengthActivity, .recoveryActivity, .sport]
        var workouts: [(row: WorkoutRow, day: String)] = []
        if !kinds.isDisjoint(with: activityKinds) {
            workouts = (await workoutRows()).compactMap { w in
                let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
                return days.contains(day) && day >= plan.startedOn ? (w, day) : nil
            }
        }
        var zoneMinutes: [Int: [Double]] = [:]
        if kinds.contains(.hrZones45) || kinds.contains(.hrZones13) {
            for w in workouts { zoneMinutes[w.row.startTs] = await planZoneMinutes(w.row, zoneSet: r.profile.zoneSet) }
        }

        // Journal answers.
        var journal: [JournalEntry] = []
        if kinds.contains(.behavior) { journal = await repo.journalEntries(days: 21 + 7 * max(0, -weekOffset)) }
        guard isCurrent(r) else { return nil }

        let context = PlanWeekContext(days: days, today: today, covered: covered, thisWeek: thisWeek,
                                      performance: performance, consistency: consistency, strain: strain,
                                      steps: steps, workouts: workouts, zoneMinutes: zoneMinutes, journal: journal)
        let goals = plan.goals.map { context.progress($0) }
        return PlanWeekSnapshot(seq: r.seq, weekStart: monday, days: days, today: today,
                                daysLeft: thisWeek ? WeeklyPlanProgress.daysLeft(today: today) : 0,
                                percent: WeeklyPlanProgress.overallPercent(goals.map {
                                    WeeklyPlanProgress.Progress(fraction: $0.fraction, met: $0.met)
                                }),
                                goals: goals)
    }

    /// One workout's minutes in zones 1…5: the imported zone percentages of its duration, else its own heart
    /// rate against the profile's zones; zeros when neither exists (it then adds nothing to a zone goal).
    func planZoneMinutes(_ w: WorkoutRow, zoneSet: HRZoneSet) async -> [Double] {
        let duration = (w.durationS ?? Double(max(0, w.endTs - w.startTs))) / 60
        if let p = WorkoutZones.percents(w.zonesJSON) { return p.map { duration * $0 / 100 } }
        let hr = await repo.hrSamples(from: w.startTs, to: w.endTs, limit: 50_000)
        guard hr.count >= 10 else { return [0, 0, 0, 0, 0] }
        return HRZones.timeInZone(hr, zoneSet: zoneSet).seconds.map { $0 / 60 }
    }
}

/// The week's measurements, and how each goal reads them.
private struct PlanWeekContext {
    let days: [String]
    let today: String
    let covered: [String]
    let thisWeek: Bool
    let performance: [String: Double]
    let consistency: [String: Double]
    let strain: [String: Double]
    let steps: [String: Double]
    let workouts: [(row: WorkoutRow, day: String)]
    let zoneMinutes: [Int: [Double]]
    let journal: [JournalEntry]

    func progress(_ goal: PulsePlanGoal) -> PlanGoalProgress {
        switch goal.kind {
        case .sleepPerformance:
            let target = goal.value ?? 85
            return average(goal, values: performance, target: target, unit: "%",
                           format: { "\(Int($0.rounded()))%" },
                           footer: String(localized: "Average at least \(Int(target))%+ Sleep Performance to complete this goal."))
        case .sleepConsistency:
            let target = goal.value ?? 80
            return average(goal, values: consistency, target: target, unit: "%",
                           format: { "\(Int($0.rounded()))%" },
                           footer: String(localized: "Average at least \(Int(target))% Sleep Consistency to complete this goal."))
        case .dayStrain:
            let threshold = goal.value ?? 14
            let target = target(goal)
            return metricCount(goal, values: strain, threshold: threshold, target: target,
                               format: PulseFormat.oneDecimal,
                               footer: String(localized: "Reach \(PulseFormat.oneDecimal(threshold))+ Day Strain at least \(target) days this week to complete this weekly goal."))
        case .steps:
            let threshold = goal.value ?? 7000
            let target = target(goal)
            return metricCount(goal, values: steps, threshold: threshold, target: target,
                               format: PulseFormat.grouped,
                               footer: String(localized: "Reach \(PulseFormat.grouped(threshold))+ steps at least \(target) days this week to complete this weekly goal."))
        case .hrZones45:
            return time(goal, zones: [3, 4], symbolZone: 4, label: String(localized: "Zone 4-5"))
        case .hrZones13:
            return time(goal, zones: [0, 1, 2], symbolZone: 2, label: String(localized: "Zone 1-3"))
        case .strengthTime:
            return time(goal, zones: nil, symbolZone: nil, label: String(localized: "strength activity"))
        case .anyActivity:
            let n = target(goal)
            return count(goal, matching: { !PlanSports.isRecovery($0) },
                         footer: String(localized: "Log a strain activity on at least \(n) days this week."))
        case .strengthActivity:
            let n = target(goal)
            return count(goal, matching: PlanSports.isStrength,
                         footer: String(localized: "Log a strength training activity on at least \(n) days this week."))
        case .recoveryActivity:
            let n = target(goal)
            return count(goal, matching: PlanSports.isRecovery,
                         footer: String(localized: "Log a recovery activity, such as yoga, stretching or a sauna, on at least \(n) days this week."))
        case .sport:
            let n = target(goal)
            let name = goal.subject.map(WorkoutSource.displaySport) ?? ""
            let key = (goal.subject ?? "").lowercased()
            return count(goal, matching: { WorkoutSource.displaySport($0).lowercased() == WorkoutSource.displaySport(key).lowercased() },
                         footer: String(localized: "Log \(name) on at least \(n) days this week."))
        case .behavior:
            return behavior(goal)
        }
    }

    /// The goal's days per week, pro-rated in the week the plan began.
    func target(_ goal: PulsePlanGoal) -> Int {
        WeeklyPlanProgress.proratedTarget(goal.days ?? 3, countedDays: covered.count)
    }

    /// MON–SUN for a day-by-day goal: done, missed ("–"), today still open (dashed), still to come (dashed).
    func states(_ met: (String) -> Bool) -> [PulseDayCircleRow.State] {
        days.map { day in
            if !covered.contains(day) { return day > today ? .future : .rest }
            if day > today { return .future }
            if met(day) { return .done }
            return day == today && thisWeek ? .future : .rest
        }
    }

    private func average(_ goal: PulsePlanGoal, values: [String: Double], target: Double, unit: String,
                         format: (Double) -> String, footer: String) -> PlanGoalProgress {
        let counted = covered.filter { $0 <= today }.compactMap { values[$0] }
        let (avg, progress) = WeeklyPlanProgress.average(counted, target: target)
        return PlanGoalProgress(
            goal: goal, title: goal.title(), section: PulsePlanSection(goal.kind), style: .metric,
            ring: .value(text: avg.map(format) ?? "--", fraction: progress.fraction), met: progress.met,
            fraction: progress.fraction, dayStates: states { (values[$0] ?? -1) >= target },
            dayValues: days.map { covered.contains($0) ? values[$0] : nil }, goalLine: target,
            averageText: avg.map { String(localized: "Avg. \(format($0))") }, progressText: nil, targetText: nil,
            activities: [], footer: footer, targetDays: nil)
    }

    private func metricCount(_ goal: PulsePlanGoal, values: [String: Double], threshold: Double, target: Int,
                             format: (Double) -> String, footer: String) -> PlanGoalProgress {
        let done = covered.filter { $0 <= today && (values[$0] ?? -1) >= threshold }.count
        let progress = WeeklyPlanProgress.count(done: done, target: target)
        let shown = covered.filter { $0 <= today }.compactMap { values[$0] }
        let avg = shown.isEmpty ? nil : shown.reduce(0, +) / Double(shown.count)
        return PlanGoalProgress(
            goal: goal, title: goal.title(), section: PulsePlanSection(goal.kind), style: .metric,
            ring: .count(done: done, target: target), met: progress.met, fraction: progress.fraction,
            dayStates: states { (values[$0] ?? -1) >= threshold },
            dayValues: days.map { covered.contains($0) ? values[$0] : nil }, goalLine: threshold,
            averageText: avg.map { String(localized: "Avg. \(format($0))") }, progressText: nil, targetText: nil,
            activities: [], footer: footer, targetDays: target)
    }

    private func time(_ goal: PulsePlanGoal, zones: [Int]?, symbolZone: Int?, label: String) -> PlanGoalProgress {
        let base = goal.value ?? (zones == nil ? 90 : 30)
        let target = WeeklyPlanProgress.proratedTotal(base, countedDays: covered.count)
        var bySport: [String: Double] = [:]
        for w in workouts {
            let minutes: Double
            if let zones {
                let z = zoneMinutes[w.row.startTs] ?? []
                minutes = zones.reduce(0) { $0 + (z.indices.contains($1) ? z[$1] : 0) }
            } else {
                guard PlanSports.isStrength(w.row.sport) else { continue }
                minutes = (w.row.durationS ?? Double(max(0, w.row.endTs - w.row.startTs))) / 60
            }
            if minutes > 0 { bySport[WorkoutSource.displaySport(w.row.sport), default: 0] += minutes }
        }
        let total = bySport.values.reduce(0, +)
        let progress = WeeklyPlanProgress.total(total, target: target)
        let left = max(0, target - total)
        let footer: String
        if progress.met {
            footer = String(localized: "You hit this week's goal of \(PulseFormat.hoursMinutes(target)) of \(label).")
        } else if zones == nil {
            footer = String(localized: "Get \(PlanTimeFormat.short(left)) more of strength activity this week to hit your goal.")
        } else {
            footer = String(localized: "Get \(PlanTimeFormat.short(left)) more of \(label) training during activities this week to hit your goal.")
        }
        let lines = bySport.sorted { $0.value > $1.value }.map {
            PlanGoalProgress.ActivityLine(id: $0.key, minutes: $0.value, sport: $0.key, symbol: PlanSports.symbol($0.key))
        }
        return PlanGoalProgress(
            goal: goal, title: goal.title(), section: PulsePlanSection(goal.kind), style: .time,
            ring: .value(text: PulseFormat.hoursMinutes(total), fraction: progress.fraction), met: progress.met,
            fraction: progress.fraction, dayStates: [], dayValues: [], goalLine: nil, averageText: nil,
            progressText: PlanTimeFormat.long(total), targetText: PlanTimeFormat.long(target), activities: lines,
            footer: footer, targetDays: nil)
    }

    private func count(_ goal: PulsePlanGoal, matching: (String) -> Bool, footer: String) -> PlanGoalProgress {
        let activeDays = Set(workouts.filter { matching($0.row.sport) }.map(\.day))
        let target = target(goal)
        let done = activeDays.filter { $0 <= today }.count
        let progress = WeeklyPlanProgress.count(done: done, target: target)
        return PlanGoalProgress(
            goal: goal, title: goal.title(), section: PulsePlanSection(goal.kind), style: .count,
            ring: .count(done: done, target: target), met: progress.met, fraction: progress.fraction,
            dayStates: states { activeDays.contains($0) }, dayValues: [], goalLine: nil, averageText: nil,
            progressText: nil, targetText: nil, activities: [], footer: footer, targetDays: target)
    }

    private func behavior(_ goal: PulsePlanGoal) -> PlanGoalProgress {
        let subject = goal.subject ?? ""
        let answers = PulseSnapshotBuilder.behaviorDays(journal, identity: PulseBehaviorLibrary.identity(for: subject))
        let metDays = goal.avoid == true ? answers.no : answers.yes
        let counted = Set(covered.filter { $0 <= today }).intersection(metDays)
        let target = target(goal)
        let progress = WeeklyPlanProgress.count(done: counted.count, target: target)
        let name = PulseBehaviorLibrary.definition(for: subject)?.title ?? PulseBehaviorLibrary.derivedTitle(subject)
        let footer = goal.avoid == true
            ? String(localized: "Go without \(name) on at least \(target) days this week, and log it in your journal.")
            : String(localized: "Log \(name) in your journal on at least \(target) days this week.")
        return PlanGoalProgress(
            goal: goal, title: goal.title(), section: .behaviors, style: .count,
            ring: .count(done: counted.count, target: target), met: progress.met, fraction: progress.fraction,
            dayStates: states { metDays.contains($0) }, dayValues: [], goalLine: nil, averageText: nil,
            progressText: nil, targetText: nil, activities: [], footer: footer, targetDays: target)
    }
}

// MARK: - Sports and times

/// How plan goals sort activities.
enum PlanSports {
    static func isStrength(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return ["strength", "weight", "lift", "crossfit", "functional", "powerlifting", "bodybuilding", "resistance"]
            .contains { s.contains($0) }
    }

    static func isRecovery(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return ["yoga", "pilates", "stretch", "meditat", "breath", "sauna", "massage", "mobility", "recovery",
                "ice bath", "cold", "steam", "foam"].contains { s.contains($0) }
    }

    /// An SF Symbol for an activity's name.
    static func symbol(_ sport: String) -> String {
        let s = sport.lowercased()
        if s.contains("run") { return "figure.run" }
        if s.contains("cycl") || s.contains("bike") || s.contains("ride") { return "figure.outdoor.cycle" }
        if s.contains("swim") { return "figure.pool.swim" }
        if s.contains("walk") || s.contains("hik") { return "figure.walk" }
        if s.contains("row") { return "figure.rower" }
        if s.contains("yoga") { return "figure.yoga" }
        if s.contains("hiit") || s.contains("interval") { return "figure.highintensity.intervaltraining" }
        if isStrength(s) { return "figure.strengthtraining.traditional" }
        return "figure.mixed.cardio"
    }
}

/// How plan times read: "0:57:01" on a time card, "1 min" / "1 h 5 min" in a sentence.
enum PlanTimeFormat {
    static func long(_ minutes: Double) -> String {
        let total = max(0, Int((minutes * 60).rounded()))
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    static func short(_ minutes: Double) -> String {
        let total = max(1, Int(minutes.rounded(.up)))
        let h = total / 60, m = total % 60
        if h == 0 { return String(localized: "\(m) min") }
        return m == 0 ? String(localized: "\(h) h") : String(localized: "\(h) h \(m) min")
    }
}
#endif
