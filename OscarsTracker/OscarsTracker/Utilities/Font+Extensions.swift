import SwiftUI

extension Font {
    // Display fonts - large titles (supports Dynamic Type via .largeTitle)
    static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let displayMedium = Font.system(.title, design: .rounded, weight: .bold)
    static let displaySmall = Font.system(.title2, design: .rounded, weight: .bold)

    // Heading fonts - section headers (supports Dynamic Type)
    static let headingLarge = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headingMedium = Font.system(.headline, weight: .semibold)
    static let headingSmall = Font.system(.subheadline, weight: .semibold)

    // Body fonts - regular text (supports Dynamic Type)
    static let bodyLarge = Font.system(.body, weight: .regular)
    static let bodyMedium = Font.system(.callout, weight: .regular)
    static let bodySmall = Font.system(.footnote, weight: .regular)

    // Caption fonts - small text (supports Dynamic Type)
    static let caption = Font.system(.caption, weight: .regular)
    static let captionSmall = Font.system(.caption2, weight: .regular)
}

// MARK: - Dynamic Type Scaling

extension View {
    /// Apply scaled font with minimum size for accessibility
    func scaledFont(_ font: Font, minimumScaleFactor: CGFloat = 0.75) -> some View {
        self
            .font(font)
            .minimumScaleFactor(minimumScaleFactor)
    }

    /// Apply dynamic line limit based on accessibility size
    func dynamicLineLimit(_ limit: Int, relaxedLimit: Int = 10) -> some View {
        self.lineLimit(limit...relaxedLimit)
    }
}
