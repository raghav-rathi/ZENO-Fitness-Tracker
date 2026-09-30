import XCTest
@testable import StrandDesign

/// Pins the on-accent ink pick: primary-button labels used to be hard-coded white, which measured 1.66:1
/// on the default dark-mode mint. The pick must land on whichever of white / near-black contrasts more.
final class OnAccentContrastTests: XCTestCase {

    func testMintAccentsTakeDarkInk() {
        XCTAssertEqual(AccentColor.inkOn("#69DDB8"), AccentColor.inkHex)   // dark-mode mint
        XCTAssertEqual(AccentColor.inkOn("#149A78"), AccentColor.inkHex)   // light-mode mint
    }

    func testDeepBlueTakesWhiteButBrightBlueTakesInk() {
        XCTAssertEqual(AccentColor.inkOn("#234F9E"), "#FFFFFF")            // light-mode WHOOP blue
        XCTAssertEqual(AccentColor.inkOn("#60A0E0"), AccentColor.inkHex)   // dark-mode WHOOP blue
    }

    func testExtremes() {
        XCTAssertEqual(AccentColor.inkOn("#000000"), "#FFFFFF")
        XCTAssertEqual(AccentColor.inkOn("#FFFFFF"), AccentColor.inkHex)
    }

    func testRelativeLuminanceMatchesWCAGReferencePoints() {
        XCTAssertEqual(AccentColor.relativeLuminance("#FFFFFF"), 1.0, accuracy: 1e-9)
        XCTAssertEqual(AccentColor.relativeLuminance("#000000"), 0.0, accuracy: 1e-9)
        // Mid grey #777777 is the classic 4.48:1-on-white reference: L ≈ 0.1845.
        XCTAssertEqual(AccentColor.relativeLuminance("#777777"), 0.1845, accuracy: 0.001)
    }

    func testChosenInkMeetsTextContrastOnTheDefaultAccents() {
        for hex in ["#69DDB8", "#149A78", "#234F9E", "#60A0E0"] {
            let ink = AccentColor.inkOn(hex)
            let a = AccentColor.relativeLuminance(hex), b = AccentColor.relativeLuminance(ink)
            let ratio = (max(a, b) + 0.05) / (min(a, b) + 0.05)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(ink) on \(hex) is only \(ratio):1")
        }
    }
}
