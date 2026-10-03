#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation
import StrandAnalytics
import WhoopStore
import WhoopProtocol

/// Start Activity (WHOOP_UI_SPEC §3.8), a full-screen modal: the pre-start screen (the activity list
/// dropping from the header, Track Route, the live heart-rate circle, the Strain Target panel), then the
/// live session pager, then Activity Details for what was saved. While a workout is already running it
/// opens straight on the live session (the ＋ menu's RESUME ACTIVITY).
///
/// It drives the app's one workout engine (`AppModel.startWorkout` / `toggleWorkoutPause` / `endWorkout` /
/// `discardWorkout`, its live heart rate and Strain, `GpsWorkoutRecorder`): nothing here records, scores
/// or saves on its own.
struct PulseStartActivityView: View {
    /// Existing entry points (the ＋ menu, Home's START ACTIVITY, the quick action) open this flow instead
    /// of the classic Workouts screen.
    static let isRebuilt = true

    @Environment(\.dismiss) private var dismiss
    /// Whether the engine has a session running; nil until the probe has looked.
    @State private var isLive: Bool?
    /// The row End & Save produced and the session's own heart rate, shown as Activity Details in place.
    @State private var finished: Finished?
    @State private var nothingSaved = false

    private struct Finished {
        let row: WorkoutRow
        /// The samples the saved Strain was scored from: the details draw these until the strap's history
        /// covers the session.
        let samples: [HRSample]
    }

    var body: some View {
        ZStack {
            if let finished {
                PulseActivityDetailView(workout: PulseWorkoutRoute(row: finished.row), liveSamples: finished.samples)
            } else if isLive == true {
                PulseLiveSessionView(onFinish: { saved, samples in
                    if let saved { finished = Finished(row: saved, samples: samples) } else { nothingSaved = true }
                }, onDiscard: { dismiss() })
                .transition(.opacity)
            } else if isLive == false {
                PulsePreStartView()
                    .transition(.opacity)
            }
        }
        .background(PulseLiveSessionProbe(isLive: $isLive))
        #if DEBUG
        .background(PulseActivityDemoStarter())
        #endif
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .dark)
        .fullScreenCover(isPresented: $nothingSaved) {
            PulseDialogCard(title: String(localized: "Nothing was saved"),
                            message: String(localized: "A session under a minute, or with no heart rate and no route, isn't kept."),
                            primaryTitle: String(localized: "Close"),
                            primary: { nothingSaved = false; dismiss() },
                            onClose: { nothingSaved = false; dismiss() })
                .presentationBackground(.clear)
        }
    }
}

/// Watches the engine for a running session without making the whole flow observe `AppModel`, which
/// publishes every heart-rate tick.
private struct PulseLiveSessionProbe: View {
    @Binding var isLive: Bool?
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Color.clear
            .onChange(of: app.activeWorkout != nil, initial: true) { _, live in
                if isLive != live { isLive = live }
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG
/// `--activity-demo-live`: starts the demo session once the flow is on screen (DEBUG only).
private struct PulseActivityDemoStarter: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Color.clear
            .onAppear {
                if PulseActivityDebug.has("--activity-reset"), app.activeWorkout != nil { app.discardWorkout() }
                PulseActivityDebug.startDemoLiveIfRequested(app: app, sport: PulseActivityDebug.sport ?? "Running")
            }
            .accessibilityHidden(true)
    }
}
#endif

// MARK: - Session preferences

/// What the pre-start screen chose for the session it starts, kept on this iPhone by the session's start
/// so a relaunch mid-session resumes with the same Strain Target. (The Track Route choice is the engine's
/// own: `AppModel.startWorkout(sport:trackRoute:)` keeps it with the session.)
enum PulseActivitySessionStore {
    static let strainTargetOnKey = "pulse.activity.strainTargetOn"
    private static let sessionKey = "pulse.activity.session"

    struct Session: Codable, Equatable {
        let startSec: Int
        /// The Activity Strain the session aims at, 0–21, when Strain Target was on.
        let target: Double?
    }

    static func save(_ session: Session, defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(session), forKey: sessionKey)
    }

    static func session(startSec: Int, defaults: UserDefaults = .standard) -> Session? {
        guard let data = defaults.data(forKey: sessionKey),
              let s = try? JSONDecoder().decode(Session.self, from: data), s.startSec == startSec else { return nil }
        return s
    }

    static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: sessionKey) }
}

// MARK: - Pre-start (§3.8)

/// The pre-start screen: the translucent header (✕ · sport glyph · NAME · ⌄), Track Route for GPS sports,
/// the dimmed map (Track Route on, location allowed) or a neutral backdrop with halos, the live heart-rate
/// circle, and the Strain Target panel with START ACTIVITY (strain sports) or a white outline START
/// ACTIVITY (recovery sports).
struct PulsePreStartView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PulseActivitySessionStore.strainTargetOnKey) private var targetOn = true

    @State private var kind: PulseActivityKind = PulsePreStartView.initialKind
    @State private var pickerOpen = false
    @State private var trackRoute = true
    @State private var snapshot: StartActivitySnapshot?
    /// A target the wearer dragged on the ring (0–21); nil keeps the recommendation.
    @State private var customTarget: Double?
    @State private var panelExpanded = false
    @State private var locationAllowed = PulsePreStartView.locationAuthorized

    private static var initialKind: PulseActivityKind {
        #if DEBUG
        if let sport = PulseActivityDebug.sport { return PulseActivityCatalog.kind(named: sport) }
        #endif
        if let recent = PulseActivityCatalog.recent(limit: 1).first, recent.category != .sleep { return recent }
        return PulseActivityCatalog.kind(named: "Running")
    }

    private static var locationAuthorized: Bool {
        let status = CLLocationManager().authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    private var isRecovery: Bool { kind.category == .recovery }
    private var showsMap: Bool { kind.isDistanceSport && trackRoute && locationAllowed }

    /// The Activity Strain the session aims at: the dragged one, else the recommendation; none once today
    /// has reached its target (a 0.0 target would park the live ring's knob at 12 o'clock).
    private var activityTarget: Double? {
        guard targetOn, let snapshot else { return nil }
        if let customTarget { return customTarget }
        guard !snapshot.targetReached else { return nil }
        return snapshot.recommendedActivityStrain
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let headerHeight = safeTop + 71
            let panelHeight = isRecovery ? 0 : 164 + safeBottom
            let circleCentre = headerHeight + (geo.size.height + safeTop + safeBottom - headerHeight
                                               - (isRecovery ? 120 + safeBottom : panelHeight)) / 2
            ZStack(alignment: .top) {
                backdrop(centreY: circleCentre)
                    .ignoresSafeArea()

                PulsePreStartHeartCircle(isRecovery: isRecovery)
                    .position(x: geo.size.width / 2, y: circleCentre - safeTop)

                if kind.isDistanceSport {
                    trackRouteRow
                        .padding(.top, headerHeight - safeTop + 14)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    if isRecovery {
                        recoveryStart
                            .padding(.bottom, max(24, safeBottom + 6))
                    } else {
                        PulseStrainTargetPanel(
                            snapshot: snapshot, targetOn: $targetOn, customTarget: $customTarget,
                            expanded: $panelExpanded, collapsedHeight: panelHeight,
                            expandedHeight: geo.size.height + safeBottom - (headerHeight - safeTop) + 4,
                            safeBottom: safeBottom, onStart: { start(app: $0) })
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                if pickerOpen {
                    picker
                        .padding(.top, headerHeight - safeTop)
                        .transition(PulseMotion.transition(.top, reduceMotion: reduceMotion))
                        .zIndex(1)
                }

                header(height: headerHeight, safeTop: safeTop)
                    .zIndex(2)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.menu, reduceMotion: reduceMotion), value: pickerOpen)
        .background(PulseTheme.pageBottom.ignoresSafeArea())
        .task(id: model.healthKey) {
            if let s = await model.build(dayOffset: 0, { builder, r in await builder.startActivity(r) }) {
                snapshot = s
            }
        }
        .onChange(of: kind) { _, _ in customTarget = nil }
        #if DEBUG
        .onAppear {
            if PulseActivityDebug.has("--activity-picker-open") { pickerOpen = true }
            if PulseActivityDebug.panel != nil { panelExpanded = true }
            if let value = PulseActivityDebug.value("--activity-target").flatMap(Double.init) { customTarget = value }
        }
        #endif
    }

    // MARK: Header

    /// ✕ · glyph · NAME · ⌄. While the list is open the ✕ goes and the name moves to the left edge, as
    /// completeness-critic/05 draws it: ⌃ is then the only way out of the list.
    private func header(height: CGFloat, safeTop: CGFloat) -> some View {
        HStack(spacing: 0) {
            if !pickerOpen {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: PulseActivityStyle.Glyph.close, weight: .light))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Close"))
            }
            Button { pickerOpen.toggle() } label: {
                HStack(spacing: 0) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: PulseActivityStyle.Glyph.preStartHeader, weight: .regular))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(width: 36)
                        .padding(.leading, pickerOpen ? 8 : 14)
                        .accessibilityHidden(true)
                    Text(kind.displayName)
                        .pulseText(.menuLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.leading, 18)
                    Spacer(minLength: 8)
                    Image(systemName: pickerOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: PulseActivityStyle.Glyph.headerChevron, weight: .semibold))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Activity, \(kind.displayName)"))
            .accessibilityHint(pickerOpen ? String(localized: "Closes the activity list")
                                          : String(localized: "Opens the activity list"))
        }
        .padding(.horizontal, 12)
        .padding(.top, safeTop + 12)
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.Activity.preStartHeader.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if pickerOpen { Rectangle().fill(PulseTheme.divider).frame(height: 1) }
        }
        .ignoresSafeArea(edges: .top)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: Backdrop

    @ViewBuilder
    private func backdrop(centreY: CGFloat) -> some View {
        if showsMap {
            Map(initialPosition: .userLocation(fallback: .automatic), interactionModes: []) {
                UserAnnotation()
            }
            .mapStyle(.standard)
            // Apple's own dark map, as a01 draws it, with nothing laid over it.
            .environment(\.colorScheme, .dark)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            // ZENO draws no strap render [Z]: a neutral gradient with concentric halos round the circle.
            ZStack {
                LinearGradient(gradient: PulseTheme.Activity.preStartBackdrop, startPoint: .top, endPoint: .bottom)
                GeometryReader { geo in
                    // The outer of the two halos (a07); the circle draws the inner one.
                    Circle().fill(PulseActivityStyle.preStartOuterHalo).frame(width: 364, height: 364)
                        .position(x: geo.size.width / 2, y: centreY)
                }
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: Track Route

    private var trackRouteRow: some View {
        HStack(spacing: 10) {
            Text(String(localized: "Track Route"))
                .activityText(.trackRoute)
                .foregroundStyle(PulseTheme.textSecondary)
            PulseLightToggle(isOn: $trackRoute, onKnob: PulseTheme.Activity.startCapsule,
                             offKnob: PulseTheme.textPrimary, track: PulseActivityStyle.toggleTrackOnDark)
                .accessibilityLabel(String(localized: "Track route"))
        }
        .frame(minHeight: PulseTheme.Layout.minTapTarget)
    }

    // MARK: Recovery start

    private var recoveryStart: some View {
        PulseStartActivityButton(style: .outline) { start(app: $0) }
            .padding(.horizontal, 54)
    }

    // MARK: Picker (completeness-critic/05)

    private var picker: some View {
        PulseActivityPickerList(style: .borderless, tabs: [.all, .strain, .recovery], selected: kind.name) { picked in
            kind = picked
            trackRoute = picked.isDistanceSport
            pickerOpen = false
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulseActivityStyle.pickerBackdrop.ignoresSafeArea())
    }

    // MARK: Start

    /// Starts the engine's session for the chosen activity and keeps this screen's choices for it.
    private func start(app: AppModel) {
        // A recovery activity has no Strain Target panel, so it starts with no target.
        PulseStartEngine.start(app: app, sport: kind.name, target: isRecovery ? nil : activityTarget,
                               trackRoute: !kind.isDistanceSport || trackRoute)
    }
}

/// The one place the flow starts a session: the engine's own start (with the Track Route choice, so a
/// route switched off is never recorded), then the screen's Strain Target for it.
@MainActor
enum PulseStartEngine {
    static func start(app: AppModel, sport: String, target: Double?, trackRoute: Bool) {
        guard app.activeWorkout == nil else { return }
        RecentSportsPrefs.recordSelection(sport)
        app.startWorkout(sport: sport, trackRoute: trackRoute)
        guard let started = app.activeWorkout?.start else { return }
        PulseActivitySessionStore.save(.init(startSec: Int(started.timeIntervalSince1970), target: target))
    }
}

// MARK: - Heart-rate circle

/// The live heart rate in its circle (§2.5 "Pre-start HR circle"): a 181 pt disc (strain blue, or the
/// recovery blue) inside a translucent halo, a heart, the bpm and the strap's battery. Its own leaf: it
/// observes the live feed, which ticks every second.
struct PulsePreStartHeartCircle: View {
    let isRecovery: Bool
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var live: LiveState

    var body: some View {
        let fill = isRecovery ? PulseTheme.Activity.preStartCircleRecovery : PulseTheme.Activity.preStartCircleStrain
        ZStack {
            Circle()
                .fill((isRecovery ? PulseTheme.Activity.preStartHaloRecovery : PulseTheme.Activity.preStartHaloStrain)
                    .opacity(0.7))
                .frame(width: 240, height: 240)
            Circle()
                .fill(fill)
                .frame(width: 181, height: 181)
            VStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: PulseActivityStyle.Glyph.circleHeart, weight: .regular))
                Text(app.bpm.map { "\($0)" } ?? "--")
                    .font(PulseType.font(.preStartHR))
                    .monospacedDigit()
                    .contentTransition(.identity)
                    .padding(.vertical, -6)
                // Fixed sizes: everything here sits inside the fixed 181 pt circle.
                if let pct = live.batteryPct, live.connected {
                    HStack(spacing: 5) {
                        Image(systemName: Self.batterySymbol(pct))
                            .font(.system(size: PulseActivityStyle.Glyph.circleBattery, weight: .regular))
                        Text("\(Int(pct.rounded()))%")
                            .activityText(.circleCaption)
                    }
                    .foregroundStyle(PulseActivityStyle.circleInkMuted)
                } else {
                    Text(String(localized: "No strap"))
                        .activityText(.circleCaption)
                        .foregroundStyle(PulseActivityStyle.circleInkMuted)
                }
            }
            .foregroundStyle(PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart rate"))
        .accessibilityValue(app.bpm.map { String(localized: "\($0) beats per minute") } ?? String(localized: "No reading"))
        // The circle shows live heart rate, which a WHOOP 5/MG streams only on request: arm it while the
        // circle is on screen (ref-counted by the engine, so the live session's own arm balances it).
        .onAppear { app.startRealtimeHR() }
        .onDisappear { app.stopRealtimeHR() }
    }

    private static func batterySymbol(_ pct: Double) -> String {
        switch pct {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// MARK: - Buttons and the light toggle

/// START ACTIVITY: the blue capsule on the white panel (§2.6 item 16f), or a white outline on the dark
/// recovery screen.
struct PulseStartActivityButton: View {
    enum Style { case filled, outline }
    let style: Style
    /// Handed the engine, so only this button observes it.
    let action: (AppModel) -> Void
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Button {
            action(app)
        } label: {
            Text(String(localized: "Start activity"))
                .pulseText(.capsuleLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 49)
                .background {
                    if style == .filled {
                        Capsule(style: .circular).fill(PulseTheme.Activity.startCapsule)
                    } else {
                        Capsule(style: .circular).strokeBorder(PulseTheme.textPrimary, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Starts recording heart rate for this activity"))
    }
}

/// The panel's switch (§2.1 activity-flow tokens): a light track with a black knob when on. The white off
/// knob takes a hairline rim against the light track, not a drop shadow (DR §9).
struct PulseLightToggle: View {
    @Binding var isOn: Bool
    var onKnob: Color = PulseTheme.Activity.panelToggleKnob
    var offKnob: Color = PulseActivityStyle.mapMarker
    var track: Color = PulseTheme.Activity.panelGrabber
    var disabled = false

    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule(style: .circular).fill(track).frame(width: 52, height: 30)
                Circle()
                    .fill(isOn ? onKnob : offKnob)
                    .overlay(Circle().strokeBorder(isOn ? Color.clear : PulseActivityStyle.panelKnobRim, lineWidth: 1))
                    .frame(width: 30, height: 30)
            }
            .frame(width: 52, height: 30)
            .opacity(disabled ? 0.4 : 1)
            .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? String(localized: "On") : String(localized: "Off"))
    }
}
#endif
