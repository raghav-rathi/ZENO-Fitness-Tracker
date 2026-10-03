#if os(iOS)
import Foundation
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore
import WhoopProtocol

// MARK: - Builders for the extras screens (group "extras")
//
// Everything here runs on the builder actor, off the main actor, and reuses the core readers so each fact
// has one resolver: the day window Home's Strain is scored over (`dayWindow`), the night that ended on the
// day (`nightGroups` + `SleepModel.mergeDay`, as Home's sleep row), the day's Recovery and Strain
// (`chargeDisplay`, `strainValue`, as Home's dials) and the workouts Home lists (`workoutRows`).

extension PulseSnapshotBuilder {

    // MARK: Day heart-rate timeline (§3.7)

    /// About one bucket per point of a landscape plot at day scale…
    static let timelineOverviewPoints = 720
    /// …and three times that for the ⊕ view.
    static let timelineDetailPoints = 2_160

    /// The day's heart-rate timeline: the existing full-day heart-rate read (`Repository.timelineSeries`,
    /// the Deep Timeline's SQL-bucketed path) over the window Home scores the day's Strain on, with the
    /// day's sleep, naps and activities as bands and the Recovery and Strain markers.
    func dayTimeline(_ r: PulseRequest) async -> DayTimelineSnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let window = await dayWindow(r)
        guard isCurrent(r) else { return nil }

        // The raw readings: the newest one ("Data synced to"), today's live Strain (the same read and
        // scorer Home's dial uses, shared through the per-refresh cache) and the low / average / high the
        // Strain dive prints for the same window.
        let raw = await heartRate(dayKey: r.day.key, from: window.from, to: window.to, isToday: r.day.isToday)
        guard isCurrent(r) else { return nil }
        let lastTs = raw.last?.ts
        let start = Date(timeIntervalSince1970: TimeInterval(window.from))
        let end: Date
        if r.day.isToday {
            // Today runs to the newest reading, as WHOOP's runs to its sync time; with none yet, to now.
            end = Date(timeIntervalSince1970: TimeInterval(lastTs ?? Int(r.now.timeIntervalSince1970)))
        } else {
            end = Date(timeIntervalSince1970: TimeInterval(window.to))
        }
        let span = max(end, start.addingTimeInterval(30 * 60))
        let toTs = Int(span.timeIntervalSince1970)

        let overview = await repo.timelineSeries(metric: .hr, from: window.from, to: toTs,
                                                 targetPoints: Self.timelineOverviewPoints)
        let detail = await repo.timelineSeries(metric: .hr, from: window.from, to: toTs,
                                               targetPoints: Self.timelineDetailPoints)
        guard isCurrent(r) else { return nil }

        // The night that ended on this day, and its naps: the same group and merge Home's sleep row reads.
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let workouts = await workoutRows()
        guard isCurrent(r) else { return nil }

        var periods: [DayTimelinePeriod] = []
        var wake: Date?
        if let g = group(endingOn: r.day.key, in: groups) {
            let night = SleepModel.mergeDay(g, habitualMidsleepSec: habitual, motionByStart: [:])
            if let night {
                let onset = night.onsetDate
                let nightEnd = Date(timeIntervalSince1970: TimeInterval(night.session.endTs))
                wake = nightEnd
                if let clipped = Self.clip(onset...nightEnd, to: start...span) {
                    let asleep = night.stages.asleep
                    periods.append(DayTimelinePeriod(
                        id: "night", kind: .sleep, start: clipped.lowerBound, end: clipped.upperBound,
                        symbol: "moon.fill", value: PulseFormat.hoursMinutes(asleep),
                        title: PulseScore.sleep.displayName,
                        accessibilityLabel: String(localized: "Sleep, \(Self.spokenDuration(minutes: asleep))")))
                }
            }
            for nap in naps(in: g, night: night) {
                guard let clipped = Self.clip(nap.start...nap.end, to: start...span) else { continue }
                periods.append(DayTimelinePeriod(
                    id: "nap-\(nap.id)", kind: .nap, start: clipped.lowerBound, end: clipped.upperBound,
                    symbol: "powersleep", value: PulseFormat.hoursMinutes(nap.asleepMin),
                    title: String(localized: "Nap"),
                    accessibilityLabel: String(localized: "Nap, \(Self.spokenDuration(minutes: nap.asleepMin))")))
            }
        }

        // The day's activities: the workouts Home lists for the same window (started inside it).
        for w in workouts where w.startTs >= window.from && w.startTs < window.to {
            let seconds = w.durationS ?? Double(max(w.endTs - w.startTs, 0))
            let wStart = Date(timeIntervalSince1970: TimeInterval(w.startTs))
            let wEnd = wStart.addingTimeInterval(max(seconds, 60))
            guard let clipped = Self.clip(wStart...wEnd, to: start...span) else { continue }
            let strain = w.strain.map { UnitFormatter.effortValue($0, scale: .whoop) }
            let name = WorkoutSource.displaySport(w.sport)
            let spoken = strain.map { String(localized: "\(name), Strain \(PulseFormat.oneDecimal($0))") } ?? name
            periods.append(DayTimelinePeriod(
                id: "workout-\(w.startTs)|\(w.sport)|\(w.source)", kind: .activity,
                start: clipped.lowerBound, end: clipped.upperBound,
                symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport),
                value: strain.map { PulseFormat.oneDecimal($0) }, title: name,
                accessibilityLabel: spoken))
        }
        periods.sort { $0.start < $1.start }

        // Recovery at wake: only the day's OWN score. A carried Recovery belongs to an earlier night.
        let (charge, _) = chargeDisplay(r, row: row)
        var recovery: DayTimelineMarker?
        if case .scored(let pct) = charge, let wake, wake >= start, wake <= span {
            recovery = DayTimelineMarker(date: wake, value: "\(PulseDisplay.displayedPercent(pct))%",
                                         band: PulseDisplay.recoveryBand(percent: pct))
        }
        // Strain at the newest reading: the value Home's dial shows for this day.
        let strainNow = strainValue(r, row: row, hr: r.day.isToday ? raw : nil)
        let strainAt = lastTs.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? span
        let strain = strainNow.map {
            DayTimelineMarker(date: min(strainAt, span), value: PulseFormat.oneDecimal($0), band: nil)
        }

        let bpms = raw.map(\.bpm)
        let average = bpms.isEmpty ? nil : Int((Double(bpms.reduce(0, +)) / Double(bpms.count)).rounded())
        guard isCurrent(r) else { return nil }
        return DayTimelineSnapshot(
            seq: r.seq, day: r.day, start: start, end: span,
            overview: Self.timelinePoints(overview), detail: Self.timelinePoints(detail),
            overviewBucket: overview.bucketSeconds, detailBucket: detail.bucketSeconds,
            periods: periods, recovery: recovery, strain: strain,
            lastReading: lastTs.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            lowest: bpms.min(), average: average, highest: bpms.max())
    }

    /// Buckets as plotted points, a new run wherever a bucket is missing (`hrGapSegments`, the rule every
    /// Pulse heart-rate line follows: a gap in wear is drawn as a gap).
    nonisolated static func timelinePoints(_ series: Repository.TimelineSeries) -> [DayTimelinePoint] {
        let ts = series.points.map { Int($0.date.timeIntervalSince1970) }
        let runs = hrGapSegments(bucketTs: ts, bucketSeconds: max(1, series.bucketSeconds))
        return series.points.enumerated().map { i, p in
            DayTimelinePoint(date: p.date, bpm: p.value, run: Int(runs[i]) ?? 0)
        }
    }

    /// `range` clipped to `bounds`, or nil when they do not overlap.
    nonisolated static func clip(_ range: ClosedRange<Date>, to bounds: ClosedRange<Date>) -> ClosedRange<Date>? {
        let lo = max(range.lowerBound, bounds.lowerBound)
        let hi = min(range.upperBound, bounds.upperBound)
        return hi > lo ? lo...hi : nil
    }

    /// "7 hours, 29 minutes", for VoiceOver.
    nonisolated static func spokenDuration(minutes: Double) -> String {
        let f = DateComponentsFormatter()
        f.unitsStyle = .full
        f.allowedUnits = minutes >= 60 ? [.hour, .minute] : [.minute]
        return f.string(from: max(0, minutes.rounded()) * 60) ?? PulseFormat.duration(minutes: minutes)
    }
}
#endif
