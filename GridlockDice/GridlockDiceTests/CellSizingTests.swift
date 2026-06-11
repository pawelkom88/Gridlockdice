import XCTest
@testable import GridlockDice

final class CellSizingTests: XCTestCase {

    private let calc = CellSizingCalculator()

    // MARK: - Small board fits phone

    func testCellSizeForSmallBoardWithinPortraitPhone() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 350, height: 400))
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, calc.maxCellSize)
    }

    func testCellSizeForLargeBoardFitsInPortraitPhone() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 350, height: 500))
        XCTAssertGreaterThan(size, 0)
    }

    // MARK: - Size limits

    func testCellSizeNeverExceedsMaximum() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 1000, height: 1000))
        XCTAssertLessThanOrEqual(size, calc.maxCellSize)
    }

    func testCellSizeIsAlwaysPositive() {
        let size = calc.compute(rows: 2, cols: 2, availableSize: CGSize(width: 10, height: 10))
        XCTAssertGreaterThan(size, 0)
    }

    // MARK: - Layout constraints

    func testBoardFitsHorizontalSpace() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 350, height: 400))
        let totalW = size * 4 + calc.gap * 3 + calc.labelWidth
        XCTAssertLessThanOrEqual(totalW, 350)
    }

    func testBoardFitsVerticalSpace() {
        let size = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 350, height: 400))
        let totalH = size * 4 + calc.gap * 3 + calc.colLabelHeight
        XCTAssertLessThanOrEqual(totalH, 400)
    }

    // MARK: - Relative sizing

    func testWiderBoardGetsSmallerCells() {
        let size4 = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 350, height: 400))
        let size6 = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 350, height: 400))
        XCTAssertLessThan(size6, size4)
    }

    func testTallerBoardGetsSmallerCells() {
        let size4 = calc.compute(rows: 4, cols: 4, availableSize: CGSize(width: 350, height: 400))
        let size6 = calc.compute(rows: 6, cols: 4, availableSize: CGSize(width: 350, height: 400))
        XCTAssertLessThan(size6, size4)
    }

    // MARK: - iPad sizing

    func testCellSizeForLargeBoardFitsInPadLandscape() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 900, height: 600))
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, calc.maxCellSize)
    }

    func testCellSizeRespectsCustomMax() {
        let size = calc.compute(rows: 6, cols: 6, availableSize: CGSize(width: 900, height: 600), maxCellSize: 120)
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, 120)
        XCTAssertGreaterThan(size, calc.maxCellSize, "Custom max should allow larger cells than default")
    }
}
