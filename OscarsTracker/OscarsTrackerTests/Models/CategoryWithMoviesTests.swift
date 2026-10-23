import XCTest
@testable import OscarsTracker

nonisolated final class CategoryWithMoviesTests: XCTestCase {

    // MARK: - CategoryNominee Tests

    @MainActor
    func testCategoryNominee_hasActorDetail_withDetail() {
        let nominee = CategoryNomineeFactory.make(detailText: "Actor Name")
        XCTAssertTrue(nominee.hasActorDetail)
    }

    @MainActor
    func testCategoryNominee_hasActorDetail_nilDetail() {
        let nominee = CategoryNomineeFactory.make(detailText: nil)
        XCTAssertFalse(nominee.hasActorDetail)
    }

    @MainActor
    func testCategoryNominee_hasActorDetail_emptyDetail() {
        let nominee = CategoryNomineeFactory.make(detailText: "")
        XCTAssertFalse(nominee.hasActorDetail)
    }

    @MainActor
    func testCategoryNominee_identifiable() {
        let nominee1 = CategoryNomineeFactory.make(id: 1)
        let nominee2 = CategoryNomineeFactory.make(id: 2)

        XCTAssertNotEqual(nominee1.id, nominee2.id)
    }

    // MARK: - CategoryWithMovies isActorCategory Tests

    @MainActor
    func testIsActorCategory_bestActor() {
        let category = CategoryWithMoviesFactory.make(name: "Best Actor")
        XCTAssertTrue(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_bestActress() {
        let category = CategoryWithMoviesFactory.make(name: "Best Actress")
        XCTAssertTrue(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_supportingActor() {
        let category = CategoryWithMoviesFactory.make(name: "Best Supporting Actor")
        XCTAssertTrue(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_supportingActress() {
        let category = CategoryWithMoviesFactory.make(name: "Best Supporting Actress")
        XCTAssertTrue(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_caseInsensitive() {
        let category1 = CategoryWithMoviesFactory.make(name: "BEST ACTOR")
        let category2 = CategoryWithMoviesFactory.make(name: "best actress")

        XCTAssertTrue(category1.isActorCategory)
        XCTAssertTrue(category2.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_notActorCategory_bestPicture() {
        let category = CategoryWithMoviesFactory.make(name: "Best Picture")
        XCTAssertFalse(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_notActorCategory_bestDirector() {
        let category = CategoryWithMoviesFactory.make(name: "Best Director")
        XCTAssertFalse(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_notActorCategory_originalScreenplay() {
        let category = CategoryWithMoviesFactory.make(name: "Best Original Screenplay")
        XCTAssertFalse(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_notActorCategory_cinematography() {
        let category = CategoryWithMoviesFactory.make(name: "Best Cinematography")
        XCTAssertFalse(category.isActorCategory)
    }

    @MainActor
    func testIsActorCategory_partialMatch_actorInMiddle() {
        let category = CategoryWithMoviesFactory.make(name: "Some Actor Award")
        XCTAssertTrue(category.isActorCategory)
    }

    // MARK: - CategoryWithMovies movies Accessor Tests

    @MainActor
    func testMovies_accessor() {
        let movies = [
            MovieFactory.make(id: 1, title: "Movie A"),
            MovieFactory.make(id: 2, title: "Movie B")
        ]
        let nominees = [
            CategoryNomineeFactory.make(id: 1, movie: movies[0]),
            CategoryNomineeFactory.make(id: 2, movie: movies[1])
        ]
        let category = CategoryWithMovies(id: 1, name: "Test", nominees: nominees)

        XCTAssertEqual(category.movies.count, 2)
        XCTAssertEqual(category.movies[0].id, 1)
        XCTAssertEqual(category.movies[1].id, 2)
    }

    @MainActor
    func testMovies_emptyNominees() {
        let category = CategoryWithMoviesFactory.make(nominees: [])

        XCTAssertTrue(category.movies.isEmpty)
    }

    // MARK: - CategoryWithMovies Identifiable Tests

    @MainActor
    func testCategoryWithMovies_identifiable() {
        let category1 = CategoryWithMoviesFactory.make(id: 1)
        let category2 = CategoryWithMoviesFactory.make(id: 2)

        XCTAssertNotEqual(category1.id, category2.id)
    }

    // MARK: - CategoryWithNominations Tests

    @MainActor
    func testCategoryWithNominations_identifiable() {
        let category1 = CategoryWithNominationsFactory.make(id: 1)
        let category2 = CategoryWithNominationsFactory.make(id: 2)

        XCTAssertNotEqual(category1.id, category2.id)
    }

    // MARK: - Nomination Tests

    @MainActor
    func testNomination_identifiable() {
        let nomination1 = NominationFactory.make(id: 1)
        let nomination2 = NominationFactory.make(id: 2)

        XCTAssertNotEqual(nomination1.id, nomination2.id)
    }

    @MainActor
    func testNomination_movieAttachment() {
        let movie = MovieFactory.make(id: 1, title: "Test Movie")
        var nomination = NominationFactory.make(id: 1, movieId: 1)
        nomination.movie = movie

        XCTAssertNotNil(nomination.movie)
        XCTAssertEqual(nomination.movie?.id, 1)
        XCTAssertEqual(nomination.movie?.title, "Test Movie")
    }

    @MainActor
    func testNomination_codable() throws {
        let json = """
        {
            "id": 1,
            "category_id": 2,
            "movie_id": 3,
            "detail_text": "Actor Name",
            "is_winner": true,
            "created_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let nomination = try JSONDecoder().decode(Nomination.self, from: json)

        XCTAssertEqual(nomination.id, 1)
        XCTAssertEqual(nomination.categoryId, 2)
        XCTAssertEqual(nomination.movieId, 3)
        XCTAssertEqual(nomination.detailText, "Actor Name")
        XCTAssertEqual(nomination.isWinner, true)
    }

    @MainActor
    func testNomination_codable_nullOptionals() throws {
        let json = """
        {
            "id": 1
        }
        """.data(using: .utf8)!

        let nomination = try JSONDecoder().decode(Nomination.self, from: json)

        XCTAssertEqual(nomination.id, 1)
        XCTAssertNil(nomination.categoryId)
        XCTAssertNil(nomination.movieId)
        XCTAssertNil(nomination.detailText)
        XCTAssertNil(nomination.isWinner)
    }
}
