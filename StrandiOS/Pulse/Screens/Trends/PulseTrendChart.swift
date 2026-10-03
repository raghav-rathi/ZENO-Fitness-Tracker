#if os(iOS)
import SwiftUI

/// The Trend View's chart (WHOOP_UI_SPEC §2.7 "Trend View line", "Trend View M", "Trend View 6M"; §3.12
/// item 7), drawn from a resolved `PulseTrendChartModel`:
///
///   - W: daily bars (Recovery in its band colours) or a line with hollow markers, values over each day;
///   - M: thirty slimmer bars under a white dashed AVG. line with its pill, or a line marking only its
///     newest point, over the typical range;
///   - 6M / 1Y / ALL: the daily data faint under the period segments, each with its value above and the
///     change from the one before below, white for the first, teal or orange by whether the change is good;
///   - stacked parts (zones, sleep stages) with a white total over each column, a partial week faint;
///   - floating bed → wake bars on a downward clock axis (TIME IN BED) with the average bedtime and wake as
///     dashed lines and pills;
///   - the menstrual-cycle strip under the plot when the overlay is on.
///
/// Geometry follows the captures, not the labels: the y labels end 33.5 pt from the screen edge and the
/// plot starts at a fixed 53 pt for every metric, its gridlines running to 12 pt from the right edge
/// (deep-dives-2026/37, 47), so the canvas bleeds into the page margins. An empty chart keeps its frame:
/// five plain gridlines, the day labels and the message. It is one Canvas: nothing in it animates, and
/// VoiceOver reads the model's one-line summary.
struct PulseTrendChart: View {
    let model: PulseTrendChartModel

    /// Room above the top gridline for a value label over the tallest column.
    static let headroom: CGFloat = 22
    static let plotHeight: CGFloat = 222
    static let phaseStrip: CGFloat = 10
    static let xLabelBand: CGFloat = 36

    /// How far the canvas reaches past the content: to the screen edge at the left, 4 pt at the right.
    private static let leadingBleed = PulseTheme.Layout.pageMargin
    private static let trailingBleed = PulseTheme.Trends.plotTrailingBleed

    private var height: CGFloat {
        Self.headroom + Self.plotHeight + (model.phases.isEmpty ? 0 : Self.phaseStrip) + Self.xLabelBand
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .frame(height: height)
        .overlay {
            if let message = model.emptyMessage {
                // Centred over the plot, not the canvas.
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.leading, PulseTheme.Trends.plotLeading)
                    .padding(.top, Self.headroom)
                    .padding(.bottom, Self.xLabelBand)
            }
        }
        .padding(.leading, -Self.leadingBleed)
        .padding(.trailing, -Self.trailingBleed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilitySummary)
        .accessibilityAddTraits(.isImage)
    }

    // MARK: Geometry

    private struct Frame {
        let plot: CGRect
        let count: Int
        let domain: ClosedRange<Double>
        /// The domain's lower bound is at the TOP (a clock running downward).
        let inverted: Bool

        /// The columns sit inside the gridlines with this much room at each end (deep-dives-2026/46, 47).
        let inset: CGFloat

        var columnsWidth: CGFloat { max(1, plot.width - 2 * inset) }
        var pitch: CGFloat { count > 0 ? columnsWidth / CGFloat(count) : columnsWidth }

        func x(_ index: Int) -> CGFloat { plot.minX + inset + (CGFloat(index) + 0.5) * pitch }
        /// The left edge of column `index` (its slot, not its bar).
        func edge(_ index: Int) -> CGFloat { plot.minX + inset + CGFloat(index) * pitch }

        func y(_ value: Double) -> CGFloat {
            let span = domain.upperBound - domain.lowerBound
            guard span > 0 else { return plot.maxY }
            let t = (value - domain.lowerBound) / span
            if inverted { return plot.minY + CGFloat(max(-0.06, min(1.06, t))) * plot.height }
            return plot.maxY - CGFloat(max(0, min(1.06, t))) * plot.height
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let left = PulseTheme.Trends.plotLeading
        let plot = CGRect(x: left, y: Self.headroom, width: max(1, size.width - left), height: Self.plotHeight)
        let frame = Frame(plot: plot, count: model.columns.count, domain: model.yDomain, inverted: model.invertedY,
                          inset: model.columns.count <= 31 ? PulseTheme.Trends.columnInset : 2)

        guard model.hasValues else {
            drawEmptyGrid(&context, frame)
            drawXLabels(&context, frame, size: size)
            return
        }
        drawGrid(&context, frame)
        if let typical = model.typical { drawTypical(&context, frame, typical, size: size) }
        drawPhases(&context, frame)

        switch model.mode {
        case .bars: drawBars(&context, frame)
        case .stacked: drawStacked(&context, frame)
        case .line: drawLine(&context, frame)
        case .dualLine: drawDual(&context, frame)
        case .floating: drawFloating(&context, frame)
        }
        if !model.segments.isEmpty { drawSegments(&context, frame) }
        if let average = model.average {
            drawMarker(&context, frame, value: average, pill: String(localized: "Avg.").uppercased())
        }
        for marker in model.markers { drawMarker(&context, frame, value: marker.value, pill: marker.pill) }
        if let span = model.dimmedSpan { drawDimmedCaption(&context, frame, span) }
        drawXLabels(&context, frame, size: size)
    }

    // MARK: Grid and overlays

    /// The y labels right-aligned in their fixed column, the gridlines from the plot's fixed left edge.
    private func drawGrid(_ context: inout GraphicsContext, _ f: Frame) {
        let font = PulseType.font(.axis)
        for tick in model.yTicks {
            let y = f.y(tick.value)
            var line = Path()
            line.move(to: CGPoint(x: f.plot.minX, y: y))
            line.addLine(to: CGPoint(x: f.plot.maxX, y: y))
            context.stroke(line, with: .color(PulseTheme.gridOnPage), lineWidth: 1)
            context.draw(Text(tick.label).font(font).foregroundColor(tick.color),
                         at: CGPoint(x: PulseTheme.Trends.yLabelTrailing, y: y), anchor: .trailing)
        }
    }

    /// No reading in the window: five plain gridlines, so the empty chart keeps the frame a full one has.
    private func drawEmptyGrid(_ context: inout GraphicsContext, _ f: Frame) {
        for i in 0..<5 {
            let y = f.plot.minY + f.plot.height * CGFloat(i) / 4
            var line = Path()
            line.move(to: CGPoint(x: f.plot.minX, y: y))
            line.addLine(to: CGPoint(x: f.plot.maxX, y: y))
            context.stroke(line, with: .color(PulseTheme.gridOnPage), lineWidth: 1)
        }
    }

    /// The typical range: from under the y labels to just short of the gridlines' end (deep-dives-2026/37).
    private func drawTypical(_ context: inout GraphicsContext, _ f: Frame, _ range: ClosedRange<Double>, size: CGSize) {
        let top = f.y(range.upperBound)
        let bottom = f.y(range.lowerBound)
        let x0 = PulseTheme.Trends.typicalBandLeading
        let x1 = size.width - PulseTheme.Trends.typicalBandTrailing
        let rect = CGRect(x: x0, y: min(top, bottom), width: max(1, x1 - x0), height: max(2, abs(bottom - top)))
        context.fill(Path(rect), with: .color(PulseTheme.Trends.typicalBand))
    }

    private func drawPhases(_ context: inout GraphicsContext, _ f: Frame) {
        guard !model.phases.isEmpty else { return }
        let y = f.plot.maxY + 4
        for span in model.phases {
            let x0 = f.edge(span.startIndex) + 1
            let x1 = f.edge(span.endIndex + 1) - 1
            guard x1 > x0 else { continue }
            let rect = CGRect(x: x0, y: y, width: x1 - x0, height: 4)
            context.fill(Path(roundedRect: rect, cornerRadius: PulseTheme.Trends.phaseStripRadius),
                         with: .color(span.phase.color))
        }
    }

    /// A dashed white line across the plot with its white pill at the left edge of the content: M's
    /// "AVG." (deep-dives-2026/26, 46), TIME IN BED's "20:32" / "04:36" (/20).
    private func drawMarker(_ context: inout GraphicsContext, _ f: Frame, value: Double, pill: String) {
        let y = f.y(value)
        var line = Path()
        line.move(to: CGPoint(x: f.plot.minX, y: y))
        line.addLine(to: CGPoint(x: f.plot.maxX, y: y))
        context.stroke(line, with: .color(PulseTheme.averageLine), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        let text = context.resolve(Text(pill).font(PulseType.font(.chipStrong)).foregroundColor(.black))
        let size = text.measure(in: CGSize(width: 120, height: 20))
        let rect = CGRect(x: Self.leadingBleed, y: y - (size.height + 6) / 2, width: size.width + 14,
                          height: size.height + 6)
        context.fill(Path(roundedRect: rect, cornerRadius: PulseTheme.Trends.pillRadius), with: .color(.white))
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    /// Training Load's building weeks: their caption at the top of the span the lines are faint across.
    private func drawDimmedCaption(_ context: inout GraphicsContext, _ f: Frame, _ span: PulseTrendChartModel.DimmedSpan) {
        let x0 = f.edge(span.startIndex)
        let x1 = f.edge(span.endIndex + 1)
        guard x1 - x0 > 24 else { return }
        let text = context.resolve(Text(span.caption.uppercased()).font(PulseType.font(.label))
            .foregroundColor(PulseTheme.textTertiary))
        let width = text.measure(in: CGSize(width: 200, height: 20)).width
        let x = width + 8 < x1 - x0 ? (x0 + x1) / 2 : x0 + width / 2 + 4
        context.draw(text, at: CGPoint(x: x, y: f.plot.minY + 6), anchor: .top)
    }

    /// The opacity of column `index`: faint inside the dimmed span.
    private func spanOpacity(_ index: Int) -> Double {
        guard let span = model.dimmedSpan, (span.startIndex...span.endIndex).contains(index) else { return 1 }
        return PulseTheme.Trends.dimmedData + 0.1
    }

    // MARK: Bars

    private func barWidth(_ f: Frame) -> CGFloat {
        if let fraction = model.barFraction { return max(2, f.pitch * fraction) }
        return min(model.barWidth, max(2, f.pitch * 0.8))
    }

    private func barRect(_ f: Frame, index: Int, from low: Double, to high: Double) -> CGRect {
        let width = barWidth(f)
        let top = f.y(high)
        let bottom = f.y(low)
        return CGRect(x: f.x(index) - width / 2, y: top, width: width, height: max(1, bottom - top))
    }

    private func drawBars(_ context: inout GraphicsContext, _ f: Frame) {
        let base = model.yDomain.lowerBound
        let opacity = model.dimmed ? PulseTheme.Trends.dimmedData : 1
        let radius = PulseTheme.Trends.barTopRadius
        for (i, column) in model.columns.enumerated() {
            guard let value = column.value else { continue }
            let rect = barRect(f, index: i, from: base, to: value)
            let shape = UnevenRoundedRectangle(topLeadingRadius: radius, topTrailingRadius: radius, style: .circular)
                .path(in: rect)
            let alpha = column.isPartial ? opacity * PulseTheme.Trends.partialOpacity : opacity
            context.fill(shape, with: .color(column.color.opacity(alpha)))
            if let label = column.label {
                drawValueLabel(&context, label, color: column.isPartial ? PulseTheme.textTertiary : column.color,
                               at: CGPoint(x: f.x(i), y: rect.minY - 4))
            }
        }
    }

    private func drawStacked(_ context: inout GraphicsContext, _ f: Frame) {
        let opacity = model.dimmed ? PulseTheme.Trends.dimmedData : 1
        for (i, column) in model.columns.enumerated() {
            guard column.value != nil else { continue }
            let alpha = column.isPartial ? opacity * PulseTheme.Trends.partialOpacity : opacity
            var low = model.yDomain.lowerBound
            var top = f.y(low)
            for (p, part) in column.parts.enumerated() where part > 0 {
                let high = low + part
                var rect = barRect(f, index: i, from: low, to: high)
                // A hairline between parts, as WHOOP separates REM from SWS.
                if p > 0 { rect.size.height = max(0.5, rect.height - 1) }
                let color = p < model.partColors.count ? model.partColors[p] : model.lineColor
                context.fill(Path(rect), with: .color(color.opacity(alpha)))
                low = high
                top = rect.minY
            }
            if let label = column.label {
                drawValueLabel(&context, label, color: column.isPartial ? PulseTheme.textTertiary : PulseTheme.textPrimary,
                               at: CGPoint(x: f.x(i), y: top - 4))
            }
        }
    }

    /// TIME IN BED: each night from bedtime (the top) down to wake, its ends labelled on W.
    private func drawFloating(_ context: inout GraphicsContext, _ f: Frame) {
        let width = barWidth(f)
        for (i, column) in model.columns.enumerated() {
            guard let range = column.range else { continue }
            let a = f.y(range.lowerBound), b = f.y(range.upperBound)
            let rect = CGRect(x: f.x(i) - width / 2, y: min(a, b), width: width, height: max(2, abs(b - a)))
            context.fill(Path(roundedRect: rect, cornerRadius: PulseTheme.Trends.barTopRadius),
                         with: .color(column.color))
            if let label = column.label {
                drawValueLabel(&context, label, color: column.color, at: CGPoint(x: f.x(i), y: rect.minY - 4))
            }
            if let label = column.secondaryLabel {
                drawValueLabel(&context, label, color: column.color, at: CGPoint(x: f.x(i), y: rect.maxY + 4),
                               below: true)
            }
        }
    }

    // MARK: Lines

    private func points(_ f: Frame, _ value: (PulseTrendChartModel.Column) -> Double?) -> [(index: Int, point: CGPoint)] {
        model.columns.enumerated().compactMap { i, c in
            value(c).map { (i, CGPoint(x: f.x(i), y: f.y($0))) }
        }
    }

    private func drawLine(_ context: inout GraphicsContext, _ f: Frame) {
        let pts = points(f) { $0.value }
        guard !pts.isEmpty else { return }
        let color = model.lineColor
        var path = Path()
        path.addLines(pts.map(\.point))
        if model.dimmed {
            context.stroke(path, with: .color(color.opacity(PulseTheme.Trends.dimmedData + 0.1)),
                           style: StrokeStyle(lineWidth: 1, lineJoin: .round))
            return
        }
        // The faint area under the line, then the line at 70%.
        var area = path
        area.addLine(to: CGPoint(x: pts[pts.count - 1].point.x, y: f.plot.maxY))
        area.addLine(to: CGPoint(x: pts[0].point.x, y: f.plot.maxY))
        area.closeSubpath()
        context.fill(area, with: .linearGradient(Gradient(colors: [color.opacity(0.16), color.opacity(0.02)]),
                                                 startPoint: CGPoint(x: 0, y: f.plot.minY),
                                                 endPoint: CGPoint(x: 0, y: f.plot.maxY)))
        context.stroke(path, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

        let marked: [(index: Int, point: CGPoint)]
        if model.showsMarkers {
            marked = pts
        } else if model.marksLastPointOnly, let last = pts.last {
            marked = [last]
        } else {
            marked = []
        }
        // Over the typical band a label sits on a small dark plate, as WHOOP sets "47" inside the band.
        let band = model.typical.map { r in
            CGRect(x: f.plot.minX, y: f.y(r.upperBound), width: f.plot.width, height: max(2, f.y(r.lowerBound) - f.y(r.upperBound)))
        }
        for m in marked {
            drawMarker(&context, at: m.point, color: color)
            if let label = model.columns[m.index].label {
                drawValueLabel(&context, label, color: color, at: CGPoint(x: m.point.x, y: m.point.y - 8), plateOver: band)
            }
        }
    }

    /// Two lines (HOURS VS. NEEDED, Training Load). Faint and unmarked on the long ranges; inside a dimmed
    /// span (Training Load's building weeks) each line is faint up to the span's end.
    private func drawDual(_ context: inout GraphicsContext, _ f: Frame) {
        let primary = points(f) { $0.value }
        let secondary = points(f) { $0.secondary }
        let secondaryColor = model.secondaryColor ?? PulseTheme.positive
        for (series, color) in [(secondary, secondaryColor), (primary, model.lineColor)] where !series.isEmpty {
            if model.dimmed {
                var path = Path()
                path.addLines(series.map(\.point))
                context.stroke(path, with: .color(color.opacity(PulseTheme.Trends.dimmedData + 0.1)),
                               style: StrokeStyle(lineWidth: 1, lineJoin: .round))
                continue
            }
            strokeLine(&context, series, color: color)
            if model.showsMarkers {
                for p in series { drawMarker(&context, at: p.point, color: color) }
            }
        }
        guard !model.dimmed else { return }
        // Each day's higher value is labelled above its marker, the lower one below.
        for (i, column) in model.columns.enumerated() {
            let x = f.x(i)
            let h = column.value.map { (value: $0, label: column.label, color: model.lineColor) }
            let n = column.secondary.map { (value: $0, label: column.secondaryLabel, color: secondaryColor) }
            let pair = [h, n].compactMap { $0 }.sorted { $0.value > $1.value }
            for (rank, item) in pair.enumerated() {
                guard let label = item.label else { continue }
                let y = f.y(item.value)
                if rank == 0 {
                    drawValueLabel(&context, label, color: item.color, at: CGPoint(x: x, y: y - 8))
                } else {
                    drawValueLabel(&context, label, color: item.color, at: CGPoint(x: x, y: y + 6), below: true)
                }
            }
        }
    }

    /// A 2 pt line at 70%, faint through the dimmed span when there is one.
    private func strokeLine(_ context: inout GraphicsContext, _ series: [(index: Int, point: CGPoint)], color: Color) {
        let style = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        guard let span = model.dimmedSpan else {
            var path = Path()
            path.addLines(series.map(\.point))
            context.stroke(path, with: .color(color.opacity(0.7)), style: style)
            return
        }
        // The faint part runs to the first point past the span, so the two parts join.
        let cut = series.firstIndex { $0.index > span.endIndex } ?? series.count
        var faint = Path()
        faint.addLines(series.prefix(min(series.count, cut + 1)).map(\.point))
        context.stroke(faint, with: .color(color.opacity(PulseTheme.Trends.dimmedData + 0.1)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        if cut < series.count {
            var strong = Path()
            strong.addLines(series.suffix(from: cut).map(\.point))
            context.stroke(strong, with: .color(color.opacity(0.7)), style: style)
        }
    }

    private func drawMarker(_ context: inout GraphicsContext, at point: CGPoint, color: Color) {
        let rect = CGRect(x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9)
        context.fill(Path(ellipseIn: rect), with: .color(PulseTheme.pageBottom))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 1, dy: 1)), with: .color(color), lineWidth: 2)
    }

    /// A value over a column or point, bottom-centred on `point` (`below`: top-centred), kept inside the
    /// chart's top. Where it would sit on `plateOver` (the typical band) it gets a dark plate so it stays
    /// legible.
    private func drawValueLabel(_ context: inout GraphicsContext, _ text: String, color: Color, at point: CGPoint,
                                below: Bool = false, plateOver: CGRect? = nil) {
        let resolved = context.resolve(Text(text).font(PulseType.numeral(15)).foregroundColor(color))
        let size = resolved.measure(in: CGSize(width: 120, height: 30))
        let bottom = below ? point.y + size.height : max(size.height, point.y)
        let rect = CGRect(x: point.x - size.width / 2, y: bottom - size.height, width: size.width, height: size.height)
        if let plate = plateOver, plate.intersects(rect) {
            context.fill(Path(roundedRect: rect.insetBy(dx: -3, dy: -1), cornerRadius: PulseTheme.Trends.pillRadius),
                         with: .color(PulseTheme.pageBottom.opacity(0.85)))
        }
        context.draw(resolved, at: CGPoint(x: point.x, y: bottom), anchor: .bottom)
    }

    // MARK: Segments

    private func drawSegments(_ context: inout GraphicsContext, _ f: Frame) {
        for segment in model.segments {
            let x0 = f.edge(segment.startIndex) + 2
            let x1 = f.edge(segment.endIndex + 1) - 2
            guard x1 > x0 else { continue }
            let y = f.y(segment.value)
            var line = Path()
            line.move(to: CGPoint(x: x0, y: y))
            line.addLine(to: CGPoint(x: x1, y: y))
            context.stroke(line, with: .color(segment.color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            let value = context.resolve(Text(segment.valueLabel).font(PulseType.numeral(15))
                .foregroundColor(segment.labelColor))
            if segment.labelBelow {
                context.draw(value, at: CGPoint(x: x0, y: y + 4), anchor: .topLeading)
            } else {
                context.draw(value, at: CGPoint(x: x0, y: y - 4), anchor: .bottomLeading)
            }
            if let change = segment.changeLabel {
                let text = context.resolve(Text(change).font(PulseType.numeral(13)).foregroundColor(segment.changeColor))
                context.draw(text, at: CGPoint(x: x0, y: y + 4), anchor: .topLeading)
            }
        }
    }

    // MARK: X labels

    private func drawXLabels(_ context: inout GraphicsContext, _ f: Frame, size: CGSize) {
        let top = f.plot.maxY + (model.phases.isEmpty ? 6 : Self.phaseStrip + 6)
        // WHOOP's x labels: the weekday or month in 11 pt semibold, the date under it in bold numerals.
        let font = PulseType.font(.chip)
        let numberFont = PulseType.font(.axis)
        for label in model.xLabels {
            let x = model.dimmed ? f.edge(label.index) : f.x(label.index)
            let line1 = context.resolve(Text(label.line1).font(font).foregroundColor(PulseTheme.textTertiary))
            let width = line1.measure(in: CGSize(width: 80, height: 20)).width
            // Keep the first and last labels inside the chart.
            let cx = min(max(x, f.plot.minX + width / 2), size.width - width / 2)
            context.draw(line1, at: CGPoint(x: cx, y: top), anchor: .top)
            if let second = label.line2 {
                let line2 = context.resolve(Text(second).font(numberFont).foregroundColor(PulseTheme.textTertiary))
                context.draw(line2, at: CGPoint(x: cx, y: top + 14), anchor: .top)
            }
        }
    }
}
#endif
