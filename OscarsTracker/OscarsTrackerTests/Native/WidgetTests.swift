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
                       savedAt: date("2027-02-01"), ceremonyNumber: 99, ballotLockAt: date("2027-03-14", hour: 16),
                       nominationsAt: date("2027-01-21", hour: 13), stage: .nominated, categoriesPicked: 9, categoriesTotal: 24)
    }

    private var contenders: WidgetSnapshot {
        var contenders = snapshot
        contenders.stage = .predicted
        contenders.filmsTotal = 40
        contenders.filmsWatched = 7
        return contenders
    }

    @Test func phaseFollowsTheSeason() {
        #expect(WidgetEntry.phase(contenders, at: date("2026-10-27"), calendar: utc) == .contenders(daysToNominations: 86, shortlisted: false))
        #expect(WidgetEntry.phase(snapshot, at: date("2027-02-04"), calendar: utc) == .season(daysToCeremony: 38))
        #expect(WidgetEntry.phase(snapshot, at: date("2027-03-14", hour: 11), calendar: utc) == .lockDay(locksAt: date("2027-03-14", hour: 16)))
        #expect(WidgetEntry.phase(snapshot, at: date("2027-03-14", hour: 17), calendar: utc) == .showtime(startsAt: date("2027-03-14", hour: 20)))
        #expect(WidgetEntry.phase(snapshot, at: date("2027-03-15", hour: 2), calendar: utc) == .results)
        #expect(WidgetEntry.phase(snapshot, at: date("2027-07-10"), calendar: utc) == .offSeason)
        #expect(WidgetEntry.phase(.empty, at: date("2027-07-10"), calendar: utc) == .empty)
    }

    @Test func aTwoPointOhSnapshotStillDecodesAsNominees() throws {
        let old = #"{"ceremonyAt":800000000,"filmsTotal":60,"filmsWatched":22,"plan":[],"savedAt":790000000}"#
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: Data(old.utf8))
        #expect(decoded.hasNominees)
        #expect(decoded.posters == nil)
    }

    @Test func tonightIsTodaysFilmAndCountsTheRest() {
        let entry = WidgetEntry.make(snapshot, at: date("2027-02-02"), calendar: utc)
        #expect(entry.tonight == "Bugonia" || entry.tonight == "Sinners")
        #expect(entry.tonightExtra == 1)
        #expect(WidgetEntry.make(snapshot, at: date("2027-01-30"), calendar: utc).next?.title == "Hamnet")
    }

    @Test func timelineRollsOverAtEachMidnightAndEachTurn() {
        let now = date("2027-02-01", hour: 18)
        let entries = WidgetEntry.timeline(snapshot, now: now, days: 3, calendar: utc)
        #expect(entries.count == 4)
        #expect(entries[0].date == now)
        #expect(entries[1].date == date("2027-02-02", hour: 0))
        #expect(entries.map(\.phase) == [41, 40, 39, 38].map { .season(daysToCeremony: $0) })
        #expect(entries[0].tonight == "Hamnet")
        #expect(entries[3].tonight == nil)
        #expect(WidgetEntry.refreshDate(now: now, days: 3, calendar: utc) == date("2027-02-05", hour: 0))

        let lockWeek = WidgetEntry.timeline(snapshot, now: date("2027-03-12"), days: 3, calendar: utc).map(\.date)
        #expect(lockWeek.contains(date("2027-03-13", hour: 16)))
        #expect(lockWeek.contains(date("2027-03-14", hour: 16)))
        #expect(lockWeek.contains(date("2027-03-14", hour: 20)))
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

    @Test func faceSaysWhatEachStateIsAbout() {
        let early = WidgetCopy.face(WidgetEntry.make(contenders, at: date("2026-10-27"), calendar: utc))
        #expect(early.count == 7 && early.of == 40 && early.frames == .films)
        #expect(early.foot == "86 days to nominations")
        let season = WidgetCopy.face(WidgetEntry.make(snapshot, at: date("2027-02-04"), calendar: utc))
        #expect(season.foot == "38 days · 9 of 24 picked")
        let lock = WidgetCopy.face(WidgetEntry.make(snapshot, at: date("2027-03-14", hour: 11), calendar: utc))
        #expect(lock.count == 9 && lock.of == 24 && lock.frames == .picks)
        #expect(lock.countdownTo == date("2027-03-14", hour: 16))
        #expect(WidgetCopy.face(.results).rectangularLine == "3rd of 212")
        #expect(WidgetCopy.face(.offSeason).inline == "Last season: 15 of 24 right")
        #expect(WidgetCopy.days(1) == "1 day")
        for sample in WidgetEntry.allSamples {
            #expect(!WidgetCopy.face(sample.entry).accessibility.contains("Open Oscars Tracker"))
        }
    }
}
