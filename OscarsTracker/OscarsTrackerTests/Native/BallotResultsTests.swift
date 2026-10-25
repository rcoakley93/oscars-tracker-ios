import Foundation
import Testing
@testable import OscarsTracker

/// P6-05: who leads a category, the group's picks after the lock, and the
/// points each category earned.
@MainActor
@Suite("Ballot results")
struct BallotResultsTests {
    private let user = SampleDataSource.userID

    private func lockedData() -> SampleDataSource {
        let data = SampleDataSource()
        data.ceremony = Ceremony(id: 2, number: 99, name: "99th Academy Awards", ceremonyAt: .now,
                                 ballotLockAt: .now.addingTimeInterval(-60), isActive: true)
        return data
    }

    /// Signed in and loaded, without `start()`'s connectivity and push setup.
    private func signedIn(_ data: SampleDataSource) async -> AppModel {
        let model = AppModel(data: data)
        await model.session.restore()
        await model.refresh()
        return model
    }

    private func nominee(_ id: Int, person: String?, film: String) -> BallotNominee {
        BallotNominee(id: id, movie: MovieFactory.make(id: id, title: film), personName: person, isWinner: false)
    }

    // MARK: display_mode

    @Test func displayModeDecidesWhoLeads() {
        let nominees = [nominee(1, person: "Jessie Buckley", film: "Hamnet")]
        #expect(BallotCategory(id: 1, name: "Actress", pointsValue: 5, nominations: nominees, displayMode: .person).leadsWithPerson)
        // A film category whose nominees carry a detail (a song) still leads with the film.
        #expect(!BallotCategory(id: 2, name: "Original Song", pointsValue: 1, nominations: nominees, displayMode: .film).leadsWithPerson)
    }

    @Test func withoutDisplayModeAPersonStillLeads() {
        let acting = BallotCategory(id: 1, name: "Actress", pointsValue: 5, nominations: [nominee(1, person: "Emma Stone", film: "Bugonia")])
        let picture = BallotCategory(id: 2, name: "Best Picture", pointsValue: 10, nominations: [nominee(2, person: nil, film: "Hamnet")])
        #expect(acting.leadsWithPerson)
        #expect(!picture.leadsWithPerson)
    }

    @Test func categoryDecodesDisplayModeAndToleratesItsAbsence() throws {
        let decoder = JSONDecoder()
        let person = try decoder.decode(OscarsTracker.Category.self, from: Data(#"{"id":1,"name":"Actress","display_mode":"person"}"#.utf8))
        let missing = try decoder.decode(OscarsTracker.Category.self, from: Data(#"{"id":2,"name":"Best Picture"}"#.utf8))
        #expect(person.displayMode == .person)
        #expect(missing.displayMode == nil)
    }

    @Test func aCachedBallotFromBeforeDisplayModeStillDecodes() throws {
        let json = #"[{"id":1,"name":"Actress","pointsValue":5,"nominations":[]}]"#
        let categories = try JSONDecoder().decode([BallotCategory].self, from: Data(json.utf8))
        #expect(categories.first?.displayMode == nil)
    }

    @Test func titlesFollowTheCategory() {
        let song = nominee(1, person: "Golden", film: "KPop Demon Hunters")
        let filmFirst = BallotCategory(id: 1, name: "Original Song", pointsValue: 1, nominations: [song], displayMode: .film)
        let personFirst = BallotCategory(id: 2, name: "Actress", pointsValue: 5, nominations: [song], displayMode: .person)
        #expect(song.title(in: filmFirst) == "KPop Demon Hunters")
        #expect(song.detail(in: filmFirst) == "Golden")
        #expect(song.title(in: personFirst) == "Golden")
        #expect(song.spokenName(in: personFirst) == "Golden, in KPop Demon Hunters")
    }

    // MARK: Points per category

    @Test func eachCategoryShowsThePointsItEarned() async {
        let data = lockedData()
        // The first nominee wins everywhere: Best Picture's pick (103) is
        // wrong, Actress's (201) right, Animated Feature has no pick.
        data.categories = data.categories.map { category in
            BallotCategory(id: category.id, name: category.name, pointsValue: category.pointsValue,
                           nominations: category.nominations.enumerated().map { index, nominee in
                               BallotNominee(id: nominee.id, movie: nominee.movie, personName: nominee.personName, isWinner: index == 0)
                           }, displayMode: category.displayMode)
        }
        let store = BallotStore(data: data)
        await store.load(userID: user)
        #expect(store.categories.map(store.points(for:)) == [0, 5, nil])
        #expect(store.score == 5)
    }

    @Test func noPointsBeforeTheWinners() async {
        let store = BallotStore(data: lockedData())
        await store.load(userID: user)
        #expect(store.categories.allSatisfy { store.points(for: $0) == nil })
    }

    // MARK: Group pick shares

    @Test func noSharesBeforeTheLock() async {
        let model = await signedIn(SampleDataSource())
        #expect(model.ballot.shares.isEmpty)
        #expect(model.ballot.sharesGroup == nil)
        #expect(model.ballot.categories.allSatisfy { model.ballot.topShare(for: $0) == nil })
    }

    @Test func afterTheLockYourFirstGroupsFavouriteShows() async throws {
        let model = await signedIn(lockedData())
        #expect(model.ballot.sharesGroup?.name == "Movies LLC")
        // Six members split 3, 2, 1, starting from the second nominee in Best Picture.
        let picture = try #require(model.ballot.categories.first { $0.id == 1 })
        let top = try #require(model.ballot.topShare(for: picture))
        #expect(top.nominee.id == 102)
        #expect(top.percent == 50)
    }

    @Test func choosingAnotherGroupReloadsItsShares() async {
        let model = await signedIn(lockedData())
        model.navigation.ballotGroupID = 2
        await model.loadPickShares()
        #expect(model.ballot.sharesGroup?.name == "Family pool")
    }

    @Test func aGroupYoureNotInShowsNothingAndRaisesNoError() async {
        let store = BallotStore(data: lockedData())
        await store.load(userID: user)
        await store.loadShares(ceremonyID: 2, group: PoolGroup(id: 99, name: "Strangers", createdBy: "x", inviteCode: "NOPE00", createdAt: nil))
        #expect(store.shares.isEmpty)
        #expect(store.sharesGroup == nil)
        #expect(store.actionError == nil)
    }

    @Test func aSlowerAnswerForTheOldGroupNeverReplacesTheNewOne() async {
        let data = lockedData()
        data.shareDelays = [1: .milliseconds(200)]
        let store = BallotStore(data: data)
        await store.load(userID: user)
        let first = Task { await store.loadShares(ceremonyID: 2, group: data.groups[0]) }
        await Task.yield()
        await store.loadShares(ceremonyID: 2, group: data.groups[1])
        await first.value
        #expect(store.sharesGroup?.name == "Family pool")
    }

    @Test func clearingDropsAnAnswerStillOnItsWay() async {
        let data = lockedData()
        data.shareDelays = [1: .milliseconds(200)]
        let store = BallotStore(data: data)
        await store.load(userID: user)
        let load = Task { await store.loadShares(ceremonyID: 2, group: data.groups[0]) }
        await Task.yield()
        store.clearShares()
        await load.value
        #expect(store.sharesGroup == nil)
        #expect(store.shares.isEmpty)
    }

    @Test func leavingTheShownGroupMovesTheBallotToTheNextOne() async {
        let model = await signedIn(lockedData())
        #expect(model.ballot.sharesGroup?.id == 1)
        await model.groups.leave(1, userID: user)
        #expect(model.ballotGroup?.id == 2)
        // BallotTab reloads on this change (`.task(id: ballotGroup?.id)`).
        await model.loadPickShares()
        #expect(model.ballot.sharesGroup?.name == "Family pool")
    }

    @Test func aTieGoesToTheNomineeListedFirst() async throws {
        let data = lockedData()
        data.shareRows = [
            PickShare(categoryId: 1, nominationId: 104, memberCount: 4, pickCount: 2),
            PickShare(categoryId: 1, nominationId: 102, memberCount: 4, pickCount: 2),
        ]
        let store = BallotStore(data: data)
        await store.load(userID: user)
        await store.loadShares(ceremonyID: 2, group: data.groups[0])
        let top = try #require(store.topShare(for: store.categories[0]))
        #expect(top.nominee.id == 102)
        #expect(top.percent == 50)
    }

    @Test func sharesRoundToAWholePercent() {
        #expect(PickShare(categoryId: 1, nominationId: 1, memberCount: 3, pickCount: 2).percent == 67)
        #expect(PickShare(categoryId: 1, nominationId: 1, memberCount: 0, pickCount: 0).percent == 0)
    }

    @Test func bothVoicesNameTheShareTheGroupAndTheNominee() {
        for voice in Voice.allCases {
            let line = Copy.for(voice).groupPicked(62, "Movies LLC", "Hamnet")
            #expect(line.contains("62%"))
            #expect(line.contains("Movies LLC"))
            #expect(line.contains("Hamnet"))
        }
    }
}
