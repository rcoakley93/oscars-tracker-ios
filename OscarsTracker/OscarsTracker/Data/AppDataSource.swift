import Foundation

/// A category on the ballot with its nominees (each nomination carries its film).
nonisolated struct BallotCategory: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let pointsValue: Int
    let nominations: [BallotNominee]

    /// Acting categories lead with the person and show the film underneath.
    var leadsWithPerson: Bool {
        nominations.contains { !($0.personName ?? "").isEmpty }
    }
}

nonisolated struct BallotNominee: Identifiable, Hashable, Sendable {
    let id: Int
    let movie: Movie?
    /// The person, for acting categories (`nominations.detail_text`).
    let personName: String?
    let isWinner: Bool
}

/// Everything the app reads from and writes to the backend. `LiveDataSource`
/// talks to Supabase; `SampleDataSource` serves fixed data to previews and
/// tests, so neither needs a network.
protocol AppDataSource: AnyObject, Sendable {
    // Session
    func currentUserID() async -> String?
    func signIn(email: String, password: String) async throws -> String
    func signUp(email: String, password: String) async throws -> String?
    func signOut() async throws
    func signInWithApple(idToken: String, nonce: String) async throws -> String
    func signInWithGoogle() async throws -> String
    /// Emails a link that opens the app's "Choose a new password" screen.
    func sendPasswordReset(email: String) async throws
    /// Signs in from a link in an auth email; returns the user's id.
    func openAuthLink(_ url: URL) async throws -> String
    func updatePassword(_ password: String) async throws

    // Season
    func activeCeremony() async throws -> Ceremony?

    // Films and watched
    func movies() async throws -> [Movie]
    func watchedMovieIDs(userID: String) async throws -> Set<Int>
    func setWatched(_ watched: Bool, movieID: Int, userID: String) async throws
    /// Where to watch a film in the US.
    func offers(movieID: Int) async throws -> [WatchOffer]
    /// How many in each of your groups have seen a film.
    func seenInGroups(movieID: Int) async throws -> [GroupSeen]

    // Ballot
    func ballot() async throws -> [BallotCategory]
    func picks(userID: String) async throws -> [Int: Int]
    func savePick(categoryID: Int, nominationID: Int, userID: String) async throws

    // Watch plan
    func plan(userID: String) async throws -> [WatchPlanItem]
    func addToPlan(movieID: Int, day: PlanDay, userID: String) async throws -> WatchPlanItem
    func movePlanItem(id: Int, to day: PlanDay) async throws
    func removePlanItem(id: Int) async throws

    // Groups and leaderboards
    func myGroups(userID: String) async throws -> [PoolGroup]
    func createGroup(name: String, userID: String) async throws -> PoolGroup
    func joinGroup(inviteCode: String) async throws -> JoinedGroup
    func leaveGroup(groupID: Int, userID: String) async throws
    func deleteGroup(groupID: Int) async throws
    func removeMember(userID: String, groupID: Int) async throws
    func groupLeaderboard(groupID: Int) async throws -> [GroupLeaderboardEntry]
    func leaderboard() async throws -> [LeaderboardEntry]

    // Profile
    func profile(userID: String) async throws -> Profile?
    func updateUsername(_ username: String, userID: String) async throws
    func deleteAccount() async throws
}
