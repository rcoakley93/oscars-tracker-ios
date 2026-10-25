import Foundation
import Testing
@testable import OscarsTracker

@Suite("Widgets (P6-09)")
struct WidgetTests {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ day: String, hour: Int = 12) -> Date {
        let d = PlanDay(day)!
        return utc.date(byAdding: .hour, value: hour, to: d.startDate(calendar: utc))!
    }

    private var snapshot: WidgetSnapshot {
        WidgetSnapshot(ceremonyAt: date("2027-03-14", hour: 20), filmsTotal: 60, filmsWatched: 22,
                       plan: [.init(title: "Hamnet", day: PlanDay("2027-02-01")!), .init(title: "Sinners", day: PlanDay("2027-02-02")!),
                              .init(title: "Bugonia", day: PlanDay("2027-02-02")!)],
                       savedAt: date("2027-02-01"))
    }

    @Test func entryCountsDaysAndFilmsLeft() {
        let entry = WidgetEntry.make(snapshot, at: date("2027-02-04"), calendar: utc)
        #expect(entry.daysToCeremony == 38)
        #expect(entry.filmsLeft == 38)
        #expect(entry.tonight == nil)
    }

    @Test func daysEndAfterTheCeremony() {
        #expect(WidgetEntry.make(snapshot, at: date("2027-03-14"), calendar: utc).daysToCeremony == 0)
        #expect(WidgetEntry.make(snapshot, at: date("2027-03-15"), calendar: utc).daysToCeremony == nil)
    }

    @Test func tonightIsTodaysFilmAndCountsTheRest() {
        let entry = WidgetEntry.make(snapshot, at: date("2027-02-02"), calendar: utc)
        #expect(entry.tonight == "Bugonia" || entry.tonight == "Sinners")
        #expect(entry.tonightExtra == 1)
    }

    @Test func timelineRollsOverAtEachMidnight() {
        let now = date("2027-02-01", hour: 18)
        let entries = WidgetEntry.timeline(snapshot, now: now, days: 3, calendar: utc)
        #expect(entries.count == 4)
        #expect(entries[0].date == now)
        #expect(entries[1].date == date("2027-02-02", hour: 0))
        #expect(entries.map(\.daysToCeremony) == [41, 40, 39, 38])
        #expect(entries[0].tonight == "Hamnet")
        #expect(entries[3].tonight == nil)
        #expect(WidgetEntry.refreshDate(now: now, days: 3, calendar: utc) == date("2027-02-05", hour: 0))
    }

    @Test func upcomingKeepsUnwatchedPlansFromTodayOn() {
        let plan = [
            WatchPlanItem(id: 1, userId: "u", movieId: 1, plannedDate: "2027-01-30", createdAt: nil),
            WatchPlanItem(id: 2, userId: "u", movieId: 2, plannedDate: "2027-02-02", createdAt: nil),
            WatchPlanItem(id: 3, userId: "u", movieId: 3, plannedDate: "2027-02-01", createdAt: nil),
            WatchPlanItem(id: 4, userId: "u", movieId: 4, plannedDate: "2027-02-03", createdAt: nil),
        ]
        let upcoming = WidgetSnapshot.upcoming(plan, watchedIDs: [3], titles: [1: "A", 2: "B", 3: "C"], today: PlanDay("2027-02-01")!)
        #expect(upcoming.map(\.title) == ["B"])
    }

    @Test func snapshotRoundTripsThroughTheStoreAndReportsChanges() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(directory: directory)
        #expect(store.read() == nil)
        #expect(store.write(snapshot))
        #expect(store.read() == snapshot)
        var later = snapshot
        later.savedAt = .now
        #expect(!store.write(later))
        later.filmsWatched = 23
        #expect(store.write(later))
        store.clear()
        #expect(store.read() == nil)
        #expect(!WidgetSnapshotStore.none.write(snapshot))
    }

    @Test func copyIsPlural() {
        #expect(WidgetCopy.filmsLeft(1) == "1 film left")
        #expect(WidgetCopy.filmsLeft(38) == "38 films left")
        #expect(WidgetCopy.accessibility(.empty) == WidgetCopy.noSeason)
        #expect(WidgetCopy.accessibility(.sample) == "38 days to go, 38 films left")
    }
}
