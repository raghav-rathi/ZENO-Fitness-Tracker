#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// The live session's EXERCISES tab (activity-flows-2026/g08): a card per line with its sets as rows of
/// input boxes — REPS, WEIGHT and RPE (the Lift Log keeps RPE; WHOOP has none) — and a "▶" that starts that
/// set (any set, any time: a gym is not a queue). The set being worked is outlined green; a done set shows
/// ✓ and can be redone. The set number is the warm-up toggle ("W"); "− +" drops or adds a set.
///
/// Every keystroke goes through the controller exactly as the Lift Log's sheet sends it
/// (`LiftSessionView`): a performed set is edited, a pending one holds its numbers until it is performed;
/// while a field is focused it shows what was typed (so "45." keeps its point), commas become points.
struct PulseStrengthExercisesTab: View {
    let onDetails: (String) -> Void
    let onAddExercise: () -> Void

    @EnvironmentObject private var session: LiftSessionController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @FocusState private var focused: Field?
    @State private var draft: [Field: String] = [:]

    enum Field: Hashable {
        case weight(LiftSlot), reps(LiftSlot), rpe(LiftSlot)
    }

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }

    var body: some View {
        if let engine = session.engine {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(Array(engine.plan.enumerated()), id: \.offset) { index, item in
                            card(engine, index: index, item: item)
                                .id(index)
                        }
                        Button(action: onAddExercise) {
                            Label(String(localized: "Add exercise"), systemImage: "plus")
                        }
                        .buttonStyle(.pulseNested)
                        .disabled(engine.plan.count >= LiftSessionEngine.maxExercises)
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                // Follow the session down the list when it moves on its own.
                .onChange(of: engine.currentSlot) { _, slot in
                    guard let slot else { return }
                    withAnimation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion)) {
                        proxy.scrollTo(slot.exerciseIndex, anchor: .top)
                    }
                }
            }
            .pulseKeyboardDone($focused)
            // A field's draft is dropped once it loses focus, so it shows the canonical number again.
            .onChange(of: focused) { _, now in
                draft = draft.filter { $0.key == now }
            }
        }
    }

    // MARK: Card

    private func card(_ engine: LiftSessionEngine, index: Int, item: LiftPlanItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                PulseStrengthThumbnail(width: 68, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.exercise)
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(2)
                    Text(item.targetSets == 1 ? String(localized: "1 Set") : String(localized: "\(item.targetSets) Sets"))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                Spacer(minLength: 4)
                PulseInfoButton(accessibilityLabel: String(localized: "Exercise details")) { onDetails(item.exercise) }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PulseStrengthColors.exerciseCardTop)

            VStack(alignment: .leading, spacing: 10) {
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                columnHeadings
                ForEach(engine.slots(forExercise: index), id: \.self) { slot in
                    setRow(engine, slot: slot)
                }
                setCountRow(engine, index: index, item: item)
            }
            .padding(14)
        }
        .background(PulseStrengthColors.exerciseCard)
        .clipShape(RoundedRectangle(cornerRadius: PulseStrengthMetrics.exerciseCardRadius, style: .circular))
    }

    private var columnHeadings: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: 26, height: 1)
            Text(String(localized: "Reps")).frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "Weight (\(LiftFormat.weightUnit(unitSystem)))")).frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "RPE")).frame(width: 52, alignment: .leading)
            Color.clear.frame(width: 34, height: 1)
        }
        .pulseText(.label)
        .foregroundStyle(PulseTheme.textTertiary)
        // "WEIGHT (KG)" takes a second line at the largest text sizes instead of being cut off.
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }

    private func setRow(_ engine: LiftSessionEngine, slot: LiftSlot) -> some View {
        let recorded = engine.recordedSet(for: slot) != nil
        let working = engine.stage == .working(slot)
        let warmup = session.isWarmup(slot)
        return HStack(spacing: 8) {
            // The set number IS the warm-up toggle, as on the Lift Log's sheet.
            Button {
                session.setWarmup(slot, !warmup)
            } label: {
                Text(warmup ? String(localized: "W") : "\(slot.setIndex)")
                    .font(PulseType.numeral(19))
                    .foregroundStyle(warmup ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    .frame(width: 26, height: 40)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                        .fill(warmup ? PulseTheme.tagFill : Color.clear))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(warmup ? String(localized: "Warm-up set, tap to make it a working set")
                                       : String(localized: "Set \(slot.setIndex), tap to mark it a warm-up"))
            field(.reps(slot), text: repsBinding(slot), ghost: ghostReps(slot),
                  label: fieldLabel(slot, warmup: warmup, column: String(localized: "reps")))
            field(.weight(slot), text: weightBinding(slot), ghost: ghostWeight(slot),
                  label: fieldLabel(slot, warmup: warmup,
                                    column: String(localized: "weight in \(LiftFormat.weightUnit(unitSystem))")))
            field(.rpe(slot), text: rpeBinding(slot), ghost: ghostRpe(engine, slot: slot),
                  label: fieldLabel(slot, warmup: warmup, column: String(localized: "RPE")))
                .frame(width: 52)
            Button {
                session.start(slot)
            } label: {
                Image(systemName: recorded ? "checkmark" : (working ? "timer" : "play.fill"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(recorded || working ? PulseTheme.Activity.strengthActiveTimer : PulseTheme.textPrimary)
                    .frame(width: 34, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(working)
            .accessibilityLabel(recorded ? String(localized: "Redo this set")
                                         : (working ? String(localized: "This set is running") : String(localized: "Start this set")))
        }
        .padding(4)
        .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
            .strokeBorder(PulseTheme.Activity.strengthActiveTimer.opacity(working ? 0.8 : 0), lineWidth: 1))
    }

    /// What VoiceOver calls a set's field: "Set 2 reps", "Warm-up set weight in kg".
    private func fieldLabel(_ slot: LiftSlot, warmup: Bool, column: String) -> String {
        warmup ? String(localized: "Warm-up set \(column)") : String(localized: "Set \(slot.setIndex) \(column)")
    }

    private func field(_ key: Field, text: Binding<String>, ghost: String, label: String) -> some View {
        // The grey number is drawn here rather than as the field's prompt, so it is always grey: a number
        // nobody typed must never read like one that was.
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(ghost)
                    .font(PulseType.numeral(18))
                    .foregroundStyle(PulseTheme.textDisabled)
                    .accessibilityHidden(true)
            }
            TextField("", text: text)
                .font(PulseType.numeral(18))
                .foregroundStyle(PulseTheme.textPrimary)
                .numericKeyboard()
                .focused($focused, equals: key)
                .accessibilityLabel(label)
                .accessibilityValue(text.wrappedValue.isEmpty ? String(localized: "\(ghost), not entered") : text.wrappedValue)
        }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                .fill(PulseStrengthColors.inputFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                .strokeBorder(focused == key ? PulseTheme.textSecondary : PulseStrengthColors.inputBorder, lineWidth: 1))
    }

    /// "− +": drop the last pending set or add one (the session's own rules decide when they may).
    private func setCountRow(_ engine: LiftSessionEngine, index: Int, item: LiftPlanItem) -> some View {
        let canAdd = item.targetSets < LiftSessionEngine.maxSetsPerExercise
        let canRemove = engine.canRemoveSet(fromExercise: index)
        return HStack(spacing: 8) {
            countButton("minus", enabled: canRemove, label: String(localized: "Remove the last set from \(item.exercise)")) {
                session.removeSet(fromExercise: index)
            }
            countButton("plus", enabled: canAdd, label: String(localized: "Add a set to \(item.exercise)")) {
                session.addSet(toExercise: index)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private func countButton(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 42, height: 36)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(PulseTheme.nested))
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    // MARK: Grey numbers (the controller's one chain)

    private func ghostWeight(_ slot: LiftSlot) -> String {
        session.carry(for: slot).weightKg.map { StrengthFormat.weight($0, unitSystem) } ?? "–"
    }

    private func ghostReps(_ slot: LiftSlot) -> String {
        session.carry(for: slot).reps.map(String.init) ?? "–"
    }

    /// The line's max RPE when the program sets one (what a blank saves); else a previous set's rating,
    /// shown as a reminder and never saved.
    private func ghostRpe(_ engine: LiftSessionEngine, slot: LiftSlot) -> String {
        if let planned = engine.planItem(for: slot)?.targetRpe { return LiftFormat.trim(planned) }
        return engine.previousSetInSession(for: slot)?.rpe.map { LiftFormat.trim($0) } ?? "–"
    }

    // MARK: Bindings (the Lift Log sheet's, unchanged in behaviour)

    private func fieldBinding(_ field: Field, formatted: @escaping () -> String,
                              store: @escaping (String) -> Void) -> Binding<String> {
        Binding(
            get: { draft[field] ?? formatted() },
            set: { typed in
                let text = typed.replacingOccurrences(of: ",", with: ".")
                draft[field] = text
                store(text)
            })
    }

    private func weightBinding(_ slot: LiftSlot) -> Binding<String> {
        fieldBinding(.weight(slot),
                     formatted: { session.enteredValues(for: slot).weightKg.map { StrengthFormat.weight($0, unitSystem) } ?? "" },
                     store: { text in
                         let kg = LiftFormat.number(text).map { LiftFormat.kilograms(fromDisplay: $0, system: unitSystem) }
                         write(slot) { $0.weightKg = kg }
                     })
    }

    private func repsBinding(_ slot: LiftSlot) -> Binding<String> {
        fieldBinding(.reps(slot),
                     formatted: { session.enteredValues(for: slot).reps.map(String.init) ?? "" },
                     store: { text in
                         write(slot) { $0.reps = Int(text.trimmingCharacters(in: .whitespaces)) }
                     })
    }

    private func rpeBinding(_ slot: LiftSlot) -> Binding<String> {
        fieldBinding(.rpe(slot),
                     formatted: { session.enteredValues(for: slot).rpe.map { LiftFormat.trim($0) } ?? "" },
                     store: { text in write(slot) { $0.rpe = LiftFormat.number(text) } })
    }

    /// One field's change, the slot's other fields as they were (performed or not: the controller decides).
    private func write(_ slot: LiftSlot, _ mutate: (inout LiftRecordedSet) -> Void) {
        let entered = session.enteredValues(for: slot)
        var row = LiftRecordedSet(exerciseIndex: slot.exerciseIndex, setIndex: slot.setIndex,
                                  weightKg: entered.weightKg, reps: entered.reps, rpe: entered.rpe,
                                  isWarmup: session.isWarmup(slot), startTs: 0, endTs: 0, restSec: nil)
        mutate(&row)
        session.updateSet(slot, weightKg: row.weightKg, reps: row.reps, rpe: row.rpe, isWarmup: row.isWarmup)
    }
}
#endif
