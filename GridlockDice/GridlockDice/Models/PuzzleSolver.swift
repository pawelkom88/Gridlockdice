import Foundation

private let maxNodeCount = 500_000

struct PuzzleSolver {

    static func isSolvable(level: LevelDef) -> Bool {
        let tray = level.pieces.map { TrayPiece(from: $0) }
        var board = BoardState(rows: level.rows, cols: level.cols, dice: level.dice)
        var nodes = 0
        return solve(&board, tray, allowsRotation: level.allowsRotation, nodes: &nodes)
    }

    static func countSolutions(level: LevelDef, max: Int) -> Int {
        let tray = level.pieces.map { TrayPiece(from: $0) }
        var board = BoardState(rows: level.rows, cols: level.cols, dice: level.dice)
        return countSolutions(&board, tray, allowsRotation: level.allowsRotation, max: max)
    }

    private static func solve(_ board: inout BoardState, _ pieces: [TrayPiece], allowsRotation: Bool, nodes: inout Int) -> Bool {
        if board.isSolved { return true }
        if nodes >= maxNodeCount { return false }
        guard let (tr, tc) = firstEmpty(board) else { return false }

        for (i, piece) in pieces.enumerated() {
            nodes += 1
            let orientations = generateOrientations(piece.shape, includeRotations: allowsRotation)
            for shape in orientations {
                if board.canPlace(shape: shape, at: tr, col: tc) {
                    var nextBoard = board
                    nextBoard.place(shape: shape, at: tr, col: tc, pieceID: piece.id, color: piece.color)
                    var nextPieces = pieces
                    nextPieces.remove(at: i)
                    if solve(&nextBoard, nextPieces, allowsRotation: allowsRotation, nodes: &nodes) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private static func countSolutions(_ board: inout BoardState, _ pieces: [TrayPiece], allowsRotation: Bool, max: Int) -> Int {
        if board.isSolved { return 1 }
        guard let (tr, tc) = firstEmpty(board) else { return 0 }
        var count = 0

        for (i, piece) in pieces.enumerated() {
            let orientations = generateOrientations(piece.shape, includeRotations: allowsRotation)
            for shape in orientations {
                if board.canPlace(shape: shape, at: tr, col: tc) {
                    var nextBoard = board
                    nextBoard.place(shape: shape, at: tr, col: tc, pieceID: piece.id, color: piece.color)
                    var nextPieces = pieces
                    nextPieces.remove(at: i)
                    count += countSolutions(&nextBoard, nextPieces, allowsRotation: allowsRotation, max: max - count)
                    if count >= max { return count }
                }
            }
        }
        return count
    }

    private static func firstEmpty(_ board: BoardState) -> (Int, Int)? {
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if case .empty = board[r, c] {
                    return (r, c)
                }
            }
        }
        return nil
    }

    private static func generateOrientations(_ shape: Shape, includeRotations: Bool) -> [Shape] {
        var result: [Shape] = [shape]
        guard includeRotations else { return result }

        var current = shape
        for _ in 0..<3 {
            let next = current.rotatedCW()
            if !result.contains(next) {
                result.append(next)
            }
            current = next
        }
        return result
    }
}
