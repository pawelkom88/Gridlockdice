import SwiftUI

// MARK: - GameView
struct GameView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(GameViewModel.self) private var vm

    // Geometry of one board cell — computed from GeometryReader
    @State private var cellSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            progressStrip
            boardArea
            trayShelf
        }
        .background(Color.bg0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            CircleButton(systemName: "chevron.left", weight: .regular) {
                appVM.screen = .levelSelect
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(vm.level.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.label1)
                    .tracking(-0.4)
                    .lineLimit(1)
                Text(vm.level.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.label3)
            }
            Spacer()
            CircleButton(systemName: "arrow.counterclockwise") {
                vm.reset()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .frame(height: 64)
    }

    // MARK: - Progress
    private var progressStrip: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.fill2)
                        .frame(height: 4)
                    Capsule()
                        .fill(vm.progress >= 1 ? Color.accentGreen : Color.accentBlue)
                        .frame(width: geo.size.width * vm.progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.progress)
                }
            }
            .frame(height: 4)

            Text("\(vm.filledCount)/\(vm.totalPlayable)")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.label1)
                .fixedSize()
        }
        .padding(.horizontal, Spacing.xl)
        .frame(height: 32)
    }

    // MARK: - Board
    private var boardArea: some View {
        GeometryReader { geo in
            let cs = computeCellSize(in: geo.size)
            VStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                BoardGridView(cellSize: cs)
                    .environment(vm)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 4)
    }

    private func computeCellSize(in size: CGSize) -> CGFloat {
        let GAP: CGFloat  = 4
        let LBL: CGFloat  = 22
        let PAD: CGFloat  = 0   // already padded by parent
        let availW = size.width - LBL - CGFloat(vm.level.cols - 1) * GAP - PAD
        let availH = size.height - 28  // col-label row height
        let byW = floor(availW / CGFloat(vm.level.cols))
        let byH = floor((availH - CGFloat(vm.level.rows - 1) * GAP) / CGFloat(vm.level.rows))
        return min(byW, byH, 84)
    }

    // MARK: - Tray shelf
    private var trayShelf: some View {
        VStack(spacing: 0) {
            Divider().background(Color.sep)

            HStack {
                Text(vm.trayPieces.isEmpty ? "Board Complete" : "\(vm.trayPieces.count) Piece\(vm.trayPieces.count == 1 ? "" : "s") Remaining")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.label1)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if vm.trayPieces.isEmpty {
                    Text("All placed ✓")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentGreen)
                } else {
                    Label("tap to rotate", systemImage: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.label4)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Active (unplaced) pieces
                    ForEach(vm.trayPieces) { piece in
                        TrayPieceView(piece: piece)
                            .environment(vm)
                    }
                    // Ghost thumbnails for placed pieces
                    ForEach(vm.placedIDs, id: \.self) { pid in
                        if let def = vm.level.pieces.first(where: { $0.id == pid }) {
                            GhostPieceView(def: def) {
                                vm.removePiece(id: pid)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 14)
            }
        }
        .background(Color.bg1)
        .frame(height: 122)
    }
}

// MARK: - BoardGridView
// Renders the coordinate labels and all cells.
// Handles DragGesture for piece placement.
struct BoardGridView: View {

    @Environment(GameViewModel.self) private var vm
    let cellSize: CGFloat

    private let GAP: CGFloat = 4
    private let LBL: CGFloat = 22
    private let ROWS = Array("ABCDEFGHIJ")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column number labels
            HStack(spacing: GAP) {
                Spacer().frame(width: LBL)
                ForEach(0..<vm.level.cols, id: \.self) { c in
                    Text("\(c + 1)")
                        .font(AppFont.mono())
                        .foregroundStyle(Color.label1)
                        .frame(width: cellSize)
                }
            }
            .padding(.bottom, 5)

            // Rows
            VStack(spacing: GAP) {
                ForEach(0..<vm.level.rows, id: \.self) { r in
                    HStack(spacing: GAP) {
                        // Row letter label
                        Text(String(ROWS[r]))
                            .font(AppFont.mono())
                            .foregroundStyle(Color.label1)
                            .frame(width: LBL)

                        // Cells
                        ForEach(0..<vm.level.cols, id: \.self) { c in
                            BoardCellView(row: r, col: c, cellSize: cellSize)
                                .environment(vm)
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.28, dampingFraction: 0.82).delay(Double(r) * 0.03), value: vm.level.id)
                }
            }
        }
        // Drag gesture lives on the whole board — single gesture recogniser
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named("board"))
                .onChanged { val in handleDragChange(val) }
                .onEnded   { val in handleDragEnd(val)   }
        )
        .coordinateSpace(name: "board")
    }

    // MARK: - Drag helpers
    private func handleDragChange(_ val: DragGesture.Value) {
        guard let drag = vm.dragState else { return }
        let loc = val.location
        let hr = rowAt(y: loc.y), hc = colAt(x: loc.x)
        vm.hoverRow = hr
        vm.hoverCol = hc
        // update drag location
        vm.dragState = DragState(piece: drag.piece, location: loc)
    }

    private func handleDragEnd(_ val: DragGesture.Value) {
        guard let drag = vm.dragState else { return }
        if let hr = vm.hoverRow, let hc = vm.hoverCol {
            vm.tryPlace(pieceID: drag.piece.id, at: hr, col: hc)
        }
        vm.dragState = nil
        vm.hoverRow  = nil
        vm.hoverCol  = nil
    }

    private func rowAt(y: CGFloat) -> Int? {
        // Skip col-label row height (~18 + 5 padding)
        let colLabelH: CGFloat = 23
        let idx = Int(floor((y - colLabelH) / (cellSize + GAP)))
        return (0..<vm.level.rows).contains(idx) ? idx : nil
    }

    private func colAt(x: CGFloat) -> Int? {
        let idx = Int(floor((x - LBL - GAP) / (cellSize + GAP)))
        return (0..<vm.level.cols).contains(idx) ? idx : nil
    }
}

// MARK: - BoardCellView
struct BoardCellView: View {

    @Environment(GameViewModel.self) private var vm
    let row:      Int
    let col:      Int
    let cellSize: CGFloat

    private var cellState: CellState { vm.board[row, col] }
    private var key: String { "\(row),\(col)" }
    private var isHovered: Bool { vm.hoverCells.contains(key) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(8, cellSize * 0.14), style: .continuous)
                .fill(cellBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, cellSize * 0.14), style: .continuous)
                        .strokeBorder(cellBorder, lineWidth: isHovered ? 1.5 : 0.5)
                )
                .shadow(color: cellShadowColor, radius: 0, x: 0, y: cellShadowY)
                .scaleEffect(isSnapping ? 1.0 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isSnapping)

            if case .dice(let label) = cellState {
                Text(label)
                    .font(.system(size: max(9, cellSize * 0.19), weight: .bold))
                    .foregroundStyle(Color.black)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if case .filled(let pid, _) = cellState {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    vm.removePiece(id: pid)
                }
            }
        }
    }

    private var isSnapping: Bool {
        if case .filled(let pid, _) = cellState {
            return vm.snappingPieceID == pid
        }
        return false
    }

    private var cellBackground: Color {
        switch cellState {
        case .empty:
            if isHovered { return vm.hoverIsValid ? Color.accentGreen.opacity(0.14) : Color.accentRed.opacity(0.12) }
            return Color.bg2
        case .dice:
            return Color.white
        case .filled(_, let color):
            return color.style.fill
        }
    }

    private var cellBorder: Color {
        switch cellState {
        case .empty:
            if isHovered { return vm.hoverIsValid ? Color.accentGreen.opacity(0.75) : Color.accentRed.opacity(0.65) }
            return Color.sep
        case .dice:
            return Color.clear
        case .filled(_, let color):
            return color.style.border
        }
    }

    private var cellShadowColor: Color {
        switch cellState {
        case .empty:  return .clear
        case .dice:   return Color.black.opacity(0.45)
        case .filled(_, let color): return color.style.shadow
        }
    }

    private var cellShadowY: CGFloat {
        switch cellState {
        case .empty: return 0
        default:     return 3
        }
    }
}

// MARK: - TrayPieceView
// Active (unplaced) piece. Tap = rotate. Drag = start drag gesture on board.
struct TrayPieceView: View {

    @Environment(GameViewModel.self) private var vm
    let piece: TrayPiece

    private let CS: CGFloat = 20
    private let GAP: CGFloat = 3
    private var col: PieceColor { piece.color.style }
    private var isRotating: Bool { vm.rotatingPieceID == piece.id }
    private var isShaking: Bool  { vm.shakingPieceID  == piece.id }

    var body: some View {
        PieceGrid(shape: piece.shape, color: piece.color, cellSize: CS, gap: GAP)
            .padding(7)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.sep, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
            .rotationEffect(isRotating ? .degrees(90) : .zero)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRotating)
            .offset(x: isShaking ? 6 : 0)
            .animation(
                isShaking ? .easeInOut(duration: 0.06).repeatCount(4, autoreverses: true) : .default,
                value: isShaking
            )
            .overlay(alignment: .topTrailing) {
                // Rotate hint badge
                ZStack {
                    Circle().fill(Color.bg3).frame(width: 16, height: 16)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.label4)
                }
                .offset(x: 5, y: -5)
            }
            .onTapGesture {
                vm.rotatePiece(id: piece.id)
            }
            // Long-press then drag to place on board
            .gesture(
                LongPressGesture(minimumDuration: 0.01)
                    .sequenced(before: DragGesture(minimumDistance: 4, coordinateSpace: .global))
                    .onChanged { val in
                        if case .second(true, let drag?) = val {
                            vm.dragState = DragState(piece: piece, location: drag.location)
                        }
                    }
                    .onEnded { _ in
                        // Board's own gesture handles the actual placement
                    }
            )
    }
}

// MARK: - GhostPieceView
// Faded placeholder for already-placed pieces. Tap to lift back to tray.
struct GhostPieceView: View {
    let def:     PieceDef
    let onTap:   () -> Void

    var body: some View {
        PieceGrid(shape: def.shape, color: def.color, cellSize: 20, gap: 3)
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

// MARK: - PieceGrid (shared renderer)
struct PieceGrid: View {
    let shape:    Shape
    let color:    PieceColorName
    let cellSize: CGFloat
    let gap:      CGFloat

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

// MARK: - Helpers
private struct CircleButton: View {
    let systemName: String
    var weight: Font.Weight = .medium
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: weight))
                .foregroundStyle(Color.label2)
                .frame(width: 36, height: 36)
                .background(Color.fill3)
                .clipShape(Circle())
        }
    }
}
