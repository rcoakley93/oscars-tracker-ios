import Foundation
import Testing
@testable import OscarsTracker

/// The ceremony-night Live Activity (P6-03). Sample ballot: Best Picture
/// (1: 101–105, you picked 103, 10 points), Actress (2: 201–203, you picked
/// 201, 5 points), Animated Feature (3: 301, no pick, 3 points).
@MainActor
@Suite("Live Activity")
struct LiveActivityTests {
    private typealias State = CeremonyActivityAttributes.ContentState

    private let picks = [1: 103, 2: 201]

    private func categories(winners: [Int: Set<Int>]) -> [BallotCategory] {
        SampleData.categories.map { category in winners[category.id].map(category.withWinners) ?? category }
    }

    private func entry(_ userID: String, rank: Int, scoring: BoardEntry.Scoring = .traditional) -> BoardEntry {
        BoardEntry(rank: rank, userId: userID, username: "u\(rank)", avatarUrl: nil, watchedCount: 0, correctCount: 0,
                   points: 0, score: 0, scoring: scoring, isCreator: false)
    }

    // MARK: - Content

    @Test func beforeTheFirstWinnerItWaits() {
        let state = LiveActivityStore.state(categories: SampleData.categories, picks: picks, latestCategoryID: nil,
                                            board: [], userID: SampleDataSource.userID)
        #expect(state == State(decided: 0, total: 3, score: 0))
        #expect(LiveActivityCopy(voice: "classic").progressLine(state) == "0 of 3 announced")
    }

    @Test func actingWinnersLeadWithThePersonAndShowTheFilm() {
        let state = LiveActivityStore.state(categories: categories(winners: [2: [201]]), picks: picks, latestCategoryID: 2,
                                            board: [], userID: SampleDataSource.userID)
        #expect(state.category == "Actress in a Leading Role")
        #expect(state.winner == "Jessie Buckley")
        #expect(state.detail == SampleData.film(1)?.title)
        #expect(state.outcome == .correct)
        #expect(state.decided == 1)
        #expect(state.score == 1)
    }

    @Test func theLatestWinnerIsTheOneLiveModeLastHeard() {
        let both = categories(winners: [1: [101], 2: [201]])
        let latest = LiveActivityStore.state(categories: both, picks: picks, latestCategoryID: 1, board: [], userID: SampleDataSource.userID)
        #expect(latest.category == "Best Picture")
        #expect(latest.outcome == .wrong)
        #expect(latest.detail == nil)
        // Without one (a cold start), the last decided category in ballot order.
        let fallback = LiveActivityStore.state(categories: both, picks: picks, latestCategoryID: nil, board: [], userID: SampleDataSource.userID)
        #expect(fallback.category == "Actress in a Leading Role")
    }

    @Test func noPickHasNoOutcome() {
        let state = LiveActivityStore.state(categories: categories(winners: [3: [301]]), picks: picks, latestCategoryID: 3,
                                            board: [], userID: SampleDataSource.userID)
        #expect(state.outcome == nil)
        #expect(LiveActivityCopy(voice: "host").outcome(state.outcome) == nil)
    }

    @Test func theScoreFollowsTheGlobalBoardsRuleAndTheRankComesFromIt() {
        let winners = categories(winners: [1: [103], 2: [201]])
        let me = SampleDataSource.userID
        let traditional = LiveActivityStore.state(categories: winners, picks: picks, latestCategoryID: 1,
                                                  board: [entry("other", rank: 1), entry(me, rank: 2)], userID: me)
        #expect(traditional.score == 2)
        #expect(traditional.rank == 2)
        #expect(traditional.players == 2)
        let weighted = LiveActivityStore.state(categories: winners, picks: picks, latestCategoryID: 1,
                                               board: [entry(me, rank: 1, scoring: .weighted)], userID: me)
        #expect(weighted.score == 15)
        // Not on the board yet: no place.
        let absent = LiveActivityStore.state(categories: winners, picks: picks, latestCategoryID: 1, board: [entry("other", rank: 1)], userID: me)
        #expect(absent.rank == nil)
        #expect(absent.players == nil)
    }

    // MARK: - Copy

    @Test func compactFormsStayShort() {
        #expect(LiveActivityCopy.progress(.previewCalled) == "12/23")
    }

    @Test func placesReadAsOrdinals() {
        let places = [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111, 112].map { OrdinalStyle().format($0) }
        #expect(places == ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd", "23rd", "101st", "111th", "112th"])
        #expect(LiveActivityCopy(voice: "classic").rank(.previewCalled) == "3rd of 212")
        #expect(LiveActivityCopy(voice: "classic").rank(.previewWaiting) == nil)
    }

    @Test func bothVoicesSayWhetherYouCalledIt() {
        let classic = LiveActivityCopy(voice: "classic")
        let host = LiveActivityCopy(voice: "host")
        #expect(classic.outcome(.correct) == "You called it")
        #expect(classic.outcome(.wrong) == "Not this time")
        #expect(host.outcome(.correct)?.hasPrefix("You called it") == true)
        #expect(host.outcome(.wrong)?.hasPrefix("Not this time") == true)
        #expect(classic.progressLine(.previewFinal) == "All winners announced")
        #expect(classic.score(1) == "1 point")
        #expect(classic.score(9) == "9 points")
    }

    // MARK: - The server's contract

    /// send-push writes these keys for updates and push-to-start; they must
    /// decode, or the system drops the push.
    @Test func theServersPayloadDecodes() throws {
        let json = """
        {"category":"Best Picture","winner":"Hamnet","detail":null,"outcome":"correct",
         "decided":23,"total":23,"score":17,"rank":2,"players":212}
        """
        let state = try JSONDecoder().decode(State.self, from: Data(json.utf8))
        #expect(state == State(category: "Best Picture", winner: "Hamnet", outcome: .correct, decided: 23, total: 23,
                               score: 17, rank: 2, players: 212))
        #expect(state.isFinished)

        let waiting = try JSONDecoder().decode(State.self, from: Data(#"{"decided":0,"total":24,"score":0}"#.utf8))
        #expect(waiting == State(decided: 0, total: 24, score: 0))

        let attributes = try JSONDecoder().decode(CeremonyActivityAttributes.self,
                                                  from: Data(#"{"ceremonyID":7,"ceremonyName":"99th Academy Awards","voice":"classic"}"#.utf8))
        #expect(attributes.ceremonyID == 7)
        #expect(attributes.voice == "classic")
    }

    // MARK: - Following

    @Test func theButtonNeedsTheFlagAndPermission() {
        let data = SampleDataSource()
        var on = AppConfig.defaults
        on.featureFlags[AppConfig.liveActivity] = true
        #expect(!LiveActivityStore(data: data, activitiesEnabled: { true }).canFollow(config: .defaults))
        #expect(LiveActivityStore(data: data, activitiesEnabled: { true }).canFollow(config: on))
        #expect(!LiveActivityStore(data: data, activitiesEnabled: { false }).canFollow(config: on))
    }

    @Test func followingWithLiveActivitiesOffSaysSo() async {
        let store = LiveActivityStore(data: SampleDataSource(), activitiesEnabled: { false })
        let ceremony = Ceremony(id: 1, number: 99, name: "99th Academy Awards", ceremonyAt: .now, ballotLockAt: .now, isActive: true)
        await store.follow(ceremony: ceremony, voice: .host, state: .previewWaiting)
        #expect(store.actionError == .liveActivitiesOff)
        #expect(!store.isFollowing)
    }

    @Test func liveModeRemembersTheLatestWinner() async {
        let data = SampleDataSource()
        let ballot = BallotStore(data: data)
        await ballot.load(userID: SampleDataSource.userID)
        let live = LiveStore(data: data, ballot: ballot, settleDelay: .zero)
        live.start()
        live.receive(WinnerUpdate(nominationID: 201, categoryID: 2, isWinner: true))
        live.settle()
        live.receive(WinnerUpdate(nominationID: 301, categoryID: 3, isWinner: true))
        live.settle()
        #expect(live.latestCategoryID == 3)
        live.stop()
        #expect(live.latestCategoryID == nil)
    }

    @Test func aColdStartKeepsThePushedWinner() {
        let pushed = State.previewCalled
        let figures = State(category: "Animated Feature", winner: "Elio", decided: 14, total: 23, score: 10, rank: 2, players: 212)
        let next = LiveActivityStore.keepingWinner(of: pushed, in: figures)
        #expect(next.category == pushed.category)
        #expect(next.winner == pushed.winner)
        #expect(next.outcome == pushed.outcome)
        #expect([next.decided, next.score, next.rank] == [14, 10, 2])
        // Nothing shown yet: the new state as it is.
        #expect(LiveActivityStore.keepingWinner(of: .previewWaiting, in: figures) == figures)
    }

    @Test func aTokenThatFailsToSendGoesAgain() async {
        let data = SampleDataSource()
        let store = LiveActivityStore(data: data, activitiesEnabled: { true })
        data.failure = .offline
        await store.register("ab", ceremonyID: 1)
        #expect(store.unsentTokens == [1: "ab"])
        #expect(store.actionError == nil)
        data.failure = .server("down")
        await store.sendUnsentTokens()
        #expect(store.actionError == .server("down"))
        data.failure = nil
        await store.sendUnsentTokens()
        #expect(store.unsentTokens.isEmpty)
        #expect(data.liveActivityTokens == [1: "ab"])
    }

    @Test func tokensReachTheServer() async throws {
        let data = SampleDataSource()
        try await data.registerLiveActivity(ceremonyID: 1, token: "ab", environment: .sandbox)
        #expect(data.liveActivityTokens == [1: "ab"])
        try await data.endLiveActivity(ceremonyID: 1)
        #expect(data.liveActivityTokens.isEmpty)
        #expect(data.endedLiveActivities == [1])
        try await data.registerLiveActivityStartToken("cd", environment: .production)
        #expect(data.liveActivityStartTokens == ["cd": .production])
        #expect(LiveActivityStore.hex(Data([0x0a, 0xff])) == "0aff")
    }
}
