import Foundation

/// The signed-in account, from the auth session: the email and how you sign in.
nonisolated struct Account: Equatable, Sendable {
    enum Provider: String, Sendable {
        case apple, google, email
    }

    let email: String?
    let provider: Provider
}

/// One past season from `get_season_history()` (P2-12): where you finished.
nonisolated struct SeasonResult: Codable, Identifiable, Hashable, Sendable {
    var id: Int { ceremonyId }
    let ceremonyId: Int
    let number: Int
    let name: String
    let ceremonyAt: Date
    let watchedCount: Int
    let correctCount: Int
    let points: Int
    let score: Int
    let scoring: BoardEntry.Scoring
    let rank: Int
    let players: Int

    enum CodingKeys: String, CodingKey {
        case ceremonyId = "ceremony_id"
        case number, name
        case ceremonyAt = "ceremony_at"
        case watchedCount = "watched_count"
        case correctCount = "correct_count"
        case points, score, scoring, rank, players
    }
}
