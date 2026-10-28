import SwiftUI

/// The top of Films (screens.md, section 2): how many films you've watched,
/// in gold, the voice's line, a film strip of every nominee and two figures.
/// The screen's one custom glass; a solid surface under Reduce Transparency
/// or Increase Contrast.
struct HeroCard: View {
    /// What ceremony night and the weeks after show instead of films watched.
    struct Results: Equatable {
        let score: Int
        let announced: Int
        let categories: Int
        var isFinal: Bool { categories > 0 && announced == categories }
    }

    let watched: Int
    let total: Int
    /// Where the season is (`SeasonPhase`); the hero's figures and line follow it.
    var phase: SeasonPhase = .none
    /// The list's stage, for the line before nominations (P9-05).
    var stage: ListStage = .predicted
    /// The clock the lock-day countdown reads.
    var now: Date = .now
    /// Your score and the winners announced, for the live and after phases.
    var results: Results?
    /// Starts the Live Activity (P6-03). Nil hides the button, unless it's
    /// already following.
    var onFollow: (() -> Void)?
    /// The Live Activity is on: the button says so instead.
    var isFollowing = false

    @Environment(\.copy) private var copy
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 56

    private var showsResults: Bool {
        switch phase {
        case .live, .after: results != nil
        default: false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if let results, showsResults {
                number(results.score, label: results.score == 1 ? "point" : "points",
                       spoken: "\(Copy.pointCount(results.score)) so far")
            } else {
                number(watched, label: "of \(total) films", spoken: "\(watched) of \(total) films watched")
            }

            if let line {
                Text(line).font(.subheadline).foregroundStyle(.ink)
            }

            if !showsResults {
                FilmStrip(watched: watched, total: total)
                    .frame(height: 22)
                    .accessibilityHidden(true)
            }

            if phase == .live, isFollowing {
                Label(copy.heroFollowing, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.inkMuted)
            } else if phase == .live, let onFollow {
                Button(copy.heroFollow, systemImage: "dot.radiowaves.left.and.right", action: onFollow)
                    .buttonStyle(.bordered)
            }

            if let days = figureDays, watched < total {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.xl) { figures(days) }
                    VStack(alignment: .leading, spacing: Theme.Space.s) { figures(days) }
                }
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(HeroSurface(solid: reduceTransparency || contrast == .increased))
    }

    private func number(_ value: Int, label: String, spoken: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Text("\(value)")
                .font(.system(size: numberSize, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.goldGradient)
                .contentTransition(.numericText(value: Double(value)))
            Text(label)
                .font(.title3.bold()).fontDesign(.rounded)
                .foregroundStyle(.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    /// The voice's line for this phase; every film watched wins before the lock.
    var line: String? {
        let left = total - watched
        switch phase {
        case .none:
            return watched == total && total > 0 ? copy.allWatched : copy.progressSummary(watched, total)
        case .beforeNominations(let date):
            return copy.heroTeaser(left, date?.formatted(.dateTime.month(.abbreviated).day()), stage)
        case .season(let days):
            return copy.heroSeason(days, left)
        case .finalWeek(let days):
            return copy.heroFinalWeek(days, left)
        case .lockDay(let locksAt):
            return copy.heroLockDay(SeasonTicker.timeLeft(until: locksAt, now: now))
        case .locked(let days):
            return copy.heroLocked(days)
        case .live:
            return results.map { copy.heroLive($0.announced, $0.categories) }
        case .after:
            return results.map { copy.heroAfter($0.isFinal) }
        }
    }

    /// Days to show as a figure: only while the ceremony is ahead and the ballot is open.
    private var figureDays: Int? {
        switch phase {
        case .season(let days), .finalWeek(let days): days
        default: nil
        }
    }

    @ViewBuilder
    private func figures(_ days: Int) -> some View {
        Figure(value: "\(days)", caption: days == 1 ? "day to the ceremony" : "days to the ceremony")
        if SeasonPhase.showsPace(phase, filmsLeft: total - watched, days: days) {
            Figure(value: Self.pace(left: total - watched, days: days), caption: "films a day to finish")
        }
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

#if DEBUG
private extension HeroCard {
    static let anchor = Date(timeIntervalSince1970: 1_800_000_000)
}

private struct HeroPhases: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.m) {
                HeroCard(watched: 0, total: 40, phase: .beforeNominations(HeroCard.anchor.addingTimeInterval(9 * 86400)))
                HeroCard(watched: 12, total: 50, phase: .season(days: 33))
                HeroCard(watched: 38, total: 50, phase: .finalWeek(days: 5))
                HeroCard(watched: 44, total: 50, phase: .lockDay(locksAt: HeroCard.anchor.addingTimeInterval(3 * 3600)), now: HeroCard.anchor)
                HeroCard(watched: 44, total: 50, phase: .locked(days: 4))
                HeroCard(watched: 44, total: 50, phase: .live, results: .init(score: 4, announced: 6, categories: 23), onFollow: {})
                HeroCard(watched: 44, total: 50, phase: .after, results: .init(score: 11, announced: 23, categories: 23))
            }
            .padding()
        }
        .background(.ground)
    }
}

#Preview("Season phases · Dark") { HeroPhases().preferredColorScheme(.dark) }
#Preview("Season phases · Light") { HeroPhases().preferredColorScheme(.light) }
#Preview("Season phases · Large text") { HeroPhases().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2) }
#Preview("Before nominations") {
    HeroCard(watched: 0, total: 40, phase: .beforeNominations(HeroCard.anchor)).padding().background(.ground)
}
#Preview("Nominations to final week") {
    HeroCard(watched: 12, total: 50, phase: .season(days: 33)).padding().background(.ground)
}
#Preview("Final week") {
    HeroCard(watched: 38, total: 50, phase: .finalWeek(days: 5)).padding().background(.ground)
}
#Preview("Lock day") {
    HeroCard(watched: 44, total: 50, phase: .lockDay(locksAt: HeroCard.anchor.addingTimeInterval(3 * 3600)), now: HeroCard.anchor)
        .padding().background(.ground)
}
#Preview("Ceremony night") {
    HeroCard(watched: 44, total: 50, phase: .live, results: .init(score: 4, announced: 6, categories: 23), onFollow: {})
        .padding().background(.ground)
}
#Preview("Ceremony night · Following") {
    HeroCard(watched: 44, total: 50, phase: .live, results: .init(score: 4, announced: 6, categories: 23), isFollowing: true)
        .padding().background(.ground)
}
#Preview("Recap") {
    HeroCard(watched: 44, total: 50, phase: .after, results: .init(score: 11, announced: 23, categories: 23)).padding().background(.ground)
}
#Preview("Dark") {
    HeroCard(watched: 12, total: 50, phase: .season(days: 33)).padding().background(.ground).preferredColorScheme(.dark)
}
#Preview("Light") {
    HeroCard(watched: 12, total: 50, phase: .season(days: 33)).padding().background(.ground).preferredColorScheme(.light)
}
#Preview("Large text") {
    HeroCard(watched: 12, total: 50, phase: .season(days: 33)).padding().background(.ground)
        .preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
#endif
