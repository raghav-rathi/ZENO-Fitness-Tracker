#if os(iOS)
import SwiftUI
import StrandAnalytics
import WhoopStore

/// ADD ACTIVITY (WHOOP_UI_SPEC §3.9), presented as a sheet: log an activity, a sleep or a nap the strap did
/// not record live. Form first, with "SELECT ACTIVITY ›" [Z].
struct PulseAddActivityView: View {
    /// Existing entry points (Home's + ADD ACTIVITY, the ＋ menu) open this sheet instead of the classic
    /// Workouts screen.
    static let isRebuilt = true

    var body: some View {
        PulseActivityForm(mode: .add(preset: nil), onDone: { _ in })
    }
}

/// What the form does.
enum PulseActivityFormMode: Equatable {
    /// A new activity, optionally with the activity already chosen.
    case add(preset: PulseActivityKind?)
    /// Change a manual (or legacy auto-detected) row.
    case edit(WorkoutRow)
    /// A new manual activity copied from an imported row, which itself stays untouched.
    case copy(WorkoutRow)

    var original: WorkoutRow? {
        switch self {
        case .add: return nil
        case .edit(let row), .copy(let row): return row
        }
    }

    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}

/// Activity Details' Edit sheet request.
struct PulseActivityEditTarget: Identifiable {
    let mode: PulseActivityFormMode
    let id = UUID()
}

/// EDIT ACTIVITY presented from Activity Details: its own stack, "✕" at its root.
struct PulseActivityFormSheet: View {
    let mode: PulseActivityFormMode
    let onDone: (WorkoutRow?) -> Void

    var body: some View {
        NavigationStack {
            PulseActivityForm(mode: mode, onDone: onDone)
                .environment(\.pulseModalRoot, true)
        }
    }
}

// MARK: - The form

/// ADD / EDIT ACTIVITY (§3.9): the info banner (add only), the activity row, TIME with Start / End pills
/// that open an inline wheel (the active pill green), the amber validation banner, LOCATION [Z], and the
/// white SAVE capsule. Saving goes through the classic manual-workout path (`WorkoutSource` validation,
/// `Repository.saveManualWorkout`, then a rescore from the strap's heart rate); a Sleep or Nap goes through
/// `Repository.addManualNap`. An overlap with something already recorded stops the save with WHOOP's
/// OVERLAPPING ACTIVITIES dialog.
struct PulseActivityForm: View {
    let mode: PulseActivityFormMode
    let onDone: (WorkoutRow?) -> Void

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var intelligence: IntelligenceEngine

    @State private var kind: PulseActivityKind?
    @State private var start: Date
    @State private var end: Date
    @State private var location: PulseActivityLocation
    @State private var editing: EditingField?
    @State private var showsPicker = false
    @State private var showsReclassify = false
    @State private var overlap: String?
    @State private var saving = false
    /// The heart rate around the edited activity, for the scrubber [Z].
    @State private var heartRate: [PulseTimeValue] = []
    @ScaledMetric(relativeTo: .subheadline) private var pillSize: CGFloat = 15

    enum EditingField: Hashable { case start, end, location }

    init(mode: PulseActivityFormMode, onDone: @escaping (WorkoutRow?) -> Void) {
        self.mode = mode
        self.onDone = onDone
        let now = Date()
        switch mode {
        case .add(let preset):
            _kind = State(initialValue: preset)
            // A valid 45-minute activity ending now, as the classic sheet opens (`ManualWorkoutSheet`).
            _start = State(initialValue: now.addingTimeInterval(-45 * 60))
            _end = State(initialValue: now)
            _location = State(initialValue: .wrist)
        case .edit(let row), .copy(let row):
            _kind = State(initialValue: PulseActivityCatalog.kind(named: WorkoutSource.editableSport(row.sport)))
            _start = State(initialValue: Date(timeIntervalSince1970: TimeInterval(row.startTs)))
            _end = State(initialValue: Date(timeIntervalSince1970: TimeInterval(row.endTs)))
            _location = State(initialValue: PulseActivityLocationStore.location(startTs: row.startTs, sport: row.sport)
                ?? .wrist)
        }
    }

    private var title: String {
        mode.isAdd ? String(localized: "Add Activity") : String(localized: "Edit Activity")
    }

    private var isSleep: Bool { kind?.category == .sleep }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if mode.isAdd {
                    infoBanner
                        .padding(.bottom, 16)
                }
                activityRow
                if !mode.isAdd && !isSleep && heartRate.count > 1 {
                    PulseActivityScrubber(points: heartRate, start: $start, end: $end)
                        .padding(.top, 22)
                }
                sectionHeader(String(localized: "Time"))
                    .padding(.top, 28)
                timeRow(String(localized: "Start Time"), date: start, field: .start)
                    .padding(.top, 14)
                timeRow(String(localized: "End Time"), date: end, field: .end)
                    .padding(.top, 8)
                if editing == .start || editing == .end {
                    wheel
                        .padding(.top, 4)
                }
                if let message = validationMessage {
                    validationBanner(message)
                        .padding(.top, 16)
                }
                if !isSleep {
                    sectionHeader(String(localized: "Location"))
                        .padding(.top, 28)
                    locationSection
                        .padding(.top, 14)
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .safeAreaInset(edge: .bottom, spacing: 0) { saveButton }
        .background(sheetBackground.ignoresSafeArea())
        .pulseNavHeader(title)
        .environment(\.colorScheme, .dark)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.card)
        .presentationBackground { sheetBackground }
        .navigationDestination(isPresented: $showsPicker) {
            PulseActivityPickerView(selected: kind?.name) { picked in
                kind = picked
            }
        }
        .sheet(isPresented: $showsReclassify) {
            PulseReclassifySheet(selected: kind?.name, isAutoDetected: isAutoDetected) { picked in
                kind = picked
                showsReclassify = false
            }
        }
        .fullScreenCover(isPresented: Binding(get: { overlap != nil }, set: { if !$0 { overlap = nil } })) {
            PulseDialogCard(title: String(localized: "Overlapping activities"),
                            message: overlap ?? "",
                            primaryTitle: String(localized: "Got it"),
                            primary: { overlap = nil },
                            onClose: { overlap = nil })
                .presentationBackground(.clear)
        }
        .task { await loadHeartRate() }
        #if DEBUG
        .task {
            let args = CommandLine.arguments
            if args.contains("--activity-wheel") { editing = .end }
            if args.contains("--activity-invalid") { end = Date().addingTimeInterval(3600) }
            if args.contains("--activity-overlap") { await checkOverlapForDebug() }
            if args.contains("--activity-reclassify") { showsReclassify = true }
            if let sport = PulseActivityDebug.value("--activity-form-sport") { kind = PulseActivityCatalog.kind(named: sport) }
        }
        #endif
    }

    @ViewBuilder
    private var sheetBackground: some View {
        if mode.isAdd {
            PulseTheme.Activity.addSheet
        } else {
            LinearGradient(gradient: PulseTheme.Activity.editSheet, startPoint: .top, endPoint: .bottom)
        }
    }

    private var isAutoDetected: Bool {
        if case .edit(let row) = mode { return WorkoutSource.classify(row.source) == .detected }
        return false
    }

    /// The heart rate around the row being edited (its own strap's), for the scrubber.
    private func loadHeartRate() async {
        guard let original = mode.original else { return }
        if let points = await model.build(dayOffset: 0, { builder, _ in await builder.activityHeartRate(around: original) }) {
            heartRate = points
        }
    }

    // MARK: Banner and activity row

    /// The info banner [Z]: what ZENO does with an added activity.
    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 1)
                .accessibilityHidden(true)
            Text(String(localized: "ZENO scores an activity you add from your strap's heart rate over that time."))
                .pulseText(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(PulseTheme.Activity.infoBannerText)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.Activity.infoBannerFill))
    }

    private var activityRow: some View {
        Button {
            if mode.isAdd { showsPicker = true } else { showsReclassify = true }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: kind?.symbol ?? "square.grid.2x2")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(kind?.displayName ?? String(localized: "Select Activity"))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.Activity.formRow))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(kind.map { String(localized: "Activity, \($0.displayName)") }
                            ?? String(localized: "Select activity"))
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
            Rectangle().fill(PulseTheme.divider).frame(height: 1)
        }
        .padding(.horizontal, -4)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Time

    private func timeRow(_ label: String, date: Date, field: EditingField) -> some View {
        HStack {
            Text(label)
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            Button {
                editing = editing == field ? nil : field
            } label: {
                Text(Self.pillText(date))
                    .font(PulseType.numeral(min(pillSize, 22)))
                    .foregroundStyle(editing == field ? Color.black : PulseTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 36)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                        .fill(editing == field ? PulseTheme.Activity.timePillActive : PulseTheme.Activity.timePillIdle))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
            .accessibilityValue(Self.pillText(date))
            .accessibilityHint(String(localized: "Opens a date and time wheel"))
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 44)
    }

    /// "8 Oct at 7:00 AM" in the device zone and locale.
    static func pillText(_ date: Date) -> String {
        let day = date.formatted(.dateTime.day().month(.abbreviated).locale(AppLanguage.activeLocale))
        return String(localized: "\(day) at \(PulseFormat.clock(date))")
    }

    /// The inline wheel for the active pill: date · hour · minute · AM/PM, never past now.
    private var wheel: some View {
        DatePicker("", selection: editing == .start ? startBinding : $end, in: ...Date(),
                   displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel(editing == .start ? String(localized: "Start time") : String(localized: "End time"))
    }

    /// Moving the start keeps the activity's length and carries the end with it, clamped so the end never
    /// lands in the future (the classic sheet's rule, `WorkoutSource.endAfterStartMove`).
    private var startBinding: Binding<Date> {
        Binding(get: { start }, set: { picked in
            let length = end.timeIntervalSince(start)
            let newStart = min(picked, Date().addingTimeInterval(-max(0, length)))
            end = WorkoutSource.endAfterStartMove(oldStart: start, oldEnd: end, newStart: newStart)
            start = newStart
        })
    }

    private func validationBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "!")
                .font(.system(size: 17, weight: .heavy))
                .accessibilityHidden(true)
            Text(message)
                .pulseText(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(PulseTheme.Activity.validationBannerText)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.Activity.validationBannerFill))
        .accessibilityElement(children: .combine)
    }

    // MARK: Location [Z]

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Where did you wear your strap?"))
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.horizontal, 20)
            Button {
                editing = editing == .location ? nil : .location
            } label: {
                Text(location.title)
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                        .fill(PulseTheme.Gradients.pillRead))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .padding(.horizontal, 20)
            .accessibilityLabel(String(localized: "Where you wore your strap"))
            .accessibilityValue(location.title)
            if editing == .location {
                Picker(String(localized: "Location"), selection: $location) {
                    ForEach(PulseActivityLocation.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
            }
        }
    }

    // MARK: Save

    private var saveButton: some View {
        let enabled = builtRow != nil && !saving
        return Button { Task { await save() } } label: {
            Text(String(localized: "Save"))
                .pulseText(.capsuleLabel)
                .foregroundStyle(enabled ? Color.black : PulseTheme.textDisabled)
                .frame(maxWidth: .infinity, minHeight: 49)
                .background(Capsule(style: .circular).fill(enabled ? Color.white : PulseTheme.Activity.saveDisabled))
                .contentShape(Capsule())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .accessibilityLabel(mode.isAdd ? String(localized: "Save activity") : String(localized: "Save changes"))
    }

    /// The row this form would save: the classic manual-workout builder with the edited row's own captured
    /// figures carried (`WorkoutSource.preservingCaptured`); nil while the times cannot make an honest row.
    private var builtRow: WorkoutRow? {
        guard let kind else { return nil }
        if kind.category == .sleep {
            let span = end.timeIntervalSince(start)
            return span >= 10 * 60 && span <= 18 * 3600 && end <= Date()
                ? WorkoutRow(startTs: Int(start.timeIntervalSince1970), endTs: Int(end.timeIntervalSince1970),
                             sport: kind.name, source: "manual", durationS: span, energyKcal: nil, avgHr: nil,
                             maxHr: nil, strain: nil, distanceM: nil, zonesJSON: nil, notes: nil, steps: nil)
                : nil
        }
        let original = mode.original
        guard let base = WorkoutSource.buildManualRowFromSpan(start: start, end: end, sport: kind.name,
                                                              avgHr: original?.avgHr,
                                                              energyKcal: original?.energyKcal,
                                                              distanceM: original?.distanceM)
        else { return nil }
        return WorkoutSource.preservingCaptured(base, from: copySource ?? original)
    }

    /// A copy carries the imported row's captured figures under a manual source (the classic
    /// "Duplicate as manual").
    private var copySource: WorkoutRow? {
        guard case .copy(let row) = mode else { return nil }
        return WorkoutRow(startTs: row.startTs, endTs: row.endTs, sport: WorkoutSource.displaySport(row.sport),
                          source: "manual", durationS: row.durationS, energyKcal: row.energyKcal,
                          avgHr: row.avgHr, maxHr: row.maxHr, strain: row.strain, distanceM: row.distanceM,
                          zonesJSON: row.zonesJSON, notes: row.notes, steps: row.steps)
    }

    /// The amber banner's words, only once an activity is chosen (an empty form is not an error).
    private var validationMessage: String? {
        guard kind != nil, builtRow == nil else { return nil }
        let now = Date()
        if start > now || end > now {
            return String(localized: "Invalid duration. Activities cannot start or end in the future.")
        }
        if end <= start { return String(localized: "Invalid duration. An activity has to end after it starts.") }
        let span = end.timeIntervalSince(start)
        if isSleep {
            return span < 10 * 60 ? String(localized: "Invalid duration. A sleep has to last at least 10 minutes.")
                : String(localized: "Invalid duration. A sleep can last at most 18 hours.")
        }
        if Int(span) < WorkoutSource.minManualSpanSeconds {
            return String(localized: "Invalid duration. An activity has to last at least 1 minute.")
        }
        if Int(span) > WorkoutSource.maxManualSpanSeconds {
            return String(localized: "Invalid duration. An activity can last at most 24 hours.")
        }
        return String(localized: "Check the times and try again.")
    }

    private func save() async {
        guard let row = builtRow, let kind else { return }
        saving = true
        defer { saving = false }
        if let message = await overlapMessage(for: row) {
            overlap = message
            return
        }
        if kind.category == .sleep {
            await repo.addManualNap(startTs: row.startTs, endTs: row.endTs)
            await intelligence.analyzeRecent()
            await repo.refresh()
            onDone(nil)
            dismiss()
            return
        }
        var replacing: WorkoutRow?
        if case .edit(let old) = mode { replacing = old }
        RecentSportsPrefs.recordSelection(row.sport)
        await repo.saveManualWorkout(row, replacing: replacing)
        if let old = replacing, old.startTs != row.startTs || old.sport != row.sport {
            PulseActivityLocationStore.remove(startTs: old.startTs, sport: old.sport)
        }
        PulseActivityLocationStore.set(location, startTs: row.startTs, sport: row.sport)
        // Score it from the strap's heart rate now, as the classic Workouts sheet does (#598).
        await intelligence.analyzeRecent()
        await repo.refresh()
        onDone(row)
        dismiss()
    }

    /// WHOOP's OVERLAPPING ACTIVITIES words when the span meets something already recorded (another
    /// activity, or a sleep when adding a sleep or nap), else nil. The row being edited (or copied) is not
    /// an overlap with itself.
    private func overlapMessage(for row: WorkoutRow) async -> String? {
        let ignore = mode.original
        let sleepEntry = kind?.category == .sleep
        let hits: [(String, Int, Int)]? = await model.build(dayOffset: 0) { builder, r in
            let rows = await builder.workoutRows()
            var out: [(String, Int, Int)] = rows.filter { other in
                guard other.startTs < row.endTs && row.startTs < other.endTs else { return false }
                if let ignore, PulseSnapshotBuilder.isSameWorkout(other, ignore) { return false }
                return true
            }
            .map { (WorkoutSource.displaySport($0.sport), $0.startTs, $0.endTs) }
            if sleepEntry {
                let groups = await builder.nightGroups(r)
                for block in groups.flatMap({ $0 }) where block.effectiveStartTs < row.endTs && row.startTs < block.endTs {
                    out.append((String(localized: "Sleep"), block.effectiveStartTs, block.endTs))
                }
            }
            return out
        }
        guard let hits, !hits.isEmpty else { return nil }
        func clock(_ ts: Int) -> String { PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(ts))) }
        let lines = hits.prefix(3).map { "\($0.0) - \(clock($0.1)) - \(clock($0.2))" }.joined(separator: "\n")
        return String(localized: "You added an activity from \(clock(row.startTs)) to \(clock(row.endTs)). ZENO already has these activities during this time:")
            + "\n\n" + lines + "\n\n"
            + String(localized: "Please go back and edit your activity or delete the overlapping activities to continue.")
    }

    #if DEBUG
    private func checkOverlapForDebug() async {
        try? await Task.sleep(for: .milliseconds(600))
        let rows: [WorkoutRow]? = await model.build(dayOffset: 0) { builder, _ in await builder.workoutRows() }
        guard let latest = rows?.max(by: { $0.startTs < $1.startTs }) else { return }
        kind = PulseActivityCatalog.kind(named: "Running")
        start = Date(timeIntervalSince1970: TimeInterval(latest.startTs + 60))
        end = Date(timeIntervalSince1970: TimeInterval(latest.endTs))
        if let row = builtRow { overlap = await overlapMessage(for: row) }
    }
    #endif
}

// MARK: - SELECT YOUR ACTIVITY (reclassify, §3.9)

/// The bottom sheet Edit opens to change an activity's type: "‹ SELECT YOUR ACTIVITY", "Search for
/// Activities", ALL · STRAIN · RECOVERY, the auto-detected note, and rounded cards.
struct PulseReclassifySheet: View {
    var selected: String?
    var isAutoDetected = false
    let onPick: (PulseActivityKind) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(String(localized: "Select your activity"))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    PulseBackButton { dismiss() }
                    Spacer()
                }
            }
            .frame(height: 52)
            .padding(.top, 12)
            PulseActivityPickerList(style: .cards, tabs: [.all, .strain, .recovery], selected: selected,
                                    searchPlaceholder: String(localized: "Search for Activities"),
                                    note: isAutoDetected
                                        ? String(localized: "An unknown activity was auto-detected. Identify which activity you completed.")
                                        : nil,
                                    onPick: onPick)
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .background(LinearGradient(gradient: PulseTheme.Activity.selectSheet, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.card)
        .presentationDetents([.large])
    }
}

// MARK: - Location [Z]

/// Where the strap was worn for an activity (§3.9 LOCATION [Z]).
enum PulseActivityLocation: String, CaseIterable, Hashable {
    case wrist, bicep, other

    var title: String {
        switch self {
        case .wrist: return String(localized: "Wrist")
        case .bicep: return String(localized: "Bicep")
        case .other: return String(localized: "Other")
        }
    }
}

/// The wear location of each activity, kept on this iPhone beside the row by its natural key (start and
/// sport), the way `RouteStore` keeps a route: `WorkoutRow` has no column for it. Nothing scores from it;
/// it is the wearer's note, shown again when the activity is edited.
enum PulseActivityLocationStore {
    static let defaultsKey = "pulse.activity.locations"

    private static func key(startTs: Int, sport: String) -> String { "\(startTs)|\(sport.lowercased())" }

    static func location(startTs: Int, sport: String, defaults: UserDefaults = .standard) -> PulseActivityLocation? {
        let map = defaults.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        return map[key(startTs: startTs, sport: sport)].flatMap(PulseActivityLocation.init(rawValue:))
    }

    static func set(_ location: PulseActivityLocation, startTs: Int, sport: String, defaults: UserDefaults = .standard) {
        var map = defaults.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        map[key(startTs: startTs, sport: sport)] = location.rawValue
        defaults.set(map, forKey: defaultsKey)
    }

    static func remove(startTs: Int, sport: String, defaults: UserDefaults = .standard) {
        var map = defaults.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        map.removeValue(forKey: key(startTs: startTs, sport: sport))
        defaults.set(map, forKey: defaultsKey)
    }
}
#endif
