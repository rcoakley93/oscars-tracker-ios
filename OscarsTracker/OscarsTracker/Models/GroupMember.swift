import Foundation

nonisolated struct GroupMember: Codable, Identifiable {
    let id: Int
    let groupId: Int?
    let userId: String?
    let joinedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}
