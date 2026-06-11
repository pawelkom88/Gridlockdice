import SwiftUI

struct GameView: View {

    @Environment(AppViewModel.self) private var appVM
    @Environment(GameViewModel.self) private var vm

    @State private var cellSize: CGFloat = 56
    @State private var activeCellSize: CGFloat = 56
    @State private var motion = ReducedMotionPolicy()

    private let calc = CellSizingCalculator()

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
        HStack(spacing: 12) {
            Button {
                appVM.screen = .levelSelect
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.label2)
                    .frame(width: 36, height: 36)
                    .background(Color.fill3)
                    .clipShape(Circle())
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
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    vm.showOnboarding = true
                }
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.label2)
                    .frame(width: 36, height: 36)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(vm.hintUsed ? Color.label4 : (vm.showingHint ? Color.accentYellow : Color.accentPurple))
                    .frame(width: 36, height: 36)
                    .background(vm.hintUsed ? Color.bg2 : (vm.showingHint ? Color.accentYellow.opacity(0.15) : Color.fill3))
                    .clipShape(Circle())
            }
            .disabled(vm.hintUsed && !vm.showingHint)

            Button {
                vm.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.label2)
                    .frame(width: 36, height: 36)
                    .background(Color.fill3)
                    .clipShape(Circle())
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
            let cs = calc.compute(rows: vm.level.rows, cols: vm.level.cols, availableSize: geo.size)
            VStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                BoardGridView(cellSize: cs)
                    .environment(vm)
                    .background(GeometryReader { boardGeo in
                        Color.clear.onAppear {
                            vm.boardFrame = boardGeo.frame(in: .global)
                            activeCellSize = cs
                        }.onChange(of: boardGeo.frame(in: .global)) { _, newFrame in
                            vm.boardFrame = newFrame
                            activeCellSize = cs
                        }
                    })
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
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
                    .font(AppFont.caption())
                    .foregroundStyle(Color.label1)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if vm.trayPieces.isEmpty {
                    Text("All placed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentGreen)
                } else if vm.level.allowsRotation {
                    Label("tap to rotate", systemImage: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.label4)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(vm.trayPieces) { piece in
                        TrayPieceView(piece: piece, cellSize: activeCellSize)
                            .environment(vm)
                    }
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
