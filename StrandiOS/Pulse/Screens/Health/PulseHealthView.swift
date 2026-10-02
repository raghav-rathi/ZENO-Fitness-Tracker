#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The current Pulse Health tab, in the new theme: the Health Monitor (each vital against its typical
/// range), Stress, the healthspan estimates, the cycle card when it applies, the Lab Book and Steps.
/// Always "now", whatever day Home is showing.
///
/// Owned by group "health", which rebuilds the tab as `PulseHealthTabView` (ZENO Age orb, Pace of Aging,
/// monitor and stress cards). Until then that tab hosts this screen.
struct PulseHealthView: View {
    let onAction: (PulseQuickAction) -> Void

    @Environment(PulseModel.self) private var model

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Health"), role: .tabRoot,
                            spacing: PulseTheme.Layout.healthStackGap,
                            refresh: { await model.pullToRefresh() }, ready: model.health != nil) {
            PulseLoadingGate(isLoading: model.health == nil) {
                if let health = model.health {
                    PulseHealthMonitor(vitals: health.vitals)
                        .id("pulse.monitor")
                    if let stress = health.stress {
                        PulseStressSection(stress: stress, onBreathe: { onAction(.breathe) })
                            .id("pulse.stress")
                    }
                    PulseHealthspanSection(health: health)
                        .id("pulse.healthspan")
                    MenstrualCycleHomeCard()
                    PulseHealthLinks(health: health)
                        .id("pulse.records")
                }
            } skeleton: {
                PulseSkeleton.cards([280, 200, 160])
            }
        }
        .task(id: model.healthKey) { await model.loadHealth() }
    }
}

// MARK: - Health Monitor

struct PulseHealthMonitor: View {
    let vitals: [PulseVital]

    private var summary: String {
        let judged = vitals.filter { $0.band != .noData }
        let inRange = judged.filter { $0.band == .inRange }.count
        guard !judged.isEmpty else { return String(localized: "No readings yet") }
        return String(localized: "\(inRange) of \(judged.count) in range")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Health Monitor"), trailing: summary)
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(vitals.enumerated()), id: \.element.id) { index, vital in
                        NavigationLink(value: vital.route) {
                            PulseVitalRow(vital: vital)
                        }
                        .buttonStyle(PulsePressStyle())
                        if index < vitals.count - 1 { PulseRowDivider() }
                    }
                }
            }
        }
    }
}

struct PulseVitalRow: View {
    let vital: PulseVital

    private var statusSymbol: String {
        switch vital.band {
        case .inRange: return "checkmark.circle.fill"
        case .outOfRange: return "exclamationmark.circle.fill"
        case .noData: return "minus.circle"
        }
    }

    private var statusTint: Color {
        switch vital.band {
        case .inRange: return PulseTheme.accent
        case .outOfRange: return PulseTheme.attention
        case .noData: return PulseTheme.textTertiary
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: statusSymbol)
                .font(.title3)
                .foregroundStyle(statusTint)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(vital.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    if let value = vital.value {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(value)
                                .font(PulseTheme.numeral(20))
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(vital.unit)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    } else {
                        Text(String(localized: "No data"))
                            .font(.caption)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                if let fraction = vital.valueFraction {
                    PulseRangeBar(value: fraction, typical: vital.typicalFraction, tint: statusTint)
                        .frame(height: 12)
                }
                HStack {
                    if let range = vital.rangeText {
                        Text("\(vital.basisText) \(range)")
                    }
                    Spacer(minLength: 6)
                    if let day = vital.dayLabel { Text(day) }
                }
                .font(.caption2)
                .foregroundStyle(PulseTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            PulseChevron()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
        .accessibilityHint(String(localized: "Opens the trend"))
    }

    private var accessibility: String {
        let status: String
        switch vital.band {
        case .inRange: status = String(localized: "in range")
        case .outOfRange: status = String(localized: "outside the typical range")
        case .noData: status = String(localized: "no data")
        }
        guard let value = vital.value else { return "\(vital.title), \(status)" }
        let range = vital.rangeText.map { ", \(vital.basisText) \($0)" } ?? ""
        return "\(vital.title), \(value) \(vital.unit), \(status)\(range)"
    }
}

/// A value marker on a track with its typical range shaded. `TypicalRangeBar` draws a fill FROM zero,
/// which reads as "how much"; a vital needs "where", so this marks a point instead.
struct PulseRangeBar: View {
    let value: Double
    let typical: ClosedRange<Double>?
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let v = min(1, max(0, value))
            ZStack(alignment: .leading) {
                Capsule().fill(PulseTheme.track).frame(height: 4)
                if let typical {
                    let lo = min(1, max(0, typical.lowerBound)), hi = min(1, max(0, typical.upperBound))
                    Capsule()
                        .fill(PulseTheme.textPrimary.opacity(0.28))
                        .frame(width: max(4, w * (hi - lo)), height: 4)
                        .offset(x: w * lo)
                }
                Circle()
                    .fill(tint)
                    .overlay(Circle().strokeBorder(PulseTheme.backgroundTop, lineWidth: 2))
                    .frame(width: h, height: h)
                    .offset(x: min(max(0, w * v - h / 2), w - h))
            }
            .frame(height: h)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Healthspan

struct PulseHealthspanSection: View {
    let health: HealthSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Healthspan"), trailing: String(localized: "Weekly"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                      spacing: 12) {
                tile(String(localized: "Body Age"), health.bodyAge.map { PulseFormat.whole($0) },
                     String(localized: "yrs"), "figure.stand", .metric("body_age"))
                tile(String(localized: "Fitness Age"), health.fitnessAge.map { fitnessAgeText($0) },
                     String(localized: "yrs"), "figure.run", .metric("fitness_age"))
                tile(String(localized: "VO₂ max"), health.vo2max.map { PulseFormat.oneDecimal($0) },
                     "ml/kg/min", "lungs.fill", .metric("vo2max_est"))
                tile(String(localized: "Vitality"), health.vitality.map { PulseFormat.whole($0) },
                     "/ 100", "sparkles", .metric("vitality"))
            }
        }
    }

    /// Fitness Age is clamped to the model's span; a clamped value is shown as a bound, as on Health.
    private func fitnessAgeText(_ v: Double) -> String {
        "\(fitnessAgeBoundSymbol(v))\(PulseFormat.whole(v))"
    }

    private func tile(_ title: String, _ value: String?, _ unit: String, _ symbol: String,
                      _ route: TabRoute) -> some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .accessibilityHidden(true)
                    PulseLabel(title)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value ?? "–")
                        .font(PulseTheme.numeral(30))
                        .foregroundStyle(value == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                    if value != nil {
                        Text(unit)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                if value == nil {
                    Text(String(localized: "Needs a few weeks of wear"))
                        .font(.caption2)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(PulseCardSurface())
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(value.map { "\(title), \($0) \(unit)" } ?? "\(title), no data")
        }
        .buttonStyle(PulsePressStyle())
    }
}

// MARK: - Links

struct PulseHealthLinks: View {
    let health: HealthSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Records"))
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    // Today's total from the shared steps resolver; opens the Steps screen (TabRoute.steps).
                    NavigationLink(value: health.stepsRoute) {
                        PulseRow(title: String(localized: "Steps"),
                                 subtitle: String(localized: "Today and your trend"),
                                 value: health.stepsToday.map { PulseFormat.grouped($0) }) {
                            PulseRowIcon(symbol: "figure.walk", tint: PulseTheme.accent)
                        }
                    }
                    .buttonStyle(PulsePressStyle())
                    PulseRowDivider()
                    NavigationLink(value: PulseRoute.classic(.labBook)) {
                        PulseRow(title: String(localized: "Lab Book"),
                                 subtitle: String(localized: "Your private health records")) {
                            PulseRowIcon(symbol: "books.vertical.fill", tint: PulseTheme.accent)
                        }
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
    }
}
#endif
