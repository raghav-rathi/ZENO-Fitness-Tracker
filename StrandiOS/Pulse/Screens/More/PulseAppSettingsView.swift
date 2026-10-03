#if os(iOS)
import SwiftUI

/// App Settings (WHOOP_UI_SPEC §3.33), presented as a sheet with "✕": nine single-line row cards with no
/// sections, in the spec's order (health-more-2026/08b; the labels there are illegible, so the mapping is
/// the spec's). Every page binds the settings keys the classic Settings screen already writes, so a
/// change here is the same change there; nothing is stored twice.
///
///   ACTIVITY SETTINGS   activity detection, keep screen on, heart-rate settings
///   AI SETTINGS         the Coach switch, its provider and model, data sharing (a sheet, "✕")
///   DATA EXPORT         backup, CSV archive, PDF report, folder sync, Shortcuts (a sheet, "✕")
///   UNITS               body, distance, temperature, skin temperature, clock
///   INTEGRATIONS        Apple Health and the data sources
///   JOURNAL             the Home journal card
///   NOTIFICATIONS       strap alerts, the morning brief, Lock Screen activities, automations
///   HORMONAL INSIGHTS   cycle insights (profiles they apply to)
///   HIDE METRICS        the switches that hide a feature's cards
struct PulseAppSettingsView: View {
    /// Rebuilt: existing entry points open this screen rather than the classic Settings.
    static let isRebuilt = true

    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var profile: ProfileStore
    @State private var modal: AppSettingsModal?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "App settings"), spacing: PulseTheme.Row.listGap) {
            MoreButtonRow(symbol: "figure.run", title: String(localized: "Activity settings")) {
                navigator.open(PulseActivitySettingsRoute().route)
            }
            MoreButtonRow(symbol: "sparkles", title: String(localized: "AI settings")) { modal = .ai }
            MoreButtonRow(symbol: "square.and.arrow.up", title: String(localized: "Data export")) { modal = .export }
            MoreButtonRow(symbol: "ruler", title: String(localized: "Units")) {
                navigator.open(PulseUnitsRoute().route)
            }
            MoreButtonRow(symbol: "link", title: String(localized: "Integrations")) {
                navigator.open(PulseIntegrationsRoute().route)
            }
            MoreButtonRow(symbol: "book.closed", title: String(localized: "Journal")) {
                navigator.open(PulseJournalSettingsRoute().route)
            }
            MoreButtonRow(symbol: "bell", title: String(localized: "Notifications")) {
                navigator.open(PulseNotificationsRoute().route)
            }
            if profile.cycleAwarenessApplies {
                MoreButtonRow(symbol: "circle.dotted.circle", title: String(localized: "Hormonal insights")) {
                    navigator.open(PulseHormonalInsightsRoute().route)
                }
            }
            MoreButtonRow(symbol: "eye.slash", title: String(localized: "Hide metrics")) {
                navigator.open(PulseHideMetricsRoute().route)
            }
        }
        // AI Settings and Export are modals of their own in WHOOP ("✕", §1.5, §1.6), over this sheet.
        .sheet(item: $modal) { modal in
            PulseModalHost(route: modal.route)
        }
        .onAppear(perform: openDebugPage)
    }

    /// DEBUG `--more-open <page>`: push (or present) one of the pages at launch for captures.
    private func openDebugPage() {
        #if DEBUG
        guard let name = PulseMoreDebug.take(prefixes: ["activity-settings", "ai-settings", "data-export", "units",
                                                        "integrations", "journal-settings", "notifications",
                                                        "hormonal-insights", "hide-metrics", "apple-health"])
        else { return }
        switch name {
        case "ai-settings": modal = .ai
        case "data-export": modal = .export
        case "activity-settings": navigator.open(PulseActivitySettingsRoute().route)
        case "units": navigator.open(PulseUnitsRoute().route)
        case "integrations": navigator.open(PulseIntegrationsRoute().route)
        case "apple-health":
            navigator.open(PulseIntegrationsRoute().route)
            navigator.open(PulseAppleHealthRoute().route)
        case "journal-settings": navigator.open(PulseJournalSettingsRoute().route)
        case "notifications": navigator.open(PulseNotificationsRoute().route)
        case "hormonal-insights": navigator.open(PulseHormonalInsightsRoute().route)
        case "hide-metrics": navigator.open(PulseHideMetricsRoute().route)
        default: break
        }
        #endif
    }
}

/// The two App Settings pages WHOOP presents as modals of their own.
private enum AppSettingsModal: String, Identifiable {
    case ai, export
    var id: String { rawValue }

    var route: PulseRoute {
        switch self {
        case .ai: return PulseAISettingsRoute().route
        case .export: return PulseDataExportRoute().route
        }
    }
}

// MARK: - Routes

/// App Settings › ACTIVITY SETTINGS.
struct PulseActivitySettingsRoute: PulseScreenRoute {
    var view: some View { PulseActivitySettingsView() }
}

/// App Settings › AI SETTINGS ("✕", profile-community-2026/55).
struct PulseAISettingsRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .sheet }
    var view: some View { PulseAISettingsView() }
}

/// App Settings › DATA EXPORT ("✕", health-more-2026/25).
struct PulseDataExportRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .sheet }
    var view: some View { PulseDataExportView() }
}

/// App Settings › UNITS.
struct PulseUnitsRoute: PulseScreenRoute {
    var view: some View { PulseUnitsView() }
}

/// App Settings › INTEGRATIONS.
struct PulseIntegrationsRoute: PulseScreenRoute {
    var view: some View { PulseIntegrationsView() }
}

/// INTEGRATIONS › APPLE HEALTH.
struct PulseAppleHealthRoute: PulseScreenRoute {
    var view: some View { PulseAppleHealthIntegrationView() }
}

/// App Settings › JOURNAL.
struct PulseJournalSettingsRoute: PulseScreenRoute {
    var view: some View { PulseJournalSettingsView() }
}

/// App Settings › NOTIFICATIONS.
struct PulseNotificationsRoute: PulseScreenRoute {
    var view: some View { PulseNotificationsView() }
}

/// App Settings › HORMONAL INSIGHTS.
struct PulseHormonalInsightsRoute: PulseScreenRoute {
    var view: some View { PulseHormonalInsightsView() }
}

/// App Settings › HIDE METRICS.
struct PulseHideMetricsRoute: PulseScreenRoute {
    var view: some View { PulseHideMetricsView() }
}
#endif
