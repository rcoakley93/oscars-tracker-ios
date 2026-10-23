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
    let navigation = AppNavigation()

    init(data: any AppDataSource) {
        session = SessionStore(data: data)
        season = SeasonStore(data: data)
        films = FilmsStore(data: data)
        ballot = BallotStore(data: data)
        plan = PlanStore(data: data)
        groups = GroupsStore(data: data)
        leaderboard = LeaderboardStore(data: data)
        profile = ProfileStore(data: data)
    }

    /// At launch: restore the session, then load the season and everything for the user.
    func start() async {
        await session.restore()
        await refresh()
    }

    /// Loads (or reloads) everything at once, for launch, sign-in and pull to refresh.
    func refresh() async {
        let userID = session.userID
        async let season: Void = season.load()
        async let films: Void = films.load(userID: userID)
        async let ballot: Void = ballot.load(userID: userID)
        async let board: Void = leaderboard.load()
        if let userID {
            async let plan: Void = plan.load(userID: userID)
            async let groups: Void = groups.load(userID: userID)
            async let profile: Void = profile.load(userID: userID)
            _ = await (plan, groups, profile)
        }
        _ = await (season, films, ballot, board)
    }

    func signOut() async {
        await session.signOut()
        clearUserData()
    }

    /// Deletes the account, and signs out only if that worked (guideline 5.1.1).
    func deleteAccount() async -> Bool {
        guard await profile.deleteAccount() else { return false }
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
