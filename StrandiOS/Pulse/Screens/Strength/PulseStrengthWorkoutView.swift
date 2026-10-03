#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// A saved workout, pushed from MY WORKOUTS (completeness-critic/07): "‹ NAME ✎", an exercise card per
/// line with its planned sets (REPS · WEIGHT) and technique note, and START WORKOUT pinned at the bottom.
/// The plan is edited in the Lift Log's program editor (✎); this page reads it.
struct PulseStrengthWorkoutRoute: PulseScreenRoute {
    let programId: String

    var view: some View { PulseStrengthWorkoutView(programId: programId) }
}

struct PulseStrengthWorkoutView: View {
    let programId: String

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var session: LiftSessionController
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @State private var snapshot: StrengthTrainerSnapshot?
    @State private var editing: PulseStrengthEditTarget?
    @State private var starting = false

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
    private var workout: StrengthWorkout? { snapshot?.workouts.first { $0.program.id == programId } }

    var body: some View {
        PulseScreenScaffold(title: workout?.program.name ?? String(localized: "Workout"),
                            trailing: .symbol("pencil", accessibilityLabel: String(localized: "Edit workout")) {
                                if let workout { editing = PulseStrengthEditTarget(program: workout.program) }
                            },
                            spacing: 12,
                            ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let workout {
                    content(workout)
                } else {
                    PulseCard {
                        Text(String(localized: "This workout no longer exists."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
            } skeleton: {
                PulseSkeleton.cards([220, 220])
            }
        }
        // START WORKOUT is pinned over the page's foot, which fades out under it down to the screen edge.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let workout {
                startButton(workout)
            }
        }
        .task(id: "\(model.detailKey)|\(PulseStrengthVersion.shared.value)|\(unitSystemRaw)") { await load() }
        .sheet(item: $editing) { target in
            LiftProgramEditorSheet(program: target.program) { PulseStrengthVersion.shared.bump() }
        }
    }

    private func load() async {
        let version = PulseStrengthVersion.shared.value
        let system = unitSystem
        if let built = await model.build(dayOffset: 0, { builder, request in
            await builder.strengthTrainer(request, version: version, range: .sixMonths, page: 0, system: system)
        }) {
            snapshot = built
        }
    }

    @ViewBuilder
    private func content(_ workout: StrengthWorkout) -> some View {
        // What MY WORKOUTS' one-line row leaves out.
        Text([workout.detail, workout.lastDone].compactMap { $0 }.joined(separator: " · "))
            .pulseText(.secondary)
            .foregroundStyle(PulseTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
        if let note = workout.program.note, !note.isEmpty {
            Text(note)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        if workout.lines.isEmpty {
            PulseCard {
                Text(String(localized: "No exercises yet. Tap ✎ to add them."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        ForEach(workout.lines) { line in
            lineCard(line)
        }
    }

    private func lineCard(_ line: StrengthWorkout.Line) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                PulseStrengthThumbnail(width: 68, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.exercise)
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(2)
                    Text(line.setsText)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PulseStrengthColors.exerciseCardTop)

            VStack(alignment: .leading, spacing: 10) {
                if let note = line.note {
                    Text(note)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 2)
                }
                HStack(spacing: 10) {
                    Color.clear.frame(width: 18, height: 1)
                    Text(String(localized: "Reps")).frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(localized: "Weight (\(LiftFormat.weightUnit(unitSystem)))")).frame(maxWidth: .infinity, alignment: .leading)
                }
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                ForEach(line.sets) { set in
                    HStack(spacing: 10) {
                        Text(verbatim: "\(set.id)")
                            .font(PulseType.numeral(17))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(width: 18)
                        valueBox(set.reps)
                        valueBox(set.weight)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "Set \(set.id): \(set.reps ?? "no") reps, \(set.weight ?? "no") \(LiftFormat.weightUnit(unitSystem))"))
                }
                Text(line.rest)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 2)
            }
            .padding(16)
        }
        .background(PulseStrengthColors.exerciseCard)
        .clipShape(RoundedRectangle(cornerRadius: PulseStrengthMetrics.exerciseCardRadius, style: .circular))
    }

    private func valueBox(_ value: String?) -> some View {
        Text(value ?? "–")
            .font(PulseType.numeral(18))
            .foregroundStyle(value == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                .fill(PulseStrengthColors.inputFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                .strokeBorder(PulseStrengthColors.inputBorder, lineWidth: 1))
    }

    private func startButton(_ workout: StrengthWorkout) -> some View {
        let running = session.isActive
        return Button {
            Task { await start(workout) }
        } label: {
            Text(running ? String(localized: "Resume workout") : String(localized: "Start workout"))
        }
        .buttonStyle(PulseStrengthSetButtonStyle(kind: .start))
        .disabled(starting || workout.lines.isEmpty)
        .opacity(workout.lines.isEmpty ? 0.4 : 1)
        .padding(.horizontal, PulseTheme.Layout.pageMargin + 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
        // The page's foot fades out from 28 pt above the capsule and stays opaque down through the
        // home-indicator strip, so no card shows under it at full strength (completeness-critic/07).
        .background {
            LinearGradient(stops: [.init(color: PulseTheme.pageBottom.opacity(0), location: 0),
                                   .init(color: PulseTheme.pageBottom, location: 0.3)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
    }

    /// START WORKOUT: a new session, or the one already running; either raises `isPresented`, and the host
    /// of the modal this page is pushed in (the Strength Trainer's) opens the live screen.
    private func start(_ workout: StrengthWorkout) async {
        if session.isActive {
            session.isPresented = true
            return
        }
        starting = true
        defer { starting = false }
        guard let plan = await PulseStrengthSessionStarter.plan(for: workout.program, repo: repo), !plan.isEmpty else { return }
        session.start(plan: plan, programId: workout.program.id, programName: workout.program.name)
    }
}
#endif
