import SwiftUI

// MARK: - Navigation

enum AppScreen {
    case levelSelect
    case game(levelID: Int)
    case paywall
    case completion(levelID: Int, elapsed: TimeInterval)
}

// MARK: - Drag state

struct DragState {
    let piece:     TrayPiece
    var location:  CGPoint
    var targetRow: Int?
    var targetCol: Int?
}

// MARK: - GameViewModel

@MainActor
@Observable
final class GameViewModel {

    let level: LevelDef
    var board: BoardState
    var trayPieces: [TrayPiece]
    var placedIDs: [String] = []

    var dragState: DragState?
    var hoverRow: Int?
    var hoverCol: Int?
    var boardFrame: CGRect = .zero

    var shakingPieceID: String?
    var snappingPieceID: String?
    var rotatingPieceID: String?

    private var startDate: Date = .now
    var elapsedSeconds: TimeInterval = 0
    private var timerTask: Task<Void, Never>?

    var onSolved: ((TimeInterval) -> Void)?

    init(level: LevelDef) {
        self.level      = level
        self.board      = BoardState(rows: level.rows, cols: level.cols, dice: level.dice)
        self.trayPieces = level.pieces.map { TrayPiece(from: $0) }
        startTimer()
    }

    private func startTimer() {
        startDate = .now
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                self.elapsedSeconds = Date.now.timeIntervalSince(self.startDate)
            }
        }
    }

    var filledCount:   Int { board.filledCount - level.dice.count }
    var totalPlayable: Int { level.rows * level.cols - level.dice.count }
    var progress:      Double { totalPlayable > 0 ? Double(filledCount) / Double(totalPlayable) : 0 }

    var hoverCells: Set<String> {
        guard let drag = dragState, let hr = hoverRow, let hc = hoverCol else { return [] }
        var result = Set<String>()
        for dr in 0..<drag.piece.shape.height {
            for dc in 0..<drag.piece.shape.width {
                if drag.piece.shape[dr][dc] {
                    result.insert("\(hr+dr),\(hc+dc)")
                }
            }
        }
        return result
    }

    var hoverIsValid: Bool {
        guard let drag = dragState, let hr = hoverRow, let hc = hoverCol else { return false }
        return board.canPlace(shape: drag.piece.shape, at: hr, col: hc)
    }

    func updateHover(globalLocation: CGPoint, cellSize: CGFloat) {
        // boardFrame is in global/screen coordinates
        // The board grid starts at x = boardFrame.minX + LBL + GAP
        // The board grid starts at y = boardFrame.minY + colLabelHeight (≈ 23pt)
        let LBL: CGFloat = 22
        let GAP: CGFloat = 4
        let colLabelH: CGFloat = 23

        let gridOriginX = boardFrame.minX + LBL + GAP
        let gridOriginY = boardFrame.minY + colLabelH

        let localX = globalLocation.x - gridOriginX
        let localY = globalLocation.y - gridOriginY

        let col = Int(floor(localX / (cellSize + GAP)))
        let row = Int(floor(localY / (cellSize + GAP)))

        // Allow slightly out-of-bounds during drag — clamp to grid edges
        // so the preview doesn't disappear the moment a finger drifts 1pt outside
        let clampedRow = max(0, min(row, level.rows - 1))
        let clampedCol = max(0, min(col, level.cols - 1))

        hoverRow = (0..<level.rows).contains(row) ? clampedRow : nil
        hoverCol = (0..<level.cols).contains(col) ? clampedCol : nil
    }

    func endDrag() {
        // Called on finger-up. Place if valid, shake if not, always clean up.
        defer {
            dragState = nil
            hoverRow  = nil
            hoverCol  = nil
        }
        guard let drag = dragState else { return }
        if let hr = hoverRow, let hc = hoverCol, hoverIsValid {
            tryPlace(pieceID: drag.piece.id, at: hr, col: hc)
        } else {
            triggerShake(id: drag.piece.id)
        }
    }

    func rotatePiece(id: String) {
        guard let idx = trayPieces.firstIndex(where: { $0.id == id }) else { return }
        guard level.allowsRotation else { return }
        trayPieces[idx].rotateCW()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rotatingPieceID = id
        }
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            rotatingPieceID = nil
        }
    }

    func tryPlace(pieceID: String, at row: Int, col: Int) {
        guard let idx = trayPieces.firstIndex(where: { $0.id == pieceID }) else { return }
        let piece = trayPieces[idx]
        if board.canPlace(shape: piece.shape, at: row, col: col) {
            board.place(shape: piece.shape, at: row, col: col, pieceID: piece.id, color: piece.color)
            trayPieces.remove(at: idx)
            placedIDs.append(pieceID)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                snappingPieceID = pieceID
            }
            Task {
                try? await Task.sleep(nanoseconds: 380_000_000)
                snappingPieceID = nil
                if board.isSolved {
                    timerTask?.cancel()
                    onSolved?(elapsedSeconds)
                }
            }
        } else {
            triggerShake(id: pieceID)
        }
    }

    func removePiece(id: String) {
        guard let def = level.pieces.first(where: { $0.id == id }) else { return }
        board.remove(pieceID: id)
        placedIDs.removeAll { $0 == id }
        trayPieces.append(TrayPiece(from: def))
    }

    func reset() {
        board       = BoardState(rows: level.rows, cols: level.cols, dice: level.dice)
        trayPieces  = level.pieces.map { TrayPiece(from: $0) }
        placedIDs   = []
        dragState   = nil
        hoverRow    = nil
        hoverCol    = nil
        timerTask?.cancel()
        elapsedSeconds = 0
        startTimer()
    }

    internal func triggerShake(id: String) {
        withAnimation(.default) { shakingPieceID = id }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            shakingPieceID = nil
        }
    }
}

// MARK: - AppViewModel

@MainActor
@Observable
final class AppViewModel {

    private let store: PersistenceStore
    private let purchaseService: PurchaseService

    var screen: AppScreen = .levelSelect
    var gameVM: GameViewModel?

    var completedIDs: Set<Int> {
        didSet { store.completedLevels = completedIDs }
    }

    var isUnlocked: Bool {
        didSet { store.isUnlocked = isUnlocked }
    }

    var priceText: String { purchaseService.priceText }
    var productAvailable: Bool { purchaseService.productAvailable }

    init(store: PersistenceStore = UserDefaultsStore(),
         purchaseService: PurchaseService) {
        self.store = store
        self.purchaseService = purchaseService
        self.completedIDs = store.completedLevels
        self.isUnlocked = store.isUnlocked
    }

    func loadProduct() async {
        await purchaseService.loadProduct()
    }

    func purchase() async throws -> Bool {
        let success = try await purchaseService.purchase()
        if success {
            isUnlocked = true
            screen = .levelSelect
        }
        return success
    }

    func restore() async throws -> Bool {
        let success = try await purchaseService.restore()
        if success {
            isUnlocked = true
            screen = .levelSelect
        }
        return success
    }

    func startLevel(_ id: Int) {
        guard let def = LevelCatalogue.all.first(where: { $0.id == id }) else { return }

        if !def.isFree && !isUnlocked {
            screen = .paywall
            Task { await loadProduct() }
            return
        }

        let vm = GameViewModel(level: def)
        vm.onSolved = { [weak self] elapsed in
            guard let self else { return }
            self.completedIDs.insert(id)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 650_000_000)
                self.screen = .completion(levelID: id, elapsed: elapsed)
            }
        }
        gameVM = vm
        screen = .game(levelID: id)
    }

    func goToNextLevel(after id: Int) {
        let nextID = id + 1
        if LevelCatalogue.all.contains(where: { $0.id == nextID }) {
            startLevel(nextID)
        } else {
            screen = .levelSelect
        }
    }

}
