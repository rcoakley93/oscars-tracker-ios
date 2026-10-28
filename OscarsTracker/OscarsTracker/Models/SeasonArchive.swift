import Foundation

/// One past season from `get_season_archive(p_ceremony_id)` (P12-06), all of
/// it yours: the ballot with right and wrong picks and the winners, the
/// season's films you watched, where you finished on each board and the
/// badges you earned. Cached whole once opened, so it reads offline.
nonisolated struct SeasonArchive: Codable, Equatable, Sendable {
    let ceremony: ArchiveCeremony
    let ballot: [Category]
    let watched: [Film]
    /// The global board first, then each group you were in by the ceremony.
    let boards: [Board]
    let badges: [UserBadge]

    nonisolated struct ArchiveCeremony: Codable, Equatable, Sendable {
        let id: Int
        let number: Int
        let name: String
        let ceremonyAt: Date
        /// How many films were nominated, for "18 of 47 films".
        let filmCount: Int

        enum CodingKeys: String, CodingKey {
            case id, number, name
            case ceremonyAt = "ceremony_at"
            case filmCount = "film_count"
        }
    }

    nonisolated struct Nominee: Codable, Equatable, Sendable {
        let nominationId: Int
        let movieId: Int
        let title: String
        let posterUrl: String?
        let releaseYear: Int?
        let detailText: String?

        enum CodingKeys: String, CodingKey {
            case nominationId = "nomination_id"
            case movieId = "movie_id"
            case title
            case posterUrl = "poster_url"
            case releaseYear = "release_year"
            case detailText = "detail_text"
        }

        /// Acting categories lead with the person, the film underneath.
        func title(personFirst: Bool) -> String {
            personFirst ? (detailText ?? title) : title
        }

        func subtitle(personFirst: Bool) -> String? {
            personFirst ? (detailText == nil ? nil : title) : detailText
        }
    }

    nonisolated struct Category: Codable, Equatable, Identifiable, Sendable {
        let id: Int
        let name: String
        let displayMode: DisplayMode
        let pointsValue: Int
        let pick: Nominee?
        let winners: [Nominee]
        /// Nil with no pick, or before a winner was set.
        let isCorrect: Bool?

        enum CodingKeys: String, CodingKey {
            case id = "category_id"
            case name
            case displayMode = "display_mode"
            case pointsValue = "points_value"
            case pick, winners
            case isCorrect = "is_correct"
        }

        var personFirst: Bool { displayMode == .person }
    }

    nonisolated struct Film: Codable, Equatable, Identifiable, Sendable {
        var id: Int { movieId }
        let movieId: Int
        let title: String
        let posterUrl: String?
        let releaseYear: Int?
        let watchedAt: Date?

        enum CodingKeys: String, CodingKey {
            case movieId = "movie_id"
            case title
            case posterUrl = "poster_url"
            case releaseYear = "release_year"
            case watchedAt = "watched_at"
        }

        var movie: Movie {
            Movie(id: movieId, title: title, posterUrl: posterUrl, releaseYear: releaseYear, runtimeMinutes: nil, createdAt: nil)
        }
    }

    nonisolated struct Board: Codable, Equatable, Identifiable, Sendable {
        var id: Int { groupId ?? 0 }
        /// Nil for the global board.
        let groupId: Int?
        let groupName: String?
        let rank: Int
        let players: Int
        let score: Int
        let scoring: BoardEntry.Scoring
        let correctCount: Int
        let points: Int
        let watchedCount: Int

        enum CodingKeys: String, CodingKey {
            case groupId = "group_id"
            case groupName = "group_name"
            case rank, players, score, scoring
            case correctCount = "correct_count"
            case points
            case watchedCount = "watched_count"
        }
    }

    nonisolated enum DisplayMode: String, Codable, Sendable {
        case film, person
    }

    var picksMade: Int { ballot.count { $0.pick != nil } }
    var correctPicks: Int { ballot.count { $0.isCorrect == true } }
}

/// A badge you earned, from `get_user_badges(p_user_id, p_ceremony_id)`
/// (P12-03). The badge case (P12-04) names and draws them; the archive shows
/// a season's.
nonisolated struct UserBadge: Codable, Equatable, Hashable, Sendable {
    let badgeKey: String
    let shelf: String
    let sortOrder: Int
    let ceremonyId: Int
    let ceremonyNumber: Int
    /// 1 Bronze, 2 Silver, 3 Gold.
    let tier: Int
    let tierName: String
    let earnedAt: Date

    enum CodingKeys: String, CodingKey {
        case badgeKey = "badge_key"
        case shelf
        case sortOrder = "sort_order"
        case ceremonyId = "ceremony_id"
        case ceremonyNumber = "ceremony_number"
        case tier
        case tierName = "tier_name"
        case earnedAt = "earned_at"
    }
}
