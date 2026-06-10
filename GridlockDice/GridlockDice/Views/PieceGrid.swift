import SwiftUI

struct PieceGrid: View {
    let shape: Shape
    let color: PieceColorName
    let cellSize: CGFloat
    let gap: CGFloat

    private var col: PieceColor { color.style }

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<shape.count, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<shape[r].count, id: \.self) { c in
                        if shape[r][c] {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(col.fill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .strokeBorder(col.border, lineWidth: 0.5)
                                )
                                .shadow(color: col.shadow, radius: 0, x: 0, y: 2)
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}
