#if os(iOS)
import SwiftUI
import StrandAnalytics
import StrandImport
import WhoopStore
import WhoopProtocol

/// Activity Details (WHOOP_UI_SPEC §3.6): one workout's Activity Strain on the 0–21 scale against this
/// sport's 30-day average, its heart rate edge to edge, time in each zone (ZONE 5 → ZONE 0) with this
/// sport's typical share, key statistics against the last 30 days, heart-rate recovery, the recorded
/// route, and the recovery-activity, Lift Log strength and not-enough-heart-rate variants. "•••" edits,
/// deletes or copies it under the classic Workouts rules (imported history is never rewritten).
///
/// Pushed from Home's and the Strain dive's activity rows; at a modal root (End & Save) it shows "✕".
struct PulseActivityDetailView: View {
    /// Existing entry points (Home and Strain dive rows) open this screen instead of the classic detail.
    static let isRebuilt = true
    /// The activity to show.
    let workout: PulseWorkoutRoute
    /// A live session's own heart rate, handed over at End & Save: drawn until the strap's history covers
    /// the session (the store gains it only when the strap offloads).
    var liveSamples: [HRSample] = []

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseModalRoot) private var modalRoot
    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var profile: ProfileStore
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""

    /// The row on screen: the one handed in, then whatever an edit saved it as.
    @State private var row: WorkoutRow?
    @State private var snapshot: ActivityDetailSnapshot?
    @State private var scrub: PulseActivityScrub?
    @State private var showsMenu = false
    @State private var showsExport = false
    @State private var confirmsDelete = false
    @State private var editTarget: PulseActivityEditTarget?
    @State private var strengthTab: StrengthTab = .exercises
    @State private var recoveryTab: RecoveryTab = .stress
    /// The window's height and its bottom safe area, for the Edit sheet's detent (WHOOP's starts ≈119 pt
    /// down, d04).
    @State private var windowHeight: CGFloat = 0
    @State private var bottomInset: CGFloat = 0

    enum StrengthTab: Hashable { case exercises, zones }
    enum RecoveryTab: Hashable { case stress, heartRate }

    /// The view state the content draws. It is read in `body` and handed down: `PulseScreenScaffold` and
    /// `PulseLoadingGate` run the content closure inside their own bodies, so state read only in there is
    /// not a dependency of THIS view, and a tap that changed only the tab left the old pane on screen.
    private struct Panes {
        let strength: StrengthTab
        let recovery: RecoveryTab
        let scrub: PulseActivityScrub?
    }

    private var currentRow: WorkoutRow { row ?? workout.row }

    private var inputs: ActivityBuildInputs {
        let body = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        let distance = UnitPrefs.resolveDistance(system: body, override: distanceSystemRaw)
        return ActivityBuildInputs(hrMax: profile.hrMax, stepTicksPerStep: profile.stepTicksPerStep,
                                   distanceImperial: distance == .imperial, massImperial: body == .imperial)
    }

    private var loadKey: String {
        "\(model.healthKey)|\(currentRow.startTs)|\(currentRow.sport)|\(currentRow.endTs)|\(inputs.distanceImperial)"
    }

    var body: some View {
        let panes = Panes(strength: strengthTab, recovery: recoveryTab, scrub: scrub)
        PulseScreenScaffold(role: .pushed, coach: coachAccessory, coachSeed: coachSeed, showsNavigationBar: false,
                            spacing: 0, topPadding: 12, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { content(snapshot, panes: panes) }
            } skeleton: {
                PulseSkeleton.cards([60, 186, 66, 66, 66])
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background(PulseSwipeBackEnabler())
        .background(GeometryReader { geo in
            Color.clear
                .onAppear {
                    windowHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                    bottomInset = geo.safeAreaInsets.bottom
                }
                .onChange(of: geo.size.height) { _, new in
                    windowHeight = new + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                    bottomInset = geo.safeAreaInsets.bottom
                }
        })
        .task(id: loadKey) { await load() }
        .confirmationDialog(snapshot?.title ?? "", isPresented: $showsMenu, titleVisibility: .hidden) {
            menuButtons
        }
        .confirmationDialog(String(localized: "Export route"), isPresented: $showsExport, titleVisibility: .visible) {
            Button(String(localized: "GPX: Strava, Garmin, most apps")) { exportRoute(.gpx) }
            Button(String(localized: "FIT: Garmin Connect")) { exportRoute(.fit) }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Save this route as a standard file you can import into other apps."))
        }
        .fullScreenCover(isPresented: $confirmsDelete) {
            PulseDialogCard(title: String(localized: "Delete this activity?"),
                            message: deleteMessage,
                            primaryTitle: String(localized: "Delete"),
                            primary: { confirmsDelete = false; Task { await delete() } },
                            secondaryTitle: String(localized: "Cancel"),
                            secondary: { confirmsDelete = false },
                            onClose: { confirmsDelete = false })
                .presentationBackground(.clear)
        }
        .sheet(item: $editTarget) { target in
            PulseActivityFormSheet(mode: target.mode,
                                   detentHeight: windowHeight > 0 ? PulseActivityFormSheet.detent(window: windowHeight, bottomInset: bottomInset) : nil) { saved in
                if let saved { row = saved }
            }
        }
        #if DEBUG
        .task { await applyDebugLaunch() }
        #endif
    }

    // MARK: Load

    private func load() async {
        var target = currentRow
        #if DEBUG
        await PulseActivityDebug.seedIfRequested(repo: repo, profile: profile)
        if target.source == "demo", let picked = await model.build(dayOffset: 0, { builder, r in
            await builder.debugPickWorkout(r, pick: PulseActivityDebug.workoutPick)
        }) {
            target = picked
            row = picked
        }
        #endif
        let handed = target
        let inputs = self.inputs
        let live = liveSamples
        if let s = await model.build(dayOffset: 0, { builder, r in
            await builder.activityDetail(r, row: handed, inputs: inputs, liveSamples: live)
        }) {
            // STRESS leads when there is a reading (e08, e10); without one the tabs are not shown.
            if s.stress != nil, snapshot?.stress == nil { recoveryTab = .stress }
            snapshot = s
        }
    }

    // MARK: Header (§3.6 item 1)

    /// "‹" (or "✕" at a modal root), the sport glyph, "RUNNING" over "6:45 AM to 7:30 AM", and "•••".
    private var header: some View {
        HStack(spacing: 0) {
            if modalRoot {
                PulseCloseButton { dismiss() }
            } else {
                PulseBackButton { dismiss() }
            }
            Image(systemName: snapshot?.symbol ?? PulseActivityCatalog.symbol(for: currentRow.sport))
                .font(.system(size: PulseActivityStyle.Glyph.header, weight: .regular))
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(width: 28, height: 28)
                .padding(.leading, 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot?.title ?? WorkoutSource.displaySport(currentRow.sport))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Text(snapshot?.timeRange ?? "")
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.leading, 9)
            Spacer(minLength: 8)
            if let snapshot, snapshot.ownership != .missing || snapshot.route != nil {
                Button { showsMenu = true } label: {
                    PulseActivityMoreGlyph()
                        .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "More actions"))
            }
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, PulseTheme.Header.navBarTop)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: ActivityDetailSnapshot, panes: Panes) -> some View {
        if s.sourceChip != nil || s.programChip != nil {
            chips(s)
                .padding(.bottom, 18)
        }
        switch s.variant {
        case .strain:
            headline(s, scrub: panes.scrub)
            hrChart(s, color: PulseTheme.strain)
                .padding(.top, 26)
            // h01, f09, g16: the zone legend ≈25 pt under the chart's start / end times.
            zonesSection(s)
                .padding(.top, 16)
            statistics(s)
        case .recovery:
            recoveryHeadline(s, scrub: panes.scrub)
            if let insight = s.insight {
                PulseInsightCard(text: insight,
                                 cta: coach.availability == .off ? nil : String(localized: "Explore insights"),
                                 action: coach.availability == .off ? nil : { coach.open(coachSeed) })
                    .padding(.top, 20)
            }
            if let stress = s.stress {
                PulseSegmentedControl(options: [RecoveryTab.stress, .heartRate], selection: $recoveryTab) { tab in
                    tab == .stress ? String(localized: "Stress") : String(localized: "Heart Rate")
                }
                .padding(.top, 22)
                if panes.recovery == .stress {
                    PulseActivityStressChart(summary: stress, window: s.start...s.end)
                        .padding(.top, 18)
                } else {
                    hrChart(s, color: PulseTheme.Activity.recoveryHRLine)
                        .padding(.top, 22)
                }
            } else {
                PulseCardTitle(String(localized: "Heart rate"))
                    .padding(.top, 26)
                hrChart(s, color: PulseTheme.Activity.recoveryHRLine)
                    .padding(.top, 10)
                Text(String(localized: "No stress reading covers this activity: ZENO scores stress from your strap's heart rate between 6 AM and 10 PM."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            statistics(s)
            if let impact = s.impact {
                PulseActivityImpactCard(impact: impact)
                    .padding(.top, 26)
            }
        case .strength:
            headline(s, scrub: panes.scrub)
            PulseSegmentedControl(options: [StrengthTab.exercises, .zones], selection: $strengthTab) { tab in
                tab == .exercises ? String(localized: "Exercises") : String(localized: "HR Zones")
            }
            .padding(.top, 22)
            hrChart(s, color: PulseTheme.strain)
                .padding(.top, 22)
            if panes.strength == .exercises, let lift = s.lift {
                PulseActivityLiftPager(lift: lift)
                    .padding(.top, 26)
            } else {
                zonesSection(s)
                    .padding(.top, 16)
            }
            statistics(s)
        }
    }

    private func chips(_ s: ActivityDetailSnapshot) -> some View {
        HStack(spacing: 8) {
            if let program = s.programChip, !program.isEmpty {
                chip(program, symbol: nil)
            }
            if let source = s.sourceChip {
                chip(source, symbol: s.row.source.lowercased().hasSuffix("-noop") ? "sparkles" : nil)
            }
        }
    }

    private func chip(_ text: String, symbol: String?) -> some View {
        HStack(spacing: 7) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: PulseActivityStyle.Glyph.chip, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .pulseText(.label)
                .lineLimit(1)
        }
        .foregroundStyle(PulseTheme.textPrimary)
        .padding(.horizontal, 10)
        .frame(minHeight: 26)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(PulseTheme.card))
    }

    // MARK: Headlines (§3.6 item 4)

    /// "13.8 ▲ 9.7 ACTIVITY STRAIN", 4 pt in from the cards (h01, f09: the headline starts at 20.3 pt where
    /// the cards start at 16). While a finger rests on the chart the readout covers it, in the same frame,
    /// so the chart below never moves.
    @ViewBuilder
    private func headline(_ s: ActivityDetailSnapshot, scrub: PulseActivityScrub?) -> some View {
        Group {
            if let strain = s.strain {
                HStack(alignment: .top, spacing: 36) {
                    let value = PulseFormat.oneDecimal(strain)
                    let average = s.strainAverage.map(PulseFormat.oneDecimal)
                    PulseActivityHeadline(value: value, color: PulseTheme.strain,
                                          label: String(localized: "Activity Strain"),
                                          average: average,
                                          direction: average.map { $0 == value ? .flat : (strain > (s.strainAverage ?? 0) ? .up : .down) },
                                          accessibilityValue: String(localized: "\(value) out of 21"))
                    if let steps = s.steps {
                        PulseActivityHeadline(value: PulseFormat.grouped(Double(steps)),
                                              label: String(localized: "Activity Steps"))
                    }
                }
            } else {
                // Not enough heart rate (§3.6 "Variants", g24): dashes in place of the Strain and why.
                VStack(alignment: .leading, spacing: 10) {
                    PulseActivityDashes()
                    Text(String(localized: "Activity Strain"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                    if let note = s.strainNote {
                        Text(note)
                            .pulseText(.rowText)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .opacity(scrub == nil ? 1 : 0)
        .overlay(alignment: .topLeading) {
            if let scrub { scrubReadout(scrub, color: PulseTheme.strain) }
        }
        .padding(.leading, 4)
    }

    /// The recovery variant's "0:10:00 ▲ 0:08:12 MINUTES" and "0.9 STRESS CHANGE" (e01, e08, e10).
    @ViewBuilder
    private func recoveryHeadline(_ s: ActivityDetailSnapshot, scrub: PulseActivityScrub?) -> some View {
        let clock = ActivityFormat.clock(seconds: s.durationSeconds)
        let average = s.durationAverage.map { ActivityFormat.clock(seconds: $0) }
        let direction: PulseTrend.Direction? = s.durationAverage.map { avg in
            ActivityFormat.clock(seconds: avg) == clock ? .flat : (s.durationSeconds > avg ? .up : .down)
        }
        HStack(alignment: .top, spacing: 30) {
            PulseActivityHeadline(value: String(clock.dropLast(3)), smallSuffix: String(clock.suffix(3)),
                                  label: String(localized: "Minutes"), average: average, direction: direction,
                                  accessibilityValue: PulseFormat.duration(minutes: s.durationSeconds / 60))
            if let stress = s.stress {
                let change = stress.change
                let shown = PulseFormat.oneDecimal(change)
                PulseActivityHeadline(value: shown == "-0.0" ? "0.0" : shown,
                                      label: String(localized: "Stress Change"),
                                      accessibilityValue: String(localized: "\(shown), from \(PulseFormat.oneDecimal(stress.shownStart)) to \(PulseFormat.oneDecimal(stress.shownEnd)) on the 0 to 3 stress scale"))
            }
        }
        .opacity(scrub == nil ? 1 : 0)
        .overlay(alignment: .topLeading) {
            if let scrub { scrubReadout(scrub, color: PulseTheme.Activity.recoveryHRLine) }
        }
        .padding(.leading, 4)
    }

    /// While a finger rests on the chart: "132 bpm" over "10:34" in place of the headline (e03).
    private func scrubReadout(_ scrub: PulseActivityScrub, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(scrub.bpm.rounded()))")
                    .font(PulseType.font(.largeValue))
                    .foregroundStyle(color)
                Text(String(localized: "bpm"))
                    .pulseText(.tileUnit)
                    .foregroundStyle(color)
            }
            Text(PulseFormat.clock(scrub.date))
                .pulseText(.baseline)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Heart rate (§3.6 item 6)

    private func hrChart(_ s: ActivityDetailSnapshot, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PulseActivityHRChart(points: s.hr, window: s.start...s.end, span: s.chartSpan, color: color, scrub: $scrub)
                .padding(.horizontal, -PulseTheme.Layout.pageMargin)
                .overlay {
                    // Over an empty chart, in its middle.
                    if !s.hasHeartRate, let message = hrMessage(s) {
                        Text(message)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 20)
                    }
                }
            // Under a chart that holds part of the activity, so it never sits on the line.
            if s.hasHeartRate, let message = hrMessage(s) {
                Text(message)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .id("pulse.activity-hr")
    }

    /// The line about the chart's heart rate. Without a Strain the headline already says why there is none; a
    /// live or manual row WITH a Strain was scored from heart rate, so it never reads "no heart rate was
    /// recorded".
    private func hrMessage(_ s: ActivityDetailSnapshot) -> String? {
        switch s.heartRate {
        case .pending:
            return s.hasHeartRate
                ? String(localized: "The rest of this session's heart rate appears once your strap syncs it.")
                : String(localized: "Heart rate appears once your strap syncs this session.")
        case .none:
            guard s.strain != nil else { return nil }
            let origin = WorkoutSource.classify(s.row.source)
            return origin == .manual || origin == .detected
                ? String(localized: "Your strap's history has no heart rate for this activity.")
                : String(localized: "No heart rate is stored for this activity.")
        case .stored, .session, .partial:
            return nil
        }
    }

    // MARK: Zones (§3.6 items 7–9)

    @ViewBuilder
    private func zonesSection(_ s: ActivityDetailSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PulseActivityZoneLegend(duration: s.durationSeconds,
                                    showsTypical: s.zoneSharesShown && s.zones.contains { $0.typical != nil })
                .padding(.bottom, 4)
            if s.heartRate == .pending && !s.zonesFromImport {
                // Nothing stored yet: no zone times to show, rather than zeros.
                Text(String(localized: "Time in each zone appears once your strap syncs this session's heart rate."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pulseCardBackground()
            } else {
                ForEach(s.zones) { zone in
                    PulseActivityZoneRow(row: zone, showsShare: s.zoneSharesShown)
                }
            }
            HStack(spacing: 0) {
                Text(s.zoneFootnote + " ")
                    .foregroundStyle(PulseTheme.textSecondary)
                + Text(String(localized: "View HR settings"))
                    .underline()
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            .pulseText(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { navigator.open(PulseHeartRateSettingsRoute().route) }
            .accessibilityAddTraits(.isButton)
            // More's HEART RATE SETTINGS edits the max and zones this footnote names.
            .accessibilityHint(String(localized: "Opens Heart Rate Settings"))
            .padding(.top, 8)
        }
        .id("pulse.activity-zones")
    }

    // MARK: Statistics (§3.6 items 10–12, [Z] heart-rate recovery)

    @ViewBuilder
    private func statistics(_ s: ActivityDetailSnapshot) -> some View {
        if !s.keyStats.isEmpty {
            // "VS. 30 DAY AVERAGE" on both variants: the chips print this sport's 30-day MEAN. WHOOP's recovery
            // variant says "30 DAY RANGE" over chips whose meaning is unconfirmed (§3.6, [Z] in ARCHITECTURE §9).
            PulseActivityStatsRow(title: s.isRecoveryActivity ? String(localized: "Session metrics")
                                                              : String(localized: "Key statistics"),
                                  caption: String(localized: "vs. 30 day average"),
                                  stats: s.keyStats)
                .padding(.top, 34)
                .id("pulse.activity-stats")
        }
        if let hrr = s.hrRecovery {
            heartRateRecovery(hrr)
                .padding(.top, 26)
        }
        if let route = s.route {
            PulseActivityRouteCard(route: route) { showsExport = true }
                .padding(.top, 26)
                .id("pulse.activity-route")
        }
    }

    private func heartRateRecovery(_ hrr: HeartRateRecovery.Result) -> some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    PulseCardTitle(String(localized: "Heart rate recovery"))
                    Text(String(localized: "From \(hrr.endHR) bpm"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize()
                }
                HStack(spacing: 0) {
                    recoveryColumn(String(localized: "1 min"), hrr.after1Minute)
                    recoveryColumn(String(localized: "2 min"), hrr.after2Minutes)
                    recoveryColumn(String(localized: "5 min"), hrr.after5Minutes)
                }
                Text(String(localized: "How far your heart rate fell after you stopped. A dash means the strap recorded too little around that minute."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .id("pulse.activity-hrr")
    }

    private func recoveryColumn(_ title: String, _ drop: Int?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(drop.map { "\($0)" } ?? "–")
                    .font(PulseType.font(.mediumValue))
                    .foregroundStyle(drop == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                if drop != nil {
                    Text(String(localized: "bpm"))
                        .pulseText(.tileUnit)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart-rate recovery after \(title)"))
        .accessibilityValue(drop.map { String(localized: "\($0) beats per minute") } ?? String(localized: "not available"))
    }

    // MARK: Coach

    /// The floating summary pill with the local sentence (§1.2 [Z]); the recovery variant keeps its sentence
    /// inline (e01–e03) and floats the button.
    private var coachAccessory: PulseCoachAccessory {
        guard let snapshot, let insight = snapshot.insight, snapshot.variant != .recovery else { return .button }
        return .pill(summary: insight)
    }

    private var coachSeed: String? {
        guard let s = snapshot else { return nil }
        var parts = [String(localized: "Activity: \(s.title), \(s.timeRange)")]
        if let strain = s.strain { parts.append(String(localized: "Activity Strain \(PulseFormat.oneDecimal(strain))")) }
        parts += s.keyStats.map { "\($0.title) \($0.value)\($0.valueTail ?? "")\($0.unit.isEmpty ? "" : " \($0.unit)")" }
        if s.zoneSharesShown {
            let high = s.zones.filter { $0.zone >= 4 }.reduce(0) { $0 + $1.seconds }
            if high > 0 { parts.append(String(localized: "Zones 4-5 \(Int((high / 60).rounded())) min")) }
        }
        if let stress = s.stress {
            parts.append(String(localized: "Stress \(PulseFormat.oneDecimal(stress.shownStart)) to \(PulseFormat.oneDecimal(stress.shownEnd))"))
        }
        return parts.joined(separator: ". ")
    }

    // MARK: Menu (§3.6 "Menus")

    @ViewBuilder
    private var menuButtons: some View {
        if let s = snapshot {
            switch s.ownership {
            case .manual:
                Button(String(localized: "Edit")) { editTarget = PulseActivityEditTarget(mode: .edit(s.row)) }
                Button(String(localized: "Delete"), role: .destructive) { confirmsDelete = true }
            case .detected:
                Button(String(localized: "Edit")) { editTarget = PulseActivityEditTarget(mode: .edit(s.row)) }
                Button(String(localized: "Not a workout"), role: .destructive) { confirmsDelete = true }
            case .imported:
                Button(String(localized: "Edit a copy")) { editTarget = PulseActivityEditTarget(mode: .copy(s.row)) }
            case .liftLinked:
                Button(String(localized: "Delete"), role: .destructive) { confirmsDelete = true }
            case .missing:
                EmptyView()
            }
            if s.route != nil {
                Button(String(localized: "Export route")) { showsExport = true }
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        }
    }

    private var deleteMessage: String {
        guard let s = snapshot else { return "" }
        switch s.ownership {
        case .detected:
            return String(localized: "It leaves your history and is not detected again. This can't be undone.")
        case .liftLinked:
            let sets = s.lift?.workingSets ?? 0
            return String(localized: "The Lift Log session and its \(sets) working sets are deleted with it. This can't be undone.")
        default:
            return String(localized: "It is removed from your history on this iPhone. This can't be undone.")
        }
    }

    private func delete() async {
        guard let s = snapshot else { return }
        RouteStore.remove(startTs: s.row.startTs, sport: s.row.sport)
        PulseActivityLocationStore.remove(startTs: s.row.startTs, sport: s.row.sport)
        if s.ownership == .liftLinked, let lift = s.lift, let store = await repo.storeHandle() {
            _ = try? await store.deleteLiftSession(id: lift.sessionId)
        }
        await repo.deleteWorkout(s.row)
        await repo.refresh()
        dismiss()
    }

    /// The classic detail's GPX / FIT export, off the main actor; the share sheet opens on it.
    private func exportRoute(_ format: RouteExporter.Format) {
        guard let s = snapshot, let route = s.route else { return }
        let points = route.points.map { RoutePoint(lat: $0.lat, lon: $0.lon) }
        let name = "noop-route-\(s.row.startTs).\(format.ext)"
        let row = s.row
        Task.detached(priority: .userInitiated) {
            let data = RouteExporter.render(format, route: points, startTs: row.startTs, endTs: row.endTs,
                                            sport: row.sport, distanceM: row.distanceM, energyKcal: row.energyKcal,
                                            avgHr: row.avgHr, maxHr: row.maxHr)
            let url = NoopScratch.file(name)
            do { try data.write(to: url) } catch { return }
            await MainActor.run { FileExport.exportFile(at: url, suggestedName: name) }
        }
    }

    #if DEBUG
    /// `--activity-menu`, `--activity-edit`, `--activity-delete`, `--activity-export`, `--activity-scrub`,
    /// `--activity-zones-tab`, `--activity-heart-rate-tab`: open that state once the screen has loaded, for
    /// captures (simctl cannot tap). `--activity-tap-zones` switches EXERCISES → HR ZONES two seconds after
    /// load, alone, through the segmented control's own binding: the update a tap makes, with nothing else
    /// changing in it.
    private func applyDebugLaunch() async {
        for _ in 0..<40 where snapshot == nil { try? await Task.sleep(for: .milliseconds(150)) }
        guard let s = snapshot else { return }
        let args = CommandLine.arguments
        if args.contains("--activity-menu") { showsMenu = true }
        if args.contains("--activity-delete") { confirmsDelete = true }
        if args.contains("--activity-export") { showsExport = true }
        if args.contains("--activity-zones-tab") { strengthTab = .zones }
        if args.contains("--activity-heart-rate-tab") { recoveryTab = .heartRate }
        if args.contains("--activity-edit") {
            try? await Task.sleep(for: .milliseconds(400))
            editTarget = PulseActivityEditTarget(mode: s.ownership == .imported ? .copy(s.row) : .edit(s.row))
        }
        if args.contains("--activity-scrub"), let mid = s.hr.filter({ s.start...s.end ~= $0.date }).dropFirst(s.hr.count / 3).first,
           let bpm = mid.value {
            scrub = PulseActivityScrub(date: mid.date, bpm: bpm)
        }
        if args.contains("--activity-view-all"), let lift = s.lift {
            navigator.open(PulseActivitySessionSummaryRoute(lift: lift).route)
        }
        if args.contains("--activity-tap-zones") {
            try? await Task.sleep(for: .seconds(2))
            $strengthTab.wrappedValue = .zones
        }
    }
    #endif
}

/// "•••" as WHOOP draws it in the header (h01, hc82, f09): three thin rings, ≈6.5 pt on a 10 pt pitch.
struct PulseActivityMoreGlyph: View {
    var body: some View {
        HStack(spacing: 3.5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .strokeBorder(PulseTheme.textPrimary, lineWidth: 1.5)
                    .frame(width: 6.5, height: 6.5)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The "---" WHOOP draws in strain blue where a Strain would be (g24).
struct PulseActivityDashes: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1, style: .circular)
                    .fill(PulseTheme.strain)
                    .frame(width: 13, height: 4)
            }
        }
        .frame(height: 20, alignment: .bottom)
        .accessibilityLabel(String(localized: "No Strain"))
    }
}
#endif
