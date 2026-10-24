import Foundation

/// The result of `join_group(p_invite_code)`.
nonisolated struct JoinedGroup: Codable, Hashable, Sendable {
    let groupId: Int
    let groupName: String

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
    }
}
