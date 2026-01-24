import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let year: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, year
        case pointsValue = "points_value"
        case createdAt = "created_at"
    }
}
