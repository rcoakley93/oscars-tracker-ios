import XCTest
@testable import OscarsTracker

/// Tests for DashboardViewModel sorting and computed properties.
/// Note: Tests focus on pure functions that don't require Supabase connection.
@MainActor
final class DashboardViewModelTests: XCTestCase {

    var viewModel: DashboardViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = DashboardViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Sort Option Tests

    @MainActor
    func testSortedMovies_titleAZ() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Zebra"),
            MovieFactory.make(id: 2, title: "Apple"),
            MovieFactory.make(id: 3, title: "Mango")
        ]
        viewModel.sortOption = .titleAZ

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted[0].title, "Apple")
        XCTAssertEqual(sorted[1].title, "Mango")
        XCTAssertEqual(sorted[2].title, "Zebra")
    }

    @MainActor
    func testSortedMovies_titleZA() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Apple"),
            MovieFactory.make(id: 2, title: "Zebra"),
            MovieFactory.make(id: 3, title: "Mango")
        ]
        viewModel.sortOption = .titleZA

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted[0].title, "Zebra")
        XCTAssertEqual(sorted[1].title, "Mango")
        XCTAssertEqual(sorted[2].title, "Apple")
    }

    @MainActor
    func testSortedMovies_runtimeAscending() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Long", runtimeMinutes: 180),
            MovieFactory.make(id: 2, title: "Short", runtimeMinutes: 90),
            MovieFactory.make(id: 3, title: "Medium", runtimeMinutes: 120)
        ]
        viewModel.sortOption = .runtimeAsc

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted[0].title, "Short")
        XCTAssertEqual(sorted[1].title, "Medium")
        XCTAssertEqual(sorted[2].title, "Long")
    }

    @MainActor
    func testSortedMovies_runtimeDescending() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Short", runtimeMinutes: 90),
            MovieFactory.make(id: 2, title: "Long", runtimeMinutes: 180),
            MovieFactory.make(id: 3, title: "Medium", runtimeMinutes: 120)
        ]
        viewModel.sortOption = .runtimeDesc

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted[0].title, "Long")
        XCTAssertEqual(sorted[1].title, "Medium")
        XCTAssertEqual(sorted[2].title, "Short")
    }

    @MainActor
    func testSortedMovies_runtimeWithNilValues() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "No Runtime", runtimeMinutes: nil),
            MovieFactory.make(id: 2, title: "Long", runtimeMinutes: 180),
            MovieFactory.make(id: 3, title: "Short", runtimeMinutes: 90)
        ]
        viewModel.sortOption = .runtimeAsc

        let sorted = viewModel.sortedMovies

        // nil runtime should be treated as 0
        XCTAssertEqual(sorted[0].title, "No Runtime")
        XCTAssertEqual(sorted[1].title, "Short")
        XCTAssertEqual(sorted[2].title, "Long")
    }

    @MainActor
    func testSortedMovies_caseInsensitiveSort() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "apple"),
            MovieFactory.make(id: 2, title: "BANANA"),
            MovieFactory.make(id: 3, title: "Cherry")
        ]
        viewModel.sortOption = .titleAZ

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted[0].title, "apple")
        XCTAssertEqual(sorted[1].title, "BANANA")
        XCTAssertEqual(sorted[2].title, "Cherry")
    }

    @MainActor
    func testSortedMovies_emptyList() {
        viewModel.movies = []
        viewModel.sortOption = .titleAZ

        let sorted = viewModel.sortedMovies

        XCTAssertTrue(sorted.isEmpty)
    }

    @MainActor
    func testSortedMovies_singleMovie() {
        viewModel.movies = [MovieFactory.make(id: 1, title: "Only Movie")]
        viewModel.sortOption = .titleAZ

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted[0].title, "Only Movie")
    }

    @MainActor
    func testSortedMovies_sameTitle() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Same Title"),
            MovieFactory.make(id: 2, title: "Same Title"),
            MovieFactory.make(id: 3, title: "Same Title")
        ]
        viewModel.sortOption = .titleAZ

        let sorted = viewModel.sortedMovies

        // Should maintain stable sort
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].title, "Same Title")
    }

    @MainActor
    func testSortedMovies_sameRuntime() {
        viewModel.movies = [
            MovieFactory.make(id: 1, title: "Movie A", runtimeMinutes: 120),
            MovieFactory.make(id: 2, title: "Movie B", runtimeMinutes: 120),
            MovieFactory.make(id: 3, title: "Movie C", runtimeMinutes: 120)
        ]
        viewModel.sortOption = .runtimeAsc

        let sorted = viewModel.sortedMovies

        XCTAssertEqual(sorted.count, 3)
        // All have same runtime, order is based on stable sort
    }

    // MARK: - Watched Count Tests

    @MainActor
    func testWatchedCount_noWatchedMovies() {
        viewModel.watchedMovieIds = []
        XCTAssertEqual(viewModel.watchedCount, 0)
    }

    @MainActor
    func testWatchedCount_someWatchedMovies() {
        viewModel.watchedMovieIds = [1, 2, 3]
        XCTAssertEqual(viewModel.watchedCount, 3)
    }

    @MainActor
    func testWatchedCount_allMoviesWatched() {
        viewModel.movies = MovieFactory.makeList(count: 5)
        viewModel.watchedMovieIds = Set([1, 2, 3, 4, 5])
        XCTAssertEqual(viewModel.watchedCount, 5)
    }

    // MARK: - Total Count Tests

    @MainActor
    func testTotalCount_emptyList() {
        viewModel.movies = []
        XCTAssertEqual(viewModel.totalCount, 0)
    }

    @MainActor
    func testTotalCount_withMovies() {
        viewModel.movies = MovieFactory.makeList(count: 10)
        XCTAssertEqual(viewModel.totalCount, 10)
    }

    // MARK: - isWatched Tests

    @MainActor
    func testIsWatched_watchedMovie() {
        viewModel.watchedMovieIds = [1, 2, 3]
        XCTAssertTrue(viewModel.isWatched(1))
        XCTAssertTrue(viewModel.isWatched(2))
        XCTAssertTrue(viewModel.isWatched(3))
    }

    @MainActor
    func testIsWatched_unwatchedMovie() {
        viewModel.watchedMovieIds = [1, 2, 3]
        XCTAssertFalse(viewModel.isWatched(4))
        XCTAssertFalse(viewModel.isWatched(5))
    }

    @MainActor
    func testIsWatched_emptyWatchedSet() {
        viewModel.watchedMovieIds = []
        XCTAssertFalse(viewModel.isWatched(1))
    }

    // MARK: - Oscar Date Tests

    @MainActor
    func testOscarDate_isCorrect() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: viewModel.oscarDate)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    // MARK: - View Mode Tests

    @MainActor
    func testInitialViewMode() {
        XCTAssertEqual(viewModel.viewMode, .masterList)
    }

    @MainActor
    func testViewModeChange() {
        viewModel.viewMode = .byCategory
        XCTAssertEqual(viewModel.viewMode, .byCategory)

        viewModel.viewMode = .masterList
        XCTAssertEqual(viewModel.viewMode, .masterList)
    }

    // MARK: - Display Mode Tests

    @MainActor
    func testInitialDisplayMode() {
        XCTAssertEqual(viewModel.masterListDisplayMode, .grid)
    }

    @MainActor
    func testDisplayModeChange() {
        viewModel.masterListDisplayMode = .list
        XCTAssertEqual(viewModel.masterListDisplayMode, .list)

        viewModel.masterListDisplayMode = .grid
        XCTAssertEqual(viewModel.masterListDisplayMode, .grid)
    }

    // MARK: - Sort Option Enum Tests

    func testSortOptionRawValues() {
        XCTAssertEqual(DashboardSortOption.titleAZ.rawValue, "Title (A-Z)")
        XCTAssertEqual(DashboardSortOption.titleZA.rawValue, "Title (Z-A)")
        XCTAssertEqual(DashboardSortOption.runtimeAsc.rawValue, "Runtime ↑")
        XCTAssertEqual(DashboardSortOption.runtimeDesc.rawValue, "Runtime ↓")
    }

    func testSortOptionSystemImage() {
        XCTAssertEqual(DashboardSortOption.titleAZ.systemImage, "textformat.abc")
        XCTAssertEqual(DashboardSortOption.titleZA.systemImage, "textformat.abc")
        XCTAssertEqual(DashboardSortOption.runtimeAsc.systemImage, "clock")
        XCTAssertEqual(DashboardSortOption.runtimeDesc.systemImage, "clock.fill")
    }

    func testSortOptionAllCases() {
        XCTAssertEqual(DashboardSortOption.allCases.count, 4)
    }

    // MARK: - View Mode Enum Tests

    func testDashboardViewModeRawValues() {
        XCTAssertEqual(DashboardViewMode.masterList.rawValue, "Master List")
        XCTAssertEqual(DashboardViewMode.byCategory.rawValue, "By Category")
    }

    func testDashboardViewModeAllCases() {
        XCTAssertEqual(DashboardViewMode.allCases.count, 2)
    }

    // MARK: - Display Mode Enum Tests

    func testMasterListDisplayModeRawValues() {
        XCTAssertEqual(MasterListDisplayMode.grid.rawValue, "Grid")
        XCTAssertEqual(MasterListDisplayMode.list.rawValue, "List")
    }

    func testMasterListDisplayModeAllCases() {
        XCTAssertEqual(MasterListDisplayMode.allCases.count, 2)
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
        let vm = DashboardViewModel()
        XCTAssertTrue(vm.movies.isEmpty)
        XCTAssertTrue(vm.watchedMovieIds.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.viewMode, .masterList)
        XCTAssertEqual(vm.masterListDisplayMode, .grid)
        XCTAssertEqual(vm.sortOption, .titleAZ)
        XCTAssertTrue(vm.categoriesWithMovies.isEmpty)
    }
}
