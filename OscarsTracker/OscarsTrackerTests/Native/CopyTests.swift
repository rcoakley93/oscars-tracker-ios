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

    @Test func theTallyKeepsItsNumbersInBothVoices() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            for (correct, announced, final) in [(0, 5, false), (3, 5, false), (14, 23, true), (23, 23, true), (4, 23, true)] {
                #expect(copy.callTally(correct, announced, final).contains("\(correct) of \(announced)"))
            }
        }
    }
}
