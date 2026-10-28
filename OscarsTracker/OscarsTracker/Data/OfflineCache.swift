import Foundation

/// The last good copy of your season (P4-11), shown at once at launch and
/// whenever the network is gone.
nonisolated struct OfflineSnapshot: Codable, Sendable {
    var movies: [Movie] = []
    var watchedIDs: Set<Int> = []
    /// The contender list (P9-05); nil in a copy saved before 2.1.
    var contenders: [Contender]? = nil
    /// The `list_stage` it was saved at, for a launch with no season; nil before 2.1.
    var listStage: ListStage? = nil
    var categories: [BallotCategory] = []
    var picks: [Int: Int] = [:]
    var plan: [WatchPlanItem] = []
    var groups: [PoolGroup] = []
    /// Boards by group id; "global" for the global board.
    var boards: [String: [BoardEntry]] = [:]
    var savedAt = Date.now
}

/// A watched toggle or a pick made offline, sent when the network is back.
nonisolated enum PendingWrite: Codable, Equatable, Sendable {
    case watched(movieID: Int, watched: Bool)
    case pick(categoryID: Int, nominationID: Int)

    /// Writes to the same film or category replace each other: only the last counts.
    func replaces(_ other: PendingWrite) -> Bool {
        switch (self, other) {
        case (.watched(let a, _), .watched(let b, _)): a == b
        case (.pick(let a, _), .pick(let b, _)): a == b
        default: false
        }
    }
}

/// Files in Caches, one snapshot and one queue per account. A nil directory
/// keeps nothing (previews and tests).
nonisolated struct OfflineCache: Sendable {
    let directory: URL?

    static let live = OfflineCache(directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
        .appending(path: "Offline", directoryHint: .isDirectory))
    static let none = OfflineCache(directory: nil)

    func snapshot(for userID: String) -> OfflineSnapshot? {
        read(OfflineSnapshot.self, "snapshot-\(userID).json")
    }

    func save(_ snapshot: OfflineSnapshot, for userID: String) {
        write(snapshot, "snapshot-\(userID).json")
    }

    func queue(for userID: String) -> [PendingWrite] {
        read([PendingWrite].self, "queue-\(userID).json") ?? []
    }

    func save(_ queue: [PendingWrite], for userID: String) {
        write(queue, "queue-\(userID).json")
    }

    /// A past season's archive (P12-06), kept once opened so it reads offline.
    func archive(ceremonyID: Int, for userID: String) -> SeasonArchive? {
        read(SeasonArchive.self, "archive-\(userID)-\(ceremonyID).json")
    }

    func save(_ archive: SeasonArchive, for userID: String) {
        write(archive, "archive-\(userID)-\(archive.ceremony.id).json")
    }

    /// At sign-out and account deletion: nothing of yours stays on the phone.
    func clear(for userID: String) {
        guard let directory else { return }
        let archives = (try? FileManager.default.contentsOfDirectory(atPath: directory.path()))?
            .filter { $0.hasPrefix("archive-\(userID)-") } ?? []
        for name in ["snapshot-\(userID).json", "queue-\(userID).json"] + archives {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
        }
    }

    private func read<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
        guard let directory, let data = try? Data(contentsOf: directory.appending(path: name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<T: Encodable>(_ value: T, _ name: String) {
        guard let directory, let data = try? JSONEncoder().encode(value) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: directory.appending(path: name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
