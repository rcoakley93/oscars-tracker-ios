import SwiftUI

/// Ambient light behind a screen (P3-06, screens.md section 2): a 3×3 mesh
/// gradient over the ground, coloured from the posters on screen and
/// drifting over about a minute. With no posters it uses the theatre
/// palette (velvet, deep teal, deep green).
///
/// Text never sits on it directly, only on a solid surface or system glass.
/// It holds still under Reduce Motion, and it's the plain ground under
/// Reduce Transparency or Increase Contrast.
struct AmbientBackground: View {
    /// Poster URLs; up to four are used, spread through the list.
    var posters: [String] = []

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    @State private var palette: [Color] = []

    /// The theatre palette from the Oct 22 mockups, for screens with no posters.
    static let theatre: [Color] = [.velvet, Color(red: 0x1f / 255, green: 0x4c / 255, blue: 0x5c / 255), Color(red: 0x2f / 255, green: 0x5a / 255, blue: 0x3a / 255)]

    /// Up to `max` distinct URLs, spread evenly through the list.
    static func pick(_ urls: [String], max: Int = 4) -> [String] {
        let unique = Array(NSOrderedSet(array: urls.filter { !$0.isEmpty })) as? [String] ?? []
        let count = min(unique.count, max)
        guard count > 0 else { return [] }
        let step = Double(unique.count) / Double(count)
        return (0..<count).map { unique[Int(Double($0) * step)] }
    }

    var body: some View {
        ZStack {
            Color.ground
            if !reduceTransparency && contrast != .increased {
                TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
                    MeshGradient(width: 3, height: 3,
                                 points: Self.points(at: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate),
                                 colors: Self.colors(palette.isEmpty ? Self.theatre : palette))
                }
                .opacity(colorScheme == .dark ? 0.35 : 0.25)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .backgroundExtensionEffect()
        .accessibilityHidden(true)
        .task(id: Self.pick(posters)) {
            let urls = Self.pick(posters).compactMap(URL.init(string:))
            let colors = await PosterPalette.shared.colors(for: urls)
            withAnimation(.smooth(duration: 0.8)) { palette = colors }
        }
    }

    /// The mesh's nine points. The corners stay put; the four edge midpoints
    /// slide along their edges and the centre wanders, each on its own sine
    /// over about 60 seconds, by at most 0.06.
    nonisolated static func points(at time: TimeInterval) -> [SIMD2<Float>] {
        func drift(_ phase: Double) -> Float {
            Float(0.06 * sin(time * 2 * .pi / 60 + phase))
        }
        return [
            [0, 0], [0.5 + drift(0), 0], [1, 0],
            [0, 0.5 + drift(1.3)], [0.5 + drift(2.1), 0.5 + drift(3.7)], [1, 0.5 + drift(4.4)],
            [0, 1], [0.5 + drift(5.2), 1], [1, 1],
        ]
    }

    /// Nine colours from up to four: the palette on the corners and centre
    /// it reaches, the ground everywhere else.
    static func colors(_ palette: [Color]) -> [Color] {
        var colors = Array(repeating: Color.ground, count: 9)
        for (slot, index) in [0, 8, 4, 2].enumerated() where !palette.isEmpty {
            colors[index] = palette[slot % palette.count]
        }
        return colors
    }
}

#Preview("Theatre, dark") {
    AmbientBackground().preferredColorScheme(.dark)
}

#Preview("Theatre, light") {
    AmbientBackground().preferredColorScheme(.light)
}

#Preview("Posters") {
    AmbientBackground(posters: SampleData.movies.compactMap(\.posterUrl)).preferredColorScheme(.dark)
}
