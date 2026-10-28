import SwiftUI
import UIKit

/// The share card's badge variant (P6-08, P12-04): the marquee card, velvet
/// and gold, with one earned badge, its name, tier and season. A fixed
/// 360 × 640 pt layout drawn at 3× for a 1080 × 1920 image, always dark.
struct BadgeShareCardView: View {
    let badge: UserBadge
    let voice: Voice
    let username: String?

    private static let velvet = Color(red: 0.557, green: 0.165, blue: 0.208)
    private static let velvetDeep = Color(red: 0.24, green: 0.06, blue: 0.09)
    private static let gold = Color(red: 0.89, green: 0.72, blue: 0.30)
    private static let cream = Color(red: 0.96, green: 0.93, blue: 0.86)
    private static let muted = Color(red: 0.96, green: 0.93, blue: 0.86).opacity(0.62)

    private var season: String {
        BadgeSeason(ceremonyId: badge.ceremonyId, ceremonyNumber: badge.ceremonyNumber, tiles: []).name
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(season.uppercased())
                .font(.system(size: 9, weight: .semibold)).tracking(1.6)
                .foregroundStyle(Self.muted)
                .padding(.top, 26)
            Text("Badge earned").font(.playfair(30)).foregroundStyle(Self.cream)
            if let username, !username.isEmpty {
                Text("@\(username)").font(.system(size: 11, weight: .medium)).foregroundStyle(Self.muted)
            }
            Spacer(minLength: 0)
            Image(badge.imageName).resizable().scaledToFit().frame(width: 200, height: 200)
            if let catalogue = badge.badge {
                Text(catalogue.name(voice)).font(.playfair(28)).foregroundStyle(Self.gold).multilineTextAlignment(.center)
                if let tier = catalogue.tierLabel(badge.tier) {
                    Text(tier.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(1.6).foregroundStyle(Self.cream)
                }
                Text(catalogue.description(voice))
                    .font(.system(size: 13)).foregroundStyle(Self.muted)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Image("BrandLogo").resizable().scaledToFit().frame(width: 36, height: 36)
                Text("Oscars Tracker").font(.playfair(18)).foregroundStyle(Self.gold)
                if ShareCardView.showsStoreBadge {
                    Image("AppStoreBadge").resizable().scaledToFit().frame(height: 28).padding(.leading, 10)
                }
            }
            .padding(.bottom, 16)
        }
        .padding(20)
        .frame(width: ShareCardView.size.width, height: ShareCardView.size.height)
        .background(LinearGradient(colors: [Self.velvet, Self.velvetDeep], startPoint: .top, endPoint: .bottom))
        .overlay { Rectangle().strokeBorder(Self.gold.opacity(0.55), lineWidth: 1).padding(8) }
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let catalogue = badge.badge else { return "Badge earned" }
        return "Badge earned, \(season): \(catalogue.name(voice))" + (catalogue.tierLabel(badge.tier).map { ", \($0)" } ?? "")
    }

    /// The card as a 1080 × 1920 image.
    static func render(_ badge: UserBadge, voice: Voice, username: String?) -> UIImage? {
        let renderer = ImageRenderer(content: BadgeShareCardView(badge: badge, voice: voice, username: username))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(ShareCardView.size)
        return renderer.uiImage
    }
}

/// Share for an earned badge: a `ShareLink` with the card's image.
struct BadgeShareButton: View {
    let badge: UserBadge
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Badge earned", image: Image(uiImage: image))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else {
                ProgressView()
            }
        }
        .task(id: "\(badge.momentKey)-\(voice.rawValue)") {
            image = BadgeShareCardView.render(badge, voice: voice, username: model.profile.profile?.username)
        }
    }
}

#if DEBUG
#Preview("Badge card, dark") {
    BadgeShareCardView(badge: SampleData.badge("films_watched", tier: 2), voice: .host, username: "filmbuff")
}

#Preview("Badge card, classic") {
    BadgeShareCardView(badge: SampleData.badge("death_race"), voice: .classic, username: "filmbuff").preferredColorScheme(.light)
}
#endif
