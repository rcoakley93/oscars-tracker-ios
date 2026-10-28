import Foundation

/// The first launch after the list changes stage (P10-03): what changed,
/// against the list the last launch saw. The server moves the stage; this
/// only compares what two launches were given.
struct StageMoment: Equatable {
    /// The new stage.
    let stage: ListStage
    /// Films you'd watched on the old list that are on the new one.
    let made: Int
    /// Films you'd watched on the old list.
    let watched: Int
    /// The new list's size.
    let total: Int
    /// Films on the new list that weren't on the old one, in the list's order.
    let addedIDs: [Int]

    /// What a launch saw: the stage and its films.
    nonisolated struct Seen: Codable, Equatable, Sendable {
        let stage: ListStage
        let ids: [Int]
    }

    /// The moment for going from `seen` to `now`; nil while the stage is the
    /// same, and on the first launch, which has nothing to compare.
    static func between(_ seen: Seen?, and now: Seen, watchedIDs: Set<Int>) -> StageMoment? {
        guard let seen, seen.stage != now.stage else { return nil }
        let old = Set(seen.ids)
        let watchedBefore = old.intersection(watchedIDs)
        return StageMoment(stage: now.stage, made: watchedBefore.intersection(now.ids).count, watched: watchedBefore.count,
                           total: now.ids.count, addedIDs: now.ids.filter { !old.contains($0) })
    }
}

/// The stage and list each account last saw: in `UserDefaults` for the live
/// app, in memory for previews and tests.
final class StageMemory {
    private let defaults: UserDefaults?
    private var memory: [String: StageMoment.Seen] = [:]

    init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    private func key(_ userID: String) -> String { "stage.seen.\(userID)" }

    func seen(for userID: String) -> StageMoment.Seen? {
        guard let defaults else { return memory[userID] }
        return defaults.data(forKey: key(userID)).flatMap { try? JSONDecoder().decode(StageMoment.Seen.self, from: $0) }
    }

    func save(_ seen: StageMoment.Seen, for userID: String) {
        guard let defaults else { return memory[userID] = seen }
        defaults.set(try? JSONEncoder().encode(seen), forKey: key(userID))
    }
}
