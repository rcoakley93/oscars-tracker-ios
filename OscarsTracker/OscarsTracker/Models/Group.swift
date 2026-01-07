import Foundation

struct Group: Codable, Identifiable {
    let id: Int
    let name: String
    let createdBy: String
    let inviteCode: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}
