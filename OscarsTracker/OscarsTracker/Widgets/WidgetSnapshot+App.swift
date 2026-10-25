import Foundation

extension WidgetSnapshot {
    /// The unwatched plan items that stay useful: today and later, capped so
    /// the file stays tiny.
    static func upcoming(_ plan: [WatchPlanItem], watchedIDs: Set<Int>, titles: [Int: String], today: PlanDay, limit: Int = 30) -> [PlannedFilm] {
        plan.compactMap { item -> PlannedFilm? in
            guard !watchedIDs.contains(item.movieId), let day = PlanDay(item.plannedDate), day >= today,
                  let title = item.movie?.title ?? titles[item.movieId] else { return nil }
            return PlannedFilm(title: title, day: day)
        }
        .sorted { ($0.day, $0.title) < ($1.day, $1.title) }
        .prefix(limit)
        .map { $0 }
    }
}
