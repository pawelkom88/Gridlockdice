import SwiftUI

struct PaywallView: View {

    @Environment(AppViewModel.self) private var appVM

    private let sampleColors: [Color] = [
        Color(hex:"#ff453a"), Color(hex:"#ffd60a"), Color(hex:"#0a84ff"), Color(hex:"#30d158"),
        Color(hex:"#5ac8fa"), Color(hex:"#ff9f0a"), Color(hex:"#bf5af2"), Color(hex:"#ff375f"),
    ]
    // 6×6 preview board: index into sampleColors, nil = empty
    private let sampleBoard: [Int?] = [
        0,1,2,3,nil,nil,  4,5,6,7,0,1,  3,nil,4,5,6,nil,
        nil,1,nil,2,3,4,  5,6,7,0,nil,1, 2,3,4,5,nil,6,
    ]

    private let features: [(icon: String, color: Color, title: String, detail: String)] = [
        ("chart.bar.fill",      Color.accentBlue,   "35 more levels",      "Rotation mechanics, larger grids, five challenge levels"),
        ("nosign",              Color.accentRed,    "Zero ads, ever",      "Pure focus. No interruptions, no upsells after this"),
        ("clock.fill",          Color.accentGreen,  "One-time purchase",   "Pay once, own it forever. No subscription required"),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Scrollable body
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Back button
                    HStack {
                        Button("‹ Back") { appVM.screen = .levelSelect }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accentBlue)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 60)
                    .padding(.bottom, Spacing.lg)

                    // Mini board preview
                    miniBoard
                        .padding(.bottom, 24)

                    // Badge
                    Text("Free trial complete")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.accentYellow)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .padding(.bottom, 8)

                    // Headline
                    VStack(spacing: 4) {
                        Text("Unlock the full game")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.label1)
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)

                        Text("one-time payment")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.label3)
                            .tracking(0.3)
                    }
                    .padding(.bottom, 8)

                    // Sub
                    Text("35 more levels. No subscriptions.\nNo ads. Ever.")
                        .font(AppFont.body())
                        .foregroundStyle(Color.label3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, 20)

                    // Feature list
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(features.indices, id: \.self) { i in
                            let f = features[i]
                            featureRow(icon: f.icon, color: f.color, title: f.title, detail: f.detail)
                            if i < features.count - 1 {
                                Divider()
                                    .background(Color.sep)
                                    .padding(.leading, 54)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 4)
                }
            }

            // ── Sticky CTA
            ctaBar
        }
        .background(Color.bg0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Mini board
    private var miniBoard: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 4), count: 6), spacing: 4) {
            ForEach(sampleBoard.indices, id: \.self) { i in
                if let ci = sampleBoard[i] {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(sampleColors[ci % sampleColors.count])
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.bg3)
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.sep, lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(10)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.sep, lineWidth: 0.5)
        )
    }

    // MARK: - Feature row
    @ViewBuilder
    private func featureRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.bg2)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.label1)
                    .tracking(-0.2)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.label3)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    // MARK: - CTA bar
    private var ctaBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.sep)

            VStack(spacing: 14) {
                Text(appVM.priceText)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.label1)
                    .tracking(-0.6)

                Button("Unlock All 50 Levels") {
                    // In production: trigger StoreKit .purchase() here
                    appVM.unlock()
                }
                .buttonStyle(AccentButtonStyle())

                Button("Restore Purchase") {
                    // StoreKit restore
                }
                .font(.system(size: 12))
                .foregroundStyle(Color.label4)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 4)
            .padding(.bottom, 24)
            .background(Color.bg0)
        }
    }
}
