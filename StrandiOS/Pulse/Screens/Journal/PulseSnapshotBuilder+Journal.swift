#if os(iOS)
import Foundation
import StrandAnalytics
import WhoopStore

// MARK: - Journal and Behavior Insights builds (off the main actor)
//
// Run through `PulseModel.build(dayOffset: 0)`, so `r.day.key` is today's key and `r.day.date` today's
// logical date (the same anchor Home's journal strip counts back from). Journal answers are read fresh on
// every build: saving the journal does not bump `refreshSeq`, so a per-refresh cache would go stale.

extension PulseSnapshotBuilder {

    // MARK: Journal day (§3.17)

    /// The Journal for the day `offset` days back from today: the 14-day strip, the day's answers, the day
    /// before's, its mood, and this week's progress on the plan's behaviour goals.
    func journalDay(_ r: PulseRequest, offset: Int, stripDays: Int, planGoals: [PulsePlanGoal]) async -> JournalDaySnapshot? {
        let cal = Calendar.current
        let keyFor: (Int) -> String = { n in
            Repository.localDayKey(cal.date(byAdding: .day, value: -n, to: r.day.date) ?? r.day.date)
        }
        let offsets = Array((0..<max(1, stripDays)).reversed())
        let strip = offsets.map { (key: keyFor($0), offset: $0) }
        let dayKey = keyFor(offset)
        let previousKey = keyFor(offset + 1)

        let logged = await repo.nativeJournalDays(from: strip.first?.key ?? dayKey, to: strip.last?.key ?? dayKey)
        let imported = await importedJournalQuestions()
        let answers = await repo.nativeJournalAnswers(day: dayKey)
        let amounts = await repo.nativeJournalNumeric(day: dayKey)
        let previousAnswers = await repo.nativeJournalAnswers(day: previousKey)
        let previousAmounts = await repo.nativeJournalNumeric(day: previousKey)
        let mood = await repo.mood(day: dayKey)

        var planDone: [String: Int] = [:]
        let goals = planGoals.filter { $0.kind == .behavior && $0.subject != nil }
        if !goals.isEmpty, let monday = WeeklyPlanProgress.weekStart(of: dayKey) {
            let week = Set(WeeklyPlanProgress.days(ofWeekStarting: monday)).subtracting([dayKey])
            let entries = await repo.journalEntries(days: 21)
            for goal in goals {
                guard let subject = goal.subject else { continue }
                let identity = PulseBehaviorLibrary.identity(for: subject)
                let days = Self.behaviorDays(entries, identity: identity)
                let met = goal.avoid == true ? days.no.subtracting(days.yes) : days.yes
                planDone[identity] = met.intersection(week).count
            }
        }
        guard !Task.isCancelled else { return nil }
        return JournalDaySnapshot(
            seq: r.seq, dayKey: dayKey, offset: offset,
            strip: strip.map { JournalDaySnapshot.Day(key: $0.key, offset: $0.offset, logged: logged.contains($0.key)) },
            importedQuestions: imported, answers: answers, amounts: amounts,
            previousAnswers: previousAnswers, previousAmounts: previousAmounts, mood: mood,
            planDoneElsewhere: planDone)
    }

    /// The imported WHOOP questions in first-seen order (the classic card's input to the catalog merge).
    func importedJournalQuestions() async -> [String] {
        await cached("journalplan.importedQuestions") {
            let rows = await repo.importedJournalEntries()
            var seen = Set<String>()
            return rows.compactMap { seen.insert($0.question).inserted ? $0.question : nil }
        }
    }

    /// The native journal days inside [from, to], for the calendar.
    func journalCalendar(from: String, to: String) async -> JournalCalendarSnapshot {
        JournalCalendarSnapshot(loggedDays: await repo.nativeJournalDays(from: from, to: to))
    }

    /// One behaviour's yes and no days across the given entries (imported ∪ native, native winning per
    /// question), every question of the same behaviour folded together. A day answered both ways under two
    /// spellings counts as yes.
    static func behaviorDays(_ entries: [JournalEntry], identity: String) -> BehaviorImpact.Answers {
        var a = BehaviorImpact.Answers()
        for e in entries where PulseBehaviorLibrary.identity(for: e.question) == identity {
            if e.answeredYes { a.yes.insert(e.day) } else { a.no.insert(e.day) }
        }
        a.no.subtract(a.yes)
        return a
    }

    // MARK: Behavior Insights (§3.18)

    /// Everything Behavior Insights and Behavior Details read, computed ONE way so the two pages cannot
    /// disagree: every journal behaviour (imported ∪ native) and every auto-tracked behaviour against
    /// Recovery, over the last 90 days, as one corrected family.
    struct BehaviorData {
        let analysis: BehaviorImpact.Analysis
        let answers: [String: BehaviorImpact.Answers]
        let amounts: [String: [String: Double]]
        let questions: [String: String]
        let recovery: [String: Double]
    }

    func behaviorData(_ r: PulseRequest) async -> BehaviorData? {
        begin(r.seq)
        let entries = await repo.journalEntries()
        var answers: [String: BehaviorImpact.Answers] = [:]
        var amounts: [String: [String: Double]] = [:]
        var questions: [String: String] = [:]
        for e in entries {
            let id = PulseBehaviorLibrary.identity(for: e.question)
            if e.answeredYes { answers[id, default: .init()].yes.insert(e.day) } else { answers[id, default: .init()].no.insert(e.day) }
            if let v = e.numericValue, v.isFinite { amounts[id, default: [:]][e.day] = v }
            questions[id] = e.question
        }
        for (id, a) in answers { answers[id]?.no = a.no.subtracting(a.yes) }

        // Auto-tracked behaviours from ZENO's own data.
        let rest = await restSeries()
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let workouts = await workoutRows()
        guard isCurrent(r) else { return nil }
        let cutoff = PulseDisplay.dayKey(r.day.key, offsetBy: -(BehaviorImpact.windowDays + 21)) ?? ""
        var performance: [String: Double] = [:]
        var strain: [String: Double] = [:]
        var recovery: [String: Double] = [:]
        for d in r.days {
            if let rec = d.recovery, rec.isFinite { recovery[d.day] = rec }
            guard d.day >= cutoff else { continue }
            if let p = sleepPerformance(dayKey: d.day, rest: rest, days: r.days) { performance[d.day] = p }
            if let s = d.strain { strain[d.day] = UnitFormatter.effortValue(s, scale: .whoop) }
        }
        var nights: [AutoBehaviors.Night] = []
        for g in groups {
            let main = SleepView.mainNightGroup(g, habitualMidsleepSec: habitual)
            guard let first = main.first, let last = main.last else { continue }
            let wake = Date(timeIntervalSince1970: TimeInterval(last.endTs))
            let day = Repository.localDayKey(wake)
            guard day >= cutoff else { continue }
            let onset = Date(timeIntervalSince1970: TimeInterval(first.effectiveStartTs))
            nights.append(AutoBehaviors.Night(
                day: day, onsetTs: first.effectiveStartTs,
                bedMinute: SleepConsistency.minuteOfDay(ts: first.effectiveStartTs,
                                                        offsetSec: TimeZone.current.secondsFromGMT(for: onset)),
                wakeMinute: SleepConsistency.minuteOfDay(ts: last.endTs,
                                                         offsetSec: TimeZone.current.secondsFromGMT(for: wake))))
        }
        let ends = workouts.map(\.endTs)
        let auto: [PulseBehaviorLibrary.Auto: BehaviorImpact.Answers] = [
            .sleepPerformance: AutoBehaviors.atLeast(AutoBehaviors.sleepPerformanceThreshold, valueByDay: performance),
            .dayStrain: AutoBehaviors.previousDayAtLeast(AutoBehaviors.strainThreshold, valueByDay: strain),
            .lateWorkout: AutoBehaviors.lateWorkout(nights: nights, workoutEnds: ends),
            .consistentBedTime: AutoBehaviors.consistent(
                minuteByDay: Dictionary(nights.map { ($0.day, $0.bedMinute) }, uniquingKeysWith: { a, _ in a })),
            .consistentWakeTime: AutoBehaviors.consistent(
                minuteByDay: Dictionary(nights.map { ($0.day, $0.wakeMinute) }, uniquingKeysWith: { a, _ in a })),
        ]
        var all = answers
        for (key, value) in auto where !(value.yes.isEmpty && value.no.isEmpty) { all[key.rawValue] = value }
        let analysis = BehaviorImpact.analyze(answers: all, recoveryByDay: recovery, today: r.day.key)
        guard isCurrent(r) else { return nil }
        return BehaviorData(analysis: analysis, answers: all, amounts: amounts, questions: questions, recovery: recovery)
    }

    func behaviorInsights(_ r: PulseRequest) async -> BehaviorInsightsSnapshot? {
        guard let data = await behaviorData(r) else { return nil }
        let isAuto: (String) -> Bool = { PulseBehaviorLibrary.Auto(rawValue: $0) != nil }
        let unlocked = data.analysis.unlocked.map { BehaviorImpactRowData($0, isAuto: isAuto($0.behavior)) }
        let locked = data.analysis.locked
            // An auto-tracked behaviour with nothing judged yet says nothing; a journal one still invites logging.
            .filter { !(isAuto($0.behavior) && $0.yesCount + $0.noCount == 0) }
            .map { BehaviorImpactRowData($0, isAuto: isAuto($0.behavior)) }
        return BehaviorInsightsSnapshot(
            seq: r.seq, unlocked: unlocked, locked: locked, recoveries: data.analysis.recoveries,
            recoveriesNeeded: BehaviorImpact.recoveriesToUnlock,
            scale: BehaviorImpact.barScale(unlocked.compactMap(\.impact)), questions: data.questions)
    }

    /// Behavior Details for one behaviour identity: its row from the SAME analysis Behavior Insights shows,
    /// the follow-up breakdown, and all of its answered days for Logging History.
    func behaviorDetails(_ r: PulseRequest, identity: String, followUpEdges: [Double]?) async -> BehaviorDetailsSnapshot? {
        guard let data = await behaviorData(r) else { return nil }
        let isAuto = PulseBehaviorLibrary.Auto(rawValue: identity) != nil
        let row = (data.analysis.unlocked + data.analysis.locked).first { $0.behavior == identity }
            .map { BehaviorImpactRowData($0, isAuto: isAuto) }
        let answers = data.answers[identity] ?? .init()

        var buckets: [BehaviorDetailsSnapshot.BucketRow] = []
        var breakdownTitle: String?
        let windowAnswers = answers.within(data.analysis.from, data.analysis.to)
        let windowAmounts = (data.amounts[identity] ?? [:]).filter {
            $0.key >= data.analysis.from && $0.key <= data.analysis.to && windowAnswers.yes.contains($0.key)
        }
        if !isAuto, !windowAmounts.isEmpty {
            let edges = followUpEdges.flatMap { $0.isEmpty ? nil : $0 } ?? BehaviorImpact.medianEdges(Array(windowAmounts.values))
            if !edges.isEmpty {
                let def = PulseBehaviorLibrary.definition(for: data.questions[identity] ?? "")
                let followUp = def?.followUp
                breakdownTitle = followUp?.breakdownTitle ?? String(localized: "How much did you have?")
                let windowRecovery = data.recovery.filter { $0.key >= data.analysis.from && $0.key <= data.analysis.to }
                buckets = BehaviorImpact.buckets(amounts: windowAmounts, noDays: windowAnswers.no,
                                                 recoveryByDay: windowRecovery, edges: edges)
                    .map { b in
                        let label = followUp?.bucketLabel(lower: b.lower, upper: b.upper)
                            ?? PulseBehaviorFollowUp.custom(unit: nil).bucketLabel(lower: b.lower, upper: b.upper)
                        return BehaviorDetailsSnapshot.BucketRow(id: "\(b.lower)", label: label, impact: b.impactPercent,
                                                                 significant: b.isSignificant, days: b.days)
                    }
            }
        }
        let unlockedImpacts = data.analysis.unlocked.compactMap(\.impactPercent)
        return BehaviorDetailsSnapshot(
            seq: r.seq, row: row, breakdownTitle: breakdownTitle, buckets: buckets,
            yesDays: isAuto ? [] : answers.yes, noDays: isAuto ? [] : answers.no,
            scale: BehaviorImpact.barScale(unlockedImpacts), today: r.day.key,
            question: data.questions[identity])
    }
}

extension PulseBehaviorLibrary {
    /// The key one behaviour is grouped under, whichever question it was stored as: the library behaviour
    /// it matches ("lib.alcohol" for both "Did you drink any alcohol?" and an imported "Have any alcoholic
    /// drinks?"), else the question's normalised text.
    static func identity(for question: String) -> String {
        if let d = definition(for: question) { return "lib.\(d.id)" }
        return "q." + JournalCatalogStore.norm(question)
    }
}
#endif
