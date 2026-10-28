import Foundation

/// A category on the ballot with its nominees (each nomination carries its film).
nonisolated struct BallotCategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let pointsValue: Int
    let nominations: [BallotNominee]
    /// `categories.display_mode`; nil from a copy cached before P6-05.
    var displayMode: DisplayMode? = nil
    /// The ceremony it belongs to; nil from a copy cached before 2.1. Films
    /// shows the nominees only once they're the contenders' ceremony's (P9-05).
    var ceremonyID: Int? = nil

    nonisolated enum DisplayMode: String, Codable, Hashable, Sendable {
        case person, film
    }

    /// The same category with `winners` as its winners and nobody else.
    func withWinners(_ winners: Set<Int>) -> BallotCategory {
        BallotCategory(id: id, name: name, pointsValue: pointsValue, nominations: nominations.map {
            BallotNominee(id: $0.id, movie: $0.movie, personName: $0.personName, isWinner: winners.contains($0.id))
        }, displayMode: displayMode, ceremonyID: ceremonyID)
    }

    var winnerIDs: Set<Int> { Set(nominations.filter(\.isWinner).map(\.id)) }

    /// Acting categories lead with the person and show the film underneath.
    /// The category's `display_mode` decides; without one, any nominee with
    /// a person does.
    var leadsWithPerson: Bool {
        if let displayMode { return displayMode == .person }
        return nominations.contains { !($0.personName ?? "").isEmpty }
    }
}

nonisolated extension BallotNominee {
    /// The person for categories that lead with the person, else the film.
    func title(in category: BallotCategory) -> String? {
        if category.leadsWithPerson, let person = personName, !person.isEmpty { return person }
        return movie?.title ?? personName
    }

    /// The line under the title: the film under the person, or the detail
    /// (a song, a country) under the film.
    func detail(in category: BallotCategory) -> String? {
        let title = title(in: category)
        let other = category.leadsWithPerson ? movie?.title : personName
        guard let other, !other.isEmpty, other != title else { return nil }
        return other
    }

    /// "Jessie Buckley, in Hamnet" for acting categories, else the film.
    func spokenName(in category: BallotCategory) -> String {
        guard let title = title(in: category) else { return "Nominee" }
        guard let detail = detail(in: category) else { return title }
        return category.leadsWithPerson ? "\(title), in \(detail)" : "\(title), \(detail)"
    }
}

/// How many of a group's members picked a nominee, after the lock (P6-05).
nonisolated struct PickShare: Codable, Hashable, Sendable {
    let categoryId: Int
    let nominationId: Int
    let memberCount: Int
    let pickCount: Int

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case nominationId = "nomination_id"
        case memberCount = "member_count"
        case pickCount = "pick_count"
    }

    /// The share of the group, rounded to a whole percent.
    var percent: Int {
        memberCount > 0 ? Int((Double(pickCount) / Double(memberCount) * 100).rounded()) : 0
    }
}

nonisolated struct BallotNominee: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let movie: Movie?
    /// The person, for acting categories (`nominations.detail_text`).
    let personName: String?
    let isWinner: Bool
}

/// One nominee's winner flag as it changes on ceremony night (P6-02).
nonisolated struct WinnerUpdate: Equatable, Sendable {
    let nominationID: Int
    let categoryID: Int
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
    /// The films we expect to be nominated, with our odds (P9-05), for the
    /// latest ceremony that has any; by category, most likely first.
    func contenders() async throws -> [Contender]
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
    /// What a group you're in picked, per nominee; empty before the lock.
    func pickShares(ceremonyID: Int, groupID: Int) async throws -> [PickShare]

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
    /// The global board when `groupID` is nil. It counts the season's list,
    /// the contenders before nominations, whatever ceremony is active.
    func board(ceremonyID: Int, groupID: Int?) async throws -> [BoardEntry]
    /// Someone you share a group with (or yourself): their watched films on
    /// the board's list and, after the lock, their picks.
    func boardPerson(ceremonyID: Int, userID: String) async throws -> BoardPerson

    // Push (P4-09)
    /// Saves this device's APNs token for you; a token from another account moves to you.
    func registerDevice(token: String, environment: PushEnvironment) async throws
    /// Forgets this device, at sign-out.
    func removeDevice(token: String) async throws
    /// Your reminder switches, voice and time zone (P6-04); nil until first saved.
    func notificationPreferences(userID: String) async throws -> NotificationPreferences?
    /// Saves them and returns what the server stored.
    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences

    // Admin (P6-01). For `Profile.isAdmin` only: the server refuses everyone else.
    /// Every ceremony with its seed counts, newest first.
    func adminStatus() async throws -> [AdminCeremony]
    /// A ceremony's categories in the order they're announced.
    func adminBallot(ceremonyID: Int) async throws -> [BallotCategory]
    /// Marks a nominee as its category's winner, replacing any other unless
    /// `tie`; returns the category's winners.
    func setWinner(nominationID: Int, tie: Bool) async throws -> Set<Int>
    func clearWinners(categoryID: Int) async throws
    /// Sets a category's winners to exactly `nominationIDs` in one write (an
    /// empty set clears them); returns the category's winners.
    func setWinners(categoryID: Int, nominationIDs: Set<Int>) async throws -> Set<Int>
    func setActiveCeremony(id: Int) async throws
    func setCeremonyDates(id: Int, ceremonyAt: Date, ballotLockAt: Date) async throws
    /// A push to every device, through send-push.
    func sendPushToEveryone(title: String, body: String, destination: PushDestination) async throws
    /// "Nominations are out" to everyone who wants it, in their voice, once
    /// per ceremony (P6-04); returns how many people it went to.
    func sendNominationsPush(ceremonyID: Int) async throws -> Int

    // Moderation (guideline 1.2, P6-16)
    func reportUser(_ userID: String, reason: ReportReason, details: String?) async throws
    /// For a group you're in.
    func reportGroup(_ groupID: Int, reason: ReportReason, details: String?) async throws
    /// Hides you from each other on every board and takes them out of the
    /// groups you created, which they can't join again.
    func blockUser(_ userID: String) async throws
    func unblockUser(_ userID: String) async throws
    /// The people you've blocked, newest first.
    func blockedUsers() async throws -> [BlockedUser]
    /// The admin's report queue: open reports first, oldest first, then the
    /// last resolved ones.
    func adminReports() async throws -> [ContentReport]
    /// Closes the report and every other open one on the same person or
    /// group; returns how many closed.
    func resolveReport(id: Int, action: ReportAction) async throws -> Int

    // Live mode (P6-02)
    /// Nominees whose `is_winner` changes, as it happens (Realtime on
    /// `nominations`, P2-11). Ends when the subscription can't be made;
    /// cancelling the loop that reads it unsubscribes.
    func winnerUpdates() -> AsyncStream<WinnerUpdate>

    // Live Activity (P6-03)
    /// Saves a ceremony's Live Activity push token, so send-push can update it.
    func registerLiveActivity(ceremonyID: Int, token: String, environment: PushEnvironment) async throws
    /// The Live Activity ended or was dismissed: no more updates, and
    /// push-to-start leaves this ceremony alone.
    func endLiveActivity(ceremonyID: Int) async throws
    /// Saves this device's push-to-start token, so the first winner can start the activity.
    func registerLiveActivityStartToken(_ token: String, environment: PushEnvironment) async throws
    /// Forgets it, at sign-out.
    func removeLiveActivityStartToken(_ token: String) async throws

    // Profile
    func profile(userID: String) async throws -> Profile?
    func updateUsername(_ username: String, userID: String) async throws
    /// Your email and how you sign in, from the session.
    func account() async -> Account?
    /// Past seasons you played, newest first.
    func seasonHistory() async throws -> [SeasonResult]
    /// One past season, yours: ballot, watched films, boards and badges (P12-06).
    func seasonArchive(ceremonyID: Int) async throws -> SeasonArchive

    // Badges (P12-04)
    /// Someone's badges, every season, newest season first, then the case's
    /// order: yours, or someone's you share a group with (else it throws).
    func userBadges(userID: String) async throws -> [UserBadge]
    /// Revokes your Sign in with Apple tokens (guideline 5.1.1(v)), with a
    /// fresh authorization code, before the account is deleted.
    func revokeApple(authorizationCode: String) async throws
    func deleteAccount() async throws
}
