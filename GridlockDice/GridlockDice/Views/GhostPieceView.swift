import SwiftUI

struct GhostPieceView: View {
    let def: PieceDef
    let onTap: () -> Void
    let cellSize: CGFloat

    init(def: PieceDef, cellSize: CGFloat = 20, onTap: @escaping () -> Void) {
        self.def = def
        self.cellSize = cellSize
        self.onTap = onTap
    }

    var body: some View {
        PieceGrid(shape: def.shape, color: def.color, cellSize: cellSize, gap: 3)
            .padding(7)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
            )
            .opacity(0.28)
            .onTapGesture(perform: onTap)
    }
}
