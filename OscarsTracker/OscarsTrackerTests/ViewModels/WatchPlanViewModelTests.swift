import XCTest
@testable import OscarsTracker

/// Tests for WatchPlanViewModel date grouping and computed properties.
/// Note: Tests focus on pure functions that don't require Supabase connection.
nonisolated final class WatchPlanViewModelTests: XCTestCase {

    var viewModel: WatchPlanViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = await MainActor.run { WatchPlanViewModel() }
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Grouped Items Tests

    @MainActor
    func testGroupedItems_emptyList() {
        viewModel.watchPlanItems = []

        let grouped = viewModel.groupedItems

        XCTAssertTrue(grouped.isEmpty)
    }

    @MainActor
    func testGroupedItems_todayLabel() {
        let todayItem = WatchPlanItemFactory.makeForDate(Date.today, id: 1)
        viewModel.watchPlanItems = [todayItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].label, "TODAY")
        XCTAssertEqual(grouped[0].items.count, 1)
    }

    @MainActor
    func testGroupedItems_tomorrowLabel() {
        let tomorrowItem = WatchPlanItemFactory.makeForDate(Date.tomorrow, id: 1)
        viewModel.watchPlanItems = [tomorrowItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].label, "TOMORROW")
        XCTAssertEqual(grouped[0].items.count, 1)
    }

    @MainActor
    func testGroupedItems_overdueLabel() {
        let yesterdayItem = WatchPlanItemFactory.makeForDate(Date.yesterday, id: 1)
        viewModel.watchPlanItems = [yesterdayItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].label, "OVERDUE")
        XCTAssertEqual(grouped[0].items.count, 1)
    }

    @MainActor
    func testGroupedItems_overdueComesFirst() {
        let yesterdayItem = WatchPlanItemFactory.makeForDate(Date.yesterday, id: 1)
        let todayItem = WatchPlanItemFactory.makeForDate(Date.today, id: 2)
        viewModel.watchPlanItems = [todayItem, yesterdayItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].label, "OVERDUE")
        XCTAssertEqual(grouped[1].label, "TODAY")
    }

    @MainActor
    func testGroupedItems_futureDateLabel() {
        let futureDate = Date.daysFromNow(5)
        let futureItem = WatchPlanItemFactory.makeForDate(futureDate, id: 1)
        viewModel.watchPlanItems = [futureItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 1)
        // Label should be formatted date, uppercase
        XCTAssertFalse(grouped[0].label.isEmpty)
        XCTAssertEqual(grouped[0].label, grouped[0].label.uppercased())
    }

    @MainActor
    func testGroupedItems_multipleDates() {
        let yesterdayItem = WatchPlanItemFactory.makeForDate(Date.yesterday, id: 1)
        let todayItem = WatchPlanItemFactory.makeForDate(Date.today, id: 2)
        let tomorrowItem = WatchPlanItemFactory.makeForDate(Date.tomorrow, id: 3)
        let futureItem = WatchPlanItemFactory.makeForDate(Date.daysFromNow(3), id: 4)

        viewModel.watchPlanItems = [futureItem, todayItem, yesterdayItem, tomorrowItem]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 4)
        XCTAssertEqual(grouped[0].label, "OVERDUE")
        XCTAssertEqual(grouped[1].label, "TODAY")
        XCTAssertEqual(grouped[2].label, "TOMORROW")
        // grouped[3] should be the future date
    }

    @MainActor
    func testGroupedItems_multipleItemsSameDay() {
        let todayItem1 = WatchPlanItemFactory.makeForDate(Date.today, id: 1)
        let todayItem2 = WatchPlanItemFactory.makeForDate(Date.today, id: 2)
        let todayItem3 = WatchPlanItemFactory.makeForDate(Date.today, id: 3)

        viewModel.watchPlanItems = [todayItem1, todayItem2, todayItem3]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].label, "TODAY")
        XCTAssertEqual(grouped[0].items.count, 3)
    }

    @MainActor
    func testGroupedItems_multipleOverdueItems() {
        let yesterday1 = WatchPlanItemFactory.makeForDate(Date.yesterday, id: 1)
        let twoDaysAgo = WatchPlanItemFactory.makeForDate(Date.daysFromNow(-2), id: 2)
        let weekAgo = WatchPlanItemFactory.makeForDate(Date.daysFromNow(-7), id: 3)

        viewModel.watchPlanItems = [yesterday1, twoDaysAgo, weekAgo]

        let grouped = viewModel.groupedItems

        // All overdue items should be in one "OVERDUE" group
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].label, "OVERDUE")
        XCTAssertEqual(grouped[0].items.count, 3)
    }

    @MainActor
    func testGroupedItems_datesSortedChronologically() {
        let date1 = Date.daysFromNow(5)
        let date2 = Date.daysFromNow(3)
        let date3 = Date.daysFromNow(7)

        let item1 = WatchPlanItemFactory.makeForDate(date1, id: 1)
        let item2 = WatchPlanItemFactory.makeForDate(date2, id: 2)
        let item3 = WatchPlanItemFactory.makeForDate(date3, id: 3)

        viewModel.watchPlanItems = [item1, item2, item3]

        let grouped = viewModel.groupedItems

        XCTAssertEqual(grouped.count, 3)
        // Should be sorted: day 3, day 5, day 7
        XCTAssertTrue(grouped[0].date < grouped[1].date)
        XCTAssertTrue(grouped[1].date < grouped[2].date)
    }

    // MARK: - Planned Count Tests

    @MainActor
    func testPlannedCount_empty() {
        viewModel.watchPlanItems = []
        XCTAssertEqual(viewModel.plannedCount, 0)
    }

    @MainActor
    func testPlannedCount_withItems() {
        viewModel.watchPlanItems = [
            WatchPlanItemFactory.make(id: 1),
            WatchPlanItemFactory.make(id: 2),
            WatchPlanItemFactory.make(id: 3)
        ]
        XCTAssertEqual(viewModel.plannedCount, 3)
    }

    // MARK: - Unplanned Count Tests

    @MainActor
    func testUnplannedCount_allUnplanned() {
        viewModel.movies = MovieFactory.makeList(count: 5)
        viewModel.watchPlanItems = []
        viewModel.watchedMovieIds = []

        XCTAssertEqual(viewModel.unplannedCount, 5)
    }

    @MainActor
    func testUnplannedCount_someWatched() {
        viewModel.movies = MovieFactory.makeList(count: 5)
        viewModel.watchPlanItems = []
        viewModel.watchedMovieIds = [1, 2]

        XCTAssertEqual(viewModel.unplannedCount, 3)
    }

    @MainActor
    func testUnplannedCount_somePlanned() {
        viewModel.movies = MovieFactory.makeList(count: 5)
        viewModel.watchPlanItems = [
            WatchPlanItemFactory.make(id: 1, movieId: 1),
            WatchPlanItemFactory.make(id: 2, movieId: 2)
        ]
        viewModel.watchedMovieIds = []

        XCTAssertEqual(viewModel.unplannedCount, 3)
    }

    @MainActor
    func testUnplannedCount_allPlannedOrWatched() {
        viewModel.movies = MovieFactory.makeList(count: 5)
        viewModel.watchPlanItems = [
            WatchPlanItemFactory.make(id: 1, movieId: 1),
            WatchPlanItemFactory.make(id: 2, movieId: 2)
        ]
        viewModel.watchedMovieIds = [3, 4, 5]

        XCTAssertEqual(viewModel.unplannedCount, 0)
    }

    @MainActor
    func testUnplannedCount_noMovies() {
        viewModel.movies = []
        viewModel.watchPlanItems = []
        viewModel.watchedMovieIds = []

        XCTAssertEqual(viewModel.unplannedCount, 0)
    }

    // MARK: - Watched Count Tests

    @MainActor
    func testWatchedCount_empty() {
        viewModel.watchedMovieIds = []
        XCTAssertEqual(viewModel.watchedCount, 0)
    }

    @MainActor
    func testWatchedCount_withWatched() {
        viewModel.watchedMovieIds = [1, 2, 3, 4]
        XCTAssertEqual(viewModel.watchedCount, 4)
    }

    // MARK: - Movie For Item Tests

    @MainActor
    func testMovieForItem_found() {
        let movie = MovieFactory.make(id: 1, title: "Test Movie")
        viewModel.movies = [movie]

        let item = WatchPlanItemFactory.make(id: 1, movieId: 1)

        let foundMovie = viewModel.movie(for: item)

        XCTAssertNotNil(foundMovie)
        XCTAssertEqual(foundMovie?.id, 1)
        XCTAssertEqual(foundMovie?.title, "Test Movie")
    }

    @MainActor
    func testMovieForItem_notFound() {
        viewModel.movies = [MovieFactory.make(id: 1)]

        let item = WatchPlanItemFactory.make(id: 1, movieId: 999)

        let foundMovie = viewModel.movie(for: item)

        XCTAssertNil(foundMovie)
    }

    @MainActor
    func testMovieForItem_emptyMoviesList() {
        viewModel.movies = []

        let item = WatchPlanItemFactory.make(id: 1, movieId: 1)

        let foundMovie = viewModel.movie(for: item)

        XCTAssertNil(foundMovie)
    }

    // MARK: - Clear Error Tests

    @MainActor
    func testClearError() {
        viewModel.errorMessage = "Some error"
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState() {
        let vm = WatchPlanViewModel()
        XCTAssertTrue(vm.watchPlanItems.isEmpty)
        XCTAssertTrue(vm.movies.isEmpty)
        XCTAssertTrue(vm.watchedMovieIds.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Auto Scheduler Request/Response Codable Tests

    @MainActor
    func testAutoSchedulerRequestCodable() throws {
        let request = WatchPlanViewModel.AutoSchedulerRequest(
            userPrompt: "Schedule movies for the weekend",
            today: "2024-01-15",
            moviesPool: [
                WatchPlanViewModel.AutoSchedulerRequest.MoviePoolItem(id: 1, title: "Movie 1", runtimeMinutes: 120),
                WatchPlanViewModel.AutoSchedulerRequest.MoviePoolItem(id: 2, title: "Movie 2", runtimeMinutes: 90)
            ],
            existingSchedule: [
                WatchPlanViewModel.AutoSchedulerRequest.ExistingScheduleItem(movieId: 3, title: "Already Scheduled", date: "2024-01-16")
            ]
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(WatchPlanViewModel.AutoSchedulerRequest.self, from: data)

        XCTAssertEqual(decoded.userPrompt, "Schedule movies for the weekend")
        XCTAssertEqual(decoded.today, "2024-01-15")
        XCTAssertEqual(decoded.moviesPool.count, 2)
        XCTAssertEqual(decoded.existingSchedule.count, 1)
    }

    @MainActor
    func testAutoSchedulerResponseCodable() throws {
        let json = """
        {
            "plan": [
                {"movie_id": 1, "date": "2024-01-16", "reason": "Good movie for Saturday"},
                {"movie_id": 2, "date": "2024-01-17", "reason": null}
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WatchPlanViewModel.AutoSchedulerResponse.self, from: json)

        XCTAssertEqual(response.plan.count, 2)
        XCTAssertEqual(response.plan[0].movieId, 1)
        XCTAssertEqual(response.plan[0].date, "2024-01-16")
        XCTAssertEqual(response.plan[0].reason, "Good movie for Saturday")
        XCTAssertNil(response.plan[1].reason)
    }
}
