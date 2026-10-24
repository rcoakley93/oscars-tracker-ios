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
    /// The active ceremony and the server's clock; nil between seasons.
    func seasonFacts() async throws -> SeasonFacts?
    func appConfig() async throws -> AppConfig

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
    /// The global board when `groupID` is nil.
    func board(ceremonyID: Int, groupID: Int?) async throws -> [BoardEntry]
    /// Someone you share a group with (or yourself): their watched nominees
    /// and, after the lock, their picks.
    func boardPerson(ceremonyID: Int, userID: String) async throws -> BoardPerson

    // Push (P4-09)
    /// Saves this device's APNs token for you; a token from another account moves to you.
    func registerDevice(token: String, environment: PushEnvironment) async throws
    /// Forgets this device, at sign-out.
    func removeDevice(token: String) async throws

    // Profile
    func profile(userID: String) async throws -> Profile?
    func updateUsername(_ username: String, userID: String) async throws
    /// Your email and how you sign in, from the session.
    func account() async -> Account?
    /// Past seasons you played, newest first.
    func seasonHistory() async throws -> [SeasonResult]
    /// Revokes your Sign in with Apple tokens (guideline 5.1.1(v)), with a
    /// fresh authorization code, before the account is deleted.
    func revokeApple(authorizationCode: String) async throws
    func deleteAccount() async throws
}
