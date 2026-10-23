import Testing
@testable import OscarsTracker

@MainActor
@Suite("Ambient backdrop")
struct AmbientBackgroundTests {
    @Test func picksAFullGridSpreadThroughTheList() {
        let urls = (1...10).map { "https://example.com/\($0).jpg" }
        let picked = AmbientBackground.pick(urls)
        #expect(picked.count == 6)
        #expect(picked.first == urls[0])
        #expect(Set(picked).count == 6)
    }

    @Test func dropsDuplicatesAndBlanks() {
        #expect(AmbientBackground.pick(["a", "a", "", "b", "c"]) == ["a", "b", "c"])
        #expect(AmbientBackground.pick(["a", "b", "c", "d", "e"]).count == 4)
        #expect(AmbientBackground.pick([]).isEmpty)
    }
}
