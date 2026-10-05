import XCTest

/// End-to-end navigation through ZENO's Pulse shell, following the spec's target navigation map
/// (WHOOP_UI_SPEC §1.8). Every step is a real tap; each test starts from a fresh launch on the demo store.
final class NavigationFlowTests: FlowTestCase {

    func testTabCapsuleReachesEveryTabRoot() {
        launch()
        expectText("Sleep, "); expectText("Recovery, "); expectText("Strain, ")
        expectText("My Day")
        app.buttons["Health"].tap(); sleep(3)
        expectText("ZENO Age"); expectText("Pace of Aging"); expectText("Health Monitor"); expectText("Stress Monitor")
        shot("nav-tab-health")
        app.buttons["Trends"].tap(); sleep(3)
        expectText("This week"); expectText("Sleep Performance")
        shot("nav-tab-trends")
        app.buttons["More"].tap(); sleep(3)
        expectText("Profile"); expectText("Device settings"); expectText("App settings")
        shot("nav-tab-more")
        app.buttons["Home"].tap(); sleep(2)
        expectText("My Day")
    }

    func testHomeHeader() {
        launch()
        tap("Profile"); expectText("Tracking since"); expectText("Achievements"); shot("nav-profile")
        back(); expectText("My Day")
        tap("Day streak"); expectText("Day Streak"); shot("nav-day-streak")
        back(); expectText("My Day")
        tap("Strap "); expectContains("strap", timeout: 8); shot("nav-device-settings")
        back()
        tap("Previous"); sleep(2)
        XCTAssertFalse(app.buttons["Today"].exists && app.buttons["Today"].isHittable, "the day pager did not move back")
        shot("nav-previous-day")
    }

    func testDialsOpenTheirDeepDives() {
        launch()
        tap("Sleep, "); expectText("Sleep performance"); expectText("Hours vs. needed"); shot("nav-sleep-dive")
        back(); expectText("My Day")
        tap("Recovery, "); expectText("Heart rate variability"); expectText("Resting heart rate"); shot("nav-recovery-dive")
        back(); expectText("My Day")
        tap("Strain, "); expectText("Heart rate zones 1"); shot("nav-strain-dive")
        back(); expectText("My Day")
    }

    func testMonitorsAndMyDay() {
        launch()
        tap("Health Monitor"); expectText("Heart rate"); expectText("Respiratory rate"); shot("nav-health-monitor")
        back()
        tap("Stress Monitor"); expectText("Stress"); shot("nav-stress-monitor")
        back()
        if tryTap("Your Day") || tryTap("Your Daily") { shot("nav-outlook"); back() }
        tap("Today's Activities"); expectText("Heart rate"); shot("nav-day-timeline")
        back()
        tap("Tonight's Sleep"); expectContains("bedtime"); shot("nav-sleep-planner")
        back()
        tap("My Journal"); expectText("What's happening"); shot("nav-journal")
        back()
        tap("Behavior insights"); expectText("Recovery Impact Analysis"); shot("nav-behavior-insights")
        back()
        tap("Customize"); expectText("Add to my dashboard"); shot("nav-customize")
        back()
        tap("Heart rate variability"); expectText("Heart Rate Variability"); expectText("Average"); shot("nav-trend-hrv")
        back()
    }

    func testActionMenu() {
        launch()
        tap("Start or add an activity"); sleep(1)
        for row in ["Start activity", "Add activity", "Strength trainer", "Complete your journal", "Breathe", "Mark moment"] {
            expectText(row, timeout: 4, "action menu row")
        }
        shot("nav-action-menu")
        tap("Start activity"); expectText("Start activity", timeout: 6); shot("nav-start-activity")
        back()
        launch()
        tap("Start or add an activity"); tap("Add activity"); expectText("Select activity"); shot("nav-add-activity")
        back()
        launch()
        tap("Start or add an activity"); tap("Strength trainer"); expectContains("workout"); shot("nav-strength-trainer")
    }

    func testCoachButtonOpensTheCoach() {
        launch()
        app.buttons["Coach"].tap(); sleep(3)
        expectContains("Coach"); shot("nav-coach")
    }

    func testHealthTab() {
        launch()
        app.buttons["Health"].tap(); sleep(3)
        tap("Go to Healthspan"); expectText("Healthspan", timeout: 8); shot("nav-healthspan")
        back()
        tap("Health Monitor"); expectText("Respiratory rate"); back()
        tap("Stress Monitor"); expectText("Stress"); back()
        tap("Lab Book"); shot("nav-lab-book"); back()
        tap("Steps"); expectText("Steps"); shot("nav-steps"); back()
    }

    func testTrendsTab() {
        launch()
        app.buttons["Trends"].tap(); sleep(3)
        tap("This week"); expectContains("week"); shot("nav-weekly-digest"); back()
        tap("Resting Heart Rate"); expectText("Resting Heart Rate"); expectText("Average"); shot("nav-trend-rhr"); back()
        tap("Training load"); shot("nav-training-load"); back()
        tap("Explore"); shot("nav-explore"); back()
    }

    func testMoreTab() {
        launch()
        app.buttons["More"].tap(); sleep(3)
        tap("Profile"); expectText("Tracking since"); back()
        tap("Device settings"); expectContains("strap"); back()
        tap("App settings"); shot("nav-app-settings"); back()
        tap("Privacy & data"); shot("nav-privacy"); back()
        tap("Lift log"); expectContains("workout"); shot("nav-more-strength"); back()
        tap("Breathe"); shot("nav-breathe"); back()
        tap("Report a problem"); shot("nav-report-problem"); back()
        tap("First week with ZENO"); shot("nav-first-week"); back()
    }
}

/// One fact, one value: the same metric must read the same on every screen that shows it (AGENTS.md
/// "two readouts of one fact must not be able to disagree").
final class ConsistencyFlowTests: FlowTestCase {

    func testRecoverySleepAndStrainAgreeAcrossScreens() {
        launch()
        let recovery = number(in: label("Recovery, ", .button))
        let sleepPct = number(in: label("Sleep, ", .button))
        let strain = number(in: label("Strain, ", .button))
        XCTAssertNotNil(recovery); XCTAssertNotNil(sleepPct); XCTAssertNotNil(strain)

        tap("Recovery, ")
        XCTAssertNotNil(label("Recovery, \(recovery ?? "?")") ?? label("\(recovery ?? "?")"), "Recovery dive differs from Home's dial")
        back()
        tap("Sleep, ")
        XCTAssertEqual(number(in: label("Sleep performance, ")), sleepPct, "Sleep dive differs from Home's dial")
        back()
        tap("Strain, ")
        XCTAssertTrue(query(strain ?? "?", .staticText).firstMatch.exists, "Strain dive differs from Home's dial (\(strain ?? "?"))")
        back()

        app.buttons["Trends"].tap(); sleep(3)
        XCTAssertEqual(number(in: label("Sleep Performance, ", .button)), sleepPct, "Trends' Sleep Performance differs from Home")
        XCTAssertEqual(number(in: label("Day Strain, ", .button)), strain, "Trends' Day Strain differs from Home")
    }

    /// The first one-decimal stress figure ("1.9") inside `container`.
    func stressFigure(in container: XCUIElement) -> String? {
        let fig = container.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]\\.[0-9]$")).firstMatch
        return fig.exists ? fig.label : nil
    }

    func testStressReadsTheSameEverywhere() {
        launch()
        let tile = query("Stress Monitor", .button).firstMatch
        let home = tile.exists ? stressFigure(in: tile) : nil
        tile.tap(); sleep(3)
        let monitor = stressFigure(in: app)
        shot("consistency-stress-monitor")
        XCTAssertEqual(home, monitor, "Home's stress tile differs from the Stress Monitor")
        back()
        app.buttons["Trends"].tap(); sleep(3)
        XCTAssertEqual(number(in: label("Day Stress, ", .button)), monitor, "Trends' Day Stress differs from the Stress Monitor")
        app.buttons["Health"].tap(); sleep(3)
        if let card = element("Stress Monitor") {
            XCTAssertEqual(stressFigure(in: card), monitor, "the Health tab's stress card differs from the Stress Monitor")
        }
    }

    func testHRVAndRestingHRAgree() {
        launch()
        tap("Recovery, ")
        let hrv = number(in: label("Heart rate variability, ", .button))
        let rhr = number(in: label("Resting heart rate, ", .button))
        shot("consistency-recovery")
        back()
        app.buttons["Trends"].tap(); sleep(3)
        XCTAssertEqual(number(in: label("Resting Heart Rate, ", .button)), rhr, "Trends' RHR differs from the Recovery dive")
        app.buttons["Health"].tap(); sleep(3)
        tap("Health Monitor")
        let monitor = app.debugDescription
        if let hrv { XCTAssertTrue(monitor.contains("'\(hrv)'"), "Health Monitor's HRV differs from the Recovery dive (\(hrv))") }
        if let rhr { XCTAssertTrue(monitor.contains("'\(rhr)'"), "Health Monitor's RHR differs from the Recovery dive (\(rhr))") }
    }

    /// The first clock time ("8:42") in `text`.
    func clock(in text: String?) -> String? {
        guard let text, let r = text.range(of: "[0-9]{1,2}:[0-9]{2}", options: .regularExpression) else { return nil }
        return String(text[r])
    }

    func testTonightsSleepMatchesThePlanner() {
        launch()
        guard let card = element("Tonight's Sleep") else { return }
        let bed = clock(in: card.otherElements.matching(NSPredicate(format: "label BEGINSWITH 'Recommended bedtime'")).firstMatch.label)
        let wake = clock(in: card.otherElements.matching(NSPredicate(format: "label BEGINSWITH 'Wake'")).firstMatch.label)
        card.tap(); sleep(3)
        shot("consistency-planner")
        let plannerBed = clock(in: label("Suggested time to bed", .other))
        let plannerWake = clock(in: label("Usual wake", .other) ?? label("Your wake time", .other) ?? label("Wake time", .other)
                                  ?? label("Alarm set to", .other))
        XCTAssertNotNil(bed, "Home's Tonight's Sleep card shows no bedtime")
        XCTAssertEqual(bed, plannerBed, "Home's recommended bedtime differs from the Sleep Planner's")
        XCTAssertEqual(wake, plannerWake, "Home's wake time differs from the Sleep Planner's")
    }
}
