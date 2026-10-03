#if os(iOS)
import SwiftUI

/// Health Monitor (WHOOP_UI_SPEC §3.21), pushed from Home's tile and the Health tab's card: the
/// calibration banner while the personal ranges are still learning, the live HEART RATE strip (moved here
/// from the Home header, §1.4), a two-column grid of vitals each against its range, and SHARE YOUR HEALTH
/// REPORT (the existing PDF report). Today only; history lives in the report and the Trend Views.
///
/// Every tile's colour is the `VitalBands` verdict Home's HEALTH MONITOR tile counts; its words read the
/// value against ±1σ of your own baseline once that baseline is trusted ("within 51 - 54", "near …",
/// "low < 49"), else against the typical adult range.
struct PulseHealthMonitorView: View {
    /// Rebuilt: existing entry points (Home's tile, the dashboard) open this instead of the classic screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var snapshot: HealthMonitorSnapshot?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Health Monitor"), coach: .button,
                            coachSeed: coachSeed, spacing: 0, topPadding: 4, ready: snapshot != nil) {
            HealthLiveHRStrip()
                .padding(.bottom, 20)
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot {
                    content(snapshot)
                }
            } skeleton: {
                PulseSkeleton.cards([118, 118, 118, 56])
            }
        }
        .task(id: model.healthKey) {
            if let s = await model.build(dayOffset: 0, { builder, request in await builder.healthMonitor(request) }) {
                if snapshot != s { snapshot = s }
            }
        }
    }

    @ViewBuilder
    private func content(_ s: HealthMonitorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let calibration = s.calibration {
                HealthMonitorCalibrationBanner(calibration: calibration)
                    .padding(.bottom, 20)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: PulseTheme.Layout.gridGap, alignment: .top),
                                GridItem(.flexible(), spacing: PulseTheme.Layout.gridGap, alignment: .top)],
                      alignment: .leading, spacing: PulseTheme.Layout.gridGap) {
                ForEach(s.vitals) { vital in
                    PulseLink(healthTrendRoute(vital.route)) {
                        HealthVitalTile(vital: vital)
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
            .id("pulse.tiles")
            Button {
                navigator.present(.classic(.report))
            } label: {
                HStack(spacing: 18) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .accessibilityHidden(true)
                    Text(String(localized: "Share your health report"))
                        .pulseText(.menuLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .pulseCardBackground()
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .padding(.top, 40)
            .id("pulse.report")
            Text(String(localized: "Printable report for sharing with your doctor, physician, trainer, or anyone of your choosing."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
    }

    /// The Coach's seed: what the page shows, in plain words.
    private var coachSeed: String? {
        guard let s = snapshot else { return nil }
        let parts = s.vitals.compactMap { v -> String? in
            guard let value = v.value else { return nil }
            return "\(v.name) \(PulseFormat.withUnit(value, v.unit)) (\(v.chipText))"
        }
        return parts.isEmpty ? nil : String(localized: "Health Monitor today: \(parts.joined(separator: "; ")).")
    }
}

/// A vital's trend: the Trend View for its metric once the trends group has rebuilt it, the metric's
/// detail screen until then.
func healthTrendRoute(_ route: TabRoute) -> PulseRoute {
    if case .metric(let key) = route { return PulseRoute.trendView(metric: key).forExistingEntryPoint }
    return .tab(route)
}

/// "Wear your strap to sleep 9 more nights to calibrate." over a 7-segment bar (onboarding/32b), while the
/// personal baselines are still learning (`Baselines.minNightsTrust` nights of HRV). Until then the tiles
/// are judged against the typical adult range, and say so.
struct HealthMonitorCalibrationBanner: View {
    let calibration: HealthMonitorSnapshot.Calibration

    private var remaining: Int { max(0, calibration.needed - calibration.nights) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(remaining == 1
                 ? String(localized: "Wear your strap to sleep 1 more night to calibrate your ranges.")
                 : String(localized: "Wear your strap to sleep \(remaining) more nights to calibrate your ranges."))
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            // Seven segments, as WHOOP draws its seven nights; each one here is two of ZENO's nights.
            HealthSegmentBar(count: 7, filled: Int((Double(calibration.nights) / Double(max(1, calibration.needed)) * 7).rounded(.down)))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(HealthPalette.monitorBannerFill))
        .accessibilityElement(children: .combine)
    }
}

/// One vital: icon + caps label (11 pt, 70%, up to two lines), the value (34 pt) with its unit (14 pt,
/// 50%), and the status chip under it (help-center/87, 88; reviews/33). ≈118 pt tall, padding 12.
struct HealthVitalTile: View {
    let vital: HealthVital

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: vital.symbol)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                PulseWordWrapText(vital.tileTitle, style: .label)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            Spacer(minLength: 12)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(vital.value ?? "--")
                    .font(PulseType.font(.largeValue))
                    .foregroundStyle(vital.value == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if vital.value != nil {
                    Text(vital.unit)
                        .pulseText(.tileUnit)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                Spacer(minLength: 0)
                if vital.isCarried, let key = vital.dayKey {
                    Text(PulseFormat.dayLabel(key, template: "MMMd"))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            HealthVitalChip(vital: vital)
                .padding(.top, 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .pulseCardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(vital.name)
        .accessibilityValue(accessibility)
        .accessibilityHint(String(localized: "Opens the trend"))
    }

    private var accessibility: String {
        guard let value = vital.value else { return vital.chipText }
        var parts = [PulseFormat.withUnit(value, vital.unit), vital.chipText]
        if vital.isCarried, let key = vital.dayKey { parts.append(String(localized: "from \(PulseFormat.dayLabel(key, template: "MMMd"))")) }
        parts.append(vital.isPersonal ? String(localized: "your own range") : String(localized: "typical adult range"))
        return parts.joined(separator: ", ")
    }
}

/// "✓ within 13.8 - 14.8" (teal), "! low < 95" (orange), "! very high > 62" (red), "● No reading yet" (grey).
struct HealthVitalChip: View {
    let vital: HealthVital

    private var style: (glyph: String, text: Color, fill: Color) {
        switch vital.status {
        case .within: return ("✓", PulseTheme.positive, PulseTheme.Tint.teal.fill)
        case .outside(let severe):
            return severe ? ("!", PulseTheme.Tint.red.glyph, PulseTheme.Tint.red.fill)
                          : ("!", PulseTheme.negative, PulseTheme.Tint.orange.fill)
        case .noData: return ("●", PulseTheme.textSecondary, PulseTheme.Tint.grey.fill)
        }
    }

    var body: some View {
        let s = style
        HStack(spacing: 5) {
            Text(verbatim: s.glyph).font(.system(size: vital.status == .noData ? 8 : 11, weight: .heavy))
            Text(vital.chipText)
                .pulseText(.chipStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(s.text)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(s.fill))
        .accessibilityHidden(true)
    }
}
#endif
