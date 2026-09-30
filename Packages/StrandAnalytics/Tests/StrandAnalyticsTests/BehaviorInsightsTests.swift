import XCTest
@testable import StrandAnalytics

final class BehaviorInsightsTests: XCTestCase {

    // MARK: - effect core computation

    func testEffectMeansDeltaAndSign() {
        // With-days outcome mean 60.5, without-days mean 70.125 → delta -9.625,
        // pct ≈ -13.7255%. Behavior lowers the outcome → negative delta & cohensD.
        let outcome: [String: Double] = [
            "d01": 60, "d02": 62, "d03": 58, "d04": 61, "d05": 59, "d06": 63,   // with
            "d07": 70, "d08": 72, "d09": 68, "d10": 71, "d11": 69, "d12": 73,   // without
            "d13": 70, "d14": 68,
        ]
        let behaviorDays: Set<String> = ["d01", "d02", "d03", "d04", "d05", "d06"]
        let e = BehaviorInsights.effect(behaviorDays: behaviorDays, controlDays: Set(outcome.keys).subtracting(behaviorDays), outcomeByDay: outcome,
                                        behavior: "Alcohol", outcome: "Recovery")!
        XCTAssertEqual(e.nWith, 6)
        XCTAssertEqual(e.nWithout, 8)
        XCTAssertEqual(e.meanWith, 60.5, accuracy: 1e-9)
        XCTAssertEqual(e.meanWithout, 70.125, accuracy: 1e-9)
        XCTAssertEqual(e.delta, -9.625, accuracy: 1e-9)
        XCTAssertEqual(e.pctChange!, -13.725490196078432, accuracy: 1e-9)
        XCTAssertLessThan(e.cohensD, 0)                  // lower outcome → negative
        XCTAssertEqual(e.cohensD, -5.247290322400142, accuracy: 1e-6)
        XCTAssertTrue(e.significant)                     // big separation, n≥5 both sides
    }

    func testEffectPositiveDirection() {
        // Behavior RAISES the outcome → positive delta.
        let outcome: [String: Double] = [
            "a": 80, "b": 82, "c": 78, "d": 81, "e": 79,   // with (mean 80)
            "f": 70, "g": 72, "h": 68, "i": 71, "j": 69,   // without (mean 70)
        ]
        let e = BehaviorInsights.effect(behaviorDays: ["a", "b", "c", "d", "e"],
                                        controlDays: Set(outcome.keys).subtracting(["a", "b", "c", "d", "e"]),
                                        outcomeByDay: outcome,
                                        behavior: "Meditation", outcome: "Recovery")!
        XCTAssertEqual(e.delta, 10.0, accuracy: 1e-9)
        XCTAssertGreaterThan(e.cohensD, 0)
        XCTAssertEqual(e.pctChange!, 100.0 * 10.0 / 70.0, accuracy: 1e-9)
        XCTAssertTrue(e.significant)
    }

    func testEffectNilWhenOneGroupEmpty() {
        // Behavior logged every day → no "without" group.
        let outcome: [String: Double] = ["a": 60, "b": 61, "c": 62]
        XCTAssertNil(BehaviorInsights.effect(behaviorDays: ["a", "b", "c"],
                                             controlDays: Set(outcome.keys).subtracting(["a", "b", "c"]),
                                             outcomeByDay: outcome,
                                             behavior: "X", outcome: "Recovery"))
        // Behavior never logged → no "with" group.
        XCTAssertNil(BehaviorInsights.effect(behaviorDays: [],
                                             controlDays: Set(outcome.keys).subtracting([]),
                                             outcomeByDay: outcome,
                                             behavior: "X", outcome: "Recovery"))
    }

    func testEffectIgnoresBehaviorDaysWithNoOutcome() {
        // "z" is in behaviorDays but has no outcome value → not counted in nWith.
        let outcome: [String: Double] = ["a": 60, "b": 62, "c": 70, "d": 72]
        let e = BehaviorInsights.effect(behaviorDays: ["a", "b", "z"],
                                        controlDays: Set(outcome.keys).subtracting(["a", "b", "z"]),
                                        outcomeByDay: outcome,
                                        behavior: "X", outcome: "Recovery")!
        XCTAssertEqual(e.nWith, 2)        // a, b only
        XCTAssertEqual(e.nWithout, 2)     // c, d
    }

    // MARK: - significance flips

    func testSignificanceFlipsWithGroupSize() {
        // SAME clear separation (≈60 vs ≈70), but only 4 days per group → even
        // with a tiny p-value the min-group guard (≥5) blocks significance.
        let smallOutcome: [String: Double] = [
            "w1": 60, "w2": 61, "w3": 59, "w4": 60,
            "o1": 70, "o2": 71, "o3": 69, "o4": 70,
        ]
        let small = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3", "w4"],
                                            controlDays: Set(smallOutcome.keys).subtracting(["w1", "w2", "w3", "w4"]),
                                            outcomeByDay: smallOutcome,
                                            behavior: "X", outcome: "Recovery")!
        XCTAssertLessThan(small.pApprox, 0.05)       // strong evidence numerically…
        XCTAssertEqual(Swift.min(small.nWith, small.nWithout), 4)
        XCTAssertFalse(small.significant)            // …but n too small → not flagged

        // Add a 5th day per group with the same separation → now significant.
        let bigOutcome: [String: Double] = [
            "w1": 60, "w2": 61, "w3": 59, "w4": 60, "w5": 60,
            "o1": 70, "o2": 71, "o3": 69, "o4": 70, "o5": 70,
        ]
        let big = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3", "w4", "w5"],
                                          controlDays: Set(bigOutcome.keys).subtracting(["w1", "w2", "w3", "w4", "w5"]),
                                          outcomeByDay: bigOutcome,
                                          behavior: "X", outcome: "Recovery")!
        XCTAssertEqual(Swift.min(big.nWith, big.nWithout), 5)
        XCTAssertTrue(big.significant)
    }

    func testSignificanceFlipsWithSeparation() {
        // Big groups but NO real separation (heavily overlapping) → not significant.
        let outcome: [String: Double] = [
            "w1": 65, "w2": 71, "w3": 60, "w4": 75, "w5": 66, "w6": 70,
            "o1": 64, "o2": 72, "o3": 61, "o4": 74, "o5": 67, "o6": 69,
        ]
        let e = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3", "w4", "w5", "w6"],
                                        controlDays: Set(outcome.keys).subtracting(["w1", "w2", "w3", "w4", "w5", "w6"]),
                                        outcomeByDay: outcome,
                                        behavior: "X", outcome: "Recovery")!
        XCTAssertGreaterThan(e.pApprox, 0.05)    // no separation → weak evidence
        XCTAssertFalse(e.significant)
    }

    // MARK: - ranking

    func testRankOrdersByEffectSizeSignificantFirst() {
        // Twenty days: d1..d10 low (~50), d11..d20 high (~70), with a little spread in each half.
        var outcome: [String: Double] = [:]
        for i in 1...20 { outcome["d\(i)"] = (i <= 10 ? 50.0 : 70.0) + Double(i % 3) - 1 }
        // Strong: cleanly splits the halves → big |d|, significant after correction.
        let strong = Set((1...10).map { "d\($0)" })
        // Mixed: 3 low + 4 high "yes" days → a small effect, not significant.
        let mixed: Set<String> = ["d1", "d2", "d3", "d11", "d12", "d13", "d14"]
        // Null: alternating days → no effect.
        let null = Set(stride(from: 1, through: 19, by: 2).map { "d\($0)" })
        // Thin: 4 "yes" days — under WHOOP's 5/5 rule, never tested, never shown.
        let thin: Set<String> = ["d1", "d2", "d3", "d4"]

        // Predates the Yes/No split and tests the ranking math, so it keeps its original partition
        // by declaring the complement as controls explicitly.
        let all = Set(outcome.keys)
        let behaviors = ["Strong": strong, "Mixed": mixed, "Null": null, "Thin": thin]
        let ranked = BehaviorInsights.rank(behaviors: behaviors,
                                           controls: behaviors.mapValues { all.subtracting($0) },
                                           outcomeByDay: outcome, outcome: "Recovery")
        XCTAssertEqual(ranked.map(\.behavior).sorted(), ["Mixed", "Null", "Strong"], "Thin is not tested")
        XCTAssertEqual(ranked.first?.behavior, "Strong")   // significant + largest |d|
        XCTAssertTrue(ranked.first!.significant)
        XCTAssertNotNil(ranked.first?.qValue)
        // Non-significant entries trail the significant one, larger |cohensD| first.
        XCTAssertFalse(ranked[1].significant)
        XCTAssertFalse(ranked[2].significant)
        XCTAssertGreaterThanOrEqual(abs(ranked[1].cohensD), abs(ranked[2].cohensD))
    }

    func testRankDropsUncomputableBehaviors() {
        var outcome: [String: Double] = [:]
        for i in 1...10 { outcome["d\(i)"] = (i <= 5 ? 60.0 : 70.0) + Double(i % 2) }
        // "AllDays" covers every day → no without group → dropped. "Half" has 5 and 5 → tested.
        // Predates the Yes/No split and tests the ranking math, so it keeps its original partition
        // by declaring the complement as controls explicitly.
        let all = Set(outcome.keys)
        let half = Set((1...5).map { "d\($0)" })
        let ranked = BehaviorInsights.rank(behaviors: ["AllDays": all, "Half": half],
                                           controls: ["AllDays": [], "Half": all.subtracting(half)],
                                           outcomeByDay: outcome, outcome: "Recovery")
        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked.first?.behavior, "Half")
    }

    // MARK: - WHOOP's 5/5 rule and false-discovery control

    func testFewerThanFiveYesOrNoDaysIsNeverTested() {
        var outcome: [String: Double] = [:]
        for i in 1...30 { outcome["d\(i)"] = (i <= 4 ? 30.0 : 70.0) + Double(i % 3) }
        let fourYes = Set((1...4).map { "d\($0)" })
        let ranked = BehaviorInsights.rank(behaviors: ["Rare": fourYes],
                                           controls: ["Rare": Set(outcome.keys).subtracting(fourYes)],
                                           outcomeByDay: outcome, outcome: "Recovery")
        XCTAssertTrue(ranked.isEmpty, "a huge effect on 4 yes days is still not a finding")
    }

    /// One behaviour with an uncorrected p ≈ 0.02 among nineteen that show nothing: on its own it would be
    /// "significant", but across the twenty tests the ranker ran its q-value is ≈ 0.5.
    func testALuckyResultAmongManyTestsIsNotSignificant() throws {
        var outcome: [String: Double] = [:]
        let jitter: [Double] = [-2, -1, 0, 1, 2]
        for i in 0..<20 { outcome["d\(i)"] = 60 + jitter[i % 5] + (i < 10 ? 1.5 : 0) }
        let lucky = Set((0..<10).map { "d\($0)" })
        let all = Set(outcome.keys)
        var behaviors = ["Lucky": lucky]
        // Nulls: five "yes" and five "no" days with identical jitter and no shift → exactly no effect.
        for k in 0..<19 {
            behaviors["Null\(k)"] = Set((10..<15).map { "d\($0)" })
        }
        let controls = behaviors.mapValues { $0 == lucky ? all.subtracting(lucky) : Set((15..<20).map { "d\($0)" }) }

        let alone = BehaviorInsights.rank(behaviors: ["Lucky": lucky], controls: ["Lucky": controls["Lucky"]!],
                                          outcomeByDay: outcome, outcome: "Recovery")
        let luckyAlone = try XCTUnwrap(alone.first)
        XCTAssertLessThan(luckyAlone.pApprox, 0.05)
        XCTAssertTrue(luckyAlone.significant, "one test: q equals p")

        let family = BehaviorInsights.rank(behaviors: behaviors, controls: controls,
                                           outcomeByDay: outcome, outcome: "Recovery")
        let luckyInFamily = try XCTUnwrap(family.first { $0.behavior == "Lucky" })
        XCTAssertEqual(luckyInFamily.pApprox, luckyAlone.pApprox)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(luckyInFamily.qValue), BehaviorInsights.fdrThreshold)
        XCTAssertFalse(luckyInFamily.significant)
        XCTAssertFalse(family.contains { $0.significant })
    }

    func testTheFamilySpansEveryOutcome() throws {
        // The same lucky split, once against its own outcome and once beside four null outcomes.
        var outcome: [String: Double] = [:], flat: [String: Double] = [:]
        let jitter: [Double] = [-2, -1, 0, 1, 2]
        for i in 0..<20 {
            outcome["d\(i)"] = 60 + jitter[i % 5] + (i < 10 ? 1.5 : 0)
            flat["d\(i)"] = 60 + jitter[i % 5]
        }
        let lucky = Set((0..<10).map { "d\($0)" })
        let controls = ["Lucky": Set(outcome.keys).subtracting(lucky)]
        var outcomes = ["Charge": outcome]
        for k in 0..<4 { outcomes["Flat\(k)"] = flat }
        let byOutcome = BehaviorInsights.rankAll(behaviors: ["Lucky": lucky], controls: controls, outcomes: outcomes)
        XCTAssertEqual(Set(byOutcome.keys), Set(outcomes.keys))
        let charge = try XCTUnwrap(byOutcome["Charge"]?.first)
        XCTAssertLessThan(charge.pApprox, 0.05)
        XCTAssertGreaterThan(try XCTUnwrap(charge.qValue), charge.pApprox, "corrected across all five outcomes")
    }

    func testBenjaminiHochbergQValues() {
        let q = MultipleTesting.benjaminiHochberg([0.01, 0.04, 0.03, 0.005])
        XCTAssertEqual(q.count, 4)
        for (got, want) in zip(q, [0.02, 0.04, 0.04, 0.02]) { XCTAssertEqual(got, want, accuracy: 1e-12) }
        XCTAssertEqual(MultipleTesting.benjaminiHochberg([]), [])
        XCTAssertEqual(MultipleTesting.benjaminiHochberg([0.9, .nan]), [1, 1])
        XCTAssertEqual(MultipleTesting.benjaminiHochberg([0.5]), [0.5])
    }

    // MARK: - sentence

    func testSentenceLowerWithPercent() {
        // Integer means avoid half-rounding ambiguity: with=60, without=80 →
        // delta -20, pct -25% → "25% lower (avg 60 vs 80, n=5 vs 5)".
        let outcome: [String: Double] = [
            "w1": 58, "w2": 62, "w3": 60, "w4": 59, "w5": 61,   // mean 60
            "o1": 78, "o2": 82, "o3": 80, "o4": 79, "o5": 81,   // mean 80
        ]
        let e = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3", "w4", "w5"],
                                        controlDays: Set(outcome.keys).subtracting(["w1", "w2", "w3", "w4", "w5"]),
                                        outcomeByDay: outcome,
                                        behavior: "Alcohol", outcome: "Recovery")!
        let s = BehaviorInsights.sentence(e)
        XCTAssertEqual(s, "On days you logged ‘Alcohol’, Recovery was 25% lower (avg 60 vs 80, n=5 vs 5).")
    }

    func testSentenceHigherWithPercent() {
        let outcome: [String: Double] = [
            "w1": 79, "w2": 81, "w3": 80,    // mean 80
            "o1": 49, "o2": 51, "o3": 50,    // mean 50
        ]
        let e = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3"],
                                        controlDays: Set(outcome.keys).subtracting(["w1", "w2", "w3"]),
                                        outcomeByDay: outcome,
                                        behavior: "Meditation", outcome: "Recovery")!
        let s = BehaviorInsights.sentence(e)
        // delta +30, pct +60% → "60% higher (avg 80 vs 50, n=3 vs 3)".
        XCTAssertEqual(s, "On days you logged ‘Meditation’, Recovery was 60% higher (avg 80 vs 50, n=3 vs 3).")
    }

    func testSentenceFallsBackToUnitsWhenPctUndefined() {
        // meanWithout 0 → pctChange nil → sentence uses absolute units.
        let outcome: [String: Double] = [
            "w1": 5, "w2": 5, "w3": 5,
            "o1": 0, "o2": 0, "o3": 0,
        ]
        let e = BehaviorInsights.effect(behaviorDays: ["w1", "w2", "w3"],
                                        controlDays: Set(outcome.keys).subtracting(["w1", "w2", "w3"]),
                                        outcomeByDay: outcome,
                                        behavior: "X", outcome: "HRV")!
        XCTAssertNil(e.pctChange)
        let s = BehaviorInsights.sentence(e)
        XCTAssertEqual(s, "On days you logged ‘X’, HRV was 5.0 higher (avg 5 vs 0, n=3 vs 3).")
    }
    // MARK: - Unlogged days are not answers (the Reddit report)

    /// "If I didn't track something for 100 days, NOOP takes that as a NO for 100 days, whereas it simply
    /// was not logged at all." Reported by a user on Reddit, and it was exactly what the split did.
    ///
    /// Twin of Kotlin `EffectRankerTest.daysWithNoJournalRowAreNotControls`.
    func testDaysWithNoJournalRowAreNotControls() {
        var outcome: [String: Double] = [:]
        var yes: Set<String> = []
        var no: Set<String> = []
        for d in 1...6 { let k = "y\(d)"; yes.insert(k); outcome[k] = Double(58 + d) }
        for d in 1...6 { let k = "n\(d)"; no.insert(k); outcome[k] = Double(68 + d) }
        // Never opened the journal on these, and their values sit far from BOTH answered groups.
        for d in 1...40 { outcome["u\(d)"] = Double(20 + (d % 3)) }

        let e = BehaviorInsights.effect(behaviorDays: yes, controlDays: no,
                                        outcomeByDay: outcome,
                                        behavior: "Alcohol", outcome: "Recovery")!
        // Controls are the six NO days only. Were the 40 unlogged days leaking in, nWithout would be 46
        // and meanWithout would be dragged towards 20.
        XCTAssertEqual(e.nWith, 6)
        XCTAssertEqual(e.nWithout, 6)
        XCTAssertGreaterThan(e.meanWithout, 60.0)
    }

    /// A behaviour the user only ever ticks Yes has no control group, so there is no comparison to make
    /// and the honest answer is none. Twin of Kotlin `aBehaviourNeverLoggedNoYieldsNothing`.
    func testBehaviourNeverLoggedNoYieldsNothing() {
        var outcome: [String: Double] = [:]
        var yes: Set<String> = []
        for d in 1...10 { let k = "y\(d)"; yes.insert(k); outcome[k] = Double(50 + d) }
        for d in 1...10 { outcome["u\(d)"] = Double(80 + d) }

        XCTAssertNil(BehaviorInsights.effect(behaviorDays: yes, controlDays: [],
                                             outcomeByDay: outcome,
                                             behavior: "Alcohol", outcome: "Recovery"))
    }

    /// rank() fails CLOSED on a caller that forgets the controls: no insight, rather than a wrong one
    /// measured against every day the user never opened the journal. Twin of Kotlin
    /// `rankWithoutControlsProducesNothingRatherThanGuessing`.
    func testRankWithoutControlsProducesNothingRatherThanGuessing() {
        var outcome: [String: Double] = [:]
        var yes: Set<String> = []
        for d in 1...10 { let k = "y\(d)"; yes.insert(k); outcome[k] = Double(50 + d) }
        for d in 1...20 { outcome["u\(d)"] = Double(75 + (d % 4)) }

        XCTAssertTrue(BehaviorInsights.rank(behaviors: ["Alcohol": yes], controls: [:],
                                            outcomeByDay: outcome, outcome: "Recovery").isEmpty)
    }

}
