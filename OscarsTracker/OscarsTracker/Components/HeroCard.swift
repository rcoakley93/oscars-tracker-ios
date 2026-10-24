import SwiftUI

/// The top of Films (screens.md, section 2): how many films you've watched,
/// in gold, the voice's line, a film strip of every nominee and two figures.
/// The screen's one custom glass; a solid surface under Reduce Transparency
/// or Increase Contrast.
struct HeroCard: View {
    let watched: Int
    let total: Int
    /// Whole days to the ceremony, nil once it's past.
    let daysLeft: Int?

    @Environment(\.copy) private var copy
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Text("\(watched)")
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.goldGradient)
                    .contentTransition(.numericText(value: Double(watched)))
                Text("of \(total) films")
                    .font(.title3.bold()).fontDesign(.rounded)
                    .foregroundStyle(.ink)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(watched) of \(total) films watched")

            Text(watched == total && total > 0 ? copy.allWatched : copy.progressSummary(watched, total))
                .font(.subheadline)
                .foregroundStyle(.ink)

            FilmStrip(watched: watched, total: total)
                .frame(height: 22)
                .accessibilityHidden(true)

            if let daysLeft, watched < total {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.xl) { figures(daysLeft) }
                    VStack(alignment: .leading, spacing: Theme.Space.s) { figures(daysLeft) }
                }
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(HeroSurface(solid: reduceTransparency || contrast == .increased))
    }

    @ViewBuilder
    private func figures(_ daysLeft: Int) -> some View {
        Figure(value: "\(daysLeft)", caption: daysLeft == 1 ? "day to the ceremony" : "days to the ceremony")
        Figure(value: Self.pace(left: total - watched, days: daysLeft), caption: "films a day to finish")
    }

    /// Films a day to finish by the ceremony: "0.3", "2", "3.5".
    static func pace(left: Int, days: Int) -> String {
        let perDay = Double(left) / Double(max(days, 1))
        return perDay.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct Figure: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).displayFont(.title2).foregroundStyle(.ink)
            Text(caption).font(.caption).foregroundStyle(.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HeroSurface: ViewModifier {
    let solid: Bool

    func body(content: Content) -> some View {
        if solid {
            content.solidSurface(radius: Theme.Radius.hero)
        } else {
            content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.Radius.hero))
        }
    }
}

/// One frame per nominee, watched ones in gold; past 50 the frames stand for
/// a share of the films, so the strip never gets too fine to read.
struct FilmStrip: View {
    let watched: Int
    let total: Int

    var body: some View {
        Canvas { context, size in
            let frames = min(max(total, 1), 50)
            let filled = total == 0 ? 0 : Int((Double(watched) / Double(total) * Double(frames)).rounded())
            let gap: CGFloat = 2
            let width = (size.width - gap * CGFloat(frames - 1)) / CGFloat(frames)
            for index in 0..<frames {
                let rect = CGRect(x: CGFloat(index) * (width + gap), y: 0, width: width, height: size.height)
                let path = Path(roundedRect: rect, cornerRadius: min(3, width / 3))
                if index < filled {
                    context.fill(path, with: .linearGradient(
                        Gradient(colors: [.goldStart, .goldMid, .goldEnd]),
                        startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)))
                } else {
                    context.fill(path, with: .color(.ink.opacity(0.12)))
                }
            }
        }
    }
}

#Preview("Dark") {
    HeroCard(watched: 12, total: 50, daysLeft: 33).padding().background(.ground).preferredColorScheme(.dark)
}

#Preview("Light") {
    HeroCard(watched: 12, total: 50, daysLeft: 33).padding().background(.ground).preferredColorScheme(.light)
}

#Preview("Large text") {
    HeroCard(watched: 12, total: 50, daysLeft: 33).padding().background(.ground)
        .preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
