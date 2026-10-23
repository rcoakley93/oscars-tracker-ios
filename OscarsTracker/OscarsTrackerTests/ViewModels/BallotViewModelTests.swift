import XCTest
@testable import OscarsTracker

/// Tests for BallotViewModel scoring and prediction logic.
/// Note: Tests focus on pure functions that don't require Supabase connection.
@MainActor
final class BallotViewModelTests: XCTestCase {

    var viewModel: BallotViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = BallotViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Sorted Categories Tests

    @MainActor
    func testSortedCategories_sortsByPointsDescending() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1, name: "Low", pointsValue: 5),
            CategoryWithNominationsFactory.make(id: 2, name: "High", pointsValue: 20),
            CategoryWithNominationsFactory.make(id: 3, name: "Medium", pointsValue: 10)
        ]

        let sorted = viewModel.sortedCategories

        XCTAssertEqual(sorted[0].name, "High")
        XCTAssertEqual(sorted[1].name, "Medium")
        XCTAssertEqual(sorted[2].name, "Low")
    }

    @MainActor
    func testSortedCategories_nilPointsTreatedAsZero() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1, name: "With Points", pointsValue: 10),
            CategoryWithNominationsFactory.make(id: 2, name: "Nil Points", pointsValue: nil)
        ]

        let sorted = viewModel.sortedCategories

        XCTAssertEqual(sorted[0].name, "With Points")
        XCTAssertEqual(sorted[1].name, "Nil Points")
    }

    @MainActor
    func testSortedCategories_empty() {
        viewModel.categories = []

        let sorted = viewModel.sortedCategories

        XCTAssertTrue(sorted.isEmpty)
    }

    @MainActor
    func testSortedCategories_samePoints() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1, name: "A", pointsValue: 10),
            CategoryWithNominationsFactory.make(id: 2, name: "B", pointsValue: 10),
            CategoryWithNominationsFactory.make(id: 3, name: "C", pointsValue: 10)
        ]

        let sorted = viewModel.sortedCategories

        XCTAssertEqual(sorted.count, 3)
        // All have same points, stable sort
    }

    // MARK: - Total/Predicted Categories Tests

    @MainActor
    func testTotalCategories_empty() {
        viewModel.categories = []
        XCTAssertEqual(viewModel.totalCategories, 0)
    }

    @MainActor
    func testTotalCategories_withCategories() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1),
            CategoryWithNominationsFactory.make(id: 2),
            CategoryWithNominationsFactory.make(id: 3)
        ]
        XCTAssertEqual(viewModel.totalCategories, 3)
    }

    @MainActor
    func testPredictedCategories_noPredictions() {
        viewModel.predictions = [:]
        XCTAssertEqual(viewModel.predictedCategories, 0)
    }

    @MainActor
    func testPredictedCategories_withPredictions() {
        viewModel.predictions = [1: 100, 2: 200, 3: 300]
        XCTAssertEqual(viewModel.predictedCategories, 3)
    }

    // MARK: - Has Winner Tests

    @MainActor
    func testHasWinner_noWinner() {
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: false)
            ]
        )

        XCTAssertFalse(viewModel.hasWinner(for: category))
    }

    @MainActor
    func testHasWinner_withWinner() {
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: true)
            ]
        )

        XCTAssertTrue(viewModel.hasWinner(for: category))
    }

    @MainActor
    func testHasWinner_nilIsWinner() {
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: nil),
                NominationFactory.make(id: 2, isWinner: nil)
            ]
        )

        XCTAssertFalse(viewModel.hasWinner(for: category))
    }

    @MainActor
    func testHasWinner_emptyNominations() {
        let category = CategoryWithNominationsFactory.make(nominations: [])

        XCTAssertFalse(viewModel.hasWinner(for: category))
    }

    // MARK: - Winning Nomination Tests

    @MainActor
    func testWinningNomination_noWinner() {
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: false)
            ]
        )

        XCTAssertNil(viewModel.winningNomination(for: category))
    }

    @MainActor
    func testWinningNomination_withWinner() {
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: true)
            ]
        )

        let winner = viewModel.winningNomination(for: category)

        XCTAssertNotNil(winner)
        XCTAssertEqual(winner?.id, 2)
    }

    @MainActor
    func testWinningNomination_returnsFirst() {
        // Edge case: multiple winners (shouldn't happen, but test behavior)
        let category = CategoryWithNominationsFactory.make(
            nominations: [
                NominationFactory.make(id: 1, isWinner: true),
                NominationFactory.make(id: 2, isWinner: true)
            ]
        )

        let winner = viewModel.winningNomination(for: category)

        XCTAssertNotNil(winner)
        XCTAssertEqual(winner?.id, 1)
    }

    // MARK: - Is Prediction Correct Tests

    @MainActor
    func testIsPredictionCorrect_correctPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [1: 2] // Predicted nomination 2

        XCTAssertTrue(viewModel.isPredictionCorrect(for: category))
    }

    @MainActor
    func testIsPredictionCorrect_incorrectPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [1: 1] // Predicted nomination 1, but 2 won

        XCTAssertFalse(viewModel.isPredictionCorrect(for: category))
    }

    @MainActor
    func testIsPredictionCorrect_noPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [:] // No prediction made

        XCTAssertFalse(viewModel.isPredictionCorrect(for: category))
    }

    @MainActor
    func testIsPredictionCorrect_noWinner() {
        let category = CategoryWithNominationsFactory.make(
            id: 1,
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: false)
            ]
        )
        viewModel.predictions = [1: 1]

        XCTAssertFalse(viewModel.isPredictionCorrect(for: category))
    }

    // MARK: - Is Prediction Incorrect Tests

    @MainActor
    func testIsPredictionIncorrect_incorrectPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [1: 1] // Predicted 1, but 2 won

        XCTAssertTrue(viewModel.isPredictionIncorrect(for: category))
    }

    @MainActor
    func testIsPredictionIncorrect_correctPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [1: 2]

        XCTAssertFalse(viewModel.isPredictionIncorrect(for: category))
    }

    @MainActor
    func testIsPredictionIncorrect_noPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, winnerNominationId: 2)
        viewModel.predictions = [:]

        XCTAssertFalse(viewModel.isPredictionIncorrect(for: category))
    }

    @MainActor
    func testIsPredictionIncorrect_noWinner() {
        let category = CategoryWithNominationsFactory.make(
            id: 1,
            nominations: [
                NominationFactory.make(id: 1, isWinner: false),
                NominationFactory.make(id: 2, isWinner: false)
            ]
        )
        viewModel.predictions = [1: 1]

        XCTAssertFalse(viewModel.isPredictionIncorrect(for: category))
    }

    // MARK: - Points Earned Tests

    @MainActor
    func testPointsEarned_correctPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 2)
        viewModel.predictions = [1: 2]

        XCTAssertEqual(viewModel.pointsEarned(for: category), 10)
    }

    @MainActor
    func testPointsEarned_incorrectPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 2)
        viewModel.predictions = [1: 1]

        XCTAssertEqual(viewModel.pointsEarned(for: category), 0)
    }

    @MainActor
    func testPointsEarned_noPrediction() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 2)
        viewModel.predictions = [:]

        XCTAssertEqual(viewModel.pointsEarned(for: category), 0)
    }

    @MainActor
    func testPointsEarned_nilPointsValue() {
        let category = CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: nil, winnerNominationId: 2)
        viewModel.predictions = [1: 2]

        XCTAssertEqual(viewModel.pointsEarned(for: category), 0)
    }

    // MARK: - Total Points Earned Tests

    @MainActor
    func testTotalPointsEarned_allCorrect() {
        viewModel.categories = [
            CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 1),
            CategoryWithNominationsFactory.makeWithWinner(id: 2, pointsValue: 20, winnerNominationId: 1),
            CategoryWithNominationsFactory.makeWithWinner(id: 3, pointsValue: 5, winnerNominationId: 1)
        ]
        viewModel.predictions = [1: 1, 2: 1, 3: 1]

        XCTAssertEqual(viewModel.totalPointsEarned, 35)
    }

    @MainActor
    func testTotalPointsEarned_someCorrect() {
        viewModel.categories = [
            CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 1),
            CategoryWithNominationsFactory.makeWithWinner(id: 2, pointsValue: 20, winnerNominationId: 1),
            CategoryWithNominationsFactory.makeWithWinner(id: 3, pointsValue: 5, winnerNominationId: 1)
        ]
        viewModel.predictions = [1: 1, 2: 2, 3: 1] // 2nd category wrong

        XCTAssertEqual(viewModel.totalPointsEarned, 15)
    }

    @MainActor
    func testTotalPointsEarned_noneCorrect() {
        viewModel.categories = [
            CategoryWithNominationsFactory.makeWithWinner(id: 1, pointsValue: 10, winnerNominationId: 1),
            CategoryWithNominationsFactory.makeWithWinner(id: 2, pointsValue: 20, winnerNominationId: 1)
        ]
        viewModel.predictions = [1: 2, 2: 2] // All wrong

        XCTAssertEqual(viewModel.totalPointsEarned, 0)
    }

    @MainActor
    func testTotalPointsEarned_emptyCategories() {
        viewModel.categories = []
        viewModel.predictions = [:]

        XCTAssertEqual(viewModel.totalPointsEarned, 0)
    }

    // MARK: - Max Possible Points Tests

    @MainActor
    func testMaxPossiblePoints_withCategories() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1, pointsValue: 10),
            CategoryWithNominationsFactory.make(id: 2, pointsValue: 20),
            CategoryWithNominationsFactory.make(id: 3, pointsValue: 5)
        ]

        XCTAssertEqual(viewModel.maxPossiblePoints, 35)
    }

    @MainActor
    func testMaxPossiblePoints_withNilPoints() {
        viewModel.categories = [
            CategoryWithNominationsFactory.make(id: 1, pointsValue: 10),
            CategoryWithNominationsFactory.make(id: 2, pointsValue: nil),
            CategoryWithNominationsFactory.make(id: 3, pointsValue: 5)
        ]

        XCTAssertEqual(viewModel.maxPossiblePoints, 15)
    }

    @MainActor
    func testMaxPossiblePoints_empty() {
        viewModel.categories = []

        XCTAssertEqual(viewModel.maxPossiblePoints, 0)
    }

    // MARK: - Is Selected Tests

    @MainActor
    func testIsSelected_selected() {
        viewModel.predictions = [1: 100]

        let nomination = NominationFactory.make(id: 100, categoryId: 1)

        XCTAssertTrue(viewModel.isSelected(nomination: nomination))
    }

    @MainActor
    func testIsSelected_notSelected() {
        viewModel.predictions = [1: 100]

        let nomination = NominationFactory.make(id: 200, categoryId: 1)

        XCTAssertFalse(viewModel.isSelected(nomination: nomination))
    }

    @MainActor
    func testIsSelected_differentCategory() {
        viewModel.predictions = [1: 100]

        let nomination = NominationFactory.make(id: 100, categoryId: 2)

        XCTAssertFalse(viewModel.isSelected(nomination: nomination))
    }

    @MainActor
    func testIsSelected_nilCategoryId() {
        viewModel.predictions = [1: 100]

        let nomination = NominationFactory.make(id: 100, categoryId: nil)

        XCTAssertFalse(viewModel.isSelected(nomination: nomination))
    }

    // MARK: - Ballot Lock Tests

    @MainActor
    func testBallotLockDate_isCorrect() {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: TimeZone(identifier: "America/Los_Angeles")!, from: viewModel.ballotLockDate)

        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.hour, 17)
        XCTAssertEqual(components.minute, 0)
    }

    @MainActor
    func testCheckLockStatus_beforeLockDate() {
        // Can't easily test time-dependent behavior without mocking
        // But we can test the method runs without error
        viewModel.checkLockStatus()
        // isLocked will be based on current date vs lock date
    }

    // MARK: - Movie For Nomination Tests

    @MainActor
    func testMovieForNomination_found() {
        let movie = MovieFactory.make(id: 1, title: "Test Movie")
        viewModel.movies = [movie]

        let nomination = NominationFactory.make(id: 1, movieId: 1)

        let foundMovie = viewModel.movie(for: nomination)

        XCTAssertNotNil(foundMovie)
        XCTAssertEqual(foundMovie?.id, 1)
    }

    @MainActor
    func testMovieForNomination_notFound() {
        viewModel.movies = [MovieFactory.make(id: 1)]

        let nomination = NominationFactory.make(id: 1, movieId: 999)

        XCTAssertNil(viewModel.movie(for: nomination))
    }

    @MainActor
    func testMovieForNomination_nilMovieId() {
        viewModel.movies = [MovieFactory.make(id: 1)]

        let nomination = NominationFactory.make(id: 1, movieId: nil)

        XCTAssertNil(viewModel.movie(for: nomination))
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState() {
        let vm = BallotViewModel()
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertTrue(vm.movies.isEmpty)
        XCTAssertTrue(vm.predictions.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isSaving)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLocked)
    }

    // MARK: - Clear Error Tests

    @MainActor
    func testClearError() {
        viewModel.errorMessage = "Some error"
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }
}
