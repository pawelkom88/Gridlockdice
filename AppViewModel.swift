import SwiftUI
import Combine

// MARK: - App navigation (replaces JS screen state string)
enum AppScreen {
    case levelSelect
    case game(levelID: Int)
    case paywall
    case completion(levelID: Int, elapsed: TimeInterval)
}

// MARK: - Drag state
struct DragState {
    let piece:     TrayPiece
    var location:  CGPoint       // current finger position in board coordinate space
    var targetRow: Int?
    var targetCol: Int?
}

// MARK: - GameViewModel
// Owns the single source of truth for the active game session.
// Maps to React GameScreen state: grid, placed, tray, drag, hover, shake, snap.
@MainActor
@Observable
final class GameViewModel {

    // Level
    let level: LevelDef

    // Board
    var board: BoardState

    // Tray pieces (mutable shapes for rotation)
    var trayPieces: [TrayPiece]

    // Placed piece ids (used to show ghost thumbnails in tray)
    var placedIDs: [String] = []

    // Drag
    var dragState: DragState? = nil

    // Hover highlight
    var hoverRow: Int? = nil
    var hoverCol: Int? = nil

    // Feedback animation IDs
    var shakingPieceID:   String? = nil
    var snappingPieceID:  String? = nil
    var rotatingPieceID:  String? = nil

    // Timer
    private var startDate: Date = .now
    var elapsedSeconds: TimeInterval = 0
    private var timerTask: Task<Void, Never>? = nil

    // Solved callback
    var onSolved: ((TimeInterval) -> Void)? = nil

    init(level: LevelDef) {
        self.level      = level
        self.board      = BoardState(rows: level.rows, cols: level.cols, dice: level.dice)
        self.trayPieces = level.pieces.map { TrayPiece(from: $0) }
        startTimer()
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Timer
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

    var formattedTime: String {
        let total = Int(elapsedSeconds)
        let m = total / 60, s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Progress
    var filledCount:   Int { board.filledCount - level.dice.count }
    var totalPlayable: Int { level.rows * level.cols - level.dice.count }
    var progress:      Double { totalPlayable > 0 ? Double(filledCount) / Double(totalPlayable) : 0 }

    // MARK: - Hover helpers
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

    // MARK: - Rotate tray piece (tap in tray)
    func rotatePiece(id: String) {
        guard let idx = trayPieces.firstIndex(where: { $0.id == id }) else { return }
        trayPieces[idx].rotateCW()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rotatingPieceID = id
        }
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            rotatingPieceID = nil
        }
    }

    // MARK: - Place piece (drag drop)
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

    // MARK: - Remove placed piece (tap on board cell)
    func removePiece(id: String) {
        guard let def = level.pieces.first(where: { $0.id == id }) else { return }
        board.remove(pieceID: id)
        placedIDs.removeAll { $0 == id }
        // Restore original (un-rotated) shape
        trayPieces.append(TrayPiece(from: def))
    }

    // MARK: - Reset
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

    // MARK: - Shake feedback
    private func triggerShake(id: String) {
        withAnimation(.default) { shakingPieceID = id }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            shakingPieceID = nil
        }
    }
}

// MARK: - AppViewModel
// Owns navigation and persisted state (completed levels, unlock status).
// Maps to React root state: screen, lvlId, completed, time, startT.
@MainActor
@Observable
final class AppViewModel {

    var screen:        AppScreen = .levelSelect
    var completedIDs:  Set<Int>  = []
    var isUnlocked:    Bool      = false

    // Active game session
    var gameVM: GameViewModel? = nil

    func startLevel(_ id: Int) {
        guard let def = LevelCatalogue.all.first(where: { $0.id == id }) else { return }
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
            screen = .paywall
        }
    }

    func unlock() {
        isUnlocked = true
        screen = .levelSelect
        // In production: trigger StoreKit purchase flow here
    }

    func formattedTime(elapsed: TimeInterval) -> String {
        let total = Int(elapsed)
        let m = total / 60, s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
