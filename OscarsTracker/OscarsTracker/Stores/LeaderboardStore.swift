import Foundation
import Observation

/// Every board you've opened, global and per group, from one RPC,
/// `get_season_board(p_ceremony_id, p_group_id)` (P2-05, 2.1), and the people
/// you've opened on them. The ranks, and the list they count, are the server's.
@Observable
final class LeaderboardStore {
    /// Films watched, or picks once the ballot locks.
    enum Metric: String, CaseIterable, Identifiable {
        case films, predictions
        var id: String { rawValue }
    }

    /// Boards by group; nil is the global board.
    private(set) var boards: [Int?: [BoardEntry]] = [:]
    private(set) var states: [Int?: LoadState] = [:]
    /// People opened from a board, by user id. Nil after a failed load:
    /// the RPC answers only for people who share a group with you.
    private(set) var people: [String: BoardPerson?] = [:]

    private let data: any AppDataSource
    private var ceremonyID: Int?

    init(data: any AppDataSource) {
        self.data = data
    }

    func entries(_ groupID: Int?) -> [BoardEntry] {
        boards[groupID] ?? []
    }

    func state(_ groupID: Int?) -> LoadState {
        states[groupID] ?? .idle
    }

    /// Picks and scores count on this board: from nominations day, never while
    /// it counts the contenders. True until it loads.
    func countsPicks(_ groupID: Int?) -> Bool {
        entries(groupID).first?.countsPicks ?? true
    }

    func load(ceremonyID: Int?, groupID: Int?) async {
        guard let ceremonyID else { return }
        self.ceremonyID = ceremonyID
        states[groupID] = .loading
        do {
            boards[groupID] = try await data.board(ceremonyID: ceremonyID, groupID: groupID)
            states[groupID] = .loaded
        } catch {
            states[groupID] = .failed(AppError(error))
        }
    }

    /// Reloads the global board and every board already open, after a refresh.
    func reload(ceremonyID: Int?) async {
        let groups = Set(boards.keys).union([nil])
        people = [:]
        for groupID in groups {
            await load(ceremonyID: ceremonyID, groupID: groupID)
        }
    }

    /// The last good copy, at launch; keyed as `OfflineSnapshot.boards`.
    func restore(boards cached: [String: [BoardEntry]], ceremonyID: Int?) {
        self.ceremonyID = self.ceremonyID ?? ceremonyID
        for (key, entries) in cached {
            let groupID: Int? = key == "global" ? nil : Int(key)
            guard groupID != nil || key == "global", boards[groupID] == nil else { continue }
            boards[groupID] = entries
            states[groupID] = .loaded
        }
    }

    /// For the snapshot.
    var cachedBoards: [String: [BoardEntry]] {
        Dictionary(uniqueKeysWithValues: boards.map { ($0.key.map(String.init) ?? "global", $0.value) })
    }

    /// Takes someone off every board, with the ranks closed up behind
    /// them, as the server does once you've blocked them (P6-16).
    func hide(_ userID: String) {
        for (groupID, entries) in boards where entries.contains(where: { $0.userId == userID }) {
            let others = entries.filter { $0.userId != userID }
            boards[groupID] = others.map { entry in entry.withRank(others.count { $0.rank < entry.rank } + 1) }
        }
        people[userID] = nil
    }

    func loadPerson(_ userID: String) async {
        guard let ceremonyID, people[userID] == nil else { return }
        people[userID] = .some(try? await data.boardPerson(ceremonyID: ceremonyID, userID: userID))
    }

    /// The board in the order the metric ranks it, with its rank. Predictions
    /// keep the server's order and rank. Films watched do too until winners
    /// are in (every score is 0 until then, so the server ranks by films);
    /// after that they're re-ranked by films, ties sharing a rank.
    static func ranked(_ entries: [BoardEntry], by metric: Metric) -> [(rank: Int, entry: BoardEntry)] {
        if metric == .predictions || entries.allSatisfy({ $0.score == 0 }) {
            return entries.map { ($0.rank, $0) }
        }
        let sorted = entries.enumerated().sorted { a, b in
            (a.element.watchedCount, b.offset) > (b.element.watchedCount, a.offset)
        }.map(\.element)
        return sorted.map { entry in (sorted.firstIndex { $0.watchedCount == entry.watchedCount }! + 1, entry) }
    }

    static func value(_ entry: BoardEntry, _ metric: Metric) -> Int {
        metric == .films ? entry.watchedCount : entry.score
    }

    /// Where you stand on a board: your rank, its size, and how you compare
    /// with the nearest person above you.
    struct Standing: Equatable {
        enum Position: Equatable {
            case first
            /// Level at the top with someone else.
            case tied(with: String)
            /// `by` behind `name`, the nearest person with more.
            case behind(String, by: Int)
        }

        /// The nearest person below you, and how many they trail by.
        struct Chaser: Equatable {
            let name: String
            let by: Int
        }

        let rank: Int
        let size: Int
        let position: Position
        var chaser: Chaser?
    }

    /// Nil until the board is loaded, or if you're not on it.
    func standing(in groupID: Int?, userID: String, metric: Metric = .films) -> Standing? {
        let board = Self.ranked(entries(groupID), by: metric)
        guard let me = board.first(where: { $0.entry.userId == userID }) else { return nil }
        let mine = Self.value(me.entry, metric)
        let others = board.map(\.entry).filter { $0.userId != userID }
        let position: Standing.Position
        if let above = others.filter({ Self.value($0, metric) > mine }).min(by: { Self.value($0, metric) < Self.value($1, metric) }) {
            position = .behind(above.username, by: Self.value(above, metric) - mine)
        } else if let level = others.first(where: { Self.value($0, metric) == mine }) {
            position = .tied(with: level.username)
        } else {
            position = .first
        }
        let chaser = others.filter { Self.value($0, metric) < mine }
            .max { Self.value($0, metric) < Self.value($1, metric) }
            .map { Standing.Chaser(name: $0.username, by: mine - Self.value($0, metric)) }
        return Standing(rank: me.rank, size: board.count, position: position, chaser: chaser)
    }

    func reset() {
        boards = [:]
        states = [:]
        people = [:]
        ceremonyID = nil
    }
}
