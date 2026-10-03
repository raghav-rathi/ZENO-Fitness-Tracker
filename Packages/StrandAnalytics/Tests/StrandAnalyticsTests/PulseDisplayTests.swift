import XCTest
@testable import StrandAnalytics
import WhoopProtocol

final class PulseDisplayTests: XCTestCase {

    // MARK: - Recovery bands

    func testRecoveryBandEdgesFollowTheDisplayedPercent() {
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 0), .red)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 33), .red)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 33.4), .red)
        // 33.5 prints "34%", so it must read yellow rather than disagree with its own number.
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 33.5), .yellow)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 34), .yellow)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 66), .yellow)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 66.4), .yellow)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 66.6), .green)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 67), .green)
        XCTAssertEqual(PulseDisplay.recoveryBand(percent: 100), .green)
    }

    func testDisplayedPercentClampsAndRounds() {
        XCTAssertEqual(PulseDisplay.displayedPercent(-4), 0)
        XCTAssertEqual(PulseDisplay.displayedPercent(104), 100)
        XCTAssertEqual(PulseDisplay.displayedPercent(72.5), 73)
        XCTAssertEqual(PulseDisplay.displayedPercent(.nan), 0)
    }

    func testStrainIntentTracksTheBand() {
        XCTAssertEqual(PulseDisplay.strainIntent(recoveryPercent: 12), .restore)
        XCTAssertEqual(PulseDisplay.strainIntent(recoveryPercent: 50), .maintain)
        XCTAssertEqual(PulseDisplay.strainIntent(recoveryPercent: 88), .push)
        for p in stride(from: 0.0, through: 100.0, by: 0.5) {
            let band = PulseDisplay.recoveryBand(percent: p)
            let intent = PulseDisplay.strainIntent(recoveryPercent: p)
            switch band {
            case .red: XCTAssertEqual(intent, .restore, "\(p)")
            case .yellow: XCTAssertEqual(intent, .maintain, "\(p)")
            case .green: XCTAssertEqual(intent, .push, "\(p)")
            }
        }
    }

    // MARK: - Comparison with recent history

    private func series(_ values: [Double], endingBefore dayKey: String) -> [(day: String, value: Double)] {
        let keys = PulseDisplay.trailingDayKeys(endingOn: PulseDisplay.dayKey(dayKey, offsetBy: -1)!,
                                                count: values.count)
        return zip(keys, values).map { (day: $0.0, value: $0.1) }
    }

    func testCompareExcludesTheComparedDayAndOlderThanTheWindow() {
        var history = series(Array(repeating: 50.0, count: 10), endingBefore: "2026-09-30")
        history.append((day: "2026-09-30", value: 500))   // the compared day: must not count
        history.append((day: "2026-07-01", value: 900))   // outside the 30-day window
        let c = PulseDisplay.compare(value: 55, history: history, dayKey: "2026-09-30")
        XCTAssertEqual(c?.reference ?? -1, 50, accuracy: 1e-9)
        XCTAssertEqual(c?.samples, 10)
        XCTAssertEqual(c?.delta ?? -1, 5, accuracy: 1e-9)
        XCTAssertEqual(c?.percent ?? -1, 10, accuracy: 1e-9)
        XCTAssertEqual(c?.direction, .up)
    }

    func testCompareNeedsEnoughDays() {
        let thin = series([60, 61, 59], endingBefore: "2026-09-30")
        XCTAssertNil(PulseDisplay.compare(value: 70, history: thin, dayKey: "2026-09-30"))
        XCTAssertNotNil(PulseDisplay.compare(value: 70, history: thin, dayKey: "2026-09-30", minSamples: 3))
        XCTAssertNil(PulseDisplay.compare(value: nil, history: thin, dayKey: "2026-09-30", minSamples: 1))
    }

    func testCompareFlatBandAndDownDirection() {
        let h = series(Array(repeating: 100.0, count: 8), endingBefore: "2026-03-10")
        XCTAssertEqual(PulseDisplay.compare(value: 101, history: h, dayKey: "2026-03-10")?.direction, .flat)
        XCTAssertEqual(PulseDisplay.compare(value: 90, history: h, dayKey: "2026-03-10")?.direction, .down)
    }

    func testCompareNearZeroAverageFallsBackToAbsoluteDelta() {
        // A skin-temperature deviation is centred on zero, where a percentage is meaningless.
        let h = series([0.1, -0.1, 0.0, 0.05, -0.05], endingBefore: "2026-09-30")
        let c = PulseDisplay.compare(value: 0.4, history: h, dayKey: "2026-09-30")
        XCTAssertNil(c?.percent)
        XCTAssertEqual(c?.direction, .up)
        XCTAssertEqual(PulseDisplay.compare(value: 0.02, history: h, dayKey: "2026-09-30")?.direction, .flat)
    }

    func testBaselineCompareUsesThePrintedFigures() {
        // 57 vs a 56.4 baseline prints "57" against "56": up, by the printed 1 of 56.
        let rhr = PulseDisplay.compare(value: 57, baseline: 56.4, fractionDigits: 0)
        XCTAssertEqual(rhr?.direction, .up)
        XCTAssertEqual(rhr?.reference ?? -1, 56, accuracy: 1e-9)
        XCTAssertEqual(rhr?.percent ?? -1, 100.0 / 56.0, accuracy: 1e-9)
        // 14.24 vs 14.16 both print "14.2": flat, whatever the raw difference.
        XCTAssertEqual(PulseDisplay.compare(value: 14.24, baseline: 14.16, fractionDigits: 1)?.direction, .flat)
        // Half away from zero, as the engine rounds: 14.25 prints "14.3".
        XCTAssertEqual(PulseDisplay.compare(value: 14.25, baseline: 14.2, fractionDigits: 1)?.direction, .up)
        XCTAssertNil(PulseDisplay.compare(value: .nan, baseline: 50, fractionDigits: 0))
    }

    /// The arrow must never point against the engine's own "above / below baseline" verdict for the
    /// same value and baseline (the What shaped it row printed right beside it). Swept over a grid,
    /// including values that print equal and half-way cases, for both precisions the engine uses.
    func testBaselineCompareNeverContradictsTheEngineVerdict() {
        for digits in [0, 1] {
            let step = digits == 0 ? 0.25 : 0.025
            for i in 0...80 {
                let value = 50 + Double(i) * step
                for j in 0...80 {
                    let baseline = 50 + Double(j) * step
                    guard let c = PulseDisplay.compare(value: value, baseline: baseline, fractionDigits: digits) else {
                        return XCTFail("no comparison for \(value) vs \(baseline)")
                    }
                    for points in [-3, 0, 3] {
                        let verdict = RecoveryScorer.baselineVerdict(value: value, baseline: baseline,
                                                                     deltaPoints: points, fractionDigits: digits)
                        switch c.direction {
                        case .up: XCTAssertTrue(verdict.hasPrefix("above baseline"), "\(value) vs \(baseline): \(verdict)")
                        case .down: XCTAssertTrue(verdict.hasPrefix("below baseline"), "\(value) vs \(baseline): \(verdict)")
                        case .flat:
                            XCTAssertTrue(verdict == "at baseline" || verdict.hasPrefix("slightly"),
                                          "\(value) vs \(baseline): \(verdict)")
                        }
                    }
                }
            }
        }
    }

    func testDayKeyArithmeticIsZoneIndependentAndCrossesMonthsAndDST() {
        XCTAssertEqual(PulseDisplay.dayKey("2026-03-01", offsetBy: -1), "2026-02-28")
        XCTAssertEqual(PulseDisplay.dayKey("2024-03-01", offsetBy: -1), "2024-02-29")
        XCTAssertEqual(PulseDisplay.dayKey("2026-11-01", offsetBy: 1), "2026-11-02")   // US DST ends
        XCTAssertEqual(PulseDisplay.dayKey("2026-01-01", offsetBy: -30), "2025-12-02")
        XCTAssertNil(PulseDisplay.dayKey("not-a-day", offsetBy: 1))
        XCTAssertEqual(PulseDisplay.trailingDayKeys(endingOn: "2026-09-30", count: 3),
                       ["2026-09-28", "2026-09-29", "2026-09-30"])
    }

    // MARK: - Cumulative strain

    /// A day at 1 sample every 5 s: resting, then an hour-long hard block, then resting again.
    private func dayOfHR(start: Int) -> [HRSample] {
        var out: [HRSample] = []
        var t = start
        func add(_ bpm: Int, minutes: Int) {
            for _ in 0..<(minutes * 12) {
                out.append(HRSample(ts: t, bpm: bpm))
                t += 5
            }
        }
        add(62, minutes: 120)
        add(165, minutes: 60)
        add(70, minutes: 120)
        return out
    }

    func testCumulativeStrainEndsAtTheWholeWindowScoreAndNeverDrops() {
        let start = 1_700_000_000
        let hr = dayOfHR(start: start)
        let end = hr.last!.ts
        let curve = PulseDisplay.cumulativeStrain(hr: hr, from: start, to: end, stepSeconds: 900,
                                                  maxHR: 190, restingHR: 60, method: .edwards, sex: "male")
        XCTAssertFalse(curve.isEmpty)
        let whole = StrainScorer.strain(hr, maxHR: 190, restingHR: 60, method: .edwards, sex: "male")
        XCTAssertNotNil(whole)
        XCTAssertEqual(curve.last?.effort ?? -1, whole ?? -2, accuracy: 1e-9)
        XCTAssertEqual(curve.last?.ts, end)
        for (a, b) in zip(curve, curve.dropFirst()) {
            XCTAssertLessThanOrEqual(a.effort, b.effort)
            XCTAssertLessThan(a.ts, b.ts)
        }
        // The hard block is where the load lands: the curve is flat-ish before it and climbs during it.
        let beforeBlock = curve.last(where: { $0.ts <= start + 120 * 60 })?.effort ?? 0
        let afterBlock = curve.first(where: { $0.ts >= start + 180 * 60 })?.effort ?? 0
        XCTAssertGreaterThan(afterBlock, beforeBlock + 10)
    }

    func testCumulativeStrainOmitsCheckpointsTooThinToScore() {
        let start = 1_700_000_000
        // 10 samples: below every scorer floor, so there is nothing honest to draw.
        let hr = (0..<10).map { HRSample(ts: start + $0 * 5, bpm: 120) }
        XCTAssertTrue(PulseDisplay.cumulativeStrain(hr: hr, from: start, to: start + 3600, stepSeconds: 600,
                                                    maxHR: 190, restingHR: 60, method: .edwards,
                                                    sex: "male").isEmpty)
        XCTAssertTrue(PulseDisplay.cumulativeStrain(hr: [], from: start, to: start + 3600, stepSeconds: 600,
                                                    maxHR: 190, restingHR: 60, method: .edwards,
                                                    sex: "male").isEmpty)
    }

    func testPrefixEndBinarySearch() {
        let hr = [HRSample(ts: 10, bpm: 60), HRSample(ts: 20, bpm: 60), HRSample(ts: 30, bpm: 60)]
        XCTAssertEqual(PulseDisplay.prefixEnd(hr, through: 5), 0)
        XCTAssertEqual(PulseDisplay.prefixEnd(hr, through: 10), 1)
        XCTAssertEqual(PulseDisplay.prefixEnd(hr, through: 25), 2)
        XCTAssertEqual(PulseDisplay.prefixEnd(hr, through: 99), 3)
    }

    func testMedianClockMinuteHandlesMidnight() {
        XCTAssertNil(PulseDisplay.medianClockMinute([]))
        XCTAssertEqual(PulseDisplay.medianClockMinute([400, 420, 410]), 410)
        XCTAssertEqual(PulseDisplay.medianClockMinute([400, 420]), 410)
        // 23:50 and 00:10 straddle midnight: their median is midnight, not midday.
        XCTAssertEqual(PulseDisplay.medianClockMinute([23 * 60 + 50, 10]), 0)
    }
}
