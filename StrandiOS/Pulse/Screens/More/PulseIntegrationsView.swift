#if os(iOS)
import SwiftUI
import StrandDesign

/// INTEGRATIONS (WHOOP_UI_SPEC §3.33, health-more-2026/08b): "‹ INTEGRATIONS", a featured APPLE HEALTH
/// card, then the sources ZENO reads and the ways it shares. Every row opens the screen that does the
/// work today; Apple Health has its own page in Pulse's look.
struct PulseIntegrationsView: View {
    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var health: HealthKitBridge

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Integrations"), spacing: MoreLayout.sectionGap) {
            Button { navigator.open(PulseAppleHealthRoute().route) } label: { featuredCard }
                .buttonStyle(PulsePressStyle())
            MoreSection(String(localized: "Bring data in")) {
                MoreLinkRow(.classic(.dataSources), symbol: "externaldrive", title: String(localized: "Data sources"),
                            subtitle: String(localized: "WHOOP export, Mi Fitness, files"))
                MoreLinkRow(.classic(.miBand), symbol: "figure.walk.motion", title: String(localized: "Mi Band"))
            }
            MoreSection(String(localized: "Share data out")) {
                MoreLinkRow(.classic(.shortcutsExport), symbol: "square.and.arrow.up.on.square",
                            title: String(localized: "Shortcuts export"),
                            subtitle: String(localized: "Strap data into Apple Health"))
                MoreLinkRow(PulseRoute.deviceSettings.forExistingEntryPoint, symbol: "dot.radiowaves.left.and.right",
                            title: String(localized: "Heart rate broadcast"),
                            subtitle: String(localized: "To gym kit and fitness apps"))
            }
        }
    }

    /// APPLE HEALTH on a dark gradient card with a status mark, the featured card at the top.
    private var featuredCard: some View {
        HStack(spacing: 14) {
            MoreHealthGlyph(size: 34)
            Text(String(localized: "Apple Health"))
                .modifier(MoreLabelText())
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            if health.auth == .authorized {
                PulseStatusBadge(.check, tint: .teal)
                    .accessibilityLabel(String(localized: "Connected"))
            }
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            shape.fill(LinearGradient(colors: [PulseTheme.rowCardTop, PulseTheme.bannerWell.opacity(0.6)],
                                      startPoint: .topTrailing, endPoint: .bottomLeading))
                .overlay(shape.strokeBorder(PulseTheme.divider, lineWidth: 1))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// A white rounded tile with a red heart: the generic sign for health data (an SF Symbol, not Apple's
/// app icon artwork).
struct MoreHealthGlyph: View {
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(ProfileArtPalette.healthHeart)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous).fill(Color.white))
            .accessibilityHidden(true)
    }
}

/// APPLE HEALTH (health-more-2026/08c): the connection graphic, the data it moves, "CONNECT TO APPLE
/// HEALTH" with its two paragraphs, and a green pill pinned at the foot: CONNECT before permission, SYNC
/// NOW after. It runs the same calls as the classic Apple Health screen (authorise, sync, refresh), and
/// says so plainly when this build cannot reach Health at all.
struct PulseAppleHealthIntegrationView: View {
    @EnvironmentObject private var health: HealthKitBridge
    @EnvironmentObject private var model: AppModel

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Apple Health"), spacing: 28) {
            connectionGraphic
                .padding(.top, 24)
            typeTiles
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Connect to Apple Health"))
                    .modifier(MoreLabelText())
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(paragraphs, id: \.self) { text in
                    Text(text)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let error = health.lastError {
                    Text(error)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.recoveryLowText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            PulseLink(.classic(.appleHealth)) {
                MoreArrowLabel(String(localized: "See your Apple Health data"))
            }
            .buttonStyle(PulsePressStyle())
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let action = primaryAction {
                Button(action: action.run) {
                    Text(action.title)
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(PulseTheme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Capsule(style: .circular).fill(PulseTheme.positive))
                        .opacity(health.syncing ? 0.5 : 1)
                }
                .buttonStyle(PulsePressStyle())
                .disabled(health.syncing)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            }
        }
    }

    /// The heart tile joined to ZENO's tile by a dotted line.
    private var connectionGraphic: some View {
        HStack(spacing: 14) {
            MoreHealthGlyph(size: 64)
            HStack(spacing: 5) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle().fill(PulseTheme.textTertiary).frame(width: 4, height: 4)
                }
            }
            ZStack {
                RoundedRectangle(cornerRadius: MoreLayout.healthTileRadius, style: .continuous)
                    .fill(ProfileArtPalette.zenoTile)
                PulseZenoMonogramShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 26, height: 26)
            }
            .frame(width: 64, height: 64)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    /// The kinds of data that move, each one `HealthKitBridge` reads or writes: workouts, heart rate,
    /// sleep, steps and respiratory rate. (ZENO moves no mindful minutes.)
    private var typeTiles: some View {
        HStack(spacing: 12) {
            ForEach(["figure.run", "heart", "bed.double", "shoeprints.fill", "lungs"], id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular).fill(PulseTheme.card))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Workouts, heart rate, sleep, steps and respiratory rate"))
    }

    private var paragraphs: [String] {
        switch health.auth {
        case .unavailable:
            return [String(localized: "Apple Health isn't available on this device.")]
        case .entitlementMissing:
            return [String(localized: "This install can't connect to Apple Health directly: it was signed without Apple's Health permission, so ZENO can't appear under Settings › Health."),
                    String(localized: "To bring Health data in anyway, import a Health export in Data sources, or turn on Shortcuts export to send your strap data into Health.")]
        case .authorized:
            let last = health.lastSync.map { $0.formatted(.relative(presentation: .named)) }
            return [last.map { String(localized: "Connected. Last synced \($0).") }
                    ?? String(localized: "Connected. New strap data is written to Health automatically, with background refresh when iOS allows it."),
                    String(localized: "To change what ZENO reads or writes, open the Health app › Sharing › Apps › ZENO.")]
        case .unknown, .denied:
            var out = [String(localized: "ZENO reads your heart rate, HRV, blood oxygen, sleep, steps and energy from Apple Health, and writes your strap's sleep, heart rate, workouts and nightly vitals back."),
                       String(localized: "Everything stays on this iPhone.")]
            if health.auth == .denied {
                out.append(String(localized: "If no prompt appears, turn ZENO on under Settings › Health › Data Access & Devices."))
            }
            return out
        }
    }

    private var primaryAction: (title: String, run: () -> Void)? {
        switch health.auth {
        case .unknown, .denied:
            return (String(localized: "Connect"), { Task { await connect() } })
        case .authorized:
            return (health.syncing ? String(localized: "Syncing…") : String(localized: "Sync now"), { Task { await sync() } })
        case .unavailable, .entitlementMissing:
            return nil
        }
    }

    /// The classic screen's connect: ask, then sync and refresh.
    private func connect() async {
        await health.requestAuthorization()
        await sync()
    }

    private func sync() async {
        await HealthSyncRefreshCoordinator.run(
            sync: { await health.sync() },
            refresh: { await model.refreshAfterAppleHealthSync(authorized: health.auth == .authorized) })
    }
}
#endif
