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
    /// The admin screen's account (P6-01); the admin calls refuse anyone else.
    var isAdmin = false
    /// Pushes sent to everyone, newest last.
    var sentPushes: [String] = []
    /// Makes every call fail with this error, to preview error states.
    var failure: AppError?
    /// Serves the season as the rehearsal ceremony, as a tester sees it (P2-13).
    var isRehearsal = false

    /// `fullBallot` adds the rest of a real ballot's 24 categories, to check
    /// scrolling and deep links on a long ballot.
    init(signedIn: Bool = true, fullBallot: Bool = false, now: Date = .now) {
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
        categories = fullBallot ? SampleData.fullBallot : SampleData.categories
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

    /// The server's clock, for tests of a phone whose clock is wrong.
    var serverNow: Date?
    var config = AppConfig.defaults

    func seasonFacts() async throws -> SeasonFacts? {
        try check()
        let now = serverNow ?? .now
        return SeasonFacts(id: ceremony.id, number: ceremony.number, name: ceremony.name, ceremonyAt: ceremony.ceremonyAt,
                           ballotLockAt: ceremony.ballotLockAt, isLocked: now >= ceremony.ballotLockAt, isRehearsal: isRehearsal, serverNow: now)
    }

    func appConfig() async throws -> AppConfig {
        try check()
        return config
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

    /// The ballot locked an hour ago; with `winners`, the first nominee in
    /// every category has won (so the sample picks score 0, 5 and nothing).
    func passLock(winners: Bool = false) {
        ceremony = Ceremony(id: ceremony.id, number: ceremony.number, name: ceremony.name, ceremonyAt: .now,
                            ballotLockAt: .now.addingTimeInterval(-3600), isActive: true)
        guard winners else { return }
        categories = categories.map { category in
            BallotCategory(id: category.id, name: category.name, pointsValue: category.pointsValue,
                           nominations: category.nominations.enumerated().map { index, nominee in
                               BallotNominee(id: nominee.id, movie: nominee.movie, personName: nominee.personName, isWinner: index == 0)
                           }, displayMode: category.displayMode)
        }
    }

    /// Sample films whose posters don't suit a 4+ store image (a gun aimed,
    /// a face dripping like a wound, a skull in hand).
    static let storeUnsafeFilms: Set<Int> = [2, 5, 7]

    /// The season for App Store captures (`-store-shots`): the same story with
    /// the films above left out of the season (films, ballot, plan, everyone's
    /// watched lists), so no screen can show their posters. The posters
    /// themselves are untouched.
    func useStoreSafeSeason() {
        let unsafe = Self.storeUnsafeFilms
        movieList.removeAll { unsafe.contains($0.id) }
        watched = [1, 4, 6]
        categories = categories.map { category in
            BallotCategory(id: category.id, name: category.name, pointsValue: category.pointsValue,
                           nominations: category.nominations.filter { !unsafe.contains($0.movie?.id ?? 0) },
                           displayMode: category.displayMode)
        }
        savedPicks[1] = 104  // Sentimental Value, not Sinners
        let swaps = [2: 8, 5: 9]  // Frankenstein and Sinners leave the plan for It Was Just an Accident and Marty Supreme
        planItems = planItems.map { item in
            guard let movieID = swaps[item.movieId], let day = PlanDay(item.plannedDate) else { return item }
            return SampleData.planItem(id: item.id, movieID: movieID, day: day)
        }
    }

    /// Fixed shares to serve instead of the made-up ones.
    var shareRows: [PickShare]?
    /// How long each group's shares take to arrive, for tests of answers
    /// that come back out of order.
    var shareDelays: [Int: Duration] = [:]

    /// After the lock, each category's nominees split six members 3, 2, 1
    /// (four in other groups: 2, 1, 1), starting from a different nominee
    /// in each category. Groups you're not in are refused.
    func pickShares(ceremonyID: Int, groupID: Int) async throws -> [PickShare] {
        _ = try requireUser()
        if let delay = shareDelays[groupID] { try await Task.sleep(for: delay) }
        guard groups.contains(where: { $0.id == groupID }) else { throw AppError.server("Not a member of this group") }
        guard ceremony.isBallotLocked() else { return [] }
        if let shareRows { return shareRows }
        let members = groupID == 1 ? 6 : 4
        let counts = groupID == 1 ? [3, 2, 1] : [2, 1, 1]
        return categories.flatMap { category in
            let nominees = category.nominations
            return counts.prefix(nominees.count).enumerated().map { offset, count in
                let nominee = nominees[(category.id + offset) % nominees.count]
                return PickShare(categoryId: category.id, nominationId: nominee.id, memberCount: members, pickCount: count)
            }
        }
    }

    // MARK: - Watch plan

    func plan(userID: String) async throws -> [WatchPlanItem] {
        _ = try requireUser()
        return planItems
    }

    func addToPlan(movieID: Int, day: PlanDay, userID: String) async throws -> WatchPlanItem {
        _ = try requireUser()
        try check()
        // Like the server's upsert: a film is planned once, so planning it again moves it.
        if let index = planItems.firstIndex(where: { $0.movieId == movieID }) {
            planItems[index].plannedDate = day.description
            return planItems[index]
        }
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
        guard groups.count < config.userGroupLimit else { throw AppError.tooManyGroups(limit: config.userGroupLimit) }
        let group = PoolGroup(id: (groups.map(\.id).max() ?? 0) + 1, name: name, createdBy: Self.userID, inviteCode: LiveDataSource.newInviteCode(), createdAt: nil)
        groups.append(group)
        return group
    }

    func joinGroup(inviteCode: String) async throws -> JoinedGroup {
        _ = try requireUser()
        let code = inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        if groups.contains(where: { $0.inviteCode == code }) { throw AppError.alreadyInGroup }
        guard code == "FRIEND" else { throw AppError.invalidInviteCode }
        guard groups.count < config.userGroupLimit else { throw AppError.tooManyGroups(limit: config.userGroupLimit) }
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
        let board = scoredBoard.filter { entry in !blocked.contains { $0.userId == entry.userId } }
            .enumerated().map { $0.element.ranked($0.offset + 1) }
        switch groupID {
        case nil: return board
        case 1: return Array(board.prefix(6))
        default: return board.filter { $0.userId == Self.userID }.map { $0.ranked(1) }
        }
    }

    /// Once winners are in, your score counts your correct picks (one point
    /// each, the traditional rule) and the board is ranked by score, then
    /// films; everyone else keeps their sample score.
    private var scoredBoard: [BoardEntry] {
        guard categories.contains(where: { !$0.winnerIDs.isEmpty }) else { return board }
        let correct = categories.count { category in savedPicks[category.id].map(category.winnerIDs.contains) ?? false }
        let rescored = board.map { entry in
            entry.userId == Self.userID
                ? BoardEntry.sample(entry.userId, entry.username, watched: entry.watchedCount, rank: entry.rank, score: correct, isCreator: entry.isCreator)
                : entry
        }
        return rescored.sorted { ($0.score, $0.watchedCount) > ($1.score, $1.watchedCount) }
            .enumerated().map { $0.element.ranked($0.offset + 1) }
    }

    /// Everyone on the sample board watched the first films in the list; picks show after the lock.
    func boardPerson(ceremonyID: Int, userID: String) async throws -> BoardPerson {
        let me = try requireUser()
        if userID == me { return BoardPerson(watchedMovieIDs: watched, picks: savedPicks) }
        guard let entry = board.first(where: { $0.userId == userID }), !blocked.contains(where: { $0.userId == userID }) else {
            throw AppError.server("Not in a group with this person")
        }
        let films = Set(movieList.prefix(entry.watchedCount).map(\.id))
        let picks = ceremony.isBallotLocked() ? Dictionary(uniqueKeysWithValues: categories.compactMap { c in c.nominations.first.map { (c.id, $0.id) } }) : [:]
        return BoardPerson(watchedMovieIDs: films, picks: picks)
    }

    // MARK: - Push

    var devices: [String: PushEnvironment] = [:]

    func registerDevice(token: String, environment: PushEnvironment) async throws {
        _ = try requireUser()
        devices[token] = environment
    }

    func removeDevice(token: String) async throws {
        devices[token] = nil
    }

    /// Live Activity tokens by ceremony, ended ceremonies, and push-to-start tokens (P6-03).
    var liveActivityTokens: [Int: String] = [:]
    var endedLiveActivities: Set<Int> = []
    var liveActivityStartTokens: [String: PushEnvironment] = [:]

    func registerLiveActivity(ceremonyID: Int, token: String, environment: PushEnvironment) async throws {
        _ = try requireUser()
        liveActivityTokens[ceremonyID] = token
        endedLiveActivities.remove(ceremonyID)
    }

    func endLiveActivity(ceremonyID: Int) async throws {
        _ = try requireUser()
        liveActivityTokens[ceremonyID] = nil
        endedLiveActivities.insert(ceremonyID)
    }

    func registerLiveActivityStartToken(_ token: String, environment: PushEnvironment) async throws {
        _ = try requireUser()
        liveActivityStartTokens[token] = environment
    }

    func removeLiveActivityStartToken(_ token: String) async throws {
        liveActivityStartTokens[token] = nil
    }

    var preferences: NotificationPreferences?
    /// Every preferences save, in order, and an optional pause before each, to test overlap.
    var preferenceSaves: [NotificationPreferences] = []
    var preferenceSaveDelay: Duration?

    func notificationPreferences(userID: String) async throws -> NotificationPreferences? {
        try check()
        return preferences
    }

    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        if let preferenceSaveDelay { try? await Task.sleep(for: preferenceSaveDelay) }
        try check()
        _ = try requireUser()
        preferenceSaves.append(preferences)
        self.preferences = preferences
        return preferences
    }

    // MARK: - Account

    var accountProvider: Account.Provider = .email
    var history: [SeasonResult] = [
        SeasonResult(ceremonyId: 1, number: 98, name: "98th Academy Awards", ceremonyAt: Date(timeIntervalSince1970: 1_773_014_400),
                     watchedCount: 41, correctCount: 15, points: 15, score: 15, scoring: .traditional, rank: 3, players: 212),
    ]
    var revokedAppleCodes: [String] = []

    func account() async -> Account? {
        signedIn ? Account(email: "filmbuff@example.com", provider: accountProvider) : nil
    }

    func seasonHistory() async throws -> [SeasonResult] {
        _ = try requireUser()
        return history
    }

    func revokeApple(authorizationCode: String) async throws {
        _ = try requireUser()
        revokedAppleCodes.append(authorizationCode)
    }

    // MARK: - Live mode

    private var winnerListeners: [UUID: AsyncStream<WinnerUpdate>.Continuation] = [:]

    /// Every winner change, as Realtime would send it: one update per nominee
    /// whose flag changed.
    func winnerUpdates() -> AsyncStream<WinnerUpdate> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: WinnerUpdate.self)
        if failure != nil {
            continuation.finish()
            return stream
        }
        winnerListeners[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.winnerListeners[id] = nil }
        }
        return stream
    }

    /// Sets a category's winners and tells the listeners, like the admin RPCs.
    func announce(_ winners: Set<Int>, inCategory categoryID: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        announce(winners, at: index)
    }

    private func announce(_ winners: Set<Int>, at index: Int) {
        let before = categories[index]
        categories[index] = before.withWinners(winners)
        for nominee in before.nominations where nominee.isWinner != winners.contains(nominee.id) {
            let update = WinnerUpdate(nominationID: nominee.id, categoryID: before.id, isWinner: !nominee.isWinner)
            for listener in winnerListeners.values { listener.yield(update) }
        }
    }

    // MARK: - Admin

    private func requireAdmin() throws {
        _ = try requireUser()
        guard isAdmin else { throw AppError.adminsOnly }
    }

    func adminStatus() async throws -> [AdminCeremony] {
        try requireAdmin()
        let past = Ceremony(id: 1, number: 98, name: "98th Academy Awards", ceremonyAt: Date(timeIntervalSince1970: 1_773_615_600),
                            ballotLockAt: Date(timeIntervalSince1970: 1_773_615_600), isActive: false)
        return [ceremony, past].map { ceremony in
            let isCurrent = ceremony.id == self.ceremony.id
            return AdminCeremony(id: ceremony.id, number: ceremony.number, name: ceremony.name, ceremonyAt: ceremony.ceremonyAt,
                                 ballotLockAt: ceremony.ballotLockAt, isActive: ceremony.isActive, isRehearsal: isCurrent && isRehearsal,
                                 categories: isCurrent ? categories.count : 24,
                                 nominations: isCurrent ? categories.map(\.nominations.count).reduce(0, +) : 120,
                                 winners: isCurrent ? categories.count { !$0.winnerIDs.isEmpty } : 24,
                                 filmsWithoutPosters: isCurrent ? 1 : 0, devices: 3)
        }
    }

    /// The current ceremony's categories, small ones first and Best Picture last.
    func adminBallot(ceremonyID: Int) async throws -> [BallotCategory] {
        try requireAdmin()
        guard ceremonyID == ceremony.id else { return [] }
        return categories.sorted { ($0.pointsValue, $0.name) < ($1.pointsValue, $1.name) }
    }

    func setWinner(nominationID: Int, tie: Bool) async throws -> Set<Int> {
        try requireAdmin()
        guard let index = categories.firstIndex(where: { $0.nominations.contains { $0.id == nominationID } }) else {
            throw AppError.server("Unknown nomination \(nominationID)")
        }
        let winners = (tie ? categories[index].winnerIDs : []).union([nominationID])
        announce(winners, at: index)
        return winners
    }

    func clearWinners(categoryID: Int) async throws {
        try requireAdmin()
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        announce([], at: index)
    }

    func setWinners(categoryID: Int, nominationIDs: Set<Int>) async throws -> Set<Int> {
        try requireAdmin()
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else {
            throw AppError.server("Unknown category \(categoryID)")
        }
        guard nominationIDs.isSubset(of: categories[index].nominations.map(\.id)) else {
            throw AppError.server("Those nominees aren't all in category \(categoryID)")
        }
        announce(nominationIDs, at: index)
        return nominationIDs
    }

    func setActiveCeremony(id: Int) async throws {
        try requireAdmin()
        ceremony = Ceremony(id: ceremony.id, number: ceremony.number, name: ceremony.name, ceremonyAt: ceremony.ceremonyAt,
                            ballotLockAt: ceremony.ballotLockAt, isActive: id == ceremony.id)
    }

    func setCeremonyDates(id: Int, ceremonyAt: Date, ballotLockAt: Date) async throws {
        try requireAdmin()
        guard ballotLockAt <= ceremonyAt else { throw AppError.server("The ballot must lock before the ceremony starts") }
        guard id == ceremony.id else { return }
        ceremony = Ceremony(id: ceremony.id, number: ceremony.number, name: ceremony.name, ceremonyAt: ceremonyAt,
                            ballotLockAt: ballotLockAt, isActive: ceremony.isActive)
    }

    func sendPushToEveryone(title: String, body: String, destination: PushDestination) async throws {
        try requireAdmin()
        sentPushes.append(title)
    }

    /// Ceremonies whose nominations push went out.
    var nominationsPushes: [Int] = []

    func sendNominationsPush(ceremonyID: Int) async throws -> Int {
        try requireAdmin()
        guard !nominationsPushes.contains(ceremonyID) else { return 0 }
        nominationsPushes.append(ceremonyID)
        return devices.count
    }

    // MARK: - Moderation

    /// Reports sent, newest last; the admin's queue.
    var reports: [ContentReport] = SampleData.reports
    var blocked: [BlockedUser] = []

    func reportUser(_ userID: String, reason: ReportReason, details: String?) async throws {
        let me = try requireUser()
        guard userID != me else { throw AppError.server("You can't report yourself") }
        let name = board.first { $0.userId == userID }?.username ?? "Someone"
        file(.user, reason: reason, details: details, name: name, userID: userID, groupID: nil)
    }

    func reportGroup(_ groupID: Int, reason: ReportReason, details: String?) async throws {
        _ = try requireUser()
        guard let group = groups.first(where: { $0.id == groupID }) else { throw AppError.server("Nothing to report") }
        file(.group, reason: reason, details: details, name: group.name, userID: nil, groupID: groupID)
    }

    private func file(_ kind: ContentReport.Kind, reason: ReportReason, details: String?, name: String, userID: String?, groupID: Int?) {
        reports.append(ContentReport(id: (reports.map(\.id).max() ?? 0) + 1, kind: kind, reason: reason, details: details,
                                     reportedName: name, currentName: name, reportedUserId: userID, groupId: groupID,
                                     reporterName: userProfile?.username, status: .open, createdAt: .now))
    }

    func blockUser(_ userID: String) async throws {
        let me = try requireUser()
        guard userID != me else { throw AppError.server("You can't block yourself") }
        guard !blocked.contains(where: { $0.userId == userID }) else { return }
        let name = board.first { $0.userId == userID }?.username
        blocked.insert(BlockedUser(userId: userID, username: name, avatarUrl: nil, blockedAt: .now), at: 0)
    }

    func unblockUser(_ userID: String) async throws {
        _ = try requireUser()
        blocked.removeAll { $0.userId == userID }
    }

    func blockedUsers() async throws -> [BlockedUser] {
        _ = try requireUser()
        return blocked
    }

    func adminReports() async throws -> [ContentReport] {
        try requireAdmin()
        return reports.filter { $0.status == .open } + reports.filter { $0.status != .open }
    }

    func resolveReport(id: Int, action: ReportAction) async throws -> Int {
        try requireAdmin()
        guard let report = reports.first(where: { $0.id == id }) else { throw AppError.server("Unknown report") }
        var closed = 0
        for index in reports.indices where reports[index].id == id
            || (reports[index].status == .open && reports[index].kind == report.kind
                && reports[index].reportedUserId == report.reportedUserId && reports[index].groupId == report.groupId) {
            reports[index].status = action == .dismiss ? .dismissed : .actioned
            closed += 1
        }
        return closed
    }

    // MARK: - Profile

    func profile(userID: String) async throws -> Profile? {
        _ = try requireUser()
        guard var profile = userProfile else { return nil }
        if isAdmin { profile.isAdmin = true }
        return profile
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
        ], displayMode: .film),
        BallotCategory(id: 2, name: "Actress in a Leading Role", pointsValue: 5, nominations: [
            BallotNominee(id: 201, movie: film(1), personName: "Jessie Buckley", isWinner: false),
            BallotNominee(id: 202, movie: film(6), personName: "Renate Reinsve", isWinner: false),
            BallotNominee(id: 203, movie: film(7), personName: "Emma Stone", isWinner: false),
        ], displayMode: .person),
        BallotCategory(id: 3, name: "Animated Feature", pointsValue: 3, nominations: [
            BallotNominee(id: 301, movie: film(3), personName: nil, isWinner: false),
        ], displayMode: .film),
    ]

    /// The three categories above, then 21 more with the sample films as nominees.
    static let fullBallot: [BallotCategory] = categories + [
        "Director", "Actor in a Leading Role", "Actor in a Supporting Role", "Actress in a Supporting Role",
        "Original Screenplay", "Adapted Screenplay", "International Feature", "Documentary Feature",
        "Cinematography", "Film Editing", "Production Design", "Costume Design", "Makeup and Hairstyling",
        "Original Score", "Original Song", "Sound", "Visual Effects", "Casting", "Animated Short",
        "Live Action Short", "Documentary Short",
    ].enumerated().map { index, name in
        let id = index + 4
        let films = (0..<5).compactMap { film((id + $0 * 3) % movies.count + 1) }
        return BallotCategory(id: id, name: name, pointsValue: 1, nominations: films.enumerated().map { n, movie in
            BallotNominee(id: id * 100 + n + 1, movie: movie, personName: nil, isWinner: false)
        })
    }

    static func planItem(id: Int, movieID: Int, day: PlanDay) -> WatchPlanItem {
        var item = WatchPlanItem(id: id, userId: SampleDataSource.userID, movieId: movieID, plannedDate: day.description, createdAt: nil)
        item.movie = film(movieID)
        return item
    }

    /// Two open reports on the same person and one on a group, for the admin.
    static let reports: [ContentReport] = [
        ContentReport(id: 1, kind: .user, reason: .offensiveName, details: "Not something I want my kids to see.",
                      reportedName: "Chris", currentName: "Chris", reportedUserId: "u-chris", groupId: nil,
                      reporterName: "Sam", status: .open, createdAt: Date(timeIntervalSince1970: 1_792_900_000)),
        ContentReport(id: 2, kind: .user, reason: .harassment, details: nil,
                      reportedName: "Chris", currentName: "Chris", reportedUserId: "u-chris", groupId: nil,
                      reporterName: "Priya", status: .open, createdAt: Date(timeIntervalSince1970: 1_792_903_600)),
        ContentReport(id: 3, kind: .group, reason: .spam, details: nil,
                      reportedName: "Free tickets here", currentName: "Free tickets here", reportedUserId: nil, groupId: 7,
                      reporterName: "Jordan", status: .open, createdAt: Date(timeIntervalSince1970: 1_792_907_200)),
    ]

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

    func ranked(_ rank: Int) -> BoardEntry { withRank(rank) }
}
