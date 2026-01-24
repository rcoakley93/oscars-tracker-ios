import SwiftUI

extension Color {
    // Backgrounds
    static let appBackground = Color(hue: 0, saturation: 0, brightness: 0.05)
    static let cardBackground = Color(hue: 0, saturation: 0, brightness: 0.08)
    static let secondaryBackground = Color(hue: 0, saturation: 0, brightness: 0.12)

    // Gold Theme
    static let goldPrimary = Color(hue: 43/360, saturation: 0.74, brightness: 0.49)
    static let goldLight = Color(hue: 43/360, saturation: 0.74, brightness: 0.65)
    static let goldDark = Color(hue: 43/360, saturation: 0.74, brightness: 0.35)

    // Text
    static let textPrimary = Color(hue: 45/360, saturation: 0.20, brightness: 0.95)
    static let textMuted = Color(hue: 45/360, saturation: 0.10, brightness: 0.60)

    // Semantic
    static let destructive = Color(hue: 0, saturation: 0.62, brightness: 0.50)
    static let success = Color(hue: 142/360, saturation: 0.71, brightness: 0.45)
    static let borderColor = Color(hue: 0, saturation: 0, brightness: 0.18)

    // Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension LinearGradient {
    static let gold = LinearGradient(
        colors: [
            Color(hex: "#FDE68A"),
            Color(hex: "#EAB308"),
            Color(hex: "#FCD34D")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - View Extensions for iPad Support

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
