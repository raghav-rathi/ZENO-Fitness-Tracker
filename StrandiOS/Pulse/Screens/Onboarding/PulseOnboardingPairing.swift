#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

// MARK: - The device sub-flow (WHOOP_UI_SPEC §3.38 ZENO step 3; gap-3 §5.3)
//
//   Put On Your Strap → Wake Up Your Strap → Check for Pairing Mode (START PAIRING) →
//   SEARCHING FOR STRAP... → SELECT YOUR DEVICE → CONNECTING → CONNECTED / CONNECTION FAILED
//
// The engine is the classic Add-a-device wizard's (`AddDeviceWizard`): a present-only scan that lists the
// straps nearby without connecting (`AppModel.presentWhoopScan`, `BLEManager.discoveredWhoops`), then
// the registry decides what connects. Three cases, each an existing path:
//   - the strap is already a registered device: make that row active (or connect it, if it already is);
//   - a fresh install with only the seeded "my-whoop" row and ONE strap nearby: the classic onboarding's
//     single-WHOOP connect (`AppModel.scan`), which adopts the strap into "my-whoop" on first connect,
//     so a first run lands in exactly the state it always did;
//   - anything else (several straps nearby, a second strap): the wizard's registration, which pins the
//     chosen strap (`registerDevice(makeActive: true)`), so the strap picked is the strap connected.
// "Connected" is the classic onboarding's own signal, `LiveState.bonded`. Other device types (heart-rate
// straps, gym machines, the experimental tier) keep the classic wizard, one tap away.

/// Where the strap search stands.
@MainActor
final class PulseStrapPairing: ObservableObject {
    enum Phase: Equatable {
        /// Scanning; the list shows what has been found.
        case searching
        /// A strap was picked and is being connected.
        case connecting(name: String)
        /// `LiveState.bonded` went true.
        case connected(name: String)
        /// Nothing bonded in time, or the strap refused the bond (`hint` is the BLE layer's own words).
        case notConnected(hint: String?)
    }

    @Published private(set) var phase: Phase = .searching
    /// Whether the link reached its encrypted bond (`LiveState.encryptedBond`): a 5.0/MG can stream heart
    /// rate before it does (#69), and CONNECTED says so.
    @Published private(set) var encrypted = false
    private var timeout: Task<Void, Never>?
    /// The app model the scan was started on, so the flow can stop it without observing the model.
    private weak var model: AppModel?

    /// How long a connect may take before the screen says it did not happen. A WHOOP 5.0/MG shows the
    /// iOS pairing prompt first, so this leaves time to read and answer it.
    static let connectTimeoutSeconds = 45

    /// Start (or restart) the present-only scan for `family`.
    func beginSearch(model: AppModel, family: WhoopModel) {
        self.model = model
        timeout?.cancel()
        phase = .searching
        model.presentWhoopScan(model: family)
    }

    /// Stop scanning and forget any pending connect timeout (leaving the device steps). A connect already
    /// asked for keeps going, as the classic onboarding's did.
    func stop() {
        timeout?.cancel()
        model?.stopWhoopScan()
    }

    /// The wearer picked a strap from the list.
    func pick(uuid: String, name: String, discoveredCount: Int, model: AppModel, family: WhoopModel) {
        model.stopWhoopScan()
        let display = name.isEmpty ? family.displayName : name
        phase = .connecting(name: display)
        connect(uuid: uuid, name: display, discoveredCount: discoveredCount, model: model, family: family)
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.connectTimeoutSeconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.timedOut()
        }
    }

    /// The strap bonded (or was already bonded when the step appeared).
    func bonded(fallbackName: String) {
        timeout?.cancel()
        switch phase {
        case .connecting(let name): phase = .connected(name: name)
        case .connected: break
        default: phase = .connected(name: fallbackName)
        }
    }

    func encryptionChanged(_ value: Bool) {
        if encrypted != value { encrypted = value }
    }

    /// The BLE layer reported a pairing problem it can name (`LiveState.pairingHint` / `reconnectGuide`).
    func failed(hint: String) {
        guard case .connecting = phase else { return }
        timeout?.cancel()
        phase = .notConnected(hint: hint)
    }

    private func timedOut() {
        guard case .connecting = phase else { return }
        phase = .notConnected(hint: nil)
    }

    #if DEBUG
    /// Captures only (`--pulse-pairing`): show a state without a strap.
    func debugSetPhase(_ forced: Phase) {
        timeout?.cancel()
        phase = forced
    }
    #endif

    private func connect(uuid: String, name: String, discoveredCount: Int, model: AppModel, family: WhoopModel) {
        guard let registry = model.deviceRegistry else {
            // The registry is wired once the store opens; until then the classic onboarding's connect.
            model.scan(model: family)
            return
        }
        if let known = registry.devices.first(where: {
            $0.peripheralId?.caseInsensitiveCompare(uuid) == .orderedSame && $0.status != .archived
        }) {
            if registry.activeDeviceId == known.id {
                model.scan(model: family)
            } else {
                registry.setActive(known.id)
            }
            return
        }
        let active = registry.devices.first { $0.id == registry.activeDeviceId }
        let untouchedSeed = active?.id == "my-whoop" && active?.peripheralId == nil
        if untouchedSeed && discoveredCount <= 1 {
            model.scan(model: family)
            return
        }
        // `AddDeviceWizard.finishAdd`'s WHOOP registration, field for field: the model labels the
        // registry resolves through `DeviceFamily.forRegistryModel`, the honest live capability set.
        let label = family == .whoop4 ? "4.0" : "5.0 MG"
        let now = Int(Date().timeIntervalSince1970)
        let device = PairedDevice(id: "whoop-\(uuid)", brand: "WHOOP", model: label, nickname: name,
                                  peripheralId: uuid, sourceKind: .liveBLE,
                                  capabilities: WhoopLiveCapabilities.metrics(forModel: label),
                                  status: .paired, addedAt: now, lastSeenAt: now)
        model.registerDevice(device, makeActive: true)
    }
}

// MARK: - Steps

/// "Put On Your Strap".
struct PulseOnboardingPutOnStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Put On Your Strap"),
            subtitle: String(localized: "Wear it snug on your wrist or bicep, with the sensor against your skin."),
            art: .device,
            onBack: onBack,
            illustration: { PulseStrapIllustration(podWidth: 122, length: PulseOnboardingMetrics.deviceArtHeight) },
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    PulseOnboardingCheckLine(text: String(localized: "Snug but comfortable: the sensor needs skin contact to read your heart."))
                    PulseOnboardingCheckLine(text: String(localized: "Keep it on overnight. Sleep and Recovery come from the nights you wear it."))
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
    }
}

/// "Wake Up Your Strap" (charge it).
struct PulseOnboardingWakeUpStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Wake Up Your Strap"),
            subtitle: String(localized: "Give it a few minutes on the charger if the battery is low. A strap with no charge can't be found."),
            art: .device,
            onBack: onBack,
            illustration: { PulseStrapIllustration(charging: true, podWidth: 122, length: PulseOnboardingMetrics.deviceArtHeight) },
            content: {
                PulseOnboardingCheckLine(text: String(localized: "Keep it within about a metre of your iPhone while it pairs."))
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
    }
}

/// "Check for Pairing Mode": which strap, the one-phone-at-a-time warning, the Bluetooth priming, and the
/// filled START PAIRING circle. SKIP leaves pairing for later, as ZENO always has allowed.
struct PulseOnboardingPairingModeStep: View {
    @Binding var family: WhoopModel
    let onBack: () -> Void
    let onSkip: () -> Void
    let onStart: () -> Void

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Check for Pairing Mode"),
            subtitle: subtitle,
            trailing: .text(String(localized: "Skip"), onSkip),
            art: .device,
            onBack: onBack,
            illustration: { PulseStrapIllustration(led: true, podWidth: 110, length: PulseOnboardingMetrics.deviceArtHeight) },
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    PulseOnboardingFieldLabel(String(localized: "Your strap"))
                    ForEach(WhoopModel.allCases) { option in
                        PulseOnboardingOptionRow(title: option.displayName, selected: family == option) {
                            family = option
                        }
                    }
                    Text(String(localized: "ZENO talks to your strap directly over Bluetooth, with no server in between. If iOS asks, choose Allow so ZENO can find it."))
                        .pulseOnboardingText(.checkLine)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
            },
            cta: { PulseOnboardingFilledButton(title: String(localized: "Start pairing"), action: onStart) })
    }

    private var subtitle: String {
        switch family {
        case .whoop4:
            return String(localized: "Make sure it isn't connected to the official WHOOP app right now. A strap talks to one phone at a time.")
        case .whoop5mg:
            return String(localized: "WHOOP 5.0 / MG pairs with one app at a time. Unpair it in the official WHOOP app and close that app first.")
        }
    }
}

/// SEARCHING FOR STRAP... → SELECT YOUR DEVICE → CONNECTING → CONNECTED / CONNECTION FAILED, one screen
/// that follows `PulseStrapPairing.phase`.
struct PulseOnboardingSearchStep: View {
    @ObservedObject var pairing: PulseStrapPairing
    let family: WhoopModel
    let onBack: () -> Void
    let onSkip: () -> Void
    /// Leave the device steps: `true` once a strap bonded, `false` when another device was added.
    let onDone: (_ bonded: Bool) -> Void

    /// Not `LiveState`: it publishes every log line and beat. The link's few facts reach this screen through
    /// the watcher below and `PulseStrapPairing`.
    @EnvironmentObject private var model: AppModel
    @State private var showsHelp = false
    @State private var showsOtherDevice = false
    @State private var activeBeforeOtherDevice: String?

    var body: some View {
        content
            .background(PulseOnboardingPairingWatcher(onBonded: { pairing.bonded(fallbackName: fallbackName) },
                                                      onEncrypted: { pairing.encryptionChanged($0) },
                                                      onHint: { pairing.failed(hint: $0) }))
            .sheet(isPresented: $showsHelp) {
                PulseStrapHelpSheet(family: family, onTryAgain: {
                    showsHelp = false
                    pairing.beginSearch(model: model, family: family)
                }, onOtherDevice: {
                    showsHelp = false
                    openOtherDevice()
                }, onSkip: {
                    showsHelp = false
                    onSkip()
                })
            }
            .sheet(isPresented: $showsOtherDevice, onDismiss: otherDeviceClosed) {
                AddDeviceWizard(live: model.live, onClose: { showsOtherDevice = false })
            }
            .onAppear {
                // Arriving here (from START PAIRING, or back from a later step): a strap already bonded is
                // CONNECTED; otherwise the search starts afresh, whatever an earlier attempt ended on.
                pairing.encryptionChanged(model.live.encryptedBond)
                if model.live.bonded {
                    pairing.bonded(fallbackName: fallbackName)
                } else {
                    pairing.beginSearch(model: model, family: family)
                }
                #if DEBUG
                PulseOnboardingStep.applyDebugPairing(pairing)
                #endif
            }
    }

    @ViewBuilder
    private var content: some View {
        switch pairing.phase {
        case .searching:
            searching
        case .connecting(let name):
            PulseOnboardingStatusPage(
                title: String(localized: "Connecting"),
                subtitle: family == .whoop5mg
                    ? String(localized: "Pairing with \(name). If iOS asks to pair, tap Pair.")
                    : String(localized: "Pairing with \(name)."),
                onLeading: { pairing.beginSearch(model: model, family: family) },
                art: { PulseConnectionArt(state: .connecting).frame(height: 300) },
                middle: { EmptyView() },
                buttons: { EmptyView() })
        case .connected(let name):
            PulseOnboardingStatusPage(
                title: String(localized: "\(name) connected"),
                subtitle: connectedLine,
                leading: .none,
                onLeading: {},
                art: { PulseConnectionArt(state: .connected).frame(height: 300) },
                middle: { EmptyView() },
                buttons: {
                    Button(String(localized: "Continue")) { onDone(true) }
                        .buttonStyle(PulseOnboardingPillStyle(kind: .white))
                })
        case .notConnected(let hint):
            PulseOnboardingStatusPage(
                title: hint == nil ? String(localized: "Couldn't connect") : String(localized: "Connection failed"),
                subtitle: hint ?? String(localized: "ZENO tried for \(PulseStrapPairing.connectTimeoutSeconds) seconds without reaching your strap. Select Retry, or open Need More Help for the steps that usually fix it."),
                leading: .closeCircle,
                onLeading: onBack,
                art: { PulseConnectionArt(state: .failed).frame(height: 300) },
                middle: { EmptyView() },
                buttons: {
                    Button(String(localized: "Retry")) { pairing.beginSearch(model: model, family: family) }
                        .buttonStyle(PulseOnboardingPillStyle(kind: .white))
                    Button(String(localized: "Need more help?")) { showsHelp = true }
                        .buttonStyle(PulseOnboardingPillStyle(kind: .dark))
                })
        }
    }

    private var searching: some View {
        PulseOnboardingStrapList(ble: model.ble) { found in
            PulseOnboardingStatusPage(
                title: found.isEmpty ? String(localized: "Searching for strap...") : String(localized: "Select your device"),
                subtitle: found.isEmpty
                    ? String(localized: "Make sure your strap is awake, in range and not connected to another app.")
                    : String(localized: "Confirm the name matches the serial on the side of your strap."),
                trailing: .help { showsHelp = true },
                titleFirst: true,
                onLeading: onBack,
                art: { searchArt(found: !found.isEmpty) },
                middle: {
                    if !found.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(found, id: \.uuid) { strap in
                                strapRow(strap, count: found.count)
                            }
                        }
                        .padding(.horizontal, PulseTheme.Layout.pageMargin)
                        .padding(.bottom, 20)
                    }
                },
                buttons: {
                    Button(String(localized: "Don't see your device?")) { showsHelp = true }
                        .buttonStyle(PulseOnboardingPillStyle(kind: .outlineWhite))
                })
        }
    }

    /// The strap with a dotted blue leader to where its serial is printed.
    private func searchArt(found: Bool) -> some View {
        ZStack {
            PulseStrapIllustration(podWidth: found ? 100 : 140)
            VStack(spacing: 0) {
                Text(String(localized: "Serial on the side"))
                    .pulseText(.label)
                    .foregroundStyle(PulseOnboardingColors.serialBlue)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 0, y: found ? 26 : 40))
                }
                .stroke(PulseOnboardingColors.serialBlue, style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                .frame(width: 1.5, height: found ? 26 : 40)
                Circle().fill(PulseOnboardingColors.serialBlue).frame(width: 9, height: 9)
            }
            .offset(x: found ? 66 : 92, y: found ? -44 : -60)
        }
        .accessibilityHidden(true)
    }

    private func strapRow(_ strap: (uuid: String, name: String, rssi: Int), count: Int) -> some View {
        Button {
            pairing.pick(uuid: strap.uuid, name: strap.name, discoveredCount: count, model: model, family: family)
        } label: {
            HStack(spacing: 12) {
                Text(strap.name.isEmpty ? family.displayName : strap.name)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                PulseSignalBars(rssi: strap.rssi)
                PulseChevron(color: PulseTheme.textSecondary, size: 14)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(Color.white.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "\(strap.name.isEmpty ? family.displayName : strap.name), signal \(SignalBars.level(for: strap.rssi)) of 4"))
    }

    private var fallbackName: String {
        model.live.advertisingName ?? String(localized: "Your strap")
    }

    /// CONNECTED's line: honest about a 5.0/MG that streams heart rate before its encrypted bond (#69).
    private var connectedLine: String {
        if pairing.encrypted || family == .whoop4 {
            return String(localized: "Your strap is ready to go.")
        }
        return String(localized: "Live heart rate is coming through. History sync waits for the full pairing, which can take another moment.")
    }

    private func openOtherDevice() {
        pairing.stop()
        activeBeforeOtherDevice = model.deviceRegistry?.activeDeviceId
        showsOtherDevice = true
    }

    /// Another kind of device was added and made active: move on (it is not called "connected", since
    /// only the wizard knows whether it streams yet). Otherwise go back to searching for a strap.
    private func otherDeviceClosed() {
        if let before = activeBeforeOtherDevice, model.deviceRegistry?.activeDeviceId != before {
            onDone(false)
        } else {
            pairing.beginSearch(model: model, family: family)
        }
    }
}

/// Four signal bars in Pulse's whites, bucketed by the Devices screen's one rule (`SignalBars.level`).
private struct PulseSignalBars: View {
    let rssi: Int

    var body: some View {
        let level = SignalBars.level(for: rssi)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(i < level ? PulseTheme.textPrimary : PulseTheme.textDisabled.opacity(0.5))
                    .frame(width: 3, height: 6 + CGFloat(i) * 3)
            }
        }
        .frame(width: 22, height: 18, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Observes the present-only scan's list (the classic wizard's `WhoopPickList` does the same), so a new
/// strap or a fresh signal reading redraws the list and nothing else.
private struct PulseOnboardingStrapList<Content: View>: View {
    @ObservedObject var ble: BLEManager
    @ViewBuilder let content: ([(uuid: String, name: String, rssi: Int)]) -> Content

    var body: some View {
        content(straps)
    }

    private var straps: [(uuid: String, name: String, rssi: Int)] {
        #if DEBUG
        if let forced = PulseOnboardingStep.debugFoundStraps { return forced }
        #endif
        return ble.discoveredWhoops.sorted { $0.rssi > $1.rssi }
    }
}

/// A hidden leaf that watches the live link, so a heartbeat redraws nothing else (the classic
/// onboarding's `BondWatcher`).
private struct PulseOnboardingPairingWatcher: View {
    let onBonded: () -> Void
    let onEncrypted: (Bool) -> Void
    let onHint: (String) -> Void
    @EnvironmentObject private var live: LiveState

    var body: some View {
        Color.clear
            .onChange(of: live.bonded) { _, bonded in if bonded { onBonded() } }
            .onChange(of: live.encryptedBond) { _, encrypted in onEncrypted(encrypted) }
            .onChange(of: live.pairingHint) { _, hint in if let hint { onHint(hint) } }
            .onChange(of: live.reconnectGuide) { _, guide in if let guide { onHint(guide) } }
            .accessibilityHidden(true)
    }
}

// MARK: - Help

/// "DON'T SEE YOUR DEVICE?" / "NEED MORE HELP?": the classic onboarding's reassurance and checklist, the
/// BLE layer's own hint when it has one, then Try again, another kind of device, or skip.
struct PulseStrapHelpSheet: View {
    let family: WhoopModel
    let onTryAgain: () -> Void
    let onOtherDevice: () -> Void
    let onSkip: () -> Void

    @EnvironmentObject private var live: LiveState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(String(localized: "Don't see your strap?"))
                    .pulseOnboardingText(.statusTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.top, 28)
                    .accessibilityAddTraits(.isHeader)
                Text(String(localized: "That's normal. WHOOP straps don't appear in your iPhone's Bluetooth settings: they advertise on a profile only apps like ZENO can find, so there's nothing to pair there, and you shouldn't try."))
                    .pulseOnboardingText(.subtitle)
                    .foregroundStyle(PulseTheme.Onboarding.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
                if let hint = live.pairingHint ?? live.reconnectGuide {
                    Text(hint)
                        .pulseOnboardingText(.checkLine)
                        .foregroundStyle(PulseTheme.Onboarding.validationText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                            .fill(PulseTheme.Activity.validationBannerFill))
                }
                VStack(alignment: .leading, spacing: 12) {
                    PulseOnboardingCheckLine(text: String(localized: "It's charged and worn. The sensor needs skin contact to wake."))
                    PulseOnboardingCheckLine(text: String(localized: "It isn't held by the official WHOOP app. Only one phone at a time: close that app or turn off its Bluetooth."))
                    if family == .whoop5mg {
                        PulseOnboardingCheckLine(text: String(localized: "A WHOOP 5.0 / MG is unpaired in the official WHOOP app first, then put in pairing mode."))
                    }
                    PulseOnboardingCheckLine(text: String(localized: "It's within about a metre of your iPhone."))
                    PulseOnboardingCheckLine(text: String(localized: "Bluetooth is on, and ZENO may use it (Settings › ZENO › Bluetooth)."))
                }
                VStack(spacing: 12) {
                    Button(String(localized: "Try again"), action: onTryAgain)
                        .buttonStyle(PulseOnboardingPillStyle(kind: .white))
                    Button(String(localized: "Pair another kind of device"), action: onOtherDevice)
                        .buttonStyle(PulseOnboardingPillStyle(kind: .dark))
                    Button(action: onSkip) {
                        Text(String(localized: "Skip for now"))
                            .pulseOnboardingText(.pill)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                }
                .padding(.top, 8)
                Text(String(localized: "Heart-rate straps, gym machines and the experimental devices pair through the same wizard as in Devices."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(PulseOnboardingBackground())
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }
}
#endif
