import Foundation

struct UserPrediction: Codable, Identifiable {
    let id: Int
    let userId: String
    let categoryId: Int
    let nominationId: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case nominationId = "nomination_id"
        case createdAt = "created_at"
    }
}
