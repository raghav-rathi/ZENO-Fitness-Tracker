#if os(iOS)
import SwiftUI
import StrandDesign

/// Onboarding / first run (WHOOP_UI_SPEC §3.38), restyled from the classic `OnboardingWizard` and
/// `TermsGateView` onto WHOOP's step template. Owned by group "onboarding-strength".
///
/// The flow, in ZENO's order (the terms come first, because ZENO must gate before it reads health data):
///
///     Landing → Before You Use ZENO → Privacy and Terms of Use
///       → [Put On → Wake Up → Check for Pairing Mode → SEARCHING / SELECT / CONNECTING / CONNECTED]
///       → Welcome (name) → Where Do You Live? → Connect To Apple Health → What's Your Birthday?
///       → Choose a Gender → Height and Weight → Bring Your History → Turn On Notifications
///       → Welcome to ZENO → What to Expect Next → Home
///
/// Two ways in:
///   - the FIRST RUN, from the app root while the Pulse shell is on (`init(needsTerms:needsSetup:…)`): the
///     same gates as the classic pair, on the same keys. `needsTerms` alone (an existing user whose terms
///     changed) shows only the two legal steps; accepting clears the gate exactly as `TermsGateView` did.
///   - the `.onboarding` route (`init()`), a replay from inside the app: the legal steps only while the
///     terms are not accepted, and finishing simply closes it.
///
/// The classic Appearance step is dropped (Pulse is dark only, §3.38); its other steps are all here.
struct PulseOnboardingView: View {
    /// Rebuilt: with the Pulse shell on, first launch shows this flow instead of the classic wizard and
    /// terms gate (`iOSRootView`). The `.onboarding` route has no classic fallback either way.
    static let isRebuilt = true

    /// What the first run must still do, and how it reports back to the app root.
    struct FirstRun {
        let onAcceptTerms: () -> Void
        let onFinished: () -> Void
    }

    private let firstRun: FirstRun?

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("noop.acceptedTermsVersion") private var acceptedTerms = ""

    /// Captured once, when the flow first appears: accepting the terms mid-flow must not pull the step
    /// the wearer is on out of the sequence.
    @State private var includesTerms: Bool
    @State private var includesSetup: Bool
    @State private var step: PulseOnboardingStep
    @State private var forward = true
    /// Landing's choice: pair a strap now, or continue without one.
    @State private var pairsStrap = true
    @State private var family: WhoopModel = .persisted
    @StateObject private var pairing = PulseStrapPairing()

    /// The `.onboarding` route: a replay from inside the app.
    init() {
        firstRun = nil
        let accepted = UserDefaults.standard.string(forKey: "noop.acceptedTermsVersion") == Terms.currentVersion
        _includesTerms = State(initialValue: !accepted)
        _includesSetup = State(initialValue: true)
        _step = State(initialValue: Self.initialStep(includesTerms: !accepted, includesSetup: true))
    }

    /// The first run, from the app root.
    /// - Parameters:
    ///   - needsTerms: the current `Terms.currentVersion` has not been accepted.
    ///   - needsSetup: onboarding has not been completed (`noop.onboarded`).
    ///   - onAcceptTerms: store the accepted version (the app root's own write, so its launch-sheet
    ///     bookkeeping stays where it was).
    ///   - onFinished: mark onboarding complete.
    init(needsTerms: Bool, needsSetup: Bool, onAcceptTerms: @escaping () -> Void, onFinished: @escaping () -> Void) {
        firstRun = FirstRun(onAcceptTerms: onAcceptTerms, onFinished: onFinished)
        _includesTerms = State(initialValue: needsTerms)
        _includesSetup = State(initialValue: needsSetup)
        _step = State(initialValue: Self.initialStep(includesTerms: needsTerms, includesSetup: needsSetup))
    }

    private static func initialStep(includesTerms: Bool, includesSetup: Bool) -> PulseOnboardingStep {
        #if DEBUG
        if let debug = PulseOnboardingStep.debugLaunchStep { return debug }
        #endif
        return includesSetup ? .landing : .termsPoints
    }

    // MARK: Sequence

    private var sequence: [PulseOnboardingStep] {
        var steps: [PulseOnboardingStep] = []
        if includesSetup { steps.append(.landing) }
        if includesTerms { steps += [.termsPoints, .privacy] }
        if includesSetup {
            if pairsStrap { steps += PulseOnboardingStep.deviceSteps }
            steps += [.name, .location, .appleHealth, .birthday, .gender, .body, .history, .notifications,
                      .welcome, .expectations]
        }
        return steps
    }

    /// The ring's progress on `step`: its place among the ring steps of its own part of the flow (the
    /// device tutorial has its own, as WHOOP's does).
    private func progress(_ step: PulseOnboardingStep) -> Double {
        let group = PulseOnboardingStep.deviceSteps.contains(step)
            ? PulseOnboardingStep.deviceRingSteps
            : sequence.filter(\.isSetupRingStep)
        guard let index = group.firstIndex(of: step) else { return 0 }
        return pulseOnboardingProgress(index + 1, of: group.count)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            PulseOnboardingBackground()
            stepView
                .id(step)
                .transition(transition)
        }
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(firstRun != nil)
        .onDisappear { pairing.stop(model: model) }
        #if DEBUG
        .onAppear { PulseOnboardingStep.applyDebugPairing(pairing) }
        #endif
    }

    private var transition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                           removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity))
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .landing:
            PulseOnboardingLanding(onPair: { pairsStrap = true; advance() },
                                   onWithoutStrap: { pairsStrap = false; advance() },
                                   onClose: firstRun == nil ? { dismiss() } : nil)
        case .termsPoints:
            PulseOnboardingTermsStep(progress: progress(.termsPoints), showsBack: canGoBack, onBack: back,
                                     onNext: advance)
        case .privacy:
            PulseOnboardingPrivacyStep(progress: progress(.privacy), onBack: back, onAccept: acceptTerms)
        case .putOn:
            PulseOnboardingPutOnStep(progress: progress(.putOn), onBack: back, onNext: advance)
        case .wakeUp:
            PulseOnboardingWakeUpStep(progress: progress(.wakeUp), onBack: back, onNext: advance)
        case .pairingMode:
            PulseOnboardingPairingModeStep(family: $family, onBack: back, onSkip: skipPairing, onStart: {
                pairing.beginSearch(model: model, family: family)
                go(to: .searching)
            })
        case .searching:
            PulseOnboardingSearchStep(pairing: pairing, family: family, onBack: {
                pairing.stop(model: model)
                go(to: .pairingMode, forward: false)
            }, onSkip: skipPairing, onDone: { _ in go(to: .name) })
        case .name:
            PulseOnboardingNameStep(progress: progress(.name), onBack: back, onNext: advance)
        case .location:
            PulseOnboardingLocationStep(progress: progress(.location), onBack: back, onNext: advance)
        case .appleHealth:
            PulseOnboardingHealthStep(progress: progress(.appleHealth), onBack: back, onNext: advance)
        case .birthday:
            PulseOnboardingBirthdayStep(progress: progress(.birthday), onBack: back, onNext: advance)
        case .gender:
            PulseOnboardingGenderStep(progress: progress(.gender), preselect: firstRun == nil, onBack: back,
                                      onNext: advance)
        case .body:
            PulseOnboardingBodyStep(progress: progress(.body), onBack: back, onNext: advance)
        case .history:
            PulseOnboardingHistoryStep(progress: progress(.history), onBack: back, onNext: advance)
        case .notifications:
            PulseOnboardingNotificationsStep(progress: progress(.notifications), onBack: back, onNext: advance)
        case .welcome:
            PulseOnboardingWelcomeStep(progress: progress(.welcome), onBack: back, onNext: advance)
        case .expectations:
            PulseOnboardingExpectationsStep(onBack: back, onDone: finish)
        }
    }

    // MARK: Navigation

    private var canGoBack: Bool {
        (sequence.firstIndex(of: step) ?? 0) > 0 || firstRun == nil
    }

    private func go(to next: PulseOnboardingStep, forward isForward: Bool = true) {
        forward = isForward
        withAnimation(reduceMotion ? PulseMotion.crossFade : .easeInOut(duration: 0.35)) { step = next }
    }

    private func advance() {
        guard let index = sequence.firstIndex(of: step) else { return }
        if index + 1 < sequence.count {
            go(to: sequence[index + 1])
        } else {
            finish()
        }
    }

    private func back() {
        guard let index = sequence.firstIndex(of: step), index > 0 else {
            // The route's first step: leave the replay.
            if firstRun == nil { dismiss() }
            return
        }
        go(to: sequence[index - 1], forward: false)
    }

    /// SKIP on the pairing steps: pair later from Devices, as ZENO always allowed.
    private func skipPairing() {
        pairing.stop(model: model)
        go(to: .name)
        pairsStrap = false
    }

    /// Every attestation is ticked: store the accepted version (the app root's write on a first run), then
    /// carry on, or, when only the terms were due, let the gate close.
    private func acceptTerms() {
        if let firstRun {
            firstRun.onAcceptTerms()
            // Terms only: the app root removes this flow as soon as the version is stored.
            if includesSetup { advance() }
        } else {
            acceptedTerms = Terms.currentVersion
            if includesSetup { advance() } else { dismiss() }
        }
    }

    private func finish() {
        pairing.stop(model: model)
        if let firstRun {
            if includesSetup { firstRun.onFinished() }
        } else {
            dismiss()
        }
    }
}

/// The steps, in the order they can appear.
enum PulseOnboardingStep: String, CaseIterable {
    case landing
    case termsPoints
    case privacy
    case putOn
    case wakeUp
    case pairingMode
    case searching
    case name
    case location
    case appleHealth
    case birthday
    case gender
    case body
    case history
    case notifications
    case welcome
    case expectations

    /// The device tutorial and pairing, present when the wearer chose to pair a strap.
    static let deviceSteps: [PulseOnboardingStep] = [.putOn, .wakeUp, .pairingMode, .searching]
    /// The device tutorial's steps that carry the ring (START PAIRING is the filled circle that ends it).
    static let deviceRingSteps: [PulseOnboardingStep] = [.putOn, .wakeUp, .pairingMode]

    /// Steps whose ring shows progress through the setup (everything except the landing, the device steps
    /// and the last step's filled circle).
    var isSetupRingStep: Bool {
        switch self {
        case .landing, .putOn, .wakeUp, .pairingMode, .searching, .expectations: return false
        default: return true
        }
    }
}

#if DEBUG
extension PulseOnboardingStep {
    /// `--pulse-onboarding-step <name>`: open the flow on a step, for captures.
    static var debugLaunchStep: PulseOnboardingStep? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-onboarding-step"), i + 1 < args.count else { return nil }
        return PulseOnboardingStep(rawValue: args[i + 1])
    }

    /// `--pulse-pairing connecting|connected|failed|failed-hint`: put the pairing screen in that state.
    @MainActor
    static func applyDebugPairing(_ pairing: PulseStrapPairing) {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-pairing"), i + 1 < args.count else { return }
        pairing.debugForce(args[i + 1])
    }
}

extension PulseStrapPairing {
    /// DEBUG: show a pairing state without a strap (captures only).
    func debugForce(_ name: String) {
        let strap = "WHOOP 4C0123456"
        switch name {
        case "connecting": debugSetPhase(.connecting(name: strap))
        case "connected": debugSetPhase(.connected(name: strap))
        case "failed": debugSetPhase(.notConnected(hint: nil))
        case "failed-hint":
            debugSetPhase(.notConnected(hint: String(localized: "Your strap refused the pairing. Unpair it in the official WHOOP app, put it in pairing mode, then tap Retry.")))
        default: break
        }
    }
}
#endif
#endif
