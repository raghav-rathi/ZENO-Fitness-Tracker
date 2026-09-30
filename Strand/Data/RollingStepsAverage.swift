import Foundation
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Calendar-day window, never 30 observed rows. Missing observations are not zero.
///
/// The arithmetic lives in `StepsStats.average` so the Steps screen's 30-day average is this card's number
/// by construction, not by two copies agreeing. The readings come from `Repository.resolvedSteps`, the one
/// steps resolver (Steps/StepsRepository.swift).
struct RollingStepsAverage: Equatable {
    let mean: Double?
    let observedDays: Int

    static let windowDays = 30

    static func startDay(ending day: String) -> String? {
        StepsDayKeys.adding(-(windowDays - 1), to: day)
    }

    static func calculate(readings: [(day: String, value: Double)], ending day: String) -> Self {
        let average = StepsStats.average(readings: readings, endingOn: day, days: windowDays)
        return .init(mean: average.mean, observedDays: average.observedDays)
    }
}

/// Loads only when explicitly enabled. Task identity follows the selected day and repository refresh.
struct RollingStepsAverageCard: View {
    let day: String
    @EnvironmentObject private var repo: Repository
    @State private var result: RollingStepsAverage?
    @State private var resultDay: String?

    var body: some View {
        let current = resultDay == day ? result : nil
        NavigationLink(value: TabRoute.metricSourced(key: "steps", source: MetricCatalog.combinedStepsSource)) {
            HStack(spacing: 12) {
                Image(systemName: DashboardCard.stepsAverage30.icon)
                    .foregroundStyle(StrandPalette.metricCyan)
                VStack(alignment: .leading, spacing: 4) {
                    Text(DashboardCard.stepsAverage30.title)
                        .font(StrandFont.subhead).foregroundStyle(StrandPalette.textPrimary)
                    Text(current.map { String(localized: "\($0.observedDays) of 30 days") } ?? "—")
                        .font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
                }
                Spacer(minLength: 8)
                Text(current?.mean.map { $0.formatted(.number.locale(AppLanguage.activeLocale).precision(.fractionLength(0))) } ?? "—")
                    .font(StrandFont.number(20)).foregroundStyle(StrandPalette.textPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .padding(14)
            .background(NoopPanelSurface(tint: StrandPalette.metricCyan, cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .task(id: "\(day)|\(repo.refreshSeq)") {
            guard let start = RollingStepsAverage.startDay(ending: day) else { return }
            let readings = await repo.resolvedSteps(from: start, to: day)
            guard !Task.isCancelled else { return }
            result = RollingStepsAverage.calculate(readings: readings.values, ending: day)
            resultDay = day
        }
    }
}
