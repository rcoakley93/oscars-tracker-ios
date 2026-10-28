import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Board")
struct BoardTests {
    private let user = SampleDataSource.userID

    @Test func standingNamesThePersonAboveAndTheGap() async throws {
        let store = LeaderboardStore(data: SampleDataSource())
        #expect(store.standing(in: 1, userID: user) == nil)
        await store.load(ceremonyID: 2, groupID: 1)
        let standing = try #require(store.standing(in: 1, userID: user))
        #expect(standing.rank == 2)
        #expect(standing.size == 6)
        #expect(standing.position == .behind("Sam", by: 2))
    }

    @Test func standingKnowsTheLeaderAndTies() async {
        let data = SampleDataSource()
        data.board = [.sample(user, "filmbuff", watched: 31, rank: 1), .sample("u-sam", "Sam", watched: 20, rank: 2)]
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 2, groupID: nil)
        #expect(store.standing(in: nil, userID: user)?.position == .first)

        data.board[1] = .sample("u-sam", "Sam", watched: 31, rank: 1)
        await store.load(ceremonyID: 2, groupID: nil)
        #expect(store.standing(in: nil, userID: user)?.position == .tied(with: "Sam"))
    }

    @Test func boardsAreKeptPerGroup() async {
        let store = LeaderboardStore(data: SampleDataSource())
        await store.load(ceremonyID: 2, groupID: nil)
        await store.load(ceremonyID: 2, groupID: 2)
        #expect(store.entries(nil).count == 6)
        #expect(store.entries(2).map(\.userId) == [user])
        #expect(store.state(1) == .idle)
    }

    @Test func aFailedLoadKeepsTheLastBoard() async {
        let data = SampleDataSource()
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 2, groupID: nil)
        data.failure = .offline
        await store.load(ceremonyID: 2, groupID: nil)
        #expect(store.entries(nil).count == 6)
        #expect(store.state(nil) == .failed(.offline))
    }

    @Test func predictionsKeepTheServersRank() {
        let board: [BoardEntry] = [
            .sample(user, "filmbuff", watched: 20, rank: 1, score: 9),
            .sample("u-sam", "Sam", watched: 31, rank: 2, score: 7),
            .sample("u-jo", "Jo", watched: 31, rank: 2, score: 7),
        ]
        #expect(LeaderboardStore.ranked(board, by: .predictions).map(\.rank) == [1, 2, 2])
        // After winners, films watched are re-ranked by films, ties sharing a rank.
        let films = LeaderboardStore.ranked(board, by: .films)
        #expect(films.map(\.entry.username) == ["Sam", "Jo", "filmbuff"])
        #expect(films.map(\.rank) == [1, 1, 3])
    }

    @Test func beforeWinnersFilmsUseTheServersRank() {
        let board: [BoardEntry] = [.sample("u-sam", "Sam", watched: 31, rank: 1), .sample(user, "filmbuff", watched: 31, rank: 2)]
        #expect(LeaderboardStore.ranked(board, by: .films).map(\.rank) == [1, 2])
    }

    @Test func predictionGapCountsPoints() async {
        let data = SampleDataSource()
        data.board = [.sample("u-sam", "Sam", watched: 10, rank: 1, score: 12), .sample(user, "filmbuff", watched: 30, rank: 2, score: 9)]
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 2, groupID: nil)
        #expect(store.standing(in: nil, userID: user, metric: .predictions)?.position == .behind("Sam", by: 3))
        #expect(store.standing(in: nil, userID: user, metric: .films)?.position == .first)
    }

    @Test func aPersonOutsideYourGroupsShowsCountsOnly() async {
        let store = LeaderboardStore(data: SampleDataSource())
        await store.load(ceremonyID: 2, groupID: nil)
        await store.loadPerson("u-sam")
        await store.loadPerson("nobody")
        #expect(store.people["u-sam"]??.watchedMovieIDs.count == min(31, SampleData.movies.count))
        #expect(store.people["nobody"] == .some(nil))
    }

    @Test func decodesTheRPCRow() throws {
        let json = #"[{"rank":1,"user_id":"u","username":"Sam","avatar_url":null,"watched_count":31,"correct_count":3,"points":12,"score":12,"scoring":"weighted","is_creator":true}]"#
        let rows = try JSONDecoder().decode([BoardEntry].self, from: Data(json.utf8))
        #expect(rows.first?.scoring == .weighted)
        #expect(rows.first?.score == 12)
        let person = BoardPerson(rows: try JSONDecoder().decode([BoardPerson.Row].self, from: Data(#"[{"movie_id":4,"category_id":null,"nomination_id":null},{"movie_id":null,"category_id":1,"nomination_id":103}]"#.utf8)))
        #expect(person == BoardPerson(watchedMovieIDs: [4], picks: [1: 103]))
    }

    @Test func bothVoicesHaveTheBoardLines() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(copy.scoreGap(1, "Sam").contains("1 point behind Sam"))
            #expect(copy.scoreGap(3, "Sam").contains("3 points behind Sam"))
            #expect(!copy.boardAlone.isEmpty && !copy.boardPredictionsLocked.isEmpty)
        }
    }
}

@MainActor
@Suite("Group comparison")
struct GroupComparisonTests {
    private let user = SampleDataSource.userID

    private func standing(_ board: [BoardEntry]) async -> LeaderboardStore.Standing? {
        let data = SampleDataSource()
        data.board = board
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 2, groupID: 1)
        return store.standing(in: 1, userID: user)
    }

    @Test func namesThePersonsAboveAndBelow() async throws {
        let s = try #require(await standing([.sample("u-sam", "Sam", watched: 12, rank: 1),
                                             .sample(user, "filmbuff", watched: 10, rank: 2),
                                             .sample("u-jo", "Jo", watched: 9, rank: 3),
                                             .sample("u-al", "Al", watched: 3, rank: 4)]))
        #expect(s.position == .behind("Sam", by: 2))
        #expect(s.chaser == .init(name: "Jo", by: 1))
    }

    @Test func firstPlaceHasNoOneAbove() async throws {
        let s = try #require(await standing([.sample(user, "filmbuff", watched: 10, rank: 1), .sample("u-jo", "Jo", watched: 4, rank: 2)]))
        #expect(s.position == .first)
        #expect(s.chaser == .init(name: "Jo", by: 6))
    }

    @Test func lastPlaceHasNoChaser() async throws {
        let s = try #require(await standing([.sample("u-sam", "Sam", watched: 12, rank: 1), .sample(user, "filmbuff", watched: 1, rank: 2)]))
        #expect(s.chaser == nil)
    }

    @Test func aTieIsNotAGap() async throws {
        let s = try #require(await standing([.sample("u-sam", "Sam", watched: 5, rank: 1), .sample(user, "filmbuff", watched: 5, rank: 1),
                                             .sample("u-jo", "Jo", watched: 2, rank: 3)]))
        #expect(s.position == .tied(with: "Sam"))
        #expect(s.chaser == .init(name: "Jo", by: 3))
    }

    @Test func linesFollowTheStandingInBothVoices() async throws {
        let s = await standing([.sample("u-sam", "Sam", watched: 12, rank: 1), .sample(user, "filmbuff", watched: 10, rank: 2),
                                .sample("u-jo", "Jo", watched: 9, rank: 3)])
        for copy in [Copy.classic, Copy.host] {
            let lines = GroupComparisonCard.lines(s, size: 3, copy: copy)
            #expect(lines.count == 2)
            #expect(lines[0].contains("Sam") && lines[1].contains("Jo"))
        }
        #expect(GroupComparisonCard.lines(s, size: 1, copy: .classic) == [Copy.classic.boardAlone])
        #expect(GroupComparisonCard.lines(nil, size: 0, copy: .host) == ["Checking the board"])
        #expect(Copy.classic.compareChaser(1, "Jo") == "Jo is 1 film behind you.")
    }
}

@MainActor
@Suite("Group limits")
struct GroupLimitTests {
    @Test func theSampleSourceFollowsTheConfiguredGroupLimit() async throws {
        let data = SampleDataSource()
        #expect(AppConfig.defaults.groupMemberLimit == 50 && AppConfig.defaults.userGroupLimit == 5)
        data.config.userGroupLimit = 2
        await #expect(throws: AppError.tooManyGroups(limit: 2)) {
            _ = try await data.createGroup(name: "Third", userID: SampleDataSource.userID)
        }
    }
}

@Suite("Saved config")
struct SavedConfigTests {
    @Test func aConfigSavedBeforeTheGroupLimitsStillDecodes() throws {
        let old = #"{"minSupportedBuild":7,"featureFlags":{"live_mode":true},"runtimeBuckets":[]}"#
        let config = try JSONDecoder().decode(AppConfig.self, from: Data(old.utf8))
        #expect(config.minSupportedBuild == 7)
        #expect(config.groupMemberLimit == 50 && config.userGroupLimit == 5)
    }
}

@MainActor
@Suite("Season board")
struct SeasonBoardTests {
    private let user = SampleDataSource.userID

    @Test(arguments: [ListStage.predicted, .shortlisted])
    func beforeNominationsTheBoardCountsContendersWithNoPicks(stage: ListStage) async throws {
        let data = SampleDataSource()
        data.useListStage(stage)
        // Last season's ceremony is still active and long locked.
        data.ceremony = Ceremony(id: 1, number: 98, name: "98th Academy Awards", ceremonyAt: .now.addingTimeInterval(-86_400 * 200),
                                 ballotLockAt: .now.addingTimeInterval(-86_400 * 201), isActive: true)
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 1, groupID: nil)
        await store.load(ceremonyID: 1, groupID: 1)
        #expect(store.entries(nil).allSatisfy { $0.listStage == stage && $0.score == 0 })
        #expect(!store.countsPicks(nil) && !store.countsPicks(1))
        await store.loadPerson("u-sam")
        let sam = try #require(store.people["u-sam"] ?? nil)
        #expect(sam.picks.isEmpty && !sam.watchedMovieIDs.isEmpty)
    }

    @Test func fromNominationsDayPicksCount() async {
        let data = SampleDataSource()
        data.useListStage(.nominated)
        let store = LeaderboardStore(data: data)
        await store.load(ceremonyID: 2, groupID: nil)
        #expect(store.entries(nil).allSatisfy { $0.listStage == .nominated })
        #expect(store.countsPicks(nil))
    }

    @Test func theRowDecodesTheStageAndACopyWithoutOneCountsPicks() throws {
        let row = #"{"rank":1,"user_id":"u","username":"u","avatar_url":null,"watched_count":3,"correct_count":0,"points":0,"score":0,"scoring":"traditional","is_creator":false%@}"#
        let season = try JSONDecoder().decode(BoardEntry.self, from: Data(row.replacingOccurrences(of: "%@", with: #","list_stage":"shortlisted""#).utf8))
        #expect(season.listStage == .shortlisted && !season.countsPicks)
        let cached = try JSONDecoder().decode(BoardEntry.self, from: Data(row.replacingOccurrences(of: "%@", with: "").utf8))
        #expect(cached.listStage == nil && cached.countsPicks)
    }

    @Test func anUnloadedBoardCountsPicks() {
        #expect(LeaderboardStore(data: SampleDataSource()).countsPicks(nil))
    }
}
