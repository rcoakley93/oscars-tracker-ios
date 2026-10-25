import Foundation

nonisolated struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let year: Int?
    let createdAt: String?
    /// Whether the ballot leads with the person or the film (P2-08).
    let displayMode: BallotCategory.DisplayMode?

    enum CodingKeys: String, CodingKey {
        case id, name, year
        case displayMode = "display_mode"
        case pointsValue = "points_value"
        case createdAt = "created_at"
    }
}
