import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Ballot")
struct BallotTests {
    private let user = SampleDataSource.userID

    /// Sample picks: Best Picture (1) and Actress (2) are picked; Animated Feature (3) isn't.
    private func loaded(_ data: SampleDataSource = SampleDataSource()) async -> BallotStore {
        let store = BallotStore(data: data)
        await store.load(userID: user)
        return store
    }

    @Test func countsWhatIsLeft() async {
        let store = await loaded()
        #expect(store.pickedCount == 2)
        #expect(store.remaining == store.categories.count - 2)
        #expect(store.nextCategory?.id == 3)
    }

    @Test func theLastPickCelebratesOnceAndOnlyAfterTheSave() async throws {
        let data = SampleDataSource()
        let store = await loaded(data)
        let last = try #require(store.categories.first { store.pick(for: $0.id) == nil })
        let nominee = try #require(last.nominations.first)

        data.failure = .offline
        await store.choose(nominationID: nominee.id, in: last.id, userID: user, locked: false)
        #expect(store.completions == 0)

        data.failure = nil
        await store.choose(nominationID: nominee.id, in: last.id, userID: user, locked: false)
        #expect(store.isComplete)
        #expect(store.completions == 1)

        // Changing a pick on a complete ballot isn't another completion.
        let other = try #require(last.nominations.last)
        await store.choose(nominationID: other.id, in: last.id, userID: user, locked: false)
        #expect(store.completions == 1)
    }

    @Test func scoresCorrectPicksOnceWinnersAreIn() async {
        let data = SampleDataSource()
        // The first nominee wins everywhere; the sample picks 103 in Best
        // Picture (wrong) and 201 in Actress (right, 5 points).
        data.categories = data.categories.map { category in
            BallotCategory(id: category.id, name: category.name, pointsValue: category.pointsValue,
                           nominations: category.nominations.enumerated().map { index, nominee in
                               BallotNominee(id: nominee.id, movie: nominee.movie, personName: nominee.personName, isWinner: index == 0)
                           })
        }
        let store = await loaded(data)
        #expect(store.hasWinners)
        #expect(store.outcome(for: store.categories[0]) == .wrong)
        #expect(store.outcome(for: store.categories[1]) == .correct)
        #expect(store.outcome(for: store.categories[2]) == nil)
        #expect(store.score == 5)
    }

    @Test func noWinnersMeansNoScore() async {
        let store = await loaded()
        #expect(!store.hasWinners)
        #expect(store.score == 0)
    }

    @Test func bothVoicesSayHowManyAreLeft() {
        for voice in Voice.allCases {
            #expect(Copy.for(voice).ballotIntro(5).contains("5"))
        }
    }
}
