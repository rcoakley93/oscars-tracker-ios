import Foundation

/// One badge in the catalogue (docs/design/badges.md, P12-01): its key, shelf
/// and tiers match the server's `badges` table; its names and descriptions
/// are app copy in both voices. The server decides who earns what
/// (`award_badges`); the app only shows it.
nonisolated struct Badge: Identifiable, Hashable, Sendable {
    nonisolated enum Shelf: String, Sendable {
        case watching, picking, groups
    }

    /// The line in each voice: both must be given.
    nonisolated struct Lines: Hashable, Sendable {
        let host: String
        let classic: String

        @MainActor func callAsFunction(_ voice: Voice) -> String { voice == .host ? host : classic }
    }

    /// `badges.key`, and the art's image set prefix.
    let key: String
    let shelf: Shelf
    /// Bronze, Silver, Gold thresholds; nil for a one-tier badge, which is Gold.
    let thresholds: [Int]?
    let name: Lines
    let description: Lines
    /// How to earn the first tier, a fact in both voices ("Watch 10 films
    /// before the ceremony"), under the outline.
    let rule: String
    /// The rule's unit for a tier's threshold ("10 films"); nil for one-tier badges.
    let unit: (@Sendable (Int) -> String)?

    var id: String { key }
    var isTiered: Bool { thresholds != nil }

    static func == (a: Badge, b: Badge) -> Bool { a.key == b.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }

    /// The catalogue in the badge case's order (`badges.sort_order`).
    static let catalogue: [Badge] = [
        Badge(key: "death_race", shelf: .watching, thresholds: nil,
              name: Lines(host: "Death Race", classic: "Every nominee watched"),
              description: Lines(host: "Watch every nominee before the curtain goes up.",
                                 classic: "Watch every nominated film before the ceremony."),
              rule: "Watch every nominee before the ceremony", unit: nil),
        Badge(key: "best_picture_slate", shelf: .watching, thresholds: nil,
              name: Lines(host: "Picture Perfect", classic: "Every Best Picture nominee watched"),
              description: Lines(host: "See every Best Picture nominee before the envelope does.",
                                 classic: "Watch every Best Picture nominee before the ceremony."),
              rule: "Watch every Best Picture nominee", unit: nil),
        Badge(key: "category_complete", shelf: .watching, thresholds: [3, 10, 20],
              name: Lines(host: "The Completist", classic: "Categories completed"),
              description: Lines(host: "Watch every nominee in a category. Then do it again. And again.",
                                 classic: "Watch every nominee in 3, 10 or 20 categories before the ceremony."),
              rule: "Watch every nominee in 3 categories", unit: { $0 == 1 ? "1 category" : "\($0) categories" }),
        Badge(key: "films_watched", shelf: .watching, thresholds: [10, 25, 40],
              name: Lines(host: "Stub Collector", classic: "Films watched"),
              description: Lines(host: "Tear 10, 25 or 40 ticket stubs before the ceremony.",
                                 classic: "Watch 10, 25 or 40 of the season's films before the ceremony."),
              rule: "Watch 10 films before the ceremony", unit: { Copy.filmCount($0) }),
        Badge(key: "short_and_sweet", shelf: .watching, thresholds: nil,
              name: Lines(host: "Short and Sweet", classic: "Every short film watched"),
              description: Lines(host: "Watch every nominated short. They're short. That's the whole point.",
                                 classic: "Watch every nominated short film before the ceremony."),
              rule: "Watch every nominated short", unit: nil),
        Badge(key: "ahead_of_the_academy", shelf: .watching, thresholds: [1, 5, 10],
              name: Lines(host: "Ahead of the Academy", classic: "Watched before the nominations"),
              description: Lines(host: "Watch a contender before the Academy agrees with you.",
                                 classic: "Watch 1, 5 or 10 contenders before nominations day that go on to be nominated."),
              rule: "Watch a contender before it's nominated", unit: { Copy.filmCount($0) }),
        Badge(key: "full_ballot", shelf: .picking, thresholds: nil,
              name: Lines(host: "Pens Down", classic: "Complete ballot"),
              description: Lines(host: "Pick every category before the lock. Second-guessing is allowed until then.",
                                 classic: "Pick every category before the ballot locks."),
              rule: "Pick every category before the lock", unit: nil),
        Badge(key: "correct_picks", shelf: .picking, thresholds: [5, 10, 15],
              name: Lines(host: "Called It", classic: "Correct picks"),
              description: Lines(host: "Get 5, 10 or 15 picks right. The Academy owes you a call.",
                                 classic: "Get 5, 10 or 15 picks right."),
              rule: "Get 5 picks right", unit: { $0 == 1 ? "1 pick" : "\($0) picks" }),
        Badge(key: "perfect_ballot", shelf: .picking, thresholds: nil,
              name: Lines(host: "Thank You, Academy", classic: "Perfect ballot"),
              description: Lines(host: "Get every category right. Bring a speech.",
                                 classic: "Get every category right."),
              rule: "Get every category right", unit: nil),
        Badge(key: "acting_sweep", shelf: .picking, thresholds: nil,
              name: Lines(host: "Full Cast", classic: "Acting sweep"),
              description: Lines(host: "Call all 4 acting categories. Take a bow.",
                                 classic: "Get all 4 acting categories right."),
              rule: "Get all 4 acting categories right", unit: nil),
        Badge(key: "category_sweep", shelf: .picking, thresholds: [1, 3, 5],
              name: Lines(host: "Clean Sweep", classic: "Category groups swept"),
              description: Lines(host: "Get a whole group of categories right, like all the music or all the shorts.",
                                 classic: "Get every category right in 1, 3 or 5 groups, like music or the shorts."),
              rule: "Get a whole group of categories right", unit: { $0 == 1 ? "1 group" : "\($0) groups" }),
        Badge(key: "top_billing", shelf: .groups, thresholds: nil,
              name: Lines(host: "Top Billing", classic: "Group winner"),
              description: Lines(host: "Finish first in a group of 3 or more. Gracious speech optional.",
                                 classic: "Finish first in a group of 3 or more people."),
              rule: "Finish first in a group of 3 or more", unit: nil),
        Badge(key: "full_house", shelf: .groups, thresholds: [5, 10, 20],
              name: Lines(host: "Full House", classic: "Full group"),
              description: Lines(host: "Fill the seats. Be in a group of 5, 10 or 20 people.",
                                 classic: "Be in a group with 5, 10 or 20 people in it."),
              rule: "Be in a group of 5 people", unit: { $0 == 1 ? "1 person" : "\($0) people" }),
    ]

    private static let byKey = Dictionary(uniqueKeysWithValues: catalogue.map { ($0.key, $0) })

    /// Nil for a key this version doesn't know: the case skips it.
    static func named(_ key: String) -> Badge? { byKey[key] }

    /// "Bronze", "Silver", "Gold": a fact, the same in both voices.
    static func tierName(_ tier: Int) -> String {
        switch tier {
        case 1: "Bronze"
        case 2: "Silver"
        default: "Gold"
        }
    }

    /// The tier shown with the name: nothing for a one-tier badge.
    func tierLabel(_ tier: Int) -> String? {
        isTiered ? Self.tierName(tier) : nil
    }

    /// "Next: Silver at 25 films", while a higher tier is left.
    func nextTier(after tier: Int) -> String? {
        guard let thresholds, let unit, tier < thresholds.count else { return nil }
        return "Next: \(Self.tierName(tier + 1)) at \(unit(thresholds[tier]))"
    }

    /// The image set: `Badges/<key>-<bronze|silver|gold>` earned, `-unearned` not yet.
    static func imageName(_ key: String, tierName: String?) -> String {
        "Badges/\(key)-\(tierName ?? "unearned")"
    }

    /// The display name of a `categories.badge_group`.
    static func groupName(_ group: String) -> String {
        switch group {
        case "acting": "Acting"
        case "writing": "Writing"
        case "music": "Music"
        case "shorts": "Shorts"
        case "features": "Features"
        case "craft": "Craft"
        case "top": "Picture and directing"
        default: group.capitalized
        }
    }
}

/// What a badge names (`user_badges.detail`, with the lists
/// `get_user_badges` computes): the group won, the categories completed, the
/// category groups swept.
nonisolated struct BadgeDetail: Codable, Hashable, Sendable {
    var groupId: Int?
    var categoryIds: [Int]?
    var badgeGroups: [String]?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case categoryIds = "category_ids"
        case badgeGroups = "badge_groups"
    }
}

nonisolated extension UserBadge {
    var badge: Badge? { Badge.named(badgeKey) }

    /// The earned moment's key: the badge, its season, its tier and what it
    /// names, so a raised tier or a second group won is new.
    var momentKey: String {
        "\(badgeKey)|\(ceremonyId)|\(tier)|\(detail?.groupId.map(String.init) ?? "")"
    }

    var imageName: String { Badge.imageName(badgeKey, tierName: tierName) }
}

/// One person on the Board's Badges segment (P12-04b), from
/// `get_board_badges`: their rank by badges this season and those badges,
/// newest first. The server lists only you and people you share a group with.
nonisolated struct BoardBadgeEntry: Codable, Identifiable, Hashable, Sendable {
    let rank: Int
    let userId: String
    let username: String
    let avatarUrl: String?
    /// Distinct badges this season: `top_billing` won twice counts once.
    let badgeCount: Int
    let badges: [UserBadge]

    var id: String { userId }

    /// The same row at another place, when someone above leaves the board.
    func withRank(_ rank: Int) -> BoardBadgeEntry {
        BoardBadgeEntry(rank: rank, userId: userId, username: username, avatarUrl: avatarUrl, badgeCount: badgeCount, badges: badges)
    }

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case badgeCount = "badge_count"
        case badges
    }

    /// The strip's tiles: one per badge, newest first, ones this version
    /// doesn't know skipped.
    var tiles: [BadgeTile] {
        var seen = Set<String>()
        return badges.compactMap { row in
            guard let badge = row.badge, seen.insert(row.badgeKey).inserted else { return nil }
            let earned = badges.filter { $0.badgeKey == row.badgeKey }.sorted { $0.tier > $1.tier }
            return BadgeTile(badge: badge, earned: earned)
        }
    }
}

/// One tile in a badge case: a badge, earned or not, in one season.
/// `top_billing` won in two groups is one tile with both rows.
nonisolated struct BadgeTile: Identifiable, Hashable, Sendable {
    let badge: Badge
    /// Every row for this badge in the season, highest tier first; empty when not earned.
    let earned: [UserBadge]

    var id: String { badge.key }
    var best: UserBadge? { earned.first }
    var isEarned: Bool { !earned.isEmpty }
    var imageName: String { best?.imageName ?? Badge.imageName(badge.key, tierName: nil) }
}

/// One season of a badge case.
nonisolated struct BadgeSeason: Identifiable, Hashable, Sendable {
    let ceremonyId: Int
    let ceremonyNumber: Int
    let tiles: [BadgeTile]

    var id: Int { ceremonyId }
    var earnedCount: Int { tiles.count(where: \.isEarned) }

    /// "99th Academy Awards".
    var name: String {
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        return "\(ordinal.string(from: ceremonyNumber as NSNumber) ?? "\(ceremonyNumber)") Academy Awards"
    }

    /// The case, newest season first. The current season shows every badge,
    /// earned or not; past seasons only what they earned, since an outline
    /// can't be earned any more. Badges this version doesn't know are skipped.
    static func seasons(_ badges: [UserBadge], current: (id: Int, number: Int)?) -> [BadgeSeason] {
        let known = badges.filter { $0.badge != nil }
        var numbers = Dictionary(known.map { ($0.ceremonyId, $0.ceremonyNumber) }, uniquingKeysWith: { first, _ in first })
        if let current { numbers[current.id] = current.number }
        return numbers.sorted { ($0.value, $0.key) > ($1.value, $1.key) }.compactMap { ceremonyID, number in
            let rows = known.filter { $0.ceremonyId == ceremonyID }
            let isCurrent = ceremonyID == current?.id
            let tiles = Badge.catalogue.compactMap { badge -> BadgeTile? in
                let earned = rows.filter { $0.badgeKey == badge.key }.sorted { ($0.tier, $1.earnedAt) > ($1.tier, $0.earnedAt) }
                return earned.isEmpty && !isCurrent ? nil : BadgeTile(badge: badge, earned: earned)
            }
            return tiles.isEmpty ? nil : BadgeSeason(ceremonyId: ceremonyID, ceremonyNumber: number, tiles: tiles)
        }
    }
}
