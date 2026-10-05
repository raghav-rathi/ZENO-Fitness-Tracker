import XCTest

/// Shared helpers for ZENO's end-to-end flow tests.
///
/// The tests drive the installed ZENO Debug build (its bundle id comes from ZENO_BUNDLE_ID, which run.sh reads
/// from the app it installs) with real synthesized touches. Every test launches on the deterministic demo
/// store (`--demo-seed`), so the values on screen are known and the same on every screen that shows them.
class FlowTestCase: XCTestCase {
    let out = ProcessInfo.processInfo.environment["FLOW_OUT"] ?? "/tmp"
    let bundleId = ProcessInfo.processInfo.environment["ZENO_BUNDLE_ID"] ?? "com.raghav.noop.noop"
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
    }

    /// Launches ZENO on the demo store and waits for the tab capsule.
    @discardableResult
    func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: bundleId)
        app.launchArguments = ["--demo-seed"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 45), "the tab capsule never appeared")
        sleep(2)
        self.app = app
        return app
    }

    func shot(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
        try? app.debugDescription.write(toFile: "\(out)/\(name).txt", atomically: true, encoding: .utf8)
    }

    func query(_ prefix: String, _ type: XCUIElement.ElementType) -> XCUIElementQuery {
        app.descendants(matching: type).matching(NSPredicate(format: "label BEGINSWITH[c] %@", prefix))
    }

    /// Whether `el` is on screen and clear of the floating tab capsule. XCUITest calls an element under the
    /// capsule hittable, but a tap there lands on the capsule.
    func clear(_ el: XCUIElement) -> Bool {
        guard el.exists, el.isHittable else { return false }
        let capsule = app.buttons["Home"]
        let bottom = capsule.exists && capsule.isHittable ? capsule.frame.minY - 6 : app.frame.maxY
        return el.frame.midY < bottom && el.frame.minY > 50
    }

    /// Scrolls the page by about `points` (positive moves the content up), for an element just off a clear spot.
    func nudge(_ points: CGFloat) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -points)))
        sleep(1)
    }

    /// The first element of `type` whose label starts with `prefix`, scrolled clear of the tab capsule: the
    /// page scrolls up (and then back down) to find it, and nudges it out from under the capsule.
    func element(_ prefix: String, _ type: XCUIElement.ElementType = .button, swipes: Int = 10,
                 file: StaticString = #filePath, line: UInt = #line) -> XCUIElement? {
        let q = query(prefix, type)
        for _ in 0..<swipes {
            let el = q.firstMatch
            if clear(el) { return el }
            if el.exists && el.isHittable { nudge(160) } else { app.swipeUp(velocity: .slow) }
        }
        for _ in 0..<swipes {
            let el = q.firstMatch
            if clear(el) { return el }
            if el.exists && el.isHittable { nudge(-160) } else { app.swipeDown(velocity: .slow) }
        }
        let el = q.firstMatch
        if el.exists { return el }
        XCTFail("no \(type) labelled '\(prefix)…' found", file: file, line: line)
        return nil
    }

    /// Taps the element labelled `prefix…`; returns false when it isn't there.
    @discardableResult
    func tap(_ prefix: String, _ type: XCUIElement.ElementType = .button,
             file: StaticString = #filePath, line: UInt = #line) -> Bool {
        guard let el = element(prefix, type, file: file, line: line) else { return false }
        el.tap()
        sleep(2)
        return true
    }

    /// Asserts some text (any element type) starting with `prefix` appears within `timeout`.
    func expectText(_ prefix: String, timeout: TimeInterval = 8, _ message: String = "",
                    file: StaticString = #filePath, line: UInt = #line) {
        let q = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH[c] %@", prefix))
        XCTAssertTrue(q.firstMatch.waitForExistence(timeout: timeout),
                      "expected '\(prefix)…' on screen. \(message)", file: file, line: line)
    }

    /// Asserts any element's label contains `fragment`.
    func expectContains(_ fragment: String, timeout: TimeInterval = 8, _ message: String = "",
                        file: StaticString = #filePath, line: UInt = #line) {
        let q = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", fragment))
        XCTAssertTrue(q.firstMatch.waitForExistence(timeout: timeout),
                      "expected a label containing '\(fragment)'. \(message)", file: file, line: line)
    }

    /// Goes back one level: a back chevron if the page was pushed, a system navigation bar's back button
    /// (classic screens), else a close button, else a downward swipe for a sheet.
    func back(file: StaticString = #filePath, line: UInt = #line) {
        for label in ["Back", "Close", "Done"] {
            let b = app.buttons[label]
            if b.exists && b.isHittable { b.tap(); sleep(2); return }
        }
        let chevron = app.buttons.matching(identifier: "chevron.left").firstMatch
        if chevron.exists && chevron.isHittable { chevron.tap(); sleep(2); return }
        let navBack = app.navigationBars.buttons.firstMatch
        if navBack.exists && navBack.isHittable { navBack.tap(); sleep(2); return }
        app.swipeDown(velocity: .fast) // dismiss a sheet
        sleep(2)
    }

    /// Taps the element labelled `prefix…` if it is there, without failing the test when it isn't.
    @discardableResult
    func tryTap(_ prefix: String, _ type: XCUIElement.ElementType = .button) -> Bool {
        let q = query(prefix, type)
        for _ in 0..<6 {
            let el = q.firstMatch
            if clear(el) { el.tap(); sleep(2); return true }
            if el.exists && el.isHittable { nudge(160) } else { app.swipeUp(velocity: .slow) }
        }
        return false
    }

    /// The label of the first element whose label starts with `prefix`, or nil.
    func label(_ prefix: String, _ type: XCUIElement.ElementType = .any) -> String? {
        let el = query(prefix, type).firstMatch
        return el.exists ? el.label : nil
    }

    func value(_ prefix: String, _ type: XCUIElement.ElementType = .any) -> String? {
        let el = query(prefix, type).firstMatch
        return el.exists ? el.value as? String : nil
    }

    /// The first number in `text` ("Recovery, 67 percent" → "67").
    func number(in text: String?) -> String? {
        guard let text else { return nil }
        let pattern = try! NSRegularExpression(pattern: "[0-9]+(\\.[0-9]+)?")
        let range = NSRange(text.startIndex..., in: text)
        guard let m = pattern.firstMatch(in: text, range: range), let r = Range(m.range, in: text) else { return nil }
        return String(text[r])
    }
}
