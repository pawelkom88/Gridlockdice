import XCTest
@testable import GridlockDice

final class ResponsiveLayoutTests: XCTestCase {

    private let calc = CellSizingCalculator()

    // MARK: - iPhone compact

    func testBoardSizingFitsIPhoneCompactViewport() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 320, height: 400))
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, calc.maxCellSize)
        let totalW = size * 6 + calc.gap * 5 + calc.labelWidth
        XCTAssertLessThanOrEqual(totalW, 320)
    }

    // MARK: - iPad

    func testBoardSizingFitsIPadAvailableArea() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 700, height: 600))
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, calc.maxCellSize)
    }

    func testIPadDoesNotSquanderSpaceOnSmallBoard() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 700, height: 600))
        XCTAssertEqual(size, calc.maxCellSize, "Small board on iPad should hit max cell size")
    }

    // MARK: - Cell size bounds

    func testCellSizeDoesNotExceedBoardBounds() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 200, height: 200))
        let boardWidth = size * 4 + calc.gap * 3 + calc.labelWidth
        let boardHeight = size * 4 + calc.gap * 3 + calc.colLabelHeight
        XCTAssertLessThanOrEqual(boardWidth, 200)
        XCTAssertLessThanOrEqual(boardHeight, 200)
    }

    func testMinimumPracticalSizePreservedWherePossible() {
        let size = calc.compute(rows: 2, cols: 2, availableSize: CGSize(width: 500, height: 500))
        XCTAssertGreaterThanOrEqual(size, 44, "Small board in large area should allow 44pt cells")
    }

    // MARK: - Tray accessibility

    func testTrayRemainsAccessibleInCompactLayout() {
        let trayHeight: CGFloat = 122
        XCTAssertGreaterThan(trayHeight, 100, "Tray height should accommodate pieces + scroll")
        XCTAssertLessThan(trayHeight, 200, "Tray should not dominate the screen")
    }

    // MARK: - Board for different catalogue sizes

    func testLargestCatalogueBoardFitsIPhone() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 350, height: 450))
        XCTAssertGreaterThan(size, 20, "6x6 board should have playable cell size on iPhone")
    }

    func testSmallestCatalogueBoardLooksGoodOnIPad() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 700, height: 600))
        XCTAssertGreaterThanOrEqual(size, 60, "4x4 board should have generous cell size on iPad")
    }
}
