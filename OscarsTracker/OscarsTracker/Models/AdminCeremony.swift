import Foundation

/// A ceremony as the admin screen sees it (`admin_status()`, P6-01): its dates,
/// whether it's active, and what's been seeded into it.
nonisolated struct AdminCeremony: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let number: Int
    let name: String
    var ceremonyAt: Date
    var ballotLockAt: Date
    var isActive: Bool
    let isRehearsal: Bool
    let categories: Int
    let nominations: Int
    /// Categories with a winner set.
    var winners: Int
    let filmsWithoutPosters: Int
    /// Every registered device, which a push to everyone reaches.
    let devices: Int

    enum CodingKeys: String, CodingKey {
        case id, number, name, categories, nominations, winners, devices
        case ceremonyAt = "ceremony_at"
        case ballotLockAt = "ballot_lock_at"
        case isActive = "is_active"
        case isRehearsal = "is_rehearsal"
        case filmsWithoutPosters = "films_without_posters"
    }

    /// "24 categories · 120 nominees · 3 winners", plus missing posters.
    var seedLine: String {
        var parts = ["\(categories) categories", "\(nominations) nominees", "\(winners) of \(categories) winners"]
        if filmsWithoutPosters > 0 { parts.append("\(filmsWithoutPosters) without posters") }
        return parts.joined(separator: " · ")
    }
}

/// Where a push opens the app (`AppNavigation.Route`, send-push's `path`).
nonisolated enum PushDestination: String, CaseIterable, Identifiable, Sendable {
    case home = "/"
    case films = "/films"
    case ballot = "/ballot"
    case board = "/board"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .films: "Films"
        case .ballot: "Ballot"
        case .board: "Board"
        }
    }
}
