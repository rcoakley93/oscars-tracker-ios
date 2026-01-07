import SwiftUI

/// Manager for accessibility preferences and utilities.
struct AccessibilityManager {
    /// Check if Reduce Motion is enabled
    static var reduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Check if VoiceOver is running
    static var voiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Check if Bold Text is enabled
    static var boldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    /// Check if Reduce Transparency is enabled
    static var reduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    /// Get appropriate animation duration based on Reduce Motion setting
    static var animationDuration: Double {
        reduceMotionEnabled ? 0 : 0.25
    }
}

// MARK: - Reduce Motion View Extension

extension View {
    /// Apply animation conditionally based on Reduce Motion setting
    func accessibilityAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.animation(AccessibilityManager.reduceMotionEnabled ? nil : animation, value: value)
    }

    /// Apply animation that respects Reduce Motion setting
    func withReduceMotionAnimation() -> some View {
        self.animation(AccessibilityManager.reduceMotionEnabled ? nil : .easeInOut(duration: 0.25))
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Scaled body font that supports Dynamic Type
    static func scaledBody(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .default)
    }

    /// Scaled heading font that supports Dynamic Type
    static func scaledHeading(_ style: Font.TextStyle = .headline) -> Font {
        .system(style, design: .default, weight: .semibold)
    }
}

// MARK: - Accessibility Traits Helper

extension View {
    /// Mark view as a button for VoiceOver
    func accessibilityAsButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    /// Mark view as a header for VoiceOver
    func accessibilityAsHeader(_ label: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Mark view as a static text for VoiceOver
    func accessibilityAsStaticText(_ label: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Color Contrast

extension Color {
    /// Gold color with sufficient contrast for accessibility
    /// WCAG AA contrast ratio: 4.5:1 for normal text
    static let accessibleGold = Color(hue: 43/360, saturation: 0.80, brightness: 0.55)

    /// Check if color has sufficient contrast against background
    /// This is a simplified check - real implementation would calculate luminance
    static func hasGoodContrast(_ foreground: Color, against background: Color) -> Bool {
        // In practice, this would calculate WCAG contrast ratio
        // For now, this is a placeholder that assumes our design colors are accessible
        return true
    }
}

#Preview("Accessibility Demo") {
    VStack(spacing: 20) {
        Text("Reduce Motion: \(AccessibilityManager.reduceMotionEnabled ? "Enabled" : "Disabled")")
        Text("VoiceOver: \(AccessibilityManager.voiceOverRunning ? "Running" : "Not Running")")
        Text("Bold Text: \(AccessibilityManager.boldTextEnabled ? "Enabled" : "Disabled")")

        Text("Dynamic Type Support")
            .font(.scaledHeading())

        Text("This text scales with Dynamic Type")
            .font(.scaledBody())
    }
    .padding()
}
