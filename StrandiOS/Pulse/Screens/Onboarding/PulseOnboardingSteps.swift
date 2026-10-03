#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import UniformTypeIdentifiers
import UserNotifications

// MARK: - The account and profile steps (WHOOP_UI_SPEC §3.38 ZENO steps 1, 2, 4–7)
//
// Each step is the classic `OnboardingWizard` / `TermsGateView` step it replaces, on the WHOOP template:
// the same stores, the same keys and the same requirements (every attestation ticked one by one, the
// notification prompt only when undetermined, the import paths, the profile bindings), in ZENO's copy.

// MARK: Landing

/// The landing page: no photo (§0), the ZENO wordmark, "PAIR MY STRAP" and the honest second way in.
/// WHOOP's "EXPLORE WITH DEMO DATA" is not offered: a Release build has no demo data to explore, so
/// the second pill continues without a strap instead, as the classic onboarding always allowed.
struct PulseOnboardingLanding: View {
    let onPair: () -> Void
    let onWithoutStrap: () -> Void
    /// A replay opened from inside the app closes from here; the first run has no way out but forward.
    var onClose: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            PulseOnboardingBackground()
            RadialGradient(colors: [Color.white.opacity(0.07), Color.clear], center: .top, startRadius: 0,
                           endRadius: 440)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                PulseZenoWordmark(width: 168, height: 28)
                    .padding(.bottom, 18)
                Text(String(localized: "Your strap. Your data. On this iPhone."))
                    .pulseOnboardingText(.subtitle)
                    .foregroundStyle(PulseTheme.Onboarding.subtitle)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 40).frame(maxHeight: 96)
                VStack(spacing: 12) {
                    Button(String(localized: "Pair my strap"), action: onPair)
                        .buttonStyle(PulseOnboardingPillStyle(kind: .white))
                    Button(String(localized: "Continue without a strap"), action: onWithoutStrap)
                        .buttonStyle(PulseOnboardingPillStyle(kind: .dark))
                }
                Text(String(localized: "ZENO is independent and not affiliated with WHOOP."))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin + 4)
            .padding(.bottom, 12)
            if let onClose {
                HStack {
                    PulseCloseButton(action: onClose)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.top, PulseTheme.Header.navBarTop)
            }
        }
    }
}

// MARK: Legal

/// The points the first-run gate has always presented (`Terms.points`, the summary of TERMS.md), before
/// the checkbox screen asks the wearer to confirm the attestations.
struct PulseOnboardingTermsStep: View {
    let progress: Double
    let showsBack: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Before You Use ZENO"),
            subtitle: String(localized: "ZENO is built on NOOP, an independent open-source project, and these points come from its terms. The next screen asks you to confirm them."),
            showsBack: showsBack,
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "list.bullet.clipboard.fill", accent: "info.circle.fill") },
            content: {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Terms.points, id: \.0) { point in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.0)
                                .pulseText(.coachingTitle)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(point.1)
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Text(String(localized: "The full terms are in TERMS.md, shipped with ZENO. This is not legal advice."))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
    }
}

/// "Privacy and Terms of Use": one un-ticked box per attestation (`Terms.attestations`). NEXT stays grey
/// until every box is ticked, one by one: they are separate, conspicuous consents by design
/// (`Terms.attestations`), so WHOOP's "SELECT AND AGREE TO ALL" row is deliberately not offered.
struct PulseOnboardingPrivacyStep: View {
    let progress: Double
    let onBack: () -> Void
    let onAccept: () -> Void

    @State private var checks: [Bool]

    init(progress: Double, onBack: @escaping () -> Void, onAccept: @escaping () -> Void) {
        self.progress = progress
        self.onBack = onBack
        self.onAccept = onAccept
        var initial = Array(repeating: false, count: Terms.attestations.count)
        #if DEBUG
        // `--pulse-onboarding-ticked`: the enabled state, for a capture.
        if CommandLine.arguments.contains("--pulse-onboarding-ticked") {
            initial = Array(repeating: true, count: Terms.attestations.count)
        }
        #endif
        _checks = State(initialValue: initial)
    }

    private var allChecked: Bool { checks.allSatisfy { $0 } }

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Privacy and Terms of Use"),
            subtitle: String(localized: "Confirm each statement to use ZENO. Your data stays on this iPhone unless you export it."),
            onBack: onBack,
            illustration: { PulsePadlockIllustration() },
            content: {
                // 14 pt between the long legal statements, so the four of them and the padlock fit a 6.3"
                // phone above the CTA (WHOOP's four are one or two lines each).
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(Terms.attestations.enumerated()), id: \.offset) { index, line in
                        attestationRow(index: index, text: line)
                    }
                }
            },
            cta: {
                PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, enabled: allChecked,
                                          action: onAccept)
            })
    }

    private func attestationRow(index: Int, text: String) -> some View {
        let checked = checks.indices.contains(index) && checks[index]
        return Button {
            guard checks.indices.contains(index) else { return }
            checks[index].toggle()
        } label: {
            HStack(alignment: .top, spacing: PulseOnboardingMetrics.checkboxGap) {
                PulseOnboardingCheckbox(checked: checked)
                Text(text)
                    .pulseOnboardingText(.checkLine)
                    .foregroundStyle(checked ? PulseTheme.textPrimary : PulseOnboardingColors.uncheckedText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // The boxes sit 19 pt inside the margin (x 35–65 on the captures), their text from x 83.
            .padding(.leading, 19)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityValue(checked ? String(localized: "Confirmed") : String(localized: "Not confirmed"))
        .accessibilityAddTraits(checked ? [.isButton, .isSelected] : [.isButton])
    }
}

/// The padlock with a blue keyhole (the Privacy step's illustration, drawn from SF Symbols): 88 pt tall,
/// as 22d's padlock, sitting on the bottom of the illustration slot.
struct PulsePadlockIllustration: View {
    private static let height: CGFloat = 88

    var body: some View {
        Image(systemName: "lock.fill")
            .resizable()
            .scaledToFit()
            .frame(height: Self.height)
            .foregroundStyle(LinearGradient(colors: [PulseOnboardingColors.illustrationTop,
                                                     PulseOnboardingColors.illustrationBottom],
                                            startPoint: .top, endPoint: .bottom))
            // The keyhole, centred in the lock's body (its lower ≈60%).
            .overlay {
                Capsule(style: .continuous)
                    .fill(PulseOnboardingColors.accentBlue)
                    .frame(width: Self.height * 0.075, height: Self.height * 0.23)
                    .offset(y: Self.height * 0.2)
            }
            .frame(height: PulseOnboardingMetrics.illustrationHeight, alignment: .bottomLeading)
            .accessibilityHidden(true)
    }
}

// MARK: Profile

/// Where onboarding keeps the wearer's first name: one UserDefaults key, read by whatever greets them by
/// name (the avatar's initials, the Daily Outlook's title). ZENO's `ProfileStore` has no name field.
enum PulseOnboardingProfile {
    static let firstNameKey = "profile.firstName"

    static var firstName: String? {
        let stored = UserDefaults.standard.string(forKey: firstNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (stored?.isEmpty ?? true) ? nil : stored
    }

    static func setFirstName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: firstNameKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: firstNameKey)
        }
    }
}

/// "Welcome to ZENO!" / "Tell us your name so we get it right." (first name only, optional).
struct PulseOnboardingNameStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var name = PulseOnboardingProfile.firstName ?? ""
    @FocusState private var focused: Bool

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Welcome to ZENO!"),
            subtitle: String(localized: "Tell us your name so we get it right."),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "hands.clap.fill", accent: "sparkles",
                                                        accentAlignment: .topTrailing) },
            content: {
                VStack(alignment: .leading, spacing: PulseOnboardingMetrics.labelToField) {
                    PulseOnboardingFieldLabel(String(localized: "First name"))
                    PulseOnboardingFieldBox {
                        TextField("", text: $name,
                                  prompt: Text(String(localized: "First name"))
                                    .foregroundStyle(PulseOnboardingColors.placeholder))
                            .pulseOnboardingText(.fieldValue)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .submitLabel(.next)
                            .focused($focused)
                            .onSubmit(save)
                            .accessibilityLabel(String(localized: "First name"))
                    }
                    Text(String(localized: "Optional. It stays on this iPhone and only labels your profile."))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.leading, 4)
                        .padding(.top, 2)
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: save) })
    }

    private func save() {
        focused = false
        PulseOnboardingProfile.setFirstName(name)
        onNext()
    }
}

/// "Where Do You Live?": a searchable country list that only sets the default units (nothing about the
/// country is stored). The selected row turns white (onboarding/16a). Optional: SKIP keeps the units.
struct PulseOnboardingLocationStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""
    @State private var query = ""
    @State private var selected: String? = Locale.current.region?.identifier

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Where Do You Live?"),
            subtitle: String(localized: "ZENO uses this to pick your units. The country itself isn't stored."),
            trailing: .text(String(localized: "Skip"), onNext),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "globe.europe.africa.fill", accent: "location.fill",
                                                        accentAlignment: .topTrailing) },
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    PulseOnboardingFieldBox {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(PulseOnboardingColors.placeholder)
                                .accessibilityHidden(true)
                            TextField("", text: $query,
                                      prompt: Text(String(localized: "Search countries"))
                                        .foregroundStyle(PulseOnboardingColors.placeholder))
                                .pulseOnboardingText(.fieldValue)
                                .foregroundStyle(PulseTheme.textPrimary)
                                .autocorrectionDisabled(true)
                                .accessibilityLabel(String(localized: "Search countries"))
                        }
                    }
                    .padding(.bottom, 6)
                    LazyVStack(spacing: 10) {
                        ForEach(matches, id: \.code) { country in
                            PulseOnboardingOptionRow(title: country.name, selected: selected == country.code,
                                                     action: { selected = country.code },
                                                     leading: {
                                                         Text(Self.flag(country.code))
                                                             .font(.system(size: 20))
                                                             .accessibilityHidden(true)
                                                     })
                        }
                    }
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: apply) })
    }

    private struct Country {
        let code: String
        let name: String
    }

    /// Every ISO country, by its name in the device's language.
    private static let countries: [Country] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
        .compactMap { code in Locale.current.localizedString(forRegionCode: code).map { Country(code: code, name: $0) } }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    private var matches: [Country] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            // The device's own country first, so the likely answer needs no scrolling.
            guard let selected, let own = Self.countries.first(where: { $0.code == selected }) else { return Self.countries }
            return [own] + Self.countries.filter { $0.code != selected }
        }
        return Self.countries.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// The regional-indicator flag for an ISO code (Unicode, not artwork).
    private static func flag(_ code: String) -> String {
        code.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map(String.init)
            .joined()
    }

    /// Units from the country's measurement system: US and UK conventions → imperial body measurements
    /// and miles; everywhere else metric. The next step shows both choices to change.
    private func apply() {
        if let selected {
            let units = Self.units(forRegion: selected)
            unitSystemRaw = units.rawValue
            distanceSystemRaw = units.rawValue
        }
        onNext()
    }

    static func units(forRegion code: String) -> UnitSystem {
        let locale = Locale(components: Locale.Components(languageCode: "en", languageRegion: Locale.Region(code)))
        switch locale.measurementSystem {
        case .us, .uk: return .imperial
        default: return .metric
        }
    }
}

/// "Connect To Apple Health": SKIP, or CONNECT, which asks iOS exactly as Settings' Apple Health screen
/// does and then runs the same first sync. A build signed without the HealthKit entitlement (free Apple
/// IDs) is told so plainly, as Apple Health's own screen does (#348).
struct PulseOnboardingHealthStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var health: HealthKitBridge
    @State private var asked = false
    @State private var asking = false

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Connect To Apple Health"),
            subtitle: String(localized: "Bring in steps, workouts and vitals from Apple Health, and let ZENO write your strap's sleep and heart rate back. It all stays on this iPhone."),
            trailing: .text(String(localized: "Skip"), onNext),
            onBack: onBack,
            illustration: { PulseHealthLinkIllustration() },
            content: {
                if asked, let note = outcome {
                    Text(note)
                        .pulseOnboardingText(.checkLine)
                        .foregroundStyle(PulseTheme.Onboarding.validationText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            },
            cta: {
                PulseOnboardingRingButton(title: asked ? String(localized: "Next") : String(localized: "Connect"),
                                          progress: progress, enabled: !asking, action: connect)
            })
    }

    /// What the request left behind when it did not connect.
    private var outcome: String? {
        switch health.auth {
        case .authorized, .unknown: return nil
        case .entitlementMissing:
            return String(localized: "This install can't connect to Apple Health directly: it was signed without Apple's Health permission, so there's nothing to enable. You can import a Health export later in Data Sources.")
        case .unavailable:
            return String(localized: "Apple Health isn't available on this device.")
        case .denied:
            return String(localized: "If you didn't see the prompt, turn ZENO on under Settings › Health › Data Access & Devices.")
        }
    }

    private func connect() {
        if asked {
            onNext()
            return
        }
        asking = true
        Task {
            await health.requestAuthorization()
            asking = false
            asked = true
            guard health.auth == .authorized else { return }
            // The first sync runs on its own (Settings' Apple Health screen runs the same pair), so the
            // wearer is not held on this step while it reads.
            Task {
                await HealthSyncRefreshCoordinator.run(
                    sync: { await health.sync() },
                    refresh: { await model.refreshAfterAppleHealthSync(authorized: health.auth == .authorized) })
            }
            onNext()
        }
    }
}

/// Apple Health → ZENO: a white tile with a heart, a blue arrow, ZENO's tile.
struct PulseHealthLinkIllustration: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .frame(width: 58, height: 58)
                .overlay(Image(systemName: "heart.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(PulseOnboardingColors.healthHeart))
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PulseOnboardingColors.accentBlue)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [PulseOnboardingColors.illustrationTop,
                                              PulseOnboardingColors.illustrationBottom],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 58, height: 58)
                .overlay(PulseZenoMonogramShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 24, height: 24))
        }
        .frame(height: PulseOnboardingMetrics.illustrationHeight, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }
}

/// "What's Your Birthday?": an inline wheel bound to the profile's date of birth (#146), the range the
/// classic onboarding allowed.
struct PulseOnboardingBirthdayStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var profile: ProfileStore

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "What's Your Birthday?"),
            subtitle: String(localized: "Your age sets your maximum heart rate and the zones built on it."),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "birthday.cake.fill", accent: "sparkle",
                                                        accentAlignment: .topTrailing) },
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker(String(localized: "Date of birth"), selection: $profile.dateOfBirth,
                               in: ProfileStore.dateOfBirthRange, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                    Text(String(localized: "Age \(profile.age) · estimated max heart rate \(profile.hrMax) bpm"))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.leading, 4)
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
    }
}

/// "Choose a Gender": the profile's physiological baseline ("male" | "female" | "nonbinary", the three
/// values the classic onboarding and Settings write). Stacked buttons, the chosen one white.
struct PulseOnboardingGenderStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var profile: ProfileStore
    /// Nothing is pre-chosen on a first run: the stored default is not an answer.
    @State private var choice: String?

    init(progress: Double, preselect: Bool, onBack: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.progress = progress
        self.onBack = onBack
        self.onNext = onNext
        _choice = State(initialValue: preselect ? UserDefaults.standard.string(forKey: "profile.sex") : nil)
    }

    private let options: [(key: String, label: String)] = [
        ("female", String(localized: "Female")),
        ("male", String(localized: "Male")),
        ("nonbinary", String(localized: "Non-binary")),
    ]

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Choose a Gender"),
            subtitle: String(localized: "ZENO uses this as the physiological baseline for its calorie and hydration estimates."),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "person.text.rectangle.fill", accent: "checkmark.circle.fill") },
            content: {
                VStack(spacing: 10) {
                    ForEach(options, id: \.key) { option in
                        PulseOnboardingOptionRow(title: option.label, selected: choice == option.key, centred: true) {
                            choice = option.key
                        }
                    }
                }
            },
            cta: {
                PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, enabled: choice != nil) {
                    if let choice { profile.sex = choice }
                    onNext()
                }
            })
    }
}

/// "Height and Weight", with the two unit choices the classic onboarding kept explicit (body
/// measurements and exercise distance are separate: Canadian pounds with kilometres is common). ZENO
/// needs these when Apple Health has none. Values open a wheel sheet in the chosen unit.
struct PulseOnboardingBodyStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var profile: ProfileStore
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""
    @State private var editing: PulseBodyField?

    private var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
    private var distanceSystem: UnitSystem { UnitPrefs.resolveDistance(system: unitSystem, override: distanceSystemRaw) }

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Height and Weight"),
            subtitle: String(localized: "ZENO needs these for calories and Strain when Apple Health has none."),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "figure.stand", accent: "ruler.fill") },
            content: {
                VStack(alignment: .leading, spacing: 0) {
                    PulseOnboardingFieldLabel(String(localized: "Body measurements"))
                        .padding(.bottom, PulseOnboardingMetrics.labelToField)
                    PulseSegmentedControl(options: UnitSystem.allCases,
                                          selection: Binding(get: { unitSystem }, set: { unitSystemRaw = $0.rawValue })) {
                        $0 == .metric ? String(localized: "Metric") : String(localized: "Imperial")
                    }
                    PulseOnboardingFieldLabel(String(localized: "Exercise distance & pace"))
                        .padding(.top, 22)
                        .padding(.bottom, PulseOnboardingMetrics.labelToField)
                    PulseSegmentedControl(options: UnitSystem.allCases,
                                          selection: Binding(get: { distanceSystem }, set: { distanceSystemRaw = $0.rawValue })) {
                        $0 == .metric ? String(localized: "Kilometres") : String(localized: "Miles")
                    }
                    HStack(alignment: .top, spacing: 12) {
                        valueField(String(localized: "Height"),
                                   UnitFormatter.heightFromCentimeters(profile.heightCm, system: unitSystem), .height)
                        valueField(String(localized: "Weight"),
                                   UnitFormatter.massFromKilograms(profile.weightKg, system: unitSystem), .weight)
                    }
                    .padding(.top, 22)
                    Text(String(localized: "Estimated max heart rate · \(profile.hrMax) bpm"))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.leading, 4)
                        .padding(.top, 14)
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
            .sheet(item: $editing) { field in
                PulseBodyValueSheet(field: field, system: unitSystem, onClose: { editing = nil })
                    .presentationDetents([.height(380)])
            }
    }

    private func valueField(_ label: String, _ value: String, _ field: PulseBodyField) -> some View {
        VStack(alignment: .leading, spacing: PulseOnboardingMetrics.labelToField) {
            PulseOnboardingFieldLabel(label)
            Button { editing = field } label: {
                PulseOnboardingFieldBox {
                    Text(value)
                        .pulseOnboardingText(.fieldValue)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(String(localized: "Opens a picker"))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Which body value the wheel sheet edits.
enum PulseBodyField: String, Identifiable {
    case height, weight
    var id: String { rawValue }
}

/// The wheel sheet for height or weight, in the chosen unit, written back in SI (the profile is always
/// SI). The ranges are the classic steppers': height 120–230 cm, weight 30–250 kg.
private struct PulseBodyValueSheet: View {
    let field: PulseBodyField
    let system: UnitSystem
    let onClose: () -> Void

    @EnvironmentObject private var profile: ProfileStore
    @State private var draft: Double = 0

    var body: some View {
        PulseWheelPickerSheet(title: field == .height ? String(localized: "Height") : String(localized: "Weight"),
                              options: options, selection: $draft, label: label,
                              onConfirm: confirm, onCancel: onClose)
            .onAppear { draft = nearest(to: current) }
    }

    /// The choices in display units: cm or whole inches; kg in halves or whole pounds.
    private var options: [Double] {
        switch (field, system) {
        case (.height, .metric): return stride(from: 120.0, through: 230.0, by: 1).map { $0 }
        case (.height, .imperial): return stride(from: 48.0, through: 90.0, by: 1).map { $0 }
        case (.weight, .metric): return stride(from: 30.0, through: 250.0, by: 0.5).map { $0 }
        case (.weight, .imperial):
            return stride(from: (30 * UnitFormatter.poundsPerKilogram).rounded(.up),
                          through: (250 * UnitFormatter.poundsPerKilogram).rounded(.down), by: 1).map { $0 }
        }
    }

    /// The stored value in display units.
    private var current: Double {
        switch (field, system) {
        case (.height, .metric): return profile.heightCm
        case (.height, .imperial): return UnitFormatter.cmToInches(profile.heightCm)
        case (.weight, .metric): return profile.weightKg
        case (.weight, .imperial): return UnitFormatter.kgToPounds(profile.weightKg)
        }
    }

    private func nearest(to value: Double) -> Double {
        options.min { abs($0 - value) < abs($1 - value) } ?? value
    }

    private func label(_ value: Double) -> String {
        switch (field, system) {
        case (.height, .metric): return "\(Int(value)) cm"
        case (.height, .imperial): return "\(Int(value) / 12)′ \(Int(value) % 12)″"
        case (.weight, .metric): return LiftFormat.trim(value) + " kg"
        case (.weight, .imperial): return "\(Int(value)) lb"
        }
    }

    private func confirm() {
        switch (field, system) {
        case (.height, .metric): profile.heightCm = draft
        case (.height, .imperial): profile.heightCm = draft * UnitFormatter.centimetersPerInch
        case (.weight, .metric): profile.weightKg = draft
        case (.weight, .imperial): profile.weightKg = draft / UnitFormatter.poundsPerKilogram
        }
        onClose()
    }
}

// MARK: History, notifications, the end

/// "Bring Your History" (the classic Import step): a WHOOP export or an Apple Health export, through the
/// same importers Data Sources uses, with their own summary lines. Optional.
struct PulseOnboardingHistoryStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var model: AppModel
    @State private var importing = false
    @State private var target: DataSourceImportKind = .whoop

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Bring Your History"),
            subtitle: String(localized: "Import a WHOOP export or an Apple Health export now, and your dashboard fills straight away. Or skip, and do it later in Data Sources."),
            trailing: .text(String(localized: "Skip"), onNext),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "tray.and.arrow.down.fill", accent: "clock.arrow.circlepath",
                                                        accentAlignment: .topTrailing) },
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    importRow(.whoop, title: model.isImporting(.whoop) ? String(localized: "Importing…")
                                                                     : String(localized: "Import WHOOP export"),
                              symbol: "tray.and.arrow.down")
                    importRow(.appleHealth, title: model.isImporting(.appleHealth) ? String(localized: "Working…")
                                                                                 : String(localized: "Import Apple Health export"),
                              symbol: "heart")
                    if let summary {
                        Text(summary)
                            .pulseOnboardingText(.checkLine)
                            .foregroundStyle(model.importFailed(target) ? PulseTheme.Onboarding.validationText
                                                                         : PulseTheme.positive)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                }
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext) })
            .fileImporter(isPresented: $importing, allowedContentTypes: allowedTypes, allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                switch target {
                case .appleHealth: model.importAppleHealth(url: url)
                default: model.importWhoop(url: url)
                }
            }
    }

    private var allowedTypes: [UTType] {
        target == .appleHealth ? [.zip, .xml] : [.zip]
    }

    private var summary: String? {
        target == .appleHealth ? model.appleHealthImportSummary : model.whoopImportSummary
    }

    private func importRow(_ kind: DataSourceImportKind, title: String, symbol: String) -> some View {
        Button {
            target = kind
            importing = true
        } label: {
            PulseListRow(symbol: symbol, title: title)
        }
        .buttonStyle(PulsePressStyle())
        .disabled(model.hasActiveImport)
        .opacity(model.hasActiveImport && !model.isImporting(kind) ? 0.5 : 1)
    }
}

/// "Turn On Notifications": the pre-permission screen. NEXT asks iOS only while the answer is still
/// undetermined, then moves on whatever the answer (the classic onboarding's rule, mirroring Android).
struct PulseOnboardingNotificationsStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "Turn On Notifications"),
            subtitle: String(localized: "ZENO can remind you to wind down, warn you when your strap's battery runs low and flag an unusual night. You choose which ones in Settings, and they all come from this iPhone."),
            onBack: onBack,
            illustration: { PulseOnboardingIllustration(symbol: "bell.fill", accent: "circle.fill", accentAlignment: .topTrailing) },
            content: {
                PulseOnboardingCheckLine(text: String(localized: "Strain nudges and your smart alarm can also tap your wrist through the strap."))
            },
            cta: { PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: request) })
    }

    private func request() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                Task { @MainActor in onNext() }
                return
            }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in
                Task { @MainActor in onNext() }
            }
        }
    }
}

/// "Welcome to ZENO": the splash before the last step.
struct PulseOnboardingWelcomeStep: View {
    let progress: Double
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        ZStack {
            PulseOnboardingBackground()
            RadialGradient(colors: [Color.white.opacity(0.06), Color.clear], center: .center, startRadius: 0,
                           endRadius: 300)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(spacing: 22) {
                Text(String(localized: "Welcome to"))
                    .pulseOnboardingText(.subtitle)
                    .foregroundStyle(PulseTheme.Onboarding.subtitle)
                PulseZenoWordmark(width: 210, height: 35)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Welcome to ZENO"))
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            PulseOnboardingTopBar(leading: .back, onLeading: onBack)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PulseOnboardingRingButton(title: String(localized: "Next"), progress: progress, action: onNext)
        }
    }
}

/// "What to Expect Next": the calibration wheel with ZENO's real thresholds, read from the analytics
/// constants the scores wait for, then the green ✓ that finishes onboarding.
struct PulseOnboardingExpectationsStep: View {
    let onBack: () -> Void
    let onDone: () -> Void

    /// The nights each score really waits for: Sleep after the first scored night, Recovery once its
    /// baselines seed (`Baselines.minNightsSeed`), Sleep Consistency once enough earlier nights exist
    /// (`SleepConsistency.minPriorNights` + the night scored), personal Health Monitor ranges once the
    /// baselines are trusted (`Baselines.minNightsTrust`).
    static var milestones: [PulseOnboardingMilestone] {
        [
            PulseOnboardingMilestone(night: 1, symbol: "moon.fill", title: String(localized: "Sleep")),
            PulseOnboardingMilestone(night: Baselines.minNightsSeed, symbol: "heart.fill",
                                     title: String(localized: "Recovery")),
            PulseOnboardingMilestone(night: SleepConsistency.minPriorNights + 1, symbol: "bed.double.fill",
                                     title: String(localized: "Sleep Consistency")),
            PulseOnboardingMilestone(night: Baselines.minNightsTrust, symbol: "waveform.path.ecg",
                                     title: String(localized: "Personal Health Monitor ranges")),
        ]
    }

    var body: some View {
        PulseOnboardingStepPage(
            title: String(localized: "What to Expect Next"),
            subtitle: String(localized: "Wear your strap day and night. ZENO learns your baseline from the nights you wear it, and new scores unlock as it does."),
            art: .large(height: PulseCalibrationWheel.size),
            onBack: onBack,
            illustration: {
                PulseCalibrationWheel(milestones: Self.wheelMilestones, nights: Baselines.minNightsTrust,
                                      highlightThrough: Baselines.minNightsSeed)
            },
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Self.milestones) { milestone in
                        HStack(spacing: 10) {
                            Text(String(localized: "Night \(milestone.night)"))
                                .pulseText(.label)
                                .foregroundStyle(PulseTheme.textTertiary)
                                .frame(width: 74, alignment: .leading)
                            Text(milestone.title)
                                .pulseOnboardingText(.checkLine)
                                .foregroundStyle(PulseTheme.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Text(String(localized: "ZENO is installed outside the App Store: re-sign it about every 7 days on a free Apple ID, and unlock your iPhone once after it restarts so ZENO can sync."))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
            },
            cta: { PulseOnboardingFilledButton(title: String(localized: "Done"), kind: .finish, action: onDone) })
    }

    /// The wheel's dots: one per distinct night (Recovery and Sleep Consistency share night 4).
    private static var wheelMilestones: [PulseOnboardingMilestone] {
        var seen = Set<Int>()
        return milestones.filter { seen.insert($0.night).inserted }
    }
}
#endif
