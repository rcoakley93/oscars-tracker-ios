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
