#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// The live session as a destination of its own, full screen. `PulseLiftSessionPresenter` presents it
/// whenever `LiftSessionController.isPresented` is set (a workout started or resumed in the Strength Trainer
/// or the Lift Log, a tap on the session bar): the host of the modal on top does, such as the Strength
/// Trainer's, else the shell.
struct PulseStrengthLiveRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .fullScreen }
    var view: some View { PulseStrengthLiveSessionView() }
}

/// The live session (WHOOP_UI_SPEC §3.29 "Live session"; activity-flows-2026/g07a–c, g08, g10), a full-
/// screen rendering of the app's one `LiftSessionController`: the strap double-tap, the rest buzzes, the
/// Lock Screen banner and the minimised bar all keep following the same session.
///
///   "•••" · WORKOUT NAME over the elapsed time · "+" (add an exercise)
///   LIVE SESSION | EXERCISES
///   LIVE SESSION: the REST / ACTIVE ring and its clock, HEART RATE with the six-zone bar, the exercise
///   card (NEXT while resting, ⓘ → Exercise Details, SET | REPS | KG), and the set button:
///   START SET (mint outline) → END SET (white outline) → … → FINISH WORKOUT.
///   EXERCISES: every line with its sets, typed into as the Lift Log's sheet allows.
///
/// ZENO's rest is a COUNTDOWN (the engine's absolute rest end; WHOOP counts up and its users ask for
/// this): the ring empties as the rest runs. The ring and clocks redraw once a second only while on screen
/// (`TimelineView`), never through the session's own publishes, which is what kept the classic sheet cheap
/// in the background (#21 Sep 2026 kills). No live strain is shown: Strain comes from heart rate after.
struct PulseStrengthLiveSessionView: View {
    enum Tab: Hashable {
        case live, exercises
    }

    @EnvironmentObject private var session: LiftSessionController
    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @State private var tab: Tab = .live
    @State private var showsFinish = false
    @State private var addingExercise = false
    @State private var details: PulseStrengthExerciseTarget?
    @State private var confirmingDiscard = false

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("--pulse-strength-exercises") {
            _tab = State(initialValue: .exercises)
        }
        #endif
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: PulseTheme.Gradients.liveSession, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let engine = session.engine, !engine.isFinished {
                VStack(spacing: 0) {
                    header(engine)
                    PulseStrengthTabs(tabs: [Tab.live, Tab.exercises], selection: $tab, centred: true) {
                        $0 == .live ? String(localized: "Live session") : String(localized: "Exercises")
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    switch tab {
                    case .live:
                        liveTab(engine)
                    case .exercises:
                        PulseStrengthExercisesTab(onDetails: { details = PulseStrengthExerciseTarget(name: $0) },
                                                  onAddExercise: { addingExercise = true })
                    }
                    setButton(engine)
                        .padding(.horizontal, 39)
                        .padding(.top, 10)
                }
            } else {
                emptyState
            }
        }
        .environment(\.colorScheme, .dark)
        // Opened as a route it sits in a navigation stack; its header is its own.
        .toolbar(.hidden, for: .navigationBar)
        // What each exercise lifted last time (the grey numbers' middle layer), again when the exercises change.
        .task(id: session.engine?.plan.map(\.exercise)) { await session.loadLastSession(from: repo) }
        .sheet(isPresented: $showsFinish) {
            PulseStrengthFinishSheet(onDone: { dismiss() })
        }
        .sheet(isPresented: $addingExercise) {
            LiftSessionExerciseSheet { name, primary, secondaries in
                session.addExercise(name, primaryMuscle: primary, secondaryMuscles: secondaries)
            }
        }
        .sheet(item: $details) { target in
            NavigationStack {
                PulseStrengthExerciseDetailsView(exercise: target.name)
                    .environment(\.pulseModalRoot, true)
            }
        }
        .confirmationDialog(String(localized: "Discard this workout?"), isPresented: $confirmingDiscard,
                            titleVisibility: .visible) {
            Button(String(localized: "Discard"), role: .destructive) {
                session.discard()
                dismiss()
            }
            Button(String(localized: "Keep going"), role: .cancel) { }
        } message: {
            Text(String(localized: "\(session.engine?.completedWorkingSets ?? 0) recorded sets will be thrown away. Nothing is saved and no workout is created."))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: stageKey)
        #if DEBUG
        .task {
            // `--pulse-strength-finish`: open FINISH WORKOUT, for captures.
            if CommandLine.arguments.contains("--pulse-strength-finish") {
                try? await Task.sleep(nanoseconds: 600_000_000)
                showsFinish = true
            }
        }
        #endif
    }

    /// Changes whenever the session moves to another stage (a set started or ended).
    private var stageKey: String {
        guard let engine = session.engine else { return "none" }
        return "\(engine.stage)"
    }

    // MARK: Header

    private func header(_ engine: LiftSessionEngine) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Menu {
                // Back to the screen it was opened over, where the session runs on: the Strength Trainer's
                // WORKOUT IN PROGRESS card, or the session bar (shown once no modal covers the shell).
                Button { dismiss() } label: {
                    Label(String(localized: "Minimise"), systemImage: "chevron.down")
                }
                Button { session.undo() } label: {
                    Label(String(localized: "Undo last step"), systemImage: "arrow.uturn.backward")
                }
                .disabled(!engine.canUndo)
                Button { showsFinish = true } label: {
                    Label(String(localized: "Finish workout"), systemImage: "flag.checkered")
                }
                Button(role: .destructive) { confirmingDiscard = true } label: {
                    Label(String(localized: "Discard workout"), systemImage: "trash")
                }
            } label: {
                PulseStrengthMoreGlyph()
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Workout options"))
            Spacer(minLength: 8)
            VStack(spacing: 3) {
                Text(session.programName ?? String(localized: "Session"))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)
                PulseStrengthClockText(padded: true, hours: true) { $0 - engine.startTs }
                    .font(PulseType.numeral(13))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .accessibilityLabel(String(localized: "Elapsed"))
            }
            Spacer(minLength: 8)
            Button { addingExercise = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(engine.plan.count >= LiftSessionEngine.maxExercises)
            .accessibilityLabel(String(localized: "Add an exercise"))
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 4)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: LIVE SESSION

    private func liveTab(_ engine: LiftSessionEngine) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                PulseStrengthStageRing(stage: PulseStrengthStage(engine: engine, doneVolume: doneVolume(),
                                                                 unit: LiftFormat.weightUnit(unitSystem)))
                    .padding(.top, 45)
                PulseStrengthHeartRateBlock()
                    .padding(.top, 56)
                exerciseCard(engine)
                    .padding(.top, 24)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// The volume this session has lifted, as finishing would save it (`setsToSave`, its grey numbers
    /// filling the blanks) and as PROGRESS counts it (`LiftMetrics.volumeLoadKg`): working sets only.
    private func doneVolume() -> String? {
        let rows = session.setsToSave(completingUnfinished: false).map { set in
            LiftSetRow(id: "", deviceId: "", sessionId: "", ord: 0, exercise: "", primaryMuscle: nil,
                       secondaryMuscles: [], setIndex: set.slot.setIndex, weightKg: set.weightKg, reps: set.reps,
                       rpe: nil, isWarmup: set.isWarmup, startTs: nil, endTs: nil, restSec: nil, note: nil)
        }
        return LiftMetrics.volumeLoadKg(rows).map { StrengthFormat.volume($0, unitSystem) }
    }

    /// The set the card describes: the one being worked, else the one coming next (NEXT).
    private func cardSlot(_ engine: LiftSessionEngine) -> (slot: LiftSlot, next: Bool)? {
        switch engine.stage {
        case .working(let slot): return (slot, false)
        case .resting(let slot, _):
            if let upcoming = engine.upcomingSlot { return (upcoming, true) }
            return (slot, false)
        case .warmup:
            return engine.upcomingSlot.map { ($0, true) }
        case .finished:
            return nil
        }
    }

    @ViewBuilder
    private func exerciseCard(_ engine: LiftSessionEngine) -> some View {
        if let shown = cardSlot(engine), let item = engine.planItem(for: shown.slot) {
            let figures = numbers(for: shown.slot)
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    PulseStrengthThumbnail(width: 72, height: 50)
                    VStack(alignment: .leading, spacing: 3) {
                        if shown.next {
                            Text(String(localized: "Next"))
                                .pulseText(.label)
                                .foregroundStyle(PulseTheme.Activity.strengthActiveTimer)
                        }
                        Text(item.exercise)
                            .pulseText(.rowText)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    PulseInfoButton(accessibilityLabel: String(localized: "Exercise details")) {
                        details = PulseStrengthExerciseTarget(name: item.exercise)
                    }
                }
                .padding(.leading, 5)
                .padding(.trailing, 2)
                .padding(.vertical, 5)
                PulseDivider()
                HStack(spacing: 0) {
                    statColumn(value: "\(shown.slot.setIndex)", suffix: "/\(item.targetSets)",
                               label: String(localized: "Set"), lit: shown.next)
                    statDivider
                    statColumn(value: figures.reps ?? "–", suffix: nil, label: String(localized: "Reps"), lit: false)
                    statDivider
                    statColumn(value: figures.weight ?? "–", suffix: nil, label: LiftFormat.weightUnit(unitSystem),
                               lit: false)
                }
                .padding(.vertical, 10)
            }
            .background(RoundedRectangle(cornerRadius: PulseStrengthMetrics.exerciseCardRadius, style: .circular)
                .fill(PulseStrengthColors.exerciseCard))
            .accessibilityElement(children: .contain)
        }
    }

    private var statDivider: some View {
        Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 34)
    }

    private func statColumn(value: String, suffix: String?, label: String, lit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(PulseType.font(.tileValue))
                    .foregroundStyle(lit ? PulseTheme.Activity.strengthActiveTimer : PulseTheme.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(PulseType.font(.tileValue))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            Text(label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .accessibilityElement(children: .combine)
    }

    /// A set's reps and weight as the Lift Log's surfaces show them: numbers typed in advance, else the
    /// set's own or grey numbers (`LiftSessionController.setNumbers`, split into its two figures).
    private func numbers(for slot: LiftSlot) -> (reps: String?, weight: String?) {
        let grey = session.values(of: slot)
        let typed = session.pendingValues[slot]
        let reps = (typed?.reps ?? grey.reps).map(String.init)
        let weight = (typed?.weightKg ?? grey.weightKg).map { StrengthFormat.weight($0, unitSystem) }
        return (reps, weight)
    }

    // MARK: The set button

    @ViewBuilder
    private func setButton(_ engine: LiftSessionEngine) -> some View {
        switch engine.stage {
        case .working:
            Button(String(localized: "End set")) { session.advance() }
                .buttonStyle(PulseStrengthSetButtonStyle(kind: .end))
        case .resting where engine.allCompleted:
            Button(String(localized: "Finish workout")) { showsFinish = true }
                .buttonStyle(PulseStrengthSetButtonStyle(kind: .finish))
        case .warmup, .resting:
            Button(String(localized: "Start set")) { session.advance() }
                .buttonStyle(PulseStrengthSetButtonStyle(kind: .start))
        case .finished:
            EmptyView()
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityHidden(true)
            Text(String(localized: "No workout running"))
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Button(String(localized: "Close")) { dismiss() }
                .buttonStyle(.pulseOutlineWhite)
                .frame(maxWidth: 220)
        }
        .padding(32)
    }
}

/// The exercise whose details sheet is open.
struct PulseStrengthExerciseTarget: Identifiable {
    let name: String
    var id: String { name }
}

// MARK: - The stage ring

/// What the ring shows, resolved from the engine's stage. The session's own elapsed time is the header's
/// alone; the ring only ever shows the stage's own figure (one readout per fact).
enum PulseStrengthStage: Equatable {
    /// Before the first set: no set or rest is being timed yet.
    case warmup
    /// A set is running: its time, counting up, green.
    case active(since: Int)
    /// Resting: the time left, counting down; the rim empties as it runs.
    case rest(start: Int, endsAt: Int)
    /// Every set is done: the volume the session lifted (`volume` nil when no set had a weight).
    case done(volume: String?, unit: String, sets: Int)

    init(engine: LiftSessionEngine, doneVolume: @autoclosure () -> String?, unit: String) {
        switch engine.stage {
        case .warmup: self = .warmup
        case .working: self = .active(since: engine.stageStartedAt)
        case .resting(_, let endsAt):
            self = engine.allCompleted
                ? .done(volume: doneVolume(), unit: unit, sets: engine.completedWorkingSets)
                : .rest(start: engine.stageStartedAt, endsAt: endsAt)
        case .finished: self = .done(volume: doneVolume(), unit: unit, sets: engine.completedWorkingSets)
        }
    }

    /// Whether the ring's figure is a clock that moves.
    var ticks: Bool {
        switch self {
        case .active, .rest: return true
        case .warmup, .done: return false
        }
    }
}

/// The REST / ACTIVE ring (g07a/b), 240 pt across: a 15 pt band with a 3 pt rim on its outer edge.
///   - REST: a dim band (white 8%) and a grey rim lit from the bottom-left; the rim is the countdown,
///     emptying as the rest runs while the band stays whole.
///   - ACTIVE: the rim runs blue at 12 o'clock, bright green from 3 to 6, navy at 9, over a band tinted in
///     the same colours, with a soft glow.
/// Inside, the stage's word and its figure (44 pt). Only the clock redraws, once a second, while on screen.
struct PulseStrengthStageRing: View {
    let stage: PulseStrengthStage

    private static let diameter: CGFloat = 240
    /// g07a's band runs from r ≈ 105 to the rim at 120.
    private static let band: CGFloat = 15
    private static let rim: CGFloat = 3

    /// The rim's colours from 12 o'clock, clockwise, for a circle drawn unrotated.
    private static func rimGradient(_ gradient: Gradient) -> AngularGradient {
        AngularGradient(gradient: gradient, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }

    var body: some View {
        ZStack {
            band
            if case .active = stage {
                activeRim
            }
            if stage.ticks {
                TimelineView(.periodic(from: Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970)), by: 1)) { context in
                    timed(now: Int(context.date.timeIntervalSince1970))
                }
            } else {
                still
            }
        }
        .frame(width: Self.diameter + 24, height: Self.diameter + 24)
    }

    // MARK: Ring

    /// The band: the rim's own colours, dimmed, so it is lit where the rim is (g07a: #2A2D32 under the
    /// top-right of the rim, #3D4144 under its bright bottom-left; g07b: navy on the left, green on the
    /// right). It stays whole while the REST rim counts down.
    private var band: some View {
        let size = Self.diameter - Self.band
        return Group {
            switch stage {
            case .active:
                Circle()
                    .stroke(Self.rimGradient(PulseStrengthColors.activeRim), lineWidth: Self.band)
                    .opacity(PulseStrengthColors.activeBandOpacity)
            case .warmup, .rest, .done:
                Circle()
                    .stroke(Self.rimGradient(PulseStrengthColors.restRim), lineWidth: Self.band)
                    .opacity(PulseStrengthColors.restBandOpacity)
            }
        }
        .frame(width: size, height: size)
    }

    /// The ACTIVE rim and its glow (static: the clock is the only thing that moves).
    private var activeRim: some View {
        let size = Self.diameter - Self.rim
        let gradient = Self.rimGradient(PulseStrengthColors.activeRim)
        return ZStack {
            Circle()
                .stroke(gradient, lineWidth: 6)
                .blur(radius: 7)
                .opacity(0.7)
            Circle()
                .stroke(gradient, lineWidth: Self.rim)
        }
        .frame(width: size, height: size)
    }

    /// The REST rim, with a faint halo: the countdown's remaining fraction, from 12 o'clock clockwise.
    /// The shape is turned a quarter for the trim to start at 12, so its gradient starts a quarter back.
    private func restRim(_ fraction: CGFloat) -> some View {
        let size = Self.diameter - Self.rim
        let arc = Circle().trim(from: 0, to: max(0, min(1, fraction)))
        let gradient = AngularGradient(gradient: PulseStrengthColors.restRim, center: .center,
                                       startAngle: .degrees(0), endAngle: .degrees(360))
        return ZStack {
            arc
                .stroke(gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .blur(radius: 4)
                .opacity(0.45)
            arc
                .stroke(gradient, style: StrokeStyle(lineWidth: Self.rim, lineCap: .round))
        }
        .rotationEffect(.degrees(-90))
        .frame(width: size, height: size)
    }

    // MARK: Figures

    @ViewBuilder
    private func timed(now: Int) -> some View {
        switch stage {
        case .active(let since):
            let clock = PulseStrengthClock.text(now - since, padded: true)
            figure(label: String(localized: "Active"), value: clock, unit: nil,
                   color: PulseTheme.Activity.strengthActiveTimer,
                   accessibility: String(localized: "Set active, \(clock)"))
        case .rest(let start, let endsAt):
            let left = max(0, endsAt - now)
            let clock = PulseStrengthClock.text(left, padded: true)
            ZStack {
                restRim(CGFloat(left) / CGFloat(max(1, endsAt - start)))
                figure(label: left > 0 ? String(localized: "Rest") : String(localized: "Ready"), value: clock,
                       unit: nil, color: PulseTheme.textPrimary,
                       accessibility: left > 0 ? String(localized: "Rest, \(clock) left")
                                               : String(localized: "Rest over, ready for the next set"))
            }
        case .warmup, .done:
            still
        }
    }

    @ViewBuilder
    private var still: some View {
        switch stage {
        case .warmup:
            // Nothing is being timed before the first set; the session's time is in the header.
            figure(label: String(localized: "Warm-up"), value: "--:--", unit: nil, color: PulseTheme.textDisabled,
                   labelColor: PulseTheme.textPrimary,
                   accessibility: String(localized: "Warm-up. Start a set to time it."))
        case .done(let volume, let unit, let sets):
            if let volume {
                figure(label: String(localized: "All sets done"), value: volume, unit: unit,
                       color: PulseTheme.textPrimary,
                       accessibility: String(localized: "All sets done, \(volume) \(unit) lifted"))
            } else {
                figure(label: String(localized: "All sets done"), value: "\(sets)",
                       unit: sets == 1 ? String(localized: "set") : String(localized: "sets"),
                       color: PulseTheme.textPrimary,
                       accessibility: String(localized: "All sets done, \(sets) sets"))
            }
        case .active, .rest:
            EmptyView()
        }
    }

    private func figure(label: String, value: String, unit: String?, color: Color,
                        labelColor: Color? = nil, accessibility: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .pulseText(.navTitle)
                .foregroundStyle(labelColor ?? color)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(PulseType.font(.strengthTimer))
                    .foregroundStyle(color)
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .pulseText(.tileUnit)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: Self.diameter - Self.band * 2 - 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }
}

/// The live clocks' format: "01:15", "00:38:26" (WHOOP pads; under an hour the session header keeps its
/// hours when `hours`).
enum PulseStrengthClock {
    static func text(_ seconds: Int, padded: Bool, hours: Bool = false) -> String {
        let s = max(0, seconds)
        let h = s / 3_600, m = (s % 3_600) / 60, sec = s % 60
        if hours || h > 0 {
            return String(format: padded ? "%02d:%02d:%02d" : "%d:%02d:%02d", h, m, sec)
        }
        return String(format: padded ? "%02d:%02d" : "%d:%02d", m, sec)
    }
}

/// A clock that ticks by itself only while on screen (the Lift Log's `LiftRunningClock`, in this format).
struct PulseStrengthClockText: View {
    var padded = true
    var hours = false
    let seconds: (Int) -> Int

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970)), by: 1)) { context in
            Text(PulseStrengthClock.text(seconds(Int(context.date.timeIntervalSince1970)), padded: padded, hours: hours))
                .monospacedDigit()
        }
    }
}

// MARK: - Heart rate

/// HEART RATE, the live value and the six-zone bar. Its own leaf: it is the only view here that watches
/// the app model's heart rate, so a beat redraws this block and nothing else. The value is the app's
/// smoothed `bpm`, shown only while the strap is connected (a frozen number reads as live and is not); the
/// zone is the profile's zone set, the one Strain is scored in.
struct PulseStrengthHeartRateBlock: View {
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var profile: ProfileStore
    /// The link's state, taken from its one publisher: observing all of `LiveState` would redraw this
    /// block on every log line (the cost the Lift Log's readouts were split out to avoid).
    @State private var connected = false

    var body: some View {
        let bpm = connected ? app.bpm : nil
        let zones = profile.hrZoneSet
        let zone = bpm.map { zones.zoneNumber(forBPM: Double($0)) }
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Heart rate"))
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textTertiary)
            Text(bpm.map(String.init) ?? "--")
                .font(PulseType.font(.largeValue))
                .foregroundStyle(bpm == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                .pulseNumericTransition()
                .accessibilityLabel(bpm.map { String(localized: "\($0) beats per minute") } ?? String(localized: "No reading"))
            PulseStrengthZoneBar(zone: zone, position: Self.position(bpm: bpm, zone: zone, zones: zones))
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(app.live.$connected) { connected = $0 }
    }

    /// Where `bpm` sits inside its zone, 0…1 (the middle of Zone 0's span below Zone 1).
    static func position(bpm: Int?, zone: Int?, zones: HRZoneSet) -> Double {
        guard let bpm, let zone else { return 0.5 }
        let value = Double(bpm)
        if zone == 0 {
            guard let first = zones.zones.first, first.lower > 0 else { return 0.5 }
            let floor = first.lower * 0.5
            return min(1, max(0, (value - floor) / (first.lower - floor)))
        }
        guard let band = zones.zones.first(where: { $0.number == zone }), band.upper > band.lower else { return 0.5 }
        return min(1, max(0, (value - band.lower) / (band.upper - band.lower)))
    }
}
#endif
