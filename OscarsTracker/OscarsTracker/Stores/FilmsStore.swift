import Foundation
import Observation

/// The nominated films and which ones you've watched.
@Observable
final class FilmsStore {
    private(set) var movies: [Movie] = []
    private(set) var watchedIDs: Set<Int> = []
    private(set) var state: LoadState = .idle
    /// Where to watch each film opened so far, by movie id. Missing until
    /// loaded; an empty list means no offers.
    private(set) var offers: [Int: [WatchOffer]] = [:]
    /// How many in each of your groups have seen each film opened so far.
    private(set) var seen: [Int: [GroupSeen]] = [:]
    /// Counts the saves that watched the last nominee, for the gold dust. It
    /// changes only once the save succeeds, so a rolled-back write never celebrates.
    private(set) var completions = 0
    /// Counts films marked watched and saved, for asking about notifications after the first.
    private(set) var saves = 0
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

    /// Loads where to watch a film, sorted stream first. Fails quietly: the
    /// sheet then offers JustWatch.
    func loadOffers(for movieID: Int) async {
        guard let loaded = try? await data.offers(movieID: movieID) else {
            if offers[movieID] == nil { offers[movieID] = [] }
            return
        }
        offers[movieID] = WatchOffer.sorted(loaded)
    }

    /// Loads your groups' counts for a film; the row stays hidden if it fails.
    func loadSeen(for movieID: Int) async {
        if let loaded = try? await data.seenInGroups(movieID: movieID) { seen[movieID] = loaded }
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
            if nowWatched { saves += 1 }
            if nowWatched, !movies.isEmpty, watchedCount == movies.count { completions += 1 }
        } catch {
            if nowWatched { watchedIDs.remove(movieID) } else { watchedIDs.insert(movieID) }
            actionError = AppError(error)
        }
    }

    func reset() {
        movies = []
        watchedIDs = []
        offers = [:]
        seen = [:]
        state = .idle
    }
}
