import SwiftUI
import UIKit
import CoreText

extension Font {
    /// Playfair Display, bundled for the envelope's voice and share cards
    /// (brand.md). Registered on first use. Fixed size: the card is an image.
    static func playfair(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        _ = PlayfairDisplay.registered
        return .custom("Playfair Display", fixedSize: size).weight(weight)
    }
}

private enum PlayfairDisplay {
    static let registered: Void = {
        for subdirectory in [nil, "Fonts", "Resources/Fonts"] {
            for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: subdirectory) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()
}

/// The marquee card (brand.md): gold on velvet, Playfair, poster art. A fixed
/// 360 × 640 pt layout drawn at 3× for a 1080 × 1920 image. Colours are
/// fixed, not the theme's: it looks the same in light and dark. Gold marks
/// your picks and, once winners are in, your wins and score.
struct ShareCardView: View {
    static let size = CGSize(width: 360, height: 640)

    let card: ShareCard
    /// Posters by URL string, loaded before the card is drawn (an
    /// `ImageRenderer` doesn't wait for `AsyncImage`).
    var posters: [String: UIImage] = [:]

    private static let velvet = Color(red: 0.557, green: 0.165, blue: 0.208)
    private static let velvetDeep = Color(red: 0.24, green: 0.06, blue: 0.09)
    private static let gold = Color(red: 0.89, green: 0.72, blue: 0.30)
    private static let cream = Color(red: 0.96, green: 0.93, blue: 0.86)
    private static let muted = Color(red: 0.96, green: 0.93, blue: 0.86).opacity(0.62)

    var body: some View {
        VStack(spacing: 14) {
            header
            posterStrip
            if card.kind == .results { summary }
            picks
            Spacer(minLength: 0)
            footer
        }
        .padding(20)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(LinearGradient(colors: [Self.velvet, Self.velvetDeep], startPoint: .top, endPoint: .bottom))
        .overlay { Rectangle().strokeBorder(Self.gold.opacity(0.55), lineWidth: 1).padding(8) }
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(card.seasonName.uppercased())
                .font(.system(size: 9, weight: .semibold)).tracking(1.6)
                .foregroundStyle(Self.muted)
            Text(card.title)
                .font(.playfair(30))
                .foregroundStyle(Self.cream)
            if let username = card.username, !username.isEmpty {
                Text("@\(username)").font(.system(size: 11, weight: .medium)).foregroundStyle(Self.muted)
            }
        }
        .padding(.top, 6)
    }

    private var posterStrip: some View {
        HStack(spacing: 6) {
            ForEach(card.posterURLs, id: \.self) { url in
                Color.black.opacity(0.25)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .overlay {
                        if let image = posters[url] {
                            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
        .frame(height: 78)
        .frame(maxWidth: .infinity)
    }

    /// Score, rank and how many were right: the wins, so gold.
    private var summary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            stat("\(card.score)", card.score == 1 ? "point" : "points", gold: true)
            stat("\(card.correctCount)/\(card.totalCount)", "correct", gold: false)
            if let rank = card.rankText { stat(rank, "ranked", gold: false) }
        }
    }

    private func stat(_ value: String, _ label: String, gold: Bool) -> some View {
        VStack(spacing: 0) {
            Text(value).font(.playfair(gold ? 34 : 20)).foregroundStyle(gold ? Self.gold : Self.cream)
            Text(label.uppercased()).font(.system(size: 8, weight: .semibold)).tracking(1.2).foregroundStyle(Self.muted)
        }
    }

    private var picks: some View {
        let half = (card.lines.count + 1) / 2
        let columns = [Array(card.lines.prefix(half)), Array(card.lines.dropFirst(half))]
        return HStack(alignment: .top, spacing: 12) {
            ForEach(0..<2, id: \.self) { index in
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(columns[index]) { line in row(line) }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func row(_ line: ShareCard.Line) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(line.category.uppercased())
                .font(.system(size: 6.5, weight: .semibold)).tracking(0.6)
                .foregroundStyle(Self.muted).lineLimit(1)
            Text(line.pick ?? "No pick")
                .font(.system(size: 10.5, weight: line.pick == nil ? .regular : .semibold))
                .foregroundStyle(color(for: line))
                .strikethrough(line.isCorrect == false, color: Self.muted)
                .lineLimit(1)
            if let film = line.film {
                Text(film)
                    .font(.system(size: 8))
                    .foregroundStyle(Self.muted).lineLimit(1)
            }
        }
    }

    /// Gold for a pick before the winners, for a win after; the rest recede.
    private func color(for line: ShareCard.Line) -> Color {
        guard line.pick != nil else { return Self.muted }
        switch line.isCorrect {
        case true: return Self.gold
        case false: return Self.muted
        case nil: return card.kind == .ballot ? Self.gold : Self.cream
        }
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("Oscars Tracker").font(.playfair(13)).foregroundStyle(Self.gold)
            Text("Posters and film data from TMDB. This product uses the TMDB API but is not endorsed or certified by TMDB.")
                .font(.system(size: 5.5)).foregroundStyle(Self.muted).multilineTextAlignment(.center)
        }
    }

    private var accessibilitySummary: String {
        switch card.kind {
        case .ballot: "\(card.title), \(card.pickedCount) of \(card.totalCount) categories picked"
        case .results: "\(card.title): \(card.score) points, \(card.correctCount) of \(card.totalCount) correct" + (card.rankText.map { ", ranked \($0)" } ?? "")
        }
    }
}

// MARK: - Rendering

@MainActor
enum ShareCardRenderer {
    /// Fetches the card's posters through the poster cache.
    static func loadPosters(for card: ShareCard) async -> [String: UIImage] {
        var result: [String: UIImage] = [:]
        for poster in card.posterURLs {
            guard let request = PosterSize.tile.request(poster),
                  let (data, _) = try? await URLSession.posters.data(for: request),
                  let image = UIImage(data: data) else { continue }
            result[poster] = image
        }
        return result
    }

    /// The card as a 1080 × 1920 image.
    static func render(_ card: ShareCard, posters: [String: UIImage]) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(card: card, posters: posters))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(ShareCardView.size)
        return renderer.uiImage
    }
}

// MARK: - Sheet

/// The card, drawn from the stores, with a `ShareLink` for its image.
struct ShareCardSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var posters: [String: UIImage]?
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            Group {
                if let card = model.shareCard {
                    ScrollView {
                        ShareCardView(card: card, posters: posters ?? [:])
                            .clipShape(Theme.shape(Theme.Radius.tile))
                            .padding()
                    }
                    .task(id: card) {
                        posters = nil
                        image = nil
                        let loaded = await ShareCardRenderer.loadPosters(for: card)
                        posters = loaded
                        image = ShareCardRenderer.render(card, posters: loaded)
                    }
                    .toolbar { shareItem(card) }
                } else {
                    ContentUnavailableView("Nothing to share yet", systemImage: "square.and.arrow.up",
                                           description: Text("Make a pick and your ballot is ready to share."))
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    @ToolbarContentBuilder
    private func shareItem(_ card: ShareCard) -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if let image {
                ShareLink(item: Image(uiImage: image), preview: SharePreview(card.title, image: Image(uiImage: image))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else {
                ProgressView()
            }
        }
    }
}

// MARK: - Entry point

extension AppModel {
    /// The card for what you've done so far; nil with nothing picked.
    var shareCard: ShareCard? {
        let userID = session.userID
        return ShareCard.make(categories: ballot.categories, picks: ballot.picks,
                              seasonName: season.ceremony?.name ?? "Academy Awards",
                              username: profile.profile?.username,
                              standing: userID.flatMap { leaderboard.standing(in: nil, userID: $0, metric: .predictions) })
    }
}

/// The share button for the Ballot and Board toolbars: opens the card sheet.
struct ShareCardToolbar: ToolbarContent {
    @Environment(AppModel.self) private var model

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(model.ballot.hasWinners ? "Share score" : "Share ballot", systemImage: "square.and.arrow.up") {
                model.navigation.sheet = .shareCard
            }
            .disabled(model.shareCard == nil)
        }
        .visibilityPriority(.low)
    }
}

#Preview("Ballot card, dark") {
    ShareCardView(card: ShareCard.preview(results: false)).preferredColorScheme(.dark)
}

#Preview("Ballot card, light") {
    ShareCardView(card: ShareCard.preview(results: false)).preferredColorScheme(.light)
}

#Preview("Ballot card, large text") {
    ShareCardView(card: ShareCard.preview(results: false)).dynamicTypeSize(.accessibility2)
}

#Preview("Results card") {
    ShareCardView(card: ShareCard.preview(results: true))
}

#Preview("Sheet") {
    ShareCardSheet().environment(AppModel.preview())
}

extension ShareCard {
    /// Sample card for previews: the full sample ballot with every other pick right.
    static func preview(results: Bool) -> ShareCard {
        let categories = SampleData.fullBallot.map { category in
            results ? BallotCategory(id: category.id, name: category.name, pointsValue: category.pointsValue,
                                     nominations: category.nominations.enumerated().map {
                BallotNominee(id: $1.id, movie: $1.movie, personName: $1.personName, isWinner: $0 == category.id % 2)
            }) : category
        }
        let picks = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.nominations[0].id) })
        return make(categories: categories, picks: picks, seasonName: "99th Academy Awards", username: "filmbuff",
                    standing: results ? .init(rank: 3, size: 1204, position: .first) : nil)!
    }
}
