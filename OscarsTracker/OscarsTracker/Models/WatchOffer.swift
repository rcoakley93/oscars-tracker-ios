import Foundation

/// One way to watch a film in the US (screens.md, 3.2): a row of
/// `movie_provider_availability` with its provider, from the daily TMDB sync
/// (JustWatch data).
nonisolated struct WatchOffer: Decodable, Identifiable, Hashable, Sendable {
    enum Kind: String, CaseIterable, Sendable {
        case stream, theaters, rent, buy, library, special

        /// The database's `availability_type`; anything new reads as special.
        init(availability: String) {
            switch availability.lowercased() {
            case "streaming", "stream", "flatrate", "free", "ads": self = .stream
            case "theaters", "theatres", "theatrical": self = .theaters
            case "rent": self = .rent
            case "buy": self = .buy
            case "library": self = .library
            default: self = .special
            }
        }

        var label: String {
            switch self {
            case .stream: "Stream"
            case .theaters: "In theaters"
            case .rent: "Rent"
            case .buy: "Buy"
            case .library: "Library"
            case .special: "Special"
            }
        }

        /// What the row says under the provider's name.
        var detail: String {
            switch self {
            case .stream: "Included with subscription"
            case .theaters: "Showing near you"
            case .rent: "Rent digitally"
            case .buy: "Buy digitally"
            case .library: "Free with a library card"
            case .special: "Special screening"
            }
        }
    }

    struct Provider: Decodable, Hashable, Sendable {
        let name: String
        let logoPath: String?

        enum CodingKeys: String, CodingKey {
            case name
            case logoPath = "logo_path"
        }
    }

    let id: Int
    let availabilityType: String
    let provider: Provider

    enum CodingKeys: String, CodingKey {
        case id
        case availabilityType = "availability_type"
        case provider = "providers"
    }

    var kind: Kind { Kind(availability: availabilityType) }

    /// TMDB's provider logo at 92 px.
    var logoURL: URL? {
        provider.logoPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w92\($0)") }
    }

    /// Stream first, then theaters, rent, buy and the rest, each by provider name.
    static func sorted(_ offers: [WatchOffer]) -> [WatchOffer] {
        offers.sorted {
            let a = Kind.allCases.firstIndex(of: $0.kind)!, b = Kind.allCases.firstIndex(of: $1.kind)!
            return a != b ? a < b : $0.provider.name.localizedCaseInsensitiveCompare($1.provider.name) == .orderedAscending
        }
    }
}

/// One row of `get_movie_seen_in_groups(p_movie_id)`: how many of a group's
/// members have watched a film. Counts only, never who.
nonisolated struct GroupSeen: Decodable, Identifiable, Hashable, Sendable {
    var id: Int { groupId }
    let groupId: Int
    let groupName: String
    let memberCount: Int
    let seenCount: Int

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
        case memberCount = "member_count"
        case seenCount = "seen_count"
    }
}
