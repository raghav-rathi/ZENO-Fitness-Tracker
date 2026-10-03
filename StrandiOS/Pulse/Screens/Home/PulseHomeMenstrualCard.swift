#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - MENSTRUAL CYCLE INSIGHTS on Home (WHOOP_UI_SPEC §3.1 item 8e)
//
// Opt-in (Settings' cycle awareness), after MY JOURNAL. The card states where the cycle is through Menstrual
// Cycle Insights' own funnel (`PulseSnapshotBuilder.cycleToday`, which the Health tab's card reads too): the
// logs first, ZENO's temperature-shift engine (`CyclePhaseEngine`) only where there are no usable logs. Its
// day ("Day 3"), the phase in its colour and the line under it ("Logged Period Day • Next period in: 26–28
// Days") are the page's header, so Home, the Health card and the page name the same day. Under them a dot per
// day of the cycle, today large and white on that same day, coloured from what is actually known (the logged
// period days, the detected temperature shift), and "+ LOG CYCLE", which opens the page's own log sheet.
// Awareness only, never a fertility or medical claim.

/// Builds the card's snapshot off the main actor, again whenever a refresh, a log, the cycle settings or the
/// temperature engine's estimate changes, exactly as the Health tab's card does (`HealthCycleSlot`), and
/// reads the estimate off AppModel in its own leaf (AppModel publishes every heart-rate tick).
struct PulseMenstrualCardHost: View {
    /// The LOG CYCLE sheet is up: Home's root presents it, so tilt mode can wait for it to close.
    @Binding var logging: Bool

    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var repo: Repository
    @Environment(PulseModel.self) private var model
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue
    @State private var today: CycleTodaySnapshot?
    @State private var periodDays: [String] = []

    /// What the card reloads on: the Health tab card's key (`HealthCycleSlot`).
    private struct LoadKey: Equatable {
        let health: String
        let logSeq: Int
        let mode: String
        let contraception: String
        let engine: CyclePhaseEngine.Result?
    }

    var body: some View {
        Group {
            if enabled {
                PulseMenstrualCard(today: today, periodDays: periodDays,
                                   shiftMarkers: app.cyclePhase?.shiftMarkers ?? []) { logging = true }
                    .equatable()
            }
        }
        .task(id: enabled ? LoadKey(health: model.healthKey, logSeq: repo.cycleTrackingSeq, mode: modeRaw,
                                    contraception: contraceptionRaw, engine: app.cyclePhase) : nil) {
            guard enabled else { return }
            await load()
        }
    }

    /// The day, the estimate and the settings read here, on the main actor, as `HealthCycleSlot.load` reads
    /// them; the logs off it.
    private func load() async {
        let day = Repository.localDayKey(Date())
        let engine = app.cyclePhase
        let mode = PulseCycleLog.Mode(rawValue: modeRaw) ?? .menstruating
        let contraception = PulseCycleLog.Contraception(rawValue: contraceptionRaw) ?? .none
        if let s = await model.build(dayOffset: 0, { builder, request in
            await builder.cycleToday(request, today: day, engine: engine, mode: mode, contraception: contraception)
        }) {
            today = s
        }
        if let days = await model.build({ builder, _ in await builder.homePeriodDays() }) {
            periodDays = days
        }
    }
}

struct PulseMenstrualCard: View, Equatable {
    /// Where the cycle is today, as Menstrual Cycle Insights states it (`cycleToday`); nil while it builds.
    let today: CycleTodaySnapshot?
    /// The logged period days (`PulseSnapshotBuilder.homePeriodDays`: a logged start or a day of period flow,
    /// as the page's calendar marks them), oldest first.
    let periodDays: [String]
    /// The temperature engine's detected shifts, for the dot strip's luteal days.
    let shiftMarkers: [CyclePhaseEngine.ShiftMarker]
    /// "+ LOG CYCLE": opens the sheet Home presents (`PulseMenstrualCardHost.logging`).
    let onLog: () -> Void

    static func == (lhs: PulseMenstrualCard, rhs: PulseMenstrualCard) -> Bool {
        lhs.today == rhs.today && lhs.periodDays == rhs.periodDays && lhs.shiftMarkers == rhs.shiftMarkers
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Space.s) {
            PulseLink(PulseRoute.cycleInsights.forExistingEntryPoint) {
                VStack(alignment: .leading, spacing: PulseTheme.Space.s) {
                    PulseCardTitle(String(localized: "Menstrual Cycle Insights"), accessory: .trailingChevron)
                    VStack(alignment: .leading, spacing: 2) {
                        // "Day 3", "Day 18–22", "Log a period to start", "Symptom tracking".
                        Text(today?.headline ?? "--")
                            .pulseText(.pageTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        if let title = today?.header.title {
                            Text(title)
                                .pulseText(.cardTitle)
                                .foregroundStyle(today?.header.phase?.dot ?? PulseTheme.textSecondary)
                        }
                    }
                    if let subtitle = today?.header.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // Only where the page places today in a cycle of phases (not under hormonal contraception,
                    // nor in menopause), as the Health card's bar.
                    if let place = today?.place {
                        PulseCycleDotStrip(dots: PulseCycleDotStrip.dots(place: place, periodDays: periodDays,
                                                                         shiftMarkers: shiftMarkers,
                                                                         todayKey: Repository.localDayKey(Date())))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            Button(action: onLog) {
                Label(String(localized: "Log cycle"), systemImage: "plus")
            }
            .buttonStyle(.pulseNested(fill: PulseTheme.Menstrual.logButton))
        }
        .padding(PulseTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground(.solid(PulseTheme.Menstrual.homeCard))
        .id("pulse.cycle")
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

    /// The strip for today's place in the cycle (`CycleTodaySnapshot.place`: the card's own cycle day, the
    /// logs' or else the middle of the engine's range, in a cycle of the modelled length), mapped to
    /// `todayKey`, so today's dot is on the day the headline states. `periodDays` are the logged period days,
    /// oldest first (`PulseSnapshotBuilder.homePeriodDays`), so a day the page shows as a logged period day is
    /// one here too.
    static func dots(place: CycleTodaySnapshot.Place, periodDays: [String],
                     shiftMarkers: [CyclePhaseEngine.ShiftMarker], todayKey: String) -> [Dot] {
        let today = max(1, place.day)
        let count = max(place.length, today)
        let firstDay = PulseDisplay.dayKey(todayKey, offsetBy: 1 - today) ?? todayKey
        let logged = Set(periodDays)
        // The last logged period day and the latest temperature shift inside this cycle, if any.
        let lastPeriodDay = periodDays.last { $0 >= firstDay && $0 <= todayKey }
        let shift = shiftMarkers.map(\.day).last { $0 >= firstDay && $0 <= todayKey }
        return (1...count).map { day -> Dot in
            if day == today { return .today }
            if day > today { return .ahead }
            guard let key = PulseDisplay.dayKey(todayKey, offsetBy: day - today) else { return .unknown }
            if logged.contains(key) { return .period }
            if let shift, key >= shift { return .luteal }
            // After the logged bleed and before the shift (or with no shift yet): the follicular phase.
            if let lastPeriodDay, key > lastPeriodDay, shift.map({ key < $0 }) ?? true { return .follicular }
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
#endif
