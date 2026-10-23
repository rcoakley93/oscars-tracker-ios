import Foundation
import Observation

/// The nominated films and which ones you've watched.
@Observable
final class FilmsStore {
    private(set) var movies: [Movie] = []
    private(set) var watchedIDs: Set<Int> = []
    private(set) var state: LoadState = .idle
    /// The last write that failed, for a toast. Cleared by the view.
    var actionError: AppError?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load(userID: String?) async {
        state = .loading
        do {
            async let films = data.movies()
            var watched: Set<Int> = []
            if let userID { watched = try await data.watchedMovieIDs(userID: userID) }
            movies = try await films
            watchedIDs = watched
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func isWatched(_ movieID: Int) -> Bool {
        watchedIDs.contains(movieID)
    }

    /// Unwatched films first (the season review's UX fix), each group by title.
    var toWatch: [Movie] { movies.filter { !watchedIDs.contains($0.id) }.sorted(by: Self.byTitle) }
    var watched: [Movie] { movies.filter { watchedIDs.contains($0.id) }.sorted(by: Self.byTitle) }
    var watchedCount: Int { movies.count { watchedIDs.contains($0.id) } }

    private static func byTitle(_ a: Movie, _ b: Movie) -> Bool {
        a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }

    /// Flips the film's watched state at once, then saves; rolls back if the save fails.
    func toggleWatched(_ movieID: Int, userID: String) async {
        let nowWatched = !watchedIDs.contains(movieID)
        if nowWatched { watchedIDs.insert(movieID) } else { watchedIDs.remove(movieID) }
        do {
            try await data.setWatched(nowWatched, movieID: movieID, userID: userID)
        } catch {
            if nowWatched { watchedIDs.remove(movieID) } else { watchedIDs.insert(movieID) }
            actionError = AppError(error)
        }
    }

    func reset() {
        movies = []
        watchedIDs = []
        state = .idle
    }
}
