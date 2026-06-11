import UIKit

enum Haptics {
    static func piecePlaced() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func invalidDrop() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func levelSolved() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func hintShown() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}
