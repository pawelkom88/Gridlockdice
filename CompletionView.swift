import SwiftUI

struct CompletionView: View {

    @Environment(AppViewModel.self) private var appVM

    let levelID: Int
    let elapsed: TimeInterval

    // Phased reveal — matches React setTimeout phase sequence
    @State private var phase1 = false   // checkmark + title (0.1s)
    @State private var phase2 = false   // stars + stats    (0.52s)
    @State private var phase3 = false   // buttons          (0.96s)
    @State private var pulseGlow = false

    private var level: LevelDef? { LevelCatalogue.all.first(where: { $0.id == levelID }) }

    private var formattedTime: String {
        let t = Int(elapsed)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Checkmark
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .overlay(Circle().strokeBorder(Color.accentGreen.opacity(0.3), lineWidth: 0.5))
                    .shadow(color: pulseGlow ? Color.accentGreen.opacity(0.35) : .clear, radius: pulseGlow ? 18 : 0)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.8), value: pulseGlow)

                Text("✓")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.accentGreen)
            }
            .scaleEffect(phase1 ? 1.0 : 0.5)
            .opacity(phase1 ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: phase1)
            .padding(.bottom, 22)

            // ── Title
            Text("Solved")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.label1)
                .tracking(-0.6)
                .offset(y: phase1 ? 0 : 18)
                .opacity(phase1 ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.12), value: phase1)

            if let level {
                Text("Level \(level.id) · \(level.name)")
                    .font(AppFont.body())
                    .foregroundStyle(Color.label3)
                    .padding(.top, 5)
                    .offset(y: phase1 ? 0 : 14)
                    .opacity(phase1 ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.2), value: phase1)
            }

            // ── Stars
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.accentYellow)
                        .scaleEffect(phase2 ? 1.0 : 0.0)
                        .rotationEffect(.degrees(phase2 ? 0 : -20))
                        .opacity(phase2 ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(0.12 + Double(i) * 0.1),
                            value: phase2
                        )
                }
            }
            .padding(.top, 28)

            // ── Stat cards
            HStack(spacing: 12) {
                StatCard(value: formattedTime, label: "Time")
                StatCard(value: "\(levelID)/50",   label: "Progress")
            }
            .padding(.top, 28)
            .offset(y: phase2 ? 0 : 14)
            .opacity(phase2 ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.32), value: phase2)

            Spacer().frame(height: 36)

            // ── Action buttons
            HStack(spacing: 10) {
                Button("All Levels") {
                    appVM.screen = .levelSelect
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Next Level →") {
                    appVM.goToNextLevel(after: levelID)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .offset(y: phase3 ? 0 : 14)
            .opacity(phase3 ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: phase3)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { phase1 = true; pulseGlow = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) { phase2 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.96) { phase3 = true }
        }
    }
}

// MARK: - Stat card
private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(AppFont.stat())
                .foregroundStyle(Color.label1)
                .tracking(-0.6)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.label3)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(minWidth: 100)
        .padding(.vertical, 14)
        .padding(.horizontal, 26)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.sep, lineWidth: 0.5)
        )
    }
}

// MARK: - Button styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.vertical, 15)
            .padding(.horizontal, 28)
            .background(Color.accentGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.accentGreen.opacity(0.30), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.label2)
            .padding(.vertical, 15)
            .padding(.horizontal, 22)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.sep, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AccentButtonStyle: ButtonStyle {
    var color: Color = Color.accentBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
