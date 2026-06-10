import XCTest
@testable import GridlockDice

final class AccessibilityTests: XCTestCase {

    // MARK: - Dice cell label

    func testDiceCellAccessibilityLabelIncludesCoordinate() {
        let label = Accessibility.diceLabel(row: 1, col: 2)
        XCTAssertTrue(label.contains("B"))
        XCTAssertTrue(label.contains("2") || label.contains("3"))
        XCTAssertTrue(label.lowercased().contains("dice") || label.lowercased().contains("fixed"))
    }

    // MARK: - Empty cell label

    func testEmptyCellAccessibilityLabelIncludesRowAndColumn() {
        let label = Accessibility.emptyCellLabel(row: 3, col: 0)
        XCTAssertTrue(label.contains("D") || label.contains("4"), "Should include row reference")
        XCTAssertTrue(label.contains("0") || label.contains("1"), "Should include column reference")
    }

    // MARK: - Tray piece label

    func testTrayPieceAccessibilityMentionsRotationWhenAvailable() {
        let def = PieceDef(id: "p1", color: .red, rows: [[1, 1]])
        let level = LevelDef(id: 25, name: "Test", subtitle: "", rows: 4, cols: 4, dice: [], pieces: [def])
        let piece = TrayPiece(from: def)
        let label = Accessibility.trayPieceLabel(piece: piece, allowsRotation: level.allowsRotation)
        XCTAssertTrue(label.lowercased().contains("red"))
        XCTAssertTrue(label.lowercased().contains("rotate") || label.lowercased().contains("rotation"))
    }

    func testTrayPieceAccessibilityOmitsRotationWhenLocked() {
        let def = PieceDef(id: "p1", color: .blue, rows: [[1]])
        let level = LevelDef(id: 1, name: "Test", subtitle: "", rows: 4, cols: 4, dice: [], pieces: [def])
        let piece = TrayPiece(from: def)
        let label = Accessibility.trayPieceLabel(piece: piece, allowsRotation: level.allowsRotation)
        XCTAssertTrue(label.lowercased().contains("blue"))
        XCTAssertFalse(label.lowercased().contains("rotate"))
    }

    // MARK: - Locked level label

    func testLockedLevelAccessibilityLabelMentionsLocked() {
        let def = LevelCatalogue.all.first(where: { $0.id == 16 })!
        let label = Accessibility.lockedLevelLabel(level: def, isUnlocked: false)
        XCTAssertTrue(label.lowercased().contains("lock"))
        XCTAssertTrue(label.lowercased().contains("16") || label.contains("pay"))
    }

    // MARK: - Reduced motion

    func testReducedMotionWrapperDisablesAnimations() {
        let policy = ReducedMotionPolicy(isReduceMotionEnabled: true)
        XCTAssertTrue(policy.shouldSimplifyAnimations)
        XCTAssertEqual(policy.springResponse, 0.0)
        XCTAssertEqual(policy.springDamping, 1.0)
        XCTAssertEqual(policy.removalAnimationDuration, 0.0)
    }

    func testStandardMotionKeepsAnimationsEnabled() {
        let policy = ReducedMotionPolicy(isReduceMotionEnabled: false)
        XCTAssertFalse(policy.shouldSimplifyAnimations)
        XCTAssertGreaterThan(policy.springResponse, 0.0)
        XCTAssertGreaterThan(policy.springDamping, 0.0)
    }
}

// MARK: - Accessibility label helpers

enum Accessibility {
    static func diceLabel(row: Int, col: Int) -> String {
        let rows = Array("ABCDEFGHIJ")
        let letter = row < rows.count ? String(rows[row]) : "\(row + 1)"
        return "Fixed dice, \(letter)\(col + 1)"
    }

    static func emptyCellLabel(row: Int, col: Int) -> String {
        let rows = Array("ABCDEFGHIJ")
        let letter = row < rows.count ? String(rows[row]) : "\(row + 1)"
        return "Empty cell \(letter)\(col + 1)"
    }

    static func trayPieceLabel(piece: TrayPiece, allowsRotation: Bool) -> String {
        let colorName = String(describing: piece.color)
        var label = "\(colorName) piece, \(piece.shape.width)×\(piece.shape.height)"
        if allowsRotation {
            label += ", tap to rotate"
        }
        return label
    }

    static func lockedLevelLabel(level: LevelDef, isUnlocked: Bool) -> String {
        if !level.isFree && !isUnlocked {
            return "Level \(level.id), locked. Purchase to unlock."
        }
        return "Level \(level.id), \(level.name)"
    }
}

// MARK: - Reduced motion policy

struct ReducedMotionPolicy {
    let shouldSimplifyAnimations: Bool

    var springResponse: Double { shouldSimplifyAnimations ? 0.0 : 0.3 }
    var springDamping: Double { shouldSimplifyAnimations ? 1.0 : 0.85 }
    var removalAnimationDuration: Double { shouldSimplifyAnimations ? 0.0 : 0.25 }

    init(isReduceMotionEnabled: Bool) {
        self.shouldSimplifyAnimations = isReduceMotionEnabled
    }
}
