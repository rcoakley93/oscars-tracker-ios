import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Admin")
struct AdminTests {
    /// Sample ballot: Best Picture (1: 101–105), Actress (2: 201–203), Animated Feature (3: 301).
    private func loaded(_ data: SampleDataSource = SampleDataSource(), admin: Bool = true) async -> AdminStore {
        data.isAdmin = admin
        let store = AdminStore(data: data)
        await store.load()
        return store
    }

    @Test func loadsTheActiveCeremonyInCeremonyOrder() async {
        let store = await loaded()
        #expect(store.ceremony?.number == 99)
        #expect(store.categories.map(\.id) == [3, 2, 1])
        #expect(store.decidedCount == 0)
        #expect(store.nextCategory?.id == 3)
    }

    @Test func onlyTheAdminCanLoadIt() async {
        let store = await loaded(admin: false)
        #expect(store.state == .failed(.adminsOnly))
        #expect(store.categories.isEmpty)
    }

    @Test func aWinnerReplacesTheOldOneAndUndoPutsItBack() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        await store.markWinner(101, in: 1)
        await store.markWinner(102, in: 1)
        #expect(store.winners(in: 1) == [102])
        #expect(data.categories.first { $0.id == 1 }?.winnerIDs == [102])
        #expect(store.ceremony?.winners == 1)

        await store.undo()
        #expect(store.winners(in: 1) == [101])
        await store.undo()
        #expect(store.winners(in: 1).isEmpty)
        #expect(data.categories.first { $0.id == 1 }?.winnerIDs.isEmpty == true)
        #expect(store.lastChange == nil)
    }

    @Test func aTieKeepsBothAndUndoRestoresIt() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        await store.markWinner(201, in: 2)
        await store.markWinner(202, in: 2, tie: true)
        #expect(store.winners(in: 2) == [201, 202])
        await store.clearWinner(in: 2)
        #expect(store.winners(in: 2).isEmpty)
        await store.undo()
        #expect(store.winners(in: 2) == [201, 202])
        #expect(data.categories.first { $0.id == 2 }?.winnerIDs == [201, 202])
    }

    @Test func aRefusedWinnerRollsBackAndKeepsNoUndo() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        data.failure = .offline
        await store.markWinner(101, in: 1)
        #expect(store.winners(in: 1).isEmpty)
        #expect(store.actionError == .offline)
        #expect(store.lastChange == nil)
    }

    @Test func aFailedUndoStaysUndoable() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        await store.markWinner(101, in: 1)
        data.failure = .offline
        await store.undo()
        #expect(store.winners(in: 1) == [101])
        #expect(store.lastChange?.current == [101])
    }

    @Test func winnersReachTheBallotAtOnce() async {
        let data = SampleDataSource()
        data.isAdmin = true
        let model = AppModel(data: data)
        await model.start()
        #expect(model.isAdmin)
        await model.admin.load()
        var seen: [AdminStore.WinnerChange] = []
        let ballotHook = model.admin.onWinnersChanged
        model.admin.onWinnersChanged = { ballotHook?($0); seen.append($0) }
        await model.admin.markWinner(201, in: 2)
        #expect(model.ballot.outcome(for: model.ballot.categories.first { $0.id == 2 }!) == .correct)
        #expect(seen == [AdminStore.WinnerChange(categoryID: 2, previous: [], current: [201])])
    }

    @Test func movesTheActiveCeremonyAndItsDates() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        let past = store.ceremonies.first { !$0.isActive }!
        #expect(await store.makeActive(past.id))
        #expect(store.ceremonies.first { $0.isActive }?.id == past.id)

        let ceremonyAt = Date.now.addingTimeInterval(86_400)
        #expect(await store.setDates(ceremonyAt: ceremonyAt, ballotLockAt: ceremonyAt.addingTimeInterval(-3600)))
        #expect(data.ceremony.ballotLockAt == ceremonyAt.addingTimeInterval(-3600))
        #expect(await store.setDates(ceremonyAt: ceremonyAt, ballotLockAt: ceremonyAt.addingTimeInterval(60)) == false)
        #expect(store.ceremony?.ceremonyAt == ceremonyAt)
    }

    @Test func sendsAPushOnlyWithATitle() async {
        let data = SampleDataSource()
        let store = await loaded(data)
        #expect(await store.sendPush(title: "  ", body: "x", destination: .home) == false)
        #expect(await store.sendPush(title: "Nominations are out", body: "Go look", destination: .films))
        #expect(data.sentPushes == ["Nominations are out"])
        #expect(store.deviceCount == 3)
    }

    @Test func theServersRefusalReadsPlainly() {
        #expect(AppError(serverMessage: "Admins only") == .adminsOnly)
    }

    @Test func profilesDecodeTheAdminFlag() throws {
        let json = Data(#"{"id":"x","username":"a","is_admin":true}"#.utf8)
        #expect(try JSONDecoder().decode(Profile.self, from: json).isAdmin == true)
        let old = Data(#"{"id":"x","username":"a"}"#.utf8)
        #expect(try JSONDecoder().decode(Profile.self, from: old).isAdmin == nil)
    }
}
