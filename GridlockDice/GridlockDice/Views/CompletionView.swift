import SwiftUI

struct CompletionView: View {
    @Environment(AppViewModel.self) private var appVM
    let levelID: Int
    let elapsed: TimeInterval

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        VStack(spacing: isPad ? 40 : 20) {
            Text("Solved")
                .font(.system(size: isPad ? 72 : 36, weight: .bold))
                .foregroundStyle(Color.label1)

            Text("Level \(levelID)")
                .font(.system(size: isPad ? 36 : 18, weight: .bold))
                .foregroundStyle(Color.label3)

            HStack(spacing: isPad ? 24 : 12) {
                Button("All Levels") {
                    appVM.screen = .levelSelect
                }
                .font(.system(size: isPad ? 34 : 17, weight: .bold))

                Button("Next Level") {
                    appVM.goToNextLevel(after: levelID)
                }
                .font(.system(size: isPad ? 34 : 17, weight: .bold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg0)
    }
}
