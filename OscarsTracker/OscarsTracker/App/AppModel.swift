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
    let navigation = AppNavigation()

    init(data: any AppDataSource) {
        session = SessionStore(data: data)
        season = SeasonStore(data: data, cacheKey: data is LiveDataSource ? "season.cache" : nil)
        films = FilmsStore(data: data)
        ballot = BallotStore(data: data)
        plan = PlanStore(data: data)
        groups = GroupsStore(data: data)
        leaderboard = LeaderboardStore(data: data)
        profile = ProfileStore(data: data)
        push = PushStore(data: data)
    }

    /// At launch: restore the session, then load the season and everything for the user.
    func start() async {
        await session.restore()
        await refresh()
        await push.refresh()
    }

    /// Loads (or reloads) everything at once, for launch, sign-in and pull to refresh.
    func refresh() async {
        let userID = session.userID
        async let season: Void = loadSeasonAndBoards()
        async let films: Void = films.load(userID: userID)
        async let ballot: Void = ballot.load(userID: userID)
        if let userID {
            async let plan: Void = plan.load(userID: userID)
            async let groups: Void = groups.load(userID: userID)
            async let profile: Void = profile.load(userID: userID)
            async let push: Void = push.signedIn()
            _ = await (plan, groups, profile, push)
        }
        _ = await (season, films, ballot)
    }

    /// Back from the background: the season may have moved on (the lock, the
    /// winners), and the push token may have changed.
    func foreground() async {
        async let season: Void = loadSeasonAndBoards()
        async let push: Void = push.refresh()
        _ = await (season, push)
    }

    /// The boards need the ceremony's id.
    private func loadSeasonAndBoards() async {
        await season.load()
        guard session.userID != nil else { return }
        await leaderboard.reload(ceremonyID: season.ceremony?.id)
    }

    func signOut() async {
        await push.signingOut()
        await session.signOut()
        clearUserData()
    }

    /// Deletes the account, and signs out only if that worked (guideline 5.1.1).
    func deleteAccount(appleAuthorizationCode: String? = nil) async -> Bool {
        guard await profile.deleteAccount(appleAuthorizationCode: appleAuthorizationCode) else { return false }
        session.didDeleteAccount()
        clearUserData()
        return true
    }

    private func clearUserData() {
        films.reset()
        ballot.reset()
        plan.reset()
        groups.reset()
        leaderboard.reset()
        profile.reset()
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
