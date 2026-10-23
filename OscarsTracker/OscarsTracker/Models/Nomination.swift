import Foundation

nonisolated struct Nomination: Codable, Identifiable {
    let id: Int
    let categoryId: Int?
    let movieId: Int?
    let detailText: String?
    let isWinner: Bool?
    let createdAt: String?

    var movie: Movie?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case movieId = "movie_id"
        case detailText = "detail_text"
        case isWinner = "is_winner"
        case createdAt = "created_at"
        case movie
    }
}

nonisolated struct CategoryWithNominations: Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let nominations: [Nomination]
}

/// A nominee in a category (movie + optional detail like actor name)
nonisolated struct CategoryNominee: Identifiable {
    let id: Int  // nomination id
    let movie: Movie
    let detailText: String?  // Actor name for actor categories

    /// Check if this category has actor/person as the primary subject
    var hasActorDetail: Bool {
        detailText != nil && !detailText!.isEmpty
    }
}

/// Category with associated nominees for dashboard category view
nonisolated struct CategoryWithMovies: Identifiable {
    let id: Int
    let name: String
    let nominees: [CategoryNominee]

    /// Check if this is an actor/performer category
    var isActorCategory: Bool {
        let actorKeywords = ["actor", "actress", "supporting actor", "supporting actress"]
        let lowercaseName = name.lowercased()
        return actorKeywords.contains { lowercaseName.contains($0) }
    }

    /// Legacy accessor for backwards compatibility
    var movies: [Movie] {
        nominees.map { $0.movie }
    }
}
