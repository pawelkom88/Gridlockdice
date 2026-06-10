import SwiftUI
import UIKit

enum Accessibility {

    private static let rows = Array("ABCDEFGHIJ")

    static func diceLabel(row: Int, col: Int) -> String {
        let letter = row < rows.count ? String(rows[row]) : "\(row + 1)"
        return "Fixed dice, \(letter)\(col + 1)"
    }

    static func emptyCellLabel(row: Int, col: Int) -> String {
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

    static func lockedLevelLabel(level: LevelDef) -> String {
        "Level \(level.id), locked. Purchase to unlock."
    }

    static func availableLevelLabel(level: LevelDef) -> String {
        "Level \(level.id), \(level.name)"
    }

    static func filledCellLabel(pieceID: String, color: PieceColorName) -> String {
        "Filled cell, \(String(describing: color)) piece"
    }
}

struct ReducedMotionPolicy {
    let shouldSimplifyAnimations: Bool

    var springResponse: Double { shouldSimplifyAnimations ? 0.0 : 0.3 }
    var springDamping: Double { shouldSimplifyAnimations ? 1.0 : 0.85 }
    var removalDuration: Double { shouldSimplifyAnimations ? 0.0 : 0.25 }
    var dragResponse: Double { shouldSimplifyAnimations ? 0.0 : 0.38 }

    init() {
        self.shouldSimplifyAnimations = UIAccessibility.isReduceMotionEnabled
    }

    init(isReduceMotionEnabled: Bool) {
        self.shouldSimplifyAnimations = isReduceMotionEnabled
    }
}
