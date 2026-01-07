import Foundation

struct WatchPlanItem: Codable, Identifiable {
    let id: Int
    let userId: String
    let movieId: Int
    var plannedDate: String
    let createdAt: String?

    var movie: Movie?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case movieId = "movie_id"
        case plannedDate = "planned_date"
        case createdAt = "created_at"
        case movie
    }

    init(id: Int, userId: String, movieId: Int, plannedDate: String, createdAt: String?) {
        self.id = id
        self.userId = userId
        self.movieId = movieId
        self.plannedDate = plannedDate
        self.createdAt = createdAt
    }

    var isMissed: Bool {
        guard let date = ISO8601DateFormatter().date(from: plannedDate + "T00:00:00Z") else {
            return false
        }
        return date < Calendar.current.startOfDay(for: Date())
    }
}
