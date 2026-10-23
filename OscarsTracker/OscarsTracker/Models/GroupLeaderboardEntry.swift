import Foundation

/// One row of `get_group_leaderboard(p_group_id)`.
nonisolated struct GroupLeaderboardEntry: Codable, Identifiable, Hashable, Sendable {
    var id: String { userId }
    let userId: String
    let username: String
    let avatarUrl: String?
    let watchedCount: Int
    let predictionScore: Int
    let rank: Int
    let isCreator: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case watchedCount = "watched_count"
        case predictionScore = "prediction_score"
        case rank
        case isCreator = "is_creator"
    }
}

/// The result of `join_group(p_invite_code)`.
nonisolated struct JoinedGroup: Codable, Hashable, Sendable {
    let groupId: Int
    let groupName: String

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
    }
}
