import Foundation
import WhoopProtocol

// SleepStress.swift — overnight stress: the Sleep dive's SLEEP STRESS card and its HIGH SLEEP STRESS
// contributor (WHOOP_UI_SPEC §3.3 item 7d, "ZENO data").
//
// This is the SAME autonomic proxy the Stress Monitor draws (`DaytimeStress`), not a new score: a window's
// mean heart rate up and its RMSSD down, z-scored against a calm reference, summed and squashed onto 0–3
// with the identical logistic (`DaytimeStress.rawScore` / `DaytimeStress.squash`). A sleep window and a
// waking hour therefore share one scale and one set of bands: LOW below 1.0, MEDIUM from 1.0, HIGH from
// `DaytimeStress.highBandFloor` (2.0). Two things change for the night, both on purpose:
//
//   • THE GRAIN. Five-minute windows, not hours: an arousal lasts minutes, and an hour of sleep around it
//     would average it away. The sample gate scales with the window, so a five-minute window needs the
//     same ~8% heart-rate coverage `DaytimeStress.minHourHRSamples` asks of an hour (25 samples).
//   • THE REFERENCE. The calm anchor of the WAKING hours before the night, built exactly as the Stress
//     Monitor's day-relative read builds its own: the lower quartile of the hours' mean heart rate, the
//     upper quartile of their RMSSD, the spread across those hours, ambulatory hours left out. Sleep is
//     the calmest stretch of any day; scored against itself, its own typical window would read 1.5
//     (MEDIUM) and the curve would say nothing. Against the waking calm a settled night reads LOW, and an
//     arousal that lifts heart rate past the waking calm reads MEDIUM or HIGH, which is what the card is
//     for. The spreads are floored (`minSpreadBPM`, `minSpreadRMSSD`) so a near-flat reference day cannot
//     turn a two-beat wobble into a HIGH.
//
// HIGH SLEEP STRESS is the share of the SCORED sleep that sat in the HIGH band; MEDIUM and LOW come off the
// same windows, so the three shares always add up to 100%. Windows before the sleep and after it can be
// scored too (`chartStart` / `chartEnd`), for the curve's context only: they never enter a share.
//
// APPROXIMATE and non-clinical, like the daytime curve. No reference (no waking heart rate before the
// night) means no score: the caller says so rather than inventing one. Pure: no store, no clock.

public enum SleepStress {

    // MARK: Tunables

    /// The window the night is scored in (five minutes).
    public static let windowSeconds: Int = 300
    /// Heart-rate samples a full window needs before it is scored: `DaytimeStress.minHourHRSamples`
    /// scaled from an hour to the window (300 per 3 600 s → 25 per 300 s).
    public static let minWindowHRSamples: Int = 25
    /// Scored, non-ambulatory waking hours the reference needs (DaytimeStress's own quartile floor).
    public static let minReferenceHours: Int = 4
    /// The smallest heart-rate spread (bpm) the reference divides by.
    public static let minSpreadBPM: Double = 4
    /// The smallest RMSSD spread (ms) the reference divides by.
    public static let minSpreadRMSSD: Double = 5
    /// MEDIUM starts here on the shared 0–3 scale (LOW 0.0–0.9, MEDIUM 1.0–1.9, HIGH 2.0–3.0).
    public static let mediumFloor: Double = 1.0
    /// HIGH starts here: the Stress Monitor's own floor.
    public static let highFloor: Double = DaytimeStress.highBandFloor

    // MARK: Reference

    /// The calm anchor a night is scored against, and the spreads its z-scores divide by.
    public struct Reference: Equatable, Sendable {
        /// The calm heart rate (bpm): the lower quartile of the waking hours' mean heart rate.
        public let meanHR: Double
        /// The heart-rate spread across those hours (bpm), floored at `minSpreadBPM`.
        public let sdHR: Double
        /// The calm RMSSD (ms): the upper quartile of the waking hours' RMSSD; nil when no hour had
        /// enough clean beats, and then the night is scored on heart rate alone.
        public let meanRMSSD: Double?
        /// The RMSSD spread (ms), floored at `minSpreadRMSSD`; 0 without an RMSSD anchor.
        public let sdRMSSD: Double
        /// How many waking hours backed it.
        public let hours: Int

        public init(meanHR: Double, sdHR: Double, meanRMSSD: Double?, sdRMSSD: Double, hours: Int) {
            self.meanHR = meanHR
            self.sdHR = sdHR
            self.meanRMSSD = meanRMSSD
            self.sdRMSSD = sdRMSSD
            self.hours = hours
        }
    }

    /// The calm reference from a `DaytimeStress` read of the day before the night: its waking hours
    /// that ENDED by `endingBy` (the sleep's start, so no hour of the sleep itself joins its own
    /// reference), excluding hours the motion gate masked and hours too thin to have a mean heart rate.
    /// nil under `minReferenceHours`.
    public static func reference(wakingHours: [DaytimeStress.HourPoint], endingBy: Int) -> Reference? {
        let usable = wakingHours.filter { hour in
            hour.startTs + DaytimeStress.bucketSeconds <= endingBy && !hour.maskedForActivity && hour.meanHR != nil
        }
        let hrMeans = usable.compactMap(\.meanHR)
        guard hrMeans.count >= minReferenceHours,
              let calmHR = DaytimeStress.calmReference(hrMeans, calmIsLow: true) else { return nil }
        let rmssds = usable.compactMap(\.rmssd)
        let calmRMSSD = DaytimeStress.calmReference(rmssds, calmIsLow: false)
        let sdHR = max(minSpreadBPM, DaytimeStress.std(hrMeans, mean: DaytimeStress.mean(hrMeans)))
        let sdRMSSD = calmRMSSD == nil
            ? 0 : max(minSpreadRMSSD, DaytimeStress.std(rmssds, mean: DaytimeStress.mean(rmssds)))
        return Reference(meanHR: calmHR, sdHR: sdHR, meanRMSSD: calmRMSSD, sdRMSSD: sdRMSSD,
                         hours: hrMeans.count)
    }

    // MARK: Output

    /// A level band on the shared 0–3 scale.
    public enum Band: String, Equatable, Sendable, CaseIterable {
        case low, medium, high

        public init(level: Double) {
            if level >= SleepStress.highFloor { self = .high } else if level >= SleepStress.mediumFloor {
                self = .medium
            } else { self = .low }
        }
    }

    /// One scored (or unscored) window of the curve.
    public struct Window: Equatable, Sendable {
        /// Unix seconds at the window's start.
        public let startTs: Int
        /// Seconds the window covers (the last window of the sleep may be shorter than `windowSeconds`).
        public let seconds: Int
        /// 0–3, or nil when the window had too little heart rate to score.
        public let level: Double?
        /// Mean heart rate over the window (bpm), or nil under the sample gate.
        public let meanHR: Double?
        /// RMSSD over the window's clean R-R (ms), or nil.
        public let rmssd: Double?
        /// True for a window inside the sleep; only these count toward the shares.
        public let inSleep: Bool

        public init(startTs: Int, seconds: Int, level: Double?, meanHR: Double?, rmssd: Double?, inSleep: Bool) {
            self.startTs = startTs
            self.seconds = seconds
            self.level = level
            self.meanHR = meanHR
            self.rmssd = rmssd
            self.inSleep = inSleep
        }

        /// The window's band, when scored.
        public var band: Band? { level.map(Band.init(level:)) }
    }

    /// The night's read.
    public struct Result: Equatable, Sendable {
        /// Every window from the chart's start to its end, in time order.
        public let windows: [Window]
        /// Seconds of SCORED sleep, and how they split across the bands.
        public let scoredSeconds: Int
        public let lowSeconds: Int
        public let mediumSeconds: Int
        public let highSeconds: Int

        public init(windows: [Window], scoredSeconds: Int, lowSeconds: Int, mediumSeconds: Int, highSeconds: Int) {
            self.windows = windows
            self.scoredSeconds = scoredSeconds
            self.lowSeconds = lowSeconds
            self.mediumSeconds = mediumSeconds
            self.highSeconds = highSeconds
        }

        /// Nothing scored.
        public static let empty = Result(windows: [], scoredSeconds: 0, lowSeconds: 0, mediumSeconds: 0,
                                         highSeconds: 0)

        /// True when at least one sleep window was scored.
        public var hasScore: Bool { scoredSeconds > 0 }

        /// A band's share of the scored sleep, 0–100, or nil with nothing scored.
        public func percent(_ band: Band) -> Double? {
            guard scoredSeconds > 0 else { return nil }
            return Double(seconds(band)) / Double(scoredSeconds) * 100
        }

        /// A band's scored seconds.
        public func seconds(_ band: Band) -> Int {
            switch band {
            case .low: return lowSeconds
            case .medium: return mediumSeconds
            case .high: return highSeconds
            }
        }

        /// HIGH SLEEP STRESS: the share of the scored sleep in the HIGH band, 0–100.
        public var highPercent: Double? { percent(.high) }
    }

    // MARK: Analysis

    /// Score the sleep `[sleepStart, sleepEnd)` against `reference`, in windows of `windowSeconds`
    /// anchored on `sleepStart`.
    ///
    /// - Parameters:
    ///   - hr: heart rate covering at least the sleep (any order; samples outside the chart are ignored).
    ///   - rr: R-R intervals over the same span, in emission order (order matters for RMSSD).
    ///   - chartStart: score whole windows from here (≤ `sleepStart`) for the curve's lead-in; they never
    ///     enter a share. Defaults to the sleep's start.
    ///   - chartEnd: score windows to here (≥ `sleepEnd`) for the curve's tail. Defaults to the sleep's end.
    public static func analyze(hr: [HRSample], rr: [RRInterval], sleepStart: Int, sleepEnd: Int,
                               reference: Reference, chartStart: Int? = nil, chartEnd: Int? = nil) -> Result {
        guard sleepEnd > sleepStart, !hr.isEmpty else { return .empty }
        let w = windowSeconds
        // The grid is anchored on the sleep's start, so the sleep tiles exactly and the lead-in windows
        // line up behind it.
        let leadIn = max(0, sleepStart - min(chartStart ?? sleepStart, sleepStart))
        let first = sleepStart - (leadIn / w) * w
        let last = max(chartEnd ?? sleepEnd, sleepEnd)

        // Window boundaries: whole windows before the sleep, the sleep itself (its last window clipped
        // at `sleepEnd`), then whole windows after it.
        var bounds: [(start: Int, end: Int, inSleep: Bool)] = []
        var t = first
        while t < sleepStart {
            bounds.append((t, t + w, false))
            t += w
        }
        t = sleepStart
        while t < sleepEnd {
            bounds.append((t, min(t + w, sleepEnd), true))
            t += w
        }
        t = sleepEnd
        while t + w <= last {
            bounds.append((t, t + w, false))
            t += w
        }
        guard !bounds.isEmpty else { return .empty }

        // Bucket the samples into those windows (binary search on the sorted starts).
        let starts = bounds.map(\.start)
        func index(of ts: Int) -> Int? {
            guard ts >= first, let lastBound = bounds.last, ts < lastBound.end else { return nil }
            var lo = 0, hi = starts.count - 1
            while lo < hi {
                let mid = (lo + hi + 1) / 2
                if starts[mid] <= ts { lo = mid } else { hi = mid - 1 }
            }
            return ts < bounds[lo].end ? lo : nil
        }
        var hrByWindow = [[Double]](repeating: [], count: bounds.count)
        for s in hr {
            if let i = index(of: s.ts) { hrByWindow[i].append(Double(s.bpm)) }
        }
        var rrByWindow = [[Double]](repeating: [], count: bounds.count)
        for s in rr {
            if let i = index(of: s.ts) { rrByWindow[i].append(Double(s.rrMs)) }
        }

        var windows: [Window] = []
        windows.reserveCapacity(bounds.count)
        var scored = 0, low = 0, medium = 0, high = 0
        for (i, b) in bounds.enumerated() {
            let seconds = b.end - b.start
            // A clipped last window asks for the same coverage, pro rata (never fewer than 5 samples).
            let gate = max(5, Int((Double(minWindowHRSamples) * Double(seconds) / Double(w)).rounded(.up)))
            let hrs = hrByWindow[i]
            let meanHR = hrs.count >= gate ? DaytimeStress.mean(hrs) : nil
            let rmssd = HRVAnalyzer.analyze(rawRR: rrByWindow[i]).rmssd
            let level: Double? = meanHR.map { m in
                DaytimeStress.squash(DaytimeStress.rawScore(hr: m, meanHR: reference.meanHR, sdHR: reference.sdHR,
                                                            rmssd: rmssd, meanRMSSD: reference.meanRMSSD,
                                                            sdRMSSD: reference.sdRMSSD))
            }
            windows.append(Window(startTs: b.start, seconds: seconds, level: level, meanHR: meanHR,
                                  rmssd: meanHR == nil ? nil : rmssd, inSleep: b.inSleep))
            guard b.inSleep, let level else { continue }
            scored += seconds
            switch Band(level: level) {
            case .low: low += seconds
            case .medium: medium += seconds
            case .high: high += seconds
            }
        }
        return Result(windows: windows, scoredSeconds: scored, lowSeconds: low, mediumSeconds: medium,
                      highSeconds: high)
    }
}
