import SwiftUI

struct LevelSelectView: View {

    @Environment(AppViewModel.self) private var appVM
    @State private var showResetConfirmation = false

    private let sections: [(label: String, sub: String, range: ClosedRange<Int>)] = [
        ("Tutorial",    "Free · No rotation",   1...5),
        ("Beginner",    "Free · No rotation",   6...15),
        ("Rotation",    "Unlock required",      16...30),
        ("Advanced",    "Unlock required",      31...50),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Block Game")
                    .font(AppFont.title())
                    .foregroundStyle(Color.label1)
                    .tracking(-0.5)
                Text("50 hand-crafted levels")
                    .font(AppFont.body())
                    .foregroundStyle(Color.label3)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.lg)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    ForEach(sections, id: \.label) { sec in
                        sectionView(sec)
                    }

                    Spacer(minLength: 60)

                    HStack {
                        Spacer()
                        Button {
                            showResetConfirmation = true
                        } label: {
                            Text("Reset Progress")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.label4)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.sep, lineWidth: 0.5)
                                )
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 40)
            }
            .alert("Reset All Progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appVM.resetProgress()
                }
            } message: {
                Text("This will clear all completed levels and purchases. This cannot be undone.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.bg0)
    }

    @ViewBuilder
    private func sectionView(_ sec: (label: String, sub: String, range: ClosedRange<Int>)) -> some View {
        let allPaid = sec.range.lowerBound >= 16
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sec.label)
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.label1)
                    Text(sec.sub)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.label3)
                }
                Spacer()
                if allPaid && !appVM.isUnlocked {
                    Button("Unlock") { appVM.screen = .paywall }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentBlue)
                }
            }

            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(sec.range, id: \.self) { lvl in
                    let def = LevelCatalogue.all.first(where: { $0.id == lvl })
                    let isLocked = (def?.isFree == false) && !appVM.isUnlocked
                    LevelCell(
                        number: lvl,
                        isDone: appVM.completedIDs.contains(lvl),
                        isNext: isNextLevel(lvl, locked: isLocked),
                        isLocked: isLocked,
                        hasLevel: def != nil
                    )
                    .onTapGesture {
                        guard let def else { return }
                        if def.isFree || appVM.isUnlocked {
                            appVM.startLevel(lvl)
                        } else {
                            appVM.screen = .paywall
                        }
                    }
                }
            }
        }
    }

    private func isNextLevel(_ lvl: Int, locked: Bool) -> Bool {
        guard !locked else { return false }
        let maxDone = appVM.completedIDs.max() ?? 0
        return !appVM.completedIDs.contains(lvl) && lvl == maxDone + 1
    }
}

private struct LevelCell: View {
    let number: Int
    let isDone: Bool
    let isNext: Bool
    let isLocked: Bool
    let hasLevel: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(border, lineWidth: isNext ? 1 : 0.5)
                )
                .shadow(color: isNext ? Color.accentBlue.opacity(0.15) : .clear, radius: 8)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.label4)
            } else {
                VStack(spacing: 2) {
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(labelColor)
                    if isDone {
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(Color.accentYellow)
                            }
                        }
                    }
                }
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.accentGreen)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(5)
                }
                if isNext {
                    Circle()
                        .fill(Color.accentBlue)
                        .frame(width: 6, height: 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if isLocked { return "Level \(number), locked" }
        if isDone   { return "Level \(number), completed" }
        if isNext   { return "Level \(number), next" }
        return "Level \(number)"
    }

    private var background: Color {
        if isDone   { return Color.accentGreen.opacity(0.10) }
        if isNext   { return Color.accentBlue.opacity(0.10) }
        if isLocked { return Color.bg1 }
        return Color.bg2
    }
    private var border: Color {
        if isNext   { return Color.accentBlue.opacity(0.5) }
        if isDone   { return Color.accentGreen.opacity(0.25) }
        return Color.sep
    }
    private var labelColor: Color {
        if isDone   { return Color.accentGreen }
        if isNext   { return Color.accentBlue }
        if hasLevel { return Color.label2 }
        return Color.label4
    }
}
