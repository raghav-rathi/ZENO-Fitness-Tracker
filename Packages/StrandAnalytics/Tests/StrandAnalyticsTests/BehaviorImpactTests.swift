import XCTest
@testable import StrandAnalytics

final class BehaviorImpactTests: XCTestCase {

    /// `count` consecutive day keys ending on `end`, oldest first.
    private func days(endingOn end: String, count: Int) -> [String] {
        PulseDisplay.trailingDayKeys(endingOn: end, count: count)
    }

    /// Recovery that is `with` on `yesDays` and `without` elsewhere, with a little alternating spread so
    /// the groups have variance.
    private func recovery(_ keys: [String], yesDays: Set<String>, with: Double, without: Double) -> [String: Double] {
        var out: [String: Double] = [:]
        for (i, k) in keys.enumerated() {
            let wobble = i % 2 == 0 ? 2.0 : -2.0
            out[k] = (yesDays.contains(k) ? with : without) + wobble
        }
        return out
    }

    // MARK: - Unlock gate

    func testEverythingIsLockedUntilTenRecoveries() {
        let keys = days(endingOn: "2026-10-02", count: 9)
        let rec = Dictionary(uniqueKeysWithValues: keys.map { ($0, 60.0) })
        let answers = ["Alcohol": BehaviorImpact.Answers(yes: Set(keys.prefix(5)), no: Set(keys.suffix(4)))]
        let a = BehaviorImpact.analyze(answers: answers, recoveryByDay: rec, today: "2026-10-02")
        XCTAssertTrue(a.isCalibrating)
        XCTAssertEqual(a.recoveries, 9)
        XCTAssertTrue(a.unlocked.isEmpty)
        XCTAssertEqual(a.locked.first?.lock, .calibrating)
        XCTAssertEqual(a.locked.first?.yesCount, 5)
        XCTAssertEqual(a.locked.first?.noCount, 4)
    }

    // MARK: - Tested behaviours

    func testAStrongEffectIsTestedAndSignificant() {
        let keys = days(endingOn: "2026-10-02", count: 40)
        let yes = Set(keys.enumerated().filter { $0.offset % 4 == 0 }.map(\.element))   // 10 days
        let no = Set(keys).subtracting(yes)                                              // 30 days
        let rec = recovery(keys, yesDays: yes, with: 50, without: 70)
        let a = BehaviorImpact.analyze(answers: ["Alcohol": .init(yes: yes, no: no)], recoveryByDay: rec,
                                       today: "2026-10-02")
        XCTAssertFalse(a.isCalibrating)
        XCTAssertEqual(a.unlocked.count, 1)
        let row = try! XCTUnwrap(a.unlocked.first)
        XCTAssertEqual(row.yesCount, 10)
        XCTAssertEqual(row.noCount, 30)
        XCTAssertTrue(row.isSignificant)
        // Yes-days all fall on the +2 wobble (mean 52); the no-days average 69.33: (52 − 69.33) / 69.33.
        XCTAssertEqual(row.impactPercent!, -25.0, accuracy: 0.01)
        XCTAssertEqual(row.effect!.meanWith, 52, accuracy: 1e-9)
    }

    func testFewerThanFiveAnswersOnASideStaysLocked() {
        let keys = days(endingOn: "2026-10-02", count: 30)
        let yes = Set(keys.prefix(4))
        let no = Set(keys.suffix(20))
        let rec = recovery(keys, yesDays: yes, with: 50, without: 70)
        let a = BehaviorImpact.analyze(answers: ["Sauna": .init(yes: yes, no: no)], recoveryByDay: rec,
                                       today: "2026-10-02")
        XCTAssertTrue(a.unlocked.isEmpty)
        XCTAssertEqual(a.locked.first?.lock, .needsAnswers)
        XCTAssertEqual(a.locked.first?.yesCount, 4)
    }

    func testAnswersWithoutRecoveriesAreNotEnough() {
        let keys = days(endingOn: "2026-10-02", count: 30)
        let yes = Set(keys.prefix(8))
        let no = Set(keys.suffix(8))
        // Recoveries exist on most days, but on only three of the yes days.
        var rec = recovery(keys, yesDays: yes, with: 50, without: 70)
        for k in keys.prefix(8).dropFirst(3) { rec[k] = nil }
        let a = BehaviorImpact.analyze(answers: ["Late Meal": .init(yes: yes, no: no)], recoveryByDay: rec,
                                       today: "2026-10-02")
        XCTAssertTrue(a.unlocked.isEmpty)
        XCTAssertEqual(a.locked.first?.lock, .needsRecoveryDays)
    }

    func testAnswersOutsideTheNinetyDayWindowAreIgnored() {
        let recent = days(endingOn: "2026-10-02", count: 30)
        let old = days(endingOn: "2026-06-01", count: 30)        // more than 90 days back
        let yes = Set(old.prefix(10)).union(recent.prefix(3))
        let no = Set(old.suffix(10)).union(recent.suffix(10))
        let rec = recovery(old + recent, yesDays: yes, with: 50, without: 70)
        let a = BehaviorImpact.analyze(answers: ["Stress": .init(yes: yes, no: no)], recoveryByDay: rec,
                                       today: "2026-10-02")
        XCTAssertEqual(a.from, "2026-07-05")
        XCTAssertEqual(a.locked.first?.yesCount, 3)
        XCTAssertEqual(a.locked.first?.noCount, 10)
        XCTAssertEqual(a.locked.first?.lock, .needsAnswers)
    }

    func testABehaviourWithNoAnswersIsStillListed() {
        let keys = days(endingOn: "2026-10-02", count: 20)
        let rec = Dictionary(uniqueKeysWithValues: keys.map { ($0, 60.0) })
        let a = BehaviorImpact.analyze(answers: ["Magnesium": .init()], recoveryByDay: rec, today: "2026-10-02")
        XCTAssertEqual(a.locked.map(\.behavior), ["Magnesium"])
        XCTAssertEqual(a.locked.first?.yesCount, 0)
    }

    // MARK: - Order and scale

    private func row(_ name: String, _ pct: Double, significant: Bool) -> BehaviorImpact.Row {
        let e = BehaviorEffect(behavior: name, outcome: "Recovery", meanWith: 60 + pct / 2, meanWithout: 60,
                               delta: pct / 2, pctChange: pct, nWith: 10, nWithout: 10, cohensD: pct / 10,
                               pApprox: significant ? 0.001 : 0.5, significant: significant, qValue: nil)
        return BehaviorImpact.Row(behavior: name, yesCount: 10, noCount: 10, effect: e, lock: nil)
    }

    func testDisplayOrderIsPositivesThenGreyThenNegatives() {
        let rows = [row("Herbal Tea", -5, significant: true), row("Caffeine", 2, significant: false),
                    row("Sleep In Own Bed", 6, significant: true), row("Stress", -3, significant: true),
                    row("Consistent Wake Time", -2, significant: false), row("Sleep Performance", 8, significant: true)]
        XCTAssertEqual(BehaviorImpact.displayOrder(rows).map(\.behavior),
                       ["Sleep Performance", "Sleep In Own Bed", "Caffeine", "Consistent Wake Time", "Stress",
                        "Herbal Tea"])
    }

    func testBarScaleHasAFloor() {
        XCTAssertEqual(BehaviorImpact.barScale([2, -1]), 10)
        XCTAssertEqual(BehaviorImpact.barScale([2, -17]), 17)
        XCTAssertEqual(BehaviorImpact.barScale([]), 10)
    }

    // MARK: - Buckets

    func testBucketsMeasureEachAmountRangeAgainstTheNoDays() {
        let keys = days(endingOn: "2026-10-02", count: 60)
        var amounts: [String: Double] = [:]
        var rec: [String: Double] = [:]
        var no = Set<String>()
        for (i, k) in keys.enumerated() {
            let wobble = i % 2 == 0 ? 1.5 : -1.5
            switch i % 3 {
            case 0: amounts[k] = 1; rec[k] = 68 + wobble          // one drink: near baseline
            case 1: amounts[k] = 4; rec[k] = 55 + wobble          // several: clearly lower
            default: no.insert(k); rec[k] = 70 + wobble
            }
        }
        let b = BehaviorImpact.buckets(amounts: amounts, noDays: no, recoveryByDay: rec, edges: [1, 2])
        XCTAssertEqual(b.count, 2)
        XCTAssertEqual(b[0].lower, 1)
        XCTAssertEqual(b[0].upper, 2)
        XCTAssertNil(b[1].upper)
        XCTAssertEqual(b[0].days, 20)
        XCTAssertEqual(b[1].days, 20)
        XCTAssertEqual(b[1].impactPercent!, (55.0 - 70.0) / 70.0 * 100, accuracy: 0.5)
        XCTAssertTrue(b[1].isSignificant)
        XCTAssertTrue(b[1].contains(6))
        XCTAssertFalse(b[0].contains(2))
    }

    func testASparseBucketIsNotTested() {
        let keys = days(endingOn: "2026-10-02", count: 30)
        var amounts: [String: Double] = [:]
        var no = Set<String>()
        for (i, k) in keys.enumerated() {
            if i < 3 { amounts[k] = 5 } else if i < 12 { amounts[k] = 1 } else { no.insert(k) }
        }
        let rec = Dictionary(uniqueKeysWithValues: keys.enumerated().map { ($1, 60.0 + Double($0 % 5)) })
        let b = BehaviorImpact.buckets(amounts: amounts, noDays: no, recoveryByDay: rec, edges: [1, 2])
        XCTAssertNotNil(b[0].effect)
        XCTAssertNil(b[1].effect)
        XCTAssertEqual(b[1].days, 3)
    }

    func testMedianEdges() {
        XCTAssertEqual(BehaviorImpact.medianEdges([100, 200, 300, 400]), [100, 250])
        XCTAssertEqual(BehaviorImpact.medianEdges([1, 1, 1, 5]), [1, 5])
        XCTAssertEqual(BehaviorImpact.medianEdges([3, 3]), [])
        XCTAssertEqual(BehaviorImpact.medianEdges([]), [])
    }

    // MARK: - Logging history

    func testMonthMarksAndCounts() {
        let m = BehaviorLoggingHistory.month(year: 2026, month: 10, yes: ["2026-10-01"], no: ["2026-10-02"],
                                             today: "2026-10-03")
        XCTAssertEqual(m.marks.count, 31)
        XCTAssertEqual(m.leadingBlanks, 4)            // 1 Oct 2026 is a Thursday
        XCTAssertEqual(m.marks[0], .yes)
        XCTAssertEqual(m.marks[1], .no)
        XCTAssertEqual(m.marks[2], .missing)
        XCTAssertEqual(m.marks[3], .future)
        XCTAssertEqual(m.yesCount, 1)
        XCTAssertEqual(m.noCount, 1)
        XCTAssertEqual(m.missingCount, 1)
    }

    func testCalendarArithmetic() {
        XCTAssertEqual(BehaviorLoggingHistory.daysIn(year: 2028, month: 2), 29)
        XCTAssertEqual(BehaviorLoggingHistory.daysIn(year: 2100, month: 2), 28)
        XCTAssertEqual(BehaviorLoggingHistory.daysIn(year: 2026, month: 4), 30)
        XCTAssertEqual(BehaviorLoggingHistory.weekdayOfFirst(year: 2026, month: 3), 0)   // Sunday
        XCTAssertEqual(BehaviorLoggingHistory.weekdayOfFirst(year: 2026, month: 5), 5)   // Friday
        XCTAssertEqual(BehaviorLoggingHistory.weekdayOfFirst(year: 2000, month: 1), 6)   // Saturday
        let months = BehaviorLoggingHistory.months(endingAt: "2026-01-15", count: 3)
        XCTAssertEqual(months.map(\.year), [2025, 2025, 2026])
        XCTAssertEqual(months.map(\.month), [11, 12, 1])
        let back = BehaviorLoggingHistory.months(endingAt: "2026-05-04", count: 3, pagesBack: 1)
        XCTAssertEqual(back.map(\.month), [12, 1, 2])
        XCTAssertEqual(back.map(\.year), [2025, 2026, 2026])
    }
}
