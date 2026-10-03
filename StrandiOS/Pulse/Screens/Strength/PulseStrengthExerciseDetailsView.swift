#if os(iOS)
import SwiftUI
import StrandDesign

/// Exercise Details (WHOOP_UI_SPEC §3.29; activity-flows-2026/g03): "‹ EXERCISE DETAILS ⓘ", the name, the
/// chips Progress | History | Instructions, then:
///   - Progress: AVG VOLUME LOAD with its change against the period before, M | 6M and the pager, the
///     monthly-segment chart, and Personal Records (the best sets, medals for the top three, each opening
///     to its estimated one-rep max);
///   - History: every session with this exercise, its sets as logged;
///   - Instructions: text only (spec [Z]): the technique notes the wearer's workouts carry for it, and its
///     muscles. WHOOP's hero photo and videos are its content and are not copied.
struct PulseStrengthExerciseRoute: PulseScreenRoute {
    let exercise: String

    var view: some View { PulseStrengthExerciseDetailsView(exercise: exercise) }
}

struct PulseStrengthExerciseDetailsView: View {
    let exercise: String

    enum Section: Hashable {
        case progress, history, instructions
    }

    @Environment(PulseModel.self) private var model
    @EnvironmentObject private var session: LiftSessionController
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @State private var section: Section = .progress
    @State private var range: StrengthRange = .sixMonths
    @State private var page = 0
    @State private var snapshot: StrengthExerciseSnapshot?
    @State private var expanded: Set<Int> = []
    @State private var showsInfo = false

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Exercise Details"),
                            trailing: .info { showsInfo = true },
                            coach: .button,
                            spacing: 16,
                            ready: snapshot != nil) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise)
                    .pulseText(.weeklyTrendsTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let muscles = snapshot?.muscles {
                    Text(muscles)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .padding(.top, 6)
            HStack(spacing: 8) {
                PulseFilterChip(title: String(localized: "Progress"), isSelected: section == .progress) { section = .progress }
                PulseFilterChip(title: String(localized: "History"), isSelected: section == .history) { section = .history }
                PulseFilterChip(title: String(localized: "Instructions"), isSelected: section == .instructions) {
                    section = .instructions
                }
            }
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot {
                    switch section {
                    case .progress: progress(snapshot)
                    case .history: history(snapshot)
                    case .instructions: instructions(snapshot)
                    }
                }
            } skeleton: {
                PulseSkeleton.cards([90, 260, 64])
            }
        }
        .task(id: "\(model.detailKey)|\(PulseStrengthVersion.shared.value)|\(session.savedSessions)|\(range.rawValue)|\(page)|\(unitSystemRaw)") {
            await load()
        }
        .sheet(isPresented: $showsInfo) { PulseStrengthInfoSheet() }
    }

    private func load() async {
        let version = PulseStrengthVersion.shared.value
        let exercise = self.exercise
        let range = self.range
        let page = self.page
        let system = unitSystem
        if let built = await model.build(dayOffset: 0, { builder, request in
            await builder.strengthExercise(request, version: version, exercise: exercise, range: range, page: page,
                                           system: system)
        }) {
            snapshot = built
        }
    }

    // MARK: Progress

    @ViewBuilder
    private func progress(_ snapshot: StrengthExerciseSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PulseStrengthChartHeader(label: String(localized: "Avg volume load"), value: snapshot.averageVolume,
                                     unit: snapshot.unit, range: $range, pager: snapshot.pager,
                                     onBack: { page += 1 }, onForward: { page = max(0, page - 1) })
            if let change = snapshot.change {
                changeChip(change)
                    .padding(.top, 6)
            }
            if snapshot.chart.points.isEmpty {
                Text(String(localized: "No weighted sets of this exercise in this period."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                PulseStrengthVolumeChart(chart: snapshot.chart, height: 260)
                    .padding(.top, 8)
            }
            Text(String(localized: "Personal Records"))
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 28)
                .padding(.bottom, 14)
            if snapshot.topSets.isEmpty {
                PulseCard {
                    Text(String(localized: "No completed sets yet."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshot.topSets) { set in
                        topSetCard(set, unit: snapshot.unit)
                    }
                }
            }
        }
    }

    /// "▼ 3% vs. prior 6 months": orange when volume fell, teal when it rose, grey when unchanged.
    private func changeChip(_ change: StrengthExerciseSnapshot.Change) -> some View {
        let trend: PulseTrend = change.up.map { PulseTrend(direction: $0 ? .up : .down, polarity: .higherIsBetter) }
            ?? PulseTrend(direction: .flat, polarity: .higherIsBetter)
        return PulseDeltaChip(text: change.text, trend: trend)
    }

    private func topSetCard(_ set: StrengthExerciseSnapshot.TopSet, unit: String) -> some View {
        let open = expanded.contains(set.id)
        return Button {
            if open { expanded.remove(set.id) } else { expanded.insert(set.id) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    if let weight = set.weight {
                        PulseValueText(value: weight, unit: unit, style: .rowValue, unitStyle: .secondary,
                                       unitColor: PulseTheme.textSecondary)
                    }
                    if let reps = set.reps {
                        PulseValueText(value: reps, unit: String(localized: "reps"), style: .rowValue,
                                       unitStyle: .secondary, unitColor: PulseTheme.textSecondary)
                    }
                    if set.rank <= 3 {
                        medal(set.rank)
                    }
                    Spacer(minLength: 6)
                    Text(set.date)
                        .pulseText(.pillTitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .rotationEffect(.degrees(open ? 180 : 0))
                        .accessibilityHidden(true)
                }
                if open {
                    VStack(alignment: .leading, spacing: 4) {
                        if let workout = set.workout {
                            Text(workout)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                        Text(set.estimate ?? String(localized: "No one-rep max estimate: it needs a weight and 12 reps or fewer."))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseStrengthColors.rowFill))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(open ? String(localized: "Collapses") : String(localized: "Shows the estimated one-rep max"))
    }

    /// A gold, silver or bronze medal (SF Symbol; WHOOP's medal art is not copied).
    private func medal(_ rank: Int) -> some View {
        let tint: Color
        switch rank {
        case 1: tint = PulseStrengthColors.gold
        case 2: tint = PulseStrengthColors.silver
        default: tint = PulseStrengthColors.bronze
        }
        return ZStack {
            Image(systemName: "medal.fill")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(tint)
            Text(verbatim: "\(rank)")
                .font(PulseType.numeral(9))
                .foregroundStyle(Color.black.opacity(0.75))
                .offset(y: 3)
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Rank \(rank)"))
    }

    // MARK: History

    @ViewBuilder
    private func history(_ snapshot: StrengthExerciseSnapshot) -> some View {
        if snapshot.history.isEmpty {
            PulseCard {
                Text(String(localized: "No sessions with this exercise yet."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(snapshot.history) { item in
                    PulseCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.title)
                                    .pulseText(.cardTitle)
                                    .foregroundStyle(PulseTheme.textPrimary)
                                Spacer(minLength: 8)
                                Text(item.date)
                                    .pulseText(.secondary)
                                    .foregroundStyle(PulseTheme.textTertiary)
                            }
                            ForEach(Array(item.sets.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .pulseText(.body)
                                    .foregroundStyle(PulseTheme.textSecondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: Instructions

    @ViewBuilder
    private func instructions(_ snapshot: StrengthExerciseSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let muscles = snapshot.muscles {
                PulseCard {
                    VStack(alignment: .leading, spacing: 6) {
                        PulseLabel(String(localized: "Muscle groups"))
                        Text(muscles)
                            .pulseText(.rowText)
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                }
            }
            if snapshot.notes.isEmpty {
                PulseCard {
                    Text(String(localized: "No instructions saved. A technique note you add to this exercise in a workout shows here."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(snapshot.notes) { note in
                    PulseCard {
                        VStack(alignment: .leading, spacing: 6) {
                            PulseLabel(note.workout)
                            Text(note.text)
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}
#endif
