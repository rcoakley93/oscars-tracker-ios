import Testing
@testable import OscarsTracker

@MainActor
@Suite("Voices")
struct CopyTests {
    @Test func bothVoicesCarryTheSameNumbers() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(copy.progressSummary(12, 50).contains("12"))
            #expect(copy.ballotProgress(18, 23).contains("18 of 23"))
            #expect(copy.pace("2.5", "March 14").contains("March 14"))
        }
    }

    @Test func theHostsPickLineIsSteadyForAPick() {
        #expect(Copy.host.pickSaved(103) == Copy.host.pickSaved(103))
        #expect(Copy.classic.pickSaved(103) == "Pick saved.")
    }

    @Test func voicesNameThemselves() {
        #expect(Copy.host.label == "Host")
        #expect(Copy.classic.label == "Classic")
    }
}
