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
    var actionError: AppError?

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
        } catch {
            picks[categoryID] = previous
            actionError = AppError(error)
        }
    }

    func reset() {
        categories = []
        picks = [:]
        state = .idle
    }
}
