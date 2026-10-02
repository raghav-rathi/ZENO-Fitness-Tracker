#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The current Pulse Sleep dive (WHOOP_UI_SPEC §3.3 in the new theme) for one night: the night pager,
/// the 260 pt Sleep Performance ring, its contributors in the notched callout, the hypnogram and stages,
/// sleeping heart rate and breathing, and naps. ‹ › move between nights and rebuild EVERYTHING on the
/// screen from that night (the classic Sleep screen only moves its hero and stages).
///
/// Owned by group "sleep", which rebuilds it as `PulseSleepDiveView` (Last Night's Sleep detail cards,
/// Weekly Trends, the coach summary pill). Until then that route hosts this screen.
struct PulseSleepView: View {
    @Environment(PulseModel.self) private var model
    /// Open on Home's night once per visit; a later reappearance (back from a pushed screen) keeps the
    /// night the wearer navigated to.
    @State private var opened = false

    var body: some View {
        PulseScreenScaffold(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                            coach: .button, ready: model.sleep != nil) {
            if let s = model.sleep {
                content(s)
            } else {
                PulseDetailLoading()
            }
        }
        .task {
            guard !opened else { return }
            opened = true
            await model.openSleep()
        }
        .onChange(of: model.seq) { _, _ in
            model.reloadSleep()
        }
    }

    @ViewBuilder
    private func content(_ s: SleepSnapshot) -> some View {
        PulseNightNavigator(snapshot: s,
                            onOlder: { model.stepNight(1) },
                            onNewer: { model.stepNight(-1) })

        VStack(spacing: 10) {
            PulseHeroRing(content: s.dial.dialContent(label: String(localized: "Sleep performance"))) {
                PulseMiniSegments(active: PulseSleepBand.index(percent: s.dial.value))
                .padding(.top, 2)
            }
            if let asleep = s.asleepMin, let need = s.needMin {
                Text(String(localized: "\(PulseFormat.duration(minutes: asleep)) asleep · \(PulseFormat.duration(minutes: need)) needed"))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)

        PulseSleepContributors(rows: s.contributors)
            .id("pulse.contributors")

        if s.spans.count >= 2, let onset = s.onset {
            VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
                PulseSectionHeader(String(localized: "Stages"),
                                   accessory: s.inBedMin.map { .caption(String(localized: "\(PulseFormat.duration(minutes: $0)) in bed")) } ?? .none)
                PulseCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Hypnogram(intervals: s.spans.map { SleepInterval(stage: $0.stage, start: $0.start, end: $0.end) },
                                  height: 150, showsStageAxis: true, showsHover: false,
                                  nightStart: onset, showsTimeAxis: true, stagePalette: .oura)
                            .accessibilityLabel(String(localized: "Hypnogram"))
                        PulseStageRows(rows: s.stages)
                    }
                }
            }
            .padding(.top, PulseTheme.Space.xs)
            .id("pulse.stages")
        } else if !s.stages.isEmpty {
            VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
                PulseSectionHeader(String(localized: "Stages"))
                PulseCard { PulseStageRows(rows: s.stages) }
            }
            .padding(.top, PulseTheme.Space.xs)
        } else if s.isStub {
            PulseCard {
                Text(String(localized: "This night has no stage data."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }

        HStack(spacing: PulseTheme.Layout.gridGap) {
            PulseMiniStat(title: String(localized: "Sleeping HR"), value: s.sleepingHR.map { "\($0)" }, unit: "bpm")
            PulseMiniStat(title: String(localized: "Lowest HR"), value: s.lowestHR.map { "\($0)" }, unit: "bpm")
            PulseMiniStat(title: String(localized: "Breathing"), value: s.respRate.map { PulseFormat.oneDecimal($0) },
                          unit: "rpm")
        }

        if !s.naps.isEmpty {
            VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
                PulseSectionHeader(String(localized: "Naps"))
                PulseCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(s.naps.enumerated()), id: \.element.id) { index, nap in
                            PulseRow(title: String(localized: "Nap"),
                                     subtitle: "\(PulseFormat.clock(nap.start)) – \(PulseFormat.clock(nap.end))",
                                     value: PulseFormat.duration(minutes: nap.asleepMin),
                                     showsChevron: false) {
                                PulseRowIcon(symbol: "powersleep", tint: PulseTheme.sleep)
                            }
                            if index < s.naps.count - 1 { PulseRowDivider() }
                        }
                    }
                }
            }
            .padding(.top, PulseTheme.Space.xs)
        }

        NavigationLink(value: PulseRoute.tab(.sleep)) {
            PulseActionButtonLabel(title: String(localized: "Open the full Sleep screen"), symbol: "bed.double")
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// "‹ LAST NIGHT ›" (§1.7 [Z]): the shared day pager, stepping night by night, with the night's window
/// under it.
struct PulseNightNavigator: View {
    let snapshot: SleepSnapshot
    let onOlder: () -> Void
    let onNewer: () -> Void

    private var title: String {
        guard let key = snapshot.wakeDayKey else { return String(localized: "No nights yet") }
        if snapshot.nightIndex == 0 { return String(localized: "Last night") }
        // A night is named by the day it ended on: a DAY KEY, so it is formatted at UTC.
        return PulseFormat.navDayTitle(dayKey: key)
    }

    var body: some View {
        VStack(spacing: 8) {
            PulseDayPager(title: title, canGoBack: snapshot.hasOlder, canGoForward: snapshot.hasNewer,
                          onBack: onOlder, onForward: onNewer)
            if let onset = snapshot.onset, let wake = snapshot.wake {
                Text("\(PulseFormat.clock(onset)) – \(PulseFormat.clock(wake))")
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// The four sleep-performance contributors as callout rows: each percent with its Poor / Sufficient /
/// Optimal segments and the figures behind it.
struct PulseSleepContributors: View {
    let rows: [PulseSleepContributor]

    var body: some View {
        PulseCallout {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    PulseCalloutRow(symbol: Self.symbol(row.id), title: row.title,
                                    value: row.percent.map { "\(PulseDisplay.displayedPercent($0))" } ?? "--",
                                    unit: row.percent == nil ? nil : "%",
                                    baseline: row.detail,
                                    segments: row.performanceBand)
                    if index < rows.count - 1 {
                        PulseDivider(leadingInset: 16, trailingInset: 16)
                    }
                }
            }
            PulseLegendWell { PulseLegendPoorSufficientOptimal() }
        }
    }

    private static func symbol(_ id: String) -> String {
        switch id {
        case "hours": return "moon.zzz"
        case "efficiency": return "bed.double"
        case "consistency": return "clock.arrow.circlepath"
        case "restorative": return "sparkles"
        default: return "moon"
        }
    }
}

/// Minutes and share per stage, in the hypnogram's own colours.
struct PulseStageRows: View {
    let rows: [PulseStageRow]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows) { row in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(StrandPalette.sleepStageColor(row.stage, palette: .oura))
                        .frame(width: 12, height: 12)
                    Text(name(row.stage))
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer()
                    Text(PulseFormat.duration(minutes: row.minutes))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text("\(Int((row.share * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 40, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(name(row.stage)), \(PulseFormat.duration(minutes: row.minutes)), \(Int((row.share * 100).rounded())) percent")
            }
        }
    }

    private func name(_ stage: SleepStage) -> String {
        switch stage {
        case .awake: return String(localized: "Awake")
        case .light: return String(localized: "Light")
        case .deep: return String(localized: "Deep")
        case .rem: return String(localized: "REM")
        }
    }
}

#endif
