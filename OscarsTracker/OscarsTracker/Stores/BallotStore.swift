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
    /// What a group picked, by category, once the ballot locks (P6-05).
    private(set) var shares: [Int: [PickShare]] = [:]
    /// The group `shares` came from.
    private(set) var sharesGroup: PoolGroup?
    /// Bumped by every share load and clear, so a slower, older answer never
    /// lands over a newer one.
    private var sharesRequest = 0
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
    var score: Int { categories.compactMap(points(for:)).reduce(0, +) }

    /// The points your pick earned once the winner is in: the category's
    /// points when you called it, else 0 (P2-04). Nil before the winner, or
    /// with no pick.
    func points(for category: BallotCategory) -> Int? {
        outcome(for: category).map { $0 == .correct ? category.pointsValue : 0 }
    }

    /// The group's most-picked nominee in a category and its share; on a
    /// tie, the one listed first.
    func topShare(for category: BallotCategory) -> (nominee: BallotNominee, percent: Int)? {
        let rows = shares[category.id] ?? []
        guard let top = rows.max(by: { $0.pickCount < $1.pickCount }), top.pickCount > 0 else { return nil }
        let tied = Set(rows.filter { $0.pickCount == top.pickCount }.map(\.nominationId))
        guard let nominee = category.nominations.first(where: { tied.contains($0.id) }) else { return nil }
        return (nominee, top.percent)
    }

    /// Loads what `group` picked. Shares are a garnish, so a failure keeps
    /// what was there and says nothing.
    func loadShares(ceremonyID: Int, group: PoolGroup) async {
        sharesRequest += 1
        let request = sharesRequest
        do {
            let rows = try await data.pickShares(ceremonyID: ceremonyID, groupID: group.id)
            guard request == sharesRequest else { return }
            shares = Dictionary(grouping: rows, by: \.categoryId)
            sharesGroup = group
        } catch {
            guard request == sharesRequest else { return }
            if sharesGroup?.id != group.id { clearShares() }
        }
    }

    func clearShares() {
        sharesRequest += 1
        shares = [:]
        sharesGroup = nil
    }

    /// Categories left to pick.
    var remaining: Int { categories.count - pickedCount }

    func pick(for categoryID: Int) -> Int? {
        picks[categoryID]
    }

    /// Right or wrong once the category's winner is set; nil before, or with no pick.
    func outcome(for category: BallotCategory) -> Outcome? {
        guard let picked = picks[category.id], !category.winnerIDs.isEmpty else { return nil }
        // A tie has more than one winner; your pick is right if it's any of them.
        return category.winnerIDs.contains(picked) ? .correct : .wrong
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
        clearShares()
        state = .idle
    }
}
