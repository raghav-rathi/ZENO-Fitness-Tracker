#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Legacy components
//
// Pieces the first Pulse screens are built from, kept so those screens keep working while the next wave
// rebuilds them. New screens use the catalogue in this folder (PulseDials, PulseRows, PulseCallout,
// PulseCharts, …) instead; once no screen uses one of these, delete it.

// MARK: - Strain target

/// The 0-21 strain track with the recommended range shaded and the day's strain filled in.
struct PulseStrainTargetBar: View {
    let target: PulseStrainTarget
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lo = CGFloat(target.range.lowerBound / 21)
            let hi = CGFloat(target.range.upperBound / 21)
            let current = CGFloat(min(1, max(0, (target.current ?? 0) / 21)))
            let knob = height + 6
            ZStack(alignment: .leading) {
                Capsule().fill(PulseTheme.track)
                // The recommended range.
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(PulseTheme.strain.opacity(0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .strokeBorder(PulseTheme.strain.opacity(0.8), lineWidth: 1)
                    )
                    .frame(width: max(height, w * (hi - lo)))
                    .offset(x: w * lo)
                // The day so far.
                if target.current != nil {
                    Capsule()
                        .fill(PulseTheme.strain)
                        .frame(width: max(height, w * current))
                    Circle()
                        .fill(PulseTheme.textPrimary)
                        .frame(width: knob, height: knob)
                        .offset(x: min(max(0, w * current - knob / 2), w - knob))
                }
            }
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: height + 8)
        .accessibilityHidden(true)
    }
}

/// The Strain Target card body: intent, range, the bar and where the day stands.
struct PulseStrainTargetContent: View {
    let target: PulseStrainTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                PulseLabel(String(localized: "Strain target"), color: PulseTheme.textSecondary)
                Spacer(minLength: 8)
                if let label = target.currentLabel {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(target.intentTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(PulseTheme.recoveryText(target.band))
                Text(target.rangeText)
                    .font(PulseTheme.numeral(22))
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 0)
            }
            PulseStrainTargetBar(target: target)
            HStack {
                Text("0").font(.caption2.monospacedDigit())
                Spacer()
                Text(target.progressText).font(.caption)
                Spacer()
                Text("21").font(.caption2.monospacedDigit())
            }
            .foregroundStyle(PulseTheme.textTertiary)
            if target.fromCarriedRecovery {
                Text(String(localized: "Based on your last scored Recovery."))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        let base = String(localized: "Strain target: \(target.intentTitle), \(target.rangeText) out of 21.")
        guard let label = target.currentLabel else { return base + " " + target.progressText }
        return base + " " + "\(label). \(target.progressText)."
    }
}

// MARK: - Sparkline

/// A tiny static trend line with a dot on the latest point. No gestures, no animation, so it can sit
/// inside a tappable tile without competing for the tap.
struct PulseSparkline: View {
    let values: [Double]
    var tint: Color = PulseTheme.textSecondary

    var body: some View {
        GeometryReader { geo in
            if values.count >= 2, let lo = values.min(), let hi = values.max() {
                let span = max(hi - lo, 0.0001)
                let step = geo.size.width / CGFloat(values.count - 1)
                let inset: CGFloat = 3
                let h = geo.size.height - inset * 2
                let point: (Int) -> CGPoint = { i in
                    CGPoint(x: CGFloat(i) * step,
                            y: inset + h - CGFloat((values[i] - lo) / span) * h)
                }
                Path { p in
                    p.move(to: point(0))
                    for i in 1..<values.count { p.addLine(to: point(i)) }
                }
                .stroke(tint.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                    .position(point(values.count - 1))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Comparison line

/// "▲ 8% vs 30-day avg".
struct PulseComparisonLine: View {
    let comparison: PulseComparison
    var showsCaption = true

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
            Text(comparison.text)
                .font(.caption.weight(.semibold).monospacedDigit())
            if showsCaption {
                Text(comparison.caption)
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(PulseTheme.textSecondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(comparison.accessibility)
    }

    private var symbol: String {
        switch comparison.direction {
        case .up: return "arrowtriangle.up.fill"
        case .down: return "arrowtriangle.down.fill"
        case .flat: return "minus"
        }
    }
}

// MARK: - Rows

/// A tappable list row: icon, title and subtitle, a trailing value, a chevron. At accessibility text
/// sizes the value moves under the title, so neither is truncated to make room for the other.
struct PulseRow<Icon: View>: View {
    let title: String
    var subtitle: String?
    var value: String?
    var valueCaption: String?
    var valueTint: Color = PulseTheme.textPrimary
    var showsChevron = true
    @ViewBuilder var icon: () -> Icon

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: typeSize.isAccessibilitySize ? .top : .center, spacing: 12) {
            icon()
                .frame(width: 36, height: 36)
                .background(Circle().fill(PulseTheme.cardRaised))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if typeSize.isAccessibilitySize { valueStack(alignment: .leading).padding(.top, 4) }
            }
            Spacer(minLength: 8)
            if !typeSize.isAccessibilitySize { valueStack(alignment: .trailing) }
            if showsChevron { PulseChevron() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func valueStack(alignment: HorizontalAlignment) -> some View {
        if value != nil || valueCaption != nil {
            VStack(alignment: alignment, spacing: 2) {
                if let value {
                    Text(value)
                        .font(PulseTheme.numeral(20))
                        .foregroundStyle(valueTint)
                }
                if let valueCaption {
                    Text(valueCaption)
                        .font(.caption2)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
    }
}

/// A row's round SF Symbol icon.
struct PulseRowIcon: View {
    let symbol: String
    var tint: Color = PulseTheme.textSecondary

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}

/// A hairline between rows in a grouped card.
struct PulseRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(PulseTheme.hairline)
            .frame(height: 1)
            .padding(.leading, 62)
    }
}

// MARK: - Big button

/// A full-width in-card button (Breathe, Open the full Sleep screen): the spec's nested button, white 10%
/// on the card, radius 10, an icon and UPPERCASE 12 pt text at 85%. `prominent` is the white capsule.
struct PulseActionButtonLabel: View {
    let title: String
    var symbol: String?
    var prominent = false

    var body: some View {
        HStack(spacing: 8) {
            if let symbol { Image(systemName: symbol).font(.system(size: 14, weight: .semibold)) }
            Text(title).pulseText(.cardTitle)
        }
        .foregroundStyle(prominent ? Color.black : PulseTheme.textButton)
        .frame(maxWidth: .infinity)
        .frame(minHeight: PulseTheme.Row.nestedButton)
        .background {
            if prominent {
                Capsule(style: .circular).fill(Color.white)
            } else {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(PulseTheme.nested)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Chip and page helpers (moved from the first theme file)

/// A compact text chip (e.g. "Today", a band word): a nested capsule, no border.
struct PulseChip: View {
    let text: String
    var tint: Color = PulseTheme.textSecondary
    var filled = false

    var body: some View {
        Text(text)
            .pulseText(.secondary)
            .foregroundStyle(filled ? PulseTheme.onAccent : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? tint : PulseTheme.nested)
            )
    }
}

extension View {
    /// DEBUG `--pulse-scroll <anchor>`: once `ready`, scroll to the tagged section so a screenshot can
    /// capture it (simctl cannot swipe). Compiles to nothing in Release.
    @ViewBuilder
    func pulseDebugScroll(_ proxy: ScrollViewProxy, ready: Bool) -> some View {
        #if DEBUG
        self.task(id: ready) {
            guard ready, let anchor = PulseDebugLaunch.scrollAnchor else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            proxy.scrollTo(anchor, anchor: .top)
        }
        #else
        self
        #endif
    }

    /// A page that keeps the SYSTEM navigation bar (a sheet's own stack): the fixed gradient behind, the
    /// bar transparent over it, forced dark. Pulse screens use `PulseScreenScaffold` instead.
    func pulsePage() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(PulseBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Stress card (Home and Health)

struct PulseStressSection: View {
    let stress: PulseStressSummary
    let onBreathe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Stress"),
                               trailing: stress.isToday ? String(localized: "Today") : nil)
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink(value: TabRoute.stress) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(stress.scoreText)
                                .font(PulseTheme.numeral(36))
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text("/ 3")
                                .font(PulseTheme.numeral(16, weight: .semibold))
                                .foregroundStyle(PulseTheme.textTertiary)
                            if let band = stress.bandTitle {
                                PulseChip(text: band.capitalized, tint: PulseTheme.textSecondary)
                                    .padding(.leading, 6)
                            }
                            Spacer(minLength: 0)
                            PulseChevron()
                        }
                        .frame(minHeight: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "Stress \(stress.scoreText) out of 3\(stress.bandTitle.map { ", \($0.lowercased())" } ?? "")"))
                    .accessibilityHint(String(localized: "Opens Stress"))

                    if stress.hasCurve {
                        DaytimeLoadLine(hours: stress.hours)
                    } else if stress.isToday {
                        Text(String(localized: "The hourly curve fills in as your strap records heart rate through the day."))
                            .font(.caption)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: onBreathe) {
                        PulseActionButtonLabel(title: String(localized: "Breathe"), symbol: "wind")
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
    }
}
// MARK: - Detail loading

/// A loading placeholder for a dive whose snapshot is still building: the dive's skeleton after 200 ms,
/// never a spinner (DR §8). New screens use `PulseLoadingGate` / `PulseSkeleton` directly.
struct PulseDetailLoading: View {
    var body: some View {
        PulseLoadingGate(isLoading: true) {
            EmptyView()
        } skeleton: {
            PulseSkeleton.dive
        }
    }
}

// MARK: - Mini stat

/// A small titled number in its own card.
struct PulseMiniStat: View {
    let title: String
    let value: String?
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PulseLabel(title)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value ?? "–")
                    .font(PulseTheme.numeral(24))
                    .foregroundStyle(value == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if value != nil {
                    Text(unit)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulseCardSurface())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.map { "\(title), \($0) \(unit)" } ?? "\(title), no data")
    }
}
#endif
