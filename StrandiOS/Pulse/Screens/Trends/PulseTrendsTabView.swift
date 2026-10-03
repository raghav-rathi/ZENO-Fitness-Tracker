#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Trends tab ("TRENDS"), ZENO's replacement for WHOOP's Community tab (WHOOP_UI_SPEC §1.1, §3.35):
///
///   1. THIS WEEK: Sleep, Recovery and Strain this week (Monday to today) against last week, each with its
///      mini ring and delta chip; the card opens the Weekly Digest, which reads the same week;
///   2. SLEEP · RECOVERY · STRAIN · STRESS · BODY: dashboard-style rows (the newest value with ▲▼ against
///      its 30-day average, the average under it, a 7-day sparkline), each opening its Trend View;
///   3. INSIGHTS: ZENO's analysis screens (What moves you, Explore, Compare, the Weekly Digest, the report,
///      Training load, Tomorrow's Recovery).
///
/// The rows read the series the Trend View charts (`PulseSnapshotBuilder.trendsTab`), so a row and the page
/// it opens agree. Owned by group "trends".
struct PulseTrendsTabView: View {
    /// NavRouter's "open Trends" lands on this tab once it is true, instead of pushing the classic Trends
    /// screen onto it.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var snapshot: TrendsTabSnapshot?
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""

    private var units: PulseTrendUnits {
        let system = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        return PulseTrendUnits(fahrenheit: UnitPrefs.resolveTemperature(system: system, override: temperatureRaw) == .fahrenheit,
                               imperialMass: system == .imperial)
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Trends"), role: .tabRoot, spacing: 0,
                            refresh: { await model.refresh() }, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { PulseTrendsTabContent(snapshot: snapshot) }
            } skeleton: {
                VStack(spacing: PulseTheme.Layout.gridGap) {
                    PulseSkeletonBlock(height: 176)
                    ForEach(0..<5, id: \.self) { _ in PulseSkeletonBlock(height: PulseTheme.Row.dashboard) }
                }
                .accessibilityElement()
                .accessibilityLabel(String(localized: "Loading"))
            }
            insights
                .id("pulse.insights")
        }
        .task(id: "\(model.healthKey)|\(units.id)") {
            let units = self.units
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.trendsTab(request, units: units)
            }) {
                snapshot = s
            }
        }
    }

    // MARK: Insights

    private var insights: some View {
        VStack(alignment: .leading, spacing: 0) {
            PulseListSectionHeader(String(localized: "Insights"))
                .padding(.top, 32)
                .padding(.bottom, 14)
            VStack(spacing: PulseTheme.Row.listGap) {
                link(String(localized: "What moves you"), String(localized: "Behaviors ranked by their effect, with dose and response"),
                     "wand.and.sparkles", .classic(.insightsHub))
                link(String(localized: "Explore"), String(localized: "Every metric, and the full day's heart rate"),
                     "square.grid.2x2", .classic(.explore))
                link(String(localized: "Compare"), String(localized: "Two to four metrics on one chart"),
                     "rectangle.split.2x1", .classic(.compare))
                link(String(localized: "Weekly Digest"), String(localized: "Your week, pillar by pillar"),
                     "calendar", PulseRoute.weeklyDigest.forExistingEntryPoint)
                Button { navigator.present(.classic(.report)) } label: {
                    PulseListRow(symbol: "doc.richtext", title: String(localized: "Report"),
                                 subtitle: String(localized: "A PDF of any range to keep or share"))
                }
                .buttonStyle(PulsePressStyle())
                link(String(localized: "Training load"), String(localized: "Fitness, fatigue and form from your Strain"),
                     "chart.line.uptrend.xyaxis", PulseRoute.trainingLoad.forExistingEntryPoint)
                link(String(localized: "Tomorrow's Recovery"), String(localized: "A forecast from today's inputs"),
                     "brain.head.profile", .classic(.intelligence))
            }
        }
    }

    private func link(_ title: String, _ subtitle: String, _ symbol: String, _ route: PulseRoute) -> some View {
        PulseLink(route) {
            PulseListRow(symbol: symbol, title: title, subtitle: subtitle)
        }
        .buttonStyle(PulsePressStyle())
    }
}

// MARK: - Content

private struct PulseTrendsTabContent: View {
    let snapshot: TrendsTabSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !snapshot.week.isEmpty {
                PulseLink(PulseRoute.weeklyDigest.forExistingEntryPoint) {
                    PulseTrendsWeekCard(snapshot: snapshot)
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens the Weekly Digest"))
            }
            ForEach(snapshot.sections) { section in
                PulseListSectionHeader(section.pillar.title)
                    .padding(.top, 32)
                    .padding(.bottom, 14)
                VStack(spacing: PulseTheme.Row.listGap) {
                    ForEach(section.rows) { row in
                        PulseLink(.trendView(metric: row.id)) {
                            PulseTrendsMetricRow(row: row)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
            }
        }
    }
}

/// THIS WEEK ›: one line per pillar (mini ring, name, this week's average, chip against last week).
private struct PulseTrendsWeekCard: View {
    let snapshot: TrendsTabSnapshot

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                // The week's dates at the right of the title; under it when both no longer fit one line.
                // The title is sized to its words: `PulseCardTitle` fills its row, and given the row it
                // left the dates no width at all.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        PulseCardTitle(String(localized: "This week"), accessory: .chevron)
                            .fixedSize()
                        Spacer(minLength: 8)
                        weekDates.fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        PulseCardTitle(String(localized: "This week"), accessory: .chevron)
                        weekDates
                    }
                }
                VStack(spacing: 0) {
                    ForEach(Array(snapshot.week.enumerated()), id: \.element.id) { index, line in
                        if index > 0 { PulseDivider() }
                        // One line at the default sizes; at large text the chip moves under the name.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                ring(line)
                                name(line)
                                Spacer(minLength: 8)
                                if let chip = line.chip {
                                    PulseDeltaChip(text: chip.text, trend: chip.trend).fixedSize()
                                }
                                value(line)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 12) {
                                    ring(line)
                                    name(line)
                                    Spacer(minLength: 8)
                                    value(line)
                                }
                                if let chip = line.chip {
                                    PulseDeltaChip(text: chip.text, trend: chip.trend)
                                        .padding(.leading, PulseTheme.Dial.miniDiameter + 12)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(minHeight: 48)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(line.accessibility)
                    }
                }
                .padding(.top, 10)
                if let note = snapshot.weekNote {
                    Text(note)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.top, 6)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var weekDates: some View {
        Text(snapshot.weekTitle)
            .pulseText(.secondary)
            .foregroundStyle(PulseTheme.textSecondary)
            .accessibilityLabel(String(localized: "Week of \(snapshot.weekTitle)"))
    }

    private func ring(_ line: TrendsTabSnapshot.WeekLine) -> some View {
        PulseMiniRing(content: line.ring)
    }

    private func name(_ line: TrendsTabSnapshot.WeekLine) -> some View {
        Text(line.score.displayName)
            .pulseText(.label)
            .foregroundStyle(PulseTheme.textPrimary)
            .lineLimit(1)
            .fixedSize()
    }

    private func value(_ line: TrendsTabSnapshot.WeekLine) -> some View {
        Text(line.value)
            .pulseText(.rowValue)
            .foregroundStyle(line.ring.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary)
            .fixedSize()
            .frame(minWidth: 48, alignment: .trailing)
    }
}

/// A Trends row: icon and name at the left (the reading's day under the name when it is not today), a
/// 7-day sparkline, then the value with its ▲▼ and the 30-day average under it.
///
/// It draws My Dashboard's row (`PulseMetricRow`: the same icon, title, value, glyph and baseline styles,
/// paddings and card) with the caption and sparkline added inside it, which the shared row has no slot for
/// yet; once it gains one (a caption and a trailing accessory), this becomes that row.
struct PulseTrendsMetricRow: View {
    let row: TrendsTabSnapshot.Row

    @ScaledMetric(relativeTo: .body) private var iconSize = PulseTheme.Trends.rowIcon

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.symbol)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                if let caption = row.caption {
                    Text(caption)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if row.value != nil {
                PulseTrendsSparkline(values: row.spark, color: row.color)
                    .frame(width: 44, height: 22)
                    .accessibilityHidden(true)
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        PulseValueText(value: row.value ?? "", unit: row.unit.isEmpty ? nil : row.unit,
                                       style: .tileValue, unitStyle: .tileUnit)
                        if let trend = row.trend {
                            PulseTrendGlyph(trend: trend)
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] + 4 }
                        }
                    }
                    if let baseline = row.baseline {
                        Text(baseline)
                            .pulseText(.baseline)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                .frame(minWidth: 64, alignment: .trailing)
            } else {
                PulseChevron()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.dashboard, alignment: .leading)
        .pulseCardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibility)
        .accessibilityHint(String(localized: "Opens its Trend View"))
    }
}

/// A tiny line through the last seven days (gaps skipped), the newest point dotted. Nothing animates.
struct PulseTrendsSparkline: View {
    let values: [Double?]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let present = values.enumerated().compactMap { i, v in v.map { (i, $0) } }
            guard present.count >= 2, let lo = present.map(\.1).min(), let hi = present.map(\.1).max() else {
                if let only = present.first {
                    let x = size.width * CGFloat(only.0) / CGFloat(max(1, values.count - 1))
                    context.fill(Path(ellipseIn: CGRect(x: x - 2, y: size.height / 2 - 2, width: 4, height: 4)),
                                 with: .color(color))
                }
                return
            }
            let span = max(hi - lo, abs(hi) * 0.05, 0.0001)
            func point(_ i: Int, _ v: Double) -> CGPoint {
                CGPoint(x: size.width * CGFloat(i) / CGFloat(max(1, values.count - 1)),
                        y: 2 + (size.height - 4) * CGFloat(1 - (v - lo) / span))
            }
            var path = Path()
            path.addLines(present.map { point($0.0, $0.1) })
            context.stroke(path, with: .color(color.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            if let last = present.last {
                let p = point(last.0, last.1)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(color))
            }
        }
    }
}
#endif
