import SwiftUI

/// A gold gradient button style with press animation.
/// Used for primary action buttons throughout the app.
struct GoldButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headingMedium)
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient.gold

                    // Overlay for pressed state
                    if configuration.isPressed {
                        Color.black.opacity(0.15)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A secondary/outline button style with gold border
struct GoldOutlineButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headingMedium)
            .foregroundStyle(Color.goldLight)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.goldPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A destructive button style for delete/remove actions
struct DestructiveButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headingMedium)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                ZStack {
                    Color.destructive

                    if configuration.isPressed {
                        Color.black.opacity(0.15)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GoldButtonStyle {
    /// Primary gold gradient button style
    static var gold: GoldButtonStyle { GoldButtonStyle() }

    /// Gold button that fits its content width
    static var goldCompact: GoldButtonStyle { GoldButtonStyle(isFullWidth: false) }
}

extension ButtonStyle where Self == GoldOutlineButtonStyle {
    /// Secondary gold outline button style
    static var goldOutline: GoldOutlineButtonStyle { GoldOutlineButtonStyle() }

    /// Gold outline button that fits its content width
    static var goldOutlineCompact: GoldOutlineButtonStyle { GoldOutlineButtonStyle(isFullWidth: false) }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    /// Destructive red button style
    static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

/// A button style for Google OAuth authentication
struct GoogleAuthButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headingMedium)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GoogleAuthButtonStyle {
    /// Google OAuth button style with white background
    static var googleAuth: GoogleAuthButtonStyle { GoogleAuthButtonStyle() }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            Button("Sign In") {}
                .buttonStyle(.gold)

            Button("Create Account") {}
                .buttonStyle(.goldOutline)

            Button("Delete Account") {}
                .buttonStyle(.destructive)

            HStack(spacing: 12) {
                Button("Cancel") {}
                    .buttonStyle(.goldOutlineCompact)

                Button("Save") {}
                    .buttonStyle(.goldCompact)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
