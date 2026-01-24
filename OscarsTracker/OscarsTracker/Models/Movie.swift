import Foundation

struct Movie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let posterUrl: String?
    let releaseYear: Int?
    let runtimeMinutes: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case posterUrl = "poster_url"
        case releaseYear = "release_year"
        case runtimeMinutes = "runtime_minutes"
        case createdAt = "created_at"
    }

    var formattedRuntime: String {
        guard let minutes = runtimeMinutes else { return "" }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}
