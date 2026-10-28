import Foundation
import Observation

/// The films and which ones you've watched. `movies` is every film row;
/// `list` is the one Films shows for the season's `list_stage` (P9-05): the
/// contenders before nominations, the nominees after. Everything that counts
/// films counts `list`.
@Observable
final class FilmsStore {
    private(set) var movies: [Movie] = []
    /// The contenders with our odds, by category, most likely first.
    private(set) var contenders: [Contender] = []
    /// `app_config`'s `list_stage`, set by `AppModel` from the season.
    var stage = ListStage.nominated
    /// The ballot, whose nominees are the list from nominations day.
    weak var ballot: BallotStore?
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
    /// The last write that failed, for an alert. Cleared by the view.
    var actionError: AppError?
    /// Takes a toggle made offline (P4-11); the toggle then stays, queued.
    var onOffline: ((PendingWrite) -> Void)?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load(userID: String?) async {
        state = .loading
        do {
            async let films = data.movies()
            // A failure here leaves the nominees, so 2.1 works before the RPC exists.
            async let contenders = try? data.contenders()
            var watched: Set<Int> = []
            if let userID { watched = try await data.watchedMovieIDs(userID: userID) }
            movies = try await films
            self.contenders = await contenders ?? self.contenders
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

    // MARK: - The list (P9-05)

    /// The stage the list really follows: the contender stages need contenders,
    /// so a flag set before any are loaded keeps the nominees.
    var listStage: ListStage {
        stage.showsContenders && !contenders.isEmpty ? stage : .nominated
    }

    /// The films Films shows, by title: the contenders; or, from nominations
    /// day, every film but the contenders that weren't nominated, which with
    /// no contenders is 2.0's list.
    var list: [Movie] {
        let contenderIDs = Set(contenders.map(\.movieId))
        if listStage.showsContenders {
            return movies.filter { contenderIDs.contains($0.id) }.sorted(by: Self.byTitle)
        }
        let nominees = Set(ballot?.categories.flatMap { $0.nominations.compactMap(\.movie?.id) } ?? [])
        let dropped = contenderIDs.subtracting(nominees)
        return movies.filter { !dropped.contains($0.id) }.sorted(by: Self.byTitle)
    }

    /// The list's categories, in order, for the category filter.
    var listCategories: [ListCategory] {
        if listStage.showsContenders {
            var seen = Set<Int>()
            return contenders.filter { seen.insert($0.categoryId).inserted }
                .map { ListCategory(id: $0.categoryId, name: $0.categoryName) }
        }
        return ballot?.categories.map { ListCategory(id: $0.id, name: $0.name) } ?? []
    }

    /// The films in one of the list's categories.
    func movieIDs(in categoryID: Int) -> Set<Int> {
        if listStage.showsContenders { return Set(contenders.filter { $0.categoryId == categoryID }.map(\.movieId)) }
        let category = ballot?.categories.first { $0.id == categoryID }
        return Set(category?.nominations.compactMap(\.movie?.id) ?? [])
    }

    /// A film's contender rows, most likely first; empty from nominations day.
    func contending(_ movieID: Int) -> [Contender] {
        guard listStage.showsContenders else { return [] }
        return contenders.filter { $0.movieId == movieID }.sorted { $0.odds > $1.odds }
    }

    /// A film's best odds, or its odds in `categoryID`; nil off the contender list.
    func odds(for movieID: Int, in categoryID: Int? = nil) -> Double? {
        contending(movieID).filter { categoryID == nil || $0.categoryId == categoryID }.map(\.odds).max()
    }

    /// Who informed the odds and when, for the credit line; nil from nominations day.
    var credit: (source: String?, updatedAt: Date)? {
        guard listStage.showsContenders, let latest = contenders.max(by: { $0.sourceUpdatedAt < $1.sourceUpdatedAt }) else { return nil }
        return (contenders.lazy.compactMap(\.source).first, latest.sourceUpdatedAt)
    }

    /// Whether the nominees are in: before then the season is "before nominations".
    var hasNominees: Bool { listStage == .nominated && !list.isEmpty }

    /// Unwatched films first (the season review's UX fix), each group by title.
    var toWatch: [Movie] { list.filter { !watchedIDs.contains($0.id) } }
    var watched: [Movie] { list.filter { watchedIDs.contains($0.id) } }
    var watchedCount: Int { list.count { watchedIDs.contains($0.id) } }

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
            if nowWatched, !list.isEmpty, watchedCount == list.count { completions += 1 }
        } catch {
            let error = AppError(error)
            if error == .offline, let onOffline {
                onOffline(.watched(movieID: movieID, watched: nowWatched))
                return
            }
            if nowWatched { watchedIDs.remove(movieID) } else { watchedIDs.insert(movieID) }
            actionError = error
        }
    }

    /// The last good copy, at launch, until the network answers.
    func restore(movies: [Movie], watchedIDs: Set<Int>, contenders: [Contender] = []) {
        guard self.movies.isEmpty, !movies.isEmpty else { return }
        self.movies = movies
        self.contenders = contenders
        self.watchedIDs = watchedIDs
        state = .loaded
    }

    /// A queued toggle, over what the server or the cache said.
    func apply(watched: Bool, movieID: Int) {
        if watched { watchedIDs.insert(movieID) } else { watchedIDs.remove(movieID) }
    }

    func reset() {
        movies = []
        contenders = []
        watchedIDs = []
        offers = [:]
        seen = [:]
        state = .idle
    }
}

/// A category the list can be filtered by.
struct ListCategory: Identifiable, Hashable {
    let id: Int
    let name: String
}
