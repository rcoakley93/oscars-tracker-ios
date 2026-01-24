import SwiftUI

/// A glass morphism style card component with blur and border effects.
/// Used for cards throughout the app to create a premium, glass-like appearance.
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base background with slight transparency
                    Color.cardBackground.opacity(0.8)

                    // Radial gradient overlay for depth
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 300
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

/// A modifier to apply glass card styling to any view
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding) {
            content
        }
    }
}

extension View {
    /// Apply glass card styling to a view
    func glassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.headingLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text("A premium glass-morphism effect")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)

            Text("Using modifier")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .glassCard()
                .padding(.horizontal)
        }
    }
    .preferredColorScheme(.dark)
}
