import Foundation

nonisolated struct UserWatched: Codable, Identifiable {
    let id: Int
    let userId: String
    let movieId: Int
    let watchedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case movieId = "movie_id"
        case watchedAt = "watched_at"
    }
}
