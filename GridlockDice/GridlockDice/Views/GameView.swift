import SwiftUI

struct GameView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(GameViewModel.self) private var vm
    @State private var cellSize: CGFloat = 56
    @State private var activeCellSize: CGFloat = 56
    @State private var motion = ReducedMotionPolicy()

    private let calc = CellSizingCalculator()

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private func cellSizeCap(availableSize: CGSize, cols: Int) -> CGFloat {
        let hardCap: CGFloat = 160
        let isLandscape = availableSize.width > availableSize.height
        let fillRatio: CGFloat = isLandscape ? 0.4 : 0.75
        let maxByWidth = floor((availableSize.width * fillRatio - CGFloat(cols - 1) * 4 - 22) / CGFloat(cols))
        return min(hardCap, max(1, maxByWidth))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                progressStrip
                boardArea
                trayShelf
            }
            .background(Color.bg0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if vm.showOnboarding {
                OnboardingOverlayView()
                    .environment(appVM)
                    .environment(vm)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: isPad ? 24 : 12) {
            Button {
                appVM.screen = .levelSelect
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: isPad ? 32 : 16, weight: .regular))
                    .foregroundStyle(Color.label2)
                    .frame(width: isPad ? 72 : 36, height: isPad ? 72 : 36)
                    .background(Color.fill3)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: isPad ? 2 : 1) {
                Text(vm.level.name)
                    .font(.system(size: isPad ? 36 : 18, weight: .bold))
                    .foregroundStyle(Color.label1)
                    .tracking(-0.4)
                    .lineLimit(1)
                Text(vm.level.subtitle)
                    .font(.system(size: isPad ? 24 : 12))
                    .foregroundStyle(Color.label3)
            }
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    vm.showOnboarding = true
                }
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: isPad ? 32 : 16, weight: .semibold))
                    .foregroundStyle(Color.label2)
                    .frame(width: isPad ? 72 : 36, height: isPad ? 72 : 36)
                    .background(Color.fill3)
                    .clipShape(Circle())
            }

            Button {
                if vm.showingHint {
                    vm.clearHint()
                } else {
                    vm.showHint()
                }
            } label: {
                Image(systemName: vm.hintUsed ? "lightbulb.slash" : (vm.showingHint ? "lightbulb.fill" : "lightbulb"))
                    .font(.system(size: isPad ? 28 : 14, weight: .medium))
                    .foregroundStyle(vm.hintUsed ? Color.label4 : (vm.showingHint ? Color.accentYellow : Color.accentPurple))
                    .frame(width: isPad ? 72 : 36, height: isPad ? 72 : 36)
                    .background(vm.hintUsed ? Color.bg2 : (vm.showingHint ? Color.accentYellow.opacity(0.15) : Color.fill3))
                    .clipShape(Circle())
            }
            .disabled(vm.hintUsed && !vm.showingHint)

            Button {
                vm.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: isPad ? 32 : 16, weight: .medium))
                    .foregroundStyle(Color.label2)
                    .frame(width: isPad ? 72 : 36, height: isPad ? 72 : 36)
                    .background(Color.fill3)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, isPad ? 32 : 16)
        .padding(.bottom, isPad ? 8 : 4)
        .frame(height: isPad ? 128 : 64)
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
                        .animation(.spring(response: motion.springResponse, dampingFraction: motion.springDamping), value: vm.progress)
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
            let maxCell = isPad ? cellSizeCap(availableSize: geo.size, cols: vm.level.cols) : nil
            let cs = calc.compute(rows: vm.level.rows, cols: vm.level.cols, availableSize: geo.size, maxCellSize: maxCell)

            let boardW = cs * CGFloat(vm.level.cols) + CGFloat(vm.level.cols - 1) * 4 + 22
            let boardH = cs * CGFloat(vm.level.rows) + CGFloat(vm.level.rows - 1) * 4 + 28
            let gFrame = geo.frame(in: .global)
            let ox = gFrame.minX + (geo.size.width - boardW) / 2
            let oy = gFrame.minY + (geo.size.height - boardH) / 2
            let boardRect = CGRect(x: ox, y: oy, width: boardW, height: boardH)

            BoardGridView(cellSize: cs)
                .environment(vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    vm.boardFrame = boardRect
                    activeCellSize = cs
                }
                .onChange(of: geo.size) { _, _ in
                    let g = geo.frame(in: .global)
                    let bw = cs * CGFloat(vm.level.cols) + CGFloat(vm.level.cols - 1) * 4 + 22
                    let bh = cs * CGFloat(vm.level.rows) + CGFloat(vm.level.rows - 1) * 4 + 28
                    vm.boardFrame = CGRect(x: g.minX + (geo.size.width - bw) / 2,
                                            y: g.minY + (geo.size.height - bh) / 2,
                                            width: bw, height: bh)
                    activeCellSize = cs
                }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 4)
    }

    // MARK: - Tray shelf

    private var trayShelf: some View {
        VStack(spacing: 0) {
            Divider().background(Color.sep)

            HStack {
                Text(vm.trayPieces.isEmpty ? "Board Complete" : "\(vm.trayPieces.count) Piece\(vm.trayPieces.count == 1 ? "" : "s") Remaining")
                    .font(.system(size: isPad ? 22 : 11, weight: .semibold))
                    .foregroundStyle(Color.label1)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if vm.trayPieces.isEmpty {
                    Text("All placed")
                        .font(.system(size: isPad ? 24 : 12, weight: .semibold))
                        .foregroundStyle(Color.accentGreen)
                } else if vm.level.allowsRotation {
                    Label("tap to rotate", systemImage: "arrow.clockwise")
                        .font(.system(size: isPad ? 20 : 10))
                        .foregroundStyle(Color.label4)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, isPad ? 20 : 10)
            .padding(.bottom, isPad ? 12 : 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(vm.trayPieces) { piece in
                        TrayPieceView(piece: piece, cellSize: activeCellSize, thumbnailSize: isPad ? 33 : 22)
                            .environment(vm)
                    }
                    ForEach(vm.placedIDs, id: \.self) { pid in
                        if let def = vm.level.pieces.first(where: { $0.id == pid }) {
                            GhostPieceView(def: def, cellSize: isPad ? 33 : 22) {
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
        .frame(height: isPad ? 150 : 122)
    }
}
