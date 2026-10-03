import Foundation

// PulseLevels.swift - the 30-level ladder behind the Pulse Profile's LEVEL card and the Levels page.
//
// A level is earned by SCORED RECOVERIES, not by days worn: every day whose stored daily row carries a
// Recovery counts once. The ladder is WHOOP_UI_SPEC §3.30's resolved table (every in-app data point the
// spec checked agrees with it: 1226 recoveries is level 22, 1907 is 25, 2344 is 27, 2999 is "1 more to
// 30"), six tiers of five levels each, level 30 the top.
//
// Display-only by design: nothing here is persisted, fed back into an engine or sent across the .noopbak
// boundary, so there is no Kotlin twin to keep byte-identical (the same rule as `PulseDisplay`). Pure, no
// clock, no I/O.

public enum PulseLevels {

    /// The six tiers, five levels each. `rawValue` is the tier's index, which is also the number of stars
    /// its medal carries (Beginner none, Bronze one, … Diamond five).
    public enum Tier: Int, CaseIterable, Equatable, Sendable {
        case beginner, bronze, silver, gold, platinum, diamond
    }

    /// What a level's plaque is made of. Levels 1–6 name their own materials (spec §3.30); the names of
    /// levels 7–30 were never seen, so from the Bronze tier on a level takes its tier's material.
    public enum Material: String, CaseIterable, Equatable, Sendable {
        case carbon, iron, steel, gunmetal, titanium, bronze, silver, gold, platinum, diamond
    }

    /// The highest level.
    public static let maxLevel = 30

    /// The fewest scored recoveries each level needs, level 1 first.
    public static let thresholds: [Int] = [
        0, 4, 7, 14, 21,                // Beginner  L1–L5
        30, 40, 50, 65, 80,             // Bronze    L6–L10
        100, 125, 150, 200, 250,        // Silver    L11–L15
        300, 400, 500, 650, 800,        // Gold      L16–L20
        1000, 1200, 1400, 1600, 1800,   // Platinum  L21–L25
        2000, 2250, 2500, 2750, 3000,   // Diamond   L26–L30
    ]

    /// Where a recovery count sits on the ladder.
    public struct Progress: Equatable, Sendable {
        /// The level reached, 1...30.
        public let level: Int
        /// The scored recoveries counted.
        public let recoveries: Int
        /// The fewest recoveries this level needs.
        public let levelMinimum: Int
        /// The next level and the recoveries it needs; nil at level 30.
        public let nextLevel: Int?
        public let nextMinimum: Int?

        /// Recoveries still to go to the next level; nil at level 30.
        public var remaining: Int? { nextMinimum.map { max(0, $0 - recoveries) } }
        /// True at the top of the ladder.
        public var isMax: Bool { nextLevel == nil }
        /// How far the count has come from this level's minimum toward the next one, 0...1 (1 at the top).
        public var fraction: Double {
            guard let nextMinimum, nextMinimum > levelMinimum else { return 1 }
            return min(1, max(0, Double(recoveries - levelMinimum) / Double(nextMinimum - levelMinimum)))
        }
        public var tier: Tier { PulseLevels.tier(forLevel: level) }
    }

    /// The level `recoveries` reaches (1 for none; a negative count reads as none).
    public static func level(forRecoveries recoveries: Int) -> Int {
        let count = max(0, recoveries)
        return thresholds.lastIndex(where: { $0 <= count }).map { $0 + 1 } ?? 1
    }

    /// The whole position: level, its minimum, the next level and what it needs.
    public static func progress(recoveries: Int) -> Progress {
        let count = max(0, recoveries)
        let level = level(forRecoveries: count)
        let next = level < maxLevel ? level + 1 : nil
        return Progress(level: level, recoveries: count, levelMinimum: thresholds[level - 1],
                        nextLevel: next, nextMinimum: next.map { thresholds[$0 - 1] })
    }

    /// The fewest recoveries `level` needs, or nil outside 1...30.
    public static func minimum(forLevel level: Int) -> Int? {
        (1...maxLevel).contains(level) ? thresholds[level - 1] : nil
    }

    /// The tier a level belongs to (levels outside 1...30 clamp to the nearest end).
    public static func tier(forLevel level: Int) -> Tier {
        let clamped = min(maxLevel, max(1, level))
        return Tier(rawValue: (clamped - 1) / 5) ?? .beginner
    }

    /// The material a level's plaque is drawn in.
    public static func material(forLevel level: Int) -> Material {
        switch min(maxLevel, max(1, level)) {
        case 1: return .carbon
        case 2: return .iron
        case 3: return .steel
        case 4: return .gunmetal
        case 5: return .titanium
        default:
            switch tier(forLevel: level) {
            case .beginner, .bronze: return .bronze
            case .silver: return .silver
            case .gold: return .gold
            case .platinum: return .platinum
            case .diamond: return .diamond
            }
        }
    }

    /// True for the first level of every tier after Beginner (6, 11, 16, 21, 26): the grid rings it.
    public static func isTierStart(_ level: Int) -> Bool {
        level > 5 && level <= maxLevel && (level - 1) % 5 == 0
    }

    /// How many days in a history carry a scored Recovery. A nil, NaN or infinite value is not a score.
    public static func scoredRecoveries(_ recoveries: [Double?]) -> Int {
        recoveries.reduce(0) { count, value in
            guard let value, value.isFinite else { return count }
            return count + 1
        }
    }
}
