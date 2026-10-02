import XCTest
@testable import StrandAnalytics

final class RecoveryBehaviorChipsTests: XCTestCase {

    private typealias Answer = RecoveryBehaviorChips.Answer

    private let today = "2026-09-30"

    /// The `count` days before `today`, oldest first.
    private func pastDays(_ count: Int) -> [String] {
        PulseDisplay.trailingDayKeys(endingOn: PulseDisplay.dayKey(today, offsetBy: -1)!, count: count)
    }

    /// 40 past days: "Alcohol" yes on every other day, with Recovery ~40 on those days and ~70 on the
    /// others (a little spread on both sides), so the split is unmistakable.
    private func history() -> (answers: [Answer], recovery: [String: Double]) {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(40).enumerated() {
            let drank = i % 2 == 0
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: drank))
            recovery[day] = (drank ? 40 : 70) + Double(i % 5)
        }
        return (answers, recovery)
    }

    func testABehaviourThatHurtsReadsHurtsWhenLoggedForTheDay() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        recovery[today] = 41
        let chips = RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today)
        XCTAssertEqual(chips.count, 1)
        XCTAssertEqual(chips.first?.behavior, "Alcohol")
        XCTAssertEqual(chips.first?.effect, .hurts)
        XCTAssertLessThan(chips.first?.impactPercent ?? 0, 0)
    }

    func testANoForTheDayMakesNoChip() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: false))
        recovery[today] = 71
        XCTAssertTrue(RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today).isEmpty)
    }

    func testTheLaterAnswerForADayWins() {
        var (answers, recovery) = history()
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: false))
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        recovery[today] = 41
        XCTAssertEqual(RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today).count, 1)
    }

    func testNothingUntilTheHistoryHoldsTenRecoveries() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(9).enumerated() {
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: i % 2 == 0))
            recovery[day] = i % 2 == 0 ? 40 : 70
        }
        answers.append(Answer(day: today, behavior: "Alcohol", answeredYes: true))
        XCTAssertTrue(RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today).isEmpty)
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
        XCTAssertTrue(RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today).isEmpty)
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
        let chips = RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today)
        XCTAssertEqual(chips.map(\.effect), [.notSignificant])
    }

    func testTheDayItselfIsLeftOutOfTheTest() {
        // The past alone shows no effect; only a wildly different Recovery TODAY could create one, and
        // the day is excluded, so the chip stays grey.
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(20).enumerated() {
            answers.append(Answer(day: day, behavior: "Magnesium", answeredYes: i % 2 == 0))
            recovery[day] = 60 + Double((i / 2) % 4)
        }
        answers.append(Answer(day: today, behavior: "Magnesium", answeredYes: true))
        recovery[today] = 99
        let chips = RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today)
        XCTAssertEqual(chips.map(\.effect), [.notSignificant])
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
        XCTAssertTrue(RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today).isEmpty)
    }

    func testHelpsComeFirstThenHurtsThenGrey() {
        var answers: [Answer] = []
        var recovery: [String: Double] = [:]
        for (i, day) in pastDays(40).enumerated() {
            let even = i % 2 == 0
            // "Read before bed" on the high days, "Alcohol" on the low ones, "Sauna" unrelated.
            answers.append(Answer(day: day, behavior: "Read before bed", answeredYes: !even))
            answers.append(Answer(day: day, behavior: "Alcohol", answeredYes: even))
            answers.append(Answer(day: day, behavior: "Sauna", answeredYes: (i / 2) % 2 == 0))
            recovery[day] = (even ? 40 : 70) + Double(i % 5)
        }
        for behavior in ["Sauna", "Alcohol", "Read before bed"] {
            answers.append(Answer(day: today, behavior: behavior, answeredYes: true))
        }
        let chips = RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recovery, dayKey: today)
        XCTAssertEqual(chips.map(\.behavior), ["Read before bed", "Alcohol", "Sauna"])
        XCTAssertEqual(chips.map(\.effect), [.helps, .hurts, .notSignificant])
    }
}
