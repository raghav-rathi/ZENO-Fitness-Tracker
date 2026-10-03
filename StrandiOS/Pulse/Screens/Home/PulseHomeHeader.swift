#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Header (WHOOP_UI_SPEC §1.4)

/// The header row: a 32 pt row starting at the safe-area top. At the left the avatar (→ Profile, pushed)
/// with the day-streak pill tucked under it (→ Day Streak, pushed; today only), the "‹ TODAY ›" pager in
/// the centre (its label opens the calendar), the strap's battery and status at the right (→ Device
/// Settings), its glyph 23 pt from the screen edge. Hit areas stay 44 pt; they overflow the row.
struct PulseHomeHeader: View {
    /// The calendar sheet, held by Home so its tilt mode knows when the sheet is up.
    @Binding var showCalendar: Bool

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if let streak = model.home?.streak, model.home?.day.isToday == true, streak > 0 {
                        Button { navigator.open(.dayStreak) } label: {
                            PulseStreakPill(days: streak)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .padding(.leading, PulseTheme.Header.avatar / 2)
                        .accessibilityHint(String(localized: "Opens your day streak"))
                        .transition(.opacity)
                    }
                    PulseAvatarButton { navigator.open(.profile) }
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
}

/// The wearer's avatar (31 pt): the photo, else the initials of the name Edit Profile stores on their
/// colour disc, else a person outline on white 10%, exactly as Profile draws it. Ringed in the page
/// colour so it reads apart from the streak pill under it.
struct PulseAvatarButton: View {
    let action: () -> Void
    @EnvironmentObject private var profile: ProfileStore
    /// Observed so the initials follow an edit; read through `PulseProfileIdentity.storedName`, the
    /// trimmed name Profile shows.
    @AppStorage(PulseProfileIdentity.nameKey) private var storedName = ""

    var body: some View {
        Button(action: action) {
            PulseAvatar(imageData: profile.avatarImageData, name: PulseProfileIdentity.storedName,
                        size: PulseTheme.Header.avatar)
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

/// The one status banner under the header, today only, in priority order: CATCHING UP… while history is
/// still on its way, DATA CAUGHT UP · SYNCED TO <time> for 8 s after a sync that really finished, STRAP OFF
/// WRIST, then LOW STRAP BATTERY (≤ 15%, dismissible for the day). Its own leaf because `LiveState`
/// publishes constantly; the banner below redraws only when what it shows changes.
struct PulseHomeStatusBanner: View {
    @EnvironmentObject private var live: LiveState

    var body: some View {
        PulseHomeStatusBannerContent(state: .init(connected: live.connected || PulseHomeBannerDebug.forced != nil,
                                                  backfilling: live.backfilling,
                                                  historyPending: live.historyPendingSync,
                                                  syncFailed: live.lastSyncError != nil,
                                                  worn: live.worn,
                                                  battery: live.activeIsWhoop ? live.batteryPct : nil,
                                                  charging: live.charging ?? false,
                                                  lastSyncedAt: live.lastSyncedAt))
            .equatable()
    }
}

/// What the banner reads from the strap.
struct PulseStrapBannerState: Equatable {
    let connected: Bool
    /// An offload is running (`LiveState.backfilling`).
    let backfilling: Bool
    /// The strap holds records newer than the ones banked (`LiveState.historyPendingSync`): set between
    /// BLEManager's back-to-back auto-continue passes and right after connecting, before an offload starts.
    let historyPending: Bool
    /// The last offload ended abnormally (`LiveState.lastSyncError`).
    let syncFailed: Bool
    let worn: Bool
    let battery: Double?
    let charging: Bool
    /// The last offload that reached HISTORY_COMPLETE (the only end BLEManager stamps): an abort, a
    /// timeout or a disconnect leaves it alone.
    let lastSyncedAt: TimeInterval?

    /// More history is still on its way: the classic Today's "syncing" rule (`backfilling ||
    /// historyPendingSync`), so the two screens never disagree on it.
    var catchingUp: Bool { backfilling || historyPending }
}

private struct PulseHomeStatusBannerContent: View, Equatable {
    let state: PulseStrapBannerState

    /// A fresh HISTORY_COMPLETE stamp waiting out `settleSeconds`: BLEManager decides whether more history
    /// is pending (and re-kicks the next pass) just after it stamps, so the stamp alone does not yet mean
    /// caught up. CATCHING UP… stays up meanwhile.
    @State private var settling: TimeInterval?
    /// The stamp DATA CAUGHT UP names, during its 8 s window.
    @State private var caughtUp: TimeInterval?
    /// The day the low-battery banner was dismissed ("yyyy-MM-dd").
    @AppStorage("pulse.home.lowBatteryDismissed") private var lowBatteryDismissed = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func == (lhs: PulseHomeStatusBannerContent, rhs: PulseHomeStatusBannerContent) -> Bool {
        lhs.state == rhs.state
    }

    /// ZENO's low-battery threshold (the header's battery figure turns red at the same point).
    private static let lowBattery = 15.0
    private static let caughtUpSeconds: TimeInterval = 8
    private static let settleSeconds: TimeInterval = 2
    /// A stamp older than this when it reaches the banner is a restored one (the launch seed from the last
    /// session), not a sync that just finished.
    private static let freshStamp: TimeInterval = 30

    private var todayKey: String { Repository.localDayKey(Date()) }

    private var kind: PulseStatusBanner.Kind? {
        #if DEBUG
        if let forced = PulseHomeBannerDebug.forced { return forced }
        #endif
        guard state.connected else { return nil }
        if state.catchingUp || settling != nil { return .catchingUp(progress: nil) }
        // Caught up only while the stamp it names is still the latest, nothing is pending and the offload
        // ended cleanly; the time is that stamp's, the one clock the fact comes from.
        if let caughtUp, caughtUp == state.lastSyncedAt, !state.syncFailed {
            return .caughtUp(syncedTo: PulseFormat.clock(Date(timeIntervalSince1970: caughtUp)))
        }
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
        .onChange(of: state.lastSyncedAt) { old, new in
            // Only a HISTORY_COMPLETE moves the stamp; a restored one is not a sync that just finished.
            guard let new, new != old, abs(Date().timeIntervalSince1970 - new) < Self.freshStamp else { return }
            caughtUp = nil
            settling = new
        }
        .onChange(of: state.catchingUp) { _, busy in
            // Another pass started (or more turned out to be pending): this stamp was not the end.
            if busy {
                settling = nil
                caughtUp = nil
            }
        }
        .task(id: settling) {
            guard let stamp = settling else { return }
            try? await Task.sleep(for: .seconds(Self.settleSeconds))
            guard !Task.isCancelled else { return }
            settling = nil
            caughtUp = stamp
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
