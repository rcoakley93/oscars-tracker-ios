import Foundation
import SwiftUI
import Testing
@testable import OscarsTracker

/// The badge strips on Profile and Board (P12-04b): this season's 13, earned
/// first, the count in both voices and what VoiceOver reads.
@MainActor
@Suite("Badge strips")
struct BadgeStripTests {
    private func model(_ badges: [UserBadge]) async -> AppModel {
        let data = SampleDataSource()
        data.badgeRows[SampleDataSource.userID] = badges
        let model = AppModel(data: data)
        await model.start()
        return model
    }

    @Test func noneEarnedShowsEveryOutline() async {
        let tiles = await model([]).currentBadgeTiles
        #expect(tiles.map(\.badge.key) == Badge.catalogue.map(\.key))
        #expect(!tiles.contains { $0.isEarned })
    }

    @Test func earnedComeFirstThenTheOutlinesInCatalogueOrder() async {
        let tiles = await model(SampleData.myBadges).currentBadgeTiles
        #expect(tiles.count == Badge.catalogue.count)
        #expect(tiles.prefix(4).map(\.badge.key) == ["category_complete", "films_watched", "full_ballot", "top_billing"])
        #expect(tiles.prefix(4).allSatisfy { $0.isEarned })
        #expect(!tiles.dropFirst(4).contains { $0.isEarned })
        let order = Badge.catalogue.map(\.key)
        let rest = tiles.dropFirst(4).map(\.badge.key)
        #expect(rest == order.filter(rest.contains))
    }

    @Test func pastSeasonsStayOutOfTheStrip() async {
        let tiles = await model(SampleData.pastBadges).currentBadgeTiles
        #expect(!tiles.contains { $0.isEarned })
    }

    @Test func allEarned() async {
        let tiles = await model(SampleData.fullBadges).currentBadgeTiles
        #expect(tiles.allSatisfy { $0.isEarned })
    }

    @Test func theStripTriesFewerUntilThree() {
        #expect(BadgeStrip.options(13) == [13, 11, 9, 7, 5, 3])
        #expect(BadgeStrip.options(12) == [12, 10, 8, 6, 4, 3])
        #expect(BadgeStrip.options(2) == [2])
    }

    @Test func voiceOverNamesTheEarnedOnes() async {
        let tiles = await model(SampleData.currentBadges).currentBadgeTiles
        #expect(BadgeStrip.label(tiles, voice: .classic)
            == "Badges, 4 of 13 earned: Categories completed, Bronze; Films watched, Silver; Complete ballot, Gold; Group winner, Gold")
        let none = await model([]).currentBadgeTiles
        #expect(BadgeStrip.label(none, voice: .host) == "Badges, none earned yet")
    }

    @Test func theCountInBothVoices() {
        #expect(Copy.classic.badgeCount(0, 13) == "0 of 13 earned")
        #expect(Copy.classic.badgeCount(4, 13) == "4 of 13 earned")
        #expect(Copy.classic.badgeCount(13, 13) == "All 13 earned")
        #expect(Copy.host.badgeCount(0, 13) == "13 badges up for grabs.")
        #expect(Copy.host.badgeCount(4, 13) == "4 of 13. Room on the mantel.")
        #expect(Copy.host.badgeCount(13, 13) == "All 13. Clear the mantel.")
    }

    @Test func theBoardEmptyLineInBothVoices() {
        #expect(Copy.classic.boardBadgesEmpty == "Nobody has earned a badge yet.")
        #expect(Copy.host.boardBadgesEmpty == "Nobody's on the shelf yet. Somebody has to go first.")
    }

    // MARK: - The Board's Badges segment

    @Test func theBadgesSegmentKeepsTheMetric() {
        let navigation = AppNavigation()
        navigation.boardMetric = .predictions
        let segment = BoardSegment.binding(navigation)
        #expect(segment.wrappedValue == .predictions)
        segment.wrappedValue = .badges
        #expect(navigation.boardShowsBadges)
        #expect(navigation.boardMetric == .predictions)
        segment.wrappedValue = .films
        #expect(!navigation.boardShowsBadges)
        #expect(navigation.boardMetric == .films)
    }

    @Test func theBadgeBoardRanksByBadges() async throws {
        let model = await model(SampleData.myBadges)
        let ceremonyID = try #require(model.season.ceremony?.id)
        await model.badges.loadBoard(ceremonyID: ceremonyID, groupID: 1)
        let entries = model.badges.board(1)
        #expect(model.badges.boardState(1) == .loaded)
        #expect(entries.map(\.userId).prefix(2) == ["u-sam", SampleDataSource.userID])
        #expect(entries.map(\.rank).prefix(2) == [1, 2])
        #expect(entries.first { $0.userId == SampleDataSource.userID }?.badgeCount == 4)
        #expect(entries.dropFirst(2).allSatisfy { $0.badgeCount == 0 && $0.badges.isEmpty })
    }

    @Test func theGlobalBadgeBoardHasOnlyYourGroupMates() async throws {
        let model = await model(SampleData.myBadges)
        let ceremonyID = try #require(model.season.ceremony?.id)
        await model.badges.loadBoard(ceremonyID: ceremonyID, groupID: nil)
        let global = Set(model.badges.board(nil).map(\.userId))
        await model.leaderboard.load(ceremonyID: ceremonyID, groupID: 1)
        let mates = Set(model.leaderboard.entries(1).map(\.userId))
        #expect(global.isSubset(of: mates.union([SampleDataSource.userID])))
        #expect(global.contains(SampleDataSource.userID))
    }

    @Test func aFailedLoadShowsTheError() async throws {
        let data = SampleDataSource()
        let model = AppModel(data: data)
        await model.start()
        let ceremonyID = try #require(model.season.ceremony?.id)
        data.failure = AppError.server("Down")
        await model.badges.loadBoard(ceremonyID: ceremonyID, groupID: nil)
        #expect(model.badges.boardState(nil).error != nil)
        data.failure = nil
        await model.badges.reloadBoards(ceremonyID: ceremonyID)
        #expect(model.badges.boardState(nil) == .loaded)
    }

    @Test func blockingTakesThemOffTheBadgeBoard() async throws {
        let model = await model(SampleData.myBadges)
        let ceremonyID = try #require(model.season.ceremony?.id)
        await model.badges.loadBoard(ceremonyID: ceremonyID, groupID: 1)
        model.badges.hide("u-sam")
        let entries = model.badges.board(1)
        #expect(!entries.contains { $0.userId == "u-sam" })
        #expect(entries.first?.userId == SampleDataSource.userID)
        #expect(entries.first?.rank == 1)
    }

    @Test func aRowsStripIsOneTileABadgeNewestFirst() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let entry = BoardBadgeEntry(rank: 1, userId: "u", username: "Sam", avatarUrl: nil, badgeCount: 2, badges: [
            SampleData.badge("top_billing", earnedAt: base.addingTimeInterval(60), detail: BadgeDetail(groupId: 2)),
            SampleData.badge("top_billing", earnedAt: base, detail: BadgeDetail(groupId: 1)),
            SampleData.badge("films_watched", tier: 1, earnedAt: base),
            SampleData.badge("not_a_badge", earnedAt: base),
        ])
        #expect(entry.tiles.map(\.badge.key) == ["top_billing", "films_watched"])
        #expect(entry.tiles[0].earned.count == 2)
        #expect(BadgeBoardRow.label(entry, isYou: false, voice: .classic)
            == "Number 1, Sam, 2 of 13 badges: Group winner, Gold, 2 times; Films watched, Bronze")
        let none = BoardBadgeEntry(rank: 3, userId: "me", username: "me", avatarUrl: nil, badgeCount: 0, badges: [])
        #expect(BadgeBoardRow.label(none, isYou: true, voice: .host) == "Number 3, you, 0 of 13 badges")
        #expect(BadgeBoardRow.count(4) == "4 of 13 earned")
    }

    @Test func theRowDecodesTheRPC() throws {
        let json = """
        [{"rank": 1, "user_id": "u-1", "username": "Sam", "avatar_url": null, "badge_count": 1,
          "badges": [{"badge_key": "full_ballot", "shelf": "picking", "sort_order": 7, "ceremony_id": 2, "ceremony_number": 99,
                      "tier": 3, "tier_name": "gold", "detail": {}, "earned_at": "2026-10-28T12:00:00+00:00"}]}]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rows = try decoder.decode([BoardBadgeEntry].self, from: Data(json.utf8))
        #expect(rows.first?.tiles.map(\.badge.key) == ["full_ballot"])
    }
}
