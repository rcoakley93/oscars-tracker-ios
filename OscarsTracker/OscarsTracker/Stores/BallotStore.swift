import Foundation
import Observation

/// The ballot: categories, nominees and your picks.
@Observable
final class BallotStore {
    enum Outcome: Equatable {
        case correct
        case wrong
    }

    private(set) var categories: [BallotCategory] = []
    private(set) var picks: [Int: Int] = [:]
    private(set) var state: LoadState = .idle
    /// Counts the saves that picked the last category, for the gold dust. It
    /// changes only once the save succeeds, so a rolled-back pick never celebrates.
    private(set) var completions = 0
    /// Counts saved picks, for asking about notifications after the first.
    private(set) var saves = 0
    var actionError: AppError?
    /// Takes a pick made offline (P4-11); the pick then stays, queued.
    var onOffline: ((PendingWrite) -> Void)?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load(userID: String?) async {
        state = .loading
        do {
            async let ballot = data.ballot()
            var saved: [Int: Int] = [:]
            if let userID { saved = try await data.picks(userID: userID) }
            categories = try await ballot
            picks = saved
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    var pickedCount: Int { categories.count { picks[$0.id] != nil } }
    var isComplete: Bool { !categories.isEmpty && pickedCount == categories.count }

    /// The first category without a pick, else the first one.
    var nextCategory: BallotCategory? {
        categories.first { picks[$0.id] == nil } ?? categories.first
    }

    /// Whether any winner is in yet (ceremony night onwards).
    var hasWinners: Bool { categories.contains { $0.nominations.contains(where: \.isWinner) } }

    /// Points from correct picks so far.
    var score: Int { categories.filter { outcome(for: $0) == .correct }.map(\.pointsValue).reduce(0, +) }

    /// Categories left to pick.
    var remaining: Int { categories.count - pickedCount }

    func pick(for categoryID: Int) -> Int? {
        picks[categoryID]
    }

    /// Right or wrong once the category's winner is set; nil before, or with no pick.
    func outcome(for category: BallotCategory) -> Outcome? {
        guard let picked = picks[category.id], let winner = category.nominations.first(where: \.isWinner) else { return nil }
        return picked == winner.id ? .correct : .wrong
    }

    /// Saves a pick at once and rolls back if the server refuses it (for
    /// example, the lock passed). `locked` comes from the season, so a
    /// locked ballot never sends a request.
    func choose(nominationID: Int, in categoryID: Int, userID: String, locked: Bool) async {
        guard !locked else {
            actionError = .ballotLocked
            return
        }
        let previous = picks[categoryID]
        picks[categoryID] = nominationID
        do {
            try await data.savePick(categoryID: categoryID, nominationID: nominationID, userID: userID)
            saves += 1
            if previous == nil, isComplete { completions += 1 }
        } catch {
            let error = AppError(error)
            if error == .offline, let onOffline {
                onOffline(.pick(categoryID: categoryID, nominationID: nominationID))
                return
            }
            picks[categoryID] = previous
            actionError = error
        }
    }

    /// The last good copy, at launch, until the network answers.
    func restore(categories: [BallotCategory], picks: [Int: Int]) {
        guard self.categories.isEmpty, !categories.isEmpty else { return }
        self.categories = categories
        self.picks = picks
        state = .loaded
    }

    /// A queued pick, over what the server or the cache said.
    func apply(pick nominationID: Int, in categoryID: Int) {
        picks[categoryID] = nominationID
    }

    /// A category's winners as they change on ceremony night (the admin
    /// screen, P6-01; live mode, P6-02).
    func apply(winners: Set<Int>, in categoryID: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        categories[index] = categories[index].withWinners(winners)
    }

    func reset() {
        categories = []
        picks = [:]
        state = .idle
    }
}
