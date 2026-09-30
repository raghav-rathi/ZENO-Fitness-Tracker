#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The Sleep deep dive for one night: performance and its contributors, the hypnogram, the stages,
/// sleeping heart rate and breathing, and naps. ‹ › move between nights and rebuild EVERYTHING on the
/// screen from that night (the classic Sleep screen only moves its hero and stages).
struct PulseSleepView: View {
    @Environment(PulseModel.self) private var model
    /// Open on Home's night once per visit; a later reappearance (back from a pushed screen) keeps the
    /// night the wearer navigated to.
    @State private var opened = false

    var body: some View {
        PulseDetailScaffold(title: PulseScore.sleep.displayName, subtitle: nightCaption,
                            ready: model.sleep != nil) {
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
            Task { await model.reloadSleep() }
        }
    }

    private var nightCaption: String? {
        guard let s = model.sleep, let key = s.wakeDayKey else { return nil }
        // A night is named by the day it ended on: a DAY KEY, so it is formatted at UTC.
        return String(localized: "Night ending \(PulseFormat.dayLabel(key, template: "EEEdMMM"))")
    }

    @ViewBuilder
    private func content(_ s: SleepSnapshot) -> some View {
        PulseNightNavigator(snapshot: s,
                            onOlder: { model.stepNight(1) },
                            onNewer: { model.stepNight(-1) })

        VStack(spacing: 10) {
            PulseDial(data: s.dial, diameter: 184, lineWidth: 14, showsLabel: false)
            if let asleep = s.asleepMin, let need = s.needMin {
                Text(String(localized: "\(PulseFormat.duration(minutes: asleep)) asleep · \(PulseFormat.duration(minutes: need)) needed"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)

        PulseSleepContributors(rows: s.contributors)

        if s.spans.count >= 2, let onset = s.onset {
            VStack(alignment: .leading, spacing: 10) {
                PulseSectionHeader(title: String(localized: "Stages"),
                                   trailing: s.inBedMin.map { String(localized: "\(PulseFormat.duration(minutes: $0)) in bed") })
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
            .id("pulse.stages")
        } else if !s.stages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                PulseSectionHeader(title: String(localized: "Stages"))
                PulseCard { PulseStageRows(rows: s.stages) }
            }
        } else if s.isStub {
            PulseCard {
                Text(String(localized: "This night has no stage data."))
                    .font(.subheadline)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }

        HStack(spacing: 12) {
            PulseMiniStat(title: String(localized: "Sleeping HR"), value: s.sleepingHR.map { "\($0)" }, unit: "bpm")
            PulseMiniStat(title: String(localized: "Lowest HR"), value: s.lowestHR.map { "\($0)" }, unit: "bpm")
            PulseMiniStat(title: String(localized: "Breathing"), value: s.respRate.map { PulseFormat.oneDecimal($0) },
                          unit: "rpm")
        }

        if !s.naps.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                PulseSectionHeader(title: String(localized: "Naps"))
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
        }

        NavigationLink(value: TabRoute.sleep) {
            PulseActionButtonLabel(title: String(localized: "Open the full Sleep screen"), symbol: "bed.double")
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// ‹ night › with the window's clock times.
struct PulseNightNavigator: View {
    let snapshot: SleepSnapshot
    let onOlder: () -> Void
    let onNewer: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onOlder) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .foregroundStyle(snapshot.hasOlder ? PulseTheme.textPrimary : PulseTheme.textTertiary.opacity(0.5))
            .disabled(!snapshot.hasOlder)
            .accessibilityLabel(String(localized: "Previous night"))

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PulseTheme.textPrimary)
                if let onset = snapshot.onset, let wake = snapshot.wake {
                    Text("\(PulseFormat.clock(onset)) – \(PulseFormat.clock(wake))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Button(action: onNewer) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .foregroundStyle(snapshot.hasNewer ? PulseTheme.textPrimary : PulseTheme.textTertiary.opacity(0.5))
            .disabled(!snapshot.hasNewer)
            .accessibilityLabel(String(localized: "Next night"))
        }
        .padding(.vertical, 2)
        .background(PulseCardSurface(radius: 14))
    }

    private var title: String {
        guard let key = snapshot.wakeDayKey else { return String(localized: "No nights yet") }
        if snapshot.nightIndex == 0 { return String(localized: "Latest night") }
        return PulseFormat.dayLabel(key, template: "EEEEdMMM")
    }
}

/// The four sleep-performance contributors as labelled bars.
struct PulseSleepContributors: View {
    let rows: [PulseSleepContributor]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Contributors"))
            PulseCard {
                VStack(spacing: 14) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(row.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(PulseTheme.textPrimary)
                                Spacer()
                                Text(row.percent.map { "\(PulseDisplay.displayedPercent($0))%" } ?? "–")
                                    .font(PulseTheme.numeral(20))
                                    .foregroundStyle(row.percent == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(PulseTheme.track)
                                    if let p = row.percent {
                                        Capsule()
                                            .fill(PulseTheme.sleep)
                                            .frame(width: max(6, geo.size.width * min(1, max(0, p / 100))))
                                    }
                                }
                            }
                            .frame(height: 6)
                            if let detail = row.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(PulseTheme.textTertiary)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(row.title), \(row.percent.map { "\(PulseDisplay.displayedPercent($0)) percent" } ?? String(localized: "no data"))\(row.detail.map { ", \($0)" } ?? "")")
                    }
                }
            }
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
