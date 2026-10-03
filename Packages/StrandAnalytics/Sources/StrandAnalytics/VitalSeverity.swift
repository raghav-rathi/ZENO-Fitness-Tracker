import Foundation

/// How far out of its typical range a vital sits: the Health Monitor tile's ELEVATED / LOW for a vital just
/// past its band and VERY ELEVATED / VERY LOW for one well past it (WHOOP_UI_SPEC §3.1 item 6).
///
/// It decides in or out of range exactly as `VitalBands.band` does, from the same inputs, gates and
/// σ·k band, and then goes one step further for a value that is out: how far out. So a value this calls
/// `within` is one `VitalBands` calls in range, and the reverse (pinned by VitalSeverityTests).
///
/// - Trusted personal baseline: |z| ≤ `VitalBands.sigmaK` (2) is within, up to `veryK` (3) is out, beyond
///   that far out.
/// - Population fallback (cold start, stale baseline, no `MetricCfg`): inside the range is within, past an
///   edge by up to `veryPopulationFraction` of the range's width is out, further is far out.
/// - Outside the metric's physiological bounds (`MetricCfg.minVal ... maxVal`): far out.
///
/// APPROXIMATE: informational, not a diagnosis. Display-only, so there is no Kotlin twin to keep in step.
public enum VitalSeverity {

    /// Which side of its band a value sits on.
    public enum Direction: String, Equatable, Sendable {
        case high, low
    }

    public enum Grade: Equatable, Sendable {
        case noData
        case within
        /// Past the typical band.
        case out(Direction)
        /// Well past it.
        case farOut(Direction)

        /// Out of range at all (what `VitalBands` calls `.outOfRange`).
        public var isOut: Bool {
            switch self {
            case .out, .farOut: return true
            case .noData, .within: return false
            }
        }
    }

    /// |z| above this, against a trusted personal baseline, is far out (VERY ELEVATED / VERY LOW).
    public static let veryK: Double = 3.0
    /// Past a population range's edge by more than this fraction of its width is far out.
    public static let veryPopulationFraction: Double = 0.5

    /// Grade one vital. The parameters are `VitalBands.band`'s, with the same meaning.
    public static func grade(value: Double?,
                             history: [Double?],
                             populationRange: ClosedRange<Double>,
                             cfg: MetricCfg?) -> Grade {
        guard let value else { return .noData }
        guard let cfg else { return population(value, range: populationRange) }
        // Absolute-plausibility outer guard first, as `VitalBands.band` applies it.
        guard cfg.minVal <= value && value <= cfg.maxVal else {
            return .farOut(value > cfg.maxVal ? .high : .low)
        }
        let state = Baselines.foldHistory(history, cfg: cfg)
        if state.trusted {
            let z = Baselines.deviation(value, state: state).z
            guard abs(z) > VitalBands.sigmaK else { return .within }
            let direction: Direction = z > 0 ? .high : .low
            return abs(z) <= veryK ? .out(direction) : .farOut(direction)
        }
        return population(value, range: populationRange)
    }

    /// Against a fixed typical-adult range: how far past its nearer edge, as a share of its width.
    static func population(_ value: Double, range: ClosedRange<Double>) -> Grade {
        guard !range.contains(value) else { return .within }
        let direction: Direction = value > range.upperBound ? .high : .low
        let past = direction == .high ? value - range.upperBound : range.lowerBound - value
        let width = range.upperBound - range.lowerBound
        return past <= width * veryPopulationFraction ? .out(direction) : .farOut(direction)
    }
}
