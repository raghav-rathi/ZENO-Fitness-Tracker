import XCTest
@testable import StrandAnalytics

final class VitalSeverityTests: XCTestCase {

    private let rhrCfg = Baselines.metricCfg["resting_hr"]!
    private let hrvCfg = Baselines.metricCfg["hrv"]!

    /// Thirty nights alternating around 55 bpm: a trusted personal baseline.
    private var steadyRHR: [Double?] { (0..<30).map { Double($0 % 2 == 0 ? 54 : 56) } }

    /// The value `k` personal spreads from the folded baseline (z = k).
    private func value(atZ k: Double, history: [Double?], cfg: MetricCfg) -> Double {
        let state = Baselines.foldHistory(history, cfg: cfg)
        XCTAssertTrue(state.trusted)
        return state.baseline + k * 1.253 * state.spread
    }

    private func grade(_ value: Double?, history: [Double?] = [], range: ClosedRange<Double> = 40...60,
                       cfg: MetricCfg?) -> VitalSeverity.Grade {
        VitalSeverity.grade(value: value, history: history, populationRange: range, cfg: cfg)
    }

    func testNoValueIsNoData() {
        XCTAssertEqual(grade(nil, cfg: rhrCfg), .noData)
    }

    // MARK: Personal baseline

    func testPersonalBaselineGradesBySpread() {
        let h = steadyRHR
        XCTAssertEqual(grade(value(atZ: 1.5, history: h, cfg: rhrCfg), history: h, cfg: rhrCfg), .within)
        XCTAssertEqual(grade(value(atZ: 2.5, history: h, cfg: rhrCfg), history: h, cfg: rhrCfg), .out(.high))
        XCTAssertEqual(grade(value(atZ: 3.5, history: h, cfg: rhrCfg), history: h, cfg: rhrCfg), .farOut(.high))
        XCTAssertEqual(grade(value(atZ: -2.5, history: h, cfg: rhrCfg), history: h, cfg: rhrCfg), .out(.low))
        XCTAssertEqual(grade(value(atZ: -3.5, history: h, cfg: rhrCfg), history: h, cfg: rhrCfg), .farOut(.low))
    }

    func testPersonalBaselineIgnoresThePopulationRange() {
        // 64 bpm is past the 40-60 population range, yet within two spreads of a 63 bpm personal norm.
        let high: [Double?] = (0..<30).map { Double($0 % 2 == 0 ? 62 : 64) }
        XCTAssertEqual(grade(64, history: high, cfg: rhrCfg), .within)
    }

    // MARK: Population fallback

    func testPopulationFallbackGradesByDistanceFromTheRange() {
        // No history: the 40-60 range judges, and 10 bpm past an edge (half its width) is the line.
        XCTAssertEqual(grade(55, cfg: rhrCfg), .within)
        XCTAssertEqual(grade(62, cfg: rhrCfg), .out(.high))
        XCTAssertEqual(grade(70, cfg: rhrCfg), .out(.high))
        XCTAssertEqual(grade(75, cfg: rhrCfg), .farOut(.high))
        XCTAssertEqual(grade(35, cfg: rhrCfg), .out(.low))
    }

    func testNoConfigIsPopulationOnly() {
        // Blood oxygen: population-only, 95-100%.
        XCTAssertEqual(grade(97, range: 95...100, cfg: nil), .within)
        XCTAssertEqual(grade(93, range: 95...100, cfg: nil), .out(.low))
        XCTAssertEqual(grade(90, range: 95...100, cfg: nil), .farOut(.low))
    }

    func testOutsidePhysiologicalBoundsIsFarOut() {
        XCTAssertEqual(grade(300, range: 40...120, cfg: hrvCfg), .farOut(.high))
        XCTAssertEqual(grade(25, cfg: rhrCfg), .farOut(.low))
    }

    // MARK: Agreement with VitalBands

    func testInOrOutAlwaysAgreesWithVitalBands() {
        let histories: [[Double?]] = [[], Array(steadyRHR.prefix(5)), steadyRHR,
                                      steadyRHR + [nil, nil, nil], (0..<30).map { _ in nil }]
        for history in histories {
            for v in stride(from: 20.0, through: 130.0, by: 0.5) {
                let band = VitalBands.band(value: v, history: history, populationRange: 40...60, cfg: rhrCfg).band
                let graded = grade(v, history: history, cfg: rhrCfg)
                XCTAssertEqual(graded.isOut, band == .outOfRange, "value \(v), \(history.count) nights")
                XCTAssertEqual(graded == .within, band == .inRange, "value \(v), \(history.count) nights")
            }
        }
        for v in stride(from: 80.0, through: 100.0, by: 0.25) {
            let band = VitalBands.band(value: v, history: [], populationRange: 95...100, cfg: nil).band
            XCTAssertEqual(grade(v, range: 95...100, cfg: nil).isOut, band == .outOfRange, "SpO₂ \(v)")
        }
    }
}
