import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Offline")
struct OfflineTests {
    private let user = SampleDataSource.userID

    private func tempCache() -> OfflineCache {
        OfflineCache(directory: FileManager.default.temporaryDirectory.appending(path: "offline-\(UUID().uuidString)"))
    }

    @Test func anOfflineToggleStaysAndSendsLater() async {
        let data = SampleDataSource()
        let model = AppModel(data: data, cache: tempCache())
        await model.start()
        data.failure = .offline
        await model.films.toggleWatched(2, userID: user)
        #expect(model.films.isWatched(2))
        #expect(model.films.actionError == nil)
        #expect(model.pending == [.watched(movieID: 2, watched: true)])

        data.failure = nil
        await model.refresh()
        #expect(model.pending.isEmpty)
        #expect(data.watched.contains(2))
        #expect(model.films.isWatched(2))
    }

    @Test func onlyTheLastChangeToAFilmIsSent() async {
        let data = SampleDataSource()
        let model = AppModel(data: data, cache: tempCache())
        await model.start()
        data.failure = .offline
        await model.films.toggleWatched(2, userID: user)
        await model.films.toggleWatched(2, userID: user)
        #expect(model.pending == [.watched(movieID: 2, watched: false)])
    }

    @Test func aPickQueuedPastTheLockIsDroppedAndSaysSo() async {
        let data = SampleDataSource()
        let model = AppModel(data: data, cache: tempCache())
        await model.start()
        data.failure = .offline
        await model.ballot.choose(nominationID: 301, in: 3, userID: user, locked: false)
        #expect(model.pending.count == 1)

        data.failure = nil
        data.ceremony = Ceremony(id: 2, number: 99, name: "99th Academy Awards", ceremonyAt: .now.addingTimeInterval(-60),
                                 ballotLockAt: .now.addingTimeInterval(-60), isActive: true)
        await model.refresh()
        #expect(model.pending.isEmpty)
        #expect(model.ballot.actionError == .offlinePickLocked)
        #expect(model.ballot.pick(for: 3) == data.savedPicks[3])
    }

    @Test func launchesOfflineWithTheLastGoodCopyAndTheQueue() async {
        let cache = tempCache()
        let data = SampleDataSource()
        let first = AppModel(data: data, cache: cache)
        await first.start()
        data.failure = .offline
        await first.films.toggleWatched(5, userID: user)

        let second = AppModel(data: data, cache: cache)
        await second.start()
        #expect(second.films.movies.count == SampleData.movies.count)
        #expect(second.films.isWatched(5))
        #expect(second.ballot.categories.count == SampleData.categories.count)
        #expect(second.leaderboard.entries(nil).count == 6)
        #expect(second.pending == [.watched(movieID: 5, watched: true)])
    }

    @Test func signingOutLeavesNothingBehind() async {
        let cache = tempCache()
        let model = AppModel(data: SampleDataSource(), cache: cache)
        await model.start()
        #expect(cache.snapshot(for: user) != nil)
        await model.signOut()
        #expect(cache.snapshot(for: user) == nil)
        #expect(cache.queue(for: user).isEmpty)
    }

    @Test func errorsDescribeThemselvesPlainly() {
        let error: Error = AppError.server("duplicate key value violates unique constraint")
        #expect(error.localizedDescription == "Something went wrong on our side. Please try again.")
        #expect(AppError.offlinePickLocked.localizedDescription.contains("after the ballot locked"))
    }

    @Test func bothVoicesHaveTheOfflineLine() {
        for voice in Voice.allCases {
            #expect(Copy.for(voice).tickerOffline(2).contains("2"))
            #expect(!Copy.for(voice).tickerOffline(0).isEmpty)
        }
    }
}
