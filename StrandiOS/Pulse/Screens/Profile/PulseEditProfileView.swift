#if os(iOS)
import SwiftUI
import PhotosUI
import StrandDesign

/// Profile › EDIT (WHOOP_UI_SPEC §3.30 "Edit Profile", profile-community-2026/77).
struct PulseEditProfileRoute: PulseScreenRoute {
    var view: some View { PulseEditProfileView() }
}

/// Edit Profile: "‹ EDIT PROFILE", the photo, then a form of dark boxes under 11 pt caps grey labels:
/// NAME, BIRTHDAY, SEX, HEIGHT, WEIGHT, UNITS, MAX HEART RATE. The pickers open the wheel sheet (§2.6.36:
/// CANCEL / CONFIRM, CONFIRM disabled while invalid). SAVE appears only after an edit and writes
/// `ProfileStore` (the same fields the classic Settings edits, so zones, calories and baselines follow)
/// plus the name, which ZENO now keeps beside them. [Z]: no email or username, country left out.
struct PulseEditProfileView: View {
    @EnvironmentObject private var profile: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PulseProfileIdentity.nameKey) private var storedName = ""
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue

    @State private var draft = ProfileDraft()
    @State private var original = ProfileDraft()
    @State private var loaded = false
    @State private var picker: ProfilePicker?
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var nameFocused: Bool

    private var imperial: Bool { draft.units == UnitSystem.imperial.rawValue }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Edit profile"), spacing: 22) {
            photo
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            field(String(localized: "Name")) {
                TextField("", text: $draft.name, prompt: Text(String(localized: "Your first name")).foregroundStyle(PulseTheme.textDisabled))
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            pickerField(String(localized: "Birthday"), value: birthdayText) { picker = .birthday }
            pickerField(String(localized: "Sex"), value: sexText(draft.sex),
                        help: String(localized: "Your physiological baseline: heart-rate zones, calories and the cycle features follow it.")) {
                picker = .sex
            }
            pickerField(String(localized: "Height"), value: heightText(draft.heightCm)) { picker = .height }
            pickerField(String(localized: "Weight"), value: weightText(draft.weightKg)) { picker = .weight }
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(String(localized: "Units"))
                PulseSegmentedControl(options: [UnitSystem.metric.rawValue, UnitSystem.imperial.rawValue],
                                      selection: $draft.units) { raw in
                    raw == UnitSystem.imperial.rawValue ? String(localized: "Imperial") : String(localized: "Metric")
                }
            }
            pickerField(String(localized: "Max heart rate"), value: maxHRText,
                        help: String(localized: "Leave it on Auto unless you have measured a higher maximum. It sets your heart-rate zones and Strain.")) {
                picker = .maxHR
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if loaded && draft != original {
                Button(action: save) {
                    Text(String(localized: "Save"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule(style: .circular).fill(Color.white))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.bottom, 10)
                .transition(.opacity)
            }
        }
        .onAppear(perform: load)
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
        .sheet(item: $picker) { picker in
            sheet(for: picker)
                .presentationDetents([.height(picker == .birthday ? 420 : 380)])
        }
    }

    // MARK: Photo

    private var photo: some View {
        VStack(spacing: 12) {
            PulseAvatar(imageData: draft.photo, name: draft.name, size: 92)
            HStack(spacing: 18) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(draft.photo == nil ? String(localized: "Add photo") : String(localized: "Change photo"))
                        .pulseText(.buttonLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(minHeight: PulseTheme.Layout.minTapTarget)
                }
                if draft.photo != nil {
                    Button { draft.photo = nil } label: {
                        Text(String(localized: "Remove"))
                            .pulseText(.buttonLabel)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
    }

    // MARK: Fields

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .pulseText(.label)
            .foregroundStyle(PulseTheme.Onboarding.fieldLabel)
            .accessibilityHidden(true)
    }

    /// A labelled dark box (h 48, radius 10, near-black fill, 1 pt dark-grey stroke).
    private func field<Content: View>(_ title: String, help: String? = nil,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)
            content()
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background {
                    let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .continuous)
                    shape.fill(PulseTheme.Onboarding.fieldFill)
                        .overlay(shape.strokeBorder(PulseTheme.Onboarding.fieldBorder, lineWidth: 1))
                }
                .accessibilityLabel(title)
            if let help {
                Text(help)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func pickerField(_ title: String, value: String, help: String? = nil,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            field(title, help: help) {
                HStack {
                    Text(value)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityValue(value)
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheet(for picker: ProfilePicker) -> some View {
        switch picker {
        case .birthday:
            ProfileBirthdaySheet(date: draft.dateOfBirth) { draft.dateOfBirth = $0; self.picker = nil }
                onCancel: { self.picker = nil }
        case .sex:
            ProfileOptionSheet(title: String(localized: "Sex"), options: ["male", "female", "nonbinary"],
                               initial: draft.sex, label: sexText(_:)) { draft.sex = $0; self.picker = nil }
                onCancel: { self.picker = nil }
        case .height:
            ProfileOptionSheet(title: String(localized: "Height"), options: heightOptions,
                               initial: nearest(draft.heightCm, in: heightOptions), label: heightText(_:)) {
                draft.heightCm = $0
                self.picker = nil
            } onCancel: { self.picker = nil }
        case .weight:
            ProfileOptionSheet(title: String(localized: "Weight"), options: weightOptions,
                               initial: nearest(draft.weightKg, in: weightOptions), label: weightText(_:)) {
                draft.weightKg = $0
                self.picker = nil
            } onCancel: { self.picker = nil }
        case .maxHR:
            ProfileOptionSheet(title: String(localized: "Max heart rate"), options: [0] + Array(140...230),
                               initial: draft.maxHR, label: { $0 == 0 ? String(localized: "Auto") : String(localized: "\($0) bpm") }) {
                draft.maxHR = $0
                self.picker = nil
            } onCancel: { self.picker = nil }
        }
    }

    /// Heights in whole centimetres (metric) or whole inches stored as centimetres (imperial).
    private var heightOptions: [Double] {
        imperial ? (48...90).map { Double($0) * 2.54 } : (120...230).map(Double.init)
    }

    /// Weights in half kilograms (metric) or whole pounds stored as kilograms (imperial).
    private var weightOptions: [Double] {
        imperial ? (66...550).map { Double($0) * 0.45359237 } : stride(from: 30.0, through: 250.0, by: 0.5).map { $0 }
    }

    private func nearest(_ value: Double, in options: [Double]) -> Double {
        options.min { abs($0 - value) < abs($1 - value) } ?? value
    }

    // MARK: Text

    private var birthdayText: String {
        draft.dateOfBirth.formatted(.dateTime.month(.wide).day().year().locale(AppLanguage.activeLocale))
    }

    private func sexText(_ raw: String) -> String {
        switch raw {
        case "female": return String(localized: "Female")
        case "nonbinary": return String(localized: "Non-binary")
        default: return String(localized: "Male")
        }
    }

    private func heightText(_ cm: Double) -> String {
        if imperial {
            let inches = Int((cm / 2.54).rounded())
            return "\(inches / 12)′ \(inches % 12)″"
        }
        return String(localized: "\(Int(cm.rounded())) cm")
    }

    private func weightText(_ kg: Double) -> String {
        imperial ? String(localized: "\(Int((kg / 0.45359237).rounded())) lb")
                 : String(localized: "\(String(format: "%.1f", locale: AppLanguage.activeLocale, kg)) kg")
    }

    private var maxHRText: String {
        draft.maxHR == 0 ? String(localized: "Auto (\(Int((208 - 0.7 * Double(ProfileStore.years(from: draft.dateOfBirth, to: Date()))).rounded())) bpm)")
                         : String(localized: "\(draft.maxHR) bpm")
    }

    // MARK: Load and save

    private func load() {
        guard !loaded else { return }
        let current = ProfileDraft(name: storedName, dateOfBirth: profile.dateOfBirth, sex: profile.sex,
                                   heightCm: profile.heightCm, weightKg: profile.weightKg, units: unitSystemRaw,
                                   maxHR: profile.hrMaxOverride, photo: profile.avatarImageData)
        draft = current
        original = current
        loaded = true
    }

    private func save() {
        nameFocused = false
        storedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.dateOfBirth != original.dateOfBirth { profile.dateOfBirth = draft.dateOfBirth }
        if draft.sex != original.sex { profile.sex = draft.sex }
        if draft.heightCm != original.heightCm { profile.heightCm = draft.heightCm }
        if draft.weightKg != original.weightKg { profile.weightKg = draft.weightKg }
        if draft.maxHR != original.maxHR { profile.hrMaxOverride = draft.maxHR }
        if draft.units != original.units { unitSystemRaw = draft.units }
        if draft.photo != original.photo { profile.setAvatar(draft.photo) }
        original = draft
        dismiss()
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Downscaled exactly as the store keeps it, so the preview is what will be saved.
                draft.photo = AvatarImage.downscaledJPEG(from: data, maxDimension: 256) ?? data
            }
            photoItem = nil
        }
    }
}

/// What Edit Profile edits, held apart from the store until SAVE.
private struct ProfileDraft: Equatable {
    var name = ""
    var dateOfBirth = Date()
    var sex = "male"
    var heightCm = 178.0
    var weightKg = 75.0
    var units = UnitSystem.metric.rawValue
    var maxHR = 0
    var photo: Data?
}

private enum ProfilePicker: String, Identifiable {
    case birthday, sex, height, weight, maxHR
    var id: String { rawValue }
}

/// A one-column wheel in the shared sheet, holding its own selection until CONFIRM.
private struct ProfileOptionSheet<Value: Hashable>: View {
    let title: String
    let options: [Value]
    let label: (Value) -> String
    let onConfirm: (Value) -> Void
    let onCancel: () -> Void
    @State private var selection: Value

    init(title: String, options: [Value], initial: Value, label: @escaping (Value) -> String,
         onConfirm: @escaping (Value) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.options = options
        self.label = label
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _selection = State(initialValue: initial)
    }

    var body: some View {
        PulseWheelPickerSheet(title: title, options: options, selection: $selection, label: label,
                              onConfirm: { onConfirm(selection) }, onCancel: onCancel)
    }
}

/// "Set Your Birthday": a date wheel in the shared sheet's look; CONFIRM is disabled outside the ages the
/// profile accepts (13 to 100, `ProfileStore.dateOfBirthRange`).
private struct ProfileBirthdaySheet: View {
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void
    @State private var date: Date

    init(date: Date, onConfirm: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _date = State(initialValue: date)
    }

    private var valid: Bool { ProfileStore.dateOfBirthRange.contains(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Set your birthday"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(String(localized: "Cancel"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 1.5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                Button { onConfirm(date) } label: {
                    Text(String(localized: "Confirm"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(valid ? Color.black : PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(valid ? Color.white : PulseTheme.buttonInvalid))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .disabled(!valid)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.wheelSheet.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .environment(\.colorScheme, .dark)
    }
}
#endif
