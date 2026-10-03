#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Which day the log sheet opens on, and which section it scrolls to.
struct PulseCycleLogTarget: Identifiable, Equatable {
    let day: String
    var focus: PulseCycleLogSheet.Section = .flow
    var id: String { day + focus.rawValue }
}

/// The flow row's glyph: an empty drop for no flow, scattered dots for spotting, then one, two or three
/// drops by volume (help-center/09).
struct PulseCycleFlowIcon: View {
    let flow: MenstrualCycleModel.Flow

    var body: some View {
        let coral = PulseCyclePhase.menstrual.dot
        switch flow {
        case .noFlow:
            Image(systemName: "drop")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
        case .spotting:
            ZStack {
                ForEach(Array([(-5.0, -4.0), (2.0, -6.0), (-2.0, 3.0), (5.0, 2.0), (0.0, 8.0)].enumerated()), id: \.offset) { _, p in
                    Circle().fill(coral.opacity(0.85)).frame(width: 3.5, height: 3.5).offset(x: p.0, y: p.1)
                }
            }
            .frame(width: 22, height: 22)
        case .light, .medium, .heavy:
            let count = flow == .light ? 1 : (flow == .medium ? 2 : 3)
            HStack(spacing: -1) {
                ForEach(0..<count, id: \.self) { _ in
                    Image(systemName: "drop.fill")
                        .font(.system(size: count == 3 ? 10 : (count == 2 ? 12 : 15), weight: .regular))
                }
            }
            .foregroundStyle(coral)
        }
    }
}

// MARK: - Symptoms sheet (WHOOP_UI_SPEC §3.24 "Symptoms sheet"; help-center/09)
//
// "SYMPTOMS ✕", the day ("Wed, Oct 08") with ‹ › to step back through earlier days, filter chips that jump
// to a section, then PERIOD FLOW (one choice; the selected row takes a coral border) and the symptom groups
// (any number; the selected rows a white border). Every tap is saved at once, on this iPhone; logging flow
// keeps the period start in step (`Repository.setCycleFlow`). Cervical-mucus logging is left out on
// purpose: it is a fertility signal, and these insights are not fertility tracking.
struct PulseCycleLogSheet: View {
    enum Section: String, CaseIterable, Identifiable {
        case flow, pain, body, mood, sleepEnergy
        var id: String { rawValue }

        var group: PulseCycleLog.Group? {
            switch self {
            case .flow: return nil
            case .pain: return .pain
            case .body: return .body
            case .mood: return .mood
            case .sleepEnergy: return .sleepEnergy
            }
        }

        var title: String {
            group?.title ?? String(localized: "Flow")
        }
    }

    let initial: PulseCycleLogTarget
    /// The earliest day the pager steps back to.
    let earliestDay: String
    let today: String

    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss

    @State private var day: String = ""
    @State private var flow: MenstrualCycleModel.Flow?
    @State private var symptoms: Set<String> = []
    @State private var loaded = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dayRow
                        .padding(.top, 8)
                    filterChips(proxy)
                        .padding(.top, 18)
                    flowSection
                        .id(Section.flow.id)
                        .padding(.top, 26)
                    ForEach(PulseCycleLog.Group.allCases) { group in
                        symptomSection(group)
                            .id(section(for: group).id)
                            .padding(.top, 30)
                    }
                    Text(String(localized: "Saved as you tap, on this iPhone only."))
                        .pulseText(.legend)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .task {
                guard !loaded else { return }
                loaded = true
                day = initial.day
                await load()
                if initial.focus != .flow {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(initial.focus.id, anchor: .top) }
                }
            }
        }
        .background(PulseBackground())
        .safeAreaInset(edge: .top, spacing: 0) { bar }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }

    private func section(for group: PulseCycleLog.Group) -> Section {
        Section.allCases.first { $0.group == group } ?? .flow
    }

    private var bar: some View {
        ZStack {
            Text(String(localized: "Symptoms"))
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Spacer()
                PulseCloseButton { dismiss() }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, 12)
        // The page's top colour behind the bar, fading over 24 pt below it, so rows scroll under cleanly.
        .background(alignment: .top) {
            VStack(spacing: 0) {
                PulseTheme.pageTop
                    .frame(height: PulseTheme.Header.navBar + 12)
                LinearGradient(colors: [PulseTheme.pageTop, PulseTheme.pageTop.opacity(0)], startPoint: .top,
                               endPoint: .bottom)
                    .frame(height: PulseTheme.Header.barFade)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var dayRow: some View {
        HStack(spacing: 4) {
            Text(day.isEmpty ? "" : PulseFormat.dayLabel(day, template: "EEEMMMdd"))
                .pulseText(.pageTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            stepButton("chevron.left", enabled: day > earliestDay, label: String(localized: "Previous day")) { step(-1) }
            stepButton("chevron.right", enabled: !day.isEmpty && day < today, label: String(localized: "Next day")) { step(1) }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func filterChips(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Section.allCases) { s in
                    PulseFilterChip(title: s.title, isSelected: false) {
                        withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(s.id, anchor: .top) }
                    }
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .padding(.horizontal, -PulseTheme.Layout.pageMargin)
    }

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseListSectionHeader(String(localized: "Period flow"))
                .padding(.bottom, 4)
            ForEach([MenstrualCycleModel.Flow.noFlow, .spotting, .light, .medium, .heavy], id: \.self) { option in
                let selected = flow == option
                Button { choose(option) } label: {
                    row(title: PulseCycleLog.title(option), selected: selected, tint: PulseCyclePhase.menstrual.dot) {
                        PulseCycleFlowIcon(flow: option)
                    }
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityHint(selected ? String(localized: "Tap again to clear") : "")
            }
        }
    }

    private func symptomSection(_ group: PulseCycleLog.Group) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseListSectionHeader(group.title)
                .padding(.bottom, 4)
            ForEach(PulseCycleLog.symptoms.filter { $0.group == group }) { symptom in
                let selected = symptoms.contains(symptom.id)
                Button { toggle(symptom.id) } label: {
                    row(title: symptom.title, selected: selected, tint: PulseTheme.textPrimary) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(selected ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    }
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    private func row<Icon: View>(title: String, selected: Bool, tint: Color,
                                 @ViewBuilder icon: () -> Icon) -> some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        return HStack(spacing: 16) {
            icon()
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(title)
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(shape.fill(selected ? tint.opacity(0.12) : PulseTheme.card))
        .overlay(shape.strokeBorder(selected ? tint : Color.clear, lineWidth: 1.5))
        .contentShape(shape)
    }

    // MARK: Data

    private func load() async {
        let logs = await repo.cycleLogs()
        flow = logs.flow[day]
        symptoms = logs.symptoms[day] ?? []
    }

    private func step(_ delta: Int) {
        guard let next = MenstrualCycleModel.shift(day, by: delta), next <= today, next >= earliestDay else { return }
        day = next
        Task { await load() }
    }

    private func choose(_ option: MenstrualCycleModel.Flow) {
        let new: MenstrualCycleModel.Flow? = flow == option ? nil : option
        flow = new
        let target = day
        Task { await repo.setCycleFlow(new, day: target) }
    }

    private func toggle(_ id: String) {
        let on = !symptoms.contains(id)
        if on { symptoms.insert(id) } else { symptoms.remove(id) }
        let target = day
        Task { await repo.setCycleSymptom(id, logged: on, day: target) }
    }
}
#endif
