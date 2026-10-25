import Foundation
import Testing
@testable import OscarsTracker

/// Live mode (P6-02). Sample ballot: Best Picture (1: 101–105, you picked
/// 103), Actress (2: 201–203, you picked 201), Animated Feature (3: 301, no pick).
@MainActor
@Suite("Live mode")
struct LiveModeTests {
    /// A loaded model on the rehearsal, with live mode on or off.
    private func model(live: Bool = true, admin: Bool = false) async -> (AppModel, SampleDataSource) {
        let data = SampleDataSource()
        data.isRehearsal = true
        data.isAdmin = admin
        data.config.featureFlags[AppConfig.liveMode] = live
        let model = AppModel(data: data)
        await model.start()
        return (model, data)
    }

    /// Waits for Realtime's updates to arrive and settle.
    private func until(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - The store

    private func store() async -> (LiveStore, BallotStore) {
        let data = SampleDataSource()
        let ballot = BallotStore(data: data)
        await ballot.load(userID: SampleDataSource.userID)
        let live = LiveStore(data: data, ballot: ballot, settleDelay: .zero)
        live.start()
        return (live, ballot)
    }

    @Test func aWinnerUpdatesTheBallotAtOnceAndQueuesItsEnvelope() async {
        let (live, ballot) = await store()
        live.receive(WinnerUpdate(nominationID: 103, categoryID: 1, isWinner: true))
        #expect(ballot.categories.first { $0.id == 1 }?.winnerIDs == [103])
        #expect(live.queue.isEmpty)
        live.settle()
        #expect(live.current == LiveStore.Reveal(categoryID: 1, category: "Best Picture", winner: ballot.categories[0].nominations[2].movie!.title,
                                                 detail: nil, outcome: .correct))
    }

    @Test func aReplacedWinnerIsOneEnvelopeForTheNewWinner() async {
        let (live, _) = await store()
        live.receive(WinnerUpdate(nominationID: 101, categoryID: 1, isWinner: true))
        live.settle()
        live.dismissCurrent()
        // admin_set_winner sends two row updates; the new winner may come first.
        live.receive(WinnerUpdate(nominationID: 102, categoryID: 1, isWinner: true))
        live.receive(WinnerUpdate(nominationID: 101, categoryID: 1, isWinner: false))
        live.settle()
        #expect(live.queue == [1])
        #expect(live.current?.outcome == .wrong)
        #expect(live.current?.winner == live.reveal(for: 1)?.winner)
    }

    @Test func actingWinnersLeadWithThePersonAndShowTheFilm() async {
        let (live, _) = await store()
        live.receive(WinnerUpdate(nominationID: 201, categoryID: 2, isWinner: true))
        live.settle()
        #expect(live.current?.winner == "Jessie Buckley")
        #expect(live.current?.detail != nil)
        #expect(live.current?.outcome == .correct)
    }

    @Test func aTieCountsYourPickAndNamesBoth() async {
        let (live, _) = await store()
        live.receive(WinnerUpdate(nominationID: 202, categoryID: 2, isWinner: true))
        live.receive(WinnerUpdate(nominationID: 201, categoryID: 2, isWinner: true))
        live.settle()
        #expect(live.current?.winner == "Jessie Buckley and Renate Reinsve" || live.current?.winner == "Renate Reinsve and Jessie Buckley")
        #expect(live.current?.outcome == .correct)
    }

    @Test func noPickHasNoVerdict() async {
        let (live, _) = await store()
        live.receive(WinnerUpdate(nominationID: 301, categoryID: 3, isWinner: true))
        live.settle()
        #expect(live.current?.categoryID == 3)
        #expect(live.current?.outcome == nil)
    }

    @Test func aWinnerTakenBackDropsItsEnvelope() async {
        let (live, ballot) = await store()
        live.receive(WinnerUpdate(nominationID: 103, categoryID: 1, isWinner: true))
        live.settle()
        live.receive(WinnerUpdate(nominationID: 103, categoryID: 1, isWinner: false))
        live.settle()
        #expect(live.queue.isEmpty)
        #expect(ballot.categories.first { $0.id == 1 }?.winnerIDs.isEmpty == true)
    }

    @Test func envelopesPlayInTheOrderTheyWereAnnounced() async {
        let (live, _) = await store()
        live.receive(WinnerUpdate(nominationID: 301, categoryID: 3, isWinner: true))
        live.settle()
        live.receive(WinnerUpdate(nominationID: 201, categoryID: 2, isWinner: true))
        live.settle()
        #expect(live.queue == [3, 2])
        live.dismissCurrent()
        #expect(live.current?.categoryID == 2)
        live.dismissCurrent()
        #expect(live.current == nil)
    }

    @Test func catchUpRevealsWinnersTheSubscriptionMissed() async {
        let data = SampleDataSource()
        let ballot = BallotStore(data: data)
        await ballot.load(userID: SampleDataSource.userID)
        let live = LiveStore(data: data, ballot: ballot, settleDelay: .zero)
        live.start()
        live.stop()
        live.start()
        // Set while nobody was listening, then found by a reload.
        data.categories[0] = data.categories[0].withWinners([104])
        await ballot.load(userID: SampleDataSource.userID)
        live.catchUp()
        #expect(live.queue == [1])
        live.catchUp()
        #expect(live.queue == [1])
    }

    @Test func aSubscriptionThatEndsIsMadeAgainOnTheNextStart() async {
        let data = SampleDataSource()
        let ballot = BallotStore(data: data)
        await ballot.load(userID: SampleDataSource.userID)
        let live = LiveStore(data: data, ballot: ballot, settleDelay: .zero)
        // The first subscription can't be made, so its stream ends at once.
        data.failure = .offline
        live.start()
        try? await Task.sleep(for: .milliseconds(100))
        data.failure = nil
        live.start()
        data.announce([103], inCategory: 1)
        await until { ballot.categories.first { $0.id == 1 }?.winnerIDs == [103] }
        #expect(ballot.categories.first { $0.id == 1 }?.winnerIDs == [103])
    }

    @Test func offIgnoresUpdates() async {
        let (live, ballot) = await store()
        live.stop()
        live.receive(WinnerUpdate(nominationID: 103, categoryID: 1, isWinner: true))
        live.settle()
        #expect(live.queue.isEmpty)
        #expect(ballot.categories.first { $0.id == 1 }?.winnerIDs.isEmpty == true)
    }

    // MARK: - End to end, on the rehearsal

    @Test func theAdminSettingAWinnerPlaysTheEnvelopeAndRescoresTheBoard() async {
        let (model, data) = await model(admin: true)
        #expect(model.season.isRehearsal)
        #expect(model.live.isOn)
        await model.profile.load(userID: SampleDataSource.userID)
        await model.admin.load()
        #expect(model.admin.ceremony?.isRehearsal == true)

        await model.admin.markWinner(103, in: 1)
        await until { model.live.current != nil && model.leaderboard.entries(nil).first?.userId == SampleDataSource.userID }

        #expect(model.live.current?.categoryID == 1)
        #expect(model.live.current?.outcome == .correct)
        #expect(model.ballot.score == 10)
        // You were second on films; one correct pick puts you first.
        #expect(model.leaderboard.entries(nil).first?.userId == SampleDataSource.userID)
        #expect(model.leaderboard.entries(nil).first?.score == 1)
        #expect(data.categories.first { $0.id == 1 }?.winnerIDs == [103])

        // A correction: undo, then the right winner.
        await model.admin.undo()
        await until { model.live.queue.isEmpty }
        #expect(model.live.queue.isEmpty)
        await model.admin.markWinner(102, in: 1)
        await until { model.live.current != nil }
        #expect(model.live.current?.outcome == .wrong)
    }

    @Test func anotherPhoneHearsTheWinnerWithoutARefresh() async {
        let (model, data) = await model()
        data.announce([202], inCategory: 2)
        await until { model.live.current != nil }
        #expect(model.ballot.categories.first { $0.id == 2 }?.winnerIDs == [202])
        #expect(model.live.current?.outcome == .wrong)
    }

    @Test func theFlagOffMeansNoLiveMode() async {
        let (model, data) = await model(live: false)
        #expect(!model.live.isOn)
        data.announce([103], inCategory: 1)
        try? await Task.sleep(for: .milliseconds(600))
        #expect(model.live.current == nil)
        #expect(model.ballot.categories.first { $0.id == 1 }?.winnerIDs.isEmpty == true)
    }

    @Test func turningTheFlagOffStopsIt() async {
        let (model, data) = await model()
        #expect(model.live.isOn)
        data.config.featureFlags[AppConfig.liveMode] = false
        await model.refresh()
        #expect(!model.live.isOn)
    }

    @Test func theFlagComingOnWhileAwayReloadsTheBallot() async {
        let (model, data) = await model(live: false)
        data.config.featureFlags[AppConfig.liveMode] = true
        // Announced while the app was in the background, before anyone listened.
        data.announce([104], inCategory: 1)
        await model.foreground()
        #expect(model.live.isOn)
        #expect(model.ballot.categories.first { $0.id == 1 }?.winnerIDs == [104])
    }

    @Test func signingOutStopsIt() async {
        let (model, _) = await model()
        await model.signOut()
        #expect(!model.live.isOn)
    }

    @Test func theTickerCountsTheEnvelopes() {
        #expect(Copy.classic.tickerLiveProgress(5, 23) == "LIVE · 5 of 23 announced")
        #expect(Copy.host.tickerLiveProgress(5, 23) == "LIVE · 5 of 23 envelopes open")
    }
}
