import XCTest
@testable import OscarsTracker

final class MovieTests: XCTestCase {

    // MARK: - formattedRuntime Tests

    func testFormattedRuntime_hoursAndMinutes() {
        let movie = MovieFactory.make(runtimeMinutes: 142)
        XCTAssertEqual(movie.formattedRuntime, "2h 22m")
    }

    func testFormattedRuntime_exactlyOneHour() {
        let movie = MovieFactory.make(runtimeMinutes: 60)
        XCTAssertEqual(movie.formattedRuntime, "1h")
    }

    func testFormattedRuntime_exactlyTwoHours() {
        let movie = MovieFactory.make(runtimeMinutes: 120)
        XCTAssertEqual(movie.formattedRuntime, "2h")
    }

    func testFormattedRuntime_lessThanOneHour() {
        let movie = MovieFactory.make(runtimeMinutes: 45)
        XCTAssertEqual(movie.formattedRuntime, "45m")
    }

    func testFormattedRuntime_zeroMinutes() {
        let movie = MovieFactory.make(runtimeMinutes: 0)
        XCTAssertEqual(movie.formattedRuntime, "0m")
    }

    func testFormattedRuntime_oneMinute() {
        let movie = MovieFactory.make(runtimeMinutes: 1)
        XCTAssertEqual(movie.formattedRuntime, "1m")
    }

    func testFormattedRuntime_nilRuntime() {
        let movie = MovieFactory.make(runtimeMinutes: nil)
        XCTAssertEqual(movie.formattedRuntime, "")
    }

    func testFormattedRuntime_longMovie() {
        let movie = MovieFactory.make(runtimeMinutes: 238) // Like LOTR
        XCTAssertEqual(movie.formattedRuntime, "3h 58m")
    }

    func testFormattedRuntime_oneHourOneMinute() {
        let movie = MovieFactory.make(runtimeMinutes: 61)
        XCTAssertEqual(movie.formattedRuntime, "1h 1m")
    }

    // MARK: - Identifiable Tests

    func testMovieIdentifiable() {
        let movie1 = MovieFactory.make(id: 1)
        let movie2 = MovieFactory.make(id: 2)
        let movie3 = MovieFactory.make(id: 1)

        XCTAssertNotEqual(movie1.id, movie2.id)
        XCTAssertEqual(movie1.id, movie3.id)
    }

    // MARK: - Hashable Tests

    func testMovieHashable() {
        let movie1 = MovieFactory.make(id: 1, title: "Movie A")
        let movie2 = MovieFactory.make(id: 1, title: "Movie A")
        let movie3 = MovieFactory.make(id: 2, title: "Movie B")

        var movieSet = Set<Movie>()
        movieSet.insert(movie1)
        movieSet.insert(movie2)
        movieSet.insert(movie3)

        // movie1 and movie2 are the same (same id), so set should have 2 items
        XCTAssertEqual(movieSet.count, 2)
    }

    // MARK: - Codable Tests

    func testMovieDecodable() throws {
        let json = """
        {
            "id": 1,
            "title": "The Movie",
            "poster_url": "https://example.com/poster.jpg",
            "release_year": 2024,
            "runtime_minutes": 120,
            "created_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let movie = try JSONDecoder().decode(Movie.self, from: json)

        XCTAssertEqual(movie.id, 1)
        XCTAssertEqual(movie.title, "The Movie")
        XCTAssertEqual(movie.posterUrl, "https://example.com/poster.jpg")
        XCTAssertEqual(movie.releaseYear, 2024)
        XCTAssertEqual(movie.runtimeMinutes, 120)
        XCTAssertEqual(movie.createdAt, "2024-01-01T00:00:00Z")
    }

    func testMovieDecodable_missingOptionalFields() throws {
        let json = """
        {
            "id": 1,
            "title": "The Movie"
        }
        """.data(using: .utf8)!

        let movie = try JSONDecoder().decode(Movie.self, from: json)

        XCTAssertEqual(movie.id, 1)
        XCTAssertEqual(movie.title, "The Movie")
        XCTAssertNil(movie.posterUrl)
        XCTAssertNil(movie.releaseYear)
        XCTAssertNil(movie.runtimeMinutes)
        XCTAssertNil(movie.createdAt)
    }

    func testMovieEncodable() throws {
        let movie = MovieFactory.make(
            id: 1,
            title: "Test Movie",
            posterUrl: "https://example.com/poster.jpg",
            releaseYear: 2024,
            runtimeMinutes: 120,
            createdAt: "2024-01-01T00:00:00Z"
        )

        let data = try JSONEncoder().encode(movie)
        let decoded = try JSONDecoder().decode(Movie.self, from: data)

        XCTAssertEqual(movie.id, decoded.id)
        XCTAssertEqual(movie.title, decoded.title)
        XCTAssertEqual(movie.posterUrl, decoded.posterUrl)
        XCTAssertEqual(movie.releaseYear, decoded.releaseYear)
        XCTAssertEqual(movie.runtimeMinutes, decoded.runtimeMinutes)
    }
}
