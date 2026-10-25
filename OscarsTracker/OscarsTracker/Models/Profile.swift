import Foundation

nonisolated struct Profile: Codable, Identifiable {
    let id: String
    var username: String?
    var avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?
    /// Runs ceremony night (P6-01). Set on the server only.
    var isAdmin: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isAdmin = "is_admin"
    }
}
