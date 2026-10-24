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

    /// Past days' films you haven't watched: one "N to reschedule" row, not a
    /// red badge on every item (the season review's UX fix).
    func toReschedule(watchedIDs: Set<Int>, today: PlanDay = .today()) -> [WatchPlanItem] {
        items.filter { item in
            guard let day = PlanDay(item.plannedDate) else { return false }
            return day < today && !watchedIDs.contains(item.movieId)
        }
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

    /// Films planned for today or later, for Fill my plan and the add sheet.
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

    func add(movieID: Int, on day: PlanDay, userID: String) async {
        do {
            items.append(try await data.addToPlan(movieID: movieID, day: day, userID: userID))
        } catch {
            actionError = AppError(error)
        }
    }

    func move(_ itemID: Int, to day: PlanDay) async {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        let previous = items[index].plannedDate
        items[index].plannedDate = day.description
        do {
            try await data.movePlanItem(id: itemID, to: day)
        } catch {
            if let index = items.firstIndex(where: { $0.id == itemID }) { items[index].plannedDate = previous }
            actionError = AppError(error)
        }
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

    /// "Move all to this week": one film a day from today, in their planned order.
    func rescheduleAll(_ overdue: [WatchPlanItem], from today: PlanDay = .today()) async {
        for (offset, item) in overdue.sorted(by: { $0.plannedDate < $1.plannedDate }).enumerated() {
            await move(item.id, to: today.adding(days: offset))
        }
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
