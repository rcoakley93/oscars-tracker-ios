import Foundation

/// Fixed sample data for previews and tests: a small season with real 2026
/// nominee titles, a few picks and a watch plan. No network; writes change
/// the in-memory copy, so previews behave like the real app.
final class SampleDataSource: AppDataSource {
    nonisolated static let userID = "00000000-0000-0000-0000-000000000001"

    var signedIn: Bool
    var ceremony: Ceremony
    var movieList: [Movie]
    var watched: Set<Int>
    var categories: [BallotCategory]
    var savedPicks: [Int: Int]
    var planItems: [WatchPlanItem]
    var groups: [PoolGroup]
    var board: [BoardEntry]
    /// Where to watch, by film; films not listed have no offers.
    var offerList: [Int: [WatchOffer]] = SampleData.offers
    var userProfile: Profile?
    /// Makes every call fail with this error, to preview error states.
    var failure: AppError?

    init(signedIn: Bool = true, now: Date = .now) {
        self.signedIn = signedIn
        ceremony = Ceremony(
            id: 2,
            number: 99,
            name: "99th Academy Awards",
            ceremonyAt: Calendar.current.date(byAdding: .day, value: 33, to: now) ?? now,
            ballotLockAt: Calendar.current.date(byAdding: .day, value: 33, to: now) ?? now,
            isActive: true
        )
        movieList = SampleData.movies
        watched = [1, 4, 7]
        categories = SampleData.categories
        savedPicks = [1: 103, 2: 201]
        let today = PlanDay.today(now: now)
        planItems = [
            SampleData.planItem(id: 1, movieID: 2, day: today.adding(days: -2)),
            SampleData.planItem(id: 2, movieID: 3, day: today),
            SampleData.planItem(id: 3, movieID: 5, day: today.adding(days: 1)),
        ]
        groups = [
            PoolGroup(id: 1, name: "Movies LLC", createdBy: Self.userID, inviteCode: "OSCAR9", createdAt: nil),
            PoolGroup(id: 2, name: "Family pool", createdBy: "someone-else", inviteCode: "FAMILY", createdAt: nil),
        ]
        board = SampleData.leaderboard
        userProfile = Profile(id: Self.userID, username: "filmbuff", avatarUrl: nil, createdAt: "2026-01-12T10:00:00Z", updatedAt: nil)
    }

    private func check() throws {
        if let failure { throw failure }
    }

    private func requireUser() throws -> String {
        try check()
        guard signedIn else { throw AppError.notSignedIn }
        return Self.userID
    }

    // MARK: - Session

    func currentUserID() async -> String? { signedIn ? Self.userID : nil }

    func signIn(email: String, password: String) async throws -> String {
        try check()
        guard password.count >= 8 else { throw AppError.invalidCredentials }
        signedIn = true
        return Self.userID
    }

    func signUp(email: String, password: String) async throws -> String? {
        try check()
        signedIn = true
        return Self.userID
    }

    func signOut() async throws { signedIn = false }

    func signInWithApple(idToken: String, nonce: String) async throws -> String {
        try check()
        signedIn = true
        return Self.userID
    }

    func signInWithGoogle() async throws -> String {
        try check()
        signedIn = true
        return Self.userID
    }

    var resetEmails: [String] = []

    func sendPasswordReset(email: String) async throws {
        try check()
        resetEmails.append(email)
    }

    func openAuthLink(_ url: URL) async throws -> String {
        try check()
        signedIn = true
        return Self.userID
    }

    var newPassword: String?

    func updatePassword(_ password: String) async throws {
        _ = try requireUser()
        newPassword = password
    }

    // MARK: - Season

    func activeCeremony() async throws -> Ceremony? {
        try check()
        return ceremony
    }

    func runtimeBuckets() async throws -> [RuntimeBucket] {
        try check()
        return RuntimeBucket.defaults
    }

    // MARK: - Films and watched

    func movies() async throws -> [Movie] {
        try check()
        return movieList
    }

    func watchedMovieIDs(userID: String) async throws -> Set<Int> {
        _ = try requireUser()
        return watched
    }

    func offers(movieID: Int) async throws -> [WatchOffer] {
        try check()
        return offerList[movieID] ?? []
    }

    func seenInGroups(movieID: Int) async throws -> [GroupSeen] {
        _ = try requireUser()
        return groups.map { group in
            GroupSeen(groupId: group.id, groupName: group.name, memberCount: 6, seenCount: (movieID + group.id) % 6 + (watched.contains(movieID) ? 1 : 0))
        }
    }

    func setWatched(_ isWatched: Bool, movieID: Int, userID: String) async throws {
        _ = try requireUser()
        if isWatched { watched.insert(movieID) } else { watched.remove(movieID) }
    }

    // MARK: - Ballot

    func ballot() async throws -> [BallotCategory] {
        try check()
        return categories
    }

    func picks(userID: String) async throws -> [Int: Int] {
        _ = try requireUser()
        return savedPicks
    }

    func savePick(categoryID: Int, nominationID: Int, userID: String) async throws {
        _ = try requireUser()
        guard !ceremony.isBallotLocked() else { throw AppError.ballotLocked }
        savedPicks[categoryID] = nominationID
    }

    // MARK: - Watch plan

    func plan(userID: String) async throws -> [WatchPlanItem] {
        _ = try requireUser()
        return planItems
    }

    func addToPlan(movieID: Int, day: PlanDay, userID: String) async throws -> WatchPlanItem {
        _ = try requireUser()
        let item = SampleData.planItem(id: (planItems.map(\.id).max() ?? 0) + 1, movieID: movieID, day: day)
        planItems.append(item)
        return item
    }

    func movePlanItem(id: Int, to day: PlanDay) async throws {
        _ = try requireUser()
        guard let index = planItems.firstIndex(where: { $0.id == id }) else { return }
        planItems[index].plannedDate = day.description
    }

    func removePlanItem(id: Int) async throws {
        _ = try requireUser()
        planItems.removeAll { $0.id == id }
    }

    // MARK: - Groups and leaderboards

    func myGroups(userID: String) async throws -> [PoolGroup] {
        _ = try requireUser()
        return groups
    }

    func createGroup(name: String, userID: String) async throws -> PoolGroup {
        _ = try requireUser()
        guard groups.count < 5 else { throw AppError.tooManyGroups }
        let group = PoolGroup(id: (groups.map(\.id).max() ?? 0) + 1, name: name, createdBy: Self.userID, inviteCode: LiveDataSource.newInviteCode(), createdAt: nil)
        groups.append(group)
        return group
    }

    func joinGroup(inviteCode: String) async throws -> JoinedGroup {
        _ = try requireUser()
        let code = inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        if groups.contains(where: { $0.inviteCode == code }) { throw AppError.alreadyInGroup }
        guard code == "FRIEND" else { throw AppError.invalidInviteCode }
        let group = PoolGroup(id: 9, name: "Film club", createdBy: "someone-else", inviteCode: code, createdAt: nil)
        groups.append(group)
        return JoinedGroup(groupId: group.id, groupName: group.name)
    }

    func leaveGroup(groupID: Int, userID: String) async throws {
        _ = try requireUser()
        groups.removeAll { $0.id == groupID }
    }

    func deleteGroup(groupID: Int) async throws {
        _ = try requireUser()
        groups.removeAll { $0.id == groupID }
    }

    func removeMember(userID: String, groupID: Int) async throws {
        _ = try requireUser()
    }

    /// The global board is everyone; Movies LLC the top six; any other group just you.
    func board(ceremonyID: Int, groupID: Int?) async throws -> [BoardEntry] {
        _ = try requireUser()
        switch groupID {
        case nil: return board
        case 1: return Array(board.prefix(6))
        default: return board.filter { $0.userId == Self.userID }.map { $0.ranked(1) }
        }
    }

    /// Everyone on the sample board watched the first films in the list; picks show after the lock.
    func boardPerson(ceremonyID: Int, userID: String) async throws -> BoardPerson {
        let me = try requireUser()
        if userID == me { return BoardPerson(watchedMovieIDs: watched, picks: savedPicks) }
        guard let entry = board.first(where: { $0.userId == userID }) else { throw AppError.server("Not in a group with this person") }
        let films = Set(movieList.prefix(entry.watchedCount).map(\.id))
        let picks = ceremony.isBallotLocked() ? Dictionary(uniqueKeysWithValues: categories.compactMap { c in c.nominations.first.map { (c.id, $0.id) } }) : [:]
        return BoardPerson(watchedMovieIDs: films, picks: picks)
    }

    // MARK: - Profile

    func profile(userID: String) async throws -> Profile? {
        _ = try requireUser()
        return userProfile
    }

    func updateUsername(_ username: String, userID: String) async throws {
        _ = try requireUser()
        if let current = userProfile {
            userProfile = Profile(id: current.id, username: username, avatarUrl: current.avatarUrl, createdAt: current.createdAt, updatedAt: nil)
        }
    }

    func deleteAccount() async throws {
        _ = try requireUser()
        signedIn = false
        userProfile = nil
    }
}

/// The sample season itself.
nonisolated enum SampleData {
    static let movies: [Movie] = [
        movie(1, "Hamnet", 2025, 126),
        movie(2, "Frankenstein", 2025, 150),
        movie(3, "KPop Demon Hunters", 2025, 96),
        movie(4, "One Battle After Another", 2025, 162),
        movie(5, "Sinners", 2025, 137),
        movie(6, "Sentimental Value", 2025, 133),
        movie(7, "Bugonia", 2025, 118),
        movie(8, "It Was Just an Accident", 2025, 103),
        movie(9, "Marty Supreme", 2025, 149),
        movie(10, "Train Dreams", 2025, 102),
    ]

    /// Where to watch the first few sample films (logos from the live `providers` table).
    static let offers: [Int: [WatchOffer]] = {
        func offer(_ id: Int, _ type: String, _ name: String, _ logo: String?) -> WatchOffer {
            WatchOffer(id: id, availabilityType: type, provider: .init(name: name, logoPath: logo))
        }
        let apple = "/qdEGArH3lKfFnAtYXMkSYk5wxuG.png", amazon = "/jn6TLbtaTZntTRX9UYucHJvpQx1.png", google = "/aZRENwYILujqs0RVOZutTh0BVGV.png"
        return [
            1: [offer(1, "streaming", "Peacock", nil), offer(2, "rent", "Apple TV Store", apple), offer(3, "rent", "Amazon Video", amazon), offer(4, "buy", "Apple TV Store", apple), offer(5, "buy", "Google Play Movies", google)],
            2: [offer(6, "streaming", "Netflix", nil)],
            3: [offer(7, "streaming", "Netflix", nil), offer(8, "theaters", "Theaters (Limited)", nil)],
        ]
    }()

    /// TMDB poster paths for the sample films (from the live `movies` table).
    static let posterPaths: [String: String] = [
        "Hamnet": "61xMzN4h8iLk0hq6oUzr9Ts6GE9",
        "Frankenstein": "g4JtvGlQO7DByTI6frUobqvSL3R",
        "KPop Demon Hunters": "zT7Lhw3BhJbMkRqm9Zlx2YGMsY0",
        "Sinners": "lOfjeJMKS7cOaaTn6q3J0y2ypiA",
        "Sentimental Value": "24JALfUQsIgfNqMD7vTbqEVfsqf",
        "Bugonia": "oxgsAQDAAxA92mFGYCZllgWkH9J",
        "It Was Just an Accident": "eNYGj2DG3n8OrVPTfYunpPW9uas",
        "Marty Supreme": "firAhZA0uQvRL2slp7v3AnOj0ZX",
        "Train Dreams": "wfzYOVdafdbD1d3SxNqiBtV2Yhx",
    ]

    static func movie(_ id: Int, _ title: String, _ year: Int, _ runtime: Int) -> Movie {
        let poster = posterPaths[title].map { "https://image.tmdb.org/t/p/w342/\($0).jpg" }
        return Movie(id: id, title: title, posterUrl: poster, releaseYear: year, runtimeMinutes: runtime, createdAt: nil)
    }

    static func film(_ id: Int) -> Movie? { movies.first { $0.id == id } }

    static let categories: [BallotCategory] = [
        BallotCategory(id: 1, name: "Best Picture", pointsValue: 10, nominations: [
            BallotNominee(id: 101, movie: film(1), personName: nil, isWinner: false),
            BallotNominee(id: 102, movie: film(4), personName: nil, isWinner: false),
            BallotNominee(id: 103, movie: film(5), personName: nil, isWinner: false),
            BallotNominee(id: 104, movie: film(6), personName: nil, isWinner: false),
            BallotNominee(id: 105, movie: film(9), personName: nil, isWinner: false),
        ]),
        BallotCategory(id: 2, name: "Actress in a Leading Role", pointsValue: 5, nominations: [
            BallotNominee(id: 201, movie: film(1), personName: "Jessie Buckley", isWinner: false),
            BallotNominee(id: 202, movie: film(6), personName: "Renate Reinsve", isWinner: false),
            BallotNominee(id: 203, movie: film(7), personName: "Emma Stone", isWinner: false),
        ]),
        BallotCategory(id: 3, name: "Animated Feature", pointsValue: 3, nominations: [
            BallotNominee(id: 301, movie: film(3), personName: nil, isWinner: false),
        ]),
    ]

    static func planItem(id: Int, movieID: Int, day: PlanDay) -> WatchPlanItem {
        var item = WatchPlanItem(id: id, userId: SampleDataSource.userID, movieId: movieID, plannedDate: day.description, createdAt: nil)
        item.movie = film(movieID)
        return item
    }

    static let leaderboard: [BoardEntry] = [
        BoardEntry.sample("u-sam", "Sam", watched: 31, rank: 1),
        BoardEntry.sample(SampleDataSource.userID, "filmbuff", watched: 29, rank: 2),
        BoardEntry.sample("u-jordan", "Jordan", watched: 24, rank: 3),
        BoardEntry.sample("u-alex", "Alex", watched: 19, rank: 4),
        BoardEntry.sample("u-priya", "Priya", watched: 15, rank: 5),
        BoardEntry.sample("u-chris", "Chris", watched: 9, rank: 6),
    ]
}

nonisolated extension BoardEntry {
    /// A board row before any winners: no score yet, ranked by films watched.
    static func sample(_ userID: String, _ name: String, watched: Int, rank: Int, score: Int = 0, scoring: Scoring = .traditional, isCreator: Bool = false) -> BoardEntry {
        BoardEntry(rank: rank, userId: userID, username: name, avatarUrl: nil, watchedCount: watched,
                   correctCount: scoring == .traditional ? score : 0, points: score, score: score, scoring: scoring, isCreator: isCreator)
    }

    func ranked(_ rank: Int) -> BoardEntry {
        BoardEntry(rank: rank, userId: userId, username: username, avatarUrl: avatarUrl, watchedCount: watchedCount,
                   correctCount: correctCount, points: points, score: score, scoring: scoring, isCreator: isCreator)
    }
}
