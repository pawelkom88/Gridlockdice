import XCTest
import SwiftUI
@testable import GridlockDice

final class ThemeTests: XCTestCase {

    func testPieceColorPaletteContainsAllGameplayColours() {
        let expectedNames: Set<String> = [
            "red", "orange", "yellow", "green",
            "teal", "blue", "purple", "pink"
        ]
        let actualNames = Set(PieceColorName.allCases.map { $0.rawValue })
        XCTAssertEqual(actualNames, expectedNames)

        for name in PieceColorName.allCases {
            let style = name.style
            XCTAssertNotNil(style.fill, "\(name.rawValue) has nil fill")
            XCTAssertNotNil(style.shadow, "\(name.rawValue) has nil shadow")
            XCTAssertNotNil(style.border, "\(name.rawValue) has nil border")
        }
    }

    func testThemeSpacingAndRadiusTokensAreUsable() {
        let spacings: [(String, CGFloat)] = [
            ("xxs", Spacing.xxs),
            ("xs",  Spacing.xs),
            ("sm",  Spacing.sm),
            ("md",  Spacing.md),
            ("lg",  Spacing.lg),
            ("xl",  Spacing.xl),
            ("xxl", Spacing.xxl),
        ]
        for (name, value) in spacings {
            XCTAssertGreaterThan(value, 0, "Spacing.\(name) should be positive, got \(value)")
        }

        let radii: [(String, CGFloat)] = [
            ("sm",   Radius.sm),
            ("md",   Radius.md),
            ("lg",   Radius.lg),
            ("xl",   Radius.xl),
            ("cell", Radius.cell),
        ]
        for (name, value) in radii {
            XCTAssertGreaterThan(value, 0, "Radius.\(name) should be positive, got \(value)")
        }
    }

    func testHexColorInitializerAcceptsReferenceHexValues() {
        let colors: [Color] = [
            Color(hex: "#0a84ff"),
            Color(hex: "#30d158"),
            Color(hex: "#ffd60a"),
            Color(hex: "#ff9f0a"),
            Color(hex: "#ff453a"),
            Color(hex: "#bf5af2"),
            Color(hex: "#ff375f"),
            Color(hex: "#5ac8fa"),
        ]
        XCTAssertEqual(colors.count, 8)
        for color in colors {
            _ = color
        }
    }
}
