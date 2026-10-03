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
    /// On a card the chip is the card's nested white 10% (f02: #474C50 on a #34393D tile); on the page,
    /// a card's white 10% (h01: #383D41 on #212830). Either way it lightens what it sits on.
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
            .fill(onCard ? PulseTheme.nested : PulseTheme.card))
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
                    .font(.system(size: PulseActivityStyle.Glyph.tile, weight: .light))
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
                Group {
                    if let tail = stat.valueTail {
                        // A clock's seconds smaller and grey, as the zone rows draw them (g15 ":18").
                        Text(stat.value).font(PulseType.font(.largeValue)).foregroundColor(PulseTheme.textPrimary)
                            + Text(tail).font(PulseType.font(.tileValue)).foregroundColor(PulseTheme.textSecondary)
                    } else {
                        Text(stat.value)
                            .font(PulseType.font(.largeValue))
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                }
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
        .accessibilityValue([stat.unit.isEmpty ? stat.value + (stat.valueTail ?? "") : "\(stat.value) \(stat.unit)",
                             stat.accessibilityComparison].compactMap { $0 }.joined(separator: ", "))
    }
}

/// "KEY STATISTICS" with "VS. 30 DAY AVERAGE" at the right, over a row of tiles that scrolls sideways.
struct PulseActivityStatsRow: View {
    let title: String
    let caption: String
    let stats: [ActivityKeyStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
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
/// 162-171 BPM 2%" with the time at the right (seconds smaller), then the zone-coloured bar over the hatched
/// track with this sport's typical share boxed. A zone with no time is a short card whose TEXT dims, the
/// card's fill staying as its neighbours' (hc82). Without heart rate that spans the activity there is no
/// share to state, so the row shows the time alone.
struct PulseActivityZoneRow: View {
    let row: ActivityZoneRow
    var showsShare = true

    /// The time's h:mm and its smaller ":ss": caps ≈1.45× the zone label's and ≈0.72 of each other, as h01,
    /// f09 and hc82 measure them.
    @ScaledMetric(relativeTo: .body) private var timeSize: CGFloat = 16
    @ScaledMetric(relativeTo: .footnote) private var secondsSize: CGFloat = 12

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
                // The range at 70% (§2.6.18; h01 #C8CBCE, hc82 #CACDD1).
                Text(row.range)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showsShare {
                    Text(shareText)
                        .activityNumeral(13, relativeTo: .caption)
                        .foregroundStyle(row.zone == 0 ? PulseTheme.textPrimary : color)
                        .fixedSize()
                }
                Spacer(minLength: 6)
                durationText
                    .fixedSize()
            }
            if showsShare && row.seconds > 0 {
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
        // Zero zones dim their content to 40% (§2.6.18); the card keeps its fill (hc82).
        .opacity(row.seconds > 0 ? 1 : 0.4)
        // ≈65 pt with its bar (h01 66, f09 65.5, g16 64) and ≈43 pt without (hc82's empty card is 0.64 of
        // its full one), the time's digits ≈13 pt under the card's top edge, as the 2026 captures draw them.
        .padding(.horizontal, 14)
        .padding(.top, 10.5)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Zone \(row.zone), \(row.range)"))
        .accessibilityValue(showsShare ? String(localized: "\(shareText), \(ActivityFormat.clock(seconds: row.seconds))")
                                       : ActivityFormat.clock(seconds: row.seconds))
    }

    /// "0:21:04" with the seconds smaller, at 70% (hc82 ":04" #D2D4D5).
    private var durationText: some View {
        let clock = ActivityFormat.clock(seconds: row.seconds)
        let head = String(clock.dropLast(3))
        let tail = String(clock.suffix(3))
        let big = min(timeSize, 16 * 1.5), small = min(secondsSize, 12 * 1.5)
        return (Text(head).font(PulseType.numeral(big)).foregroundColor(PulseTheme.textPrimary)
                + Text(tail).font(PulseType.numeral(small)).foregroundColor(PulseTheme.textSecondary))
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
                .activityNumeral(13, relativeTo: .caption)
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

    /// The y range and its gridlines: 25 bpm steps over a wide range, finer over a narrow one. Every gridline
    /// is labelled, the lowest included, so the plot runs a little below it to a base of its own, which the
    /// fill and the edge dots stand on (g24: 100 / 80 / 60 / 40 over an empty chart; h01, f09).
    private var axis: (domain: ClosedRange<Double>, ticks: [Double]) {
        let values = points.compactMap(\.value)
        guard let lo = values.min(), let hi = values.max() else { return (32...100, [40, 60, 80, 100]) }
        let range = hi - lo
        let step: Double = range > 70 ? 25 : (range > 30 ? 20 : 10)
        let bottom = floor((lo - 4) / step) * step
        let top = max(bottom + step * 2, ceil((hi + 4) / step) * step)
        let ticks = stride(from: bottom, through: top, by: step).map { $0 }
        return ((bottom - step * 0.4)...top, ticks)
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
                            // y labels inside the plot at the left (h01, 82), one on every gridline.
                            ForEach(axis.ticks, id: \.self) { tick in
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
                    .activityNumeral(12, relativeTo: .caption, maxScale: 1.4)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .offset(x: max(4, startX - 2))
                Text(PulseFormat.clock(window.upperBound))
                    .activityNumeral(12, relativeTo: .caption, maxScale: 1.4)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .frame(width: max(0, endX + 2), alignment: .trailing)
            }
        }
        .frame(height: 20)
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
                            .overlay(Circle().strokeBorder(PulseActivityStyle.mapMarker, lineWidth: 3))
                    }
                }
                if let last = coordinates.last {
                    Annotation("", coordinate: last) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: PulseActivityStyle.Glyph.mapMarker, weight: .bold))
                            .foregroundStyle(PulseActivityStyle.mapInk)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(PulseActivityStyle.mapMarker))
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
                .foregroundStyle(PulseActivityStyle.mapInk)
                .padding(.leading, 20)
                .padding(.top, 24)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: PulseActivityStyle.Glyph.share, weight: .semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: 34, height: 32)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
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
        .clipShape(RoundedRectangle(cornerRadius: PulseActivityStyle.routeCardRadius, style: .circular))
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
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
            .fill(PulseTheme.Activity.routeShare))
    }

    private func stat(_ value: String, _ unit: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(PulseType.numeral(26)).foregroundStyle(PulseTheme.textPrimary)
                if !unit.isEmpty {
                    Text(unit).pulseText(.tileUnit).foregroundStyle(PulseActivityStyle.mapStatUnit)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseActivityStyle.mapStatLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Dialog card

/// The dialog card (§2.6 item 30) as the activity flows need it: a message that can carry emphasised runs
/// (c06 sets the times and the overlapping activities in white bold) and a TEXT second action (§3.8 [Z]:
/// "END & SAVE" on the white capsule, "DISCARD" as text). Built from the same tokens as `PulseDialogCard`,
/// which offers neither (a candidate for the foundation's card).
struct PulseActivityDialogCard: View {
    let title: String
    let message: AttributedString
    let primaryTitle: String
    let primary: () -> Void
    var secondaryTitle: String?
    var secondary: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            PulseTheme.dialogScrim.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    PulseCloseButton(action: onClose)
                }
                .padding(.bottom, -12)
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(primaryTitle, action: primary)
                    .buttonStyle(.pulseFilledWhite)
                if let secondaryTitle, let secondary {
                    Button(action: secondary) {
                        Text(secondaryTitle)
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, secondaryTitle == nil ? 20 : 8)
            .padding(.top, 8)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .circular)
                .fill(LinearGradient(colors: [PulseTheme.dialogTop, PulseTheme.dialogBottom], startPoint: .top,
                                     endPoint: .bottom)))
            .padding(.horizontal, 32)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .environment(\.colorScheme, .dark)
    }

    /// A run set in white bold inside a dialog's grey message.
    static func emphasised(_ text: String) -> AttributedString {
        var run = AttributedString(text)
        run.inlinePresentationIntent = .stronglyEmphasized
        run.foregroundColor = PulseTheme.textPrimary
        return run
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
                        .fill(PulseActivityStyle.scrubberWindow)
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
                           label: String(localized: "Start"), value: start, move: { location in
                        let date = span.lowerBound.addingTimeInterval(total * Double(max(0, min(1, location / geo.size.width))))
                        start = min(date, end.addingTimeInterval(-60))
                    }, step: { minutes in
                        start = min(start.addingTimeInterval(minutes * 60), end.addingTimeInterval(-60))
                    })
                    handle(at: min(max(0, x(end)), geo.size.width), height: geo.size.height,
                           label: String(localized: "End"), value: end, move: { location in
                        let date = span.lowerBound.addingTimeInterval(total * Double(max(0, min(1, location / geo.size.width))))
                        end = min(Date(), max(date, start.addingTimeInterval(60)))
                    }, step: { minutes in
                        end = min(Date(), max(end.addingTimeInterval(minutes * 60), start.addingTimeInterval(60)))
                    })
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

    /// A dashed handle with a white knob. VoiceOver adjusts it a minute at a time.
    private func handle(at x: CGFloat, height: CGFloat, label: String, value: Date,
                        move: @escaping (CGFloat) -> Void, step: @escaping (Double) -> Void) -> some View {
        ZStack(alignment: .bottom) {
            Path { p in
                p.move(to: CGPoint(x: 22, y: 0))
                p.addLine(to: CGPoint(x: 22, y: height - 10))
            }
            .stroke(PulseActivityStyle.scrubberHandle, style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
            Circle()
                .fill(PulseTheme.textPrimary)
                .frame(width: 20, height: 20)
        }
        .frame(width: 44, height: height)
        .contentShape(Rectangle())
        .offset(x: x - 22)
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("pulse.scrubber")).onChanged { value in
            move(value.location.x)
        })
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(PulseFormat.clock(value))
        .accessibilityHint(String(localized: "Swipe up or down to move it by a minute"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(1)
            case .decrement: step(-1)
            @unknown default: break
            }
        }
    }
}
#endif
