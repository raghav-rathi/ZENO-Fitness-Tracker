#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - MENSTRUAL CYCLE INSIGHTS on Home (WHOOP_UI_SPEC §3.1 item 8e)
//
// Opt-in (Settings' cycle awareness), after MY JOURNAL. The card says where the cycle is from ZENO's own
// temperature-shift engine (`CyclePhaseEngine`, published on AppModel): the estimated cycle day, the phase
// in its colour, the likely window for the next period, a dot per day of the cycle coloured from what is
// actually known (a logged period start, the detected temperature shift), today large and white, and
// "+ LOG CYCLE". Awareness only, never a fertility or medical claim; with too little data it says it is
// learning, and with no clear pattern it predicts nothing.

/// Reads the cycle estimate off AppModel in its own leaf (AppModel publishes every heart-rate tick), and
/// the logged period starts off the main actor, again whenever one is logged.
struct PulseMenstrualCardHost: View {
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var repo: Repository
    @Environment(PulseModel.self) private var model
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false
    @State private var periodStarts: [String] = []

    var body: some View {
        Group {
            if let demo = Self.debugResult {
                PulseMenstrualCard(result: demo.result, periodStarts: demo.periodStarts)
                    .equatable()
            } else if enabled {
                PulseMenstrualCard(result: app.cyclePhase, periodStarts: periodStarts)
                    .equatable()
            }
        }
        .task(id: enabled ? repo.cycleTrackingSeq : -1) {
            guard enabled else { return }
            if let starts = await model.build({ builder, _ in await builder.homePeriodStarts() }) {
                periodStarts = starts
            }
        }
    }

    /// DEBUG `--pulse-cycle-demo`: a synthetic luteal estimate (cycle day 21 of 28, a period logged on day 1
    /// and the temperature shift on day 15), so the card's day, phase, window and dot strip can be captured
    /// without six weeks of temperature data. nil in Release and without the flag.
    static var debugResult: (result: CyclePhaseEngine.Result, periodStarts: [String])? {
        #if DEBUG
        guard CommandLine.arguments.contains("--pulse-cycle-demo") else { return nil }
        let today = Repository.localDayKey(Date())
        func day(_ offset: Int) -> String { PulseDisplay.dayKey(today, offsetBy: offset) ?? today }
        let window = CyclePhaseEngine.NextPeriodWindow(earliestDay: day(6), latestDay: day(9))
        let result = CyclePhaseEngine.Result(phase: .luteal, confidence: .building, cycleDayLow: 21, cycleDayHigh: 21,
                                             cycleLengthDays: 28, nextPeriodWindow: window,
                                             shiftMarkers: [CyclePhaseEngine.ShiftMarker(day: day(-6))], note: "")
        return (result, [day(-20)])
        #else
        return nil
        #endif
    }
}

struct PulseMenstrualCard: View, Equatable {
    let result: CyclePhaseEngine.Result?
    /// Logged period starts (`Repository.periodStarts`), oldest first.
    let periodStarts: [String]

    @State private var logging = false

    static func == (lhs: PulseMenstrualCard, rhs: PulseMenstrualCard) -> Bool {
        lhs.result == rhs.result && lhs.periodStarts == rhs.periodStarts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Space.s) {
            PulseLink(PulseRoute.cycleInsights.forExistingEntryPoint) {
                VStack(alignment: .leading, spacing: PulseTheme.Space.s) {
                    PulseCardTitle(String(localized: "Menstrual Cycle Insights"), accessory: .trailingChevron)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headline)
                            .pulseText(.pageTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        if let phase {
                            Text(phase.name)
                                .pulseText(.cardTitle)
                                .foregroundStyle(phase.color)
                        }
                    }
                    Text(sentence)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let result, let dots = PulseCycleDotStrip.dots(result: result, periodStarts: periodStarts,
                                                                       todayKey: Repository.localDayKey(Date())) {
                        PulseCycleDotStrip(dots: dots)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            Button { logging = true } label: {
                Label(String(localized: "Log cycle"), systemImage: "plus")
            }
            .buttonStyle(.pulseNested(fill: PulseTheme.Menstrual.logButton))
        }
        .padding(PulseTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground(.solid(PulseTheme.Menstrual.homeCard))
        .sheet(isPresented: $logging) { PulseLogPeriodSheet() }
        .id("pulse.cycle")
    }

    private var headline: String {
        guard let result else { return String(localized: "Learning Your Cycle") }
        switch result.phase {
        case .learning: return String(localized: "Learning Your Cycle")
        case .unknown: return String(localized: "No Phase Predicted")
        default:
            guard let lo = result.cycleDayLow, let hi = result.cycleDayHigh else {
                return String(localized: "No Phase Predicted")
            }
            return lo == hi ? String(localized: "Day \(lo)") : String(localized: "Day \(lo)-\(hi)")
        }
    }

    private var phase: (name: String, color: Color)? {
        switch result?.phase {
        case .follicular: return (String(localized: "Follicular phase"), PulseTheme.Menstrual.Phase.follicular.dot)
        case .periOvulatory: return (String(localized: "Around your mid-cycle shift"), PulseTheme.Menstrual.Phase.ovulatory.dot)
        case .luteal: return (String(localized: "Luteal phase"), PulseTheme.Menstrual.Phase.luteal.dot)
        default: return nil
        }
    }

    private var sentence: String {
        guard let result else {
            return String(localized: "Learning your pattern from your nightly temperature. Keep wearing your strap overnight.")
        }
        if let window = result.nextPeriodWindow {
            return String(localized: "Your next period is likely between \(PulseFormat.dayLabel(window.earliestDay)) and \(PulseFormat.dayLabel(window.latestDay)). A range, not a date.")
        }
        switch result.phase {
        case .follicular: return String(localized: "Temperature is near your baseline.")
        case .periOvulatory: return String(localized: "Temperature is changing around your mid-cycle shift.")
        case .luteal: return String(localized: "Temperature is above your baseline.")
        case .unknown:
            return String(localized: "No clear temperature pattern yet. This can happen with irregular cycles, hormonal contraception or shift work.")
        case .learning:
            return String(localized: "Learning your pattern from your nightly temperature. Keep wearing your strap overnight.")
        }
    }
}

/// One dot per day of the cycle (health-more-2026/04): a logged period day coral, the days after the
/// detected temperature shift in the luteal colour, the days between the two in the follicular colour,
/// today a larger white dot, the days ahead faint. A day nothing says anything about stays neutral: the
/// strip never assumes a period length or a phase it was not given. Day numbers 1 · 7 · 14 · 21 · 28 under
/// it. As long as the longer of the wearer's cycle length and today's cycle day.
struct PulseCycleDotStrip: View {
    enum Dot: Equatable {
        case period, follicular, luteal, unknown, today, ahead

        var color: Color {
            switch self {
            case .period: return PulseTheme.Menstrual.Phase.menstrual.dot
            case .follicular: return PulseTheme.Menstrual.Phase.follicular.dot
            case .luteal: return PulseTheme.Menstrual.Phase.luteal.dot
            case .unknown: return PulseTheme.textTertiary
            case .today: return PulseTheme.textPrimary
            case .ahead: return PulseTheme.textDisabled.opacity(0.5)
            }
        }
    }

    /// Cycle days 1 ... n, in order.
    let dots: [Dot]

    /// The strip for `result`, once the engine has seen the wearer's own cycle length. Today's cycle day is
    /// the middle of the engine's estimate (the headline's "Day 20-22" is day 21), mapped to `todayKey`.
    static func dots(result: CyclePhaseEngine.Result, periodStarts: [String], todayKey: String) -> [Dot]? {
        guard let length = result.cycleLengthDays, length > 0,
              let low = result.cycleDayLow, let high = result.cycleDayHigh else { return nil }
        let today = max(1, (low + high) / 2)
        let count = max(length, today)
        guard let firstDay = PulseDisplay.dayKey(todayKey, offsetBy: 1 - today) else { return nil }
        let logged = Set(periodStarts)
        // The latest logged start and temperature shift inside this cycle, if any.
        let start = periodStarts.last { $0 >= firstDay && $0 <= todayKey }
        let shift = result.shiftMarkers.map(\.day).last { $0 >= firstDay && $0 <= todayKey }
        return (1...count).map { day -> Dot in
            if day == today { return .today }
            if day > today { return .ahead }
            guard let key = PulseDisplay.dayKey(todayKey, offsetBy: day - today) else { return .unknown }
            if logged.contains(key) { return .period }
            if let shift, key >= shift { return .luteal }
            // After a logged start and before the shift (or with no shift yet): the follicular phase.
            if let start, key > start, shift.map({ key < $0 }) ?? true { return .follicular }
            return .unknown
        }
    }

    private var todayIndex: Int { (dots.firstIndex(of: .today) ?? 0) + 1 }

    var body: some View {
        VStack(spacing: PulseTheme.Space.xxs) {
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(1, dots.count))
                ZStack(alignment: .leading) {
                    ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                        let size: CGFloat = dot == .today ? 10 : 5
                        Circle()
                            .fill(dot.color)
                            .frame(width: size, height: size)
                            .position(x: step * (CGFloat(index) + 0.5), y: geo.size.height / 2)
                    }
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(1, dots.count))
                ForEach(marks, id: \.self) { day in
                    Text(verbatim: "\(day)")
                        .font(PulseType.font(.axis))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .position(x: step * (CGFloat(day) - 0.5), y: geo.size.height / 2)
                }
            }
            .frame(height: 14)
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Cycle day \(todayIndex) of \(dots.count)"))
    }

    private var marks: [Int] {
        [1, 7, 14, 21, 28, 35, 42].filter { $0 <= dots.count }
    }
}

/// "Log a period start": a dark sheet with a calendar (today and earlier), saving the day as cycle day 1
/// under ZENO's own isolated `noop-cycle` source, then re-running the cycle estimate.
struct PulseLogPeriodSheet: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var saving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: PulseTheme.Space.m) {
                DatePicker(String(localized: "Period started on"), selection: $date, in: ...Date(),
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(PulseTheme.Menstrual.Phase.menstrual.dot)
                Text(String(localized: "This date anchors cycle day 1 and is checked against your nightly temperature pattern. Awareness only, not contraception or a diagnosis."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button(String(localized: "Save")) {
                    saving = true
                    let day = Repository.localDayKey(date)
                    Task {
                        await repo.logPeriodStart(day: day)
                        await app.refreshV5Signals()
                        dismiss()
                    }
                }
                .buttonStyle(.pulseFilledWhite)
                .disabled(saving)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, PulseTheme.Space.m)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(PulseTheme.wheelSheet.ignoresSafeArea())
            .navigationTitle(String(localized: "Log Period Start"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                        .foregroundStyle(PulseTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }
}
#endif
