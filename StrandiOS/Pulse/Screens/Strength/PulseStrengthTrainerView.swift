#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Strength Trainer (WHOOP_UI_SPEC §3.29), presented full screen: "✕ STRENGTH TRAINER ⓘ" over the
/// underline tabs PROGRESS · MY WORKOUTS (WHOOP WORKOUTS is licensed content and not built). Owned by
/// group "onboarding-strength".
///
/// It is the Lift Log restyled, on the Lift Log's own data and controller:
///   - MY WORKOUTS lists the Lift Log's programs; BUILD MANUALLY and Edit open the Lift Log's program
///     editor, a row opens the workout page (START WORKOUT), "•••" starts, edits, shares or deletes;
///   - PROGRESS shows Total Volume Load (the mean session volume over M or 6M, monthly or weekly
///     segments over the sessions), Personal Records (→ Exercise Details), and, as ZENO extras kept from
///     the Lift Log, the week's sets per muscle and the recent sessions (→ the session detail);
///   - a running session opens the live screen (`PulseStrengthLiveSessionView`), which drives the app's
///     one `LiftSessionController`, so the strap gesture, the rest buzzes and the Lock Screen banner work
///     exactly as before.
/// No figure here feeds Strain: Strain stays what the strap measured from heart rate.
struct PulseStrengthTrainerView: View {
    /// Rebuilt: the ＋ menu's STRENGTH TRAINER and the Home Screen quick action open this screen.
    static let isRebuilt = true

    enum Tab: Hashable {
        case progress
        case workouts
    }

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var session: LiftSessionController
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue

    @State private var tab: Tab = .workouts
    @State private var range: StrengthRange = .sixMonths
    @State private var page = 0
    @State private var snapshot: StrengthTrainerSnapshot?
    @State private var editing: PulseStrengthEditTarget?
    @State private var importing = false
    @State private var viewing: PulseStrengthSessionTarget?
    @State private var showsLive = false
    @State private var showsInfo = false
    @State private var deleting: LiftProgramRow?

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }

    private var loadKey: String {
        "\(model.detailKey)|\(PulseStrengthVersion.shared.value)|\(session.savedSessions)|\(range.rawValue)|\(page)|\(unitSystemRaw)"
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Strength Trainer"),
                            trailing: .info { showsInfo = true },
                            coach: .button,
                            coachSeed: String(localized: "My strength training"),
                            spacing: 20,
                            topPadding: 4,
                            ready: snapshot != nil) {
            PulseStrengthTabs(tabs: [Tab.progress, Tab.workouts], selection: $tab) { tab in
                tab == .progress ? String(localized: "Progress") : String(localized: "My Workouts")
            }
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot {
                    switch tab {
                    case .workouts: workouts(snapshot)
                    case .progress: progress(snapshot)
                    }
                }
            } skeleton: {
                PulseSkeleton.cards([60, 56, 56, 56])
            }
        }
        .task(id: loadKey) { await load() }
        .sheet(item: $editing) { target in
            LiftProgramEditorSheet(program: target.program) { PulseStrengthVersion.shared.bump() }
        }
        .sheet(isPresented: $importing) {
            LiftProgramImportSheet { PulseStrengthVersion.shared.bump() }
        }
        .sheet(item: $viewing) { target in
            LiftSessionDetailSheet(session: target.session) { PulseStrengthVersion.shared.bump() }
        }
        .sheet(isPresented: $showsInfo) { PulseStrengthInfoSheet() }
        .fullScreenCover(isPresented: $showsLive) { PulseStrengthLiveSessionView() }
        .confirmationDialog(String(localized: "Delete this workout?"), isPresented: deletingPresented,
                            titleVisibility: .visible, presenting: deleting) { program in
            Button(String(localized: "Delete \(program.name)"), role: .destructive) { delete(program) }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: { _ in
            Text(String(localized: "The workout goes. Sessions you ran from it stay in your history."))
        }
        #if DEBUG
        .task { await debugLaunch() }
        #endif
    }

    private var deletingPresented: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    private func load() async {
        let version = PulseStrengthVersion.shared.value
        let range = self.range
        let page = self.page
        let system = unitSystem
        #if DEBUG
        await PulseStrengthDemo.seedIfRequested(repo: repo)
        #endif
        if let built = await model.build(dayOffset: 0, { builder, request in
            await builder.strengthTrainer(request, version: version, range: range, page: page, system: system)
        }) {
            snapshot = built
        }
    }

    // MARK: MY WORKOUTS

    @ViewBuilder
    private func workouts(_ snapshot: StrengthTrainerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if session.isActive {
                activeSessionCard
            }
            Button(String(localized: "Build manually")) {
                editing = PulseStrengthEditTarget(program: nil)
            }
            .buttonStyle(PulseStrengthWideButtonStyle())
            PulseTextCTA(title: String(localized: "Import from a spreadsheet"), tint: .color(PulseTheme.recoveryBlue)) {
                importing = true
            }
            .padding(.leading, 4)
            PulseListSectionHeader(String(localized: "My Workouts"))
                .padding(.top, 8)
                .padding(.bottom, 4)
            if snapshot.workouts.isEmpty {
                PulseCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "No workouts yet"))
                            .pulseText(.coachingTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(String(localized: "A workout is a list of exercises with your targets: sets, reps, weight, rest and your own technique notes. Build one, then start it at the gym and tap through your sets."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                ForEach(snapshot.workouts) { workout in
                    workoutRow(workout)
                }
            }
        }
    }

    private var activeSessionCard: some View {
        let shown = session.presentation(system: unitSystem)
        return Button { showsLive = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Workout in progress"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.Activity.strengthActiveTimer)
                    Text(session.programName ?? String(localized: "Session"))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let shown {
                        Text("\(shown.status) · \(shown.exercise)")
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(String(localized: "Resume"))
                    .pulseText(.buttonLabel)
                    .foregroundStyle(PulseTheme.Activity.strengthStartOutline)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 36)
                    .background(Capsule(style: .continuous)
                        .strokeBorder(PulseTheme.Activity.strengthStartOutline, lineWidth: 1.5))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseStrengthColors.rowFill))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens the running workout"))
    }

    private func workoutRow(_ workout: StrengthWorkout) -> some View {
        HStack(spacing: 0) {
            PulseLink(PulseStrengthWorkoutRoute(programId: workout.program.id).route) {
                HStack(spacing: 14) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(workout.program.name)
                            .pulseText(.menuLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .lineLimit(2)
                        Text([workout.detail, workout.lastDone].compactMap { $0 }.joined(separator: " · "))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                }
                .padding(.leading, 18)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            Menu {
                Button { Task { await start(workout.program) } } label: {
                    Label(String(localized: "Start workout"), systemImage: "play.fill")
                }
                Button { editing = PulseStrengthEditTarget(program: workout.program) } label: {
                    Label(String(localized: "Edit"), systemImage: "pencil")
                }
                ShareLink(item: Self.shareText(workout, unit: snapshot?.unit ?? "kg")) {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) { deleting = workout.program } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            } label: {
                PulseStrengthMoreGlyph()
                    .frame(width: 56, height: 64)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "More for \(workout.program.name)"))
        }
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseStrengthColors.rowFill))
    }

    /// A workout as plain text, for the share sheet (spec [Z]: "QR share → share a text export").
    static func shareText(_ workout: StrengthWorkout, unit: String) -> String {
        var lines = [workout.program.name]
        if let note = workout.program.note, !note.isEmpty { lines.append(note) }
        for line in workout.lines {
            let reps = line.sets.first?.reps ?? "–"
            let weight = line.sets.first?.weight.map { " @ \($0) \(unit)" } ?? ""
            var text = "• \(line.exercise): \(line.sets.count) × \(reps)\(weight), \(line.rest.lowercased())"
            if let note = line.note { text += " (\(note))" }
            lines.append(text)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: PROGRESS

    @ViewBuilder
    private func progress(_ snapshot: StrengthTrainerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Total Volume Load"))
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 14)
            PulseStrengthChartHeader(label: String(localized: "Ø Volume load"), value: snapshot.averageVolume,
                                     unit: snapshot.unit, range: $range, pager: snapshot.pager,
                                     onBack: { page += 1 }, onForward: { page = max(0, page - 1) })
            if snapshot.hasSessions {
                PulseStrengthVolumeChart(chart: snapshot.chart)
                    .padding(.top, 10)
                if snapshot.chart.points.isEmpty {
                    Text(String(localized: "No finished sessions in this period."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, -150)
                        .padding(.bottom, 130)
                }
            } else {
                PulseCard {
                    Text(String(localized: "Finish a workout and your volume, records and sets per muscle show here. Volume load is weight × reps over your working sets."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 16)
            }

            if !snapshot.records.isEmpty {
                sectionTitle(String(localized: "Personal Records"))
                VStack(spacing: 10) {
                    ForEach(snapshot.records) { record in
                        recordRow(record)
                    }
                }
            }

            sectionTitle(String(localized: "Sets per Muscle"), caption: String(localized: "Last 7 days"))
            musclesCard(snapshot.muscles)

            if !snapshot.sessions.isEmpty {
                sectionTitle(String(localized: "Recent Sessions"))
                VStack(spacing: 10) {
                    ForEach(snapshot.sessions) { item in
                        Button { viewing = PulseStrengthSessionTarget(session: item.row) } label: {
                            PulseListRow(title: item.title, subtitle: item.subtitle)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String, caption: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let caption {
                Text(caption)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 14)
    }

    private func recordRow(_ record: StrengthRecord) -> some View {
        PulseLink(PulseStrengthExerciseRoute(exercise: record.exercise).route) {
            HStack(spacing: 14) {
                PulseStrengthThumbnail(width: 72, height: 50)
                Text(record.exercise)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                PulseValueText(value: record.value, unit: record.unit, style: .tileValue, unitStyle: .tileUnit,
                               unitColor: PulseTheme.textPrimary)
                PulseChevron(color: PulseTheme.textSecondary, size: 14)
            }
            .padding(.leading, 6)
            .padding(.trailing, 16)
            .padding(.vertical, 6)
            .frame(minHeight: 62)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseStrengthColors.rowFill))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "\(record.exercise), best \(record.value) \(record.unit)"))
        .accessibilityHint(String(localized: "Opens exercise details"))
    }

    private func musclesCard(_ muscles: [StrengthMuscleWeek]) -> some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                if muscles.isEmpty {
                    Text(String(localized: "Once you've logged a session, this shows how many sets each muscle got this week."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(muscles) { muscle in
                        PulseStrengthMuscleBar(muscle: muscle)
                    }
                }
                // The classic Lift Log's wording: a sourced research reference, never a target.
                Text(String(localized: "Direct sets count once, indirect ones half. The tick is about 4 sets a week, below which studies of groups stop reliably detecting growth. It's a research reference, not a target, and the bar is never full."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Actions

    /// Start `program` the way the Lift Log does (its lines snapshot into the plan, classified from the
    /// exercise vocabulary), refusing a second session over a running one, then open the live screen here
    /// rather than the shell's classic sheet.
    private func start(_ program: LiftProgramRow) async {
        guard !session.isActive else {
            showsLive = true
            return
        }
        guard let plan = await PulseStrengthSessionStarter.plan(for: program, repo: repo), !plan.isEmpty else { return }
        session.start(plan: plan, programId: program.id, programName: program.name)
        // `start` raises the shell's classic session sheet; this screen shows its own instead.
        session.isPresented = false
        showsLive = true
    }

    private func delete(_ program: LiftProgramRow) {
        Task {
            guard let store = await repo.storeHandle() else { return }
            _ = try? await store.deleteLiftProgram(id: program.id)
            PulseStrengthVersion.shared.bump()
        }
    }

    #if DEBUG
    /// Captures: `--pulse-strength-tab progress`, `--pulse-strength-live rest|active|warmup|exercises|done`.
    private func debugLaunch() async {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--pulse-strength-tab"), i + 1 < args.count, args[i + 1] == "progress" {
            tab = .progress
        }
        // Names take "_" for spaces (the capture script splits on spaces) and match by prefix.
        if let i = args.firstIndex(of: "--pulse-strength-exercise"), i + 1 < args.count {
            tab = .progress
            await PulseStrengthDemo.seedIfRequested(repo: repo)
            if let name = await PulseStrengthDemo.exercise(matching: args[i + 1], repo: repo) {
                navigator.push(PulseStrengthExerciseRoute(exercise: name).route)
            }
        }
        if let i = args.firstIndex(of: "--pulse-strength-workout"), i + 1 < args.count {
            await PulseStrengthDemo.seedIfRequested(repo: repo)
            let name = args[i + 1].replacingOccurrences(of: "_", with: " ")
            if let program = await PulseStrengthDemo.program(named: name, repo: repo) {
                navigator.push(PulseStrengthWorkoutRoute(programId: program.id).route)
            }
        }
        if let i = args.firstIndex(of: "--pulse-strength-live"), i + 1 < args.count {
            await PulseStrengthDemo.seedIfRequested(repo: repo)
            await PulseStrengthDemo.startLive(stage: args[i + 1], session: session, repo: repo)
            showsLive = true
        }
    }
    #endif
}

/// "•••": three small outlined circles (g01).
struct PulseStrengthMoreGlyph: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().strokeBorder(Color.white, lineWidth: 1.5).frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}

/// One muscle's week, drawn as the Lift Log draws it.
struct PulseStrengthMuscleBar: View {
    let muscle: StrengthMuscleWeek

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(muscle.name)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
                Spacer(minLength: 8)
                Text(muscle.setsText)
                    .font(PulseType.numeral(15))
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(PulseTheme.track)
                    Capsule()
                        .fill(PulseTheme.strain.opacity(muscle.atOrAboveFloor ? 1 : 0.45))
                        .frame(width: max(2, geo.size.width * muscle.fill))
                    Capsule()
                        .fill(PulseTheme.textPrimary.opacity(0.45))
                        .frame(width: 2)
                        .offset(x: max(0, geo.size.width * muscle.tick - 1))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(muscle.atOrAboveFloor
                            ? String(localized: "\(muscle.name): \(muscle.setsText) sets, at or above the weekly floor of 4")
                            : String(localized: "\(muscle.name): \(muscle.setsText) sets, below the weekly floor of 4"))
    }
}

/// What the program editor sheet edits: a program, or nil for a new one.
struct PulseStrengthEditTarget: Identifiable {
    let id = UUID()
    let program: LiftProgramRow?
}

/// The session whose detail sheet is open.
struct PulseStrengthSessionTarget: Identifiable {
    let session: LiftSessionRow
    var id: String { session.id }
}

/// Builds a session's plan from a program exactly as the Lift Log does (`LiftLogView.start`).
enum PulseStrengthSessionStarter {
    @MainActor
    static func plan(for program: LiftProgramRow, repo: Repository) async -> [LiftPlanItem]? {
        guard let store = await repo.storeHandle() else { return nil }
        let items = (try? await store.liftProgramItems(programId: program.id)) ?? []
        guard !items.isEmpty else { return [] }
        let vocabulary = (try? await store.liftExercises(deviceId: repo.deviceId)) ?? []
        return items.sorted { $0.ord < $1.ord }.map { item -> LiftPlanItem in
            // The classification comes from the exercise vocabulary, which owns it.
            let known = vocabulary.first { $0.name == item.exercise }
            return LiftPlanItem(exercise: item.exercise,
                                primaryMuscle: known?.primaryMuscle,
                                secondaryMuscles: known?.secondaryMuscles ?? [],
                                targetSets: item.targetSets,
                                restSec: item.restSec,
                                targetRepsLow: item.targetRepsLow,
                                targetRepsHigh: item.targetRepsHigh,
                                targetRpe: item.targetRpe,
                                targetWeightKg: item.targetWeightKg,
                                note: item.note,
                                programItemId: item.id)
        }
    }
}

/// ⓘ: how the Strength Trainer's figures are made.
struct PulseStrengthInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let points: [(String, String)] = [
        (String(localized: "Volume load"),
         String(localized: "Weight × reps, added up over a session's working sets. Warm-ups and sets you discarded don't count, and a set with no weight (bodyweight work) adds no volume.")),
        (String(localized: "Ø Volume load"),
         String(localized: "The average volume of the sessions you finished in the period shown. Each line on the chart is a month's (or a week's) average, with its change from the one before.")),
        (String(localized: "Personal records"),
         String(localized: "Your heaviest working set of each exercise, or the most reps for an exercise you've never logged with a weight. The estimated one-rep max uses the Epley formula, for sets of 12 reps or fewer.")),
        (String(localized: "Sets per muscle"),
         String(localized: "Counted from the muscles you gave each exercise: a direct set once, an indirect one half.")),
        (String(localized: "Strain"),
         String(localized: "Lifting never changes your Strain. ZENO measures Strain from your heart rate, so a workout gets its Strain from the strap, not from the numbers you type.")),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(points, id: \.0) { point in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(point.0)
                                .pulseText(.coachingTitle)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(point.1)
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(PulseTheme.Layout.pageMargin)
                .padding(.top, 8)
            }
            .background(PulseBackground())
            .pulseNavHeader(String(localized: "How it works"))
            .environment(\.pulseModalRoot, true)
        }
        .environment(\.colorScheme, .dark)
    }
}
#endif
