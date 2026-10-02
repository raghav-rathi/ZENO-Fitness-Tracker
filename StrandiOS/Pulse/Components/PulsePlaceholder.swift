#if os(iOS)
import SwiftUI

// MARK: - Placeholder screen

/// The themed screen a route shows until its group rebuilds it: the spec's title in the navigation bar,
/// back (or "✕" at a modal root), a short "being rebuilt" card naming the spec section and owning group,
/// and a link to each classic screen that does the job today, so the app never dead-ends.
///
///     PulsePlaceholderScreen(name: String(localized: "Sleep Planner"), symbol: "bed.double",
///                            summary: "…", spec: "§3.11", group: "sleep",
///                            links: [.init(title: String(localized: "Alarms"), symbol: "alarm", route: .classic(.alarms))])
struct PulsePlaceholderScreen: View {
    struct Link: Identifiable {
        let title: String
        let symbol: String
        let route: PulseRoute
        var id: String { title }
    }

    /// The screen's name as the spec writes it ("Sleep Planner"); the bar shows it in caps.
    let name: String
    let symbol: String
    /// One or two sentences on what the screen will do.
    let summary: String
    /// The WHOOP_UI_SPEC section it follows ("§3.11").
    let spec: String
    /// The group that owns the rebuild ("sleep").
    let group: String
    var links: [Link] = []
    var role: PulseScreenRole = .pushed
    var coach: PulseCoachAccessory = .none

    init(name: String, symbol: String, summary: String, spec: String, group: String, links: [Link] = [],
         role: PulseScreenRole = .pushed, coach: PulseCoachAccessory = .none) {
        self.name = name
        self.symbol = symbol
        self.summary = summary
        self.spec = spec
        self.group = group
        self.links = links
        self.role = role
        self.coach = coach
    }

    var body: some View {
        PulseScreenScaffold(title: name, role: role, coach: coach) {
            PulseCard {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: symbol)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .accessibilityHidden(true)
                    Text(String(localized: "\(name) is being rebuilt"))
                        .pulseText(.cardHeadline)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(summary)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: "WHOOP_UI_SPEC \(spec) · \(group)")
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.top, 2)
                }
            }
            if !links.isEmpty {
                PulseListSectionHeader(String(localized: "Use it today"))
                    .padding(.top, 8)
                VStack(spacing: PulseTheme.Row.listGap) {
                    ForEach(links) { link in
                        PulseLink(link.route) {
                            PulseListRow(symbol: link.symbol, title: link.title)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
            }
        }
    }
}
#endif
