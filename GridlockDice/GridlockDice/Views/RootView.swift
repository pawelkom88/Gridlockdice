import SwiftUI

struct RootView: View {

    @State private var appVM = AppViewModel(
        purchaseService: StoreKitPurchaseService()
    )
    @State private var isIphoneLandscape = false

    var body: some View {
        GeometryReader { geo in
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

                if isIphoneLandscape {
                    PortraitPromptView()
                        .transition(.opacity)
                }
            }
            .onAppear { checkOrientation(geo.size) }
            .onChange(of: geo.size) { _, newSize in checkOrientation(newSize) }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: screenKey)
    }

    private func checkOrientation(_ size: CGSize) {
        isIphoneLandscape = UIDevice.current.userInterfaceIdiom == .phone && size.width > size.height
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

private struct PortraitPromptView: View {
    var body: some View {
        Color.bg0
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 24) {
                    Image(systemName: "iphone.landscape")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.label4)
                        .rotationEffect(.degrees(-90))

                    Text("Rotate to Portrait")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.label1)

                    Text("This game is best played in portrait mode on iPhone.")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.label3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            )
    }
}
