import Foundation

nonisolated struct LeaderboardEntry: Codable, Identifiable, Equatable {
    var id: String { userId }
    let userId: String
    let username: String
    let avatarUrl: String?
    let watchedCount: Int
    let predictionScore: Int
    let lastWatchedAt: String?
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case watchedCount = "watched_count"
        case predictionScore = "prediction_score"
        case lastWatchedAt = "last_watched_at"
        case rank
    }
}
