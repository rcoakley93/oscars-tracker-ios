import Foundation

/// Why someone reports a person or a group (guideline 1.2, P6-16); the raw
/// values are `reports.reason`.
nonisolated enum ReportReason: String, Codable, CaseIterable, Identifiable, Sendable {
    case offensiveName = "offensive_name"
    case harassment
    case spam
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .offensiveName: "Offensive name"
        case .harassment: "Harassment"
        case .spam: "Spam"
        case .other: "Something else"
        }
    }
}

/// What a report is about.
nonisolated enum ReportTarget: Hashable, Identifiable, Sendable {
    case person(id: String, name: String)
    case group(id: Int, name: String)

    var id: String {
        switch self {
        case .person(let id, _): "person-\(id)"
        case .group(let id, _): "group-\(id)"
        }
    }

    var name: String {
        switch self {
        case .person(_, let name), .group(_, let name): name
        }
    }
}

/// Someone you've blocked (`get_blocked_users()`).
nonisolated struct BlockedUser: Codable, Identifiable, Hashable, Sendable {
    let userId: String
    /// Nil once the admin has cleared their name.
    let username: String?
    let avatarUrl: String?
    let blockedAt: Date?

    var id: String { userId }
    var name: String { username ?? "Someone" }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case blockedAt = "blocked_at"
    }
}

/// A report in the admin's queue (`admin_reports()`).
nonisolated struct ContentReport: Codable, Identifiable, Hashable, Sendable {
    nonisolated enum Kind: String, Codable, Sendable {
        case user, group
    }

    nonisolated enum Status: String, Codable, Sendable {
        case open, actioned, dismissed
    }

    let id: Int
    let kind: Kind
    let reason: ReportReason
    let details: String?
    /// The name when it was reported.
    let reportedName: String
    /// The name now; nil once cleared, or if the person or group is gone.
    let currentName: String?
    let reportedUserId: String?
    let groupId: Int?
    let reporterName: String?
    var status: Status
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, kind, reason, details, status
        case reportedName = "reported_name"
        case currentName = "current_name"
        case reportedUserId = "reported_user_id"
        case groupId = "group_id"
        case reporterName = "reporter_name"
        case createdAt = "created_at"
    }

    /// The person or group is gone, so there's no name left to clear.
    var targetIsGone: Bool { kind == .user ? reportedUserId == nil : groupId == nil }
}

/// What the admin does with a report.
nonisolated enum ReportAction: String, Sendable {
    /// Closes it and changes nothing.
    case dismiss
    /// Empties the username (its owner picks a new one) or renames the group "Group <id>".
    case clearName = "clear_name"
}
