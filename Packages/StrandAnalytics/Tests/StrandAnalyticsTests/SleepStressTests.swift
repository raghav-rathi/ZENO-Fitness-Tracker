import XCTest
@testable import StrandAnalytics
import WhoopProtocol

final class SleepStressTests: XCTestCase {

    // A night from 23:00 to 07:00 (UTC, so the wall clock and the local clock agree).
    private let sleepStart = 23 * 3_600
    private let sleepEnd = 31 * 3_600

    /// A waking reference with a calm anchor of `calm` bpm and a spread well above the floor.
    private func reference(calm: Double = 70, sd: Double = 8, rmssd: Double? = nil) -> SleepStress.Reference {
        SleepStress.Reference(meanHR: calm, sdHR: sd, meanRMSSD: rmssd, sdRMSSD: rmssd == nil ? 0 : 12, hours: 8)
    }

    /// 1 Hz heart rate at `bpm(t)` over [from, to).
    private func hr(_ from: Int, _ to: Int, bpm: (Int) -> Int) -> [HRSample] {
        stride(from: from, to: to, by: 1).map { HRSample(ts: $0, bpm: bpm($0)) }
    }

    private func hourPoint(_ hour: Int, meanHR: Double?, rmssd: Double? = nil, masked: Bool = false)
        -> DaytimeStress.HourPoint {
        DaytimeStress.HourPoint(hour: hour % 24, startTs: hour * 3_600, level: meanHR == nil ? nil : 1.5,
                                meanHR: meanHR, rmssd: rmssd, maskedForActivity: masked)
    }

    // MARK: Scoring

    func testASettledNightAgainstTheWakingCalmReadsLow() {
        let night = hr(sleepStart, sleepEnd) { _ in 54 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepEnd,
                                      reference: reference())
        XCTAssertTrue(res.hasScore)
        XCTAssertEqual(res.highPercent, 0)
        XCTAssertEqual(res.percent(.low), 100)
        for w in res.windows {
            XCTAssertEqual(w.band, .low, "a sleeping heart rate 16 bpm under the waking calm is LOW")
        }
    }

    func testAnArousalPastTheWakingCalmReadsHighForItsWindowsOnly() {
        // Ten minutes at 92 bpm starting two hours in: two whole windows.
        let arousal = sleepStart + 2 * 3_600
        let night = hr(sleepStart, sleepEnd) { t in (t >= arousal && t < arousal + 600) ? 92 : 54 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepEnd,
                                      reference: reference())
        let highs = res.windows.filter { $0.band == .high }
        XCTAssertEqual(highs.map(\.startTs), [arousal, arousal + 300])
        XCTAssertEqual(res.highSeconds, 600)
        XCTAssertEqual(res.highPercent ?? -1, 600.0 / Double(8 * 3_600) * 100, accuracy: 1e-9)
    }

    func testTheSharesAlwaysAddUpToTheScoredSleep() {
        let night = hr(sleepStart, sleepEnd) { t in 50 + ((t - self.sleepStart) / 900) % 40 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepEnd,
                                      reference: reference())
        XCTAssertEqual(res.lowSeconds + res.mediumSeconds + res.highSeconds, res.scoredSeconds)
        let total = SleepStress.Band.allCases.compactMap(res.percent).reduce(0, +)
        XCTAssertEqual(total, 100, accuracy: 1e-9)
        XCTAssertGreaterThan(res.mediumSeconds, 0)
        XCTAssertGreaterThan(res.highSeconds, 0)
    }

    func testItUsesTheStressMonitorsScaleAndBands() {
        // A window sitting exactly on the calm anchor, HR only, is the logistic's midpoint: 1.5 (MEDIUM).
        let night = hr(sleepStart, sleepStart + 300) { _ in 70 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepStart + 300,
                                      reference: reference())
        XCTAssertEqual(res.windows.first?.level ?? -1, DaytimeStress.squash(0), accuracy: 1e-12)
        XCTAssertEqual(res.windows.first?.band, .medium)
        XCTAssertEqual(SleepStress.Band(level: 0.99), .low)
        XCTAssertEqual(SleepStress.Band(level: 1.0), .medium)
        XCTAssertEqual(SleepStress.Band(level: DaytimeStress.highBandFloor), .high)
    }

    func testRMSSDBelowTheCalmAnchorAddsStress() {
        // Same heart rate, two R-R patterns: nearly steady beats (RMSSD ≈ 10 ms) read more stressed than
        // variable ones (RMSSD ≈ 40 ms) against a calm RMSSD of 50.
        let start = sleepStart
        let end = sleepStart + 300
        func beats(swing: Int) -> [RRInterval] {
            stride(from: start, to: end, by: 1).enumerated().map { i, ts in
                RRInterval(ts: ts, rrMs: i % 2 == 0 ? 1_000 - swing : 1_000 + swing)
            }
        }
        let night = hr(start, end) { _ in 60 }
        let ref = reference(calm: 70, sd: 8, rmssd: 50)
        let steady = SleepStress.analyze(hr: night, rr: beats(swing: 5), sleepStart: start, sleepEnd: end,
                                         reference: ref).windows.first
        let variable = SleepStress.analyze(hr: night, rr: beats(swing: 20), sleepStart: start, sleepEnd: end,
                                           reference: ref).windows.first
        XCTAssertNotNil(steady?.rmssd)
        XCTAssertNotNil(variable?.rmssd)
        XCTAssertLessThan(steady?.rmssd ?? .infinity, variable?.rmssd ?? 0)
        XCTAssertGreaterThan(steady?.level ?? 0, variable?.level ?? .infinity)
    }

    // MARK: Windows

    func testWindowsTileTheSleepFromItsStartAndClipTheLastOne() {
        let end = sleepStart + 3 * 300 + 120
        let night = hr(sleepStart, end) { _ in 55 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: end,
                                      reference: reference())
        XCTAssertEqual(res.windows.map(\.startTs),
                       [sleepStart, sleepStart + 300, sleepStart + 600, sleepStart + 900])
        XCTAssertEqual(res.windows.map(\.seconds), [300, 300, 300, 120])
        XCTAssertEqual(res.scoredSeconds, 3 * 300 + 120)
    }

    func testLeadInAndTailWindowsDrawButNeverCount() {
        let night = hr(sleepStart - 1_800, sleepEnd + 900) { t in t < self.sleepStart ? 95 : 54 }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepEnd,
                                      reference: reference(), chartStart: sleepStart - 1_800,
                                      chartEnd: sleepEnd + 900)
        let lead = res.windows.filter { !$0.inSleep && $0.startTs < sleepStart }
        let tail = res.windows.filter { !$0.inSleep && $0.startTs >= sleepEnd }
        XCTAssertEqual(lead.count, 6)
        XCTAssertEqual(tail.count, 3)
        XCTAssertTrue(lead.allSatisfy { $0.band == .high }, "the evening before sleep is scored for the curve")
        XCTAssertEqual(res.highSeconds, 0, "but it never enters the night's shares")
        XCTAssertEqual(res.scoredSeconds, sleepEnd - sleepStart)
        XCTAssertEqual(res.windows.map(\.startTs), res.windows.map(\.startTs).sorted())
    }

    func testAThinWindowIsLeftUnscoredAndOutOfTheShares() {
        // Every window has 1 Hz data except the third, which has 10 samples.
        let third = sleepStart + 600
        let night = hr(sleepStart, sleepStart + 1_500) { _ in 55 }.filter { s in
            !(s.ts >= third && s.ts < third + 300) || s.ts < third + 10
        }
        let res = SleepStress.analyze(hr: night, rr: [], sleepStart: sleepStart, sleepEnd: sleepStart + 1_500,
                                      reference: reference())
        XCTAssertNil(res.windows[2].level)
        XCTAssertNil(res.windows[2].meanHR)
        XCTAssertEqual(res.scoredSeconds, 4 * 300)
        XCTAssertEqual(res.percent(.low), 100)
    }

    func testNoHeartRateIsNoScore() {
        let res = SleepStress.analyze(hr: [], rr: [], sleepStart: sleepStart, sleepEnd: sleepEnd,
                                      reference: reference())
        XCTAssertEqual(res, .empty)
        XCTAssertNil(res.highPercent)
        XCTAssertFalse(res.hasScore)
    }

    // MARK: Reference

    func testTheReferenceIsTheStressMonitorsCalmAnchorOfTheHoursBeforeSleep() {
        let means: [Double] = [62, 66, 70, 74, 78, 82]
        let hours = means.enumerated().map { hourPoint(14 + $0.offset, meanHR: $0.element) }
        let ref = SleepStress.reference(wakingHours: hours, endingBy: sleepStart)
        XCTAssertEqual(ref?.meanHR, DaytimeStress.calmReference(means, calmIsLow: true))
        XCTAssertEqual(ref?.sdHR ?? 0, DaytimeStress.std(means, mean: DaytimeStress.mean(means)), accuracy: 1e-12)
        XCTAssertNil(ref?.meanRMSSD, "no hour had R-R, so the night scores on heart rate alone")
        XCTAssertEqual(ref?.hours, 6)
    }

    func testTheReferenceLeavesOutMovingHoursAndHoursOfTheSleepItself() {
        var hours = (14..<20).map { hourPoint($0, meanHR: 70) }
        hours.append(hourPoint(20, meanHR: 140, masked: true))   // a run: exertion, not calm
        hours.append(hourPoint(22, meanHR: 50))                  // 22:00–23:00 ends at sleep start: kept
        hours.append(hourPoint(23, meanHR: 45))                  // the sleep's own first hour: dropped
        let ref = SleepStress.reference(wakingHours: hours, endingBy: sleepStart)
        XCTAssertEqual(ref?.hours, 7)
        XCTAssertEqual(ref?.meanHR, DaytimeStress.calmReference(Array(repeating: 70, count: 6) + [50],
                                                               calmIsLow: true))
    }

    func testTheReferenceNeedsFourHoursAndFloorsItsSpread() {
        let three = (14..<17).map { hourPoint($0, meanHR: 70) }
        XCTAssertNil(SleepStress.reference(wakingHours: three, endingBy: sleepStart))
        let flat = (14..<20).map { hourPoint($0, meanHR: 70, rmssd: 40) }
        let ref = SleepStress.reference(wakingHours: flat, endingBy: sleepStart)
        XCTAssertEqual(ref?.sdHR, SleepStress.minSpreadBPM, "a flat day must not make a 2 bpm wobble HIGH")
        XCTAssertEqual(ref?.sdRMSSD, SleepStress.minSpreadRMSSD)
        XCTAssertEqual(ref?.meanRMSSD, 40)
    }
}
