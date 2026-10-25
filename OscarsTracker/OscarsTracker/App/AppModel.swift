import Foundation
import Observation
import SwiftUI

/// The app's state: the session, one store per area, and navigation. Created
/// once at launch with `LiveDataSource`; previews use `AppModel.preview`.
/// Inject it with `.environment(model)` and read it with
/// `@Environment(AppModel.self)`.
@Observable
final class AppModel {
    let session: SessionStore
    let season: SeasonStore
    let films: FilmsStore
    let ballot: BallotStore
    let plan: PlanStore
    let groups: GroupsStore
    let leaderboard: LeaderboardStore
    let profile: ProfileStore
    let push: PushStore
    /// Ceremony night, for the admin only (P6-01).
    let admin: AdminStore
    /// Oscar night: winners as they're announced (P6-02).
    let live: LiveStore
    /// Ceremony night on the Lock Screen and in the Dynamic Island (P6-03).
    let liveActivity: LiveActivityStore
    let navigation = AppNavigation()
    let connectivity = Connectivity()
    /// Watched toggles and picks made offline, oldest first (P4-11).
    private(set) var pending: [PendingWrite] = []

    private let data: any AppDataSource
    private let cache: OfflineCache

    /// `cache` defaults to files in Caches for the live backend and nothing otherwise.
    init(data: any AppDataSource, cache: OfflineCache? = nil) {
        self.data = data
        self.cache = cache ?? (data is LiveDataSource ? .live : .none)
        session = SessionStore(data: data)
        season = SeasonStore(data: data, cacheKey: data is LiveDataSource ? "season.cache" : nil)
        films = FilmsStore(data: data)
        ballot = BallotStore(data: data)
        plan = PlanStore(data: data)
        groups = GroupsStore(data: data)
        leaderboard = LeaderboardStore(data: data)
        profile = ProfileStore(data: data)
        push = PushStore(data: data)
        admin = AdminStore(data: data)
        live = LiveStore(data: data, ballot: ballot)
        liveActivity = LiveActivityStore(data: data)
        admin.onWinnersChanged = { [weak self] in self?.ballot.apply(winners: $0.current, in: $0.categoryID) }
        live.onWinnersSettled = { [weak self] in
            guard let self else { return }
            Task {
                await self.leaderboard.reload(ceremonyID: self.season.ceremony?.id)
                await self.updateLiveActivity()
            }
        }
        films.onOffline = { [weak self] in self?.enqueue($0) }
        ballot.onOffline = { [weak self] in self?.enqueue($0) }
    }

    /// The network is gone, so what's on screen is the last good copy.
    var isOffline: Bool { !connectivity.isOnline }

    /// At launch: restore the session and show the last good copy at once,
    /// then load the season and everything for the user.
    func start() async {
        connectivity.start()
        await session.restore()
        restoreSnapshot()
        await refresh()
        await push.refresh()
    }

    /// Loads (or reloads) everything at once, for launch, sign-in, pull to
    /// refresh and the network coming back. Offline writes go first, so the
    /// reload includes them.
    func refresh() async {
        await sendPending()
        let userID = session.userID
        async let season: Void = loadSeasonAndBoards()
        async let films: Void = films.load(userID: userID)
        async let ballot: Void = ballot.load(userID: userID)
        if let userID {
            async let plan: Void = plan.load(userID: userID)
            async let groups: Void = groups.load(userID: userID)
            async let profile: Void = profile.load(userID: userID)
            async let push: Void = push.signedIn()
            async let reminders: Void = self.push.loadPreferences(userID: userID)
            _ = await (plan, groups, profile, push, reminders)
        }
        _ = await (season, films, ballot)
        await loadPickShares()
        applyPending()
        followLiveMode()
        await followLiveActivity()
        saveSnapshot()
    }

    // MARK: - Offline (P4-11)

    private func restoreSnapshot() {
        guard let userID = session.userID else { return }
        pending = cache.queue(for: userID)
        if let snapshot = cache.snapshot(for: userID) {
            films.restore(movies: snapshot.movies, watchedIDs: snapshot.watchedIDs)
            ballot.restore(categories: snapshot.categories, picks: snapshot.picks)
            plan.restore(items: snapshot.plan)
            groups.restore(groups: snapshot.groups)
            leaderboard.restore(boards: snapshot.boards, ceremonyID: season.ceremony?.id)
        }
        applyPending()
    }

    private func saveSnapshot() {
        guard let userID = session.userID, !films.movies.isEmpty else { return }
        cache.save(OfflineSnapshot(movies: films.movies, watchedIDs: films.watchedIDs, categories: ballot.categories,
                                   picks: ballot.picks, plan: plan.items, groups: groups.groups, boards: leaderboard.cachedBoards),
                   for: userID)
    }

    private func enqueue(_ write: PendingWrite) {
        guard let userID = session.userID else { return }
        pending.removeAll { write.replaces($0) }
        pending.append(write)
        cache.save(pending, for: userID)
    }

    /// Queued writes over whatever the stores hold (the cache, or a load
    /// that finished while some were still waiting).
    private func applyPending() {
        for write in pending {
            switch write {
            case .watched(let movieID, let watched): films.apply(watched: watched, movieID: movieID)
            case .pick(let categoryID, let nominationID): ballot.apply(pick: nominationID, in: categoryID)
            }
        }
    }

    /// Sends what queued up offline, oldest first, and stops at the first
    /// one that still can't reach the server. A pick that arrives after the
    /// lock is dropped, and the Ballot says so plainly.
    func sendPending() async {
        guard let userID = session.userID, !pending.isEmpty else { return }
        sending: while let write = pending.first {
            do {
                switch write {
                case .watched(let movieID, let watched):
                    try await data.setWatched(watched, movieID: movieID, userID: userID)
                case .pick(let categoryID, let nominationID):
                    try await data.savePick(categoryID: categoryID, nominationID: nominationID, userID: userID)
                }
                pending.removeFirst()
            } catch {
                let error = AppError(error)
                if error == .offline { break sending }
                pending.removeFirst()
                switch write {
                case .pick: ballot.actionError = error == .ballotLocked ? .offlinePickLocked : error
                case .watched: films.actionError = error
                }
            }
        }
        cache.save(pending, for: userID)
    }

    /// Back from the background: the season may have moved on (the lock, the
    /// winners), and the push token may have changed.
    func foreground() async {
        async let season: Void = loadSeasonAndBoards()
        async let push: Void = push.refresh()
        _ = await (season, push)
        await loadPickShares()
        guard session.userID != nil, self.season.config.isEnabled(AppConfig.liveMode) else { return live.stop() }
        // Winners missed while the app was away, or announced before live mode came on.
        await ballot.load(userID: session.userID)
        applyPending()
        followLiveMode()
        await followLiveActivity()
    }

    /// Follows winners while `live_mode` is on and someone is signed in,
    /// and plays the ones a reload found that Realtime didn't deliver.
    private func followLiveMode() {
        guard session.userID != nil, self.season.config.isEnabled(AppConfig.liveMode) else { return live.stop() }
        live.start()
        live.catchUp()
    }

    // MARK: - Live Activity (P6-03)

    /// What the Live Activity shows now.
    var liveActivityState: CeremonyActivityAttributes.ContentState {
        LiveActivityStore.state(categories: ballot.categories, picks: ballot.picks, latestCategoryID: live.latestCategoryID,
                                board: leaderboard.entries(nil), userID: session.userID)
    }

    /// The hero's "Follow the ceremony" button shows: ceremony night, signed
    /// in, the flag on and Live Activities allowed.
    var canFollowCeremony: Bool {
        session.userID != nil && season.ceremony != nil && liveActivity.canFollow(config: season.config)
    }

    /// The hero's button: starts the Live Activity.
    func followCeremony() async {
        guard let ceremony = season.ceremony, canFollowCeremony else { return }
        let voice = UserDefaults.standard.string(forKey: Voice.storageKey).flatMap(Voice.init) ?? .host
        await liveActivity.follow(ceremony: ceremony, voice: voice, state: liveActivityState)
    }

    /// Picks up running activities and the push-to-start token while the
    /// flag is on, and brings a running activity up to date.
    private func followLiveActivity() async {
        guard session.userID != nil, season.config.isEnabled(AppConfig.liveActivity) else { return }
        liveActivity.start(ceremonyID: season.ceremony?.id)
        await updateLiveActivity()
    }

    private func updateLiveActivity() async {
        guard liveActivity.isFollowing, !ballot.categories.isEmpty else { return }
        await liveActivity.update(liveActivityState)
    }

    /// The group the Ballot's "62% of Movies LLC picked Hamnet" lines speak for.
    var ballotGroup: PoolGroup? {
        groups.groups.first { $0.id == navigation.ballotGroupID } ?? groups.groups.first
    }

    /// What `ballotGroup` picked, once the ballot locks (P6-05).
    func loadPickShares() async {
        guard session.userID != nil, let ceremony = season.ceremony, season.isBallotLocked(), let group = ballotGroup else {
            ballot.clearShares()
            return
        }
        await ballot.loadShares(ceremonyID: ceremony.id, group: group)
    }

    /// Whether this account runs ceremony night (P6-01).
    var isAdmin: Bool { profile.profile?.isAdmin == true }

    /// The boards need the ceremony's id.
    private func loadSeasonAndBoards() async {
        await season.load()
        guard session.userID != nil else { return }
        await leaderboard.reload(ceremonyID: season.ceremony?.id)
    }

    func signOut() async {
        await push.signingOut()
        await liveActivity.stop()
        if let userID = session.userID { cache.clear(for: userID) }
        await session.signOut()
        clearUserData()
    }

    /// Deletes the account, and signs out only if that worked (guideline 5.1.1).
    func deleteAccount(appleAuthorizationCode: String? = nil) async -> Bool {
        let userID = session.userID
        guard await profile.deleteAccount(appleAuthorizationCode: appleAuthorizationCode) else { return false }
        await liveActivity.stop()
        if let userID { cache.clear(for: userID) }
        session.didDeleteAccount()
        clearUserData()
        return true
    }

    private func clearUserData() {
        pending = []
        films.reset()
        ballot.reset()
        plan.reset()
        groups.reset()
        leaderboard.reset()
        profile.reset()
        admin.reset()
        live.stop()
        navigation.reset()
    }
}

extension AppModel {
    /// A loaded model over sample data, for previews.
    static func preview(signedIn: Bool = true, configure: (SampleDataSource) -> Void = { _ in }) -> AppModel {
        let data = SampleDataSource(signedIn: signedIn)
        configure(data)
        let model = AppModel(data: data)
        Task { await model.start() }
        return model
    }
}
