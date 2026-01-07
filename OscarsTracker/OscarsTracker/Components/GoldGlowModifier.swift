import SwiftUI

/// A modifier that adds a gold glow effect around a view.
/// Used to highlight important elements like selected items or achievements.
struct GoldGlowModifier: ViewModifier {
    var radius: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: Color.goldPrimary.opacity(opacity), radius: radius, x: 0, y: 0)
            .shadow(color: Color.goldPrimary.opacity(opacity * 0.5), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    /// Add a gold glow effect to the view
    /// - Parameters:
    ///   - radius: The blur radius of the glow (default: 8)
    ///   - opacity: The opacity of the glow effect (default: 0.6)
    func goldGlow(radius: CGFloat = 8, opacity: Double = 0.6) -> some View {
        modifier(GoldGlowModifier(radius: radius, opacity: opacity))
    }

    /// Add a subtle gold glow effect
    func goldGlowSubtle() -> some View {
        modifier(GoldGlowModifier(radius: 4, opacity: 0.3))
    }

    /// Add an intense gold glow effect
    func goldGlowIntense() -> some View {
        modifier(GoldGlowModifier(radius: 12, opacity: 0.8))
    }
}

/// A pulsing gold glow animation modifier
struct PulsingGoldGlowModifier: ViewModifier {
    @State private var isPulsing = false
    var minOpacity: Double = 0.3
    var maxOpacity: Double = 0.7
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.goldPrimary.opacity(isPulsing ? maxOpacity : minOpacity),
                radius: radius,
                x: 0,
                y: 0
            )
            .shadow(
                color: Color.goldPrimary.opacity(isPulsing ? maxOpacity * 0.5 : minOpacity * 0.5),
                radius: radius * 2,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Add a pulsing gold glow animation
    func pulsingGoldGlow(minOpacity: Double = 0.3, maxOpacity: Double = 0.7, radius: CGFloat = 8) -> some View {
        modifier(PulsingGoldGlowModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, radius: radius))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.goldPrimary)
                .goldGlow()

            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.goldPrimary)
                .goldGlowSubtle()

            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.goldPrimary)
                .goldGlowIntense()

            Image(systemName: "medal.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.goldPrimary)
                .pulsingGoldGlow()

            Text("Golden Text")
                .font(.displayMedium)
                .foregroundStyle(Color.goldPrimary)
                .goldGlow(radius: 6, opacity: 0.5)
        }
    }
    .preferredColorScheme(.dark)
}
