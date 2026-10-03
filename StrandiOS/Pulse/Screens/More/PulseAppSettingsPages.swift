#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - App Settings pages (WHOOP_UI_SPEC §3.33)
//
// Each page binds the keys the classic Settings and Automations screens already write, and repeats what
// those screens do when a switch moves (asking for notification permission, re-evaluating the illness
// watch, refreshing the cycle signals), so a switch here behaves exactly like its classic twin. Nothing
// is stored under a new key.

// MARK: Units

/// UNITS (the probable 5-letter App Settings row, §3.33 [Z]): body measurements, exercise distance,
/// temperature, skin temperature and the clock. Display-only: stored data never changes.
struct PulseUnitsView: View {
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""
    @AppStorage(UnitPrefs.skinTempDisplayKey) private var skinTempDisplayRaw = ""
    @AppStorage(ClockFormatPreference.defaultsKey) private var clockFormatRaw = ClockFormatPreference.system.rawValue

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }

    /// Exercise distance follows body measurements until chosen separately (`UnitPrefs.resolveDistance`).
    private var distanceBinding: Binding<String> {
        Binding(get: { UnitPrefs.resolveDistance(system: unitSystem, override: distanceSystemRaw).rawValue },
                set: { distanceSystemRaw = $0 })
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Units"), spacing: MoreLayout.sectionGap) {
            MoreSection(nil) {
                PulseMenuRow(symbol: "scalemass", title: String(localized: "Body measurements"),
                             selection: $unitSystemRaw,
                             options: [(UnitSystem.metric.rawValue, String(localized: "Metric (kg, cm)")),
                                       (UnitSystem.imperial.rawValue, String(localized: "Imperial (lb, ft)"))])
                PulseMenuRow(symbol: "figure.run", title: String(localized: "Distance & pace"),
                             selection: distanceBinding,
                             options: [(UnitSystem.metric.rawValue, String(localized: "Kilometres")),
                                       (UnitSystem.imperial.rawValue, String(localized: "Miles"))])
                PulseMenuRow(symbol: "thermometer.medium", title: String(localized: "Temperature"),
                             selection: $temperatureRaw,
                             options: [("", String(localized: "Follow body")),
                                       (TemperatureUnit.celsius.rawValue, "°C"),
                                       (TemperatureUnit.fahrenheit.rawValue, "°F")])
                PulseMenuRow(symbol: "hand.raised", title: String(localized: "Skin temperature"),
                             selection: $skinTempDisplayRaw,
                             options: [("", String(localized: "Temperature")),
                                       (SkinTempDisplay.Kind.deviation.rawValue, String(localized: "vs baseline"))])
                PulseMenuRow(symbol: "clock", title: String(localized: "Clock"),
                             selection: $clockFormatRaw,
                             options: [(ClockFormatPreference.system.rawValue, String(localized: "System")),
                                       (ClockFormatPreference.twelveHour.rawValue, String(localized: "12-hour")),
                                       (ClockFormatPreference.twentyFourHour.rawValue, String(localized: "24-hour"))])
            }
            MoreHelpText(String(localized: "Units only change how numbers are shown. Everything is stored the same way."))
        }
        // The resolved clock is memoised (#1829): drop the memo so the change shows at once.
        .onChange(of: clockFormatRaw) { _, _ in AppClock.invalidate() }
    }
}

/// A settings row whose value opens a menu of options (UNITS).
struct PulseMenuRow: View {
    let symbol: String?
    let title: String
    @Binding var selection: String
    let options: [(value: String, label: String)]

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
        } label: {
            MoreListRow(symbol: symbol, title: title, trailing: .value(currentLabel))
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityValue(currentLabel)
    }

    private var currentLabel: String {
        options.first { $0.value == selection }?.label ?? options.first?.label ?? ""
    }
}

// MARK: Notifications

/// NOTIFICATIONS: the strap's wrist alerts, the notifications ZENO can post, the Lock Screen activities,
/// and Automations folded in (§3.33 [Z]). The morning brief lives with the Coach's settings.
struct PulseNotificationsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseNavigator) private var navigator
    @AppStorage("notif.masterEnabled") private var wristAlertsMaster = false
    @AppStorage(UnitPrefs.liveActivityKey) private var liveActivityEnabled = true
    @AppStorage(UnitPrefs.liftLiveActivityKey) private var liftLiveActivityEnabled = true
    @AppStorage(UnitPrefs.syncLiveActivityKey) private var syncLiveActivityEnabled = true
    @State private var showCoachSettings = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Notifications"), spacing: MoreLayout.sectionGap) {
            MoreSection(String(localized: "On your phone")) {
                MoreToggleRow(title: String(localized: "Illness heads-up"), isOn: $behavior.illnessWatch,
                              help: String(localized: "When two or more of your signals drift from your 28-day baseline together. Needs 14 days of history; at most once a day."))
                    .onChange(of: behavior.illnessWatch) { _, on in
                        model.reevaluateIllness()
                        if on { IllnessNotifier.requestAuthorization() }
                    }
                MoreToggleRow(title: String(localized: "Strain target reached"), isOn: $behavior.strainTargetNudge,
                              help: String(localized: "Once a day, when your Strain reaches the low end of today's optimal range. Posts after the strap syncs."))
                    .onChange(of: behavior.strainTargetNudge) { _, on in
                        if on {
                            StrainTargetNotifier.requestAuthorization()
                            model.evaluateStrainTarget()
                        }
                    }
                MoreToggleRow(title: String(localized: "Strap battery"), isOn: $behavior.batteryAlerts,
                              help: String(localized: "A reminder to charge before bed at 15%, and a heads-up when it is full."))
                    .onChange(of: behavior.batteryAlerts) { _, on in
                        if on { BatteryNotifier.requestAuthorization() }
                    }
                if coach.availability != .off {
                    MoreButtonRow(symbol: nil, title: String(localized: "Morning brief"),
                                  subtitle: String(localized: "A line from your Coach each morning"),
                                  trailing: .value(CoachBriefScheduler.isEnabled ? String(localized: "On")
                                                                                 : String(localized: "Off"))) {
                        showCoachSettings = true
                    }
                }
            }
            MoreSection(String(localized: "On your wrist")) {
                MoreToggleRow(title: String(localized: "Wrist alerts"), isOn: $wristAlertsMaster,
                              help: String(localized: "The master switch for every strap buzz: inactivity, stress and alerts. Off keeps the strap quiet."))
            }
            MoreSection(String(localized: "Lock Screen")) {
                MoreToggleRow(title: String(localized: "Live heart rate"), isOn: $liveActivityEnabled,
                              help: String(localized: "While the strap is connected."))
                MoreToggleRow(title: String(localized: "Lift log session"), isOn: $liftLiveActivityEnabled,
                              help: String(localized: "Your set, rest and heart rate during a session."))
                MoreToggleRow(title: String(localized: "Strap sync"), isOn: $syncLiveActivityEnabled,
                              help: String(localized: "Progress while ZENO pulls history from the strap."))
            }
            MoreSection(String(localized: "More")) {
                MoreLinkRow(PulseRoute.sleepPlanner.forExistingEntryPoint, symbol: "alarm",
                            title: String(localized: "Alarm & wind-down"))
                MoreLinkRow(.classic(.automations), symbol: "wand.and.stars", title: String(localized: "Automations"),
                            subtitle: String(localized: "Double-tap, haptics, inactivity"))
            }
        }
        .sheet(isPresented: $showCoachSettings) {
            CoachSettingsView()
        }
    }
}

// MARK: Journal

/// JOURNAL: whether Home shows the MY JOURNAL card, and the way into the journal itself.
struct PulseJournalSettingsView: View {
    @AppStorage(PuffinExperiment.journalReminderKey) private var journalReminder = true

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Journal"), spacing: MoreLayout.sectionGap) {
            MoreSection(nil) {
                MoreToggleRow(title: String(localized: "Journal on Home"), isOn: $journalReminder,
                              help: String(localized: "Shows MY JOURNAL on Home with the week's logged days, as a reminder to answer today's questions."))
                MoreLinkRow(PulseRoute.journal(dayOffset: nil).forExistingEntryPoint, symbol: "square.and.pencil",
                            title: String(localized: "Open journal"))
            }
        }
    }
}

// MARK: Hormonal insights

/// HORMONAL INSIGHTS: cycle awareness, offered to the profiles it applies to (it reads the menstrual
/// skin-temperature shift), and its "not for me" switch, exactly as Automations writes them.
struct PulseHormonalInsightsView: View {
    @EnvironmentObject private var profile: ProfileStore
    @AppStorage(AppModel.cycleAwarenessKey) private var cycleAwareness = false
    @AppStorage(AppModel.cycleAwarenessHiddenKey) private var cycleHidden = false
    @EnvironmentObject private var model: AppModel

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Hormonal insights"), spacing: MoreLayout.sectionGap) {
            if profile.cycleAwarenessApplies {
                MoreSection(nil) {
                    PulseCycleVisibilityToggle()
                    if !cycleHidden {
                        MoreToggleRow(title: String(localized: "Cycle awareness"), isOn: $cycleAwareness,
                                      help: String(localized: "Reads a coarse cycle phase from your nightly skin temperature, on this iPhone. Awareness only: not contraception, not a fertility predictor, not a medical service."))
                            .onChange(of: cycleAwareness) { _, on in
                                model.cycleAwarenessEnabled = on
                                Task { await model.refreshV5Signals() }
                            }
                    }
                }
            } else {
                MorePageIntro(text: String(localized: "Cycle insights read the menstrual temperature shift, so they are offered for female and non-binary profiles. Change your sex in Edit Profile."))
            }
        }
    }
}

/// "Show cycle insights": the user's own "not for me" switch. Hiding also stops tracking, as the classic
/// Automations switch does; showing only re-offers it.
struct PulseCycleVisibilityToggle: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage(AppModel.cycleAwarenessKey) private var cycleAwareness = false
    @AppStorage(AppModel.cycleAwarenessHiddenKey) private var cycleHidden = false
    var title: String = String(localized: "Show cycle insights")

    var body: some View {
        MoreToggleRow(title: title,
                      isOn: Binding(get: { !cycleHidden },
                                    set: { show in
                                        cycleHidden = !show
                                        if !show {
                                            cycleAwareness = false
                                            model.cycleAwarenessEnabled = false
                                            Task { await model.refreshV5Signals() }
                                        }
                                    }),
                      help: String(localized: "Turn off to hide the cycle cards everywhere. A private choice, never based on your age."))
    }
}

// MARK: Hide metrics

/// HIDE METRICS: only the switches that really hide a feature today. WHOOP's Recovery & Sleep, Weight
/// and Healthspan switches (and ZENO's planned Stress one) need every screen to honour one key, which
/// does not exist yet, so they are not offered as switches that would do nothing.
struct PulseHideMetricsView: View {
    @EnvironmentObject private var profile: ProfileStore
    @AppStorage(HydrationStore.enabledKey) private var hydrationEnabled = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Hide metrics"), spacing: MoreLayout.sectionGap) {
            MorePageIntro(text: String(localized: "Hide a feature's cards. ZENO keeps recording underneath, so turning one back on shows everything since."))
            MoreSection(nil) {
                if profile.cycleAwarenessApplies {
                    PulseCycleVisibilityToggle()
                }
                MoreToggleRow(title: String(localized: "Show hydration"), isOn: $hydrationEnabled,
                              help: String(localized: "The water log and its daily goal. Off by default."))
            }
            if PulseCustomizeDashboardView.isRebuilt {
                MoreSection(nil) {
                    MoreLinkRow(.customizeDashboard, symbol: "square.grid.2x2",
                                title: String(localized: "My Dashboard"),
                                subtitle: String(localized: "Choose the metrics Home shows"))
                }
            }
        }
    }
}

// MARK: Activity settings

/// ACTIVITY SETTINGS: activity detection, keeping the screen on during a workout, and HEART RATE SETTINGS
/// (resting and max heart rate, and the zones built from them).
struct PulseActivitySettingsView: View {
    @EnvironmentObject private var profile: ProfileStore
    @AppStorage(PuffinExperiment.autoDetectWorkoutsKey) private var autoDetect = false
    @AppStorage("workoutKeepScreenOn") private var keepScreenOn = false
    @State private var editingMaxHR = false
    @State private var maxHRDraft = 0

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Activity settings"), spacing: MoreLayout.sectionGap) {
            MoreSection(nil) {
                MoreToggleRow(title: String(localized: "Activity detection"),
                              isOn: $autoDetect,
                              help: String(localized: "After a sync, ZENO looks for a sustained rise in heart rate and offers to save it as an activity. It only suggests."))
                MoreToggleRow(title: String(localized: "Keep screen on"), isOn: $keepScreenOn,
                              help: String(localized: "Holds the screen awake while a workout records, so your live heart rate stays visible."))
            }
            VStack(alignment: .leading, spacing: 16) {
                MoreSectionHeader(String(localized: "Heart rate settings"))
                MorePageIntro(title: String(localized: "Heart Rate Zones"),
                              text: profile.hasCustomHRZones
                                ? String(localized: "Your own zone boundaries.")
                                : String(localized: "Calculated with the heart-rate reserve formula from your max and resting heart rate."))
                VStack(spacing: PulseTheme.Row.listGap) {
                    MoreListRow(symbol: "heart", title: String(localized: "Resting HR"),
                                trailing: .value(profile.zoneRestingHR.map { String(localized: "\(Int($0.rounded())) bpm") }
                                                 ?? String(localized: "After your first night")))
                    MoreButtonRow(symbol: "bolt.heart", title: String(localized: "Max HR"),
                                  subtitle: profile.hrMaxOverride > 0 ? String(localized: "Set by you")
                                                                      : String(localized: "Estimated from your age"),
                                  trailing: .value(String(localized: "\(profile.hrMax) bpm"))) {
                        maxHRDraft = profile.hrMaxOverride
                        editingMaxHR = true
                    }
                    MoreToggleRow(title: String(localized: "Manual heart rate zones"),
                                  isOn: Binding(get: { profile.hasCustomHRZones },
                                                set: { profile.setCustomHRZonesEnabled($0) }))
                }
                PulseZoneTable(zones: profile.hrZoneSet.zones)
                if profile.hasCustomHRZones {
                    MoreLinkRow(.classic(.settings), symbol: "pencil", title: String(localized: "Edit zone boundaries"),
                                subtitle: String(localized: "In Classic settings › Profile"))
                }
            }
        }
        .sheet(isPresented: $editingMaxHR) {
            PulseWheelPickerSheet(title: String(localized: "Max heart rate"),
                                  options: [0] + Array(140...230), selection: $maxHRDraft,
                                  label: { $0 == 0 ? String(localized: "Auto (\(Self.tanaka(profile.age)) bpm)")
                                                   : String(localized: "\($0) bpm") },
                                  onConfirm: {
                                      profile.hrMaxOverride = maxHRDraft
                                      editingMaxHR = false
                                  },
                                  onCancel: { editingMaxHR = false })
                .presentationDetents([.height(380)])
        }
    }

    /// The age estimate `ProfileStore.hrMax` falls back to.
    private static func tanaka(_ age: Int) -> Int { Int((208 - 0.7 * Double(age)).rounded()) }
}

/// "ZONE | MIN | MAX", Zone 5 down to Zone 1, each edged in its zone colour (help-center/98).
struct PulseZoneTable: View {
    let zones: [HRZone]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "Zone")).frame(maxWidth: .infinity, alignment: .leading)
                Text(String(localized: "Zone min")).frame(width: 90, alignment: .trailing)
                Text(String(localized: "Zone max")).frame(width: 90, alignment: .trailing)
            }
            .pulseText(.label)
            .foregroundStyle(PulseTheme.textTertiary)
            .padding(.bottom, 10)
            ForEach(zones.sorted { $0.number > $1.number }, id: \.number) { zone in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 1.5).fill(PulseTheme.Zone.color(zone.number)).frame(width: 3, height: 22)
                    Text(String(localized: "Zone \(zone.number)"))
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(localized: "\(Int(zone.lower.rounded())) bpm"))
                        .pulseText(.rowValue)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(width: 90, alignment: .trailing)
                    // Every zone's top is exclusive but the last, whose top is the max heart rate itself.
                    Text(String(localized: "\(Int(zone.upper.rounded()) - (zone.number == 5 ? 0 : 1)) bpm"))
                        .pulseText(.rowValue)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(.vertical, 9)
                .accessibilityElement(children: .combine)
                if zone.number != 1 { PulseDivider() }
            }
        }
        .padding(16)
        .pulseCardBackground()
    }
}
#endif
