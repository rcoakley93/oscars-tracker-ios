import SwiftUI

/// Ceremony Night design tokens (docs/design/brand.md in the backend repo).
///
/// Colours are colour sets in `Resources/Assets.xcassets` with dark and light
/// values, so Xcode generates `Color.ground`, `.ink`, `.inkMuted`, `.gold`,
/// `.goldText`, `.goldOnGlass`, `.velvet`, `.success`, `.warning`, `.danger`
/// and the rest, usable as `.foregroundStyle(.inkMuted)`.
///
/// - `gold` is earned: progress, your picks, wins. `goldText` is for small
///   gold text on solid surfaces; `goldOnGlass` for small gold text on glass
///   or the ambient backdrop (both reach 4.5:1).
/// - `velvet` is for Oscar night only: the envelope and the red carpet.
enum Theme {
    /// Continuous corner radii. Nested shapes are concentric: inner radius =
    /// outer radius minus the padding between them.
    enum Radius {
        static let thumbnail: CGFloat = 8
        static let tile: CGFloat = 14
        static let row: CGFloat = 16
        static let card: CGFloat = 22
        static let hero: CGFloat = 28
        static let sheet: CGFloat = 32
    }

    /// A 4-point spacing scale.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// The gold gradient, for the hero number and the film strip: never decoration.
    static let goldGradient = LinearGradient(
        colors: [.goldStart, .goldMid, .goldEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// A continuous rounded rectangle at one of the radii above.
    static func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

// MARK: - Type

extension View {
    /// Display type: SF Pro Rounded, bold, for screen titles, big numbers and the hero.
    func displayFont(_ style: Font.TextStyle = .largeTitle) -> some View {
        font(.system(style, design: .rounded, weight: .bold))
    }

    /// The small uppercase label above a title ("99TH ACADEMY AWARDS").
    func eyebrowStyle() -> some View {
        font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(.goldOnGlass)
    }
}

// MARK: - Surfaces

extension View {
    /// The solid surface for content: rows, cards and anything in a long list.
    /// Glass is only for the layer that floats (bars, the hero, sheets).
    func solidSurface(radius: CGFloat = Theme.Radius.card) -> some View {
        background(.surface, in: Theme.shape(radius))
            .overlay(Theme.shape(radius).strokeBorder(.hairline.opacity(0.6), lineWidth: 0.5))
    }

    /// A text field's well: padded, on `raised` so it reads against `ground`
    /// in both appearances. Replaces `.roundedBorder`, which is flat black in
    /// dark mode with its text against the edge.
    func fieldSurface() -> some View {
        padding(.horizontal, Theme.Space.m)
            .padding(.vertical, Theme.Space.s)
            .frame(minHeight: 48)
            .background(.raised, in: Theme.shape(Theme.Radius.tile))
            .overlay(Theme.shape(Theme.Radius.tile).strokeBorder(.hairline, lineWidth: 0.5))
    }
}
