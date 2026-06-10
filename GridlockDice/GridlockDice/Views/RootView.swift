import SwiftUI

struct RootView: View {

    @State private var appVM = AppViewModel(
        purchaseService: StoreKitPurchaseService()
    )

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()

            switch appVM.screen {

            case .levelSelect:
                LevelSelectView()
                    .environment(appVM)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity
                    ))

            case .game:
                if let vm = appVM.gameVM {
                    GameView()
                        .environment(appVM)
                        .environment(vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }

            case .paywall:
                PaywallView()
                    .environment(appVM)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

            case .completion(let levelID, let elapsed):
                CompletionView(levelID: levelID, elapsed: elapsed)
                    .environment(appVM)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: screenKey)
    }

    private var screenKey: String {
        switch appVM.screen {
        case .levelSelect:           return "levels"
        case .game(let id):          return "game-\(id)"
        case .paywall:               return "paywall"
        case .completion(let id, _): return "completion-\(id)"
        }
    }
}
