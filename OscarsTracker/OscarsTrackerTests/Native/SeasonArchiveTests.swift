import Foundation
import PostgREST
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Season archive")
struct SeasonArchiveTests {
    private let user = SampleDataSource.userID

    private func tempCache() -> OfflineCache {
        OfflineCache(directory: FileManager.default.temporaryDirectory.appending(path: "archive-\(UUID().uuidString)"))
    }

    @Test func decodesTheServersDocument() throws {
        // As get_season_archive() returns it: jsonb timestamps with fractional seconds.
        let json = #"""
        {"ceremony":{"id":1,"number":98,"name":"98th Academy Awards","ceremony_at":"2026-03-15T23:00:00+00:00","film_count":47},
         "ballot":[{"category_id":5,"name":"Actor in a Leading Role","display_mode":"person","points_value":5,
           "pick":{"nomination_id":51,"movie_id":2,"title":"Beta","poster_url":null,"release_year":2025,"detail_text":"Person 2"},
           "winners":[{"nomination_id":52,"movie_id":3,"title":"Gamma","poster_url":null,"release_year":2025,"detail_text":"Person 3"}],
           "is_correct":false},
          {"category_id":6,"name":"Casting","display_mode":"film","points_value":1,"pick":null,"winners":[],"is_correct":null}],
         "watched":[{"movie_id":1,"title":"Alpha","poster_url":null,"release_year":2025,"watched_at":"2026-02-01T20:15:03.123456+00:00"}],
         "boards":[{"group_id":null,"group_name":null,"rank":3,"players":212,"score":15,"scoring":"traditional","correct_count":15,"points":20,"watched_count":41},
                   {"group_id":7,"group_name":"Pool","rank":1,"players":6,"score":20,"scoring":"weighted","correct_count":15,"points":20,"watched_count":41}],
         "badges":[{"badge_key":"films_watched","shelf":"watching","sort_order":4,"ceremony_id":1,"ceremony_number":98,"tier":3,"tier_name":"gold","detail":{},"earned_at":"2026-03-15T23:00:01.5+00:00"}]}
        """#
        let archive = try PostgrestClient.Configuration.jsonDecoder.decode(SeasonArchive.self, from: Data(json.utf8))
        #expect(archive.ceremony.filmCount == 47)
        #expect(archive.ballot.map(\.isCorrect) == [false, nil])
        #expect(archive.ballot[0].personFirst)
        #expect(archive.ballot[0].pick?.title(personFirst: true) == "Person 2")
        #expect(archive.ballot[0].pick?.subtitle(personFirst: true) == "Beta")
        #expect(archive.boards.map(\.groupName) == [nil, "Pool"])
        #expect(archive.badges.first?.tier == 3)
        #expect(archive.picksMade == 1)
        #expect(archive.correctPicks == 0)
    }

    @Test func opensASeasonAndCachesIt() async {
        let cache = tempCache()
        let store = ProfileStore(data: SampleDataSource(), cache: cache)
        await store.loadArchive(ceremonyID: 1, userID: user)
        #expect(store.archiveState(1) == .loaded)
        #expect(store.archives[1] == SampleData.archive98)
        #expect(cache.archive(ceremonyID: 1, for: user) == SampleData.archive98)
    }

    @Test func readsOfflineFromTheCacheOnceOpened() async {
        let cache = tempCache()
        cache.save(SampleData.archive98, for: user)
        let data = SampleDataSource()
        data.failure = .offline
        let store = ProfileStore(data: data, cache: cache)
        await store.loadArchive(ceremonyID: 1, userID: user)
        #expect(store.archives[1] == SampleData.archive98)
        #expect(store.archiveState(1) == .loaded)
    }

    @Test func offlineAndNeverOpenedIsAnError() async {
        let data = SampleDataSource()
        data.failure = .offline
        let store = ProfileStore(data: data, cache: tempCache())
        await store.loadArchive(ceremonyID: 1, userID: user)
        #expect(store.archives[1] == nil)
        #expect(store.archiveState(1).error == .offline)
    }

    @Test func signingOutForgetsTheArchives() async {
        let cache = tempCache()
        let model = AppModel(data: SampleDataSource(), cache: cache)
        await model.start()
        await model.profile.loadArchive(ceremonyID: 1, userID: user)
        #expect(cache.archive(ceremonyID: 1, for: user) != nil)
        await model.signOut()
        #expect(cache.archive(ceremonyID: 1, for: user) == nil)
        #expect(model.profile.archives.isEmpty)
    }

    @Test func pastSeasonsListOfflineAfterARelaunch() async {
        let cache = tempCache()
        await ProfileStore(data: SampleDataSource(), cache: cache).loadHistory(userID: user)
        let data = SampleDataSource()
        data.failure = .offline
        let relaunched = ProfileStore(data: data, cache: cache)
        await relaunched.loadHistory(userID: user)
        #expect(relaunched.history.map(\.ceremonyId) == [1])
    }

    @Test func anArchiveLandingAfterSignOutIsDropped() async {
        let cache = tempCache()
        let data = SampleDataSource()
        data.archiveDelay = .milliseconds(200)
        let store = ProfileStore(data: data, cache: cache)
        let load = Task { await store.loadArchive(ceremonyID: 1, userID: user) }
        try? await Task.sleep(for: .milliseconds(50))
        store.reset()
        await load.value
        #expect(store.archives.isEmpty)
        #expect(store.archiveState(1) == .idle)
        #expect(cache.archive(ceremonyID: 1, for: user) == nil)
    }

    @Test func noPicksAndNoGroup() {
        #expect(SampleData.archiveNoPicks.picksMade == 0)
        #expect(SampleData.archiveNoPicks.ballot.allSatisfy { $0.isCorrect == nil })
        #expect(SampleData.archiveNoGroup.boards.map(\.groupId) == [nil])
    }
}
