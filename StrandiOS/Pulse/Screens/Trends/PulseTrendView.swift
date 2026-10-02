#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Trend View (WHOOP_UI_SPEC §3.12), pushed: one metric over W / M / 6M / 1Y / ALL.
///
/// Top to bottom, as WHOOP lays it out (deep-dives-2026/46, 47, 37, 44, 45, 51, 53): "‹ TREND VIEW", the
/// metric dropdown (→ the metric picker), the header (AVERAGE, the value and its unit, the delta chip; the
/// range control and the range pager at the right), the sentence, the legend, the chart, the footnotes,
/// the breakdown block, then the metric's CTA rows and explainer, and the cycle-overlay note when the
/// overlay is on. The Coach button floats at the bottom right.
///
/// Every number comes from `TrendViewSnapshot`, built off the main actor from the metric's resolved
/// series (`PulseSnapshotBuilder.trendView`). The window is anchored on today whatever day Home shows.
/// Owned by group "trends".
struct PulseTrendView: View {
    /// Existing entry points (My Dashboard rows, STRAIN & RECOVERY) open this screen instead of the classic
    /// metric detail once it is true (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = true
    /// The `MetricCatalog` key of the metric to chart first.
    let metric: String

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var key: String
    @State private var range: PulseTrendMath.Range
    @State private var page: Int
    @State private var snapshot: TrendViewSnapshot?
    /// WHAT CORRELATES, loaded after the page (it scans every other metric).
    @State private var correlations: [PulseTrendCorrelation]?
    @State private var showsPicker = false
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""
    @AppStorage(AppModel.cycleAwarenessKey) private var cycleAwareness = false

    init(metric: String) {
        self.metric = metric
        _key = State(initialValue: metric)
        var range = PulseTrendMath.Range.week
        var page = 0
        var picker = false
        #if DEBUG
        range = PulseTrendDebugLaunch.range ?? range
        page = PulseTrendDebugLaunch.page ?? page
        picker = PulseTrendDebugLaunch.opensPicker
        #endif
        _range = State(initialValue: range)
        _page = State(initialValue: page)
        _showsPicker = State(initialValue: picker)
    }

    private var units: PulseTrendUnits {
        let system = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        return PulseTrendUnits(fahrenheit: UnitPrefs.resolveTemperature(system: system, override: temperatureRaw) == .fahrenheit,
                               imperialMass: system == .imperial)
    }

    private var resolved: PulseTrendMetric? { PulseTrendMetric.resolve(key) }

    private var loadKey: String {
        "\(model.healthKey)|\(key)|\(range.rawValue)|\(page)|\(units.id)|\(cycleAwareness)"
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Trend View"), coach: .button, coachSeed: coachSeed,
                            spacing: 0, ready: snapshot != nil) {
            dropdown
                .padding(.top, 18)
            if resolved == nil {
                unavailable
                    .padding(.top, 24)
            } else {
                PulseLoadingGate(isLoading: snapshot == nil) {
                    if let snapshot {
                        PulseTrendPage(snapshot: snapshot, correlations: correlations, range: rangeBinding,
                                       onBack: back, onForward: forward)
                    }
                } skeleton: {
                    skeleton
                }
            }
        }
        .task(id: loadKey) { await load() }
        .sheet(isPresented: $showsPicker) {
            PulseTrendMetricPicker(selected: key, units: units) { chosen in
                guard chosen != key else { return }
                key = chosen
                page = 0
                snapshot = nil
                correlations = nil
                if let m = PulseTrendMetric.resolve(chosen), !m.ranges.contains(range) {
                    range = m.ranges.first ?? .week
                }
            }
            .environment(model)
        }
    }

    // MARK: Loading

    private func load() async {
        guard resolved != nil else { return }
        let key = self.key, range = self.range, page = self.page, units = self.units, cycle = cycleAwareness
        if let s = await model.build(dayOffset: 0, { builder, request in
            await builder.trendView(request, key: key, range: range, page: page, units: units, cycleOverlay: cycle)
        }) {
            snapshot = s
            // The builder clamps a page past the history; keep the state in step with what is shown.
            if s.page != self.page { self.page = s.page }
            if s.range != self.range { self.range = s.range }
        }
        if let rows = await model.build(dayOffset: 0, { builder, request in
            await builder.trendCorrelations(request, key: key, range: range, page: page, units: units)
        }) {
            correlations = rows
        }
    }

    private var rangeBinding: Binding<PulseTrendMath.Range> {
        Binding(get: { range }, set: { new in
            guard new != range else { return }
            range = new
            page = 0
        })
    }

    private func back() { page += 1 }
    private func forward() { page = max(0, page - 1) }

    private var coachSeed: String? {
        guard let s = snapshot else { return nil }
        let headline = s.headlines.map { "\($0.label) \($0.value)\($0.unit.isEmpty ? "" : " " + $0.unit)" }
            .joined(separator: ", ")
        return String(localized: "Trend View: \(s.metric.title), \(s.pager.title). \(headline). \(s.insight ?? "")")
    }

    // MARK: Pieces

    /// The metric dropdown: a full-width card (≈54 pt, radius 12) with the metric's icon, its name in
    /// 13 pt Bold caps and "⌄" at the right. It opens the metric picker.
    private var dropdown: some View {
        Button { showsPicker = true } label: {
            HStack(spacing: 14) {
                Image(systemName: resolved?.symbol ?? "chart.xyaxis.line")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(resolved?.title ?? String(localized: "Choose a metric"))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Trends.dropdownHeight, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.Trends.dropdown))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(resolved?.title ?? String(localized: "Choose a metric"))
        .accessibilityHint(String(localized: "Opens the list of metrics"))
    }

    private var unavailable: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "No Trend View for this metric"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Choose another metric from the list above."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    PulseSkeletonBlock(height: 12, width: 64, radius: 4)
                    PulseSkeletonBlock(height: 36, width: 96, radius: 6)
                    PulseSkeletonBlock(height: 18, width: 132, radius: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 18) {
                    PulseSkeletonBlock(height: 36, width: PulseTheme.Trends.rangeColumnWidth, radius: PulseTheme.Radius.control)
                    PulseSkeletonBlock(height: 16, width: 150, radius: 4)
                }
            }
            .padding(.top, 31)
            PulseSkeletonBlock(height: 44, radius: 6)
                .padding(.top, 30)
            PulseSkeletonBlock(height: 280)
                .padding(.top, 32)
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Loading"))
    }
}

// MARK: - The page

/// Everything below the dropdown, drawn from one snapshot.
private struct PulseTrendPage: View {
    let snapshot: TrendViewSnapshot
    let correlations: [PulseTrendCorrelation]?
    @Binding var range: PulseTrendMath.Range
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, 31)
            if let insight = snapshot.insight {
                Text(insight)
                    .pulseText(.trendInsight)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 30)
            }
            VStack(alignment: .trailing, spacing: 12) {
                if !snapshot.legend.isEmpty { legend }
                PulseTrendChart(model: snapshot.chart)
            }
            .padding(.top, snapshot.legend.isEmpty ? 32 : 24)
            if !snapshot.footnotes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(snapshot.footnotes, id: \.self) { note in footnote(note) }
                }
                .padding(.top, 14)
            }
            if let breakdown = snapshot.breakdown {
                PulseTrendBreakdownView(breakdown: breakdown)
                    .padding(.top, 28)
            }
            if snapshot.showsCycleNote {
                cycleNote.padding(.top, 24)
            }
            if let cta = snapshot.metric.cta {
                ctaRow(cta).padding(.top, 24)
            }
            if let explainer = snapshot.metric.explainer, explainer.count == 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(explainer[0])
                        .pulseText(.subsectionTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(explainer[1])
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 28)
            }
            if let correlations, snapshot.hasData {
                PulseTrendCorrelationsCard(rows: correlations, metric: snapshot.metric, range: snapshot.range)
                    .padding(.top, 28)
            }
        }
    }

    // MARK: Header

    /// AVERAGE / value / chip at the left; W | M | 6M | 1Y | ALL and the range pager at the right. At large
    /// text sizes the two stack.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                headlines
                Spacer(minLength: 0)
                rangeColumn
            }
            VStack(alignment: .leading, spacing: 20) {
                headlines
                rangeColumn
            }
        }
    }

    @ViewBuilder
    private var headlines: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(snapshot.headlines) { item in
                if item.compact { compactHeadline(item) } else { headline(item) }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func headline(_ item: PulseTrendHeadline) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
            // WHOOP sets the unit bold, about 0.6 of the value and a space apart ("74 %", "50 ms").
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(item.value)
                    .pulseText(.largeValue)
                    .foregroundStyle(item.valueColor)
                if !item.unit.isEmpty {
                    Text(item.unit)
                        .pulseText(.dialUnit)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
            }
            .lineLimit(1)
            .padding(.top, 4)
            if let chip = item.chip {
                PulseDeltaChip(text: chip.text, trend: chip.trend)
                    .padding(.top, 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibility + (item.chip.map { ", \($0.text), \($0.trend.accessibilityDescription)" } ?? ""))
    }

    /// HOURS VS. NEEDED's stacked values: "7:40 hr ▼1%" over "AVG. NEED".
    private func compactHeadline(_ item: PulseTrendHeadline) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                PulseValueText(value: item.value, unit: item.unit.isEmpty ? nil : item.unit, style: .mediumValue,
                               unitStyle: .tileUnit, color: item.valueColor, unitColor: PulseTheme.textPrimary)
                if let chip = item.chip { PulseDeltaChip(text: chip.text, trend: chip.trend) }
            }
            Text(item.label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibility + (item.chip.map { ", \($0.text), \($0.trend.accessibilityDescription)" } ?? ""))
    }

    private var rangeColumn: some View {
        VStack(alignment: .trailing, spacing: 22) {
            PulseSegmentedControl(options: snapshot.metric.ranges, selection: $range) { $0.segmentTitle }
                .frame(width: PulseTheme.Trends.rangeColumnWidth)
                .accessibilityLabel(String(localized: "Range"))
            PulseTrendRangePager(pager: snapshot.pager, onBack: onBack, onForward: onForward)
                .frame(width: PulseTheme.Trends.rangeColumnWidth)
        }
    }

    // MARK: Legend, footnotes, rows

    private var legend: some View {
        PulseWordFlow(alignment: .trailing, spacing: 16, lineSpacing: 10) {
            ForEach(snapshot.legend) { item in
                HStack(spacing: 7) {
                    swatch(item)
                    Text(item.title)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func swatch(_ item: PulseTrendLegendItem) -> some View {
        switch item.swatch {
        case .square:
            RoundedRectangle(cornerRadius: 1.5).fill(item.color).frame(width: 10, height: 10)
        case .dot:
            Capsule().fill(item.color).frame(width: 14, height: 7)
        case .ring:
            Circle().strokeBorder(item.color, lineWidth: 2).frame(width: 10, height: 10)
        }
    }

    private func footnote(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "info")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(width: 12)
                .accessibilityHidden(true)
            Text(text)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 6)
    }

    private var cycleNote: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "info")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PulseTheme.Activity.infoBannerText)
                .accessibilityHidden(true)
            Text(String(localized: "See patterns in your trends data across your menstrual cycle. Phases follow your nightly temperature; menstrual days are the five from each period start you log. You can turn cycle awareness off in Automations at any time."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.Activity.infoBannerText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.Activity.infoBannerFill.opacity(0.6)))
    }

    private func ctaRow(_ cta: PulseTrendCTA) -> some View {
        let (title, symbol, route) = Self.cta(cta)
        return PulseLink(route) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(title)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textPrimary, size: 15)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Trends.ctaRowHeight, alignment: .leading)
            .pulseCardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    /// A CTA row's words, icon and destination. Steps: "SET A STEPS GOAL IN WEEKLY PLAN" once the plan
    /// is rebuilt; until then the goal lives on the Steps screen, which the older WHOOP wording names.
    private static func cta(_ cta: PulseTrendCTA) -> (String, String, PulseRoute) {
        switch cta {
        case .addActivity:
            return (String(localized: "Add activity"), "plus", PulseRoute.addActivity.forExistingEntryPoint)
        case .stepsGoal:
            let plan = PulseRoute.weeklyPlan(editing: true)
            return plan.isRebuilt
                ? (String(localized: "Set a steps goal in Weekly Plan"), "list.clipboard", plan)
                : (String(localized: "Update your daily step goal"), "list.clipboard", .tab(.steps(day: nil)))
        }
    }
}

// MARK: - What correlates

/// WHAT CORRELATES (§3.12 [Z]): the other metrics that move with this one over the page's period, each
/// opening its own Trend View. Pearson r on the days both have a reading; |r| ≥ 0.30 on 10 or more days.
private struct PulseTrendCorrelationsCard: View {
    let rows: [PulseTrendCorrelation]
    let metric: PulseTrendMetric
    let range: PulseTrendMath.Range

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(String(localized: "What correlates"))
                Text(String(localized: "Metrics whose days moved with \(metric.sentenceName) over this period"))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                if rows.isEmpty {
                    Text(range == .week
                         ? String(localized: "A week is too short to tell. Try M or a longer range.")
                         : String(localized: "Nothing moved clearly with \(metric.sentenceName) over this period."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { PulseDivider() }
                            PulseLink(.trendView(metric: row.id)) { line(row) }
                                .buttonStyle(PulsePressStyle())
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    private func line(_ row: PulseTrendCorrelation) -> some View {
        HStack(spacing: 14) {
            Image(systemName: row.symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(row.r > 0 ? String(localized: "Moves with it, \(row.n) days")
                               : String(localized: "Moves against it, \(row.n) days"))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            Spacer(minLength: 8)
            Text(String(format: "%+.2f", locale: AppLanguage.activeLocale, row.r))
                .pulseText(.rowValue)
                .foregroundStyle(PulseTheme.textPrimary)
            PulseChevron()
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(row.title), correlation \(String(format: "%.2f", row.r)) over \(row.n) days"))
        .accessibilityHint(String(localized: "Opens its Trend View"))
    }
}

// MARK: - Range pager

/// "‹ SEP 19 - SEP 25, 26 ›" under the range control: 12 pt Bold caps, white chevrons, "›" (or "‹") white
/// 40% when there is nothing that way. The chevrons' 44 pt hit areas overflow the column.
struct PulseTrendRangePager: View {
    let pager: PulseTrendPager
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            chevron("chevron.left", enabled: pager.canGoBack, label: String(localized: "Previous period"), action: onBack)
            Text(pager.title)
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(pager.accessibility)
            chevron("chevron.right", enabled: pager.canGoForward, label: String(localized: "Next period"), action: onForward)
        }
        .frame(height: 24)
    }

    private func chevron(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 22, height: 24)
                .contentShape(Rectangle().inset(by: -11))
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: - Breakdown

/// "RECOVERY BREAKDOWN (DAYS)": the title, a 12 pt stacked bar with 3 pt gaps, then a row per band: a
/// square swatch, the count ("11x") or time ("0:30"), and the band's name and range in grey.
struct PulseTrendBreakdownView: View {
    let breakdown: PulseTrendBreakdown

    private var shown: [PulseTrendBreakdown.Row] { breakdown.rows.filter { $0.share > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(breakdown.title)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(breakdown.unitNote)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            GeometryReader { geo in
                let gaps = CGFloat(max(0, shown.count - 1)) * PulseTheme.Trends.breakdownBarGap
                HStack(spacing: PulseTheme.Trends.breakdownBarGap) {
                    ForEach(shown) { row in
                        Rectangle()
                            .fill(row.color)
                            .frame(width: max(1, (geo.size.width - gaps) * row.share))
                    }
                }
            }
            .frame(height: PulseTheme.Trends.breakdownBarHeight)
            .padding(.top, 14)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(breakdown.rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Rectangle()
                            .fill(row.color)
                            .frame(width: PulseTheme.Trends.breakdownSwatch, height: PulseTheme.Trends.breakdownSwatch)
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                        Text(row.amount)
                            .pulseText(.rowValue)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(minWidth: 44, alignment: .leading)
                            .padding(.leading, 12)
                        Text(row.range.isEmpty ? row.name : "\(row.name) \(row.range)")
                            .pulseText(.subtitle)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .padding(.leading, 6)
                    }
                    .frame(minHeight: PulseTheme.Trends.breakdownRowPitch)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(row.amount) \(row.name) \(row.range)")
                }
            }
            .padding(.top, 6)
        }
    }
}

#if DEBUG
/// DEBUG launch flags for captures: `--trend-range w|m|6m|1y|all`, `--trend-page N` (also the digest's
/// page), `--trend-picker`, `--trend-cycle-demo` and `--digest-mode w|m`.
enum PulseTrendDebugLaunch {
    private static func value(_ flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var range: PulseTrendMath.Range? {
        switch value("--trend-range")?.lowercased() {
        case "w": return .week
        case "m": return .month
        case "6m": return .sixMonths
        case "1y": return .year
        case "all": return .all
        default: return nil
        }
    }

    static var page: Int? { value("--trend-page").flatMap(Int.init) }

    /// `--trend-picker`: open the Trend View's metric picker at launch.
    static var opensPicker: Bool { CommandLine.arguments.contains("--trend-picker") }

    /// `--trend-cycle-demo` (with cycle awareness on): a fixed 28-day phase pattern for the overlay, so the
    /// strip, its legend and its note can be checked in the simulator, whose seeded skin temperature never
    /// gives the cycle engine a usable baseline. DEBUG only; nothing in a Release build draws it.
    static func cycleDemoPhases(endingOn today: String) -> [String: PulseTrendCyclePhase]? {
        guard CommandLine.arguments.contains("--trend-cycle-demo") else { return nil }
        var out: [String: PulseTrendCyclePhase] = [:]
        for back in 0..<200 {
            let day = PulseTrendMath.addDays(today, -back)
            let cycleDay = ((200 - back) % 28)
            switch cycleDay {
            case ..<5: out[day] = .menstrual
            case ..<12: out[day] = .follicular
            case ..<16: out[day] = .ovulatory
            default: out[day] = .luteal
            }
        }
        return out
    }

    /// `--digest-mode w|m`: the Weekly Digest's week or month.
    static var digestMode: WeeklyDigestSnapshot.Mode? {
        switch value("--digest-mode")?.lowercased() {
        case "w": return .week
        case "m": return .month
        default: return nil
        }
    }
}
#endif
#endif
