import SwiftUI

struct BoardGridView: View {

    @Environment(GameViewModel.self) private var vm
    let cellSize: CGFloat

    private let GAP: CGFloat = 4
    private let LBL: CGFloat = 22
    private let ROWS = Array("ABCDEFGHIJ")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: GAP) {
                Spacer().frame(width: LBL)
                ForEach(0..<vm.level.cols, id: \.self) { c in
                    Text("\(c + 1)")
                        .font(AppFont.mono())
                        .foregroundStyle(Color.label1)
                        .frame(width: cellSize)
                }
            }
            .padding(.bottom, 5)

            VStack(spacing: GAP) {
                ForEach(0..<vm.level.rows, id: \.self) { r in
                    HStack(spacing: GAP) {
                        Text(String(ROWS[r]))
                            .font(AppFont.mono())
                            .foregroundStyle(Color.label1)
                            .frame(width: LBL)

                        ForEach(0..<vm.level.cols, id: \.self) { c in
                            BoardCellView(row: r, col: c, cellSize: cellSize)
                                .environment(vm)
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.28, dampingFraction: 0.82).delay(Double(r) * 0.03), value: vm.level.id)
                }
            }
        }
    }
}
