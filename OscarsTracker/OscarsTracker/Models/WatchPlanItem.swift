import Foundation

nonisolated struct WatchPlanItem: Codable, Identifiable, Equatable {
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

    /// A plan is for a calendar day in the viewer's own time zone, so it's missed
    /// only once that local day has passed (not at UTC midnight).
    var isMissed: Bool {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: plannedDate) else {
            return false
        }
        return date < Calendar.current.startOfDay(for: Date())
    }
}
