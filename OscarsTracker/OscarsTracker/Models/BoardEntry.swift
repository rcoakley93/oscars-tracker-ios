import Foundation

/// One row of `get_leaderboard(p_ceremony_id, p_group_id)` (P2-05): the global
/// board when the group is nil, a group's board otherwise. The server ranks
/// by score, then films watched, then who got there first.
nonisolated struct BoardEntry: Codable, Identifiable, Hashable, Sendable {
    enum Scoring: String, Codable, Sendable {
        /// One point per correct pick.
        case traditional
        /// Each category's `points_value`.
        case weighted
    }

    var id: String { userId }
    let rank: Int
    let userId: String
    let username: String
    let avatarUrl: String?
    let watchedCount: Int
    let correctCount: Int
    let points: Int
    /// `correctCount` or `points`, by the board's scoring.
    let score: Int
    let scoring: Scoring
    let isCreator: Bool

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case watchedCount = "watched_count"
        case correctCount = "correct_count"
        case points, score, scoring
        case isCreator = "is_creator"
    }
}

/// What `get_board_person(p_ceremony_id, p_user_id)` returns for someone you
/// share a group with: the nominees they've watched and, after the lock,
/// their picks.
nonisolated struct BoardPerson: Equatable, Sendable {
    var watchedMovieIDs: Set<Int>
    /// Nomination by category.
    var picks: [Int: Int]

    /// One row from the RPC: a watched film, or a pick.
    struct Row: Decodable, Sendable {
        let movieId: Int?
        let categoryId: Int?
        let nominationId: Int?

        enum CodingKeys: String, CodingKey {
            case movieId = "movie_id"
            case categoryId = "category_id"
            case nominationId = "nomination_id"
        }
    }

    init(watchedMovieIDs: Set<Int>, picks: [Int: Int]) {
        self.watchedMovieIDs = watchedMovieIDs
        self.picks = picks
    }

    init(rows: [Row]) {
        watchedMovieIDs = Set(rows.compactMap(\.movieId))
        picks = Dictionary(rows.compactMap { row in row.categoryId.flatMap { c in row.nominationId.map { (c, $0) } } },
                           uniquingKeysWith: { first, _ in first })
    }
}
