#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Weekly Digest (WHOOP_UI_SPEC §3.40, a ZENO screen: WHOOP has none in-app), pushed, restyling the classic
/// `WeeklyDigestView` on the same engine (`WeeklyDigestEngine`):
///
///   1. "‹ WEEKLY DIGEST", the range pager ("‹ SEP 22 - SEP 28 ›") and W | M for the monthly digest;
///   2. Sleep, Recovery and Strain averages as Home's three dials, each with its chip against the period
///      before (the THIS WEEK card on the Trends tab reads the same week);
///   3. the deep dives' Weekly Trends cards for RECOVERY, STRAIN and SLEEP PERFORMANCE;
///   4. Highlights: best Recovery, max Strain, longest sleep, most time in HR zones, each with its day;
///   5. Behaviors this week: the journal behaviours logged, each with its effect on Recovery over 90 days;
///   6. a plain summary (local text, not the Coach's), ASK COACH when the Coach is on, and EXPORT REPORT.
///
/// The plan block (§3.40 item 3) appears once Weekly Plan data exists; ZENO has none yet. Owned by group
/// "trends".
struct PulseWeeklyDigestView: View {
    /// Existing entry points (Trends › THIS WEEK, INSIGHTS) open this screen instead of the classic Weekly
    /// digest once it is true (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    @Environment(PulseModel.self) private var model
    @State private var mode: WeeklyDigestSnapshot.Mode = .week
    @State private var page = 0
    @State private var snapshot: WeeklyDigestSnapshot?
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""

    init() {
        #if DEBUG
        _mode = State(initialValue: PulseTrendDebugLaunch.digestMode ?? .week)
        _page = State(initialValue: PulseTrendDebugLaunch.page ?? 0)
        #endif
    }

    private var units: PulseTrendUnits {
        let system = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        return PulseTrendUnits(fahrenheit: UnitPrefs.resolveTemperature(system: system, override: temperatureRaw) == .fahrenheit,
                               imperialMass: system == .imperial)
    }

    private var modeBinding: Binding<WeeklyDigestSnapshot.Mode> {
        Binding(get: { mode }, set: { new in
            guard new != mode else { return }
            mode = new
            page = 0
        })
    }

    var body: some View {
        PulseScreenScaffold(title: mode == .week ? String(localized: "Weekly Digest") : String(localized: "Monthly Digest"),
                            coach: .button, coachSeed: snapshot?.insight, spacing: 0, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot {
                    PulseDigestContent(snapshot: snapshot, mode: modeBinding,
                                       onBack: { page += 1 }, onForward: { page = max(0, page - 1) })
                }
            } skeleton: {
                VStack(spacing: PulseTheme.Layout.stackGap) {
                    PulseSkeletonBlock(height: 36, radius: PulseTheme.Radius.control)
                    HStack(spacing: 30) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().strokeBorder(PulseTheme.skeleton, lineWidth: PulseTheme.Dial.homeStroke)
                                .frame(width: PulseTheme.Dial.homeDiameter, height: PulseTheme.Dial.homeDiameter)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    PulseSkeletonBlock(height: 280)
                    PulseSkeletonBlock(height: 280)
                }
                .padding(.top, 8)
                .accessibilityElement()
                .accessibilityLabel(String(localized: "Loading"))
            }
        }
        .task(id: "\(model.healthKey)|\(mode.rawValue)|\(page)|\(units.id)") {
            let mode = self.mode, page = self.page, units = self.units
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.weeklyDigest(request, mode: mode, page: page, units: units)
            }) {
                snapshot = s
                if s.page != self.page { self.page = s.page }
            }
        }
    }
}

// MARK: - Content

private struct PulseDigestContent: View {
    let snapshot: WeeklyDigestSnapshot
    @Binding var mode: WeeklyDigestSnapshot.Mode
    let onBack: () -> Void
    let onForward: () -> Void

    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.pulseCoach) private var coach

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                PulseTrendRangePager(pager: snapshot.pager, onBack: onBack, onForward: onForward)
                    .frame(maxWidth: .infinity)
                PulseSegmentedControl(options: WeeklyDigestSnapshot.Mode.allCases, selection: $mode) { $0.segmentTitle }
                    .frame(width: 104)
                    .accessibilityLabel(String(localized: "Week or month"))
            }
            .padding(.top, 8)

            PulseDialColumns(contents: snapshot.pillars.map(\.content), routes: snapshot.pillars.map(\.route))
                .padding(.top, 28)
            HStack(spacing: 0) {
                ForEach(snapshot.pillars) { pillar in
                    Group {
                        if let chip = pillar.chip {
                            PulseDeltaChip(text: chip.text, trend: chip.trend)
                        } else {
                            Color.clear.frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
            if let note = snapshot.note {
                Text(note)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            if !snapshot.hasData {
                PulseCard {
                    Text(snapshot.mode == .week
                         ? String(localized: "No Sleep, Recovery or Strain readings this week yet. Wear your strap to bed and through the day and your digest fills in.")
                         : String(localized: "No Sleep, Recovery or Strain readings this month yet."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
            } else {
                PulseSectionHeader(snapshot.mode == .week ? String(localized: "Weekly Trends") : String(localized: "Monthly Trends"),
                                   style: .weeklyTrendsTitle)
                    .padding(.top, PulseTheme.Layout.sectionGap)
                VStack(spacing: PulseTheme.Layout.stackGap) {
                    ForEach(snapshot.cards) { card in
                        PulseLink(card.route) {
                            PulseChartCard(card.title, accessory: .chevron) {
                                PulseBarChart(data: card.data, yDomain: card.yDomain, gridValues: card.gridValues,
                                              highlightID: card.highlightID, barWidth: snapshot.mode == .week ? 14 : 5)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
                .padding(.top, PulseTheme.Layout.headerGap)

                if !snapshot.highlights.isEmpty {
                    highlights.padding(.top, PulseTheme.Layout.stackGap)
                }
                if !snapshot.behaviors.isEmpty {
                    behaviors.padding(.top, PulseTheme.Layout.stackGap)
                }
                summary.padding(.top, PulseTheme.Layout.stackGap)
            }

            Button { navigator.present(.classic(.report)) } label: {
                Label(String(localized: "Export report"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.pulseOutlineWhite)
            .padding(.top, 24)
        }
    }

    // MARK: Cards

    private var highlights: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(String(localized: "Highlights"))
                    .padding(.bottom, 6)
                ForEach(Array(snapshot.highlights.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { PulseDivider() }
                    HStack(spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .pulseText(.label)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(item.day)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                        Spacer(minLength: 8)
                        PulseValueText(value: item.value, unit: item.unit.isEmpty ? nil : item.unit, style: .calloutValue,
                                       unitStyle: .tileUnit)
                    }
                    .frame(minHeight: 56)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.title), \(item.day), \(item.value) \(item.unit)")
                }
            }
        }
    }

    private var behaviors: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(snapshot.mode == .week ? String(localized: "Behaviors this week")
                                                      : String(localized: "Behaviors this month"))
                Text(String(localized: "Their effect on your Recovery over the last 90 days"))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                ForEach(Array(snapshot.behaviors.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { PulseDivider() }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.title)
                                .pulseText(.rowText)
                                .foregroundStyle(PulseTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(item.logged)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                        if let effect = item.effect {
                            PulseImpactBar(fraction: item.fraction, effect: effect, valueText: item.valueText)
                        } else if let note = item.note {
                            Text(note)
                                .pulseText(.rowSubline)
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var summary: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.insight)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if coach.availability != .off {
                    PulseTextCTA(title: String(localized: "Ask Coach about this period"), tint: .ai) {
                        coach.open(snapshot.insight)
                    }
                }
            }
        }
    }
}
#endif
