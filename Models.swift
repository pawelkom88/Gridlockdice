import Foundation

// MARK: - Shape
// A piece shape is a 2D array of Bool (true = filled cell).
typealias Shape = [[Bool]]

extension Shape {
    /// Rotate 90° clockwise.
    func rotatedCW() -> Shape {
        let rows = self.count
        let cols = self[0].count
        return (0..<cols).map { c in
            (0..<rows).map { r in
                self[rows - 1 - r][c]
            }
        }
    }

    var width:  Int { self[0].count }
    var height: Int { self.count }
}

// MARK: - Piece definition (level template — immutable)
struct PieceDef: Identifiable {
    let id:    String
    let color: PieceColorName
    let shape: Shape

    // Convenience init from Int array rows (1 = filled, 0 = empty)
    init(id: String, color: PieceColorName, rows: [[Int]]) {
        self.id    = id
        self.color = color
        self.shape = rows.map { $0.map { $0 == 1 } }
    }
}

// MARK: - Tray piece (mutable — shape can be rotated)
struct TrayPiece: Identifiable {
    let id:      String
    let color:   PieceColorName
    var shape:   Shape          // mutated on rotation

    init(from def: PieceDef) {
        self.id    = def.id
        self.color = def.color
        self.shape = def.shape
    }

    mutating func rotateCW() {
        shape = shape.rotatedCW()
    }
}

// MARK: - Dice marker (fixed blocker on the board)
struct DiceMarker: Identifiable {
    let id:    String           // e.g. "A1"
    let row:   Int
    let col:   Int
    let label: String
}

// MARK: - Level definition
struct LevelDef: Identifiable {
    let id:      Int
    let name:    String
    let subtitle:String         // e.g. "4 × 4 · Tutorial"
    let rows:    Int
    let cols:    Int
    let dice:    [DiceMarker]
    let pieces:  [PieceDef]
}

// MARK: - Grid cell state
enum CellState: Equatable {
    case empty
    case dice(label: String)
    case filled(pieceID: String, color: PieceColorName)
}

// MARK: - Board state (value type, easy to diff)
struct BoardState {
    let rows: Int
    let cols: Int
    private var cells: [[CellState]]

    init(rows: Int, cols: Int, dice: [DiceMarker]) {
        self.rows  = rows
        self.cols  = cols
        self.cells = Array(repeating: Array(repeating: .empty, count: cols), count: rows)
        for d in dice {
            cells[d.row][d.col] = .dice(label: d.label)
        }
    }

    subscript(r: Int, c: Int) -> CellState {
        get { cells[r][c] }
        set { cells[r][c] = newValue }
    }

    func canPlace(shape: Shape, at row: Int, col: Int) -> Bool {
        for dr in 0..<shape.height {
            for dc in 0..<shape.width {
                guard shape[dr][dc] else { continue }
                let nr = row + dr, nc = col + dc
                guard nr >= 0, nr < rows, nc >= 0, nc < cols else { return false }
                guard cells[nr][nc] == .empty else { return false }
            }
        }
        return true
    }

    mutating func place(shape: Shape, at row: Int, col: Int, pieceID: String, color: PieceColorName) {
        for dr in 0..<shape.height {
            for dc in 0..<shape.width {
                if shape[dr][dc] {
                    cells[row + dr][col + dc] = .filled(pieceID: pieceID, color: color)
                }
            }
        }
    }

    mutating func remove(pieceID: String) {
        for r in 0..<rows {
            for c in 0..<cols {
                if case .filled(let pid, _) = cells[r][c], pid == pieceID {
                    cells[r][c] = .empty
                }
            }
        }
    }

    var isSolved: Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 != .empty } }
    }

    var filledCount: Int {
        cells.flatMap { $0 }.filter {
            if case .empty = $0 { return false }
            return true
        }.count
    }

    // Number of non-dice cells
    var playableCellCount: Int {
        cells.flatMap { $0 }.filter {
            if case .dice = $0 { return false }
            return true
        }.count
    }
}

// MARK: - Level catalogue
struct LevelCatalogue {
    static let all: [LevelDef] = [
        LevelDef(
            id: 1, name: "First Steps", subtitle: "4 × 4  ·  Tutorial",
            rows: 4, cols: 4,
            dice: [
                DiceMarker(id:"A1", row:0, col:0, label:"A1"),
                DiceMarker(id:"C4", row:2, col:3, label:"C4"),
            ],
            pieces: [
                PieceDef(id:"p1", color:.red,    rows:[[1,1],[1,0]]),
                PieceDef(id:"p2", color:.blue,   rows:[[1,1,1]]),
                PieceDef(id:"p3", color:.yellow, rows:[[1,0],[1,1]]),
                PieceDef(id:"p4", color:.green,  rows:[[1,1]]),
                PieceDef(id:"p5", color:.teal,   rows:[[1],[1],[1]]),
            ]
        ),
        LevelDef(
            id: 2, name: "Corner Case", subtitle: "5 × 5  ·  Beginner",
            rows: 5, cols: 5,
            dice: [
                DiceMarker(id:"A5", row:0, col:4, label:"A5"),
                DiceMarker(id:"E1", row:4, col:0, label:"E1"),
                DiceMarker(id:"B3", row:1, col:2, label:"B3"),
                DiceMarker(id:"D4", row:3, col:3, label:"D4"),
            ],
            pieces: [
                PieceDef(id:"p1", color:.orange, rows:[[1,1,1],[0,1,0]]),
                PieceDef(id:"p2", color:.purple, rows:[[1,1],[1,0]]),
                PieceDef(id:"p3", color:.red,    rows:[[1,0],[1,1],[1,0]]),
                PieceDef(id:"p4", color:.blue,   rows:[[1,1,1,1]]),
                PieceDef(id:"p5", color:.green,  rows:[[1,1],[0,1]]),
                PieceDef(id:"p6", color:.teal,   rows:[[1],[1],[1]]),
                PieceDef(id:"p7", color:.yellow, rows:[[1,1,1],[1,0,0]]),
            ]
        ),
        LevelDef(
            id: 3, name: "The Notch", subtitle: "6 × 6  ·  Beginner",
            rows: 6, cols: 6,
            dice: [
                DiceMarker(id:"B1", row:1, col:0, label:"B1"),
                DiceMarker(id:"C5", row:2, col:4, label:"C5"),
                DiceMarker(id:"D2", row:3, col:1, label:"D2"),
                DiceMarker(id:"D4", row:3, col:3, label:"D4"),
                DiceMarker(id:"E5", row:4, col:4, label:"E5"),
                DiceMarker(id:"F1", row:5, col:0, label:"F1"),
                DiceMarker(id:"F2", row:5, col:1, label:"F2"),
            ],
            pieces: [
                PieceDef(id:"p1", color:.red,    rows:[[1,1],[0,1],[0,1]]),
                PieceDef(id:"p2", color:.yellow, rows:[[1,1,1],[0,1,0]]),
                PieceDef(id:"p3", color:.blue,   rows:[[1,0],[1,1],[1,0]]),
                PieceDef(id:"p4", color:.green,  rows:[[0,1],[1,1],[1,0]]),
                PieceDef(id:"p5", color:.teal,   rows:[[1],[1],[1],[1]]),
                PieceDef(id:"p6", color:.orange, rows:[[1,1,1]]),
                PieceDef(id:"p7", color:.purple, rows:[[1,1],[1,0]]),
                PieceDef(id:"p8", color:.pink,   rows:[[1,1]]),
            ]
        ),
        LevelDef(
            id: 4, name: "Staircase", subtitle: "5 × 5  ·  Beginner",
            rows: 5, cols: 5,
            dice: [
                DiceMarker(id:"A1", row:0, col:0, label:"A1"),
                DiceMarker(id:"B2", row:1, col:1, label:"B2"),
                DiceMarker(id:"C3", row:2, col:2, label:"C3"),
                DiceMarker(id:"D4", row:3, col:3, label:"D4"),
                DiceMarker(id:"E5", row:4, col:4, label:"E5"),
            ],
            pieces: [
                PieceDef(id:"p1", color:.red,    rows:[[1,1,1]]),
                PieceDef(id:"p2", color:.blue,   rows:[[1,1],[1,0]]),
                PieceDef(id:"p3", color:.green,  rows:[[0,1],[1,1],[1,0]]),
                PieceDef(id:"p4", color:.orange, rows:[[1,0],[1,1],[0,1]]),
                PieceDef(id:"p5", color:.purple, rows:[[1,1,1],[0,0,1]]),
                PieceDef(id:"p6", color:.yellow, rows:[[1,1]]),
                PieceDef(id:"p7", color:.teal,   rows:[[1],[1]]),
            ]
        ),
        LevelDef(
            id: 5, name: "Archipelago", subtitle: "6 × 6  ·  Intermediate",
            rows: 6, cols: 6,
            dice: [
                DiceMarker(id:"A1", row:0, col:0, label:"A1"),
                DiceMarker(id:"A6", row:0, col:5, label:"A6"),
                DiceMarker(id:"C3", row:2, col:2, label:"C3"),
                DiceMarker(id:"C4", row:2, col:3, label:"C4"),
                DiceMarker(id:"F1", row:5, col:0, label:"F1"),
                DiceMarker(id:"F6", row:5, col:5, label:"F6"),
            ],
            pieces: [
                PieceDef(id:"p1", color:.red,    rows:[[1,1],[1,0]]),
                PieceDef(id:"p2", color:.yellow, rows:[[1,1,1],[0,1,0]]),
                PieceDef(id:"p3", color:.blue,   rows:[[1,0],[1,1],[1,0]]),
                PieceDef(id:"p4", color:.green,  rows:[[1,1,1,1]]),
                PieceDef(id:"p5", color:.teal,   rows:[[1,1],[0,1],[0,1]]),
                PieceDef(id:"p6", color:.orange, rows:[[1,1,1]]),
                PieceDef(id:"p7", color:.purple, rows:[[1,1],[1,0]]),
                PieceDef(id:"p8", color:.pink,   rows:[[1,0],[1,1]]),
                PieceDef(id:"p9", color:.red,    rows:[[1],[1]]),
            ]
        ),
    ]
}
