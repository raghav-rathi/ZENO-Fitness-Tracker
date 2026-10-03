#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// App Settings › ACTIVITY SETTINGS › HEART RATE SETTINGS (WHOOP_UI_SPEC §3.33, help-center/98, 99).
struct PulseHeartRateSettingsRoute: PulseScreenRoute {
    var view: some View { PulseHeartRateSettingsView() }
}

/// "‹ HEART RATE SETTINGS": "Heart Rate Zones" with the heart-rate-reserve paragraph; RESTING HR (read
/// only) beside MAX HR (editable); the "Manual Heart Rate Zones" switch with its helper; a ZONE · ZONE MIN ·
/// ZONE MAX table of Zone 5 → 1, each edged in its zone colour, with bpm boxes; then SAVE HR ZONES
/// (disabled until something changes) and CANCEL.
///
/// Everything binds the profile the classic Settings edits: the max is `hrMaxOverride` (0 = the age
/// estimate), the resting heart rate is `zoneRestingHR` (the latest scored night, read only), and manual
/// zones are the five inclusive zone starts `setCustomHRZonesEnabled` seeds. ZENO's zones are contiguous,
/// so a zone's MAX is the next zone's MIN less one: editing either moves both, and Zone 5 ends at the max.
struct PulseHeartRateSettingsView: View {
    @EnvironmentObject private var profile: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft = HRSettingsDraft()
    @State private var saved = HRSettingsDraft()
    @State private var loaded = false
    @State private var explainer: HRExplainer?
    @FocusState private var focusedField: HRField?

    /// Max heart rates the profile accepts, as Edit Profile's picker offers them.
    private static let maxRange = 140...230

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Heart rate settings"), spacing: 0, topPadding: 12) {
            Text(String(localized: "Heart Rate Zones"))
                .pulseText(.sectionTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "Calculated with the heart-rate reserve formula: your zones are personalized from your resting heart rate and your maximum heart rate."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            inputs
                .padding(.top, 24)
            manualSwitch
                .padding(.top, 24)
            zoneTable
                .padding(.top, 22)
            if let problem = validationProblem {
                Text(problem)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.Onboarding.validationText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }
            actions
                .padding(.top, 36)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) { focusedField = nil }
            }
        }
        .fullScreenCover(item: $explainer) { explainer in
            PulseDialogCard(title: explainer.title, message: explainer.message(estimate: tanakaEstimate),
                            primaryTitle: String(localized: "Okay"), primary: { self.explainer = nil },
                            onClose: { self.explainer = nil })
                .presentationBackground(.clear)
        }
        .onAppear(perform: load)
        // The zone starts the profile holds can change under the page (the switch seeds them).
        .onChange(of: profile.hrZoneThresholds) { _, _ in reloadZones() }
    }

    // MARK: RESTING HR · MAX HR

    private var inputs: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(String(localized: "Resting HR"), explainer: .resting)
                HRValueBox(text: .constant(restingText), editable: false, invalid: false,
                           accessibilityLabel: String(localized: "Resting heart rate"),
                           focus: $focusedField, field: .resting)
                Text(profile.zoneRestingHR == nil ? String(localized: "After your first scored night")
                                                  : String(localized: "From your latest night"))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(String(localized: "Max HR"), explainer: .max)
                HRValueBox(text: digitsBinding(\.maxHR), editable: true, invalid: maxInvalid,
                           accessibilityLabel: String(localized: "Maximum heart rate"),
                           focus: $focusedField, field: .maxHR)
                if overridden {
                    Button { draft.maxHR = String(tanakaEstimate) } label: {
                        Text(String(localized: "Use age estimate (\(tanakaEstimate))"))
                            .pulseText(.legend)
                            .foregroundStyle(PulseTheme.recoveryBlue)
                            .frame(minHeight: 22, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                } else {
                    Text(String(localized: "Estimated from your age"))
                        .pulseText(.legend)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
    }

    private func fieldLabel(_ title: String, explainer: HRExplainer) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
            Button { self.explainer = explainer } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(11)
                    .contentShape(Rectangle())
                    .padding(-11)
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "About \(title)"))
        }
    }

    // MARK: Manual zones

    private var manualSwitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(String(localized: "Manual Heart Rate Zones"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 8)
                Toggle(String(localized: "Manual Heart Rate Zones"),
                       isOn: Binding(get: { profile.hasCustomHRZones },
                                     set: { on in
                                         focusedField = nil
                                         profile.setCustomHRZonesEnabled(on)
                                         reloadZones()
                                     }))
                    .toggleStyle(MoreSwitchStyle())
            }
            Text(String(localized: "As your fitness and resting heart rate change, your zones adjust on their own. Set them yourself if they don't feel right."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Zone table

    private var zoneTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(String(localized: "Zone")).frame(width: Self.zoneColumn, alignment: .leading)
                Text(String(localized: "Zone min")).frame(maxWidth: .infinity, alignment: .leading)
                Text(String(localized: "Zone max")).frame(maxWidth: .infinity, alignment: .leading)
            }
            .pulseText(.label)
            .foregroundStyle(PulseTheme.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            ForEach((1...5).reversed(), id: \.self) { zone in
                zoneRow(zone)
            }
        }
    }

    private static let zoneColumn: CGFloat = 72

    private func zoneRow(_ zone: Int) -> some View {
        let index = zone - 1
        let manual = profile.hasCustomHRZones
        let mins = shownMins
        let below = index < 4 ? Int(mins[index + 1]).map { String($0 - 1) } ?? "--" : displayedMax
        return HStack(spacing: 10) {
            Text(String(localized: "Zone \(zone)"))
                .profileFont(15, weight: .medium, relativeTo: .subheadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: Self.zoneColumn, alignment: .leading)
            HRValueBox(text: manual ? minBinding(index) : .constant(mins[index]), editable: manual,
                       invalid: manual && zoneInvalid(index),
                       accessibilityLabel: String(localized: "Zone \(zone) minimum"),
                       focus: $focusedField, field: .min(index))
            // Zone 5 runs to the max heart rate; the others end one below the next zone's start.
            HRValueBox(text: manual && zone < 5 ? maxBinding(index) : .constant(below),
                       editable: manual && zone < 5, invalid: false,
                       accessibilityLabel: String(localized: "Zone \(zone) maximum"),
                       focus: $focusedField, field: .max(index))
        }
        .padding(.vertical, 2)
        .background(alignment: .leading) {
            // The zone's colour along the screen's left edge, fading into the row (help-center/98).
            LinearGradient(colors: [PulseTheme.Zone.color(zone).opacity(0.35), Color.clear], startPoint: .leading,
                           endPoint: .trailing)
                .frame(width: 90)
                .overlay(alignment: .leading) {
                    Rectangle().fill(PulseTheme.Zone.color(zone)).frame(width: 3)
                }
                .padding(.leading, -PulseTheme.Layout.pageMargin)
                .padding(.vertical, -2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 6) {
            Button(action: save) {
                Text(String(localized: "Save HR zones"))
            }
            .buttonStyle(.pulseOutline(canSave ? PulseTheme.recoveryBlue : PulseTheme.textDisabled))
            .disabled(!canSave)
            Button {
                focusedField = nil
                dismiss()
            } label: {
                Text(String(localized: "Cancel"))
                    .pulseText(.buttonLabel)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
        .padding(.horizontal, 24)
    }

    // MARK: Draft

    private var tanakaEstimate: Int { Int((208 - 0.7 * Double(profile.age)).rounded()) }
    private var overridden: Bool { Int(draft.maxHR) != tanakaEstimate }
    private var restingText: String { profile.zoneRestingHR.map { String(Int($0.rounded())) } ?? "--" }
    private var displayedMax: String { draft.maxHR.isEmpty ? "--" : draft.maxHR }

    private var maxValue: Int? { Int(draft.maxHR) }
    private var maxInvalid: Bool { maxValue.map { !Self.maxRange.contains($0) } ?? true }

    /// The zone starts the table shows: as typed in manual mode; otherwise the heart-rate-reserve starts,
    /// following a max heart rate being edited so the table previews what SAVE will give.
    private var shownMins: [String] {
        if profile.hasCustomHRZones { return draft.mins }
        guard draft.maxHR != saved.maxHR, let max = maxValue, !maxInvalid else { return draft.mins }
        return HRZones.defaultLowerBounds(maxHR: Double(max), restingHR: profile.resolvedZoneRestingHR).map(String.init)
    }

    /// The five zone starts as typed, when every one parses.
    private var zoneStarts: [Int]? {
        let values = draft.mins.compactMap(Int.init)
        return values.count == 5 ? values : nil
    }

    /// A zone start out of the accepted range or not above the zone below it, or Zone 5 starting at the max.
    private func zoneInvalid(_ index: Int) -> Bool {
        guard let value = Int(draft.mins[index]), HRZones.customBPMRange.contains(value) else { return true }
        if index > 0, let below = Int(draft.mins[index - 1]), value <= below { return true }
        if index == 4, let max = maxValue, value >= max { return true }
        return false
    }

    private var validationProblem: String? {
        if maxInvalid {
            return String(localized: "Max HR must be between \(Self.maxRange.lowerBound) and \(Self.maxRange.upperBound) bpm.")
        }
        if profile.hasCustomHRZones, (0..<5).contains(where: zoneInvalid) {
            return String(localized: "Each zone must start above the one below it and below your max HR.")
        }
        return nil
    }

    private var canSave: Bool { loaded && draft != saved && validationProblem == nil }

    private func load() {
        guard !loaded else { return }
        let current = HRSettingsDraft(maxHR: String(profile.hrMax), mins: Self.mins(profile))
        draft = current
        saved = current
        loaded = true
    }

    /// The zone boxes from the profile as it now stands, keeping a max heart rate being edited.
    private func reloadZones() {
        let mins = Self.mins(profile)
        draft.mins = mins
        saved.mins = mins
    }

    /// The five zone starts: the manual ones, or the heart-rate-reserve zones rounded to the whole bpm
    /// that classifies exactly as the zones do.
    private static func mins(_ profile: ProfileStore) -> [String] {
        let starts = profile.customHRZoneLowerBounds.map { $0.map { Int($0) } }
            ?? HRZones.defaultLowerBounds(maxHR: profile.zoneMaxHR, restingHR: profile.resolvedZoneRestingHR)
        return starts.map(String.init)
    }

    private func save() {
        focusedField = nil
        guard canSave, let max = maxValue else { return }
        if draft.maxHR != saved.maxHR {
            // The age estimate itself means "no override", so the max keeps following the birthday.
            profile.hrMaxOverride = max == tanakaEstimate ? 0 : max
        }
        if profile.hasCustomHRZones, let starts = zoneStarts, draft.mins != saved.mins {
            profile.hrZoneThresholds = starts
        }
        saved = draft
        dismiss()
    }

    // MARK: Bindings

    /// Digits only, at most three.
    private static func digits(_ text: String) -> String { String(text.filter(\.isNumber).prefix(3)) }

    private func digitsBinding(_ key: WritableKeyPath<HRSettingsDraft, String>) -> Binding<String> {
        Binding(get: { draft[keyPath: key] }, set: { draft[keyPath: key] = Self.digits($0) })
    }

    /// A zone's MIN; the zone below ends one bpm under it.
    private func minBinding(_ index: Int) -> Binding<String> {
        Binding(get: { draft.mins[index] }, set: { draft.mins[index] = Self.digits($0) })
    }

    /// A zone's MAX, shown as the next zone's start less one; typing it moves that start.
    private func maxBinding(_ index: Int) -> Binding<String> {
        Binding(get: { Int(draft.mins[index + 1]).map { String($0 - 1) } ?? "" },
                set: { text in
                    let typed = Self.digits(text)
                    draft.mins[index + 1] = Int(typed).map { String($0 + 1) } ?? typed
                })
    }
}

/// What the page edits, held apart from the profile until SAVE HR ZONES.
private struct HRSettingsDraft: Equatable {
    var maxHR = ""
    /// Zone 1 … Zone 5 starts, as typed.
    var mins = Array(repeating: "", count: 5)
}

private enum HRField: Hashable {
    case resting
    case maxHR
    case min(Int)
    case max(Int)
}

private enum HRExplainer: String, Identifiable {
    case resting, max
    var id: String { rawValue }

    var title: String {
        switch self {
        case .resting: return String(localized: "Resting HR")
        case .max: return String(localized: "Max HR")
        }
    }

    func message(estimate: Int) -> String {
        switch self {
        case .resting:
            return String(localized: "Your resting heart rate from your latest scored night. ZENO updates it each morning; your zones are measured up from it.")
        case .max:
            return String(localized: "The highest heart rate you reach. ZENO estimates \(estimate) bpm from your age unless you set your own, for example from a maximal test.")
        }
    }
}

/// A bpm box: the number at the left, "bpm" at the right, in the onboarding field's dark fill. Read-only
/// boxes are dimmed; an invalid one takes the validation border.
private struct HRValueBox: View {
    @Binding var text: String
    let editable: Bool
    let invalid: Bool
    let accessibilityLabel: String
    var focus: FocusState<HRField?>.Binding
    let field: HRField

    var body: some View {
        HStack(spacing: 6) {
            if editable {
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .focused(focus, equals: field)
                    .profileFont(17, weight: .regular, relativeTo: .body)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityValue(text.isEmpty ? String(localized: "Empty") : String(localized: "\(text) bpm"))
            } else {
                Text(text)
                    .profileFont(17, weight: .regular, relativeTo: .body)
                    .foregroundStyle(PulseTheme.textDisabled)
                    .lineLimit(1)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityValue(String(localized: "\(text) bpm"))
            }
            Spacer(minLength: 4)
            Text(verbatim: "bpm")
                .pulseText(.subtitle)
                .foregroundStyle(editable ? PulseTheme.textTertiary : PulseTheme.textDisabled)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 46)
        .background {
            let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .continuous)
            shape.fill(PulseTheme.Onboarding.fieldFill.opacity(editable ? 1 : 0.55))
                .overlay(shape.strokeBorder(invalid ? PulseTheme.Onboarding.validationBorder
                                                    : PulseTheme.Onboarding.fieldBorder, lineWidth: 1))
        }
        .contentShape(Rectangle())
        .onTapGesture { if editable { focus.wrappedValue = field } }
    }
}
#endif
