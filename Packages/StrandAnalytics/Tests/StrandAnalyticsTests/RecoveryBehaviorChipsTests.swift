import XCTest
@testable import StrandAnalytics

final class RecoveryBehaviorChipsTests: XCTestCase {

    private typealias Answer = RecoveryBehaviorChips.Answer

    private let today = "2026-09-30"

    /// The `count` days before `today`, oldest first.
    private func pastDays(_ count: Int) -> [String] {
        PulseDisplay.trailingDayKeys(endingOn: PulseDisplay.dayKey(today, offsetBy: -1)!, count: count)
    }

    /// A fixed pseudo-random sequence in [0, 1) (a 64-bit LCG), so the tests' noise is the same on every
    /// run and every platform.
    private struct Noise {
        var state: UInt64
        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 11) / Double(UInt64(1) << 53)
        }
    }

    private func chips(_ answers: [Answer], recovery: [String: Double]) -> [RecoveryBehaviorChips.Chip] {
        RecoveryBehaviorChips.chips(answers: answers, outcomes: ["recovery": recovery], dayKey: today)
    }

    /// 40 past days: "Alcohol" yes on about half of them at random, with Recovery ~40 on those days and
    /// ~70 on the others (a little spread on both sides), so the split is unmistakable. The days are drawn
    /// at random rather than alternated: a periodic pattern would put the same split at a one- or two-day
    /// lag too, and the lag-aware ranking would be free to pick it.
    private func history() -> (answers: [Answer], recovery: [String: Double]) {
        var noise = Noise(state: 3)
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for day in pastDays(40) {
            let drank = noise.next() < 0.5
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: drank))
            recovery[day] = (drank ? 40 : 70) + noise.next() * 5
        }
        return (answers, recovery)
    }

    /// 60 past days of noise around a behaviour answered at random, plus HRV, resting heart rate and
    /// Sleep Performance series unrelated to it: the four outcomes the Insights hub ranks. Recovery is
    /// `effect` lower on the behaviour's yes days. Today is a "yes" with a Recovery of 50.
    private func noisyHistory(seed: UInt64, effect: Double)
        -> (answers: [Answer], outcomes: [String: [String: Double]]) {
        var noise = Noise(state: seed)
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        var hrv: [String: Double] = [:]
        var rhr: [String: Double] = [:]
        var sleep: [String: Double] = [:]
        for day in pastDays(60) {
            let yes = noise.next() < 0.5
            answers.append(Answer(day: day, behavior: "Late meal", answeredYes: yes))
            recovery[day] = 60 + (noise.next() - 0.5) * 30 - (yes ? effect : 0)
            hrv[day] = 70 + (noise.next() - 0.5) * 30
            rhr[day] = 55 + (noise.next() - 0.5) * 8
            sleep[day] = 80 + (noise.next() - 0.5) * 20
        }
        answers.append(Answer(day: today, behavior: "Late meal", answeredYes: true))
        recovery[today] = 50
        return (answers, ["recovery": recovery, "hrv": hrv, "rhr": rhr, "sleep_performance": sleep])
    }

    /// The yes and no day sets the hub builds from the same answers.
    private func split(_ answers: [Answer]) -> (yes: [String: Set<String>], no: [String: Set<String>]) {
        var yes: [String: Set<String>] = [:]
        var no: [String: Set<String>] = [:]
        for a in answers {
            if a.answeredYes { yes[a.behavior, default: []].insert(a.day) } else { no[a.behavior, default: []].insert(a.day) }
        }
        return (yes, no)
    }

    func testABehaviourThatHurtsReadsHurtsWhenLoggedForTheDay() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        recovery[today] = 41
        let chips = chips(answers, recovery: recovery)
        XCTAssertEqual(chips.count, 1)
        XCTAssertEqual(chips.first?.behavior, "Alcohol")
        XCTAssertEqual(chips.first?.effect, .hurts)
        XCTAssertLessThan(chips.first?.impactPercent ?? 0, 0)
    }

    func testANoForTheDayMakesNoChip() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: false))
        recovery[today] = 71
        XCTAssertTrue(chips(answers, recovery: recovery).isEmpty)
    }

    func testTheLaterAnswerForADayWins() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: false))
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        recovery[today] = 41
        XCTAssertEqual(chips(answers, recovery: recovery).count, 1)
    }

    func testNothingUntilTheHistoryHoldsTenRecoveries() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(9).enumerated() {
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: i % 2 == 0))
            recovery[day] = i % 2 == 0 ? 40 : 70
        }
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        XCTAssertTrue(chips(answers, recovery: recovery).isEmpty)
    }

    func testABehaviourWithFewerThanFiveNoAnswersIsStillLocked() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(30).enumerated() {
            // 26 yes, 4 no: below the 5-and-5 rule.
            answers.append(Answer(day: day, behavior: "Read before bed", answeredYes: i >= 4))
            recovery[day] = i >= 4 ? 75 + Double(i % 3) : 40
        }
        answers.append(Answer(day: today, behavior: "Read before bed", answeredYes: true))
        XCTAssertTrue(chips(answers, recovery: recovery).isEmpty)
    }

    func testAnUnlockedBehaviourWithNoClearEffectIsGrey() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(40).enumerated() {
            // Yes and no days drawn from the same Recovery pattern.
            answers.append(Answer(day: day, behavior: "Sauna", answeredYes: i % 2 == 0))
            recovery[day] = 50 + Double((i / 2) % 7) * 3
        }
        answers.append(Answer(day: today, behavior: "Sauna", answeredYes: true))
        XCTAssertEqual(chips(answers, recovery: recovery).map(\.effect), [.notSignificant])
    }

    func testAnswersOlderThanTheWindowDoNotUnlockABehaviour() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        // Plenty of Recoveries in the window, but the behaviour was only answered 100+ days ago.
        for day in pastDays(30) { recovery[day] = 60 }
        let old = PulseDisplay.trailingDayKeys(endingOn: PulseDisplay.dayKey(today, offsetBy: -100)!, count: 20)
        for (i, day) in old.enumerated() {
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: i % 2 == 0))
            recovery[day] = i % 2 == 0 ? 40 : 70
        }
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        XCTAssertTrue(chips(answers, recovery: recovery).isEmpty)
    }

    func testHelpsComeFirstThenHurtsThenGrey() {
        var noise = Noise(state: 5)
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for day in pastDays(60) {
            // "Read before bed" lifts Recovery, "Alcohol" lowers it, "Sauna" is unrelated.
            let read = noise.next() < 0.5
            let drank = noise.next() < 0.5
            answers.append(Answer(day: day, behavior: "Read before bed", answeredYes: read))
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: drank))
            answers.append(Answer(day: day, behavior: "Sauna", answeredYes: noise.next() < 0.5))
            recovery[day] = 55 + (read ? 15 : 0) - (drank ? 15 : 0) + noise.next() * 6
        }
        for behavior in ["Sauna", "Alcohol", "Read before bed"] {
            answers.append(Answer(day: today, behavior: behavior, answeredYes: true))
        }
        let chips = chips(answers, recovery: recovery)
        XCTAssertEqual(chips.map(\.behavior), ["Read before bed", "Alcohol", "Sauna"])
        XCTAssertEqual(chips.map(\.effect), [.helps, .hurts, .notSignificant])
    }

    // MARK: One resolver with the Insights hub

    /// Each chip states the Recovery row of the hub's own ranking (EffectRanker over every answer and the
    /// four outcomes), for every behaviour logged on the day.
    func testEveryChipStatesTheInsightsHubVerdict() {
        var noise = Noise(state: 42)
        var answers: [Answer] = []
        var outcomes: [String: [String: Double]] = ["recovery": [:], "hrv": [:], "rhr": [:], "sleep_performance": [:]]
        let behaviors = ["Alcohol", "Sauna", "Late meal", "Read before bed"]
        for day in pastDays(80) + [today] {
            var recovery = 60 + (noise.next() - 0.5) * 20
            for (i, behavior) in behaviors.enumerated() {
                let yes = day == today || noise.next() < 0.4
                answers.append(Answer(day: day, behavior: behavior, answeredYes: yes))
                // Alcohol hurts, reading helps, the others do nothing.
                if yes && i == 0 { recovery -= 15 }
                if yes && i == 3 { recovery += 12 }
            }
            outcomes["recovery"]?[day] = recovery
            outcomes["hrv"]?[day] = 70 + (noise.next() - 0.5) * 30
            outcomes["rhr"]?[day] = 55 + (noise.next() - 0.5) * 8
            outcomes["sleep_performance"]?[day] = 80 + (noise.next() - 0.5) * 20
        }
        let chips = RecoveryBehaviorChips.chips(answers: answers, outcomes: outcomes, dayKey: today)
        XCTAssertEqual(Set(chips.map(\.behavior)), Set(behaviors))

        let sets = split(answers)
        let hub = EffectRanker.rankAll(behaviors: sets.yes, controls: sets.no, outcomes: outcomes)["recovery"] ?? []
        for chip in chips {
            guard let row = hub.first(where: { $0.behavior == chip.behavior }) else {
                return XCTFail("The hub has no Recovery row for \(chip.behavior)")
            }
            let expected: RecoveryBehaviorChips.Chip.Effect = !row.effect.significant || row.effect.delta == 0
                ? .notSignificant : (row.effect.delta > 0 ? .helps : .hurts)
            XCTAssertEqual(chip.effect, expected, chip.behavior)
            XCTAssertEqual(chip.impactPercent ?? .nan, row.effect.pctChange ?? .nan, accuracy: 1e-9, chip.behavior)
        }
        XCTAssertEqual(chips.first(where: { $0.behavior == "Alcohol" })?.effect, .hurts)
        XCTAssertEqual(chips.first(where: { $0.behavior == "Read before bed" })?.effect, .helps)
    }

    /// The other outcomes' tests are part of the correction, as on the hub: an effect that would clear the
    /// false-discovery bar if Recovery were tested alone does not clear it in the hub's family, and the
    /// chip follows the hub.
    func testTheHubsOtherOutcomesEnterTheCorrection() {
        let (answers, outcomes) = noisyHistory(seed: 4, effect: 8)
        let sets = split(answers)
        let alone = EffectRanker.rankAll(behaviors: sets.yes, controls: sets.no,
                                         outcomes: ["recovery": outcomes["recovery"] ?? [:]])["recovery"]?.first
        XCTAssertEqual(alone?.effect.significant, true, "precondition: Recovery alone clears the bar")
        XCTAssertLessThan(alone?.effect.delta ?? 0, 0)

        XCTAssertEqual(RecoveryBehaviorChips.chips(answers: answers, outcomes: outcomes, dayKey: today).map(\.effect),
                       [.notSignificant])
        // Ranked against Recovery alone it would have read "hurts": the family is what differs.
        XCTAssertEqual(RecoveryBehaviorChips.chips(answers: answers, outcomes: ["recovery": outcomes["recovery"] ?? [:]],
                                                   dayKey: today).map(\.effect),
                       [.hurts])
    }

    /// Keys other than the hub's four do not enter the family.
    func testOutcomesOutsideTheHubsSetAreIgnored() {
        let (answers, outcomes) = noisyHistory(seed: 4, effect: 8)
        var noise = Noise(state: 7)
        var widened = outcomes
        widened["steps"] = Dictionary(uniqueKeysWithValues: pastDays(60).map { ($0, 8000 + noise.next() * 4000) })
        XCTAssertEqual(RecoveryBehaviorChips.chips(answers: answers, outcomes: widened, dayKey: today),
                       RecoveryBehaviorChips.chips(answers: answers, outcomes: outcomes, dayKey: today))
    }

    /// The hub keeps the lag with the largest effect; a behaviour whose Recovery effect shows the morning
    /// after (lag +1) and not on its own day still reads as it does on the hub.
    func testAnEffectTheHubFindsTheNextMorningColoursTheChip() {
        // Yes, yes, no, no, …: Recovery is low on each day after a yes, so the yes days themselves split
        // evenly between low and high (no same-day effect) and the next mornings are all low.
        var noise = Noise(state: 11)
        let days = pastDays(48)
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in days.enumerated() {
            answers.append(Answer(day: day, behavior: "Felt stressed", answeredYes: i % 4 < 2))
            let afterYes = i > 0 && (i - 1) % 4 < 2
            recovery[day] = (afterYes ? 45 : 70) + (noise.next() - 0.5) * 6
        }
        answers.append(Answer(day: today, behavior: "Felt stressed", answeredYes: true))
        recovery[today] = 60

        let sets = split(answers)
        let row = EffectRanker.rankAll(behaviors: sets.yes, controls: sets.no,
                                       outcomes: ["recovery": recovery])["recovery"]?.first
        XCTAssertEqual(row?.lag, 1, "precondition: the hub finds the effect the next morning")
        XCTAssertEqual(chips(answers, recovery: recovery).map(\.effect), [.hurts])
    }
}
