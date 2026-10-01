import SwiftUI

struct TrayPieceView: View {

    @Environment(GameViewModel.self) private var vm
    let piece: TrayPiece
    let cellSize: CGFloat
    let thumbnailSize: CGFloat

    init(piece: TrayPiece, cellSize: CGFloat, thumbnailSize: CGFloat = 20) {
        self.piece = piece
        self.cellSize = cellSize
        self.thumbnailSize = thumbnailSize
    }

    private let GAP: CGFloat = 3

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var isRotating: Bool { vm.rotatingPieceID == piece.id }
    private var isShaking: Bool  { vm.shakingPieceID == piece.id }
    private var isDragging: Bool { vm.dragState?.piece.id == piece.id }

    var body: some View {
        PieceGrid(shape: piece.shape, color: piece.color, cellSize: thumbnailSize, gap: GAP)
            .padding(7)
            .frame(minWidth: isPad ? 64 : 48, minHeight: isPad ? 64 : 48)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.sep, lineWidth: 0.5)
            )
            .shadow(color: isDragging ? Color.accentBlue.opacity(0.45) : Color.black.opacity(0.3), radius: isDragging ? 10 : 4, y: isDragging ? 4 : 2)
            .scaleEffect(isDragging ? 1.08 : 1.0)
            .rotationEffect(isRotating ? .degrees(90) : .zero)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRotating)
            .offset(x: isShaking ? 6 : 0)
            .animation(
                isShaking ? .easeInOut(duration: 0.06).repeatCount(4, autoreverses: true) : .default,
                value: isShaking
            )
            .overlay(alignment: .topTrailing) {
                if vm.level.allowsRotation {
                    ZStack {
                        Circle().fill(Color.bg3).frame(width: 16, height: 16)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.label4)
                    }
                    .offset(x: 5, y: -5)
                }
            }
            .accessibilityLabel(Accessibility.trayPieceLabel(piece: piece, allowsRotation: vm.level.allowsRotation))
            .accessibilityAction(named: "Rotate") {
                vm.rotatePiece(id: piece.id)
            }
            .highPriorityGesture(TapGesture().onEnded {
                vm.rotatePiece(id: piece.id)
            })
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onChanged { value in
                        if vm.dragState == nil || vm.dragState?.piece.id != piece.id {
                            // Only initiate dragging if the movement is primarily vertical
                            guard abs(value.translation.height) > abs(value.translation.width) else { return }
                            vm.dragState = DragState(piece: piece, location: value.location)
                        }
                        vm.updateHover(globalLocation: value.location, cellSize: cellSize)
                    }
                    .onEnded { _ in
                        vm.endDrag()
                    }
            )
    }
}
