import Foundation
import Observation

/// Ceremony night for the admin (P6-01): winners, the active ceremony and its
/// dates, and a push to everyone. Winners change at once and roll back if the
/// server refuses; every change can be undone, newest first.
///
/// `markWinner`, `clearWinner` and `onWinnersChanged` are the winner API that
/// live mode (P6-02) and the Live Activity (P6-03) build on.
@Observable
final class AdminStore {
    /// One change to a category's winners, for the undo and for whoever
    /// follows the winners (the ballot, live mode, the Live Activity).
    struct WinnerChange: Equatable, Sendable {
        let categoryID: Int
        let previous: Set<Int>
        let current: Set<Int>
    }

    private(set) var ceremonies: [AdminCeremony] = []
    /// The ceremony whose winners the screen sets; the active real one by default.
    private(set) var ceremonyID: Int?
    /// In ceremony order.
    private(set) var categories: [BallotCategory] = []
    private(set) var state: LoadState = .idle
    /// Changes that can still be undone, newest last.
    private(set) var undoStack: [WinnerChange] = []
    /// Categories with a winner change on its way, which take no other
    /// change until it's settled, so changes never overlap.
    private(set) var pendingCategories: Set<Int> = []
    private(set) var isSendingPush = false
    var actionError: AppError?
    /// Called after the server accepts a change to a category's winners.
    var onWinnersChanged: ((WinnerChange) -> Void)?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    var ceremony: AdminCeremony? { ceremonies.first { $0.id == ceremonyID } }

    /// The last change, for the Undo bar.
    var lastChange: WinnerChange? { undoStack.last }

    func load() async {
        if state != .loaded { state = .loading }
        do {
            ceremonies = try await data.adminStatus()
            if ceremonyID == nil || ceremony == nil {
                ceremonyID = (ceremonies.first { $0.isActive && !$0.isRehearsal } ?? ceremonies.first)?.id
            }
            if let requested = ceremonyID {
                let ballot = try await data.adminBallot(ceremonyID: requested)
                // A switch to another ceremony while this loaded wins.
                guard requested == ceremonyID else { return }
                categories = ballot
            } else {
                categories = []
            }
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// Switches the ceremony whose winners are set (the rehearsal, say).
    func select(ceremonyID: Int) async {
        guard ceremonyID != self.ceremonyID, pendingCategories.isEmpty else { return }
        self.ceremonyID = ceremonyID
        undoStack = []
        categories = []
        state = .loading
        await load()
    }

    func category(_ id: Int) -> BallotCategory? {
        categories.first { $0.id == id }
    }

    func winners(in categoryID: Int) -> Set<Int> {
        category(categoryID)?.winnerIDs ?? []
    }

    /// Categories with a winner, of all of them.
    var decidedCount: Int { categories.count { !$0.winnerIDs.isEmpty } }

    /// The first category without a winner: what's announced next.
    var nextCategory: BallotCategory? { categories.first { $0.winnerIDs.isEmpty } }

    /// Marks a nominee as its category's winner, replacing the old winner
    /// unless `tie` keeps it.
    func markWinner(_ nominationID: Int, in categoryID: Int, tie: Bool = false) async {
        let previous = winners(in: categoryID)
        let expected = (tie ? previous : []).union([nominationID])
        guard expected != previous else { return }
        await change(categoryID, from: previous, to: expected, recordUndo: true) {
            try await self.data.setWinner(nominationID: nominationID, tie: tie)
        }
    }

    func clearWinner(in categoryID: Int) async {
        let previous = winners(in: categoryID)
        guard !previous.isEmpty else { return }
        await change(categoryID, from: previous, to: [], recordUndo: true) {
            try await self.data.clearWinners(categoryID: categoryID)
            return []
        }
    }

    func isPending(_ categoryID: Int) -> Bool {
        pendingCategories.contains(categoryID)
    }

    /// Puts the last change back, in one write, ties included.
    func undo() async {
        guard let last = undoStack.last, !isPending(last.categoryID) else { return }
        undoStack.removeLast()
        let current = winners(in: last.categoryID)
        let restored = await change(last.categoryID, from: current, to: last.previous, recordUndo: false) {
            try await self.data.setWinners(categoryID: last.categoryID, nominationIDs: last.previous)
        }
        if !restored { undoStack.append(last) }
    }

    @discardableResult
    private func change(_ categoryID: Int, from previous: Set<Int>, to expected: Set<Int>, recordUndo: Bool,
                        _ send: () async throws -> Set<Int>) async -> Bool {
        guard !isPending(categoryID) else { return false }
        pendingCategories.insert(categoryID)
        defer { pendingCategories.remove(categoryID) }
        apply(expected, in: categoryID)
        do {
            let saved = try await send()
            apply(saved, in: categoryID)
            let change = WinnerChange(categoryID: categoryID, previous: previous, current: saved)
            if recordUndo { undoStack.append(change) }
            updateWinnerCount()
            onWinnersChanged?(change)
            return true
        } catch {
            apply(previous, in: categoryID)
            actionError = AppError(error)
            return false
        }
    }

    private func apply(_ winners: Set<Int>, in categoryID: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        categories[index] = categories[index].withWinners(winners)
    }

    private func updateWinnerCount() {
        guard let index = ceremonies.firstIndex(where: { $0.id == ceremonyID }) else { return }
        ceremonies[index].winners = decidedCount
    }

    // MARK: - The season

    /// Makes a ceremony the active one of its kind (real or rehearsal), and
    /// returns whether the server took it.
    @discardableResult
    func makeActive(_ ceremonyID: Int) async -> Bool {
        guard let target = ceremonies.first(where: { $0.id == ceremonyID }), !target.isActive else { return false }
        let before = ceremonies
        for index in ceremonies.indices where ceremonies[index].isRehearsal == target.isRehearsal {
            ceremonies[index].isActive = ceremonies[index].id == ceremonyID
        }
        do {
            try await data.setActiveCeremony(id: ceremonyID)
            return true
        } catch {
            ceremonies = before
            actionError = AppError(error)
            return false
        }
    }

    /// Returns whether the server took the new dates.
    func setDates(ceremonyAt: Date, ballotLockAt: Date) async -> Bool {
        guard let index = ceremonies.firstIndex(where: { $0.id == ceremonyID }) else { return false }
        guard ballotLockAt <= ceremonyAt else {
            actionError = .server("The ballot must lock before the ceremony starts")
            return false
        }
        let before = ceremonies[index]
        ceremonies[index].ceremonyAt = ceremonyAt
        ceremonies[index].ballotLockAt = ballotLockAt
        do {
            try await data.setCeremonyDates(id: before.id, ceremonyAt: ceremonyAt, ballotLockAt: ballotLockAt)
            return true
        } catch {
            ceremonies[index] = before
            actionError = AppError(error)
            return false
        }
    }

    // MARK: - Push

    /// How many devices a push to everyone reaches.
    var deviceCount: Int { ceremonies.first?.devices ?? 0 }

    /// Returns whether the push was queued.
    func sendPush(title: String, body: String, destination: PushDestination) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        isSendingPush = true
        defer { isSendingPush = false }
        do {
            try await data.sendPushToEveryone(title: title, body: body, destination: destination)
            return true
        } catch {
            actionError = AppError(error)
            return false
        }
    }

    /// Whether the nominations push is going out.
    private(set) var isSendingNominations = false

    /// "Nominations are out" for the selected ceremony, to everyone who
    /// wants it, in their voice (P6-04). Returns how many people it went to
    /// (0 if it had already gone out), or nil if it failed.
    func sendNominationsPush() async -> Int? {
        guard let ceremonyID else { return nil }
        isSendingNominations = true
        defer { isSendingNominations = false }
        do {
            return try await data.sendNominationsPush(ceremonyID: ceremonyID)
        } catch {
            actionError = AppError(error)
            return nil
        }
    }

    func reset() {
        ceremonies = []
        ceremonyID = nil
        categories = []
        undoStack = []
        pendingCategories = []
        state = .idle
    }
}
