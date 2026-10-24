import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Season facts and config", .serialized)
struct SeasonTests {
    @Test func locksOnTheServersClock() async {
        let data = SampleDataSource()
        // The server is two days ahead of this phone, so the lock 33 days out
        // is 31 days out by its clock: the countdown follows the server.
        data.serverNow = Date.now.addingTimeInterval(2 * 24 * 3600)
        let season = SeasonStore(data: data)
        await season.load()
        #expect(abs(season.clockOffset - 2 * 24 * 3600) < 5)
        #expect(season.daysToCeremony() == 31)

        data.serverNow = data.ceremony.ballotLockAt.addingTimeInterval(60)
        await season.load()
        #expect(season.isBallotLocked())
    }

    @Test func asksOldBuildsToUpdate() async {
        let data = SampleDataSource()
        data.config.minSupportedBuild = 40
        let season = SeasonStore(data: data)
        await season.load()
        #expect(season.needsUpdate(build: 39))
        #expect(!season.needsUpdate(build: 40))
        #expect(!season.needsUpdate(build: nil))
    }

    @Test func opensOfflineWithTheLastGoodSeason() async {
        let key = "season.cache.test"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        let data = SampleDataSource()
        data.config.featureFlags = ["live_mode": true]
        await SeasonStore(data: data, cacheKey: key).load()

        data.failure = .offline
        let offline = SeasonStore(data: data, cacheKey: key)
        await offline.load()
        #expect(offline.ceremony?.name == "99th Academy Awards")
        #expect(offline.config.isEnabled("live_mode"))
        #expect(offline.state == .loaded)
    }

    @Test func failsOnlyWithNothingToShow() async {
        let data = SampleDataSource()
        data.failure = .offline
        let season = SeasonStore(data: data)
        await season.load()
        #expect(season.state == .failed(.offline))
    }

    @Test func decodesTheFacts() throws {
        let json = #"[{"id":2,"number":99,"name":"99th Academy Awards","ceremony_at":"2027-03-14T23:00:00Z","ballot_lock_at":"2027-03-14T23:00:00Z","is_locked":false,"is_rehearsal":false,"server_now":"2026-10-24T12:00:00Z"}]"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let facts = try decoder.decode([SeasonFacts].self, from: Data(json.utf8))
        #expect(facts.first?.ceremony.number == 99)
    }

    @Test func bothVoicesHaveTheNewTickerLines() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(copy.tickerAfter(2, 6, "Movies LLC").contains("2nd of 6 in Movies LLC"))
            #expect(copy.tickerBeforeNominations("Jan 21").contains("Jan 21"))
            #expect(copy.tickerLive.hasPrefix("LIVE"))
        }
    }
}
