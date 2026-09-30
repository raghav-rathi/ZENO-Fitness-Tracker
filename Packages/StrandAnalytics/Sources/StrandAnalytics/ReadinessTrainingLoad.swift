import WhoopStore

public extension ReadinessEngine {
    /// Readiness plus descriptive long-horizon training-load state.
    ///
    /// The training-load result is deliberately OUTSIDE the Readiness synthesis. CTL/ATL/TSB do not
    /// change `readiness.level`, signals, confidence, or any headline score; they are contextual trends
    /// for charts and explanations. This keeps the existing ACWR/monotony behavior intact and makes any
    /// future decision to feed training-load state into a score an explicit, separately validated change.
    struct TrainingLoadAnalysis: Sendable, Equatable {
        public let readiness: Readiness
        public let trainingLoad: TrainingLoadEngine.Result

        public init(readiness: Readiness, trainingLoad: TrainingLoadEngine.Result) {
            self.readiness = readiness
            self.trainingLoad = trainingLoad
        }
    }

    /// Evaluate existing Readiness and the CTL/ATL/TSB model over the same daily-metric history.
    ///
    /// `today` has the same stale-data semantics as `ReadinessEngine.evaluate`: when supplied, both
    /// analyses target exactly that YYYY-MM-DD. A missing target therefore yields an insufficient
    /// Readiness and `trainingLoad.unavailableReason == .missingTargetDay` rather than falling back to an
    /// older row. With no explicit target, both use the latest row.
    static func evaluateWithTrainingLoad(
        days: [DailyMetric],
        today: String? = nil,
        trainingLoadConfiguration: TrainingLoadEngine.Configuration = .standard
    ) -> TrainingLoadAnalysis {
        let readiness = evaluate(days: days, today: today)
        let trainingLoad = TrainingLoadEngine.evaluate(
            days: trainingLoadDays(days),
            through: today,
            configuration: trainingLoadConfiguration
        )
        return TrainingLoadAnalysis(readiness: readiness, trainingLoad: trainingLoad)
    }

    /// The calendar-day loads the CTL/ATL/TSB model runs on: each day's linear `dailyLoad`
    /// (TRIMP-equivalent), the same load ACWR and monotony use, so every load read-out is on one scale.
    /// A day without an Effort stays unobserved (nil), never an invented zero.
    static func trainingLoadDays(_ days: [DailyMetric]) -> [TrainingLoadEngine.DailyLoad] {
        days.map { TrainingLoadEngine.DailyLoad(day: $0.day, load: $0.strain.map { dailyLoad(effort: $0) }) }
    }
}
