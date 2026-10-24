import Foundation

/// The watch plan's two helpers (screens.md, 3.5), deterministic and local:
/// "Fill my plan" replaces the old AI auto-scheduler, and "What can I watch?"
/// suggests a film for the time you have.
nonisolated enum PlanFiller {
    struct Assignment: Equatable, Sendable {
        let movieID: Int
        let day: PlanDay
    }

    /// Spreads `films` over the days from `start` up to and including `end`,
    /// shortest first, at most `perDay` films a day (counting what's already
    /// planned), skipping `busyWeekdays` (1 = Sunday … 7 = Saturday). The
    /// open slots are taken evenly across the range, so a few films land a
    /// few days apart rather than all this week. With more films than slots,
    /// the shortest ones get planned.
    static func fill(
        films: [Movie],
        from start: PlanDay,
        through end: PlanDay,
        perDay: Int = 1,
        busyWeekdays: Set<Int> = [],
        alreadyPlanned: [PlanDay: Int] = [:],
        calendar: Calendar = .current
    ) -> [Assignment] {
        guard perDay > 0, !(end < start) else { return [] }
        var slots: [PlanDay] = []
        var day = start
        while !(end < day) {
            let weekday = calendar.component(.weekday, from: day.startDate(calendar: calendar))
            if !busyWeekdays.contains(weekday) {
                let open = perDay - (alreadyPlanned[day] ?? 0)
                if open > 0 { slots += Array(repeating: day, count: open) }
            }
            day = day.adding(days: 1, calendar: calendar)
        }
        let queue = shortestFirst(films).prefix(slots.count)
        guard !queue.isEmpty else { return [] }
        return queue.enumerated().map { index, film in
            Assignment(movieID: film.id, day: slots[index * slots.count / queue.count])
        }
    }

    /// The films that fit in `minutes`, longest first, so the first one makes
    /// the most of the evening. Films without a runtime never fit.
    static func fits(_ films: [Movie], in minutes: Int) -> [Movie] {
        films
            .filter { ($0.runtimeMinutes ?? .max) <= minutes }
            .sorted { ($0.runtimeMinutes ?? 0, $1.title) > ($1.runtimeMinutes ?? 0, $0.title) }
    }

    /// Shortest first; unknown runtimes last; ties by title.
    static func shortestFirst(_ films: [Movie]) -> [Movie] {
        films.sorted { ($0.runtimeMinutes ?? .max, $0.title) < ($1.runtimeMinutes ?? .max, $1.title) }
    }
}
