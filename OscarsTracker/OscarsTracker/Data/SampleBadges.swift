import Foundation

/// Sample badges (P12-04) for previews and tests: a partial case this season
/// (the 99th, ceremony 2), the 98th's two from the archive, Sam's few, and a
/// full case of every badge in Gold.
extension SampleData {
    static func badge(_ key: String, tier: Int = 3, ceremony: Int = 2, number: Int = 99,
                                  earnedAt: Date = Date(timeIntervalSince1970: 1_773_014_400),
                                  detail: BadgeDetail? = nil) -> UserBadge {
        let badge = Badge.named(key)
        let order = (Badge.catalogue.firstIndex { $0.key == key } ?? 0) + 1
        return UserBadge(badgeKey: key, shelf: badge?.shelf.rawValue ?? "watching", sortOrder: order, ceremonyId: ceremony,
                         ceremonyNumber: number, tier: tier, tierName: ["bronze", "silver", "gold"][max(0, min(tier, 3) - 1)],
                         earnedAt: earnedAt, detail: detail)
    }

    /// This season so far: four badges, two of them tiers below Gold.
    static let currentBadges: [UserBadge] = [
        badge("category_complete", tier: 1, detail: BadgeDetail(categoryIds: [1, 2, 3])),
        badge("films_watched", tier: 2),
        badge("full_ballot"),
        badge("top_billing", detail: BadgeDetail(groupId: 1)),
    ]

    /// The 98th's badges, as its archive shows them.
    static var pastBadges: [UserBadge] { archive98.badges }

    static var myBadges: [UserBadge] { currentBadges + pastBadges }

    static let samBadges: [UserBadge] = [
        badge("death_race"),
        badge("films_watched"),
        badge("ahead_of_the_academy", tier: 2),
        badge("category_sweep", tier: 1, detail: BadgeDetail(badgeGroups: ["acting"])),
        badge("acting_sweep"),
        badge("correct_picks", tier: 2),
        badge("full_house", tier: 1),
        badge("best_picture_slate"),
    ]

    /// Every badge this season in Gold, for the full-case preview.
    static let fullBadges: [UserBadge] = Badge.catalogue.map { badge in
        SampleData.badge(badge.key, detail: badge.key == "top_billing" ? BadgeDetail(groupId: 1) : nil)
    }
}
