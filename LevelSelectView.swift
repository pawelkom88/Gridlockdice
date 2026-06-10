import SwiftUI

struct LevelSelectView: View {

    @Environment(AppViewModel.self) private var appVM

    private let sections: [(label: String, sub: String, range: ClosedRange<Int>, locked: Bool)] = [
        ("Tutorial", "Free · No rotation",  1...5,   false),
        ("Beginner", "Free · No rotation",  6...15,  false),
        ("Rotation", "Unlock required",     16...30, true ),
        ("Advanced", "Unlock required",     31...50, true ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Title bar
            VStack(alignment: .leading, spacing: 5) {
                Text("Gridlock Dice")
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

            // ── Level grid
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    ForEach(sections, id: \.label) { sec in
                        sectionView(sec)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.bg0)
    }

    // MARK: - Section
    @ViewBuilder
    private func sectionView(_ sec: (label: String, sub: String, range: ClosedRange<Int>, locked: Bool)) -> some View {
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
                if sec.locked {
                    Button("Unlock →") { appVM.screen = .paywall }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentBlue)
                }
            }

            // 5-column grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(sec.range, id: \.self) { lvl in
                    LevelCell(
                        number:    lvl,
                        isDone:    appVM.completedIDs.contains(lvl),
                        isNext:    isNextLevel(lvl, locked: sec.locked),
                        isLocked:  sec.locked,
                        hasLevel:  LevelCatalogue.all.contains(where: { $0.id == lvl })
                    )
                    .onTapGesture {
                        if sec.locked { appVM.screen = .paywall; return }
                        if LevelCatalogue.all.contains(where: { $0.id == lvl }) {
                            appVM.startLevel(lvl)
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

// MARK: - Level cell
private struct LevelCell: View {

    let number:   Int
    let isDone:   Bool
    let isNext:   Bool
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
    }

    private var background: Color {
        if isDone  { return Color.accentGreen.opacity(0.10) }
        if isNext  { return Color.accentBlue.opacity(0.10) }
        if isLocked{ return Color.bg1 }
        return Color.bg2
    }

    private var border: Color {
        if isNext  { return Color.accentBlue.opacity(0.5) }
        if isDone  { return Color.accentGreen.opacity(0.25) }
        return Color.sep
    }

    private var labelColor: Color {
        if isDone  { return Color.accentGreen }
        if isNext  { return Color.accentBlue }
        if hasLevel{ return Color.label2 }
        return Color.label4
    }
}
