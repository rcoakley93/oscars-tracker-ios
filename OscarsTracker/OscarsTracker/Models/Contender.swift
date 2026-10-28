import Foundation

/// Which list Films shows (2.1, P9-05): `app_config.feature_flags.list_stage`,
/// changed on the server as the season moves, never in a release.
nonisolated enum ListStage: String, Codable, CaseIterable, Sendable {
    /// Before the shortlists: the films we expect to be nominated, with our odds.
    case predicted
    /// Dec 15 to nominations: the Academy's shortlists where there are any,
    /// our predictions elsewhere.
    case shortlisted
    /// From nominations day: the nominees, as in 2.0.
    case nominated

    var showsContenders: Bool { self != .nominated }
}

/// A film we expect to be nominated in a category, from `get_contenders()`
/// (P9-02). `odds` is ours (0–1); the source's own numbers never reach the app.
nonisolated struct Contender: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let ceremonyId: Int
    let categoryId: Int
    let categoryName: String
    let displayMode: BallotCategory.DisplayMode?
    let movieId: Int
    /// The person, for acting categories.
    let detailText: String?
    let stage: Stage
    let odds: Double
    /// Who informed the odds, for the credit line; nil for our own.
    let source: String?
    let sourceUpdatedAt: Date

    nonisolated enum Stage: String, Codable, Hashable, Sendable {
        case predicted, shortlisted
    }

    enum CodingKeys: String, CodingKey {
        case id, stage, odds, source
        case ceremonyId = "ceremony_id"
        case categoryId = "category_id"
        case categoryName = "category_name"
        case displayMode = "display_mode"
        case movieId = "movie_id"
        case detailText = "detail_text"
        case sourceUpdatedAt = "source_updated_at"
    }

    /// Our odds as a whole percent, 1 to 99: a prediction is never certain.
    var percent: Int { Self.percent(odds) }

    static func percent(_ odds: Double) -> Int {
        min(99, max(1, Int((odds * 100).rounded())))
    }
}
