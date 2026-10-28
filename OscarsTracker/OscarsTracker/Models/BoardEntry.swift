import Foundation

/// One row of `get_season_board(p_ceremony_id, p_group_id)` (2.1; P2-05's
/// `get_leaderboard` with the list stage): the global board when the group is
/// nil, a group's board otherwise. The server ranks by score, then films
/// watched, then who got there first. Before nominations it counts films
/// watched on the contender list and every score is 0.
nonisolated struct BoardEntry: Codable, Identifiable, Hashable, Sendable {
    enum Scoring: String, Codable, Sendable {
        /// One point per correct pick.
        case traditional
        /// Each category's `points_value`.
        case weighted
    }

    /// The same row at another place, when someone above leaves the board.
    func withRank(_ rank: Int) -> BoardEntry {
        BoardEntry(rank: rank, userId: userId, username: username, avatarUrl: avatarUrl, watchedCount: watchedCount,
                   correctCount: correctCount, points: points, score: score, scoring: scoring, isCreator: isCreator,
                   listStage: listStage)
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
    /// The list the board counts, decided by the server: the contenders at
    /// `predicted` and `shortlisted`, the nominees from nominations day. Nil
    /// in a copy cached before 2.1, which counted the nominees.
    var listStage: ListStage? = nil

    /// Picks and scores count on this board: only once it counts the nominees.
    var countsPicks: Bool { (listStage ?? .nominated) == .nominated }

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case watchedCount = "watched_count"
        case correctCount = "correct_count"
        case points, score, scoring
        case isCreator = "is_creator"
        case listStage = "list_stage"
    }
}

/// What `get_season_board_person(p_ceremony_id, p_user_id)` returns for
/// someone you share a group with: the films they've watched on the board's
/// list and, after the lock, their picks.
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
