import Foundation
import Testing
@testable import OscarsTracker

@Suite("Posters")
struct PosterSizeTests {
    @Test func asksTMDBForTheSizeShown() {
        let original = "https://image.tmdb.org/t/p/original/m1jFoahEbeQXtx4zArT2FKdbNIj.jpg"
        #expect(PosterSize.tile.url(original)?.absoluteString == "https://image.tmdb.org/t/p/w342/m1jFoahEbeQXtx4zArT2FKdbNIj.jpg")
        #expect(PosterSize.thumbnail.url(original)?.absoluteString == "https://image.tmdb.org/t/p/w92/m1jFoahEbeQXtx4zArT2FKdbNIj.jpg")
    }

    @Test func movesTheOtherTMDBHostToTheImageHost() {
        let media = "https://media.themoviedb.org/t/p/original/24rb1DaPwGTolrXzC0qOSicm5zr.jpg"
        #expect(PosterSize.tile.url(media)?.absoluteString == "https://image.tmdb.org/t/p/w342/24rb1DaPwGTolrXzC0qOSicm5zr.jpg")
    }

    @Test func leavesOtherURLsAlone() {
        #expect(PosterSize.tile.url("https://example.com/poster.jpg")?.absoluteString == "https://example.com/poster.jpg")
        #expect(PosterSize.tile.url(nil) == nil)
    }

    @Test func readsFromTheCacheFirst() {
        #expect(PosterSize.tile.request("https://image.tmdb.org/t/p/original/a.jpg")?.cachePolicy == .returnCacheDataElseLoad)
    }
}

@MainActor
@Suite("Films")
struct FilmsTests {
    private let user = SampleDataSource.userID

    @Test func sortsByRuntimeWithUnknownRuntimesLast() {
        let films = [
            Movie(id: 1, title: "Long", posterUrl: nil, releaseYear: nil, runtimeMinutes: 160, createdAt: nil),
            Movie(id: 2, title: "Unknown", posterUrl: nil, releaseYear: nil, runtimeMinutes: nil, createdAt: nil),
            Movie(id: 3, title: "Short", posterUrl: nil, releaseYear: nil, runtimeMinutes: 90, createdAt: nil),
        ]
        #expect(FilmsTab.Sort.shortest.sorted(films).map(\.id) == [3, 1, 2])
        #expect(FilmsTab.Sort.longest.sorted(films).map(\.id) == [1, 3, 2])
        #expect(FilmsTab.Sort.title.sorted(films).map(\.id) == [1, 2, 3])
    }

    @Test func watchingTheLastNomineeCelebratesOnce() async {
        let data = SampleDataSource()
        data.watched = Set(SampleData.movies.map(\.id)).subtracting([2])
        let store = FilmsStore(data: data)
        await store.load(userID: user)
        await store.toggleWatched(2, userID: user)
        #expect(store.completions == 1)
        await store.toggleWatched(2, userID: user)
        #expect(store.completions == 1)
    }

    @Test func aFailedLastSaveDoesNotCelebrate() async {
        let data = SampleDataSource()
        data.watched = Set(SampleData.movies.map(\.id)).subtracting([2])
        let store = FilmsStore(data: data)
        await store.load(userID: user)
        data.failure = .offline
        await store.toggleWatched(2, userID: user)
        #expect(store.completions == 0)
    }

    @Test func standingNamesThePersonAboveAndTheGap() async throws {
        let store = GroupsStore(data: SampleDataSource())
        #expect(store.standing(in: 1, userID: user) == nil)
        await store.loadBoard(for: 1)
        let standing = try #require(store.standing(in: 1, userID: user))
        #expect(standing.rank == 2)
        #expect(standing.size == 6)
        #expect(standing.position == .behind("Sam", films: 2))
    }

    @Test func standingKnowsTheLeaderAndTies() async {
        let data = SampleDataSource()
        data.board = [
            LeaderboardEntry(userId: user, username: "filmbuff", avatarUrl: nil, watchedCount: 31, predictionScore: 0, lastWatchedAt: nil, rank: 1),
            LeaderboardEntry(userId: "u-sam", username: "Sam", avatarUrl: nil, watchedCount: 20, predictionScore: 0, lastWatchedAt: nil, rank: 2),
        ]
        let store = GroupsStore(data: data)
        await store.loadBoard(for: 1)
        #expect(store.standing(in: 1, userID: user)?.position == .first)

        data.board[1] = LeaderboardEntry(userId: "u-sam", username: "Sam", avatarUrl: nil, watchedCount: 31, predictionScore: 0, lastWatchedAt: nil, rank: 1)
        await store.loadBoard(for: 1)
        #expect(store.standing(in: 1, userID: user)?.position == .tied(with: "Sam"))
    }

    @Test func bothVoicesGiveTheRankAndTheGap() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(copy.compareRank(2, 6, "Movies LLC") == "2nd of 6 in Movies LLC")
            #expect(copy.compareGap(2, "Sam").contains("2 films behind Sam"))
            #expect(copy.compareGap(1, "Sam").contains("1 film behind Sam"))
            #expect(copy.compareGap(5, "Sam").contains("5 films behind Sam"))
            #expect(copy.compareTied("Sam").contains("Sam"))
            #expect(copy.filmsPreseason("Jan 21").title.contains("Jan 21"))
        }
    }
}

@Suite("Search")
struct SearchTests {
    @Test func findsNothingForAnEmptyQuery() {
        let results = SearchResults(query: "  ", films: SampleData.movies, categories: SampleData.categories)
        #expect(results.isEmpty)
        #expect(results.query.isEmpty)
    }

    @Test func findsFilmsPeopleAndCategories() {
        let results = SearchResults(query: "ham", films: SampleData.movies, categories: SampleData.categories)
        #expect(results.films.map(\.title) == ["Hamnet"])

        let people = SearchResults(query: "buckley", films: SampleData.movies, categories: SampleData.categories)
        #expect(people.people.map(\.nominee.personName) == ["Jessie Buckley"])
        #expect(people.people.first?.category.name == "Actress in a Leading Role")

        let categories = SearchResults(query: "animated", films: SampleData.movies, categories: SampleData.categories)
        #expect(categories.categories.map(\.name) == ["Animated Feature"])
    }

    @Test func ignoresCaseAndAccents() {
        let films = [Movie(id: 1, title: "Amélie", posterUrl: nil, releaseYear: nil, runtimeMinutes: nil, createdAt: nil)]
        #expect(SearchResults(query: "AMELIE", films: films, categories: []).films.count == 1)
    }
}
