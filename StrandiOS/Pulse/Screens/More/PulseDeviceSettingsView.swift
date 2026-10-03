#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// Device Settings (WHOOP_UI_SPEC §3.32), a full-screen modal: "✕ DEVICE SETTINGS ⓘ", the strap's
/// connection and last sync, then STATUS | ADVANCED (reviews/r01, help-center/96, 97, onboarding/43a).
///
/// STATUS: the band, its battery with a vertical level bar, and BROADCAST HEART RATE pinned at the foot
/// (ZENO's phone-side re-broadcaster, with the experimental strap-side switch under it); disconnected, the
/// "STRAP DISCONNECTED" picture and PAIR A DEVICE. ADVANCED: pair, unpair, firmware check, reboot (where a
/// safe command exists), and MY DEVICES. ERASE is left out: ZENO sends no destructive command.
///
/// Everything reads what the classic Devices screen reads (the registry's active device, `LiveState`,
/// `FirmwareAttribution`) and acts through the same calls (`AddDeviceWizard`, `forgetDevice` + `archive`,
/// `rebootStrap`, `setActive`, `rename`), so the two screens can never disagree about the strap.
struct PulseDeviceSettingsView: View {
    /// Rebuilt: NavRouter's Devices request and the Home strap chip open this screen.
    static let isRebuilt = true

    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let registry = model.deviceRegistry {
            PulseDeviceSettingsContent(registry: registry)
        } else {
            // The registry is built once the store opens, a beat after launch.
            PulseScreenScaffold(title: String(localized: "Device settings")) {
                PulseSkeleton.cards([60, 300, 72])
            }
        }
    }
}

private enum DeviceTab: String, CaseIterable {
    case status, advanced

    var title: String {
        switch self {
        case .status: return String(localized: "Status")
        case .advanced: return String(localized: "Advanced")
        }
    }
}

/// The screen once the registry exists. It observes the registry; the live strap readings sit in leaf
/// views, so a heart-rate tick re-renders only them.
private struct PulseDeviceSettingsContent: View {
    @ObservedObject var registry: DeviceRegistry
    @EnvironmentObject private var model: AppModel
    @Environment(\.pulseNavigator) private var navigator

    @State private var tab: DeviceTab = .status
    @State private var showPairing = false
    @State private var showInfo = false
    @State private var renaming = false
    @State private var renameDraft = ""
    @State private var dialog: DeviceDialog?
    @State private var switchTarget: PairedDevice?
    @State private var pickNewActive = false

    private var active: PairedDevice? {
        registry.devices.first { $0.status == .active && !$0.isImportSource }
    }

    private var pairedDevices: [PairedDevice] {
        registry.devices.filter { $0.status != .archived && !$0.isImportSource }
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Device settings"),
                            trailing: .info { showInfo = true },
                            spacing: 0, topPadding: 18) {
            DeviceHeader(device: active, onRename: active == nil ? nil : {
                renameDraft = active?.nickname ?? active?.displayName ?? ""
                renaming = true
            })
            DeviceTabs(selection: $tab)
                .padding(.top, 26)
            switch tab {
            case .status:
                DeviceStatusTab(device: active, modelName: active.map(modelName) ?? "",
                                onPair: { showPairing = true })
            case .advanced:
                advanced
                    .padding(.top, 38)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if tab == .status, active != nil {
                DeviceBroadcastSlot()
            }
        }
        .sheet(isPresented: $showPairing) {
            AddDeviceWizard(live: model.live) { showPairing = false }
                .environmentObject(model)
                .environmentObject(model.live)
        }
        .sheet(isPresented: $showInfo) {
            DeviceInfoSheet()
        }
        .alert(String(localized: "Rename your strap"), isPresented: $renaming) {
            TextField(String(localized: "Name"), text: $renameDraft)
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Save")) {
                if let id = active?.id { registry.rename(id, to: String(renameDraft.prefix(24))) }
            }
        } message: {
            Text(String(localized: "The name ZENO shows for this strap. Leave it empty to use the model name."))
        }
        .fullScreenCover(item: $dialog) { dialog in
            dialogView(dialog)
                .presentationBackground(.clear)
        }
        .confirmationDialog(String(localized: "Make this your active strap?"),
                            isPresented: Binding(get: { switchTarget != nil }, set: { if !$0 { switchTarget = nil } }),
                            titleVisibility: .visible, presenting: switchTarget) { device in
            Button(String(localized: "Make active")) { registry.setActive(device.id) }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: { device in
            Text(String(localized: "\(device.displayName) will provide your live data from now on. Every strap's history stays as it is."))
        }
        .confirmationDialog(String(localized: "Pick a new active strap"), isPresented: $pickNewActive,
                            titleVisibility: .visible) {
            ForEach(pairedDevices) { device in
                Button(device.displayName) { registry.setActive(device.id) }
            }
            Button(String(localized: "Leave none active"), role: .cancel) { }
        } message: {
            Text(String(localized: "Choose which paired band provides your live data, or pair one later."))
        }
        .onAppear(perform: openDebugTab)
    }

    // MARK: ADVANCED

    private var advanced: some View {
        VStack(alignment: .leading, spacing: 0) {
            advancedItem(symbol: "plus.circle", title: String(localized: "Pair a device"),
                         help: String(localized: "Pair a strap with ZENO. A new WHOOP becomes your active strap; your other straps and their history stay.")) {
                showPairing = true
            }
            if let active {
                advancedItem(symbol: "minus.circle", title: String(localized: "Unpair device"),
                             help: String(localized: "ZENO stops connecting to \(active.displayName) and releases its Bluetooth link. Its recorded data stays.")) {
                    dialog = .unpair(active)
                }
                advancedItem(symbol: "cpu", title: String(localized: "Firmware check"),
                             help: String(localized: "See which firmware your strap runs. ZENO never installs firmware.")) {
                    dialog = .firmware(firmware(for: active))
                }
                DeviceRebootItem(device: active, isWhoop4: model.ble.isWhoop4) { dialog = .reboot(active) }
            }
            MoreSection(String(localized: "My devices")) {
                ForEach(pairedDevices) { device in
                    MoreButtonRow(symbol: symbol(for: device), title: device.displayName,
                                  subtitle: device.brand == device.model ? nil : device.model,
                                  trailing: .tag(device.status == .active ? String(localized: "Active")
                                                                         : String(localized: "Paired"))) {
                        if device.status != .active { switchTarget = device }
                    }
                }
                MoreLinkRow(.classic(.devices), symbol: "slider.horizontal.3", title: String(localized: "Manage all devices"),
                            subtitle: String(localized: "Rename, remove, Oura and gym kit"))
            }
            .padding(.top, 8)
        }
    }

    private func advancedItem(symbol: String, title: String, help: String,
                              action: @escaping () -> Void) -> some View {
        DeviceAdvancedItem(symbol: symbol, title: title, help: help, action: action)
    }

    // MARK: Dialogs

    @ViewBuilder
    private func dialogView(_ dialog: DeviceDialog) -> some View {
        switch dialog {
        case .unpair(let device):
            PulseDialogCard(title: String(localized: "Are you sure?"),
                            message: String(localized: "ZENO will stop connecting to \(device.displayName). Its recorded data stays on this iPhone, and you can pair it again any time."),
                            primaryTitle: String(localized: "Unpair"),
                            primary: {
                                self.dialog = nil
                                unpair(device)
                            },
                            secondaryTitle: String(localized: "Cancel"),
                            secondary: { self.dialog = nil },
                            onClose: { self.dialog = nil })
        case .firmware(let version):
            PulseDialogCard(title: String(localized: "No new updates"),
                            message: version.map { String(localized: "Your strap runs firmware \($0). ZENO never installs firmware: updates come only from WHOOP's own app.") }
                                ?? String(localized: "Connect your strap to read its firmware. ZENO never installs firmware: updates come only from WHOOP's own app."),
                            primaryTitle: String(localized: "Okay"),
                            primary: { self.dialog = nil },
                            onClose: { self.dialog = nil })
        case .reboot(let device):
            PulseDialogCard(title: String(localized: "Reboot your strap?"),
                            message: String(localized: "\(device.displayName) disconnects for about 30 seconds while it restarts, then reconnects on its own. Your data is kept."),
                            primaryTitle: String(localized: "Reboot"),
                            primary: {
                                self.dialog = nil
                                model.rebootStrap()
                            },
                            secondaryTitle: String(localized: "Cancel"),
                            secondary: { self.dialog = nil },
                            onClose: { self.dialog = nil })
        }
    }

    /// The classic Devices screen's remove, step for step: release the Bluetooth link (so the strap can
    /// go into pairing mode again), archive the row, then ask for a new active strap if one remains.
    private func unpair(_ device: PairedDevice) {
        let wasActive = device.status == .active
        model.ble.forgetDevice(device.peripheralId)
        registry.archive(device.id)
        if wasActive && !pairedDevices.isEmpty { pickNewActive = true }
    }

    /// The firmware the classic Devices card shows for this strap (`FirmwareAttribution`).
    private func firmware(for device: PairedDevice) -> String? {
        let isWhoop = SourceCoordinator.isWhoop(device)
        return FirmwareAttribution.resolve(
            live: device.status == .active ? model.live.strapFirmware : nil,
            perDevice: isWhoop ? FirmwareAttribution.prefKey(peripheralId: device.peripheralId)
                .flatMap { UserDefaults.standard.string(forKey: $0) } : nil,
            legacyGlobal: isWhoop ? UserDefaults.standard.string(forKey: "noop.lastFirmware") : nil,
            pairedCount: registry.devices.count)
    }

    /// The strap's generation for the battery's caption: the registry's model when it names one, else the
    /// family ZENO is talking to ("WHOOP 4.0").
    private func modelName(_ device: PairedDevice) -> String {
        if SourceCoordinator.isWhoop(device), device.model.trimmingCharacters(in: .whitespaces).uppercased() == "WHOOP" {
            return model.ble.isWhoop4 ? WhoopModel.whoop4.displayName : WhoopModel.whoop5mg.displayName
        }
        return device.model
    }

    private func symbol(for device: PairedDevice) -> String {
        if SourceCoordinator.isWhoop(device) { return "sensor.tag.radiowaves.forward" }
        if device.id.hasPrefix("oura-") { return "circle.circle" }
        return "heart.circle"
    }

    /// DEBUG `--more-open device-advanced` opens on ADVANCED for captures.
    private func openDebugTab() {
        #if DEBUG
        if PulseMoreDebug.take(prefixes: ["device-advanced"]) != nil { tab = .advanced }
        #endif
    }
}

/// An ADVANCED row: its card, then its grey helper text, 37 pt above the next card (help-center/97).
private struct DeviceAdvancedItem: View {
    let symbol: String
    let title: String
    let help: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            MoreButtonRow(symbol: symbol, title: title,
                          titleColor: disabled ? PulseTheme.textDisabled : PulseTheme.textPrimary, action: action)
                .disabled(disabled)
            Text(help)
                .pulseText(.rowSubline)
                .lineSpacing(3)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
        }
        .padding(.bottom, 34)
    }
}

/// REBOOT DEVICE, a leaf that follows the link: offered for a connected WHOOP with a safe restart frame.
/// A WHOOP 4.0 has none (#275: every candidate frame does nothing or wedges the link), so its row says
/// so instead of offering a button that cannot work.
private struct DeviceRebootItem: View {
    let device: PairedDevice
    let isWhoop4: Bool
    let onReboot: () -> Void
    @EnvironmentObject private var live: LiveState

    var body: some View {
        if SourceCoordinator.isWhoop(device) {
            if isWhoop4 {
                DeviceAdvancedItem(symbol: "power", title: String(localized: "Reboot device"),
                                   help: String(localized: "A WHOOP 4.0 has no safe restart command, so ZENO cannot restart it. Its charger restarts it."),
                                   disabled: true) { }
            } else {
                DeviceAdvancedItem(symbol: "power", title: String(localized: "Reboot device"),
                                   help: live.connected ? String(localized: "Restart your strap. It disconnects for about 30 seconds, then reconnects on its own.")
                                                        : String(localized: "Connect your strap to restart it."),
                                   disabled: !live.connected, action: onReboot)
            }
        }
    }
}

private enum DeviceDialog: Identifiable {
    case unpair(PairedDevice)
    case firmware(String?)
    case reboot(PairedDevice)

    var id: String {
        switch self {
        case .unpair(let d): return "unpair-\(d.id)"
        case .firmware: return "firmware"
        case .reboot(let d): return "reboot-\(d.id)"
        }
    }
}

// MARK: - Header

/// "CONNECTED TO" (teal) or "NOT CONNECTED TO" (grey) over the strap's name and a ✎, and at the right
/// LAST SYNC (or CATCHING UP while history pulls) over its time, with a cloud mark.
private struct DeviceHeader: View {
    let device: PairedDevice?
    let onRename: (() -> Void)?
    @EnvironmentObject private var live: LiveState

    var body: some View {
        DeviceHeaderContent(name: device?.displayName, connected: live.connected || Self.isDemo,
                            syncing: live.backfilling, lastSync: live.lastSyncedAt, onRename: onRename)
    }

    /// DEBUG `--demo-sync` stands in for a connected strap, as it does for the Home strap chip.
    private static var isDemo: Bool {
        #if DEBUG
        return DemoSyncHarness.active
        #else
        return false
        #endif
    }
}

private struct DeviceHeaderContent: View {
    let name: String?
    let connected: Bool
    let syncing: Bool
    let lastSync: TimeInterval?
    let onRename: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(name == nil ? String(localized: "No strap paired")
                                 : (connected ? String(localized: "Connected to") : String(localized: "Not connected to")))
                    .pulseText(.label)
                    .foregroundStyle(connected ? PulseTheme.positive : PulseTheme.textTertiary)
                if let name {
                    Button { onRename?() } label: {
                        HStack(spacing: 8) {
                            Text(name)
                                .font(.system(size: 17, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundStyle(PulseTheme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "\(name), rename"))
                }
            }
            Spacer(minLength: 8)
            if name != nil {
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(syncing ? String(localized: "Catching up") : String(localized: "Last sync"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textSecondary)
                        Text(lastSyncText)
                            .font(PulseType.numeral(15))
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    Image(systemName: syncing ? "icloud.and.arrow.up" : (lastSync == nil ? "icloud" : "checkmark.icloud"))
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// "10:37 AM" today, "Oct 1, 7:17 PM" before; a real instant, so the device's zone.
    private var lastSyncText: String {
        guard let lastSync else { return "--" }
        let date = Date(timeIntervalSince1970: lastSync)
        if Calendar.current.isDateInToday(date) { return PulseFormat.clock(date) }
        let day = date.formatted(.dateTime.month(.abbreviated).day().locale(AppLanguage.activeLocale))
        return "\(day), \(PulseFormat.clock(date))"
    }
}

// MARK: - Tabs

/// "STATUS   ADVANCED": left-aligned caps tabs, the selected one white over a 2 pt underline, the other
/// 50% (help-center/97).
private struct DeviceTabs: View {
    @Binding var selection: DeviceTab

    var body: some View {
        HStack(spacing: 34) {
            ForEach(DeviceTab.allCases, id: \.self) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .pulseText(.cardTitle)
                            .foregroundStyle(selection == tab ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        Rectangle()
                            .fill(selection == tab ? PulseTheme.textPrimary : Color.clear)
                            .frame(height: 2)
                    }
                    .fixedSize()
                    .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 4)
    }
}

// MARK: - STATUS

/// The band, cropped off the left edge, with the battery at the right: "58 %" over the model and a
/// vertical level bar (spec §3.32). Disconnected or unpaired, the picture says so and offers pairing.
private struct DeviceStatusTab: View {
    let device: PairedDevice?
    let modelName: String
    let onPair: () -> Void
    @EnvironmentObject private var live: LiveState

    var body: some View {
        let display = batteryDisplay
        Group {
            if let device, live.connected || isDemo {
                connected(device: device, display: display)
            } else {
                disconnected
            }
        }
    }

    private func connected(device: PairedDevice, display: LiquidTodayView.StrapBatteryDisplay) -> some View {
        ZStack(alignment: .bottomTrailing) {
            DeviceStrapArt(height: 330)
                .offset(x: -40, y: -8)
                .frame(maxWidth: .infinity, alignment: .leading)
            DeviceBatteryReadout(display: display, model: modelName)
                .padding(.trailing, 4)
                .padding(.bottom, 26)
        }
        .frame(height: 430)
        .padding(.top, 34)
    }

    /// onboarding/43a: the band at the left and a phone at the right, both cropped by the screen edges,
    /// joined by a dotted line broken by a red ✕, the words right under it, PAIR A DEVICE lower down.
    private var disconnected: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    // Wider than its slot: the band runs off the screen's left edge, as on onboarding/43a.
                    DeviceStrapArt(height: 230)
                        .frame(width: 130, alignment: .trailing)
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.black, lineWidth: 5)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(hex: "#1E2328")))
                        .overlay {
                            PulseZenoMonogramShape()
                                .stroke(PulseTheme.textTertiary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 22, height: 22)
                                .padding(12)
                                .overlay(Circle().strokeBorder(PulseTheme.textTertiary, lineWidth: 1.5))
                        }
                        .frame(width: 112, height: 240)
                        .offset(x: 52)
                }
                .padding(.horizontal, -PulseTheme.Layout.pageMargin)
                HStack(spacing: 6) {
                    dots
                    ZStack {
                        Circle().strokeBorder(PulseTheme.recoveryLow, lineWidth: 2)
                        Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.white)
                    }
                    .frame(width: 40, height: 40)
                    dots
                }
                VStack(spacing: 6) {
                    Text(device == nil ? String(localized: "No strap paired") : String(localized: "Strap disconnected"))
                        .modifier(MoreLabelText(tracking: 1.4))
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Tap 'Pair a device' below to continue."))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .offset(y: 70)
                .accessibilityElement(children: .combine)
            }
            .frame(height: 300)
            MoreButtonRow(symbol: "plus.circle", title: String(localized: "Pair a device"), action: onPair)
                .padding(.top, 130)
        }
        .padding(.top, 50)
    }

    private var dots: some View {
        HStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { _ in
                Circle().fill(PulseTheme.textTertiary).frame(width: 2.5, height: 2.5)
            }
        }
        .accessibilityHidden(true)
    }

    /// The same resolution as the Home strap chip (`StrapBatteryDisplay`), so the two never disagree.
    private var batteryDisplay: LiquidTodayView.StrapBatteryDisplay {
        #if DEBUG
        if DemoSyncHarness.active {
            return .charge(pct: DemoSyncHarness.batteryPercent, charging: DemoSyncHarness.charging, isRing: false)
        }
        #endif
        return LiquidTodayView.StrapBatteryDisplay.resolve(
            activeIsWhoop: live.activeIsWhoop, connected: live.connected, batteryPct: live.batteryPct,
            charging: live.charging, ringPct: live.ouraBatteryPct, ringCharging: live.ouraWearState == .charging)
    }

    private var isDemo: Bool {
        #if DEBUG
        return DemoSyncHarness.active
        #else
        return false
        #endif
    }
}

/// "58 %" (40 pt, the % 17 pt) over the model in grey caps, beside a 6 × 150 pt level bar.
private struct DeviceBatteryReadout: View {
    let display: LiquidTodayView.StrapBatteryDisplay
    let model: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    if charging {
                        Image(systemName: "bolt.fill").font(.system(size: 20, weight: .bold))
                            .foregroundStyle(PulseTheme.positive)
                    }
                    Text(percentText).font(PulseType.numeral(44, hero: true))
                    Text(verbatim: "%").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(PulseTheme.textPrimary)
                Text(model)
                    .pulseText(.secondary)
                    .textCase(.uppercase)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            ZStack(alignment: .bottom) {
                Capsule().fill(PulseTheme.track)
                Capsule().fill(low ? PulseTheme.recoveryLow : PulseTheme.positive)
                    .frame(height: 150 * fraction)
            }
            .frame(width: 6, height: 150)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(model) battery"))
        .accessibilityValue(fraction > 0 ? String(localized: "\(percentText) percent\(charging ? ", charging" : "")")
                                         : String(localized: "No reading yet"))
    }

    private var pct: Double? {
        if case .charge(let pct, _, _) = display { return pct }
        return nil
    }

    private var charging: Bool {
        switch display {
        case .charge(_, let charging, _): return charging
        case .pending(let charging): return charging
        default: return false
        }
    }

    private var percentText: String { pct.map { "\(Int($0.rounded()))" } ?? "--" }
    private var fraction: CGFloat { CGFloat(max(0, min(100, pct ?? 0)) / 100) }
    /// ZENO's low-battery threshold, as the Home chip colours it.
    private var low: Bool { (pct ?? 100) <= 15 && !charging }
}

// MARK: - Broadcast

/// The pinned card's slot: shown while the strap is connected (onboarding/43a shows PAIR A DEVICE, not the
/// card, while it is not). A leaf, so the link's ticks re-render only this.
private struct DeviceBroadcastSlot: View {
    @EnvironmentObject private var live: LiveState

    var body: some View {
        if live.connected || Self.isDemo {
            DeviceBroadcastCard()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
    }

    private static var isDemo: Bool {
        #if DEBUG
        return DemoSyncHarness.active
        #else
        return false
        #endif
    }
}

/// BROADCAST HEART RATE pinned at the foot of STATUS (spec §3.32 [Z]): the phone advertises the standard
/// Heart Rate Service with the strap's live heart rate (`HrBroadcaster`, the Data Sources switch's key),
/// while this screen is open, and below it the experimental strap-side switch.
private struct DeviceBroadcastCard: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var model: AppModel
    @AppStorage(HrBroadcaster.defaultsKey) private var broadcastEnabled = false
    @AppStorage(PuffinExperiment.broadcastHrKey) private var strapBroadcastEnabled = false
    @StateObject private var broadcaster: HrBroadcaster
    private let sink: LogSink

    /// Forwards the broadcaster's "HR-out:" lifecycle lines into the strap log, as Data Sources does.
    private final class LogSink { weak var live: LiveState? }

    init() {
        let sink = LogSink()
        self.sink = sink
        _broadcaster = StateObject(wrappedValue: HrBroadcaster(log: { [weak sink] line in
            MainActor.assumeIsolated { sink?.live?.append(log: line) }
        }))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(broadcastEnabled ? PulseTheme.strain : Color.white.opacity(0.12))
                    Image(systemName: "heart.fill").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Broadcast heart rate"))
                        .modifier(MoreLabelText(tracking: 1.4))
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(statusLine)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
                Spacer(minLength: 8)
                Toggle(String(localized: "Broadcast heart rate"), isOn: $broadcastEnabled)
                    .labelsHidden()
                    .tint(PulseTheme.positive)
            }
            .padding(.vertical, 14)
            if live.connected {
                PulseDivider()
                Toggle(isOn: $strapBroadcastEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Broadcast from the strap (experimental)"))
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
                .tint(PulseTheme.positive)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.cardSolidTop))
        .onAppear {
            sink.live = live
            broadcaster.bind(to: live)
            if broadcastEnabled { broadcaster.start() }
        }
        .onDisappear { broadcaster.stop() }
        .onChange(of: broadcastEnabled) { _, on in
            if on { broadcaster.start() } else { broadcaster.stop() }
        }
        .onChange(of: strapBroadcastEnabled) { _, on in model.ble.setBroadcastHr(on) }
    }

    /// What the phone-side broadcast is doing right now, never a fabricated "connected".
    private var statusLine: String {
        guard broadcastEnabled else { return String(localized: "To compatible apps & devices") }
        if let note = broadcaster.statusNote { return note }
        if broadcaster.subscriberCount > 0 {
            return broadcaster.subscriberCount == 1 ? String(localized: "1 device reading")
                                                    : String(localized: "\(broadcaster.subscriberCount) devices reading")
        }
        return broadcaster.advertising ? String(localized: "On while this screen is open") : String(localized: "Starting…")
    }
}

// MARK: - ⓘ

private struct DeviceInfoSheet: View {
    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: String(localized: "Your strap")) {
                ForEach(Self.items, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0).modifier(MoreLabelText()).foregroundStyle(PulseTheme.textPrimary)
                        Text(item.1)
                            .pulseText(.subtitle)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 10)
                }
            }
            .environment(\.pulseModalRoot, true)
        }
    }

    private static let items: [(String, String)] = [
        (String(localized: "Connection"), String(localized: "ZENO talks to your strap directly over Bluetooth. There is no WHOOP account and no cloud: if the strap is near and awake, ZENO connects on its own.")),
        (String(localized: "Sync"), String(localized: "The strap stores its data while you are away and sends it when it reconnects. CATCHING UP means that history is arriving now.")),
        (String(localized: "Battery"), String(localized: "The level is the strap's own reading. ZENO can remind you to charge before bed in App Settings › Notifications.")),
        (String(localized: "Broadcast heart rate"), String(localized: "Shares your live heart rate as a standard Bluetooth heart-rate sensor, so a treadmill, a bike computer or a fitness app can read it. Local Bluetooth only.")),
    ]
}
#endif
