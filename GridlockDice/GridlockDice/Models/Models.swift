import Foundation

typealias Shape = [[Bool]]

extension Shape {
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

struct PieceDef: Identifiable {
    let id:    String
    let color: PieceColorName
    let shape: Shape

    init(id: String, color: PieceColorName, rows: [[Int]]) {
        self.id    = id
        self.color = color
        self.shape = rows.map { $0.map { $0 == 1 } }
    }
}

struct TrayPiece: Identifiable {
    let id:      String
    let color:   PieceColorName
    var shape:   Shape

    init(from def: PieceDef) {
        self.id    = def.id
        self.color = def.color
        self.shape = def.shape
    }

    mutating func rotateCW() {
        shape = shape.rotatedCW()
    }
}

struct DiceMarker: Identifiable {
    let id:    String
    let row:   Int
    let col:   Int
    let label: String
}

struct LevelDef: Identifiable {
    let id:      Int
    let name:    String
    let subtitle: String
    let rows:    Int
    let cols:    Int
    let dice:    [DiceMarker]
    let pieces:  [PieceDef]

    var isFree: Bool { id <= 15 }
    var allowsRotation: Bool { id >= 21 }
}

enum CellState: Equatable {
    case empty
    case dice(label: String)
    case filled(pieceID: String, color: PieceColorName)
}

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

    var playableCellCount: Int {
        cells.flatMap { $0 }.filter {
            if case .dice = $0 { return false }
            return true
        }.count
    }
}

struct LevelCatalogue {
    static let all: [LevelDef] = buildCatalogue()

    private static let RL = Array("ABCDEF")

    private static func diceMarkers(from coords: [(Int, Int)]) -> [DiceMarker] {
        coords.enumerated().map { i, c in
            DiceMarker(id: "D\(i+1)", row: c.0, col: c.1,
                       label: "\(RL[c.0])\(c.1 + 1)")
        }
    }

    private static let shapeBank: [(name: String, cells: Int, shape: [[Int]])] = [
        ("1×1", 1, [[1]]),
        ("2×1h", 2, [[1,1]]),
        ("3×1h", 3, [[1,1,1]]),
        ("2×2",  4, [[1,1],[1,1]]),
    ]

    private static func makePieces(remaining: Int, boardSize: Int, dice: [DiceMarker],
                                    startID: Int, colors: [PieceColorName]) -> [PieceDef] {
        let padded = colors + colors
        func generate() -> [PieceDef] {
            var pieces: [PieceDef] = []
            var left = remaining
            var pc = startID
            while left > 0 {
                let idx = pieces.count
                if left >= 4 && boardSize >= 6 && idx % 7 == 0 {
                    pieces.append(PieceDef(id: "p\(pc)", color: padded[idx % padded.count], rows: [[1,1],[1,1]]))
                    pc += 1; left -= 4
                } else if left >= 3 && idx % 5 == 0 {
                    pieces.append(PieceDef(id: "p\(pc)", color: padded[idx % padded.count], rows: [[1,1,1]]))
                    pc += 1; left -= 3
                } else if left >= 2 {
                    pieces.append(PieceDef(id: "p\(pc)", color: padded[idx % padded.count], rows: [[1,1]]))
                    pc += 1; left -= 2
                } else {
                    pieces.append(PieceDef(id: "p\(pc)", color: padded[idx % padded.count], rows: [[1]]))
                    pc += 1; left -= 1
                }
            }
            return pieces
        }
        let pieces = generate()
        let level = LevelDef(id: 0, name: "", subtitle: "", rows: boardSize, cols: boardSize,
                             dice: dice, pieces: pieces)
        if PuzzleSolver.isSolvable(level: level) {
            return pieces
        }
        return (0..<remaining).map { i in
            PieceDef(id: "p\(startID + i)", color: colors[i % colors.count], rows: [[1]])
        }
    }

    private static func buildCatalogue() -> [LevelDef] {
        var levels: [LevelDef] = []
        var pc = 0
        let clr: [PieceColorName] = [.red,.orange,.yellow,.green,.teal,.blue,.purple,.pink]

        func HC(_ id: Int, _ name: String, _ subtitle: String, _ size: Int,
                _ diceCoords: [(Int, Int)], _ pieces: [PieceDef]) {
            let dice = diceMarkers(from: diceCoords)
            let remaining = size * size - diceCoords.count
            let level = LevelDef(id: id, name: name, subtitle: subtitle,
                                 rows: size, cols: size, dice: dice, pieces: pieces)
            let finalPieces: [PieceDef]
            if PuzzleSolver.isSolvable(level: level) {
                finalPieces = pieces
            } else {
                finalPieces = (0..<remaining).map { i in
                    PieceDef(id: "p\(pc + i + 1)", color: clr[i % clr.count], rows: [[1]])
                }
            }
            pc += finalPieces.count
            levels.append(LevelDef(
                id: id, name: name, subtitle: subtitle,
                rows: size, cols: size,
                dice: dice,
                pieces: finalPieces
            ))
        }

        func L(_ id: Int, _ name: String, _ subtitle: String, _ size: Int,
               _ diceCoords: [(Int, Int)]) {
            let remaining = size * size - diceCoords.count
            let dice = diceMarkers(from: diceCoords)
            let pieces = makePieces(remaining: remaining, boardSize: size, dice: dice,
                                    startID: pc, colors: clr)
            pc += pieces.count
            levels.append(LevelDef(
                id: id, name: name, subtitle: subtitle,
                rows: size, cols: size,
                dice: dice,
                pieces: pieces
            ))
        }

        // MARK: - Tutorial (1-5) — handcrafted polyominoes
        HC(1, "First Steps", "4 × 4 · Tutorial", 4, [(0,0),(2,3)], [
            PieceDef(id:"p1", color:.red,    rows:[[1,1],[0,1]]),
            PieceDef(id:"p2", color:.blue,   rows:[[1],[1],[1]]),
            PieceDef(id:"p3", color:.yellow, rows:[[1,0],[1,1]]),
            PieceDef(id:"p4", color:.green,  rows:[[1],[1]]),
            PieceDef(id:"p5", color:.teal,   rows:[[1,1,1]]),
        ])
        HC(2, "Corner Case", "5 × 5 · Beginner", 5, [(0,4),(4,0),(1,2),(3,3)], [
            PieceDef(id:"p1", color:.orange, rows:[[1,1,1],[1,0,0]]),
            PieceDef(id:"p2", color:.purple, rows:[[1,0],[1,1]]),
            PieceDef(id:"p3", color:.red,    rows:[[1,0],[1,1],[0,1]]),
            PieceDef(id:"p4", color:.blue,   rows:[[1],[1],[1],[1]]),
            PieceDef(id:"p5", color:.green,  rows:[[1,0],[1,1]]),
            PieceDef(id:"p6", color:.teal,   rows:[[1],[1],[1]]),
        ])
        HC(3, "The Notch", "6 × 6 · Beginner", 6, [(1,0),(2,4),(3,1),(3,3),(4,4),(5,0),(5,1)], [
            PieceDef(id:"p1", color:.red,    rows:[[1,1,1],[0,0,1]]),
            PieceDef(id:"p2", color:.yellow, rows:[[1,1,1],[0,1,0]]),
            PieceDef(id:"p3", color:.blue,   rows:[[1,1,1],[0,1,0]]),
            PieceDef(id:"p4", color:.green,  rows:[[1,1,0],[0,1,1]]),
            PieceDef(id:"p5", color:.teal,   rows:[[1,1,1,1]]),
            PieceDef(id:"p6", color:.orange, rows:[[1],[1],[1]]),
            PieceDef(id:"p7", color:.purple, rows:[[1,1],[0,1]]),
            PieceDef(id:"p8", color:.pink,   rows:[[1,1,1]]),
        ])
        HC(4, "Staircase", "5 × 5 · Beginner", 5, [(0,0),(1,1),(2,2),(3,3),(4,4)], [
            PieceDef(id:"p1", color:.red,    rows:[[1],[1],[1]]),
            PieceDef(id:"p2", color:.blue,   rows:[[1,1],[0,1]]),
            PieceDef(id:"p3", color:.green,  rows:[[1,1,0],[0,1,1]]),
            PieceDef(id:"p4", color:.orange, rows:[[1,0],[1,1],[1,0]]),
            PieceDef(id:"p5", color:.purple, rows:[[1,1],[1,0],[1,0]]),
            PieceDef(id:"p6", color:.yellow, rows:[[1,1]]),
        ])
        HC(5, "Archipelago", "6 × 6 · Intermediate", 6, [(0,0),(0,5),(2,2),(2,3),(5,0),(5,5)], [
            PieceDef(id:"p1", color:.red,    rows:[[1,1],[1,0]]),
            PieceDef(id:"p2", color:.yellow, rows:[[1,0],[1,1],[1,0]]),
            PieceDef(id:"p3", color:.blue,   rows:[[1,1,1],[0,1,0]]),
            PieceDef(id:"p4", color:.green,  rows:[[1,1,1,1]]),
            PieceDef(id:"p5", color:.teal,   rows:[[1,1],[0,1],[0,1]]),
            PieceDef(id:"p6", color:.orange, rows:[[1],[1],[1]]),
            PieceDef(id:"p7", color:.purple, rows:[[1,1],[0,1]]),
            PieceDef(id:"p8", color:.pink,   rows:[[1,0],[1,1]]),
            PieceDef(id:"p9", color:.red,    rows:[[1,1]]),
        ])

        // MARK: - Beginner A (6-10)
        L(6,  "Domino Run",     "5 × 5 · Beginner",     5, [(0,0),(0,4),(4,0),(4,4)])
        L(7,  "Four Corners",   "5 × 5 · Beginner",     5, [(0,0),(0,4),(4,0),(4,4),(2,2)])
        L(8,  "Diagonal",       "5 × 5 · Beginner",     5, [(0,0),(1,1),(3,3),(4,4)])
        L(9,  "Window Pane",    "5 × 5 · Beginner",     5, [(1,1),(1,3),(3,1),(3,3)])
        L(10, "Plus Sign",      "5 × 5 · Beginner",     5, [(2,2)])

        // MARK: - Beginner B (11-15)
        L(11, "First 6×6",      "6 × 6 · Beginner",     6, [(0,0),(0,5),(5,0),(5,5)])
        L(12, "Arches",         "6 × 6 · Beginner",     6, [(0,0),(0,5),(2,2),(2,3),(5,0),(5,5)])
        L(13, "T Shape",        "5 × 5 · Beginner",     5, [(0,2),(4,2)])
        L(14, "Checkers",       "5 × 5 · Beginner",     5, [(0,0),(0,2),(0,4),(2,0),(2,2),(2,4),(4,0),(4,2),(4,4)])
        L(15, "Snake",          "6 × 6 · Beginner",     6, [(0,0),(0,5),(5,0),(5,5),(2,2),(3,3)])

        // MARK: - Intermediate (16-20)
        L(16, "Lock & Key",     "5 × 5 · Intermediate", 5, [(0,1),(0,3),(4,1),(4,3)])
        L(17, "Framed",         "5 × 5 · Intermediate", 5, [(0,0),(0,4),(4,0),(4,4),(2,2)])
        L(18, "Spotlight",      "5 × 5 · Intermediate", 5, [(2,2)])
        L(19, "Nested",         "5 × 5 · Intermediate", 5, [(0,0),(0,4),(4,0),(4,4),(1,1),(1,3),(3,1),(3,3)])
        L(20, "Diamond",        "6 × 6 · Intermediate", 6, [(0,3),(1,3),(2,0),(2,5),(3,0),(3,5),(4,2),(5,2)])

        // MARK: - Rotation Intro (21-25)
        L(21, "Turn Around",    "5 × 5 · Rotation",     5, [(0,1),(0,3),(4,2)])
        L(22, "Flip It",        "5 × 5 · Rotation",     5, [(1,1),(1,3),(3,1),(3,3)])
        L(23, "Spin Doctor",    "5 × 5 · Rotation",     5, [(2,2)])
        L(24, "Twister",        "6 × 6 · Rotation",     6, [(0,0),(0,5),(5,0),(5,5),(2,2),(3,3)])
        L(25, "Helix",          "6 × 6 · Rotation",     6, [(0,2),(1,0),(2,5),(3,0),(4,5),(5,3)])

        // MARK: - Rotation (26-30)
        L(26, "Zigzag",         "5 × 5 · Rotation",     5, [(0,0),(2,2),(4,4)])
        L(27, "Cross Hatch",    "5 × 5 · Rotation",     5, [(0,1),(0,3),(2,2),(4,1),(4,3)])
        L(28, "Maze",           "6 × 6 · Rotation",     6, [(0,0),(0,3),(1,5),(2,1),(3,4),(4,0),(5,2),(5,5)])
        L(29, "Triangles",      "6 × 6 · Rotation",     6, [(0,0),(0,2),(0,4),(2,0),(4,0),(5,5),(5,3),(5,1),(3,5),(1,5)])
        L(30, "Bridge",         "6 × 6 · Rotation",     6, [(1,2),(1,3),(4,2),(4,3)])

        // MARK: - Advanced A (31-40)
        L(31, "Fortress",       "6 × 6 · Advanced",     6, [(0,0),(0,5),(5,0),(5,5),(2,2),(2,3),(3,2),(3,3)])
        L(32, "Obstacle",       "6 × 6 · Advanced",     6, [(0,1),(1,4),(2,0),(2,5),(3,1),(3,4),(4,5),(5,2)])
        L(33, "Winding",        "6 × 6 · Advanced",     6, [(0,2),(1,5),(2,1),(3,3),(4,0),(5,4)])
        L(34, "Pillars",        "6 × 6 · Advanced",     6, [(1,1),(1,4),(3,1),(3,4),(4,2),(4,3)])
        L(35, "Gridlock",       "6 × 6 · Advanced",     6, [(0,1),(0,3),(0,5),(2,0),(2,4),(4,2),(4,5),(5,1),(5,3)])
        L(36, "Split",          "6 × 6 · Advanced",     6, [(0,0),(0,5),(2,2),(2,3),(3,2),(3,3),(5,0),(5,5)])
        L(37, "Octagon",        "6 × 6 · Advanced",     6, [(0,0),(0,2),(0,3),(0,5),(2,0),(2,5),(3,0),(3,5),(5,0),(5,2),(5,3),(5,5)])
        L(38, "Lattice",        "6 × 6 · Advanced",     6, [(0,2),(0,3),(1,0),(1,5),(4,0),(4,5),(5,2),(5,3)])
        L(39, "Vortex",         "6 × 6 · Advanced",     6, [(0,2),(1,1),(1,4),(4,1),(4,4),(5,3)])
        L(40, "Knot",           "6 × 6 · Advanced",     6, [(0,0),(0,5),(1,2),(1,3),(4,2),(4,3),(5,0),(5,5)])

        // MARK: - Advanced B (41-45)
        L(41, "Gateway",        "6 × 6 · Advanced",     6, [(1,1),(1,4),(2,2),(2,3),(3,2),(3,3),(4,1),(4,4)])
        L(42, "Rings",          "6 × 6 · Advanced",     6, [(0,1),(0,4),(1,0),(1,5),(4,0),(4,5),(5,1),(5,4)])
        L(43, "Scattered",      "6 × 6 · Advanced",     6, [(0,2),(1,4),(2,1),(3,5),(4,3),(5,0)])
        L(44, "Orbit",          "6 × 6 · Advanced",     6, [(0,0),(0,2),(0,4),(1,5),(2,0),(4,0),(5,1),(5,3),(5,5)])
        L(45, "Arrow",          "6 × 6 · Advanced",     6, [(0,3),(1,1),(1,4),(2,2),(2,3),(3,2),(3,3),(4,1),(4,4),(5,3)])

        // MARK: - Expert (46-50)
        L(46, "Gauntlet",       "6 × 6 · Expert",       6, [(0,1),(0,4),(1,2),(1,3),(4,2),(4,3),(5,1),(5,4)])
        L(47, "Thorns",         "6 × 6 · Expert",       6, [(0,0),(0,3),(1,1),(1,4),(2,2),(3,2),(4,1),(4,4),(5,0),(5,3)])
        L(48, "Endgame",        "6 × 6 · Expert",       6, [(0,0),(0,2),(0,4),(2,0),(2,5),(3,5),(4,0),(5,1),(5,3),(5,5)])
        L(49, "Final Maze",     "6 × 6 · Expert",       6, [(0,1),(1,0),(1,3),(2,1),(2,4),(3,2),(3,5),(4,0),(4,3),(5,1),(5,4)])
        L(50, "Grand Finale",   "6 × 6 · Expert",       6, [(0,0),(0,5),(1,1),(1,4),(2,2),(3,3),(4,1),(4,4),(5,0),(5,5)])

        return levels
    }
}
