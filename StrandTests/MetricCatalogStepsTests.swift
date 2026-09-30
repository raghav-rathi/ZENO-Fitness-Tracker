import XCTest
@testable import Strand

/// Which daily count Today shows for steps is no longer a catalog question: every steps surface resolves
/// through `StepsResolver` (StrandAnalytics, tested there). What stays here is that each source's history
/// remains addressable on its own, and that catalog order never decides a bare-key lookup.
final class MetricCatalogStepsTests: XCTestCase {
    func testAppleHealthStepsRemainsAnIndependentCatalogMetric() {
        let metric = MetricCatalog.metric(key: "steps", source: "apple-health")

        XCTAssertEqual(metric?.id, "apple-health:steps")
    }

    /// Both measured WHOOP steps and the WHOOP 4.0 estimate must be resolvable by EXACT source, so a
    /// surface can route to them (via `.metricSourced`) without depending on catalog declaration order.
    func testWhoopStepsAreResolvableBySource() {
        XCTAssertEqual(MetricCatalog.metric(key: "steps", source: "my-whoop")?.id, "my-whoop:steps")
        XCTAssertEqual(MetricCatalog.metric(key: "steps_est", source: "my-whoop")?.id, "my-whoop:steps_est")
    }

    /// Regression guard: the bare-key `first { $0.key == "steps" }` resolvers that are NOT source-aware
    /// (LabBookView's correlation descriptors, CompareView's default/legacy picks, the TabRoute `.metric`
    /// fallback) must keep resolving Apple Health, exactly as before the measured-WHOOP entry was added.
    /// The measured entry is declared AFTER apple-health precisely so it never captures these lookups —
    /// the Today surface reaches it explicitly instead. If a future edit reorders the catalog, this fails
    /// loudly rather than silently emptying those screens for an Apple-Health-steps user.
    func testBareKeyStepsResolutionStaysAppleHealth() {
        XCTAssertEqual(MetricCatalog.all.first(where: { $0.key == "steps" })?.source, "apple-health")
    }
}
