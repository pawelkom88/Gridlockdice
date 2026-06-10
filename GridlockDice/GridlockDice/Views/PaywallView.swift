import SwiftUI

struct PaywallView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isPurchasing = false
    @State private var isRestoring = false

    private let features: [(icon: String, color: Color, title: String, detail: String)] = [
        ("chart.bar.fill",      Color.accentBlue,   "35 more levels",      "Rotation mechanics, larger grids, five challenge levels"),
        ("nosign",              Color.accentRed,    "Zero ads, ever",      "Pure focus. No interruptions, no upsells after this"),
        ("clock.fill",          Color.accentGreen,  "One-time purchase",   "Pay once, own it forever. No subscription required"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Button("< Back") {
                            appVM.screen = .levelSelect
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentBlue)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.lg)

                    Text("Unlock the full game")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.label1)
                        .tracking(-0.5)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)

                    Text("35 more levels. No subscriptions.\nNo ads. Ever.")
                        .font(AppFont.body())
                        .foregroundStyle(Color.label3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, 28)

                    VStack(spacing: 0) {
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
                    .padding(.bottom, 24)
                }
            }

            ctaBar
        }
        .background(Color.bg0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await appVM.loadProduct()
        }
    }

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
        .padding(.vertical, 14)
    }

    private var ctaBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.sep)

            VStack(spacing: 14) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(appVM.priceText)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color.label1)
                        .tracking(-0.6)
                    Text("one-time\npayment")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.label3)
                        .lineSpacing(2)
                        .padding(.bottom, 4)
                }

                Button {
                    isPurchasing = true
                    Task {
                        _ = try? await appVM.purchase()
                        isPurchasing = false
                    }
                } label: {
                    Text(isPurchasing ? "Purchasing..." : "Unlock All 50 Levels")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPurchasing || isRestoring)

                Button {
                    isRestoring = true
                    Task {
                        _ = try? await appVM.restore()
                        isRestoring = false
                    }
                } label: {
                    Text(isRestoring ? "Restoring..." : "Restore Purchase")
                }
                .font(.system(size: 12))
                .foregroundStyle(Color.label4)
                .disabled(isPurchasing || isRestoring)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 14)
            .padding(.bottom, 32)
            .background(Color.bg0)
        }
    }
}
