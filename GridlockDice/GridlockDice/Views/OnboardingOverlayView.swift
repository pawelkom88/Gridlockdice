import SwiftUI

struct OnboardingOverlayView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(GameViewModel.self) private var vm
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Semi-transparent backdrop blur
            Color.black.opacity(0.70)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 0) {
                // Card Container
                VStack(spacing: 0) {
                    // Header with Skip Button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.label4)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }
                    }

                    // Content Carousel
                    TabView(selection: $currentPage) {
                        slideOne
                            .tag(0)
                        slideTwo
                            .tag(1)
                        slideThree
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 400)

                    // Page Indicator & Action Button
                    VStack(spacing: 16) {
                        // Dot indicators
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.accentBlue : Color.label4.opacity(0.5))
                                    .frame(width: 7, height: 7)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: currentPage)
                            }
                        }
                        .padding(.top, 8)

                        // CTA Button
                        Button {
                            if currentPage < totalPages - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text(currentPage == totalPages - 1 ? "Let's Play" : "Next")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.accentBlue)
                                )
                                .shadow(color: Color.accentBlue.opacity(0.35), radius: 6, y: 3)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.bg1)
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.sepStrong, lineWidth: 1)
                )
                .padding(.horizontal, 28)
            }
        }
    }

    private func dismiss() {
        appVM.hasSeenOnboarding = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            vm.showOnboarding = false
        }
    }

    // MARK: - Slide 1: Core Objective
    private var slideOne: some View {
        VStack(spacing: 16) {
            // Header icon/illustration
            ZStack {
                Circle()
                    .fill(Color.accentBlue.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentBlue)
            }

            VStack(spacing: 6) {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Gridlock" + " " + "Dice")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.label1)
                Text("THE OBJECTIVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentBlue)
                    .tracking(1.2)
            }

            Text("Fill all empty cells on the board with your colorful pieces to solve the puzzle.")
                .font(.system(size: 14))
                .foregroundStyle(Color.label3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Warning block callout
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.sep, lineWidth: 0.5)
                    )

                Text("White cells represent pre-placed blockages (dice). These act as walls and cannot be moved or covered.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.label3)
                    .lineLimit(3)
            }
            .padding(12)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Slide 2: Drag, Drop & Anchor
    private var slideTwo: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "hand.and.arrow.leading.and.trailing")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentGreen)
            }

            VStack(spacing: 6) {
                Text("Drag to Place")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.label1)
                Text("PLACEMENT RULES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentGreen)
                    .tracking(1.2)
            }

            Text("Drag pieces from the tray. Watch the cells highlight as you hover over the board:")
                .font(.system(size: 14))
                .foregroundStyle(Color.label3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle().fill(Color.accentGreen).frame(width: 8, height: 8)
                    Text("Green overlay indicates a valid placement.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.label2)
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.accentRed).frame(width: 8, height: 8)
                    Text("Red overlay indicates blocked or overlapping space.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.label2)
                }
            }
            .padding(.horizontal, 28)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentBlue)
                    .frame(width: 22, alignment: .center)
                Text("Rotation becomes available starting at level 21")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.accentBlue)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.accentBlue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.accentBlue.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            // Crucial: The Top-Left Anchor Explanation
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentYellow)
                    .frame(width: 22, alignment: .center)

                Text("Tip: Dragging anchors the top-left corner of the block under your finger. Position your finger over the starting cell.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.accentYellow)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.accentYellow.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.accentYellow.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Slide 3: Swipable Tray, Tap to Rotate, and Remove
    private var slideThree: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentPurple)
            }

            VStack(spacing: 6) {
                Text("Tap & Swipe")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.label1)
                Text("EXTRA CONTROLS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentPurple)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentBlue)
                        .frame(width: 20)
                    Text("Swipe the footer left/right to scroll through and select different blocks.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.label3)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentOrange)
                        .frame(width: 20)
                    Text("Tap a piece in the tray to rotate it clockwise (on rotation levels).")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.label3)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentGreen)
                        .frame(width: 20)
                    Text("Tap any block on the board to return it back to your tray.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.label3)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentYellow)
                        .frame(width: 20)
                    Text("Stuck? Tap the lightbulb for a hint. One hint available per level.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.label3)
                }
            }
            .padding(.horizontal, 28)
        }
    }
}
