import Foundation

// MARK: - Shape
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

struct PieceDef {
    let id: String
    let shape: Shape
    init(id: String, rows: [[Int]]) {
        self.id = id
        self.shape = rows.map { $0.map { $0 == 1 } }
    }
}

let l1_dice = [(0,0), (2,3)]

struct Board {
    var cells: [[Bool]]
    let rows: Int
    let cols: Int
    init(rows: Int, cols: Int, dice: [(Int, Int)]) {
        self.rows = rows; self.cols = cols
        cells = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for (r,c) in dice { cells[r][c] = true } // true = blocked
    }
    mutating func place(_ s: Shape, _ r: Int, _ c: Int) {
        for dr in 0..<s.height {
            for dc in 0..<s.width {
                if s[dr][dc] { cells[r+dr][c+dc] = true }
            }
        }
    }
    mutating func remove(_ s: Shape, _ r: Int, _ c: Int) {
        for dr in 0..<s.height {
            for dc in 0..<s.width {
                if s[dr][dc] { cells[r+dr][c+dc] = false }
            }
        }
    }
    func canPlace(_ s: Shape, _ r: Int, _ c: Int) -> Bool {
        for dr in 0..<s.height {
            for dc in 0..<s.width {
                if s[dr][dc] {
                    let nr = r+dr, nc = c+dc
                    if nr >= rows || nc >= cols || cells[nr][nc] { return false }
                }
            }
        }
        return true
    }
    var solved: Bool { cells.allSatisfy { $0.allSatisfy { $0 } } }
    var firstEmpty: (Int, Int)? {
        for r in 0..<rows {
            for c in 0..<cols {
                if !cells[r][c] { return (r, c) }
            }
        }
        return nil
    }
}

func solveStrict(_ board: inout Board, _ pieces: [PieceDef], used: inout [(String, Shape)]) -> Bool {
    if board.solved { return true }
    guard let (tr, tc) = board.firstEmpty else { return false }

    for (i, p) in pieces.enumerated() {
        var orientations = [p.shape]
        var curr = p.shape
        for _ in 0..<3 { curr = curr.rotatedCW(); if !orientations.contains(curr) { orientations.append(curr) } }
        
        // Filter out orientations that don't start with true! Because strict solver requires [0][0] == true to cover firstEmpty
        let strictOrientations = orientations.filter { $0[0][0] == true }
        
        for shape in strictOrientations {
            if board.canPlace(shape, tr, tc) {
                board.place(shape, tr, tc)
                used.append((p.id, shape))
                var np = pieces; np.remove(at: i)
                if solveStrict(&board, np, used: &used) { return true }
                board.remove(shape, tr, tc)
                used.removeLast()
            }
        }
    }
    return false
}

let pieces = [
    PieceDef(id:"p1", rows:[[1,1],[1,0]]),
    PieceDef(id:"p2", rows:[[1,1,1]]),
    PieceDef(id:"p3", rows:[[1,0],[1,1]]),
    PieceDef(id:"p4", rows:[[1,1]]),
    PieceDef(id:"p5", rows:[[1],[1],[1]])
]

var b1 = Board(rows: 4, cols: 4, dice: l1_dice)
var used: [(String, Shape)] = []
if solveStrict(&b1, pieces, used: &used) {
    print("Found strict solution for L1:")
    for u in used {
        print("\(u.0):")
        for r in 0..<u.1.height {
            print(u.1[r].map { $0 ? "1" : "0" }.joined(separator: ", "))
        }
    }
} else {
    print("No strict solution for L1")
}

let piecesL2 = [
    PieceDef(id:"p1", rows:[[1,1,1],[0,1,0]]),
    PieceDef(id:"p2", rows:[[1,1],[1,0]]),
    PieceDef(id:"p3", rows:[[1,0],[1,1],[0,1]]),
    PieceDef(id:"p4", rows:[[1,1,1,1]]),
    PieceDef(id:"p5", rows:[[1,1],[0,1]]),
    PieceDef(id:"p6", rows:[[1],[1],[1]]),
]
var b2 = Board(rows: 5, cols: 5, dice: [(0,4), (4,0), (1,2), (3,3)])
var used2: [(String, Shape)] = []
if solveStrict(&b2, piecesL2, used: &used2) {
    print("Found strict solution for L2:")
    for u in used2 {
        print("\(u.0):")
        for r in 0..<u.1.height { print(u.1[r].map { $0 ? "1" : "0" }.joined(separator: ", ")) }
    }
} else { print("No strict solution for L2") }

// Add L3, L4, L5 to check if ANY fail to have a strict solution
let piecesL3 = [
    PieceDef(id:"p1", rows:[[1,1],[0,1],[0,1]]),
    PieceDef(id:"p2", rows:[[1,1,1],[0,1,0]]),
    PieceDef(id:"p3", rows:[[1,0],[1,1],[1,0]]),
    PieceDef(id:"p4", rows:[[0,1],[1,1],[1,0]]),
    PieceDef(id:"p5", rows:[[1],[1],[1],[1]]),
    PieceDef(id:"p6", rows:[[1,1,1]]),
    PieceDef(id:"p7", rows:[[1,1],[1,0]]),
    PieceDef(id:"p8", rows:[[1,1,1]]),
]
var b3 = Board(rows: 6, cols: 6, dice: [(1,0), (2,4), (3,1), (3,3), (4,4), (5,0), (5,1)])
var used3: [(String, Shape)] = []
if solveStrict(&b3, piecesL3, used: &used3) {
    print("Found strict solution for L3!")
    for u in used3 {
        print("\(u.0):")
        for r in 0..<u.1.height { print(u.1[r].map { $0 ? "1" : "0" }.joined(separator: ", ")) }
    }
} else { print("No strict solution for L3") }

let piecesL4 = [
    PieceDef(id:"p1", rows:[[1,1,1]]),
    PieceDef(id:"p2", rows:[[1,1],[1,0]]),
    PieceDef(id:"p3", rows:[[0,1],[1,1],[1,0]]),
    PieceDef(id:"p4", rows:[[1,0],[1,1],[0,1]]),
    PieceDef(id:"p5", rows:[[1,1,1],[0,0,1]]),
    PieceDef(id:"p6", rows:[[1,1]]),
]
var b4 = Board(rows: 5, cols: 5, dice: [(0,0), (1,1), (2,2), (3,3), (4,4)])
var used4: [(String, Shape)] = []
if solveStrict(&b4, piecesL4, used: &used4) {
    print("Found strict solution for L4!")
    for u in used4 {
        print("\(u.0):")
        for r in 0..<u.1.height { print(u.1[r].map { $0 ? "1" : "0" }.joined(separator: ", ")) }
    }
} else { print("No strict solution for L4") }

let piecesL5 = [
    PieceDef(id:"p1", rows:[[1,1],[1,0]]),
    PieceDef(id:"p2", rows:[[1,1,1],[0,1,0]]),
    PieceDef(id:"p3", rows:[[1,0],[1,1],[1,0]]),
    PieceDef(id:"p4", rows:[[1,1,1,1]]),
    PieceDef(id:"p5", rows:[[1,1],[0,1],[0,1]]),
    PieceDef(id:"p6", rows:[[1,1,1]]),
    PieceDef(id:"p7", rows:[[1,1],[1,0]]),
    PieceDef(id:"p8", rows:[[1,0],[1,1]]),
    PieceDef(id:"p9", rows:[[1],[1]]),
]
var b5 = Board(rows: 6, cols: 6, dice: [(0,0), (0,5), (2,2), (2,3), (5,0), (5,5)])
var used5: [(String, Shape)] = []
if solveStrict(&b5, piecesL5, used: &used5) {
    print("Found strict solution for L5!")
    for u in used5 {
        print("\(u.0):")
        for r in 0..<u.1.height { print(u.1[r].map { $0 ? "1" : "0" }.joined(separator: ", ")) }
    }
} else { print("No strict solution for L5") }
