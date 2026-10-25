import Foundation
import Testing
@testable import OscarsTracker

/// The `-store-shots` season keeps posters unfit for a 4+ store image off screen (P6-17).
@MainActor
@Suite("Store shots")
struct StoreShotsTests {
    private let user = SampleDataSource.userID

    @Test func leavesUnsafeFilmsOutOfTheSeason() async throws {
        let data = SampleDataSource(fullBallot: true)
        data.useStoreSafeSeason()
        let unsafe = SampleDataSource.storeUnsafeFilms
        let categories = try await data.ballot()
        let picks = try await data.picks(userID: user)
        let picked = categories.flatMap(\.nominations).filter { picks.values.contains($0.id) }.compactMap(\.movie?.id)
        #expect(unsafe.isDisjoint(with: picked))
        #expect(unsafe.isDisjoint(with: try await data.plan(userID: user).map(\.movieId)))
        #expect(unsafe.isDisjoint(with: try await data.watchedMovieIDs(userID: user)))
        #expect(unsafe.isDisjoint(with: try await data.movies().map(\.id)))
        let nominated = Set(categories.flatMap(\.nominations).compactMap(\.movie?.id))
        #expect(unsafe.isDisjoint(with: nominated))
        #expect(categories.allSatisfy { !$0.nominations.isEmpty })
    }

    @Test func leavesTheRegularSampleSeasonAlone() async throws {
        let data = SampleDataSource()
        #expect(try await data.picks(userID: user)[1] == 103)
    }
}
