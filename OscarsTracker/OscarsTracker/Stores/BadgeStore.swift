import Foundation
import Observation

/// Badges (P12-04): your case from `get_user_badges`, the people you've
/// opened on a board, and the earned moment's queue. The server awards them
/// and never takes one away; this only shows them.
@Observable
final class BadgeStore {
    /// Yours, every season, newest season first.
    private(set) var mine: [UserBadge] = []
    private(set) var state: LoadState = .idle
    /// People opened from a board, by user id. Nil after a failed load: the
    /// server shows badges only to people who share a group.
    private(set) var people: [String: [UserBadge]?] = [:]
    /// Badges waiting for their reveal, oldest first; the first is on screen.
    private(set) var queue: [UserBadge] = []

    private let data: any AppDataSource
    private let memory: BadgeMemory
    /// Moves on at sign-out, so a load still in flight for the previous
    /// account is dropped when it lands.
    private var generation = 0
    /// The last load came from the server, not only the offline copy.
    private var isFresh = false

    init(data: any AppDataSource, memory: BadgeMemory = BadgeMemory(defaults: nil)) {
        self.data = data
        self.memory = memory
    }

    func load(userID: String) async {
        if mine.isEmpty { state = .loading }
        let generation = generation
        do {
            let badges = try await data.userBadges(userID: userID)
            guard generation == self.generation else { return }
            mine = badges
            people = [:]
            isFresh = true
            state = .loaded
        } catch {
            guard generation == self.generation else { return }
            // The offline copy stays; only an empty case shows the error.
            isFresh = false
            state = mine.isEmpty ? .failed(AppError(error)) : .loaded
        }
    }

    /// The last good copy, at launch.
    func restore(_ badges: [UserBadge]) {
        guard mine.isEmpty else { return }
        mine = badges
    }

    func loadPerson(_ userID: String) async {
        guard people[userID] == nil else { return }
        people[userID] = .some(try? await data.userBadges(userID: userID))
    }

    // MARK: - The earned moment

    /// Fills the queue with badges this device hasn't shown for `userID`;
    /// true when there's something to reveal. Only after a load from the
    /// server, so the offline copy never replays. The first time on a
    /// device, badges earned more than `BadgeQueue.recent` ago count as seen.
    @discardableResult
    func noteNew(userID: String, now: Date = .now) -> Bool {
        guard isFresh, queue.isEmpty else { return !queue.isEmpty }
        var seen = memory.seen(for: userID)
        if seen == nil {
            let old = BadgeQueue.settled(mine, now: now)
            memory.save(old, for: userID)
            seen = old
        }
        queue = BadgeQueue.unseen(mine, seen: seen ?? [])
        return !queue.isEmpty
    }

    /// The reveal on screen: marked seen as soon as it appears, so it shows once.
    func shown(_ badge: UserBadge, userID: String) {
        var seen = memory.seen(for: userID) ?? []
        guard seen.insert(badge.momentKey).inserted else { return }
        memory.save(seen, for: userID)
    }

    /// "Next": the one on screen is done.
    func advance() {
        if !queue.isEmpty { queue.removeFirst() }
    }

    /// The reveal was closed: what's left waits, unseen, for the next refresh.
    func closeReveal() {
        queue = []
    }

    func reset() {
        mine = []
        people = [:]
        queue = []
        state = .idle
        isFresh = false
        generation += 1
    }
}

/// Which badges the earned moment shows, as plain functions for the tests.
enum BadgeQueue {
    /// How far back a first launch on a device still reveals.
    static let recent: TimeInterval = 3 * 24 * 60 * 60

    /// Known badges not yet shown, oldest first, then in the case's order.
    static func unseen(_ badges: [UserBadge], seen: Set<String>) -> [UserBadge] {
        var keys = Set<String>()
        return badges
            .filter { $0.badge != nil && !seen.contains($0.momentKey) && keys.insert($0.momentKey).inserted }
            .sorted { ($0.earnedAt, $0.sortOrder) < ($1.earnedAt, $1.sortOrder) }
    }

    /// The keys of badges earned before `recent`, for a first launch.
    static func settled(_ badges: [UserBadge], now: Date) -> Set<String> {
        Set(badges.filter { now.timeIntervalSince($0.earnedAt) > recent }.map(\.momentKey))
    }
}

/// The badges each account has seen revealed on this device: in
/// `UserDefaults` for the live app, in memory for previews and tests.
final class BadgeMemory {
    private let defaults: UserDefaults?
    private var memory: [String: Set<String>] = [:]

    init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    private func key(_ userID: String) -> String { "badges.seen.\(userID)" }

    func seen(for userID: String) -> Set<String>? {
        guard let defaults else { return memory[userID] }
        return defaults.stringArray(forKey: key(userID)).map(Set.init)
    }

    func save(_ seen: Set<String>, for userID: String) {
        guard let defaults else { return memory[userID] = seen }
        defaults.set(seen.sorted(), forKey: key(userID))
    }
}
