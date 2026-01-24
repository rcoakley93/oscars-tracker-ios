import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    var username: String?
    var avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
