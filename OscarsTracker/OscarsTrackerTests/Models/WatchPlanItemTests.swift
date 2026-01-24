import XCTest
@testable import OscarsTracker

final class WatchPlanItemTests: XCTestCase {

    // MARK: - isMissed Tests

    func testIsMissed_pastDate() {
        let item = WatchPlanItemFactory.make(plannedDate: .yesterdayString)
        XCTAssertTrue(item.isMissed)
    }

    func testIsMissed_todayDate() {
        let item = WatchPlanItemFactory.make(plannedDate: .todayString)
        XCTAssertFalse(item.isMissed)
    }

    func testIsMissed_futureDate() {
        let item = WatchPlanItemFactory.make(plannedDate: .tomorrowString)
        XCTAssertFalse(item.isMissed)
    }

    func testIsMissed_farPastDate() {
        let item = WatchPlanItemFactory.make(plannedDate: "2020-01-01")
        XCTAssertTrue(item.isMissed)
    }

    func testIsMissed_farFutureDate() {
        let item = WatchPlanItemFactory.make(plannedDate: "2030-12-31")
        XCTAssertFalse(item.isMissed)
    }

    func testIsMissed_invalidDateFormat() {
        let item = WatchPlanItemFactory.make(plannedDate: "invalid-date")
        XCTAssertFalse(item.isMissed) // Returns false when date can't be parsed
    }

    func testIsMissed_emptyDateString() {
        let item = WatchPlanItemFactory.make(plannedDate: "")
        XCTAssertFalse(item.isMissed)
    }

    // MARK: - Identifiable Tests

    func testIdentifiable() {
        let item1 = WatchPlanItemFactory.make(id: 1)
        let item2 = WatchPlanItemFactory.make(id: 2)

        XCTAssertNotEqual(item1.id, item2.id)
    }

    // MARK: - Movie Attachment Tests

    func testMovieAttachment() {
        let movie = MovieFactory.make(id: 5, title: "Attached Movie")
        var item = WatchPlanItemFactory.make(id: 1, movieId: 5)
        item.movie = movie

        XCTAssertNotNil(item.movie)
        XCTAssertEqual(item.movie?.id, 5)
        XCTAssertEqual(item.movie?.title, "Attached Movie")
    }

    func testMovieAttachment_nil() {
        let item = WatchPlanItemFactory.make(id: 1)

        XCTAssertNil(item.movie)
    }

    // MARK: - Codable Tests

    func testDecodable() throws {
        let json = """
        {
            "id": 1,
            "user_id": "user-123",
            "movie_id": 5,
            "planned_date": "2024-01-15",
            "created_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(WatchPlanItem.self, from: json)

        XCTAssertEqual(item.id, 1)
        XCTAssertEqual(item.userId, "user-123")
        XCTAssertEqual(item.movieId, 5)
        XCTAssertEqual(item.plannedDate, "2024-01-15")
        XCTAssertEqual(item.createdAt, "2024-01-01T00:00:00Z")
    }

    func testDecodable_minimalFields() throws {
        let json = """
        {
            "id": 1,
            "user_id": "user-123",
            "movie_id": 5,
            "planned_date": "2024-01-15"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(WatchPlanItem.self, from: json)

        XCTAssertEqual(item.id, 1)
        XCTAssertNil(item.createdAt)
    }

    func testEncodable() throws {
        let item = WatchPlanItemFactory.make(
            id: 1,
            userId: "user-123",
            movieId: 5,
            plannedDate: "2024-01-15",
            createdAt: "2024-01-01T00:00:00Z"
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(WatchPlanItem.self, from: data)

        XCTAssertEqual(item.id, decoded.id)
        XCTAssertEqual(item.userId, decoded.userId)
        XCTAssertEqual(item.movieId, decoded.movieId)
        XCTAssertEqual(item.plannedDate, decoded.plannedDate)
    }

    // MARK: - Planned Date Mutation Tests

    func testPlannedDateMutation() {
        var item = WatchPlanItemFactory.make(plannedDate: "2024-01-15")

        XCTAssertEqual(item.plannedDate, "2024-01-15")

        item.plannedDate = "2024-01-20"

        XCTAssertEqual(item.plannedDate, "2024-01-20")
    }

    // MARK: - Initializer Tests

    func testInitializer() {
        let item = WatchPlanItem(
            id: 10,
            userId: "test-user",
            movieId: 20,
            plannedDate: "2024-06-15",
            createdAt: "2024-01-01T00:00:00Z"
        )

        XCTAssertEqual(item.id, 10)
        XCTAssertEqual(item.userId, "test-user")
        XCTAssertEqual(item.movieId, 20)
        XCTAssertEqual(item.plannedDate, "2024-06-15")
        XCTAssertEqual(item.createdAt, "2024-01-01T00:00:00Z")
        XCTAssertNil(item.movie)
    }

    func testInitializer_nilCreatedAt() {
        let item = WatchPlanItem(
            id: 1,
            userId: "user",
            movieId: 1,
            plannedDate: "2024-01-15",
            createdAt: nil
        )

        XCTAssertNil(item.createdAt)
    }
}
