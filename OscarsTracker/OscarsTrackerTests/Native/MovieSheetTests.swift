import Foundation
import Testing
@testable import OscarsTracker

@Suite("Where to watch")
struct WatchOfferTests {
    @Test func decodesAnAvailabilityRowWithItsProvider() throws {
        let json = #"[{"id": 7, "availability_type": "streaming", "providers": {"name": "Netflix", "logo_path": "/abc.png"}}]"#
        let offers = try JSONDecoder().decode([WatchOffer].self, from: Data(json.utf8))
        #expect(offers.first?.kind == .stream)
        #expect(offers.first?.provider.name == "Netflix")
        #expect(offers.first?.logoURL?.absoluteString == "https://image.tmdb.org/t/p/w92/abc.png")
    }

    @Test func readsTheDatabasesKindsAndCallsTheRestSpecial() {
        #expect(WatchOffer.Kind(availability: "streaming") == .stream)
        #expect(WatchOffer.Kind(availability: "theaters") == .theaters)
        #expect(WatchOffer.Kind(availability: "rent") == .rent)
        #expect(WatchOffer.Kind(availability: "buy") == .buy)
        #expect(WatchOffer.Kind(availability: "festival") == .special)
    }

    @Test func listsStreamingFirstThenByProvider() {
        func offer(_ id: Int, _ type: String, _ name: String) -> WatchOffer {
            WatchOffer(id: id, availabilityType: type, provider: .init(name: name, logoPath: nil))
        }
        let sorted = WatchOffer.sorted([offer(1, "buy", "Apple"), offer(2, "rent", "Amazon"), offer(3, "streaming", "Peacock"), offer(4, "rent", "Apple")])
        #expect(sorted.map(\.id) == [3, 2, 4, 1])
    }
}

@MainActor
@Suite("Movie sheet")
struct MovieSheetStoreTests {
    @Test func loadsAndCachesOffersPerFilm() async {
        let store = FilmsStore(data: SampleDataSource())
        #expect(store.offers[1] == nil)
        await store.loadOffers(for: 1)
        #expect(store.offers[1]?.first?.kind == .stream)
        await store.loadOffers(for: 9)
        #expect(store.offers[9] == [])
    }

    @Test func aFailedOfferLoadShowsNoOffersRatherThanLoadingForever() async {
        let data = SampleDataSource()
        data.failure = .offline
        let store = FilmsStore(data: data)
        await store.loadOffers(for: 1)
        #expect(store.offers[1] == [])
    }

    @Test func loadsGroupCountsAndKeepsThemHiddenOnFailure() async {
        let data = SampleDataSource()
        let store = FilmsStore(data: data)
        await store.loadSeen(for: 2)
        #expect(store.seen[2]?.map(\.groupName) == ["Movies LLC", "Family pool"])
        data.failure = .offline
        await store.loadSeen(for: 3)
        #expect(store.seen[3] == nil)
    }

    @Test func bothVoicesCountTheGroup() {
        for voice in Voice.allCases {
            #expect(Copy.for(voice).groupSeen(4, 6, "Movies LLC").hasPrefix("4 of 6 in Movies LLC have seen it."))
        }
    }
}
