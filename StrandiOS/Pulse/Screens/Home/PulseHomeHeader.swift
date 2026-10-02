#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Header (WHOOP_UI_SPEC §1.4)

/// The header row: a 32 pt row starting at the safe-area top. At the left the avatar (→ Profile) with the
/// day-streak pill tucked under it (→ Day Streak; today only), the "‹ TODAY ›" pager in the centre (its
/// label opens the calendar), the strap's battery and status at the right (→ Device Settings), its glyph
/// 23 pt from the screen edge. Hit areas stay 44 pt; they overflow the row.
struct PulseHomeHeader: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var showCalendar = false

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if let streak = model.home?.streak, model.home?.day.isToday == true, streak > 0 {
                        Button { openKeepingClassicModal(PulseRoute.dayStreak.forExistingEntryPoint) } label: {
                            PulseStreakPill(days: streak)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .padding(.leading, PulseTheme.Header.avatar / 2)
                        .accessibilityHint(String(localized: "Opens your day streak"))
                        .transition(.opacity)
                    }
                    PulseAvatarButton { openKeepingClassicModal(PulseRoute.profile.forExistingEntryPoint) }
                }
                Spacer(minLength: 0)
                // Device Settings is a full-screen modal (§1.6); its classic stand-in opens as a sheet.
                PulseStrapChip { navigator.present(PulseRoute.deviceSettings.forExistingEntryPoint) }
                    .padding(.trailing, PulseTheme.Header.strapTrailing - PulseTheme.Layout.pageMargin)
            }
            PulseDayPager(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                          canGoBack: model.dayOffset < model.maxDayOffset,
                          canGoForward: model.dayOffset > 0,
                          onBack: { model.stepDay(1) },
                          onForward: { model.stepDay(-1) },
                          onTitleTap: { showCalendar = true })
        }
        .frame(height: PulseTheme.Header.homeRow)
        .pulseAnimation(PulseMotion.chrome, value: model.home?.day.isToday)
        .sheet(isPresented: $showCalendar) {
            PulseCalendarSheet()
        }
    }

    /// Opens a rebuilt Pulse screen the way the spec presents it (Profile and Day Streak push), and its
    /// classic stand-in modally with "Done", as the header always opened it.
    private func openKeepingClassicModal(_ route: PulseRoute) {
        if route.isClassic { navigator.present(route) } else { navigator.open(route) }
    }
}

/// The wearer's avatar (31 pt; the photo, else a person outline on white 10%), ringed in the page colour
/// so it reads apart from the streak pill under it.
struct PulseAvatarButton: View {
    let action: () -> Void
    @EnvironmentObject private var profile: ProfileStore

    var body: some View {
        Button(action: action) {
            PulseAvatar(imageData: profile.avatarImageData, name: nil, size: PulseTheme.Header.avatar)
                .background(Circle().fill(PulseTheme.pageTop).padding(-1.5))
                .padding((PulseTheme.Layout.minTapTarget - PulseTheme.Header.avatar) / 2)
                .contentShape(Rectangle())
                .padding(-(PulseTheme.Layout.minTapTarget - PulseTheme.Header.avatar) / 2)
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Profile"))
    }
}

// MARK: - Status banner (§3.1 item 2, §2.9 "Syncing", "Off wrist")

/// The one status banner under the header, today only, in priority order: CATCHING UP… while the strap
/// backfills history, DATA CAUGHT UP · SYNCED TO <time> for 8 s after a sync finishes, STRAP OFF WRIST,
/// then LOW STRAP BATTERY (≤ 15%, dismissible for the day). Its own leaf because `LiveState` publishes
/// constantly; the banner below redraws only when what it shows changes.
struct PulseHomeStatusBanner: View {
    @EnvironmentObject private var live: LiveState

    var body: some View {
        PulseHomeStatusBannerContent(state: .init(connected: live.connected || PulseHomeBannerDebug.forced != nil,
                                                  backfilling: live.backfilling, worn: live.worn,
                                                  battery: live.activeIsWhoop ? live.batteryPct : nil,
                                                  charging: live.charging ?? false,
                                                  lastSyncedAt: live.lastSyncedAt))
            .equatable()
    }
}

/// What the banner reads from the strap.
struct PulseStrapBannerState: Equatable {
    let connected: Bool
    let backfilling: Bool
    let worn: Bool
    let battery: Double?
    let charging: Bool
    let lastSyncedAt: TimeInterval?
}

private struct PulseHomeStatusBannerContent: View, Equatable {
    let state: PulseStrapBannerState

    /// The sync that just finished, while its 8 s "caught up" window is open.
    @State private var caughtUp: Date?
    @State private var lastBackfilling = false
    /// The day the low-battery banner was dismissed ("yyyy-MM-dd").
    @AppStorage("pulse.home.lowBatteryDismissed") private var lowBatteryDismissed = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func == (lhs: PulseHomeStatusBannerContent, rhs: PulseHomeStatusBannerContent) -> Bool {
        lhs.state == rhs.state
    }

    /// ZENO's low-battery threshold (the header's battery figure turns red at the same point).
    private static let lowBattery = 15.0
    private static let caughtUpSeconds: TimeInterval = 8

    private var todayKey: String { Repository.localDayKey(Date()) }

    private var kind: PulseStatusBanner.Kind? {
        #if DEBUG
        if let forced = PulseHomeBannerDebug.forced { return forced }
        #endif
        guard state.connected else { return nil }
        if state.backfilling { return .catchingUp(progress: nil) }
        if let caughtUp { return .caughtUp(syncedTo: PulseFormat.clock(caughtUp)) }
        if !state.worn { return .offWrist }
        if let battery = state.battery, !state.charging, battery <= Self.lowBattery, lowBatteryDismissed != todayKey {
            return .lowBattery(percent: Int(battery.rounded()))
        }
        return nil
    }

    var body: some View {
        Group {
            if let kind {
                PulseStatusBanner(kind, onDismiss: dismissAction(kind))
                    .padding(.top, PulseHomeLayout.bannerTop)
                    // The wordmark under a banner sits closer than under the header row (27 vs 31 pt).
                    .padding(.bottom, PulseHomeLayout.wordmarkAfterBanner - PulseTheme.Header.wordmarkTop)
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion), value: kind)
        .onChange(of: state.backfilling) { was, now in
            // A backfill that just ended opens the 8 s "caught up" window.
            if was && !now { caughtUp = Date() }
        }
        .task(id: caughtUp) {
            guard caughtUp != nil else { return }
            try? await Task.sleep(for: .seconds(Self.caughtUpSeconds))
            guard !Task.isCancelled else { return }
            caughtUp = nil
        }
    }

    private func dismissAction(_ kind: PulseStatusBanner.Kind) -> (() -> Void)? {
        guard case .lowBattery = kind else { return nil }
        return { lowBatteryDismissed = todayKey }
    }
}

/// DEBUG `--pulse-banner caught-up|catching-up|off-wrist|low-battery`: show that banner for a capture.
enum PulseHomeBannerDebug {
    static var forced: PulseStatusBanner.Kind? {
        #if DEBUG
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-banner"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "caught-up": return .caughtUp(syncedTo: PulseFormat.clock(Date().addingTimeInterval(-60)))
        case "catching-up": return .catchingUp(progress: nil)
        case "off-wrist": return .offWrist
        case "low-battery": return .lowBattery(percent: 12)
        default: return nil
        }
        #else
        return nil
        #endif
    }
}

/// Home's own spacing around a status banner, measured on help-center/91 and health-more-2026/23.
enum PulseHomeLayout {
    /// From the header row to the banner.
    static let bannerTop: CGFloat = 20
    /// From the banner to the wordmark's frame.
    static let wordmarkAfterBanner: CGFloat = 27
}

// MARK: - Calendar

/// The day picker: a graphical calendar bounded by the earliest banked day and today (ZENO extra).
struct PulseCalendarSheet: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { model.selectedLogicalDate },
                    set: { picked in
                        model.pick(date: picked)
                        dismiss()
                    }),
                in: model.earliestLogicalDate...Repository.logicalDay(Date()),
                displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(PulseTheme.accent)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle(String(localized: "Pick a day"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "Done")) { dismiss() }
                            .foregroundStyle(PulseTheme.accent)
                    }
                }
                .background(PulseTheme.wheelSheet.ignoresSafeArea())
        }
        .presentationDetents([.medium, .large])
        .environment(\.colorScheme, .dark)
    }
}
#endif
