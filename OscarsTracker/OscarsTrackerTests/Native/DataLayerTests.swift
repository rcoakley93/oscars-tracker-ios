import Foundation
import Testing
@testable import OscarsTracker

@Suite("Plan days and runtimes")
struct PlanDayTests {
    private let newYork: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    @Test func parsesAndFormatsDatabaseDays() {
        #expect(PlanDay("2027-03-14")?.description == "2027-03-14")
        #expect(PlanDay("2027-3-14")?.description == "2027-03-14")
        #expect(PlanDay("not a day") == nil)
        #expect(PlanDay("2027-13-01") == nil)
    }

    /// 9pm in New York is already tomorrow in UTC; the plan day must stay today.
    @Test func usesTheViewersTimeZone() throws {
        let evening = try #require(ISO8601DateFormatter().date(from: "2027-01-22T02:00:00Z"))
        #expect(PlanDay(evening, calendar: newYork).description == "2027-01-21")
    }

    @Test func countsDaysAcrossDaylightSavingTime() throws {
        let before = try #require(PlanDay("2027-03-13"))
        let after = try #require(PlanDay("2027-03-15"))
        #expect(before.days(until: after, calendar: newYork) == 2)
        #expect(before.adding(days: 1, calendar: newYork).description == "2027-03-14")
    }

    @Test func ordersDays() throws {
        #expect(try #require(PlanDay("2027-01-31")) < (try #require(PlanDay("2027-02-01"))))
    }

    @Test(arguments: [(nil, ""), (0, ""), (45, "45m"), (60, "1h"), (126, "2h 6m")] as [(Int?, String)])
    func formatsRuntimes(minutes: Int?, expected: String) {
        #expect(Runtime.format(minutes: minutes) == expected)
    }
}

@Suite("Friendly errors")
struct AppErrorTests {
    @Test(arguments: [
        ("Ballot is locked", AppError.ballotLocked),
        ("Invalid invite code", .invalidInviteCode),
        ("You are already a member of this group", .alreadyInGroup),
        ("You are the creator of this group", .ownGroup),
        ("Group has reached the maximum limit of 12 members", .groupFull(limit: 12)),
        ("User has reached the maximum limit of 5 groups", .tooManyGroups(limit: 5)),
        ("Not authenticated", .notSignedIn),
    ])
    func mapsServerMessages(message: String, expected: AppError) {
        #expect(AppError(serverMessage: message) == expected)
    }

    @Test func groupLimitsAreMatchedByCodeNotByNumber() {
        #expect(AppError(serverMessage: "Group has reached the maximum limit of 50 members", code: "GRP01", hint: "group_full") == .groupFull(limit: 50))
        #expect(AppError(serverMessage: "anything", code: "GRP02") == .tooManyGroups(limit: nil))
        #expect(AppError(serverMessage: "whatever", hint: "group_full") == .groupFull(limit: nil))
        #expect(AppError.groupFull(limit: 50).message == "That group is full (50 members).")
        #expect(AppError.tooManyGroups(limit: 8).message == "You're in 8 groups already, the most you can join.")
        #expect(!AppError.groupFull(limit: nil).message.contains("("))
    }

    @Test func mapsOfflineErrors() {
        #expect(AppError(URLError(.notConnectedToInternet)) == .offline)
    }

    @Test func keepsUnknownServerMessagesButShowsPlainText() {
        let error = AppError(serverMessage: "deadlock detected")
        #expect(error == .server("deadlock detected"))
        #expect(!error.message.contains("deadlock"))
    }

    @Test func passwordRulesMatchSupabase() {
        #expect(PasswordRules.isValid("Oscars2027"))
        #expect(!PasswordRules.isValid("oscars2027"))
        #expect(!PasswordRules.isValid("OSCARS2027"))
        #expect(!PasswordRules.isValid("Oscarsss"))
        #expect(!PasswordRules.isValid("Osc2027"))
    }
}

@MainActor
@Suite("Stores")
struct StoreTests {
    private let user = SampleDataSource.userID

    @Test func filmsListUnwatchedFirst() async {
        let store = FilmsStore(data: SampleDataSource())
        await store.load(userID: user)
        #expect(store.state == .loaded)
        #expect(store.toWatch.allSatisfy { !store.isWatched($0.id) })
        #expect(store.watched.map(\.id).sorted() == [1, 4, 7])
        #expect(store.toWatch.count + store.watched.count == store.movies.count)
    }

    @Test func togglingWatchedRollsBackWhenTheSaveFails() async {
        let data = SampleDataSource()
        let store = FilmsStore(data: data)
        await store.load(userID: user)
        data.failure = .offline
        await store.toggleWatched(2, userID: user)
        #expect(!store.isWatched(2))
        #expect(store.actionError == .offline)
    }

    @Test func togglingWatchedSaves() async {
        let data = SampleDataSource()
        let store = FilmsStore(data: data)
        await store.load(userID: user)
        await store.toggleWatched(2, userID: user)
        #expect(store.isWatched(2))
        #expect(data.watched.contains(2))
    }

    @Test func aLockedBallotSendsNothing() async {
        let data = SampleDataSource()
        let store = BallotStore(data: data)
        await store.load(userID: user)
        await store.choose(nominationID: 301, in: 3, userID: user, locked: true)
        #expect(store.pick(for: 3) == nil)
        #expect(store.actionError == .ballotLocked)
        #expect(data.savedPicks[3] == nil)
    }

    @Test func picksCountTowardCompletion() async {
        let store = BallotStore(data: SampleDataSource())
        await store.load(userID: user)
        #expect(store.pickedCount == 2)
        #expect(store.nextCategory?.id == 3)
        await store.choose(nominationID: 301, in: 3, userID: user, locked: false)
        #expect(store.isComplete)
    }

    @Test func outcomesAppearOnceAWinnerIsSet() async {
        let data = SampleDataSource()
        data.categories[0] = BallotCategory(id: 1, name: "Best Picture", pointsValue: 10, nominations: [
            BallotNominee(id: 101, movie: nil, personName: nil, isWinner: true),
            BallotNominee(id: 103, movie: nil, personName: nil, isWinner: false),
        ])
        let store = BallotStore(data: data)
        await store.load(userID: user)
        #expect(store.outcome(for: store.categories[0]) == .wrong)
        #expect(store.outcome(for: store.categories[1]) == nil)
    }

    @Test func actingCategoriesLeadWithThePerson() {
        #expect(SampleData.categories[1].leadsWithPerson)
        #expect(!SampleData.categories[0].leadsWithPerson)
    }

    @Test func upcomingDaysSkipPastPlans() async throws {
        let store = PlanStore(data: SampleDataSource())
        await store.load(userID: user)
        let today = PlanDay.today()
        #expect(store.upcomingDays(today: today).map(\.day) == [today, today.adding(days: 1)])
        #expect(store.pastDays(today: today).map(\.day) == [today.adding(days: -2)])
    }

    @Test func removingAPlanItemRollsBackOnFailure() async {
        let data = SampleDataSource()
        let store = PlanStore(data: data)
        await store.load(userID: user)
        data.failure = .server("boom")
        await store.remove(1)
        #expect(store.items.contains { $0.id == 1 })
        #expect(store.actionError == .server("boom"))
    }

    @Test func joiningWithABadCodeExplainsWhy() async {
        let store = GroupsStore(data: SampleDataSource())
        await store.load(userID: user)
        #expect(await store.join(code: "nope", userID: user) == nil)
        #expect(store.actionError == .invalidInviteCode)
        #expect(await store.join(code: " friend ", userID: user)?.groupName == "Film club")
        #expect(store.groups.contains { $0.name == "Film club" })
    }

    @Test func groupNamesAreValidatedBeforeSaving() async {
        let data = SampleDataSource()
        let store = GroupsStore(data: data)
        await store.load(userID: user)
        #expect(await store.create(name: "ab", userID: user) == nil)
        #expect(GroupsStore.nameProblem("ab") != nil)
        #expect(await store.create(name: "Office Oscars", userID: user)?.name == "Office Oscars")
    }

    @Test func newAccountsPickAUsernameFirst() async {
        let data = SampleDataSource()
        data.userProfile = Profile(id: user, username: nil, avatarUrl: nil, createdAt: nil, updatedAt: nil)
        let store = ProfileStore(data: data)
        await store.load(userID: user)
        #expect(store.needsUsername)
        #expect(await store.setUsername("cinephile", userID: user))
        #expect(!store.needsUsername)
    }

    @Test func signUpRejectsWeakPasswordsBeforeCallingTheServer() async {
        let data = SampleDataSource(signedIn: false)
        let session = SessionStore(data: data)
        #expect(await session.signUp(email: "a@b.co", password: "short") == nil)
        #expect(session.error == .weakPassword)
        #expect(!data.signedIn)
    }

    @Test func appleAndGoogleSignYouIn() async {
        let data = SampleDataSource(signedIn: false)
        let session = SessionStore(data: data)
        #expect(await session.signInWithApple(idToken: "token", nonce: "nonce"))
        #expect(session.userID == user)
        await session.signOut()
        #expect(await session.signInWithGoogle())
        #expect(session.userID == user)
    }

    @Test func closingTheSignInSheetShowsNoError() async {
        let data = SampleDataSource(signedIn: false)
        data.failure = .cancelled
        let session = SessionStore(data: data)
        #expect(await !session.signInWithGoogle())
        #expect(session.error == nil)
        #expect(session.state != .signedIn(userID: user))
    }

    @Test func aResetLinkAsksForANewPassword() async throws {
        let data = SampleDataSource(signedIn: false)
        let session = SessionStore(data: data)
        #expect(await session.sendPasswordReset(email: " a@b.co "))
        #expect(data.resetEmails == ["a@b.co"])

        #expect(await !session.open(try #require(URL(string: "https://example.com/reset-password"))))
        #expect(await session.open(try #require(URL(string: "oscarstracker://reset-password?code=abc"))))
        #expect(session.isChoosingNewPassword)
        #expect(await !session.chooseNewPassword("weak"))
        #expect(session.error == .weakPassword)
        #expect(await session.chooseNewPassword("Oscars2027"))
        #expect(!session.isChoosingNewPassword)
        #expect(data.newPassword == "Oscars2027")
    }

    @Test func appleNoncesAreRandomAndHashed() {
        let nonce = AppleNonce.make()
        #expect(nonce.count == 32)
        #expect(nonce != AppleNonce.make())
        #expect(AppleNonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func aFailedAccountDeletionKeepsYouSignedIn() async {
        let data = SampleDataSource()
        let model = AppModel(data: data)
        await model.start()
        data.failure = .server("fk violation")
        #expect(await !model.deleteAccount())
        #expect(model.session.userID == user)
        #expect(model.profile.actionError == .server("fk violation"))
    }

    @Test func deletingTheAccountSignsOutAndClearsData() async {
        let model = AppModel(data: SampleDataSource())
        await model.start()
        model.navigation.tab = .ballot
        #expect(await model.deleteAccount())
        #expect(model.session.state == .signedOut)
        #expect(model.films.movies.isEmpty)
        #expect(model.navigation.tab == .films)
    }

    @Test func theSeasonCountsDownInLocalDays() async {
        let store = SeasonStore(data: SampleDataSource())
        await store.load()
        #expect(store.daysToCeremony() == 33)
        #expect(!store.isBallotLocked())
    }
}
