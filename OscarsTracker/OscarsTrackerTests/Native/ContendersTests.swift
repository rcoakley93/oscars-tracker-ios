import Foundation
import Testing
@testable import OscarsTracker

/// The contender list (P9-05): the list for each `list_stage`, our odds, the
/// odds sort, the credit, and the offline copy.
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

    // MARK: - The stage switch

    @Test func predictedShowsTheContendersAndNotTheNominees() async {
        let (model, _) = await model(.predicted)
        let ids = Set(model.films.list.map(\.id))
        #expect(model.films.listStage == .predicted)
        #expect(ids == Set(SampleData.contenders(.predicted).map(\.movieId)))
        #expect(ids.contains(11) && ids.contains(12))
        // Before nominations: the season stays "before nominations".
        #expect(!model.films.hasNominees)
        #expect(model.films.watchedCount == 3)
    }

    @Test func theSwitchKeepsWatchedFilmsAndCountsTheCurrentList() async {
        let (model, data) = await model(.predicted)
        await model.films.toggleWatched(11, userID: user)
        #expect(model.films.watchedCount == 4)

        data.useListStage(.shortlisted)
        await model.refresh()
        #expect(model.films.listStage == .shortlisted)
        #expect(model.films.contending(8).first?.stage == .shortlisted)
        #expect(model.films.watchedCount == 4)

        data.useListStage(.nominated)
        await model.refresh()
        #expect(model.films.listStage == .nominated)
        #expect(model.films.hasNominees)
        // 11 was a contender, never a nominee: still watched, no longer counted.
        #expect(model.films.isWatched(11))
        // The contenders that weren't nominated drop off: the list is the ballot's films.
        let nominees = Set(SampleData.categories.flatMap { $0.nominations.compactMap(\.movie?.id) })
        #expect(Set(model.films.list.map(\.id)) == nominees)
        #expect(model.films.watchedCount == 3)
        #expect(model.films.toWatch.count == nominees.count - 3)
        #expect(model.films.odds(for: 1) == nil)
        #expect(model.films.credit == nil)
    }

    @Test func aContenderFlagWithNoContendersKeepsTheNominees() async {
        let data = SampleDataSource()
        data.config.listStage = .predicted
        let model = AppModel(data: data)
        await model.start()
        #expect(model.films.listStage == .nominated)
        #expect(model.films.list.count == SampleData.movies.count)
        #expect(model.films.hasNominees)
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

    @Test func percentsAreWholeAndNeverCertain() {
        #expect(Contender.percent(0.724) == 72)
        #expect(Contender.percent(1) == 99)
        #expect(Contender.percent(0) == 1)
        #expect(Copy.odds(72) == "72% to be nominated")
    }

    @Test func theOddsSortIsMostLikelyFirstAndKeepsTitleOrderOnTies() {
        let movies = SampleData.movies.sorted { $0.title < $1.title }
        let odds: [Int: Double] = [1: 0.5, 2: 0.9, 3: 0.5]
        let sorted = FilmsTab.Sort.odds.sorted(movies) { odds[$0] }
        #expect(sorted.first?.id == 2)
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

    @Test func theCreditSaysPredictionsAndNamesTheSourceAndDateInBothVoices() async {
        let (model, _) = await model(.predicted)
        let credit = try! #require(model.films.credit)
        #expect(credit.source == "Next Best Picture")
        #expect(credit.updatedAt == SampleData.contendersUpdatedAt)
        for copy in [Copy.host, Copy.classic] {
            let line = copy.contendersCredit(credit.source, "Oct 27")
            #expect(line.contains("Next Best Picture's expert predictions"))
            #expect(line.contains("Oct 27"))
            #expect(copy.contendersCredit(nil, "Oct 27").contains("Our own odds"))
        }
        #expect(Copy.classic.contendersCredit(nil, "Oct 27").contains("predictions"))
    }

    @Test func theTickerAndHeroCountContendersBeforeNominations() {
        for copy in [Copy.host, Copy.classic] {
            #expect(copy.tickerBeforeNominations("Jan 21", 12).contains("12 contenders"))
            #expect(copy.tickerBeforeNominations("Jan 21", 12).contains("Jan 21"))
            #expect(copy.heroTeaser(1, "Jan 21").contains("1 contender"))
            #expect(copy.heroTeaser(5, "Jan 21").contains("Jan 21"))
        }
        #expect(Copy.classic.tickerBeforeNominations("Jan 21", nil) == "Nominations announced Jan 21.")
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

    @Test func theOfflineCopyKeepsTheContenders() async {
        let cache = OfflineCache(directory: FileManager.default.temporaryDirectory.appending(path: "offline-\(UUID().uuidString)"))
        let (first, data) = await model(.predicted, cache: cache)
        #expect(cache.snapshot(for: user)?.contenders?.count == data.contenderList.count)

        data.failure = .offline
        let second = AppModel(data: data, cache: cache)
        second.films.stage = .predicted
        await second.start()
        #expect(second.films.contenders.count == first.films.contenders.count)
        second.films.stage = .predicted
        #expect(second.films.list.count == first.films.list.count)
    }

    @Test func aSnapshotSavedBefore21StillOpens() throws {
        let old = #"{"movies":[],"watchedIDs":[],"categories":[],"picks":{},"plan":[],"groups":[],"boards":{},"savedAt":0}"#
        let snapshot = try JSONDecoder().decode(OfflineSnapshot.self, from: Data(old.utf8))
        #expect(snapshot.contenders == nil)
    }

    @Test func contendersDecodeFromTheRPC() throws {
        let json = #"""
        [{"id":1,"ceremony_id":2,"category_id":1,"category_name":"Best Picture","display_mode":"film","movie_id":7,
          "detail_text":null,"stage":"predicted","odds":0.724,"source":"Next Best Picture","source_updated_at":"2026-10-27T12:00:00Z"}]
        """#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rows = try decoder.decode([Contender].self, from: Data(json.utf8))
        #expect(rows.first?.percent == 72)
        #expect(rows.first?.stage == .predicted)
    }
}
