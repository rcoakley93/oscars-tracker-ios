import CoreGraphics
import Foundation
import Testing
@testable import OscarsTracker

@Suite("Season ticker")
struct SeasonTickerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func loadedSeason() async -> SeasonStore {
        let store = SeasonStore(data: SampleDataSource(now: now))
        await store.load()
        return store
    }

    @Test func countsDownDuringTheSeason() async {
        let season = await loadedSeason()
        #expect(season.ticker(filmsLeft: 7, now: now) == .season(days: 33, filmsLeft: 7))
    }

    @Test func switchesToLockDayInTheLastDay() async throws {
        let season = await loadedSeason()
        let lock = try #require(season.ceremony?.ballotLockAt)
        #expect(season.ticker(filmsLeft: 2, now: lock.addingTimeInterval(-3 * 3600)) == .lockDay(locksAt: lock))
    }

    @Test func saysNothingAfterTheLockUntilSeasonFactsLand() async throws {
        let season = await loadedSeason()
        let lock = try #require(season.ceremony?.ballotLockAt)
        #expect(season.ticker(filmsLeft: 0, now: lock.addingTimeInterval(60)) == .none)
        #expect(SeasonStore(data: SampleDataSource()).ticker(filmsLeft: 3) == .none)
    }

    @Test func roundsTheTimeLeftUp() {
        #expect(SeasonTicker.timeLeft(until: now.addingTimeInterval(3 * 3600), now: now) == "3 hours")
        #expect(SeasonTicker.timeLeft(until: now.addingTimeInterval(3600), now: now) == "1 hour")
        #expect(SeasonTicker.timeLeft(until: now.addingTimeInterval(40 * 60 - 10), now: now) == "40 minutes")
        #expect(SeasonTicker.timeLeft(until: now.addingTimeInterval(5), now: now) == "1 minute")
    }

    @Test func bothVoicesCountDays() {
        #expect(Copy.classic.tickerSeason(1, 1) == "1 day to the ceremony · 1 film left")
        #expect(Copy.classic.tickerSeason(33, 0) == "33 days to the ceremony · All films watched")
        #expect(Copy.host.tickerFinalWeek(7, 4) == "One week. Time to become a morning person.")
        #expect(Copy.host.tickerLockDay("3 hours") == "Pens down in 3 hours.")
    }
}

@Suite("Fold layout")
struct FoldLayoutTests {
    /// A vertical fold down the middle of an 800-point-wide inner display.
    private let fold = CGRect(x: 398, y: 0, width: 4, height: 600)

    @Test func keepsColumnsEvenAcrossAFold() {
        #expect(FoldLayout.columns(5, fold: fold) == 4)
        #expect(FoldLayout.columns(4, fold: fold) == 4)
        #expect(FoldLayout.columns(3, fold: fold) == 2)
        #expect(FoldLayout.columns(1, fold: fold) == 2)
    }

    @Test func leavesColumnsAloneWithoutAVerticalFold() {
        #expect(FoldLayout.columns(5, fold: nil) == 5)
        #expect(FoldLayout.columns(5, fold: CGRect(x: 0, y: 300, width: 800, height: 4)) == 5)
    }

    @Test func centresInTheRoomierHalf() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        #expect(FoldLayout.roomierHalf(of: bounds, fold: nil) == bounds)
        #expect(FoldLayout.roomierHalf(of: bounds, fold: fold) == CGRect(x: 0, y: 0, width: 398, height: 600))
        let offCentre = CGRect(x: 300, y: 0, width: 4, height: 600)
        #expect(FoldLayout.roomierHalf(of: bounds, fold: offCentre) == CGRect(x: 304, y: 0, width: 496, height: 600))
    }
}
