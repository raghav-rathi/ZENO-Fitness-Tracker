#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - MENSTRUAL CYCLE INSIGHTS on Home (WHOOP_UI_SPEC §3.1 item 8e)
//
// Opt-in (Settings' cycle awareness), after MY JOURNAL. The card says where the cycle is from ZENO's own
// temperature-shift engine (`CyclePhaseEngine`, published on AppModel): the estimated cycle day, the phase
// in its colour, the likely window for the next period, a dot per day of the wearer's own cycle length
// with today large and white, and "+ LOG CYCLE". Awareness only, never a fertility or medical claim; with
// too little data it says it is learning, and with no clear pattern it predicts nothing.

/// Reads the cycle estimate off AppModel in its own leaf (AppModel publishes every heart-rate tick).
struct PulseMenstrualCardHost: View {
    @EnvironmentObject private var app: AppModel
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false

    var body: some View {
        if let demo = PulseMenstrualCardHost.debugResult {
            PulseMenstrualCard(result: demo)
                .equatable()
        } else if enabled {
            PulseMenstrualCard(result: app.cyclePhase)
                .equatable()
        }
    }

    /// DEBUG `--pulse-cycle-demo`: a synthetic luteal estimate, so the card's phase, window and dot strip
    /// can be captured without six weeks of temperature data. nil in Release and without the flag.
    static var debugResult: CyclePhaseEngine.Result? {
        #if DEBUG
        guard CommandLine.arguments.contains("--pulse-cycle-demo") else { return nil }
        let today = Repository.localDayKey(Date())
        let window = CyclePhaseEngine.NextPeriodWindow(earliestDay: PulseDisplay.dayKey(today, offsetBy: 6) ?? today,
                                                       latestDay: PulseDisplay.dayKey(today, offsetBy: 9) ?? today)
        return CyclePhaseEngine.Result(phase: .luteal, confidence: .building, cycleDayLow: 21, cycleDayHigh: 21,
                                       cycleLengthDays: 28, nextPeriodWindow: window, shiftMarkers: [], note: "")
        #else
        return nil
        #endif
    }
}

struct PulseMenstrualCard: View, Equatable {
    let result: CyclePhaseEngine.Result?

    @State private var logging = false

    static func == (lhs: PulseMenstrualCard, rhs: PulseMenstrualCard) -> Bool { lhs.result == rhs.result }

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
                    if let strip {
                        PulseCycleDotStrip(length: strip.length, today: strip.today, color: phase?.color ?? PulseTheme.textSecondary)
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

    /// The dot strip, only once the engine has seen the wearer's own cycle length.
    private var strip: (length: Int, today: Int)? {
        guard let result, let length = result.cycleLengthDays, let day = result.cycleDayHigh, length > 0 else {
            return nil
        }
        return (length, min(day, length))
    }
}

/// One dot per day of the cycle: the days so far in the phase's colour (dimmed), today a larger white dot,
/// the rest faint; day numbers 1 · 7 · 14 · 21 · 28 under the strip.
struct PulseCycleDotStrip: View {
    let length: Int
    let today: Int
    let color: Color

    var body: some View {
        VStack(spacing: PulseTheme.Space.xxs) {
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(1, length))
                ZStack(alignment: .leading) {
                    ForEach(1...max(1, length), id: \.self) { day in
                        let isToday = day == today
                        Circle()
                            .fill(isToday ? PulseTheme.textPrimary : (day < today ? color.opacity(0.7) : PulseTheme.textDisabled.opacity(0.5)))
                            .frame(width: isToday ? 10 : 5, height: isToday ? 10 : 5)
                            .position(x: step * (CGFloat(day) - 0.5), y: geo.size.height / 2)
                    }
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(1, length))
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
        .accessibilityLabel(String(localized: "Cycle day \(today) of \(length)"))
    }

    private var marks: [Int] {
        [1, 7, 14, 21, 28, 35].filter { $0 <= length }
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
