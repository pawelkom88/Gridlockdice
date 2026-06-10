import SwiftUI

struct CompletionView: View {
    @Environment(AppViewModel.self) private var appVM
    let levelID: Int
    let elapsed: TimeInterval

    var body: some View {
        VStack(spacing: 20) {
            Text("Solved")
                .font(AppFont.large())
                .foregroundStyle(Color.label1)

            Text("Level \(levelID)")
                .font(AppFont.headline())
                .foregroundStyle(Color.label3)

            HStack(spacing: 12) {
                Button("All Levels") {
                    appVM.screen = .levelSelect
                }
                Button("Next Level") {
                    appVM.goToNextLevel(after: levelID)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg0)
    }
}
