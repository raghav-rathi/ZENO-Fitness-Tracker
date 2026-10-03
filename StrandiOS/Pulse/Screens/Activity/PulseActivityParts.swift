#if os(iOS)
import SwiftUI
import Charts
import MapKit

// MARK: - Pieces the activity screens share (WHOOP_UI_SPEC §3.6, §3.8)
//
// Group "activity" only; built from the theme's tokens and the shared components. Anything here another
// group needs should move to Components/ through the foundation owner.

// MARK: Average chip

/// The grey chip beside a headline or under a tile: the comparison's AVERAGE with a ▲ / ▼ / ● saying where
/// today sits against it ("▲ 9.7", "▼ 131bpm", "● 15.9", activity-flows-2026/d01, e01, h01). Grey whatever
/// the direction: these comparisons have no good or bad side.
struct PulseActivityAverageChip: View {
    let text: String
    let direction: PulseTrend.Direction
    /// On a card the chip darkens the card; on the page it lightens the page.
    var onCard = false

    var body: some View {
        HStack(spacing: 4) {
            switch direction {
            case .flat:
                Circle().frame(width: 5, height: 5)
            case .up, .down:
                PulseTriangle(pointsUp: direction == .up).frame(width: 7, height: 6)
            }
            Text(text).font(PulseType.numeral(12))
        }
        .foregroundStyle(PulseTheme.textPrimary.opacity(0.85))
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
            .fill(onCard ? Color.black.opacity(0.25) : PulseTheme.card))
        .accessibilityHidden(true)
    }
}

// MARK: Headline stat

/// "13.8 ▲ 9.7" over "ACTIVITY STRAIN" (§3.6 item 4): a large condensed number, its average chip on the
/// number's baseline, the label under it.
struct PulseActivityHeadline: View {
    let value: String
    var unit: String?
    var smallSuffix: String?
    var color: Color = PulseTheme.textPrimary
    let label: String
    var average: String?
    var direction: PulseTrend.Direction?
    var accessibilityValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(value)
                        .font(PulseType.font(.largeValue))
                        .foregroundStyle(color)
                    if let smallSuffix {
                        Text(smallSuffix)
                            .font(PulseType.numeral(20))
                            .foregroundStyle(color)
                    }
                    if let unit {
                        Text(unit)
                            .pulseText(.tileUnit)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .padding(.leading, 3)
                    }
                }
                .lineLimit(1)
                .fixedSize()
                if let average, let direction {
                    PulseActivityAverageChip(text: average, direction: direction)
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 12 }
                }
            }
            PulseWordWrapText(label, style: .label)
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue ?? value)
    }
}

// MARK: Key statistics tile

/// One KEY STATISTICS / SESSION METRICS tile (§3.6 item 10): icon and caps label, the value at 34 pt with
/// its unit, and the average chip; ≈160 × 128 on a white-10% card.
struct PulseActivityStatTile: View {
    let stat: ActivityKeyStat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: stat.icon)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 22)
                Text(stat.title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 10)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(stat.value)
                    .font(PulseType.font(.largeValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !stat.unit.isEmpty {
                    Text(stat.unit)
                        .pulseText(.tileUnit)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let average = stat.average, let direction = stat.direction {
                PulseActivityAverageChip(text: average, direction: direction, onCard: true)
            } else {
                Color.clear.frame(height: 20)
            }
        }
        .padding(16)
        .frame(width: 171, height: 128, alignment: .topLeading)
        .pulseCardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stat.title)
        .accessibilityValue([stat.unit.isEmpty ? stat.value : "\(stat.value) \(stat.unit)",
                             stat.accessibilityComparison].compactMap { $0 }.joined(separator: ", "))
    }
}

/// "KEY STATISTICS" with "VS. 30 DAY AVERAGE" at the right, over a row of tiles that scrolls sideways.
struct PulseActivityStatsRow: View {
    let title: String
    let caption: String
    let stats: [ActivityKeyStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text(caption)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(stats) { PulseActivityStatTile(stat: $0) }
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .padding(.horizontal, -PulseTheme.Layout.pageMargin)
        }
    }
}

// MARK: Zone rows

/// One heart-rate zone in its own card (§2.6 item 18 as the 2026 captures draw it, h01, 82, g16): "ZONE 4
/// 162-171 BPM 2%" with the time at the right (seconds smaller and grey), then the zone-coloured bar over
/// the hatched track with this sport's typical share boxed. A zone with no time is a short dimmed card
/// with no bar.
struct PulseActivityZoneRow: View {
    let row: ActivityZoneRow

    private var color: Color { PulseTheme.Zone.color(row.zone) }

    private var shareText: String {
        let pct = row.share * 100
        if row.seconds > 0 && pct < 0.5 { return "<1%" }
        return "\(Int(pct.rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(String(localized: "Zone \(row.zone)"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                Text(row.range)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(shareText)
                    .font(PulseType.numeral(13))
                    .foregroundStyle(row.zone == 0 ? PulseTheme.textPrimary : color)
                    .fixedSize()
                Spacer(minLength: 6)
                durationText
                    .fixedSize()
            }
            if row.seconds > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        PulseHatchedTrack()
                        RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                            .fill(color)
                            .frame(width: max(5, geo.size.width * CGFloat(min(1, row.share))))
                        if let typical = row.typical {
                            PulseTypicalRangeBox()
                                .frame(width: max(6, geo.size.width * CGFloat(typical.upperBound - typical.lowerBound)))
                                .offset(x: geo.size.width * CGFloat(typical.lowerBound))
                        }
                    }
                }
                .frame(height: 14)
            }
        }
        // 66 pt with its bar and 44 pt without, as the 2026 captures measure (h01, 82).
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .opacity(row.seconds > 0 ? 1 : 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Zone \(row.zone), \(row.range)"))
        .accessibilityValue(String(localized: "\(shareText), \(ActivityFormat.clock(seconds: row.seconds))"))
    }

    /// "0:21:04" with the seconds smaller and grey (§2.6 item 18).
    private var durationText: some View {
        let clock = ActivityFormat.clock(seconds: row.seconds)
        let head = String(clock.dropLast(3))
        let tail = String(clock.suffix(3))
        return (Text(head).font(PulseType.numeral(19)).foregroundColor(PulseTheme.textPrimary)
                + Text(tail).font(PulseType.numeral(13)).foregroundColor(PulseTheme.textTertiary))
    }
}

/// "▦ TYPICAL RANGE" at the left and "DURATION 0:25:59" at the right, above the zone rows.
struct PulseActivityZoneLegend: View {
    let duration: Double
    var showsTypical: Bool

    var body: some View {
        HStack(spacing: 8) {
            if showsTypical {
                PulseTypicalRangeBox()
                    .frame(width: 14, height: 16)
                Text(String(localized: "Typical range"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            Text(String(localized: "Duration"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(ActivityFormat.clock(seconds: duration))
                .font(PulseType.numeral(13))
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Heart-rate chart

/// A touch on the activity chart: the reading under the finger.
struct PulseActivityScrub: Equatable {
    let date: Date
    let bpm: Double
}

/// The activity's heart rate, edge to edge (§3.6 item 6, §2.7 "HR area"): the line over a soft fill in the
/// activity colour, a little of the time before and after drawn dimmer, dashed rules at the start and end
/// with a dot at their foot and the times under them, y labels inside the plot at the left. Touch and
/// hold to read a moment ("132 bpm" over "10:34"); the headline shows it while the finger is down.
struct PulseActivityHRChart: View {
    let points: [PulseTimeValue]
    let window: ClosedRange<Date>
    let span: ClosedRange<Date>
    var color: Color = PulseTheme.strain
    var height: CGFloat = 186
    @Binding var scrub: PulseActivityScrub?

    /// The y range and its gridlines: 25 bpm steps over a wide range, finer over a narrow one.
    private var axis: (domain: ClosedRange<Double>, ticks: [Double]) {
        let values = points.compactMap(\.value)
        guard let lo = values.min(), let hi = values.max() else { return (40...100, [40, 60, 80, 100]) }
        let range = hi - lo
        let step: Double = range > 70 ? 25 : (range > 30 ? 20 : 10)
        let bottom = floor((lo - 4) / step) * step
        let top = max(bottom + step * 2, ceil((hi + 4) / step) * step)
        let ticks = stride(from: bottom, through: top, by: step).map { $0 }
        return (bottom...top, ticks)
    }

    private var runs: [(Int, [PulseTimeValue])] {
        var out: [[PulseTimeValue]] = [[]]
        for p in points {
            if p.value == nil {
                if !(out.last?.isEmpty ?? true) { out.append([]) }
            } else {
                out[out.count - 1].append(p)
            }
        }
        return out.filter { !$0.isEmpty }.enumerated().map { ($0.offset, $0.element) }
    }

    var body: some View {
        let axis = self.axis
        VStack(spacing: 4) {
            Chart {
                ForEach(runs, id: \.0) { index, run in
                    ForEach(run) { p in
                        if let v = p.value {
                            AreaMark(x: .value("Time", p.date), yStart: .value("Base", axis.domain.lowerBound),
                                     yEnd: .value("BPM", v), series: .value("Run", index))
                                .foregroundStyle(LinearGradient(colors: [color.opacity(0.42), color.opacity(0.0)],
                                                                startPoint: .top, endPoint: .bottom))
                                .opacity(window.contains(p.date) ? 1 : 0.45)
                            LineMark(x: .value("Time", p.date), y: .value("BPM", v), series: .value("Run", index))
                                .foregroundStyle(color.opacity(window.contains(p.date) ? 1 : 0.55))
                                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                ForEach([window.lowerBound, window.upperBound], id: \.self) { edge in
                    RuleMark(x: .value("Edge", edge))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Edge", edge), y: .value("Foot", axis.domain.lowerBound))
                        .symbolSize(18)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                if let scrub {
                    RuleMark(x: .value("Cursor", scrub.date))
                        .foregroundStyle(PulseTheme.textPrimary.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Cursor", scrub.date), y: .value("BPM", scrub.bpm))
                        .symbolSize(70)
                        .foregroundStyle(color)
                }
            }
            .chartXScale(domain: span)
            .chartYScale(domain: axis.domain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                }
            }
            .chartYAxis {
                AxisMarks(values: axis.ticks) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnPage)
                }
            }
            .chartPlotStyle { $0.clipped() }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if let plotAnchor = proxy.plotFrame {
                        let plot = geo[plotAnchor]
                        ZStack(alignment: .topLeading) {
                            // y labels inside the plot at the left (h01, 82).
                            ForEach(axis.ticks.dropFirst(), id: \.self) { tick in
                                if let y = proxy.position(forY: tick) {
                                    Text("\(Int(tick))")
                                        .font(PulseType.font(.axis))
                                        .foregroundStyle(PulseTheme.textTertiary)
                                        .position(x: plot.minX + 14, y: plot.minY + y)
                                }
                            }
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .frame(width: plot.width, height: plot.height)
                                .offset(x: plot.minX, y: plot.minY)
                                .gesture(scrubGesture(proxy: proxy, plotMinX: plot.minX))
                        }
                    }
                }
            }
            .frame(height: height)
            edgeLabels
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart rate"))
        .accessibilityValue(summary)
    }

    /// The start and end times under their rules: the start's left edge on its rule, the end's right edge.
    private var edgeLabels: some View {
        GeometryReader { geo in
            let total = span.upperBound.timeIntervalSince(span.lowerBound)
            let startX = total > 0 ? geo.size.width * window.lowerBound.timeIntervalSince(span.lowerBound) / total : 0
            let endX = total > 0 ? geo.size.width * window.upperBound.timeIntervalSince(span.lowerBound) / total
                : geo.size.width
            ZStack(alignment: .topLeading) {
                Text(PulseFormat.clock(window.lowerBound))
                    .font(PulseType.numeral(12))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .offset(x: max(4, startX - 2))
                Text(PulseFormat.clock(window.upperBound))
                    .font(PulseType.numeral(12))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .frame(width: max(0, endX + 2), alignment: .trailing)
            }
        }
        .frame(height: 16)
    }

    private func scrubGesture(proxy: ChartProxy, plotMinX: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.18)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value, let drag else { return }
                let x = drag.location.x - plotMinX
                guard let date: Date = proxy.value(atX: x) else { return }
                let nearest = points.filter { $0.value != nil }
                    .min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
                if let nearest, let bpm = nearest.value {
                    let next = PulseActivityScrub(date: nearest.date, bpm: bpm)
                    if scrub != next { scrub = next }
                }
            }
            .onEnded { _ in scrub = nil }
    }

    private var summary: String {
        let inside = points.filter { window.contains($0.date) }.compactMap(\.value)
        guard let lo = inside.min(), let hi = inside.max() else { return String(localized: "No heart-rate data") }
        return String(localized: "\(Int(lo.rounded())) to \(Int(hi.rounded())) beats per minute")
    }
}

// MARK: Route map

/// The ROUTE card (§3.6 item 12, f02, f06): a light standard map of the route (#0A8AF0), a blue start dot
/// with a white ring and a checkered finish, "ROUTE" in black caps at the top-left, an export button at the
/// top-right, and the near-black stats panel over the bottom.
struct PulseActivityRouteCard: View {
    let route: ActivityRouteSummary
    let onExport: () -> Void

    private var coordinates: [CLLocationCoordinate2D] {
        route.points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
    }

    private var region: MKCoordinateRegion {
        let lats = route.points.map(\.lat), lons = route.points.map(\.lon)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        // Room for the stats panel under the route: the map frames the route in its upper part.
        let span = MKCoordinateSpan(latitudeDelta: max(0.004, (maxLat - minLat) * 1.9),
                                    longitudeDelta: max(0.004, (maxLon - minLon) * 1.4))
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta * 0.12,
                                                                 longitude: center.longitude), span: span)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: .region(region), interactionModes: []) {
                MapPolyline(coordinates: coordinates)
                    .stroke(PulseTheme.Activity.mapRoute, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                if let first = coordinates.first {
                    Annotation("", coordinate: first) {
                        Circle()
                            .fill(PulseTheme.Activity.mapRoute)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                    }
                }
                if let last = coordinates.last {
                    Annotation("", coordinate: last) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white))
                    }
                }
            }
            .mapStyle(.standard)
            .environment(\.colorScheme, .light)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            statsPanel
                .padding(.horizontal, 12)
                .padding(.bottom, 34)
        }
        .overlay(alignment: .topLeading) {
            Text(String(localized: "Route"))
                .pulseText(.cardTitle)
                .foregroundStyle(Color.black)
                .padding(.leading, 20)
                .padding(.top, 24)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 34, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(PulseTheme.Activity.routeShare))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .padding(.trailing, 12)
            .padding(.top, 14)
            .accessibilityLabel(String(localized: "Export route"))
        }
        .frame(height: 390)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Route, \(route.distance.value) \(route.distance.unit)"))
    }

    private var statsPanel: some View {
        HStack(alignment: .top, spacing: 0) {
            stat(route.distance.value, route.distance.unit, String(localized: "Distance"))
            stat(route.rate.value, route.rate.unit, route.rateTitle)
            stat(route.duration, "", String(localized: "Duration"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PulseTheme.Activity.routeShare))
    }

    private func stat(_ value: String, _ unit: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(PulseType.numeral(26)).foregroundStyle(Color.white)
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Edit scrubber [Z]

/// The Edit sheet's heart-rate scrubber (§3.9 [Z]): the heart rate around the activity with two dashed
/// handles for its start and end. Dragging a handle moves that time (it writes the same bindings the pills
/// do), never closer than a minute to the other or past now.
struct PulseActivityScrubber: View {
    let points: [PulseTimeValue]
    /// The activity as it was stored: with the heart rate, it fixes the scrubber's time span, so a handle
    /// moving never moves the scale under the finger.
    let original: ClosedRange<Date>
    @Binding var start: Date
    @Binding var end: Date

    private var span: ClosedRange<Date> {
        let dates = points.map(\.date)
        let lo = min(dates.min() ?? original.lowerBound, original.lowerBound)
        let hi = max(dates.max() ?? original.upperBound, original.upperBound)
        return lo...max(hi, lo.addingTimeInterval(60))
    }

    private var domain: ClosedRange<Double> {
        let values = points.compactMap(\.value)
        guard let lo = values.min(), let hi = values.max() else { return 40...120 }
        return (lo - 6)...(hi + 6)
    }

    var body: some View {
        let span = self.span
        let total = span.upperBound.timeIntervalSince(span.lowerBound)
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let x = { (date: Date) -> CGFloat in geo.size.width * CGFloat(date.timeIntervalSince(span.lowerBound) / total) }
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: max(0, x(end) - x(start)), height: geo.size.height)
                        .offset(x: x(start))
                    Chart(points) { p in
                        if let v = p.value {
                            AreaMark(x: .value("Time", p.date), yStart: .value("Base", domain.lowerBound),
                                     yEnd: .value("BPM", v))
                                .foregroundStyle(LinearGradient(colors: [PulseTheme.strain.opacity(0.4), PulseTheme.strain.opacity(0)],
                                                                startPoint: .top, endPoint: .bottom))
                                .opacity((start...end).contains(p.date) ? 1 : 0.4)
                            LineMark(x: .value("Time", p.date), y: .value("BPM", v))
                                .foregroundStyle(PulseTheme.strain.opacity((start...end).contains(p.date) ? 1 : 0.45))
                                .lineStyle(StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                        }
                    }
                    .chartXScale(domain: span)
                    .chartYScale(domain: domain)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    handle(at: min(max(0, x(start)), geo.size.width), height: geo.size.height,
                           label: String(localized: "Start")) { location in
                        let date = span.lowerBound.addingTimeInterval(total * Double(max(0, min(1, location / geo.size.width))))
                        start = min(date, end.addingTimeInterval(-60))
                    }
                    handle(at: min(max(0, x(end)), geo.size.width), height: geo.size.height,
                           label: String(localized: "End")) { location in
                        let date = span.lowerBound.addingTimeInterval(total * Double(max(0, min(1, location / geo.size.width))))
                        end = min(Date(), max(date, start.addingTimeInterval(60)))
                    }
                }
                .coordinateSpace(name: "pulse.scrubber")
            }
            .frame(height: 130)
            Text(String(localized: "Drag the handles to trim the activity."))
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .accessibilityElement(children: .contain)
    }

    private func handle(at x: CGFloat, height: CGFloat, label: String, move: @escaping (CGFloat) -> Void) -> some View {
        ZStack(alignment: .bottom) {
            Path { p in
                p.move(to: CGPoint(x: 22, y: 0))
                p.addLine(to: CGPoint(x: 22, y: height - 10))
            }
            .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .frame(width: 44, height: height)
        .contentShape(Rectangle())
        .offset(x: x - 22)
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("pulse.scrubber")).onChanged { value in
            move(value.location.x)
        })
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityHint(String(localized: "Drag to change the time"))
    }
}
#endif
