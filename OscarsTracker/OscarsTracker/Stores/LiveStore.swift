import Foundation
import Observation

/// Oscar night (P6-02): winners arrive through Realtime as the admin sets
/// them, the ballot updates at once, and each new winner waits in line for
/// its envelope. On only while `app_config.feature_flags.live_mode` is.
///
/// The store keeps its own copy of each category's winners rather than
/// reading the ballot's, because the admin's own phone changes the ballot
/// before Realtime echoes the change, and the admin should see the envelope too.
@Observable
final class LiveStore {
    /// What an envelope shows: the category, its winner (or winners, in a
    /// tie), and whether your pick was right.
    struct Reveal: Identifiable, Equatable {
        let categoryID: Int
        let category: String
        let winner: String
        /// The film, when the winners are people.
        let detail: String?
        /// nil when you made no pick in the category.
        let outcome: EnvelopeReveal.Outcome?

        var id: Int { categoryID }
    }

    /// Whether winners are being followed.
    private(set) var isOn = false
    /// Categories with a winner still to reveal, oldest first.
    private(set) var queue: [Int] = []
    /// Called once a burst of winner changes settles, so the boards reload.
    var onWinnersSettled: (() -> Void)?

    private let data: any AppDataSource
    private let ballot: BallotStore
    /// How long to wait for the rest of a burst (a replaced winner is two
    /// row updates) before revealing.
    private let settleDelay: Duration
    /// Each category's winners as this store last heard them.
    private var winners: [Int: Set<Int>] = [:]
    /// Each category's winners when its envelope was last queued.
    private var revealed: [Int: Set<Int>] = [:]
    private var touched: Set<Int> = []
    private var listening: Task<Void, Never>?
    private var settling: Task<Void, Never>?

    init(data: any AppDataSource, ballot: BallotStore, settleDelay: Duration = .milliseconds(400)) {
        self.data = data
        self.ballot = ballot
        self.settleDelay = settleDelay
    }

    /// The envelope to show now.
    var current: Reveal? { queue.first.flatMap(reveal(for:)) }

    func reveal(for categoryID: Int) -> Reveal? {
        guard let category = ballot.categories.first(where: { $0.id == categoryID }) else { return nil }
        let won = category.nominations.filter(\.isWinner)
        guard !won.isEmpty else { return nil }
        let people = won.compactMap(\.personName).filter { !$0.isEmpty }
        let films = won.compactMap(\.movie?.title)
        let leadsWithPerson = people.count == won.count
        let outcome: EnvelopeReveal.Outcome? = ballot.pick(for: categoryID).map { category.winnerIDs.contains($0) ? .correct : .wrong }
        return Reveal(categoryID: categoryID, category: category.name,
                      winner: (leadsWithPerson ? people : films).formatted(.list(type: .and)),
                      detail: leadsWithPerson && !films.isEmpty ? films.formatted(.list(type: .and)) : nil,
                      outcome: outcome)
    }

    /// Categories with a winner, of all of them.
    var decidedCount: Int { ballot.categories.count { !$0.winnerIDs.isEmpty } }

    // MARK: - Following

    /// Starts following winners from what the ballot holds now. Does nothing
    /// if it's already on.
    func start() {
        guard !isOn else { return }
        isOn = true
        for category in ballot.categories where winners[category.id] == nil {
            winners[category.id] = category.winnerIDs
            revealed[category.id] = category.winnerIDs
        }
        let updates = data.winnerUpdates()
        listening = Task { [weak self] in
            for await update in updates {
                self?.receive(update)
            }
        }
    }

    /// Stops following and forgets the queue (the flag went off, or sign-out).
    func stop() {
        listening?.cancel()
        settling?.cancel()
        listening = nil
        settling = nil
        isOn = false
        queue = []
        winners = [:]
        revealed = [:]
        touched = []
    }

    /// One nominee's flag from Realtime: the ballot changes now, the envelope
    /// once the burst settles.
    func receive(_ update: WinnerUpdate) {
        guard isOn else { return }
        let id = update.categoryID
        var current = winners[id] ?? ballot.categories.first { $0.id == id }?.winnerIDs ?? []
        if revealed[id] == nil { revealed[id] = current }
        if update.isWinner { current.insert(update.nominationID) } else { current.remove(update.nominationID) }
        winners[id] = current
        ballot.apply(winners: current, in: id)
        touched.insert(id)
        scheduleSettle()
    }

    /// After a reload (a refresh, the network back, the app back from the
    /// background): winners the subscription missed play their envelopes too.
    func catchUp() {
        guard isOn else { return }
        for category in ballot.categories {
            guard let known = winners[category.id] else {
                winners[category.id] = category.winnerIDs
                revealed[category.id] = category.winnerIDs
                continue
            }
            if known != category.winnerIDs {
                winners[category.id] = category.winnerIDs
                touched.insert(category.id)
            }
        }
        if !touched.isEmpty { settle() }
    }

    /// The envelope was watched; the next one, if any, follows.
    func dismissCurrent() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
    }

    private func scheduleSettle() {
        settling?.cancel()
        settling = Task { [weak self, settleDelay] in
            try? await Task.sleep(for: settleDelay)
            guard !Task.isCancelled else { return }
            self?.settle()
        }
    }

    /// Queues an envelope for each touched category that gained a winner, and
    /// drops the envelope of one whose winner was taken back.
    func settle() {
        settling?.cancel()
        settling = nil
        for id in touched.sorted() {
            let now = winners[id] ?? []
            if now.isEmpty {
                queue.removeAll { $0 == id }
            } else if !now.isSubset(of: revealed[id] ?? []), !queue.contains(id) {
                queue.append(id)
            }
            revealed[id] = now
        }
        let changed = !touched.isEmpty
        touched = []
        if changed { onWinnersSettled?() }
    }
}
