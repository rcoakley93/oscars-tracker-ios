import Kingfisher
import SwiftUI

/// Ambient light behind a screen (P3-06): a heavily blurred mosaic of the
/// posters on screen over the dark ground, with a theatre gradient (gold house
/// lights, velvet seats) underneath. Glass needs something rich to bend.
///
/// Text never sits on this directly without a solid or glass surface, and the
/// mosaic is dimmed so no poster can wash it out. With Reduce Transparency or
/// Increase Contrast it's just the plain ground.
struct AmbientBackground: View {
    /// Poster URLs; up to six are used, spread through the list.
    var posters: [String] = []

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    static func pick(_ urls: [String], max: Int = 6) -> [String] {
        let unique = Array(NSOrderedSet(array: urls.filter { !$0.isEmpty })) as? [String] ?? []
        let count = [6, 4, 3, 2, 1].first { $0 <= min(unique.count, max) } ?? 0
        guard count > 0 else { return [] }
        let step = Double(unique.count) / Double(count)
        return (0..<count).map { unique[Int(Double($0) * step)] }
    }

    var body: some View {
        ZStack {
            Color.ground
            if !reduceTransparency && contrast != .increased {
                theatre
                mosaic
                LinearGradient(colors: [.black.opacity(colorScheme == .dark ? 0.28 : 0), .ground.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var theatre: some View {
        ZStack {
            RadialGradient(colors: [.goldMid.opacity(0.10), .clear], center: UnitPoint(x: 0.5, y: -0.1), startRadius: 0, endRadius: 520)
            RadialGradient(colors: [.velvet.opacity(0.32), .clear], center: UnitPoint(x: 1, y: 1.05), startRadius: 0, endRadius: 460)
            RadialGradient(colors: [.velvet.opacity(0.18), .clear], center: UnitPoint(x: 0, y: 1), startRadius: 0, endRadius: 400)
        }
    }

    @ViewBuilder
    private var mosaic: some View {
        let picked = Self.pick(posters)
        if !picked.isEmpty {
            let columns = picked.count >= 5 ? 3 : (picked.count == 1 ? 1 : 2)
            GeometryReader { proxy in
                let rows = Int(ceil(Double(picked.count) / Double(columns)))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns), spacing: 0) {
                    ForEach(picked, id: \.self) { url in
                        KFImage(URL(string: url))
                            .resizable()
                            .fade(duration: 0.6)
                            .aspectRatio(contentMode: .fill)
                            .frame(height: proxy.size.height * 1.3 / CGFloat(rows))
                            .clipped()
                    }
                }
                .frame(width: proxy.size.width * 1.3)
                .offset(x: -proxy.size.width * 0.15, y: -proxy.size.height * 0.15)
            }
            // One blur over the whole mosaic; brightness caps how light a poster
            // can make the backdrop (the web contrast check, P3-11).
            .blur(radius: 64)
            .saturation(1.5)
            .brightness(colorScheme == .dark ? -0.2 : 0.15)
            .opacity(colorScheme == .dark ? 0.6 : 0.35)
            .drawingGroup()
        }
    }
}

#Preview("Theatre fallback") {
    AmbientBackground().preferredColorScheme(.dark)
}
