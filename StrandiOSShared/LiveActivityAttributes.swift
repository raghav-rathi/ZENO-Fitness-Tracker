#if os(iOS)
import Foundation
import ActivityKit

/// Live Activity attributes for an active live-HR / workout session. Shared between the app (which
/// starts/updates the activity) and the widget extension (which renders it on the Lock Screen and in
/// the Dynamic Island).
public struct NOOPActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var bpm: Int?
        public var recovery: Int?
        public var bonded: Bool
        // Effort / strain on NOOP's 0–100 axis (#446) — one more stat in the Dynamic Island expanded
        // region. OPTIONAL with a nil default so an activity started by an older build still decodes.
        public var effort: Int?
        /// `effort` as the banner prints it, on the resolved Effort scale (WHOOP's 0–21 under Pulse), formatted
        /// by the app like the widget's `effortDisplay`. Nil from an older build: the banner falls back to `effort`.
        public var effortDisplay: String?
        /// Which names the banner gives the scores (`GlanceScoreNames`): true under the iPhone's Pulse interface,
        /// false in the classic one, nil (an older build) read as Pulse. Published for the same reason as the
        /// widget's `pulseVocabulary`.
        public var pulseVocabulary: Bool?

        public init(bpm: Int?, recovery: Int?, bonded: Bool, effort: Int? = nil,
                    effortDisplay: String? = nil, pulseVocabulary: Bool? = nil) {
            self.bpm = bpm
            self.recovery = recovery
            self.bonded = bonded
            self.effort = effort
            self.effortDisplay = effortDisplay
            self.pulseVocabulary = pulseVocabulary
        }

        /// The names to give the scores on the banner.
        public var scoreNames: GlanceScoreNames { GlanceScoreNames(pulse: pulseVocabulary) }
    }

    /// Static title shown for the session.
    public var title: String

    public init(title: String = "Live HR") {
        self.title = title
    }
}
#endif
