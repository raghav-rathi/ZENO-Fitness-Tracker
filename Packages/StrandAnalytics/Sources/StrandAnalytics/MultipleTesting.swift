import Foundation

// MultipleTesting.swift — false-discovery-rate control for a family of tests.
//
// "What Moves You" tests every behaviour against every outcome at three lags. At p < 0.05 with no
// correction, 20 truly-null tests produce about one "significant" finding by chance, and the feed then
// shows that fluke with the same badge as a real effect. Benjamini–Hochberg bounds the expected share of
// false findings among those surfaced instead, which is the right guarantee for a list of candidates a
// person reads (Benjamini & Hochberg 1995).

public enum MultipleTesting {

    /// Benjamini–Hochberg adjusted p-values ("q-values"), in the same order as `pValues`.
    ///
    /// With the m p-values ranked ascending, q at rank i is min over j ≥ i of p_(j) · m / j, capped at 1
    /// — the step-up procedure's monotone form, so rejecting every test with q < α controls the FDR at α
    /// for independent (or positively dependent) tests. A non-finite p is treated as 1.
    public static func benjaminiHochberg(_ pValues: [Double]) -> [Double] {
        let m = pValues.count
        guard m > 0 else { return [] }
        let order = pValues.indices.sorted {
            let a = pValues[$0].isFinite ? pValues[$0] : 1, b = pValues[$1].isFinite ? pValues[$1] : 1
            return a != b ? a < b : $0 < $1
        }
        var q = [Double](repeating: 1, count: m)
        var running = 1.0
        for rank in stride(from: m, through: 1, by: -1) {
            let i = order[rank - 1]
            let p = pValues[i].isFinite ? pValues[i] : 1
            running = min(running, p * Double(m) / Double(rank))
            q[i] = min(max(running, 0), 1)
        }
        return q
    }
}
