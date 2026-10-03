import XCTest
@testable import StrandAnalytics

final class PulseAchievementsTests: XCTestCase {

    private func keys(from start: String, count: Int) -> [String] {
        (0..<count).compactMap { PulseDisplay.dayKey(start, offsetBy: $0) }
    }

    private func badge(_ rule: PulseAchievements.Rule, in badges: [PulseAchievements.Badge],
                       file: StaticString = #filePath, line: UInt = #line) -> PulseAchievements.Badge? {
        let found = badges.first { $0.id == rule.rawValue }
        XCTAssertNotNil(found, "no badge for \(rule)", file: file, line: line)
        return found
    }

    // MARK: Milestones and stars

    func testMilestonesSeenOnWhoopCaptures() {
        // Gear Grinder: 1173 shows 1150 with 1200 next; Sleep Specialist 1950 → 2000.
        XCTAssertEqual(PulseAchievements.milestone(atOrBelow: 1173), 1150)
        XCTAssertEqual(PulseAchievements.milestone(after: 1173), 1200)
        XCTAssertEqual(PulseAchievements.milestone(atOrBelow: 1950), 1950)
        XCTAssertEqual(PulseAchievements.milestone(after: 1950), 2000)
        // Below 100: 1, 5, 10, 25, 50, 100.
        XCTAssertEqual([0, 1, 4, 5, 9, 24, 25, 49, 50, 99, 100, 149, 150].map(PulseAchievements.milestone(atOrBelow:)),
                       [0, 1, 1, 5, 5, 10, 25, 25, 50, 50, 100, 100, 150])
        XCTAssertEqual([0, 1, 37, 99].map(PulseAchievements.milestone(after:)), [1, 5, 50, 100])
    }

    func testStarsMatchEveryCountedSample() {
        // spec §3.30 / gap-6 §3.5: 50 → 1★, 150 → 2★, 250 and 400 → 3★, 500 and 650 → 4★, 800 and 950
        // → 5★, 1050, 1350 and 2300 → 6★; nothing under 50.
        let samples: [(Int, Int)] = [(25, 0), (50, 1), (150, 2), (250, 3), (400, 3), (500, 4), (650, 4),
                                     (800, 5), (950, 5), (1050, 6), (1350, 6), (2300, 6)]
        for (milestone, stars) in samples {
            XCTAssertEqual(PulseAchievements.stars(forMilestone: milestone), stars, "milestone \(milestone)")
        }
    }

    // MARK: Rules

    func testACumulativeBadgeShowsItsLastMilestoneDatedTheDayItFell() {
        let dayKeys = keys(from: "2026-06-01", count: 30)
        // 27 nights of 85%+, three that fall short.
        let days = dayKeys.enumerated().map { i, key in
            PulseAchievements.Day(day: key, sleepPerformance: [3, 10, 20].contains(i) ? 70 : 90)
        }
        let restful = badge(.restfulNights, in: PulseAchievements.evaluate(days: days, activities: []))
        XCTAssertEqual(restful?.count, 27)
        XCTAssertEqual(restful?.shown, 25)
        XCTAssertEqual(restful?.nextMilestone, 50)
        XCTAssertEqual(restful?.remaining, 23)
        XCTAssertEqual(restful?.stars, 0)
        // The 25th qualifying night: 27 nights start Jun 1, skipping the 4th, 11th and 21st days.
        XCTAssertEqual(restful?.unlockedDay, "2026-06-28")
        XCTAssertEqual(restful?.kind, .cumulative)
    }

    func testMissingValuesNeverQualify() {
        let days = [PulseAchievements.Day(day: "2026-06-01"),
                    PulseAchievements.Day(day: "2026-06-02", recovery: .nan, strain: nil)]
        let badges = PulseAchievements.evaluate(days: days, activities: [])
        XCTAssertTrue(badges.filter { $0.rule != nil }.allSatisfy { !$0.isUnlocked })
    }

    func testGreenIsJudgedOnThePrintedPercent() {
        // 66.5 prints 67% and is green; 66.4 prints 66% and is not.
        let days = [PulseAchievements.Day(day: "2026-06-01", recovery: 66.5),
                    PulseAchievements.Day(day: "2026-06-02", recovery: 66.4)]
        let green = badge(.greenLight, in: PulseAchievements.evaluate(days: days, activities: []))
        XCTAssertEqual(green?.count, 1)
        XCTAssertEqual(green?.unlockedDay, "2026-06-01")
    }

    func testEventBadgesCountOccurrencesDatedTheLatest() {
        let days = [PulseAchievements.Day(day: "2026-06-01", recovery: 99.2, strain: 18.4),
                    PulseAchievements.Day(day: "2026-06-05", recovery: 4.6, strain: 12),
                    PulseAchievements.Day(day: "2026-06-09", recovery: 98.6, strain: 19)]
        let badges = PulseAchievements.evaluate(days: days, activities: [])
        let near = badge(.nearPerfect, in: badges)
        XCTAssertEqual(near?.shown, 2)                       // 99.2 and 98.6 both print 99%
        XCTAssertEqual(near?.unlockedDay, "2026-06-09")
        XCTAssertEqual(near?.stars, 0)
        XCTAssertNil(near?.nextMilestone)
        XCTAssertEqual(badge(.runningOnEmpty, in: badges)?.shown, 1)   // 4.6 prints 5%
        XCTAssertEqual(badge(.redline, in: badges)?.shown, 2)
        XCTAssertEqual(badge(.bigDays, in: badges)?.count, 2)
    }

    func testAFullWeekCountsOnceAndAGapBreaksIt() {
        // 16 green days in a row then a gap, then 7 more: weeks complete on days 7 and 14 of the first
        // run and day 7 of the second.
        let first = keys(from: "2026-05-01", count: 16)
        let second = keys(from: "2026-05-20", count: 7)
        let days = (first + second).map { PulseAchievements.Day(day: $0, recovery: 80) }
        let streak = badge(.greenStreak, in: PulseAchievements.evaluate(days: days, activities: []))
        XCTAssertEqual(streak?.shown, 3)
        XCTAssertEqual(streak?.unlockedDay, "2026-05-26")
        XCTAssertEqual(PulseAchievements.weekCompletions(first), ["2026-05-07", "2026-05-14"])
    }

    func testOnTargetNeedsTheStrainInsideThatDaysRange() {
        let days = [PulseAchievements.Day(day: "2026-06-01", strain: 15, optimalStrain: 14...18),
                    PulseAchievements.Day(day: "2026-06-02", strain: 9, optimalStrain: 10...14),
                    PulseAchievements.Day(day: "2026-06-03", strain: 12, optimalStrain: nil)]
        XCTAssertEqual(badge(.onTarget, in: PulseAchievements.evaluate(days: days, activities: []))?.count, 1)
    }

    func testDuplicateDaysCountOnce() {
        let days = [PulseAchievements.Day(day: "2026-06-01", recovery: 90),
                    PulseAchievements.Day(day: "2026-06-01", recovery: 90)]
        XCTAssertEqual(badge(.greenLight, in: PulseAchievements.evaluate(days: days, activities: []))?.count, 1)
    }

    func testYoungerSelfCountsWholeYears() {
        let gap = PulseAchievements.AgeGap(yearsYounger: 4.6, day: "2026-09-01")
        let younger = badge(.youngerSelf, in: PulseAchievements.evaluate(days: [], activities: [], ageGap: gap))
        XCTAssertEqual(younger?.shown, 4)
        XCTAssertEqual(younger?.nextMilestone, 5)
        XCTAssertEqual(younger?.unlockedDay, "2026-09-01")
        let older = PulseAchievements.AgeGap(yearsYounger: -2, day: "2026-09-01")
        XCTAssertEqual(badge(.youngerSelf, in: PulseAchievements.evaluate(days: [], activities: [], ageGap: older))?.shown, 0)
    }

    func testActivityBadgesGroupBySportMostLoggedFirst() {
        let runs = keys(from: "2026-04-01", count: 12).map { PulseAchievements.Activity(day: $0, sport: "Running") }
        let rides = keys(from: "2026-04-01", count: 3).map { PulseAchievements.Activity(day: $0, sport: "cycling") }
        let other = [PulseAchievements.Activity(day: "2026-04-02", sport: "running"),
                     PulseAchievements.Activity(day: "2026-04-03", sport: "detected"),
                     PulseAchievements.Activity(day: "2026-04-03", sport: "  ")]
        let badges = PulseAchievements.evaluate(days: [], activities: runs + rides + other)
            .filter { $0.family == .activities }
        XCTAssertEqual(badges.map(\.id), ["activity.running", "activity.cycling"])
        XCTAssertEqual(badges.first?.count, 13)
        XCTAssertEqual(badges.first?.shown, 10)
        XCTAssertEqual(badges.first?.sport, "Running")
        XCTAssertEqual(badges.last?.shown, 1)
        XCTAssertEqual(badges.last?.nextMilestone, 5)
    }

    func testEveryRuleIsListedEvenWhenLocked() {
        let badges = PulseAchievements.evaluate(days: [], activities: [])
        XCTAssertEqual(badges.compactMap(\.rule), PulseAchievements.Rule.allCases)
        XCTAssertTrue(badges.allSatisfy { !$0.isUnlocked })
    }

    // MARK: Unlocks

    func testAFirstLookAnnouncesNothing() {
        let days = keys(from: "2026-06-01", count: 5).map { PulseAchievements.Day(day: $0, recovery: 90) }
        let badges = PulseAchievements.evaluate(days: days, activities: [])
        XCTAssertTrue(PulseAchievements.newUnlocks(badges, acknowledged: nil).isEmpty)
    }

    func testNewMilestonesAndFirstEventsAreAnnounced() {
        let before = keys(from: "2026-06-01", count: 4).map { PulseAchievements.Day(day: $0, recovery: 90) }
        let seen = PulseAchievements.acknowledging(PulseAchievements.evaluate(days: before, activities: []))
        // One more green day reaches the 5 milestone; a 99% day is the first near-perfect one.
        let after = before + [PulseAchievements.Day(day: "2026-06-05", recovery: 99.4)]
        let fresh = PulseAchievements.newUnlocks(PulseAchievements.evaluate(days: after, activities: []),
                                                 acknowledged: seen)
        XCTAssertEqual(Set(fresh.map(\.id)), [PulseAchievements.Rule.greenLight.rawValue,
                                             PulseAchievements.Rule.nearPerfect.rawValue])
    }

    func testARepeatEventIsNotAnnouncedAgain() {
        let one = [PulseAchievements.Day(day: "2026-06-01", recovery: 99.4)]
        let seen = PulseAchievements.acknowledging(PulseAchievements.evaluate(days: one, activities: []))
        let two = one + [PulseAchievements.Day(day: "2026-06-02", recovery: 99.6)]
        let fresh = PulseAchievements.newUnlocks(PulseAchievements.evaluate(days: two, activities: []),
                                                 acknowledged: seen)
        XCTAssertFalse(fresh.contains { $0.id == PulseAchievements.Rule.nearPerfect.rawValue })
    }

    func testASportFirstLoggedAfterTheBaselineIsAnnounced() {
        let seen = PulseAchievements.acknowledging(PulseAchievements.evaluate(days: [], activities: []))
        let fresh = PulseAchievements.newUnlocks(
            PulseAchievements.evaluate(days: [], activities: [.init(day: "2026-06-01", sport: "Yoga")]),
            acknowledged: seen)
        XCTAssertEqual(fresh.map(\.id), ["activity.yoga"])
    }
}
