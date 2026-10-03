import Foundation

// HealthspanBreakdown.swift — the years a Healthspan pillar row prints, only when they add up to the
// ZENO Age the page shows.
//
// ZENO Age is the VitalityEngine Body Age the weekly scoring pass STORES for each week ("body_age"). A
// pillar row explains it factor by factor: the factor's log-hazard in years (`VitalityEngine.years(for:)`),
// which the screen recomputes from the week's daily rows. The two are one fact read twice, and they part
// whenever the recomputation no longer sees what the pass saw:
//   - the pass ran before the week's last days arrived (or before an import replaced them);
//   - the merged daily rows differ from the computed days the pass scored;
//   - the age clamp moved the stored age (the factors then add up to more than the gap shown);
//   - the stored value did not come from the engine at all (a seeded demo store).
// A breakdown that does not add up to the age above it would contradict it, so this returns the per-factor
// years only when their sum lands on the stored gap; otherwise the screen withholds them.
//
// Pure, database-free and deterministic. Wellness estimate, never a clinical measure.
public enum HealthspanBreakdown {

    /// How far the factors' summed years may sit from the stored gap (ZENO Age minus the chronological
    /// age) and still be shown. The pass stores the engine's full-precision value, so a breakdown of the
    /// same inputs lands within rounding; a value rounded to one decimal lands within 0.05.
    public static let tolerance = 0.1

    /// Each factor's years (keyed by `VitalityEngine.Contribution.key`; negative takes years off) for
    /// `inputs`, when they add up to `storedBodyAge − inputs.chronoAge` within `tolerance`. nil when the
    /// engine would not score the inputs (fewer than `VitalityEngine.minFactors`) or the sum misses.
    public static func years(_ inputs: VitalityEngine.Inputs, storedBodyAge: Double) -> [String: Double]? {
        guard storedBodyAge.isFinite, let result = VitalityEngine.compute(inputs) else { return nil }
        let factors = result.contributions.map { (key: $0.key, years: VitalityEngine.years(for: $0)) }
        let sum = factors.reduce(0) { $0 + $1.years }
        guard abs(sum - (storedBodyAge - inputs.chronoAge)) <= tolerance else { return nil }
        return Dictionary(factors.map { ($0.key, $0.years) }, uniquingKeysWith: { _, last in last })
    }
}
