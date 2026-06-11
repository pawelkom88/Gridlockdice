import SwiftUI

struct BoardCellView: View {

    @Environment(GameViewModel.self) private var vm
    let row: Int
    let col: Int
    let cellSize: CGFloat

    private var state: CellState { vm.board[row, col] }
    private var isHovered: Bool { vm.hoverCells.contains("\(row),\(col)") }
    private var isHinted: Bool { vm.hintCells.contains("\(row),\(col)") }
    private var isShaking: Bool {
        if case .filled(let pid, _) = state { return vm.shakingPieceID == pid }
        return false
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(8, cellSize * 0.14), style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, cellSize * 0.14), style: .continuous)
                        .strokeBorder(border, lineWidth: isHovered ? 1.5 : 0.5)
                )
                .shadow(color: shadowColor, radius: 0, x: 0, y: shadowY)


        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            isHinted
                ? RoundedRectangle(cornerRadius: max(8, cellSize * 0.14), style: .continuous)
                    .stroke(Color.accentYellow.opacity(0.6), lineWidth: 2)
                    .frame(width: cellSize, height: cellSize)
                    .opacity(vm.showingHint ? 1 : 0)
                : nil
        )
        .accessibilityLabel(cellAccessibilityLabel)
        .onTapGesture {
            if case .filled(let pid, _) = state {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    vm.removePiece(id: pid)
                }
            }
        }
        .offset(x: isShaking ? 6 : 0)
        .animation(isShaking ? .easeInOut(duration: 0.06).repeatCount(4, autoreverses: true) : .default, value: isShaking)
    }

    private var background: Color {
        switch state {
        case .empty:
            if isHinted { return Color.accentYellow.opacity(0.18) }
            if isHovered { return vm.hoverIsValid ? Color.accentGreen.opacity(0.14) : Color.accentRed.opacity(0.12) }
            return Color.bg2
        case .dice:
            return Color(hex: "#F7F2EC")
        case .filled(_, let color):
            return color.style.fill
        }
    }

    private var border: Color {
        switch state {
        case .empty:
            if isHinted { return Color.accentYellow.opacity(0.8) }
            if isHovered { return vm.hoverIsValid ? Color.accentGreen.opacity(0.75) : Color.accentRed.opacity(0.65) }
            return Color.sep
        case .dice:
            return Color.clear
        case .filled(_, let color):
            return color.style.border
        }
    }

    private var shadowColor: Color {
        switch state {
        case .empty: return .clear
        case .dice:  return Color.black.opacity(0.45)
        case .filled(_, let color): return color.style.shadow
        }
    }

    private var shadowY: CGFloat {
        switch state {
        case .empty: return 0
        default:     return 3
        }
    }

    private var cellAccessibilityLabel: String {
        switch state {
        case .empty:
            return Accessibility.emptyCellLabel(row: row, col: col)
        case .dice:
            return Accessibility.diceLabel(row: row, col: col)
        case .filled(let pid, let color):
            return Accessibility.filledCellLabel(pieceID: pid, color: color)
        }
    }
}
