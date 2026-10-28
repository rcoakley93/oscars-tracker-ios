import Foundation
import Testing
@testable import OscarsTracker

/// The contender list (P9-05). The stage moves on the server alone: these
/// tests change only the Sample source's flag and data, never the app.
@MainActor
@Suite("Contenders")
struct ContendersTests {
    private let user = SampleDataSource.userID

    private func model(_ stage: ListStage?, cache: OfflineCache = .none) async -> (AppModel, SampleDataSource) {
        let data = SampleDataSource()
        if let stage { data.useListStage(stage) }
        let model = AppModel(data: data, cache: cache)
        await model.start()
        return (model, data)
    }

    private var nominees: Set<Int> { Set(SampleData.categories.flatMap { $0.nominations.compactMap(\.movie?.id) }) }

    // MARK: - Predicted → shortlisted → nominated, by the server alone

    @Test func theListMovesThroughEveryStageWithOnlyTheFlagAndTheData() async {
        let data = SampleDataSource()
        data.config.listStage = .predicted
        data.contenderList = SampleData.contenders(.predicted)
        data.movieList += SampleData.contenderOnlyMovies
        data.announceNominations(false)
        let model = AppModel(data: data)
        await model.start()
        #expect(model.films.listStage == .predicted)
        #expect(Set(model.films.list.map(\.id)) == Set(SampleData.contenders(.predicted).map(\.movieId)))
        #expect(!model.films.hasNominees)
        await model.films.toggleWatched(11, userID: user)

        // Dec 15: the shortlists load and the flag flips.
        data.config.listStage = .shortlisted
        data.contenderList = SampleData.contenders(.shortlisted)
        await model.refresh()
        #expect(model.films.listStage == .shortlisted)
        #expect(model.films.contending(8).first?.stage == .shortlisted)
        #expect(model.films.isWatched(11))

        // Jan 21: the flag flips and the nominations are announced.
        data.config.listStage = .nominated
        data.announceNominations(true)
        await model.refresh()
        #expect(model.films.listStage == .nominated)
        #expect(model.films.hasNominees)
        #expect(Set(model.films.list.map(\.id)) == nominees)
        // 11 was a contender, never a nominee: still watched, no longer counted.
        #expect(model.films.isWatched(11))
        #expect(model.films.watchedCount == 3)
        #expect(model.films.toWatch.count == nominees.count - 3)
        #expect(model.films.odds(for: 1) == nil)
    }

    @Test func theFlagAloneDoesntShowNomineesBeforeTheyreAnnounced() async {
        let (model, data) = await model(.shortlisted)
        data.config.listStage = .nominated
        await model.refresh()
        // The 99th's categories are still hidden: the contenders stay, as they stand.
        #expect(model.films.listStage == .shortlisted)
        #expect(model.films.list.contains { $0.id == 11 })
        #expect(!model.films.hasNominees)
    }

    @Test func anotherCeremonysNomineesNeverReplaceTheContenders() async {
        // The 98th is still the active ceremony: its nominees are on the ballot.
        let (model, data) = await model(.predicted)
        data.ceremony = Ceremony(id: 1, number: 98, name: "98th Academy Awards", ceremonyAt: data.ceremony.ceremonyAt,
                                 ballotLockAt: data.ceremony.ballotLockAt, isActive: true)
        data.config.listStage = .nominated
        data.announceNominations(true)
        await model.refresh()
        #expect(model.films.listStage != .nominated)
        #expect(model.films.list.contains { $0.id == 11 })
    }

    @Test func aContenderFlagWithNoContendersKeepsTheNominees() async {
        let data = SampleDataSource()
        data.config.listStage = .predicted
        let model = AppModel(data: data)
        await model.start()
        #expect(model.films.listStage == .nominated)
        #expect(Set(model.films.list.map(\.id)) == nominees)
        #expect(model.films.hasNominees)
    }

    @Test func aFailedBallotKeepsAValidList() async {
        // Nominations are out, but the ballot hasn't loaded: the contenders
        // stay, rather than every contender dropping off.
        let data = SampleDataSource()
        data.useListStage(.nominated)
        let model = AppModel(data: data)
        model.films.stage = .nominated
        await model.films.load(userID: user)
        #expect(model.ballot.categories.isEmpty)
        #expect(model.films.listStage == .shortlisted)
        #expect(Set(model.films.list.map(\.id)) == Set(SampleData.contenders(.shortlisted).map(\.movieId)))
        // With no contenders either: every film, as 2.0 showed.
        data.contenderList = []
        await model.films.load(userID: user)
        #expect(model.films.list.count == data.movieList.count)
    }

    @Test func aStageChangeWhileAwayReloadsTheListOnReturn() async {
        let (model, data) = await model(.predicted)
        data.useListStage(.nominated)
        await model.foreground()
        #expect(model.films.listStage == .nominated)
        #expect(Set(model.films.list.map(\.id)) == nominees)
    }

    @Test func nomineesAnnouncedAfterTheFlagArriveOnTheNextReturn() async {
        let (model, data) = await model(.shortlisted)
        data.config.listStage = .nominated
        await model.foreground()
        #expect(model.films.awaitsNominees)
        #expect(model.films.listStage == .shortlisted)

        // Later the nominations are announced; the flag doesn't change again.
        data.announceNominations(true)
        await model.foreground()
        #expect(!model.films.awaitsNominees)
        #expect(model.films.listStage == .nominated)
        #expect(Set(model.films.list.map(\.id)) == nominees)
    }

    @Test func theCategoryFilterFollowsTheStage() async {
        let (model, data) = await model(.predicted)
        #expect(model.films.listCategories.map(\.name).contains("Sound"))
        #expect(model.films.movieIDs(in: 19) == [2, 4, 5, 11])

        data.useListStage(.nominated)
        await model.refresh()
        #expect(model.films.listCategories.map(\.id) == SampleData.categories.map(\.id))
        #expect(model.films.movieIDs(in: 3) == [3])
    }

    // MARK: - Odds

    @Test func aFilmShowsItsBestOddsOrItsOddsInACategory() async {
        let (model, _) = await model(.predicted)
        #expect(model.films.odds(for: 4) == 0.88)
        #expect(model.films.odds(for: 4, in: 19) == 0.74)
        #expect(model.films.odds(for: 4, in: 2) == nil)
        #expect(model.films.contending(6).map(\.categoryId) == [10, 2, 1])
    }

    @Test func oddsAreABarePercentNeverCertain() {
        #expect(Contender.percent(0.724) == 72)
        #expect(Contender.percent(1) == 99)
        #expect(Contender.percent(0) == 1)
        #expect(Copy.odds(72) == "72%")
        #expect(Copy.oddsSpoken(72) == "72% to be nominated")
    }

    @Test func theOddsSortIsMostLikelyFirstAndKeepsTitleOrderOnTies() {
        let movies = SampleData.movies.sorted { $0.title < $1.title }
        let odds: [Int: Double] = [1: 0.5, 2: 0.9, 3: 0.5]
        let sorted = FilmsTab.Sort.odds.sorted(movies) { odds[$0] }
        // Frankenstein, then Hamnet and KPop Demon Hunters by title, then the rest.
        #expect(Array(sorted.prefix(3).map(\.id)) == [2, 1, 3])
        #expect(sorted.count == movies.count)
    }

    @Test func theOddsSortIsOnlyOfferedWithOdds() {
        #expect(FilmsTab.Sort.available(in: .predicted).contains(.odds))
        #expect(!FilmsTab.Sort.available(in: .nominated).contains(.odds))
        #expect(FilmsTab.Sort.odds.resolved(in: .nominated) == .shortest)
        #expect(FilmsTab.Sort.odds.resolved(in: .shortlisted) == .odds)
    }

    // MARK: - Copy

    @Test func everyStageHasItsLinesInBothVoices() {
        for copy in [Copy.host, Copy.classic] {
            for stage in ListStage.allCases {
                #expect(copy.tickerBeforeNominations("Jan 21", 12, stage).contains("12 contenders"))
                #expect(copy.heroTeaser(1, "Jan 21", stage).contains("1 contender"))
                #expect(copy.heroTeaser(5, "Jan 21", stage).contains("Jan 21"))
            }
        }
        #expect(Copy.classic.tickerBeforeNominations("Jan 21", nil, .predicted) == "Nominations announced Jan 21.")
    }

    // MARK: - Config and offline

    @Test func aConfigCachedBefore21ReadsAsNominated() throws {
        let old = #"{"minSupportedBuild":0,"featureFlags":{"live_mode":false},"runtimeBuckets":[]}"#
        let config = try JSONDecoder().decode(AppConfig.self, from: Data(old.utf8))
        #expect(config.listStage == .nominated)
        var predicted = AppConfig.defaults
        predicted.listStage = .predicted
        let round = try JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(predicted))
        #expect(round.listStage == .predicted)
    }

    @Test func theOfflineCopyFollowsTheStage() async {
        let cache = OfflineCache(directory: FileManager.default.temporaryDirectory.appending(path: "offline-\(UUID().uuidString)"))
        let (first, data) = await model(.predicted, cache: cache)
        #expect(cache.snapshot(for: user)?.listStage == .predicted)
        #expect(cache.snapshot(for: user)?.contenders?.count == data.contenderList.count)

        data.useListStage(.nominated)
        await first.refresh()
        #expect(cache.snapshot(for: user)?.listStage == .nominated)

        // Offline relaunch with no season: the copy's stage, not the old one.
        data.failure = .offline
        let second = AppModel(data: data, cache: cache)
        await second.start()
        #expect(second.films.listStage == .nominated)
        #expect(Set(second.films.list.map(\.id)) == nominees)
    }

    @Test func aSnapshotSavedBefore21StillOpens() throws {
        let old = #"{"movies":[],"watchedIDs":[],"categories":[],"picks":{},"plan":[],"groups":[],"boards":{},"savedAt":0}"#
        let snapshot = try JSONDecoder().decode(OfflineSnapshot.self, from: Data(old.utf8))
        #expect(snapshot.contenders == nil)
        #expect(snapshot.listStage == nil)
    }

    @Test func contendersDecodeFromTheRPC() throws {
        let json = #"""
        [{"id":1,"ceremony_id":2,"category_id":1,"category_name":"Best Picture","display_mode":"film","movie_id":7,
          "detail_text":null,"stage":"predicted","odds":0.724,"source":"Next Best Picture","source_updated_at":"2026-10-27T12:00:00Z"}]
        """#
        let rows = try JSONDecoder().decode([Contender].self, from: Data(json.utf8))
        #expect(rows.first?.percent == 72)
        #expect(rows.first?.ceremonyId == 2)
    }
}
