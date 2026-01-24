import Foundation
@testable import OscarsTracker

// MARK: - Test Data Factories

/// Factory for creating test Movie objects
enum MovieFactory {
    static func make(
        id: Int = 1,
        title: String = "Test Movie",
        posterUrl: String? = "https://example.com/poster.jpg",
        releaseYear: Int? = 2024,
        runtimeMinutes: Int? = 120,
        createdAt: String? = "2024-01-01T00:00:00Z"
    ) -> Movie {
        Movie(
            id: id,
            title: title,
            posterUrl: posterUrl,
            releaseYear: releaseYear,
            runtimeMinutes: runtimeMinutes,
            createdAt: createdAt
        )
    }

    static func makeList(count: Int) -> [Movie] {
        (1...count).map { i in
            make(
                id: i,
                title: "Movie \(i)",
                runtimeMinutes: 90 + (i * 10)
            )
        }
    }
}

/// Factory for creating test Category objects
enum CategoryFactory {
    static func make(
        id: Int = 1,
        name: String = "Best Picture",
        pointsValue: Int? = 10,
        year: Int? = 2024,
        createdAt: String? = nil
    ) -> Category {
        Category(
            id: id,
            name: name,
            pointsValue: pointsValue,
            year: year,
            createdAt: createdAt
        )
    }
}

/// Factory for creating test Nomination objects
enum NominationFactory {
    static func make(
        id: Int = 1,
        categoryId: Int? = 1,
        movieId: Int? = 1,
        detailText: String? = nil,
        isWinner: Bool? = false,
        createdAt: String? = nil,
        movie: Movie? = nil
    ) -> Nomination {
        var nomination = Nomination(
            id: id,
            categoryId: categoryId,
            movieId: movieId,
            detailText: detailText,
            isWinner: isWinner,
            createdAt: createdAt
        )
        nomination.movie = movie
        return nomination
    }
}

/// Factory for creating test CategoryWithNominations objects
enum CategoryWithNominationsFactory {
    static func make(
        id: Int = 1,
        name: String = "Best Picture",
        pointsValue: Int? = 10,
        nominations: [Nomination] = []
    ) -> CategoryWithNominations {
        CategoryWithNominations(
            id: id,
            name: name,
            pointsValue: pointsValue,
            nominations: nominations
        )
    }

    static func makeWithWinner(
        id: Int = 1,
        name: String = "Best Picture",
        pointsValue: Int? = 10,
        winnerNominationId: Int = 1
    ) -> CategoryWithNominations {
        let nominations = [
            NominationFactory.make(id: 1, categoryId: id, isWinner: winnerNominationId == 1),
            NominationFactory.make(id: 2, categoryId: id, isWinner: winnerNominationId == 2),
            NominationFactory.make(id: 3, categoryId: id, isWinner: winnerNominationId == 3)
        ]
        return CategoryWithNominations(
            id: id,
            name: name,
            pointsValue: pointsValue,
            nominations: nominations
        )
    }
}

/// Factory for creating test WatchPlanItem objects
enum WatchPlanItemFactory {
    static func make(
        id: Int = 1,
        userId: String = "test-user-id",
        movieId: Int = 1,
        plannedDate: String = "2024-01-15",
        createdAt: String? = nil,
        movie: Movie? = nil
    ) -> WatchPlanItem {
        var item = WatchPlanItem(
            id: id,
            userId: userId,
            movieId: movieId,
            plannedDate: plannedDate,
            createdAt: createdAt
        )
        item.movie = movie
        return item
    }

    static func makeForDate(_ date: Date, id: Int = 1, movieId: Int = 1) -> WatchPlanItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return make(id: id, movieId: movieId, plannedDate: formatter.string(from: date))
    }
}

/// Factory for creating test CategoryNominee objects
enum CategoryNomineeFactory {
    static func make(
        id: Int = 1,
        movie: Movie = MovieFactory.make(),
        detailText: String? = nil
    ) -> CategoryNominee {
        CategoryNominee(id: id, movie: movie, detailText: detailText)
    }
}

/// Factory for creating test CategoryWithMovies objects
enum CategoryWithMoviesFactory {
    static func make(
        id: Int = 1,
        name: String = "Best Picture",
        nominees: [CategoryNominee] = []
    ) -> CategoryWithMovies {
        CategoryWithMovies(id: id, name: name, nominees: nominees)
    }

    static func makeActorCategory(
        id: Int = 1,
        name: String = "Best Actor"
    ) -> CategoryWithMovies {
        let nominees = [
            CategoryNomineeFactory.make(id: 1, movie: MovieFactory.make(id: 1, title: "Movie A"), detailText: "Actor Name A"),
            CategoryNomineeFactory.make(id: 2, movie: MovieFactory.make(id: 2, title: "Movie B"), detailText: "Actor Name B")
        ]
        return CategoryWithMovies(id: id, name: name, nominees: nominees)
    }
}

// MARK: - Date Helpers

extension Date {
    /// Create a date relative to today
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }

    /// Get today at start of day
    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Get tomorrow at start of day
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today)!
    }

    /// Get yesterday at start of day
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: today)!
    }
}

// MARK: - String Date Helpers

extension String {
    /// Create a date string for a given number of days from now
    static func dateString(daysFromNow: Int) -> String {
        let date = Date.daysFromNow(daysFromNow)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static var todayString: String { dateString(daysFromNow: 0) }
    static var tomorrowString: String { dateString(daysFromNow: 1) }
    static var yesterdayString: String { dateString(daysFromNow: -1) }
}
