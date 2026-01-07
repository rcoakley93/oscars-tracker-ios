import Foundation

struct Nomination: Codable, Identifiable {
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

struct CategoryWithNominations: Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let nominations: [Nomination]
}
