import XCTest
@testable import OscarsTracker

/// Tests for LeaderboardViewModel medal assignment and helper methods.
/// Note: Tests focus on pure functions that don't require Supabase connection.
final class LeaderboardViewModelTests: XCTestCase {

    var viewModel: LeaderboardViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = LeaderboardViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Medal Type Tests

    @MainActor
    func testMedalType_firstPlace() {
        let medal = viewModel.medalType(for: 1)
        XCTAssertEqual(medal, .gold)
    }

    @MainActor
    func testMedalType_secondPlace() {
        let medal = viewModel.medalType(for: 2)
        XCTAssertEqual(medal, .silver)
    }

    @MainActor
    func testMedalType_thirdPlace() {
        let medal = viewModel.medalType(for: 3)
        XCTAssertEqual(medal, .bronze)
    }

    @MainActor
    func testMedalType_fourthPlace() {
        let medal = viewModel.medalType(for: 4)
        XCTAssertNil(medal)
    }

    @MainActor
    func testMedalType_tenthPlace() {
        let medal = viewModel.medalType(for: 10)
        XCTAssertNil(medal)
    }

    @MainActor
    func testMedalType_zeroRank() {
        let medal = viewModel.medalType(for: 0)
        XCTAssertNil(medal)
    }

    @MainActor
    func testMedalType_negativeRank() {
        let medal = viewModel.medalType(for: -1)
        XCTAssertNil(medal)
    }

    // MARK: - Medal Type Enum Tests

    func testMedalType_goldColor() {
        XCTAssertEqual(MedalType.gold.color, "goldPrimary")
    }

    func testMedalType_silverColor() {
        XCTAssertEqual(MedalType.silver.color, "silver")
    }

    func testMedalType_bronzeColor() {
        XCTAssertEqual(MedalType.bronze.color, "bronze")
    }

    func testMedalType_icon() {
        XCTAssertEqual(MedalType.gold.icon, "medal.fill")
        XCTAssertEqual(MedalType.silver.icon, "medal.fill")
        XCTAssertEqual(MedalType.bronze.icon, "medal.fill")
    }

    // MARK: - Is Current User Tests

    @MainActor
    func testIsCurrentUser_matchingUserId() {
        viewModel.currentUserId = "user-123"

        let entry = LeaderboardEntry(
            userId: "user-123",
            username: "testuser",
            totalPoints: 100,
            rank: 1
        )

        XCTAssertTrue(viewModel.isCurrentUser(entry))
    }

    @MainActor
    func testIsCurrentUser_differentUserId() {
        viewModel.currentUserId = "user-123"

        let entry = LeaderboardEntry(
            userId: "user-456",
            username: "otheruser",
            totalPoints: 100,
            rank: 2
        )

        XCTAssertFalse(viewModel.isCurrentUser(entry))
    }

    @MainActor
    func testIsCurrentUser_nilCurrentUserId() {
        viewModel.currentUserId = nil

        let entry = LeaderboardEntry(
            userId: "user-123",
            username: "testuser",
            totalPoints: 100,
            rank: 1
        )

        XCTAssertFalse(viewModel.isCurrentUser(entry))
    }

    // MARK: - Current User Entry Tests

    @MainActor
    func testCurrentUserEntry_found() {
        viewModel.currentUserId = "user-123"
        viewModel.entries = [
            LeaderboardEntry(userId: "user-456", username: "user1", predictionScore: 150, rank: 1),
            LeaderboardEntry(userId: "user-123", username: "currentuser", predictionScore: 100, rank: 2),
            LeaderboardEntry(userId: "user-789", username: "user2", predictionScore: 50, rank: 3)
        ]

        let entry = viewModel.currentUserEntry

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.userId, "user-123")
        XCTAssertEqual(entry?.username, "currentuser")
    }

    @MainActor
    func testCurrentUserEntry_notFound() {
        viewModel.currentUserId = "user-999"
        viewModel.entries = [
            LeaderboardEntry(userId: "user-456", username: "user1", predictionScore: 150, rank: 1),
            LeaderboardEntry(userId: "user-123", username: "user2", predictionScore: 100, rank: 2)
        ]

        let entry = viewModel.currentUserEntry

        XCTAssertNil(entry)
    }

    @MainActor
    func testCurrentUserEntry_nilCurrentUserId() {
        viewModel.currentUserId = nil
        viewModel.entries = [
            LeaderboardEntry(userId: "user-123", username: "user1", totalPoints: 100, rank: 1)
        ]

        let entry = viewModel.currentUserEntry

        XCTAssertNil(entry)
    }

    @MainActor
    func testCurrentUserEntry_emptyEntries() {
        viewModel.currentUserId = "user-123"
        viewModel.entries = []

        let entry = viewModel.currentUserEntry

        XCTAssertNil(entry)
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
        let vm = LeaderboardViewModel()
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertNil(vm.currentUserId)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - LeaderboardEntry Tests

    func testLeaderboardEntry_identifiable() {
        let entry1 = LeaderboardEntry(userId: "user-1", username: "user1", predictionScore: 100, rank: 1)
        let entry2 = LeaderboardEntry(userId: "user-2", username: "user2", predictionScore: 90, rank: 2)

        // userId is the identifier
        XCTAssertNotEqual(entry1.userId, entry2.userId)
        XCTAssertEqual(entry1.id, entry1.userId) // id computed property
    }

    // MARK: - Edge Cases

    @MainActor
    func testMedalType_largeRank() {
        let medal = viewModel.medalType(for: 1000)
        XCTAssertNil(medal)
    }

    @MainActor
    func testIsCurrentUser_emptyUserId() {
        viewModel.currentUserId = ""

        let entry = LeaderboardEntry(
            userId: "",
            username: "emptyuser",
            predictionScore: 100,
            rank: 1
        )

        XCTAssertTrue(viewModel.isCurrentUser(entry))
    }

    @MainActor
    func testCurrentUserEntry_firstInList() {
        viewModel.currentUserId = "user-123"
        viewModel.entries = [
            LeaderboardEntry(userId: "user-123", username: "currentuser", predictionScore: 200, rank: 1),
            LeaderboardEntry(userId: "user-456", username: "other", predictionScore: 100, rank: 2)
        ]

        let entry = viewModel.currentUserEntry

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.rank, 1)
    }

    @MainActor
    func testCurrentUserEntry_lastInList() {
        viewModel.currentUserId = "user-123"
        viewModel.entries = [
            LeaderboardEntry(userId: "user-456", username: "other1", predictionScore: 200, rank: 1),
            LeaderboardEntry(userId: "user-789", username: "other2", predictionScore: 150, rank: 2),
            LeaderboardEntry(userId: "user-123", username: "currentuser", predictionScore: 100, rank: 3)
        ]

        let entry = viewModel.currentUserEntry

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.rank, 3)
    }
}

// MARK: - LeaderboardEntry Factory for Tests

enum LeaderboardEntryFactory {
    static func make(
        userId: String = "user-123",
        username: String = "testuser",
        avatarUrl: String? = nil,
        watchedCount: Int = 10,
        predictionScore: Int = 100,
        lastWatchedAt: String? = nil,
        rank: Int = 1
    ) -> LeaderboardEntry {
        LeaderboardEntry(
            userId: userId,
            username: username,
            avatarUrl: avatarUrl,
            watchedCount: watchedCount,
            predictionScore: predictionScore,
            lastWatchedAt: lastWatchedAt,
            rank: rank
        )
    }
}

extension LeaderboardEntry {
    init(
        userId: String,
        username: String,
        avatarUrl: String? = nil,
        watchedCount: Int = 0,
        predictionScore: Int = 0,
        lastWatchedAt: String? = nil,
        rank: Int
    ) {
        self.userId = userId
        self.username = username
        self.avatarUrl = avatarUrl
        self.watchedCount = watchedCount
        self.predictionScore = predictionScore
        self.lastWatchedAt = lastWatchedAt
        self.rank = rank
    }
}
