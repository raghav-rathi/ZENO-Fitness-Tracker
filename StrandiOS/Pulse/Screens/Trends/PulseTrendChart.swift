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
///   - stacked parts (zones, sleep stages) with a white total over each column;
///   - the menstrual-cycle strip under the plot when the overlay is on.
///
/// The y labels sit at the left (Recovery's coloured by band), the gridlines run on the page, and the x
/// labels are two lines (W, M) or month names (long ranges). It is one Canvas: nothing in it animates, and
/// VoiceOver reads the model's one-line summary.
struct PulseTrendChart: View {
    let model: PulseTrendChartModel

    /// Room above the top gridline for a value label over the tallest column.
    static let headroom: CGFloat = 22
    static let plotHeight: CGFloat = 222
    static let phaseStrip: CGFloat = 10
    static let xLabelBand: CGFloat = 36

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
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, Self.headroom)
                    .padding(.bottom, Self.xLabelBand)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilitySummary)
        .accessibilityAddTraits(.isImage)
    }

    // MARK: Geometry

    private struct Frame {
        let plot: CGRect
        let count: Int
        let domain: ClosedRange<Double>

        /// The columns sit inside the gridlines with this much room at each end (deep-dives-2026/47).
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
            return plot.maxY - CGFloat(max(0, min(1.06, t))) * plot.height
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let axisFont = PulseType.font(.axis)
        // The y labels' column: as wide as the widest label.
        let labelWidth = model.yTicks.map { tick in
            context.resolve(Text(tick.label).font(axisFont)).measure(in: size).width
        }.max() ?? 0
        let plotLeft = labelWidth > 0 ? ceil(labelWidth) + 10 : 0
        let plot = CGRect(x: plotLeft, y: Self.headroom, width: max(1, size.width - plotLeft),
                          height: Self.plotHeight)
        let frame = Frame(plot: plot, count: model.columns.count, domain: model.yDomain,
                          inset: model.columns.count <= 12 ? 8 : 2)

        drawGrid(&context, frame, font: axisFont)
        if let typical = model.typical { drawTypical(&context, frame, typical) }
        drawPhases(&context, frame)

        switch model.mode {
        case .bars: drawBars(&context, frame)
        case .stacked: drawStacked(&context, frame)
        case .line: drawLine(&context, frame)
        case .dualLine: drawDual(&context, frame)
        }
        if !model.segments.isEmpty { drawSegments(&context, frame) }
        if let average = model.average { drawAverage(&context, frame, average) }
        drawXLabels(&context, frame, size: size)
    }

    // MARK: Grid and overlays

    private func drawGrid(_ context: inout GraphicsContext, _ f: Frame, font: Font) {
        for tick in model.yTicks {
            let y = f.y(tick.value)
            var line = Path()
            line.move(to: CGPoint(x: f.plot.minX, y: y))
            line.addLine(to: CGPoint(x: f.plot.maxX, y: y))
            context.stroke(line, with: .color(PulseTheme.gridOnPage), lineWidth: 1)
            context.draw(Text(tick.label).font(font).foregroundColor(tick.color),
                         at: CGPoint(x: 0, y: y), anchor: .leading)
        }
    }

    private func drawTypical(_ context: inout GraphicsContext, _ f: Frame, _ range: ClosedRange<Double>) {
        let top = f.y(range.upperBound)
        let bottom = f.y(range.lowerBound)
        let rect = CGRect(x: f.plot.minX, y: top, width: f.plot.width, height: max(2, bottom - top))
        context.fill(Path(rect), with: .color(PulseTheme.typicalBand))
    }

    private func drawPhases(_ context: inout GraphicsContext, _ f: Frame) {
        guard !model.phases.isEmpty else { return }
        let y = f.plot.maxY + 4
        for span in model.phases {
            let x0 = f.edge(span.startIndex) + 1
            let x1 = f.edge(span.endIndex + 1) - 1
            guard x1 > x0 else { continue }
            let rect = CGRect(x: x0, y: y, width: x1 - x0, height: 4)
            context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(span.phase.color))
        }
    }

    private func drawAverage(_ context: inout GraphicsContext, _ f: Frame, _ value: Double) {
        let y = f.y(value)
        var line = Path()
        line.move(to: CGPoint(x: f.plot.minX, y: y))
        line.addLine(to: CGPoint(x: f.plot.maxX, y: y))
        context.stroke(line, with: .color(PulseTheme.averageLine), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        // The "AVG." pill at the left axis, over the y labels, as WHOOP sets it.
        let text = context.resolve(Text(String(localized: "Avg.").uppercased())
            .font(PulseType.font(.chipStrong)).foregroundColor(.black))
        let size = text.measure(in: CGSize(width: 80, height: 20))
        let pill = CGRect(x: 0, y: y - (size.height + 6) / 2, width: size.width + 14, height: size.height + 6)
        context.fill(Path(roundedRect: pill, cornerRadius: 3), with: .color(.white))
        context.draw(text, at: CGPoint(x: pill.midX, y: pill.midY), anchor: .center)
    }

    // MARK: Bars

    private func barRect(_ f: Frame, index: Int, from low: Double, to high: Double) -> CGRect {
        let width = min(model.barWidth, max(2, f.pitch * 0.8))
        let top = f.y(high)
        let bottom = f.y(low)
        return CGRect(x: f.x(index) - width / 2, y: top, width: width, height: max(1, bottom - top))
    }

    private func drawBars(_ context: inout GraphicsContext, _ f: Frame) {
        let base = model.yDomain.lowerBound
        let opacity = model.dimmed ? PulseTheme.Trends.dimmedData : 1
        for (i, column) in model.columns.enumerated() {
            guard let value = column.value else { continue }
            let rect = barRect(f, index: i, from: base, to: value)
            let shape = UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2, style: .circular)
                .path(in: rect)
            context.fill(shape, with: .color(column.color.opacity(opacity)))
            if let label = column.label {
                drawValueLabel(&context, label, color: column.color, at: CGPoint(x: f.x(i), y: rect.minY - 4))
            }
        }
    }

    private func drawStacked(_ context: inout GraphicsContext, _ f: Frame) {
        let opacity = model.dimmed ? PulseTheme.Trends.dimmedData : 1
        for (i, column) in model.columns.enumerated() {
            guard column.value != nil else { continue }
            var low = model.yDomain.lowerBound
            var top = f.y(low)
            for (p, part) in column.parts.enumerated() where part > 0 {
                let high = low + part
                var rect = barRect(f, index: i, from: low, to: high)
                // A hairline between parts, as WHOOP separates REM from SWS.
                if p > 0 { rect.size.height = max(0.5, rect.height - 1) }
                let color = p < model.partColors.count ? model.partColors[p] : model.lineColor
                context.fill(Path(rect), with: .color(color.opacity(opacity)))
                low = high
                top = rect.minY
            }
            if let label = column.label {
                drawValueLabel(&context, label, color: PulseTheme.textPrimary, at: CGPoint(x: f.x(i), y: top - 4))
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

    private func drawDual(_ context: inout GraphicsContext, _ f: Frame) {
        let hours = points(f) { $0.value }
        let need = points(f) { $0.secondary }
        let needColor = model.secondaryColor ?? PulseTheme.positive
        for (series, color) in [(need, needColor), (hours, model.lineColor)] where !series.isEmpty {
            var path = Path()
            path.addLines(series.map(\.point))
            context.stroke(path, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            for p in series { drawMarker(&context, at: p.point, color: color) }
        }
        // Each day's higher value is labelled above its marker, the lower one below.
        for (i, column) in model.columns.enumerated() {
            let x = f.x(i)
            let h = column.value.map { (value: $0, label: column.label, color: model.lineColor) }
            let n = column.secondary.map { (value: $0, label: column.secondaryLabel, color: needColor) }
            let pair = [h, n].compactMap { $0 }.sorted { $0.value > $1.value }
            for (rank, item) in pair.enumerated() {
                guard let label = item.label else { continue }
                let y = f.y(item.value)
                if rank == 0 {
                    drawValueLabel(&context, label, color: item.color, at: CGPoint(x: x, y: y - 8))
                } else {
                    drawValueLabel(&context, label, color: item.color, at: CGPoint(x: x, y: y + 22))
                }
            }
        }
    }

    private func drawMarker(_ context: inout GraphicsContext, at point: CGPoint, color: Color) {
        let rect = CGRect(x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9)
        context.fill(Path(ellipseIn: rect), with: .color(PulseTheme.pageBottom))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 1, dy: 1)), with: .color(color), lineWidth: 2)
    }

    /// A value over a column or point, bottom-centred on `point`, kept inside the chart's top. Where it
    /// would sit on `plateOver` (the typical band) it gets a dark plate so it stays legible.
    private func drawValueLabel(_ context: inout GraphicsContext, _ text: String, color: Color, at point: CGPoint,
                                plateOver: CGRect? = nil) {
        let resolved = context.resolve(Text(text).font(PulseType.numeral(15)).foregroundColor(color))
        let size = resolved.measure(in: CGSize(width: 120, height: 30))
        let y = max(size.height, point.y)
        let rect = CGRect(x: point.x - size.width / 2, y: y - size.height, width: size.width, height: size.height)
        if let plate = plateOver, plate.intersects(rect) {
            context.fill(Path(roundedRect: rect.insetBy(dx: -3, dy: -1), cornerRadius: 3),
                         with: .color(PulseTheme.pageBottom.opacity(0.85)))
        }
        context.draw(resolved, at: CGPoint(x: point.x, y: y), anchor: .bottom)
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
            let value = context.resolve(Text(segment.valueLabel).font(PulseType.numeral(15)).foregroundColor(PulseTheme.textPrimary))
            context.draw(value, at: CGPoint(x: x0, y: y - 4), anchor: .bottomLeading)
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
