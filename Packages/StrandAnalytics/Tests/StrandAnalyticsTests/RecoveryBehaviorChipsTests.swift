import XCTest
@testable import StrandAnalytics

final class RecoveryBehaviorChipsTests: XCTestCase {

    private typealias Answers = BehaviorImpact.Answers

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

    /// The chips for `today`, from the analysis Behavior Insights builds over the same answers.
    private func chips(_ answers: [String: Answers], recovery: [String: Double]) -> [RecoveryBehaviorChips.Chip] {
        let analysis = BehaviorImpact.analyze(answers: answers, recoveryByDay: recovery, today: today)
        return RecoveryBehaviorChips.chips(analysis: analysis, answers: answers, dayKey: today)
    }

    /// 40 past days: "lib.alcohol" yes on about half of them at random, with Recovery ~40 on those days and
    /// ~70 on the others (a little spread on both sides), so the split is unmistakable.
    private func history() -> (answers: [String: Answers], recovery: [String: Double]) {
        var noise = Noise(state: 3)
        var alcohol = Answers()
        var recovery: [String: Double] = [:]
        for day in pastDays(40) {
            let drank = noise.next() < 0.5
            if drank { alcohol.yes.insert(day) } else { alcohol.no.insert(day) }
            recovery[day] = (drank ? 40 : 70) + noise.next() * 5
        }
        return (["lib.alcohol": alcohol], recovery)
    }

    func testABehaviourThatHurtsReadsHurtsWhenLoggedForTheDay() {
        var (answers, recovery) = history()
        answers["lib.alcohol"]?.yes.insert(today)
        recovery[today] = 41
        let chips = chips(answers, recovery: recovery)
        XCTAssertEqual(chips.count, 1)
        XCTAssertEqual(chips.first?.behavior, "lib.alcohol")
        XCTAssertEqual(chips.first?.effect, .hurts)
        XCTAssertLessThan(chips.first?.impactPercent ?? 0, 0)
    }

    func testANoForTheDayMakesNoChip() {
        var (answers, recovery) = history()
        answers["lib.alcohol"]?.no.insert(today)
        recovery[today] = 71
        XCTAssertTrue(chips(answers, recovery: recovery).isEmpty)
    }

    func testNothingUntilTheHistoryHoldsTenRecoveries() {
        var alcohol = Answers()
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(9).enumerated() {
            if i % 2 == 0 { alcohol.yes.insert(day) } else { alcohol.no.insert(day) }
            recovery[day] = i % 2 == 0 ? 40 : 70
        }
        alcohol.yes.insert(today)
        XCTAssertTrue(chips(["lib.alcohol": alcohol], recovery: recovery).isEmpty)
    }

    func testABehaviourWithFewerThanFiveNoAnswersIsStillLocked() {
        var read = Answers()
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(30).enumerated() {
            // 26 yes, 4 no: below the 5-and-5 rule.
            if i >= 4 { read.yes.insert(day) } else { read.no.insert(day) }
            recovery[day] = i >= 4 ? 75 + Double(i % 3) : 40
        }
        read.yes.insert(today)
        XCTAssertTrue(chips(["lib.readBeforeBed": read], recovery: recovery).isEmpty)
    }

    func testAnUnlockedBehaviourWithNoClearEffectIsGrey() {
        var sauna = Answers()
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(40).enumerated() {
            // Yes and no days drawn from the same Recovery pattern.
            if i % 2 == 0 { sauna.yes.insert(day) } else { sauna.no.insert(day) }
            recovery[day] = 50 + Double((i / 2) % 7) * 3
        }
        sauna.yes.insert(today)
        XCTAssertEqual(chips(["lib.sauna": sauna], recovery: recovery).map(\.effect), [.notSignificant])
    }

    func testAnswersOlderThanTheWindowDoNotUnlockABehaviour() {
        var alcohol = Answers()
        var recovery: [String: Double] = [:]
        // Plenty of Recoveries in the window, but the behaviour was only answered 100+ days ago.
        for day in pastDays(30) { recovery[day] = 60 }
        let old = PulseDisplay.trailingDayKeys(endingOn: PulseDisplay.dayKey(today, offsetBy: -100)!, count: 20)
        for (i, day) in old.enumerated() {
            if i % 2 == 0 { alcohol.yes.insert(day) } else { alcohol.no.insert(day) }
            recovery[day] = i % 2 == 0 ? 40 : 70
        }
        alcohol.yes.insert(today)
        XCTAssertTrue(chips(["lib.alcohol": alcohol], recovery: recovery).isEmpty)
    }

    func testHelpsComeFirstThenHurtsThenGrey() {
        var noise = Noise(state: 5)
        var answers: [String: Answers] = ["lib.readBeforeBed": Answers(), "lib.alcohol": Answers(),
                                          "lib.sauna": Answers()]
        var recovery: [String: Double] = [:]
        for day in pastDays(60) {
            // Reading lifts Recovery, alcohol lowers it, the sauna is unrelated.
            let read = noise.next() < 0.5
            let drank = noise.next() < 0.5
            let sauna = noise.next() < 0.5
            for (id, yes) in [("lib.readBeforeBed", read), ("lib.alcohol", drank), ("lib.sauna", sauna)] {
                if yes { answers[id]?.yes.insert(day) } else { answers[id]?.no.insert(day) }
            }
            recovery[day] = 55 + (read ? 15 : 0) - (drank ? 15 : 0) + noise.next() * 6
        }
        for id in ["lib.sauna", "lib.alcohol", "lib.readBeforeBed"] { answers[id]?.yes.insert(today) }
        let chips = chips(answers, recovery: recovery)
        XCTAssertEqual(chips.map(\.behavior), ["lib.readBeforeBed", "lib.alcohol", "lib.sauna"])
        XCTAssertEqual(chips.map(\.effect), [.helps, .hurts, .notSignificant])
    }

    /// An auto-tracked behaviour the page tests makes a chip like a journal one, keyed by its own id.
    func testAnAutoTrackedBehaviourMakesAChip() {
        var noise = Noise(state: 9)
        var sleep = Answers()
        var recovery: [String: Double] = [:]
        for day in pastDays(50) {
            let good = noise.next() < 0.5
            if good { sleep.yes.insert(day) } else { sleep.no.insert(day) }
            recovery[day] = (good ? 72 : 48) + noise.next() * 6
        }
        sleep.yes.insert(today)
        let chips = chips(["auto.sleepPerformance": sleep], recovery: recovery)
        XCTAssertEqual(chips.map(\.behavior), ["auto.sleepPerformance"])
        XCTAssertEqual(chips.map(\.effect), [.helps])
    }

    // MARK: One resolver with Behavior Insights

    /// Each chip states the page's own row for its behaviour: the same tested behaviours, the same impact
    /// and the colour the page draws (`verdict`), for every behaviour logged YES on the day.
    func testEveryChipStatesThePageVerdict() {
        var noise = Noise(state: 42)
        let behaviors = ["lib.alcohol", "lib.sauna", "lib.lateMeal", "lib.readBeforeBed", "auto.lateWorkout"]
        var answers: [String: Answers] = [:]
        var recovery: [String: Double] = [:]
        for day in pastDays(80) + [today] {
            var value = 60 + (noise.next() - 0.5) * 20
            for (i, behavior) in behaviors.enumerated() {
                // Every behaviour but the last is answered YES today; the last one NO.
                let yes = day == today ? i < behaviors.count - 1 : noise.next() < 0.4
                if yes { answers[behavior, default: Answers()].yes.insert(day) } else {
                    answers[behavior, default: Answers()].no.insert(day)
                }
                // Alcohol hurts, reading helps, the others do nothing.
                if yes && i == 0 { value -= 15 }
                if yes && i == 3 { value += 12 }
            }
            recovery[day] = value
        }
        let analysis = BehaviorImpact.analyze(answers: answers, recoveryByDay: recovery, today: today)
        let chips = RecoveryBehaviorChips.chips(analysis: analysis, answers: answers, dayKey: today)
        let expected = analysis.unlocked.filter { answers[$0.behavior]?.yes.contains(today) == true }
        XCTAssertEqual(Set(chips.map(\.behavior)), Set(expected.map(\.behavior)))
        XCTAssertFalse(chips.contains { $0.behavior == "auto.lateWorkout" }, "a NO today makes no chip")
        for chip in chips {
            guard let row = analysis.unlocked.first(where: { $0.behavior == chip.behavior }) else {
                return XCTFail("The page has no row for \(chip.behavior)")
            }
            XCTAssertEqual(chip.effect, RecoveryBehaviorChips.verdict(impactPercent: row.impactPercent,
                                                                      significant: row.isSignificant), chip.behavior)
            XCTAssertEqual(chip.impactPercent ?? .nan, row.impactPercent ?? .nan, accuracy: 1e-9, chip.behavior)
        }
        XCTAssertEqual(chips.first(where: { $0.behavior == "lib.alcohol" })?.effect, .hurts)
        XCTAssertEqual(chips.first(where: { $0.behavior == "lib.readBeforeBed" })?.effect, .helps)
    }

    /// The page's colour rule: a significant effect that prints as 0% is grey, like one that is not
    /// significant; anything else follows its sign.
    func testTheVerdictIsThePagesColourRule() {
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: 12, significant: true), .helps)
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: -0.6, significant: true), .hurts)
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: 0.4, significant: true), .notSignificant)
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: -12, significant: false), .notSignificant)
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: nil, significant: true), .notSignificant)
        XCTAssertEqual(RecoveryBehaviorChips.verdict(impactPercent: .nan, significant: true), .notSignificant)
    }
}
