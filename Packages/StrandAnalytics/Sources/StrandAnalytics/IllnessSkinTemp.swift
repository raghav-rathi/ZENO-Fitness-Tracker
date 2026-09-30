import Foundation

// IllnessSkinTemp.swift — the skin-temperature input to the illness heads-up, deviation-only.
//
// `DailyMetric.skinTempDevC` is bimodal (#622): a strap night stores a signed DEVIATION from the personal
// baseline (±°C), but a WHOOP CSV / Health import stores the ABSOLUTE wrist temperature (~30–35 °C) in the
// same column. The heads-up divided the recent mean of that column by a 0.3 °C spread, so one imported
// 33 °C night inside the recent window read as z ≈ 110 — a guaranteed second corroborating signal the
// moment an import overlapped recent days. Only deviation-kind values may enter the reading; absolute ones
// are dropped rather than converted, because converting needs a baseline an import-only night lacks.

public extension IllnessSignalEngine {

    /// One personal spread of nightly skin-temperature deviation (°C) — the `skin_temp` baseline's floor
    /// spread — so a recent mean deviation of +0.6 °C reads as z = 2.
    static let skinTempDeviationSpreadC: Double = 0.3

    /// The mean of the recent nights' skin-temperature DEVIATIONS (°C), keeping only values
    /// `SkinTempDisplay` classifies as a deviation. nil when none remain.
    static func recentSkinTempDeviation(_ values: [Double?]) -> Double? {
        let deviations = values.compactMap { $0 }
            .filter { $0.isFinite && SkinTempDisplay.kind(of: $0) == .deviation }
        guard !deviations.isEmpty else { return nil }
        return deviations.reduce(0, +) / Double(deviations.count)
    }

    /// The illness-ward skin-temperature reading for the recent window (warmer = more illness-like), or nil
    /// when the window holds no deviation-kind value.
    static func skinTempReading(recentValues: [Double?]) -> SignalReading? {
        recentSkinTempDeviation(recentValues).map { SignalReading(zIllnessward: $0 / skinTempDeviationSpreadC) }
    }
}
