#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - The day heart-rate timeline's plot (WHOOP_UI_SPEC §3.7, §2.7)
//
// One plot, laid out by the screen for portrait or landscape:
//   - the label strip above the plot: a moon and the time asleep over the night, a sport glyph and Strain
//     over each activity, RECOVERY at wake and STRAIN at the newest reading; while scrubbing, only the
//     readout ("115 bpm" over "10:34");
//   - the plot: gridlines at 40–200 on a fixed 0–220 axis, the night and the activities as columns that fade
//     toward the foot with a 2 pt cap on top, heart rate in sleep blue while asleep, strain blue inside an
//     activity and white 45% otherwise, and the dashed Recovery / Strain markers;
//   - the y labels left of the plot and the time labels under it: the day's start and end, and whole hours.
// A drag scrubs (a dashed cursor and a dot on the line). Zoomed in (⊕), a drag pans and a short hold
// scrubs. VoiceOver reads a summary and steps a cursor through the day half an hour at a time.

/// Maps the timeline's instants and heart rates to points. The plot keeps `dataInset` before the day's
/// first instant so its time label clears the y axis; ⊕ stretches the data `zoom` times and
/// `scrollFraction` slides it (0 shows the day's start, 1 its end), so a pan survives a change of layout.
struct DayTimelineGeometry {
    let plot: CGRect
    let start: Date
    let end: Date
    var zoom: CGFloat = 1
    var scrollFraction: CGFloat = 0
    var dataInset: CGFloat = PulseExtrasTheme.Timeline.dataInset

    var span: TimeInterval { max(60, end.timeIntervalSince(start)) }
    /// The width the day's span is drawn across.
    var dataWidth: CGFloat { max(1, (plot.width - dataInset) * zoom) }
    var maxScroll: CGFloat { max(0, dataWidth + dataInset - plot.width) }
    /// How far the content has slid left, in points.
    var scroll: CGFloat { min(max(scrollFraction, 0), 1) * maxScroll }

    func x(_ date: Date) -> CGFloat {
        plot.minX + dataInset + CGFloat(date.timeIntervalSince(start) / span) * dataWidth - scroll
    }

    /// The instant under screen `x`, clamped to the day.
    func date(atX x: CGFloat) -> Date {
        let fraction = Double((x - plot.minX - dataInset + scroll) / dataWidth)
        return start.addingTimeInterval(min(max(fraction, 0), 1) * span)
    }

    func y(_ bpm: Double) -> CGFloat {
        let domain = PulseExtrasTheme.Timeline.bpmDomain
        let clamped = min(max(bpm, domain.lowerBound), domain.upperBound)
        let fraction = (clamped - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
        return plot.maxY - CGFloat(fraction) * plot.height
    }

    var visibleStart: Date { date(atX: plot.minX) }
    var visibleEnd: Date { date(atX: plot.maxX) }

    /// The scroll fraction that puts `date` at screen `x` at this zoom, clamped to the content.
    func scrollFraction(keeping date: Date, atX screenX: CGFloat) -> CGFloat {
        guard maxScroll > 0 else { return 0 }
        let contentX = dataInset + CGFloat(date.timeIntervalSince(start) / span) * dataWidth
        return min(max((contentX - (screenX - plot.minX)) / maxScroll, 0), 1)
    }

    /// The scroll fraction after dragging `dx` points from `fraction`.
    func scrollFraction(from fraction: CGFloat, draggedBy dx: CGFloat) -> CGFloat {
        guard maxScroll > 0 else { return 0 }
        return min(max(fraction - dx / maxScroll, 0), 1)
    }
}

/// The plot, its label strip and its axes, drawn into a canvas the size of the screen region it covers.
struct DayTimelineChart: View {
    let snapshot: DayTimelineSnapshot
    /// The plot and the strip above it, in this view's coordinates.
    let plot: CGRect
    let strip: CGRect
    /// The horizontal span every label (strip, readout, time axis) stays inside: the screen less its side
    /// safe-area insets and `labelInset`, so the edge never cuts a label.
    let labelBounds: ClosedRange<CGFloat>
    let zoom: CGFloat
    @Binding var scrollFraction: CGFloat
    @Binding var cursor: Date?

    @State private var drag: DragMode = .idle
    @State private var holdTask: Task<Void, Never>?
    /// Bumped when a hold turns into a scrub, for the haptic.
    @State private var scrubStarts = 0

    private enum DragMode: Equatable {
        case idle
        /// Zoomed in, finger down, not yet moved: a hold scrubs, a move pans.
        case deciding(startScroll: CGFloat)
        case panning(startScroll: CGFloat)
        case scrubbing
    }

    private typealias T = PulseExtrasTheme.Timeline

    private var geometry: DayTimelineGeometry {
        DayTimelineGeometry(plot: plot, start: snapshot.start, end: snapshot.end, zoom: zoom,
                           scrollFraction: scrollFraction)
    }

    /// The series for the current scale.
    private var points: [DayTimelinePoint] { zoom > 1.01 ? snapshot.detail : snapshot.overview }

    /// The activity under the cursor, lit like WHOOP's selected column.
    private var selectedActivity: String? {
        guard let cursor else { return nil }
        return snapshot.periods.first { $0.kind == .activity && $0.contains(cursor) }?.id
    }

    var body: some View {
        let g = geometry
        let points = self.points
        let selected = selectedActivity
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                DayTimelineDrawing(snapshot: snapshot, points: points, geometry: g, cursor: cursor,
                                   selectedActivity: selected)
                    .draw(in: &context)
            }
            .accessibilityHidden(true)

            yLabels(g)
            xLabels(g)
            stripLabels(g)
            if !snapshot.hasHeartRate { emptyMessage(g) }

            // The touch surface over the strip and the plot; it is also the chart's one VoiceOver element,
            // so its frame (not the whole screen this view covers) is what VoiceOver outlines.
            Color.clear
                .contentShape(Rectangle())
                .frame(width: plot.width, height: plot.maxY - strip.minY)
                .gesture(dragGesture(g))
                .accessibilityElement()
                .accessibilityLabel(accessibilityTitle)
                .accessibilityValue(accessibilityValue)
                .accessibilityHint(String(localized: "Swipe up or down to move through the day."))
                .accessibilityAdjustableAction { direction in
                    adjustCursor(direction)
                }
                .offset(x: plot.minX, y: strip.minY)
        }
        .sensoryFeedback(.selection, trigger: scrubStarts)
    }

    // MARK: Axes

    private func yLabels(_ g: DayTimelineGeometry) -> some View {
        ForEach(T.gridValues, id: \.self) { value in
            Text(PulseFormat.whole(value))
                .font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: T.yLabelWidth, alignment: .trailing)
                .position(x: plot.minX - T.yLabelGap - T.yLabelWidth / 2, y: g.y(value))
        }
        .accessibilityHidden(true)
    }

    private struct XLabel: Identifiable {
        let id: String
        let x: CGFloat
        let width: CGFloat
        let text: String
    }

    /// A time label centred on `x`, moved inward when it would cross `labelBounds` (the day's last label
    /// sits at the plot's end, which in portrait is 16 pt from the screen's edge).
    private func xLabel(_ id: String, at x: CGFloat, text: String) -> XLabel {
        let width = PulseTextMetrics.width(text, style: .axis)
        let half = width / 2
        let centre = labelBounds.upperBound - labelBounds.lowerBound >= width
            ? min(max(x, labelBounds.lowerBound + half), labelBounds.upperBound - half)
            : (labelBounds.lowerBound + labelBounds.upperBound) / 2
        return XLabel(id: id, x: centre, width: width, text: text)
    }

    /// The day's start and end (when in view) and whole hours between, at least `xLabelSpacing` apart and
    /// never touching the start and end labels.
    private func xLabelItems(_ g: DayTimelineGeometry) -> [XLabel] {
        var out: [XLabel] = []
        let lo = plot.minX - 1, hi = plot.maxX + 1
        let startX = g.x(snapshot.start), endX = g.x(snapshot.end)
        if startX >= lo && startX <= hi {
            out.append(xLabel("start", at: startX, text: PulseFormat.clock(snapshot.start)))
        }
        if endX >= lo && endX <= hi {
            out.append(xLabel("end", at: endX, text: PulseFormat.clock(snapshot.endLabelDate)))
        }
        let pointsPerHour = g.dataWidth / CGFloat(g.span / 3_600)
        let step = [1, 2, 3, 4, 6, 8, 12].first { CGFloat($0) * pointsPerHour >= T.xLabelSpacing } ?? 12
        let cal = Calendar.current
        guard var t = cal.nextDate(after: g.visibleStart.addingTimeInterval(-1),
                                   matching: DateComponents(minute: 0, second: 0),
                                   matchingPolicy: .nextTime) else { return out }
        let edges = out
        while t <= g.visibleEnd {
            let hour = cal.component(.hour, from: t)
            let x = g.x(t)
            if hour % step == 0, x >= lo, x <= hi {
                let label = xLabel("h\(Int(t.timeIntervalSince1970))", at: x, text: Self.hourLabel(t))
                if edges.allSatisfy({ abs($0.x - label.x) >= ($0.width + label.width) / 2 + T.xLabelMinimumGap }) {
                    out.append(label)
                }
            }
            t = t.addingTimeInterval(3_600)
        }
        return out
    }

    private func xLabels(_ g: DayTimelineGeometry) -> some View {
        ForEach(xLabelItems(g)) { label in
            Text(label.text)
                .font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
                .position(x: label.x, y: plot.maxY + T.xLabelGap)
        }
        .accessibilityHidden(true)
    }

    /// "00:00" on a 24-hour clock, "12 AM" on a 12-hour one: whole hours need no minutes.
    static func hourLabel(_ date: Date) -> String {
        if AppClock.uses24Hour { return PulseFormat.clock(date) }
        return hourFormatter.string(from: date)
    }

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = AppClock.formattingLocale
        f.setLocalizedDateFormatFromTemplate("ha")
        return f
    }()

    // MARK: Strip labels

    private struct StripItem: Identifiable {
        enum Content {
            case period(symbol: String, value: String?)
            case marker(title: String, value: String, color: Color)
        }

        let id: String
        var x: CGFloat
        let width: CGFloat
        /// Markers outrank the night, which outranks activities, when labels collide.
        let priority: Int
        /// A period's band as drawn on screen: its label may slide along it to clear a marker.
        var span: ClosedRange<CGFloat>?
        let content: Content
    }

    private static let markerPriority = 2
    private static let sleepPriority = 1
    private static let activityPriority = 0

    /// The strip's fonts: values 15 pt Bold condensed, the period glyphs 17 pt.
    private static let valueFont = PulseType.numeral(T.stripValueSize)

    private func stripItems(_ g: DayTimelineGeometry) -> [StripItem] {
        var items: [StripItem] = []
        let lo = plot.minX, hi = plot.maxX
        for period in snapshot.periods {
            let start = g.x(period.start), end = g.x(period.end)
            let x0 = max(start, lo), x1 = min(end, hi)
            guard x1 > x0 else { continue }
            let valueWidth = period.value.map { PulseTextMetrics.width($0, style: .rowValue, size: T.stripValueSize) } ?? 0
            let width = max(T.stripGlyphSize, valueWidth)
            // Centred on the whole band and held inside the part on screen, so a night that began before the
            // view starts keeps its label at the view's left edge (help-center/106's "8:30").
            let centre = (start + end) / 2
            let x = x1 - x0 >= width ? min(max(centre, x0 + width / 2), x1 - width / 2) : (x0 + x1) / 2
            items.append(StripItem(id: period.id, x: x, width: width,
                                   priority: period.kind.isSleep ? Self.sleepPriority : Self.activityPriority,
                                   span: x0...x1,
                                   content: .period(symbol: period.symbol, value: period.value)))
        }
        if let marker = snapshot.recovery, let band = marker.band {
            let x = g.x(marker.date)
            if x >= lo - 1, x <= hi + 1 {
                let title = PulseScore.recovery.displayName
                items.append(StripItem(id: "recovery", x: x,
                                       width: max(PulseTextMetrics.width(title, style: .label),
                                                  PulseTextMetrics.width(marker.value, style: .rowValue,
                                                                         size: T.stripValueSize)),
                                       priority: Self.markerPriority,
                                       content: .marker(title: title, value: marker.value,
                                                        color: PulseTheme.recoveryText(band))))
            }
        }
        if let marker = snapshot.strain {
            let x = g.x(marker.date)
            if x >= lo - 1, x <= hi + 1 {
                let title = PulseScore.strain.displayName
                items.append(StripItem(id: "strain", x: x,
                                       width: max(PulseTextMetrics.width(title, style: .label),
                                                  PulseTextMetrics.width(marker.value, style: .rowValue,
                                                                         size: T.stripValueSize)),
                                       priority: Self.markerPriority,
                                       content: .marker(title: title, value: marker.value, color: PulseTheme.strain)))
            }
        }
        return Self.resolveCollisions(items, within: labelBounds)
    }

    /// Keeps the strip's labels apart and inside `bounds`:
    ///   - two markers that crowd each other move apart evenly about their midpoint, then shift together
    ///     until both are inside the bounds (RECOVERY at wake beside STRAIN at the newest reading, a few
    ///     points apart in portrait);
    ///   - a night's or nap's label that would overlap a marker slides along its own band, as little as it
    ///     needs to, before it is dropped (WHOOP keeps "8:30" beside "RECOVERY 82%", help-center/106);
    ///   - an activity's label that would overlap anything of higher priority is dropped.
    private static func resolveCollisions(_ items: [StripItem], within bounds: ClosedRange<CGFloat>) -> [StripItem] {
        let gap = T.stripLabelGap
        var placed: [StripItem] = []

        /// `x` held so that a label `width` wide stays inside `range` (its middle when it cannot fit).
        func clamp(_ x: CGFloat, width: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
            guard range.upperBound - range.lowerBound >= width else { return (range.lowerBound + range.upperBound) / 2 }
            return min(max(x, range.lowerBound + width / 2), range.upperBound - width / 2)
        }
        func clash(at x: CGFloat, width: CGFloat) -> Int? {
            placed.indices.first { abs(placed[$0].x - x) < (placed[$0].width + width) / 2 + gap }
        }

        for item in items.sorted(by: { ($0.priority, -$0.x) > ($1.priority, -$1.x) }) {
            var candidate = item
            candidate.x = clamp(item.x, width: item.width, to: bounds)
            guard let hit = clash(at: candidate.x, width: candidate.width) else {
                placed.append(candidate)
                continue
            }
            if candidate.priority == markerPriority && placed[hit].priority == markerPriority {
                var other = placed[hit]
                let need = (other.width + candidate.width) / 2 + gap
                let mid = (other.x + candidate.x) / 2
                let leftFirst = other.x <= candidate.x
                other.x = mid + (leftFirst ? -need / 2 : need / 2)
                candidate.x = mid + (leftFirst ? need / 2 : -need / 2)
                // Spread about their midpoint, a pair can cross an edge: bring both back inside together.
                let left = min(other.x - other.width / 2, candidate.x - candidate.width / 2)
                let right = max(other.x + other.width / 2, candidate.x + candidate.width / 2)
                var shift: CGFloat = 0
                if left < bounds.lowerBound { shift = bounds.lowerBound - left }
                if right + shift > bounds.upperBound { shift = bounds.upperBound - right }
                other.x += shift
                candidate.x += shift
                placed[hit] = other
                placed.append(candidate)
                continue
            }
            guard candidate.priority == sleepPriority, let span = item.span else { continue }
            // Slide along the band (the part of it inside the bounds), away from whatever it hit: try the
            // band's two ends and the spots just clear of each placed label, nearest first.
            let laneStart = max(span.lowerBound, bounds.lowerBound)
            let lane = laneStart...max(laneStart, min(span.upperBound, bounds.upperBound))
            var spots = [lane.lowerBound + candidate.width / 2, lane.upperBound - candidate.width / 2]
            for other in placed {
                let need = (other.width + candidate.width) / 2 + gap
                spots.append(other.x - need)
                spots.append(other.x + need)
            }
            let fits = spots
                .map { clamp($0, width: candidate.width, to: lane) }
                .filter { clash(at: $0, width: candidate.width) == nil }
                .min { abs($0 - item.x) < abs($1 - item.x) }
            if let x = fits {
                candidate.x = x
                placed.append(candidate)
            }
        }
        return placed
    }

    @ViewBuilder
    private func stripLabels(_ g: DayTimelineGeometry) -> some View {
        if let cursor, g.x(cursor) >= plot.minX - 1, g.x(cursor) <= plot.maxX + 1 {
            readout(at: cursor, g)
        } else {
            ForEach(stripItems(g)) { item in
                stripLabel(item)
            }
            .accessibilityHidden(true)
        }
    }

    /// A period's glyph (its foot on the markers' caption baseline) over its value, or a marker's caption
    /// over its value, each row at its own height in the strip.
    @ViewBuilder
    private func stripLabel(_ item: StripItem) -> some View {
        switch item.content {
        case .period(let symbol, let value):
            Image(systemName: symbol)
                .font(.system(size: T.stripGlyphSize, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
                .position(x: item.x, y: strip.minY + T.stripGlyphCentre)
            if let value {
                Text(value)
                    .font(Self.valueFont)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .position(x: item.x, y: strip.minY + T.stripRow2)
            }
        case .marker(let title, let value, let color):
            Text(title)
                .font(PulseType.font(.label))
                .tracking(PulseTextStyle.label.spec.tracking)
                .textCase(.uppercase)
                .foregroundStyle(color)
                .fixedSize()
                .position(x: item.x, y: strip.minY + T.stripRow1)
            Text(value)
                .font(Self.valueFont)
                .foregroundStyle(color)
                .fixedSize()
                .position(x: item.x, y: strip.minY + T.stripRow2)
        }
    }

    /// The scrub readout: "115 bpm" over the time, centred on the cursor and kept inside `labelBounds`.
    private func readout(at date: Date, _ g: DayTimelineGeometry) -> some View {
        let bpm = DayTimelineDrawing.value(at: date, in: points)
        let half = T.readoutWidth / 2
        let x = min(max(g.x(date), labelBounds.lowerBound + half), labelBounds.upperBound - half)
        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(bpm.map { PulseFormat.whole($0) } ?? "--")
                    .font(PulseType.font(.rowValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "bpm"))
                    .font(.system(size: T.readoutUnitSize, weight: .bold))
                    .foregroundStyle(PulseTheme.textButton)
            }
            .frame(height: T.stripRow2 - T.stripRow1)
            Text(PulseFormat.clock(date))
                .font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(height: T.stripRow2 - T.stripRow1)
        }
        .fixedSize()
        .position(x: x, y: strip.minY + (T.stripRow1 + T.stripRow2) / 2)
        .accessibilityHidden(true)
    }

    private func emptyMessage(_ g: DayTimelineGeometry) -> some View {
        Text(snapshot.day.isToday
             ? String(localized: "No heart rate synced yet today. Wear your strap and it fills in as it syncs.")
             : String(localized: "No heart rate was recorded for this day."))
            .pulseText(.body)
            .foregroundStyle(PulseTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(width: min(plot.width - 32, 320))
            .position(x: plot.midX, y: plot.midY)
            .accessibilityHidden(true)
    }

    // MARK: Gestures

    private func dragGesture(_ g: DayTimelineGeometry) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                // The touch surface sits at the plot's origin; convert to this view's coordinates.
                let x = value.location.x + plot.minX
                switch drag {
                case .idle:
                    if zoom > 1.01 {
                        drag = .deciding(startScroll: scrollFraction)
                        let at = g.date(atX: value.startLocation.x + plot.minX)
                        holdTask?.cancel()
                        holdTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(300))
                            guard !Task.isCancelled, case .deciding = drag else { return }
                            drag = .scrubbing
                            cursor = at
                            scrubStarts += 1
                        }
                    } else {
                        drag = .scrubbing
                        cursor = g.date(atX: x)
                    }
                case .deciding(let startScroll):
                    if abs(value.translation.width) > 8 || abs(value.translation.height) > 8 {
                        holdTask?.cancel()
                        drag = .panning(startScroll: startScroll)
                        scrollFraction = g.scrollFraction(from: startScroll, draggedBy: value.translation.width)
                    }
                case .panning(let startScroll):
                    scrollFraction = g.scrollFraction(from: startScroll, draggedBy: value.translation.width)
                case .scrubbing:
                    cursor = g.date(atX: x)
                }
            }
            .onEnded { _ in
                holdTask?.cancel()
                holdTask = nil
                drag = .idle
                cursor = nil
            }
    }

    // MARK: Accessibility

    private var accessibilityTitle: String {
        String(localized: "Heart rate, \(PulseFormat.clock(snapshot.start)) to \(PulseFormat.clock(snapshot.endLabelDate))")
    }

    private var accessibilityValue: String {
        if let cursor {
            var parts = [PulseFormat.clock(cursor)]
            if let bpm = DayTimelineDrawing.value(at: cursor, in: points) {
                parts.append(String(localized: "\(PulseFormat.whole(bpm)) beats per minute"))
            } else {
                parts.append(String(localized: "no reading"))
            }
            if let period = snapshot.periods.first(where: { $0.contains(cursor) }) {
                parts.append(period.title)
            }
            return parts.joined(separator: ", ")
        }
        var parts: [String] = []
        if let low = snapshot.lowest, let avg = snapshot.average, let high = snapshot.highest {
            parts.append(String(localized: "Lowest \(low), average \(avg), highest \(high) beats per minute"))
        } else {
            parts.append(String(localized: "No heart rate"))
        }
        parts.append(contentsOf: snapshot.periods.map(\.accessibilityLabel))
        if let r = snapshot.recovery {
            parts.append(String(localized: "Recovery \(r.value) at \(PulseFormat.clock(r.date))"))
        }
        if let s = snapshot.strain {
            parts.append(String(localized: "Strain \(s.value)"))
        }
        return parts.joined(separator: ". ")
    }

    private func adjustCursor(_ direction: AccessibilityAdjustmentDirection) {
        let step: TimeInterval = 30 * 60
        let current = cursor ?? snapshot.start.addingTimeInterval(-step)
        switch direction {
        case .increment:
            cursor = min(current.addingTimeInterval(step), snapshot.end)
        case .decrement:
            cursor = max(current.addingTimeInterval(-step), snapshot.start)
        @unknown default:
            break
        }
        // Keep the cursor in view when zoomed.
        if let cursor {
            let g = geometry
            let x = g.x(cursor)
            if x < plot.minX || x > plot.maxX {
                scrollFraction = g.scrollFraction(keeping: cursor, atX: plot.midX)
            }
        }
    }
}

// MARK: - Drawing

/// The canvas part of the timeline: gridlines, bands and their caps, the heart-rate line in its period
/// colours, the dashed markers and the cursor.
struct DayTimelineDrawing {
    let snapshot: DayTimelineSnapshot
    let points: [DayTimelinePoint]
    let geometry: DayTimelineGeometry
    let cursor: Date?
    let selectedActivity: String?

    private typealias T = PulseExtrasTheme.Timeline

    func draw(in context: inout GraphicsContext) {
        let g = geometry
        let plot = g.plot

        // Gridlines across the plot.
        var grid = Path()
        for value in T.gridValues {
            let y = (g.y(value)).rounded() + 0.5
            grid.move(to: CGPoint(x: plot.minX, y: y))
            grid.addLine(to: CGPoint(x: plot.maxX, y: y))
        }
        context.stroke(grid, with: .color(T.grid), lineWidth: 1)

        // Everything else stays inside the plot (the caps sit on its top edge).
        var clipped = context
        clipped.clip(to: Path(CGRect(x: plot.minX, y: plot.minY - 2, width: plot.width, height: plot.height + 2)))

        for period in snapshot.periods {
            let x0 = g.x(period.start), x1 = g.x(period.end)
            guard x1 > plot.minX, x0 < plot.maxX, x1 > x0 else { continue }
            let column = CGRect(x: x0, y: plot.minY, width: x1 - x0, height: plot.height)
            let hue = period.kind.isSleep ? PulseTheme.sleep : PulseTheme.strain
            let top = period.kind.isSleep ? T.sleepBandTop : T.activityBandTop
            clipped.fill(Path(column), with: .linearGradient(
                Gradient(colors: [hue.opacity(top), hue.opacity(T.bandFoot)]),
                startPoint: CGPoint(x: column.midX, y: column.minY),
                endPoint: CGPoint(x: column.midX, y: column.maxY)))
            let selected = period.id == selectedActivity
            if selected { clipped.fill(Path(column), with: .color(T.selectedLift)) }
            let cap = period.kind.isSleep ? T.sleepCap : (selected ? T.selectedCap : T.activityCap)
            clipped.fill(Path(CGRect(x: x0, y: plot.minY - 1, width: x1 - x0, height: 2)), with: .color(cap))
        }

        drawLine(in: &clipped)

        // Markers: dashed rules down the plot.
        if let r = snapshot.recovery, let band = r.band {
            dashedRule(at: g.x(r.date), color: PulseTheme.recovery(band), in: &clipped)
        }
        if let s = snapshot.strain {
            dashedRule(at: g.x(s.date), color: PulseTheme.strain, in: &clipped)
        }

        // The cursor and its dot.
        if let cursor {
            let x = g.x(cursor)
            var rule = Path()
            rule.move(to: CGPoint(x: x, y: plot.minY))
            rule.addLine(to: CGPoint(x: x, y: plot.maxY))
            clipped.stroke(rule, with: .color(T.cursor), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            if let bpm = Self.value(at: cursor, in: points) {
                let dot = CGRect(x: x - 6, y: g.y(bpm) - 6, width: 12, height: 12)
                clipped.fill(Path(ellipseIn: dot), with: .color(T.cursor))
                clipped.stroke(Path(ellipseIn: dot), with: .color(T.cursorRing), lineWidth: 1.5)
            }
        }
    }

    private func dashedRule(at x: CGFloat, color: Color, in context: inout GraphicsContext) {
        let plot = geometry.plot
        guard x >= plot.minX - 1, x <= plot.maxX + 1 else { return }
        var rule = Path()
        rule.move(to: CGPoint(x: x, y: plot.minY))
        rule.addLine(to: CGPoint(x: x, y: plot.maxY))
        context.stroke(rule, with: .color(color), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
    }

    /// What colours a stretch of the line.
    private enum Stroke: Equatable {
        case awake, sleep, activity(selected: Bool)
    }

    private func stroke(at date: Date) -> Stroke {
        if let activity = snapshot.periods.first(where: { $0.kind == .activity && $0.contains(date) }) {
            return .activity(selected: activity.id == selectedActivity)
        }
        if snapshot.periods.contains(where: { $0.kind.isSleep && $0.contains(date) }) { return .sleep }
        return .awake
    }

    private func color(_ stroke: Stroke) -> Color {
        switch stroke {
        case .awake: return T.awakeLine
        case .sleep: return T.sleepLine
        case .activity(let selected): return selected ? T.selectedLine : T.activityLine
        }
    }

    /// The line, one polyline per run and colour. A colour change shares its boundary point so the line
    /// stays continuous; a new run (a gap in wear) starts a fresh polyline.
    private func drawLine(in context: inout GraphicsContext) {
        let g = geometry
        let margin = g.span * 0.02
        let lo = g.visibleStart.addingTimeInterval(-margin), hi = g.visibleEnd.addingTimeInterval(margin)
        var path = Path()
        var current: Stroke?
        var lastRun: Int?
        var previous: CGPoint?
        let style = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

        func flush() {
            if let current, !path.isEmpty { context.stroke(path, with: .color(color(current)), style: style) }
            path = Path()
        }

        for p in points where p.date >= lo && p.date <= hi {
            let point = CGPoint(x: g.x(p.date), y: g.y(p.bpm))
            let s = stroke(at: p.date)
            if p.run != lastRun {
                flush()
                path.move(to: point)
                current = s
            } else if s != current {
                path.addLine(to: point)
                flush()
                path.move(to: previous ?? point)
                path.addLine(to: point)
                current = s
            } else {
                path.addLine(to: point)
            }
            previous = point
            lastRun = p.run
        }
        flush()
    }

    /// The reading at `date`: the nearest bucket, when one lies within two bucket widths.
    static func value(at date: Date, in points: [DayTimelinePoint]) -> Double? {
        guard !points.isEmpty else { return nil }
        var lo = 0, hi = points.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if points[mid].date < date { lo = mid + 1 } else { hi = mid }
        }
        let candidates = [lo - 1, lo].filter { points.indices.contains($0) }
        guard let best = candidates.min(by: {
            abs(points[$0].date.timeIntervalSince(date)) < abs(points[$1].date.timeIntervalSince(date))
        }) else { return nil }
        let spacing = points.count > 1
            ? points[points.count - 1].date.timeIntervalSince(points[0].date) / Double(points.count - 1)
            : 60
        guard abs(points[best].date.timeIntervalSince(date)) <= max(120, spacing * 2) else { return nil }
        return points[best].bpm
    }
}
#endif
