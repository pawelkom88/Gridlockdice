import CoreGraphics

struct CellSizingCalculator {
    let gap: CGFloat = 4
    let labelWidth: CGFloat = 22
    let colLabelHeight: CGFloat = 28
    let maxCellSize: CGFloat = 84

    func compute(rows: Int, cols: Int, availableSize: CGSize) -> CGFloat {
        let availW = availableSize.width - labelWidth - CGFloat(cols - 1) * gap
        let availH = availableSize.height - colLabelHeight - CGFloat(rows - 1) * gap
        let byW = floor(availW / CGFloat(cols))
        let byH = floor(availH / CGFloat(rows))
        return max(1, min(byW, byH, maxCellSize))
    }
}
