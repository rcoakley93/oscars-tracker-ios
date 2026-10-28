import Foundation
import PostgREST
import Testing
import UIKit
@testable import OscarsTracker

@MainActor
@Suite("Badges")
struct BadgeTests {
    private let user = SampleDataSource.userID
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func store(_ badges: [UserBadge], memory: BadgeMemory = BadgeMemory(defaults: nil)) -> (BadgeStore, SampleDataSource) {
        let data = SampleDataSource()
        data.badgeRows[SampleDataSource.userID] = badges
        return (BadgeStore(data: data, memory: memory), data)
    }

    private func fresh(_ key: String, tier: Int = 3, minutesAgo: Double = 5, detail: BadgeDetail? = nil) -> UserBadge {
        SampleData.badge(key, tier: tier, earnedAt: now.addingTimeInterval(-minutesAgo * 60), detail: detail)
    }

    // MARK: - The earned-moment queue

    @Test func queuesNewBadgesOldestFirst() async {
        let (store, _) = store([fresh("full_ballot", minutesAgo: 1), fresh("films_watched", tier: 1, minutesAgo: 10)])
        await store.load(userID: user)
        #expect(store.noteNew(userID: user, now: now))
        #expect(store.queue.map(\.badgeKey) == ["films_watched", "full_ballot"])
    }

    @Test func eachBadgeShowsOnce() async {
        let memory = BadgeMemory(defaults: nil)
        let (store, _) = store([fresh("full_ballot")], memory: memory)
        await store.load(userID: user)
        #expect(store.noteNew(userID: user, now: now))
        store.shown(store.queue[0], userID: user)
        store.closeReveal()
        await store.load(userID: user)
        #expect(!store.noteNew(userID: user, now: now))
        #expect(store.queue.isEmpty)
    }

    @Test func closingLeavesTheRestForTheNextRefresh() async {
        let (store, _) = store([fresh("full_ballot", minutesAgo: 2), fresh("death_race", minutesAgo: 1)])
        await store.load(userID: user)
        store.noteNew(userID: user, now: now)
        store.shown(store.queue[0], userID: user)
        store.closeReveal()
        #expect(store.noteNew(userID: user, now: now))
        #expect(store.queue.map(\.badgeKey) == ["death_race"])
    }

    @Test func nextMovesThroughTheQueue() async {
        let (store, _) = store([fresh("full_ballot", minutesAgo: 2), fresh("death_race", minutesAgo: 1)])
        await store.load(userID: user)
        store.noteNew(userID: user, now: now)
        store.advance()
        #expect(store.queue.map(\.badgeKey) == ["death_race"])
        store.advance()
        #expect(store.queue.isEmpty)
    }

    @Test func aRaisedTierIsNew() async {
        let memory = BadgeMemory(defaults: nil)
        let (store, data) = store([fresh("films_watched", tier: 1)], memory: memory)
        await store.load(userID: user)
        store.noteNew(userID: user, now: now)
        store.shown(store.queue[0], userID: user)
        store.closeReveal()
        data.badgeRows[user] = [fresh("films_watched", tier: 2)]
        await store.load(userID: user)
        #expect(store.noteNew(userID: user, now: now))
        #expect(store.queue.map(\.tier) == [2])
    }

    @Test func aSecondGroupWonIsNew() {
        let seen: Set = [fresh("top_billing", detail: BadgeDetail(groupId: 1)).momentKey]
        let second = fresh("top_billing", detail: BadgeDetail(groupId: 2))
        #expect(BadgeQueue.unseen([fresh("top_billing", detail: BadgeDetail(groupId: 1)), second], seen: seen) == [second])
    }

    @Test func aFirstLaunchSkipsOldBadges() async {
        let (store, _) = store([fresh("films_watched", minutesAgo: 60 * 24 * 30), fresh("full_ballot")])
        await store.load(userID: user)
        #expect(store.noteNew(userID: user, now: now))
        #expect(store.queue.map(\.badgeKey) == ["full_ballot"])
    }

    @Test func theOfflineCopyNeverReveals() async {
        let (store, data) = store([fresh("full_ballot")])
        store.restore([fresh("full_ballot")])
        data.failure = .offline
        await store.load(userID: user)
        #expect(store.state == .loaded)
        #expect(!store.noteNew(userID: user, now: now))
    }

    @Test func unknownBadgesAreSkipped() {
        let unknown = UserBadge(badgeKey: "future_badge", shelf: "watching", sortOrder: 99, ceremonyId: 2, ceremonyNumber: 99,
                                tier: 3, tierName: "gold", earnedAt: now)
        #expect(BadgeQueue.unseen([unknown], seen: []).isEmpty)
    }

    @Test func signOutDropsTheQueue() async {
        let (store, _) = store([fresh("full_ballot")])
        await store.load(userID: user)
        store.noteNew(userID: user, now: now)
        store.reset()
        #expect(store.queue.isEmpty)
        #expect(store.mine.isEmpty)
    }

    @Test func theMemoryPersistsInDefaults() throws {
        let suite = "badges-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        BadgeMemory(defaults: defaults).save(["a", "b"], for: user)
        #expect(BadgeMemory(defaults: defaults).seen(for: user) == ["a", "b"])
        #expect(BadgeMemory(defaults: defaults).seen(for: "someone-else") == nil)
    }

    // MARK: - The app

    @Test func aRefreshOpensTheReveal() async {
        let data = SampleDataSource()
        data.badgeRows[user] = [SampleData.badge("full_ballot", earnedAt: .now)]
        let model = AppModel(data: data)
        await model.start()
        #expect(model.navigation.sheet == .badgeEarned)
        #expect(model.badges.queue.map(\.badgeKey) == ["full_ballot"])
    }

    @Test func oldSampleBadgesDontOpenTheReveal() async {
        let model = AppModel(data: SampleDataSource())
        await model.start()
        #expect(model.navigation.sheet == nil)
        #expect(model.badges.mine.count == SampleData.myBadges.count)
    }

    @Test func theSnapshotKeepsBadges() async {
        let cache = OfflineCache(directory: FileManager.default.temporaryDirectory.appending(path: "badges-\(UUID().uuidString)"))
        let model = AppModel(data: SampleDataSource(), cache: cache)
        await model.start()
        #expect(cache.snapshot(for: user)?.badges == SampleData.myBadges.sorted {
            ($1.ceremonyNumber, $0.sortOrder) < ($0.ceremonyNumber, $1.sortOrder)
        })
    }

    // MARK: - The case

    @Test func theCurrentSeasonShowsEveryBadgeAndPastOnesOnlyTheirs() {
        let seasons = BadgeSeason.seasons(SampleData.myBadges, current: (id: 2, number: 99))
        #expect(seasons.map(\.ceremonyNumber) == [99, 98])
        #expect(seasons[0].tiles.count == Badge.catalogue.count)
        #expect(seasons[0].earnedCount == SampleData.currentBadges.count)
        #expect(seasons[1].tiles.map(\.badge.key) == ["films_watched", "top_billing"])
        #expect(seasons[0].name == "99th Academy Awards")
    }

    @Test func anEmptyCaseStillShowsThisSeason() {
        let seasons = BadgeSeason.seasons([], current: (id: 2, number: 99))
        #expect(seasons.count == 1)
        #expect(seasons[0].earnedCount == 0)
        #expect(seasons[0].tiles.allSatisfy { $0.imageName.hasSuffix("-unearned") })
    }

    @Test func twoGroupsWonAreOneTile() {
        let rows = [SampleData.badge("top_billing", detail: BadgeDetail(groupId: 1)),
                    SampleData.badge("top_billing", detail: BadgeDetail(groupId: 2))]
        let tile = BadgeSeason.seasons(rows, current: nil)[0].tiles[0]
        #expect(tile.earned.count == 2)
        #expect(BadgeArt.label(tile, voice: .classic) == "Group winner, Gold, 2 times")
    }

    @Test func everyBadgeHasArt() {
        for badge in Badge.catalogue {
            let tiers = badge.isTiered ? ["bronze", "silver", "gold"] : ["gold"]
            for name in tiers + [nil] {
                #expect(UIImage(named: Badge.imageName(badge.key, tierName: name)) != nil, "\(badge.key) \(name ?? "unearned")")
            }
        }
    }

    @Test func theCatalogueMatchesTheServer() {
        #expect(Badge.catalogue.count == 13)
        #expect(Badge.named("films_watched")?.thresholds == [10, 25, 40])
        #expect(Badge.named("films_watched")?.nextTier(after: 1) == "Next: Silver at 25 films")
        #expect(Badge.named("death_race")?.tierLabel(3) == nil)
    }

    @Test func decodesGetUserBadges() throws {
        let json = #"""
        [{"badge_key":"top_billing","shelf":"groups","sort_order":12,"ceremony_id":2,"ceremony_number":99,"tier":3,"tier_name":"gold",
          "detail":{"group_id":7},"earned_at":"2027-03-14T23:00:01.5+00:00"},
         {"badge_key":"category_complete","shelf":"watching","sort_order":3,"ceremony_id":2,"ceremony_number":99,"tier":1,"tier_name":"bronze",
          "detail":{"category_ids":[1,2,3]},"earned_at":"2027-03-14T23:00:01+00:00"},
         {"badge_key":"death_race","shelf":"watching","sort_order":1,"ceremony_id":2,"ceremony_number":99,"tier":3,"tier_name":"gold",
          "detail":{},"earned_at":"2027-03-14T23:00:01+00:00"}]
        """#
        let rows = try PostgrestClient.Configuration.jsonDecoder.decode([UserBadge].self, from: Data(json.utf8))
        #expect(rows[0].detail?.groupId == 7)
        #expect(rows[1].detail?.categoryIds == [1, 2, 3])
        #expect(rows[2].detail == BadgeDetail())
        #expect(rows[0].momentKey == "top_billing|2|3|7")
    }

    @Test func peopleOutsideYourGroupsShowNoBadges() async {
        let data = SampleDataSource()
        let store = BadgeStore(data: data)
        await store.loadPerson("u-sam")
        await store.loadPerson("u-stranger")
        #expect(store.people["u-sam"]??.count == SampleData.samBadges.count)
        #expect(store.people["u-stranger"] == .some(nil))
    }
}
