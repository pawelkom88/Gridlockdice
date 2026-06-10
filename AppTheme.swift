import SwiftUI

// MARK: - Colours
// All values map 1:1 from the React design token object T {}
extension Color {

    // Backgrounds
    static let bg0 = Color(hex: "#000000")   // pure black canvas
    static let bg1 = Color(hex: "#1c1c1e")   // tray shelf / elevated surface
    static let bg2 = Color(hex: "#2c2c2e")   // cells, cards, buttons
    static let bg3 = Color(hex: "#3a3a3c")   // tertiary fill

    // Separators
    static let sep       = Color.white.opacity(0.12)
    static let sepStrong = Color.white.opacity(0.20)

    // Labels
    static let label1 = Color.white
    static let label2 = Color.white
    static let label3 = Color.white.opacity(0.75)
    static let label4 = Color.white.opacity(0.38)

    // System fills (translucent)
    static let fill2 = Color(red: 0.47, green: 0.47, blue: 0.50).opacity(0.24)
    static let fill3 = Color(red: 0.46, green: 0.46, blue: 0.50).opacity(0.22)

    // Accents — map directly to iOS system palette
    static let accentBlue   = Color(hex: "#0a84ff")
    static let accentGreen  = Color(hex: "#30d158")
    static let accentYellow = Color(hex: "#ffd60a")
    static let accentOrange = Color(hex: "#ff9f0a")
    static let accentRed    = Color(hex: "#ff453a")
    static let accentPurple = Color(hex: "#bf5af2")

    // Hex initialiser
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Piece colours
struct PieceColor {
    let fill:   Color
    let shadow: Color
    let border: Color
}

enum PieceColorName: String, CaseIterable {
    case red, orange, yellow, green, teal, blue, purple, pink

    var style: PieceColor {
        switch self {
        case .red:    return PieceColor(fill: Color(hex:"#ff453a"), shadow: Color(hex:"#ff453a").opacity(0.45), border: Color(hex:"#ff6e64").opacity(0.7))
        case .orange: return PieceColor(fill: Color(hex:"#ff9f0a"), shadow: Color(hex:"#ff9f0a").opacity(0.45), border: Color(hex:"#ffc33c").opacity(0.7))
        case .yellow: return PieceColor(fill: Color(hex:"#ffd60a"), shadow: Color(hex:"#ffd60a").opacity(0.40), border: Color(hex:"#ffeb46").opacity(0.7))
        case .green:  return PieceColor(fill: Color(hex:"#30d158"), shadow: Color(hex:"#30d158").opacity(0.45), border: Color(hex:"#50e66e").opacity(0.7))
        case .teal:   return PieceColor(fill: Color(hex:"#5ac8fa"), shadow: Color(hex:"#5ac8fa").opacity(0.45), border: Color(hex:"#82dcff").opacity(0.7))
        case .blue:   return PieceColor(fill: Color(hex:"#0a84ff"), shadow: Color(hex:"#0a84ff").opacity(0.45), border: Color(hex:"#46a5ff").opacity(0.7))
        case .purple: return PieceColor(fill: Color(hex:"#bf5af2"), shadow: Color(hex:"#bf5af2").opacity(0.45), border: Color(hex:"#d782ff").opacity(0.7))
        case .pink:   return PieceColor(fill: Color(hex:"#ff375f"), shadow: Color(hex:"#ff375f").opacity(0.45), border: Color(hex:"#ff6e8c").opacity(0.7))
        }
    }
}

// MARK: - Spacing
enum Spacing {
    static let xxs: CGFloat = 3
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 28
}

// MARK: - Typography
// React used SF Pro natively via -apple-system; SwiftUI uses .system font automatically.
// Weight mapping: fontWeight 700/800 → .bold, 600 → .semibold, 500 → .medium
enum AppFont {
    static func title()      -> Font { .system(size: 30, weight: .bold,     design: .default) }
    static func headline()   -> Font { .system(size: 18, weight: .bold,     design: .default) }
    static func subheadline()-> Font { .system(size: 15, weight: .semibold, design: .default) }
    static func body()       -> Font { .system(size: 14, weight: .regular,  design: .default) }
    static func caption()    -> Font { .system(size: 11, weight: .semibold, design: .default) }
    static func mono()       -> Font { .system(size: 12, weight: .semibold, design: .monospaced) }
    static func large()      -> Font { .system(size: 36, weight: .bold,     design: .default) }
    static func stat()       -> Font { .system(size: 24, weight: .bold,     design: .default) }
}

// MARK: - Corner radii
enum Radius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 14
    static let xl:  CGFloat = 18
    static let cell: CGFloat = 10   // board cells, computed in view
}
