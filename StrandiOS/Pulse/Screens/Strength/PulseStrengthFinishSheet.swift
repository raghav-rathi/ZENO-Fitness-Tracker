#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// FINISH WORKOUT: the Lift Log's finish sheet in Pulse's look, asking the same questions and saving the
/// same way (`LiftSessionView.finishSheet` / `save`):
///   - how hard the whole session was (session RPE, optional), for Foster's session load;
///   - sets never started: complete them with their grey numbers, or discard them to zeros every figure
///     leaves out (one answer for all; a set that was done is never asked about);
///   - when set counts changed or exercises were added: keep them in the workout, or not;
///   - SAVE (after both answers), or DISCARD, which records nothing.
/// Saving files the session, its sets in the order they happened, the workout's new heaviest sets, and a
/// manual workout through the repository's own path, whose Strain the engine fills from heart rate.
struct PulseStrengthFinishSheet: View {
    /// Called once the session is saved or discarded, so the live screen can close.
    let onDone: () -> Void

    @EnvironmentObject private var session: LiftSessionController
    @EnvironmentObject private var repo: Repository

    @State private var sessionRpe: Int?
    @State private var unfinishedChoice: UnfinishedChoice?
    @State private var programChoice: ProgramChoice?
    @State private var setCountChanges: [LiftSessionController.SetCountChange] = []
    @State private var saving = false
    @State private var confirmingDiscard = false

    private enum UnfinishedChoice: Hashable { case complete, discard }
    private enum ProgramChoice: Hashable { case update, keep }

    private var addedExercises: [LiftPlanItem] {
        session.engine?.plan.filter(\.addedInSession) ?? []
    }

    private var unfinished: Int { session.unfinishedSlots.count }
    private var asksAboutProgram: Bool { !setCountChanges.isEmpty || !addedExercises.isEmpty }
    private var answered: Bool {
        (unfinished == 0 || unfinishedChoice != nil) && (!asksAboutProgram || programChoice != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rpeCard
                    if unfinished > 0 { unfinishedCard }
                    if asksAboutProgram { programCard }
                    Button(saving ? String(localized: "Saving…") : String(localized: "Save workout")) {
                        Task { await save() }
                    }
                    .buttonStyle(PulseStrengthSetButtonStyle(kind: .finish))
                    .disabled(saving || !answered)
                    .opacity(saving || !answered ? 0.4 : 1)
                    .padding(.top, 8)
                    if !answered {
                        Text(String(localized: "Choose an option above to save."))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                    Button(role: .destructive) { confirmingDiscard = true } label: {
                        Text(String(localized: "Discard workout"))
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(PulseTheme.recoveryLowText)
                            .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .disabled(saving)
                }
                .padding(PulseTheme.Layout.pageMargin)
            }
            .background(PulseBackground())
            .pulseNavHeader(String(localized: "Finish workout"))
            .environment(\.pulseModalRoot, true)
            .confirmationDialog(String(localized: "Discard this workout?"), isPresented: $confirmingDiscard,
                                titleVisibility: .visible) {
                Button(String(localized: "Discard"), role: .destructive) {
                    session.discard()
                    // Closing the live screen closes this sheet with it.
                    onDone()
                }
                Button(String(localized: "Keep going"), role: .cancel) { }
            } message: {
                Text(String(localized: "\(session.engine?.completedWorkingSets ?? 0) recorded sets will be thrown away. Nothing is saved and no workout is created."))
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDragIndicator(.visible)
        .task { await loadSetCountChanges() }
    }

    // MARK: Cards

    private var rpeCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                PulseCardTitle(String(localized: "How hard was the whole session?"))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            sessionRpe = sessionRpe == value ? nil : value
                        } label: {
                            Text(verbatim: "\(value)")
                                .font(PulseType.numeral(18))
                                .foregroundStyle(sessionRpe == value ? Color.black : PulseTheme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                                    .fill(sessionRpe == value ? Color.white : PulseTheme.nested))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityLabel(String(localized: "Session effort \(value) of 10"))
                        .accessibilityAddTraits(sessionRpe == value ? [.isSelected, .isButton] : .isButton)
                    }
                }
                Text(String(localized: "Optional. Session RPE × the session's length gives session load, the one figure that compares a leg day with a run."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var unfinishedCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                PulseCardTitle(String(localized: "Unfinished sets"))
                Text(String(localized: "Sets not started: \(unfinished)"))
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                PulseButtonRow {
                    choice(String(localized: "Complete them"), selected: unfinishedChoice == .complete) {
                        unfinishedChoice = .complete
                    }
                    choice(String(localized: "Discard them"), selected: unfinishedChoice == .discard) {
                        unfinishedChoice = .discard
                    }
                }
                Text(String(localized: "Completing saves them with the grey numbers shown. Discarding keeps them out of every figure; they stay under Edit sets as zeros you can fill in later."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                // Said before Save rather than after: saving files nothing when no set counts.
                if unfinishedChoice == .discard,
                   !LiftSessionController.anyPerformed(session.setsToSave(completingUnfinished: false)) {
                    Text(String(localized: "Every set would be a zero, so discarding saves no session and no workout."))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.negative)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var programCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                PulseCardTitle(String(localized: "Workout"))
                Text(programQuestion)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(setCountChanges, id: \.itemId) { change in
                    Text(String(localized: "\(change.exercise): \(change.from) → \(change.to) sets"))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                ForEach(Array(addedExercises.enumerated()), id: \.offset) { _, line in
                    Text(String(localized: "New: \(line.exercise) · sets: \(line.targetSets)"))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                PulseButtonRow {
                    choice(String(localized: "Update workout"), selected: programChoice == .update) { programChoice = .update }
                    choice(String(localized: "Keep as it was"), selected: programChoice == .keep) { programChoice = .keep }
                }
            }
        }
    }

    private var programQuestion: String {
        switch (!setCountChanges.isEmpty, !addedExercises.isEmpty) {
        case (true, true):
            return String(localized: "You added exercises and changed the number of sets. Keep these changes in the workout for next time?")
        case (false, true):
            return String(localized: "You added exercises. Add them to the workout for next time?")
        default:
            return String(localized: "You changed the number of sets. Keep the new counts in the workout for next time?")
        }
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .pulseText(.buttonLabel)
                .foregroundStyle(selected ? Color.black : PulseTheme.textButton)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.nestedButton)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                    .fill(selected ? Color.white : PulseTheme.nested))
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Saving (the Lift Log's, step for step)

    private func save() async {
        guard !saving, let store = await repo.storeHandle() else { return }
        saving = true
        defer { saving = false }

        session.finish()
        guard let engine = session.engine else { return }
        let endTs = Int(Date().timeIntervalSince1970)
        let sessionId = UUID().uuidString
        // After `finish`, which closes out the running rest: that set's measured rest belongs to it.
        let finished = session.setsToSave(completingUnfinished: unfinishedChoice == .complete)

        // Nothing to file, so file nothing (a session of zeros would still read back as a workout); the
        // workout's set counts are a separate choice, so those still apply.
        guard LiftSessionController.anyPerformed(finished) else {
            await writeProgram(store: store, plan: engine.plan, sets: finished)
            await finishAndClose()
            return
        }

        let row = LiftSessionRow(
            id: sessionId, deviceId: repo.deviceId,
            startTs: engine.startTs, endTs: endTs, sport: LiftSessionView.sport,
            programId: session.programId,
            programName: session.programName,
            sessionRpe: sessionRpe.map(Double.init),
            note: session.programName)
        _ = try? await store.upsertLiftSessions([row])

        // `ord` is completion order: the order the sets actually happened.
        let rows = finished.enumerated().map { ord, set -> LiftSetRow in
            let item = engine.planItem(for: set.slot)
            return LiftSetRow(
                id: UUID().uuidString, deviceId: repo.deviceId, sessionId: sessionId,
                ord: ord, exercise: item?.exercise ?? "",
                primaryMuscle: item?.primaryMuscle,
                secondaryMuscles: item?.secondaryMuscles ?? [],
                setIndex: set.slot.setIndex, weightKg: set.weightKg, reps: set.reps, rpe: set.rpe,
                isWarmup: set.isWarmup, startTs: set.startTs, endTs: set.endTs,
                restSec: set.restSec, note: nil)
        }
        _ = try? await store.upsertLiftSets(rows)
        await writeProgram(store: store, plan: engine.plan, sets: finished)

        // The same path a manual workout takes; `strain` stays nil for the engine to fill from the heart
        // rate the strap measured, never from typed sets and reps.
        let workout = WorkoutRow(
            startTs: engine.startTs, endTs: endTs, sport: LiftSessionView.sport,
            source: "manual", durationS: Double(max(0, endTs - engine.startTs)),
            energyKcal: nil, avgHr: nil, maxHr: nil, strain: nil,
            distanceM: nil, zonesJSON: nil, notes: session.programName, steps: nil)
        await repo.saveManualWorkout(workout)

        await finishAndClose()
    }

    private func finishAndClose() async {
        session.finishedSaving()
        await repo.refresh()
        PulseStrengthVersion.shared.bump()
        // Closing the live screen closes this sheet with it.
        onDone()
    }

    private func loadSetCountChanges() async {
        guard let programId = session.programId, let plan = session.engine?.plan,
              let store = await repo.storeHandle(),
              let rows = try? await store.liftProgramItems(programId: programId) else { return }
        setCountChanges = LiftSessionController.setCountChanges(plan: plan, program: rows)
    }

    /// The workout after this session (`LiftSessionController.programAfterSession`), written only when a
    /// line differs.
    private func writeProgram(store: WhoopStore, plan: [LiftPlanItem],
                              sets: [LiftSessionController.FinishedSet]) async {
        guard let programId = session.programId,
              let rows = try? await store.liftProgramItems(programId: programId) else { return }
        let edited = LiftSessionController.programAfterSession(
            sets, plan: plan, program: rows, keepingChanges: programChoice == .update,
            programId: programId, deviceId: repo.deviceId)
        guard edited != rows else { return }
        _ = try? await store.replaceLiftProgramItems(programId: programId, items: edited)
    }
}
#endif
