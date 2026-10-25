import Foundation
import Testing
@testable import OscarsTracker

@Suite("Fill my plan and What can I watch")
struct PlanFillerTests {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func film(_ id: Int, _ minutes: Int?, _ title: String = "") -> Movie {
        Movie(id: id, title: title.isEmpty ? "Film \(id)" : title, posterUrl: nil, releaseYear: nil, runtimeMinutes: minutes, createdAt: nil)
    }

    /// Monday, Feb 1, 2027.
    private var monday: PlanDay { PlanDay(year: 2027, month: 2, day: 1) }

    @Test func spreadsFilmsShortestFirstOverTheDays() {
        let films = [film(1, 150), film(2, 90), film(3, 120)]
        let plan = PlanFiller.fill(films: films, from: monday, through: monday.adding(days: 5, calendar: utc), calendar: utc)
        #expect(plan.map(\.movieID) == [2, 3, 1])
        #expect(plan.map(\.day.description) == ["2027-02-01", "2027-02-03", "2027-02-05"])
    }

    @Test func skipsBusyDaysAndFullDays() {
        let films = [film(1, 90), film(2, 100), film(3, 110)]
        // Tuesday (3) is busy and Monday already has a film.
        let plan = PlanFiller.fill(films: films, from: monday, through: monday.adding(days: 2, calendar: utc),
                                   busyWeekdays: [3], alreadyPlanned: [monday: 1], calendar: utc)
        #expect(plan == [PlanFiller.Assignment(movieID: 1, day: monday.adding(days: 2, calendar: utc))])
    }

    @Test func plansSeveralADayAndTheShortestWhenThereIsNoRoom() {
        let films = [film(1, 200), film(2, 90), film(3, 100), film(4, nil)]
        let plan = PlanFiller.fill(films: films, from: monday, through: monday, perDay: 2, calendar: utc)
        #expect(plan.map(\.movieID) == [2, 3])
        #expect(Set(plan.map(\.day)) == [monday])
    }

    @Test func plansNothingWithoutDaysOrFilms() {
        #expect(PlanFiller.fill(films: [film(1, 90)], from: monday, through: monday.adding(days: -1, calendar: utc), calendar: utc).isEmpty)
        #expect(PlanFiller.fill(films: [], from: monday, through: monday, calendar: utc).isEmpty)
    }

    @Test func suggestsTheLongestFilmThatFits() {
        let films = [film(1, 96, "KPop Demon Hunters"), film(2, 126), film(3, 40), film(4, nil)]
        #expect(PlanFiller.fits(films, in: 120).map(\.id) == [1, 3])
        #expect(PlanFiller.fits(films, in: 30).isEmpty)
    }

    @Test func readsTheRuntimeBucketsShortestFirst() {
        let buckets = RuntimeBucket.parse(["standard": [91, 120], "short": [0, 40], "medium": [41, 90], "broken": [5]])
        #expect(buckets.map(\.name) == ["short", "medium", "standard"])
        #expect(buckets.last?.minutes == 91...120)
    }

    @Test func bothVoicesCarryThePlanNumbers() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(copy.planReschedule(4).contains("4"))
            #expect(copy.planFillDone(12, 9).contains("12 films"))
            #expect(copy.planFillDone(12, 9).contains("9"))
            #expect(copy.planFit("KPop Demon Hunters", "1h 36m").contains("KPop Demon Hunters"))
            #expect(copy.planFit("KPop Demon Hunters", "1h 36m").contains("1h 36m"))
        }
    }
}

@MainActor
@Suite("Plan store")
struct PlanStoreTests {
    private let user = SampleDataSource.userID

    @Test func theAgendaShowsTheWeekThenLaterDaysWithFilms() async {
        let data = SampleDataSource()
        let today = PlanDay.today()
        data.planItems.append(SampleData.planItem(id: 9, movieID: 6, day: today.adding(days: 20)))
        let store = PlanStore(data: data)
        await store.load(userID: user)
        let agenda = store.agenda(today: today)
        #expect(agenda.count == 8)
        #expect(agenda.first?.day == today)
        #expect(agenda.last?.day == today.adding(days: 20))
        #expect(store.pastDays(today: today).map(\.day) == [today.adding(days: -2)])
    }

    @Test func movesSeveralFilmsToADay() async {
        let store = PlanStore(data: SampleDataSource())
        await store.load(userID: user)
        let target = PlanDay.today().adding(days: 3)
        await store.move([2, 3], to: target)
        #expect(store.items(on: target).map(\.id).sorted() == [2, 3])
    }

    @Test func fillAddsEachAssignment() async {
        let store = PlanStore(data: SampleDataSource())
        await store.load(userID: user)
        let day = PlanDay.today().adding(days: 4)
        let added = await store.fill([.init(movieID: 8, day: day), .init(movieID: 9, day: day)], userID: user)
        #expect(added == 2)
        #expect(store.items(on: day).map(\.movieId).sorted() == [8, 9])
        #expect(store.plannedMovieIDs().isSuperset(of: [8, 9]))
    }

    @Test func fillStopsAtAFailure() async {
        let data = SampleDataSource()
        let store = PlanStore(data: data)
        await store.load(userID: user)
        data.failure = .offline
        let added = await store.fill([.init(movieID: 8, day: .today())], userID: user)
        #expect(added == 0)
        #expect(store.actionError == .offline)
    }
}

@MainActor
@Suite("Planning a film twice")
struct PlanTwiceTests {
    private func loaded() async -> (PlanStore, SampleDataSource) {
        let data = SampleDataSource()
        let store = PlanStore(data: data)
        await store.load(userID: SampleDataSource.userID)
        return (store, data)
    }

    @Test func addingAPlannedFilmMovesIt() async {
        let (store, data) = await loaded()
        let before = store.items.count
        let day = PlanDay.today().adding(days: 4)
        // Film 2 is on the plan two days ago in the sample season.
        await store.add(movieID: 2, on: day, userID: SampleDataSource.userID)
        #expect(store.items.count == before)
        #expect(store.plannedDay(of: 2) == day)
        #expect(store.actionError == nil)
        #expect(data.planItems.filter { $0.movieId == 2 }.count == 1)
    }

    @Test func aFailedMoveRollsBack() async {
        let (store, data) = await loaded()
        let original = store.plannedDay(of: 2)
        data.failure = .offline
        await store.add(movieID: 2, on: PlanDay.today().adding(days: 4), userID: SampleDataSource.userID)
        #expect(store.plannedDay(of: 2) == original)
        #expect(store.actionError == .offline)
    }

    @Test func addingANewFilmStillAdds() async {
        let (store, _) = await loaded()
        let before = store.items.count
        await store.add(movieID: 9, on: .today(), userID: SampleDataSource.userID)
        #expect(store.items.count == before + 1)
    }

    @Test func fillingPlansAFilmThatIsAlreadyPlannedByMovingIt() async {
        let (store, _) = await loaded()
        let before = store.items.count
        let day = PlanDay.today().adding(days: 3)
        let added = await store.fill([PlanFiller.Assignment(movieID: 2, day: day)], userID: SampleDataSource.userID)
        #expect(added == 1)
        #expect(store.items.count == before)
        #expect(store.plannedDay(of: 2) == day)
    }

    @Test func aDuplicateKeyErrorHasPlainCopy() {
        let error = AppError(serverMessage: #"duplicate key value violates unique constraint "watch_plan_user_id_movie_id_key""#, code: "23505")
        #expect(error == .alreadyPlanned)
        #expect(!error.message.isEmpty)
        #expect(AppError(serverMessage: "duplicate key value violates unique constraint \"profiles_username_key\"", code: "23505") != .alreadyPlanned)
    }
}
