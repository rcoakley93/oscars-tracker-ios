import Foundation
import Observation

/// Your watch plan: which film on which day.
@Observable
final class PlanStore {
    struct Day: Identifiable, Equatable {
        var id: PlanDay { day }
        let day: PlanDay
        let items: [WatchPlanItem]
    }

    private(set) var items: [WatchPlanItem] = []
    private(set) var state: LoadState = .idle
    var actionError: AppError?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load(userID: String) async {
        state = .loading
        do {
            items = try await data.plan(userID: userID)
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// The last good copy, at launch, until the network answers.
    func restore(items: [WatchPlanItem]) {
        guard self.items.isEmpty, !items.isEmpty else { return }
        self.items = items
        state = .loaded
    }

    /// Today and later, by day.
    func upcomingDays(today: PlanDay = .today()) -> [Day] {
        days(where: { $0 >= today })
    }

    /// The agenda: today and the next `minimumDays - 1` days, empty or not,
    /// then every later day that has films.
    func agenda(today: PlanDay = .today(), minimumDays: Int = 7) -> [Day] {
        let planned = Dictionary(uniqueKeysWithValues: upcomingDays(today: today).map { ($0.day, $0) })
        let week = (0..<minimumDays).map { today.adding(days: $0) }
        let days = Set(week).union(planned.keys).sorted()
        return days.map { planned[$0] ?? Day(day: $0, items: []) }
    }

    /// Days before today that have films, newest first ("Show past days").
    func pastDays(today: PlanDay = .today()) -> [Day] {
        days(where: { $0 < today }).reversed()
    }

    /// Every film on the plan, whatever its day.
    var allPlannedMovieIDs: Set<Int> { Set(items.map(\.movieId)) }

    /// Films planned for today or later, for the add sheet.
    func plannedMovieIDs(from today: PlanDay = .today()) -> Set<Int> {
        Set(upcomingDays(today: today).flatMap(\.items).map(\.movieId))
    }

    /// How many films each day from today already has, for Fill my plan.
    func countsByDay(from today: PlanDay = .today()) -> [PlanDay: Int] {
        Dictionary(uniqueKeysWithValues: upcomingDays(today: today).map { ($0.day, $0.items.count) })
    }

    /// The films planned for one day.
    func items(on day: PlanDay) -> [WatchPlanItem] {
        items.filter { PlanDay($0.plannedDate) == day }
    }

    private func days(where include: (PlanDay) -> Bool) -> [Day] {
        let byDay = Dictionary(grouping: items.compactMap { item in PlanDay(item.plannedDate).map { ($0, item) } }, by: \.0)
        return byDay.keys.filter(include).sorted().map { Day(day: $0, items: byDay[$0]!.map(\.1)) }
    }

    /// Plans a film. A film is on the plan once, so one that's already there
    /// moves to `day` instead of being added again.
    func add(movieID: Int, on day: PlanDay, userID: String) async {
        if let existing = items.first(where: { $0.movieId == movieID }) {
            await move(existing.id, to: day)
            return
        }
        do {
            items.append(try await data.addToPlan(movieID: movieID, day: day, userID: userID))
        } catch {
            actionError = AppError(error)
        }
    }

    func move(_ itemID: Int, to day: PlanDay) async {
        await moveItem(itemID, to: day)
    }

    /// Moves a film optimistically; returns false (and rolls back) if it fails.
    @discardableResult
    private func moveItem(_ itemID: Int, to day: PlanDay) async -> Bool {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return false }
        let previous = items[index].plannedDate
        items[index].plannedDate = day.description
        do {
            try await data.movePlanItem(id: itemID, to: day)
            return true
        } catch {
            if let index = items.firstIndex(where: { $0.id == itemID }) { items[index].plannedDate = previous }
            actionError = AppError(error)
            return false
        }
    }

    /// Where a film is planned, if it is.
    func plannedDay(of movieID: Int) -> PlanDay? {
        items.first { $0.movieId == movieID }.flatMap { PlanDay($0.plannedDate) }
    }

    /// Moves several films to one day (a drag between days, or Reschedule).
    func move(_ itemIDs: [Int], to day: PlanDay) async {
        for id in itemIDs where items.first(where: { $0.id == id }).flatMap({ PlanDay($0.plannedDate) }) != day {
            await move(id, to: day)
        }
    }

    /// Adds Fill my plan's assignments; returns how many were saved. Stops
    /// at the first failure, which `actionError` reports.
    @discardableResult
    func fill(_ assignments: [PlanFiller.Assignment], userID: String) async -> Int {
        var added = 0
        for assignment in assignments {
            if let existing = items.first(where: { $0.movieId == assignment.movieID }) {
                guard await moveItem(existing.id, to: assignment.day) else { break }
                added += 1
                continue
            }
            do {
                items.append(try await data.addToPlan(movieID: assignment.movieID, day: assignment.day, userID: userID))
                added += 1
            } catch {
                actionError = AppError(error)
                break
            }
        }
        return added
    }

    func remove(_ itemID: Int) async {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        let removed = items.remove(at: index)
        do {
            try await data.removePlanItem(id: itemID)
        } catch {
            items.insert(removed, at: min(index, items.count))
            actionError = AppError(error)
        }
    }

    func reset() {
        items = []
        state = .idle
    }
}
