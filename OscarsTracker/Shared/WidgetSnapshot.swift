import Foundation

/// What the widgets show, written by the app into the App Group whenever its
/// stores refresh (P6-09). Widgets can't call the backend or read the app's
/// stores, so this is the whole of what they know. Shared with the widget
/// extension: keep it free of app types.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// A film planned for a day, not yet watched.
    struct PlannedFilm: Codable, Equatable, Sendable {
        let title: String
        let day: PlanDay
    }

    /// Which list the films are (P11-02): nil is the nominees, as 2.0 wrote it.
    enum ListStage: String, Codable, Sendable {
        case predicted, shortlisted, nominated
    }

    /// A watched film's poster colour, lighting its frame on the strip.
    struct PosterColor: Codable, Equatable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
    }

    /// Your ballot once winners are in, and where it puts you on the global board.
    struct Results: Codable, Equatable, Sendable {
        let correct: Int
        let total: Int
        var rank: Int?
        var ranked: Int?
    }

    var ceremonyAt: Date?
    var filmsTotal: Int
    var filmsWatched: Int
    /// Unwatched films planned from today on, earliest first.
    var plan: [PlannedFilm]
    var savedAt: Date
    // Added for 2.1 (P11-02); optional, so a 2.0 snapshot still decodes.
    var ceremonyNumber: Int?
    var ballotLockAt: Date?
    var nominationsAt: Date?
    var stage: ListStage?
    /// Up to 16 watched films' poster colours.
    var posters: [PosterColor]?
    var categoriesPicked: Int?
    var categoriesTotal: Int?
    var results: Results?

    var filmsLeft: Int { max(filmsTotal - filmsWatched, 0) }
    /// Whether the films are the nominees rather than contenders.
    var hasNominees: Bool { (stage ?? .nominated) == .nominated && filmsTotal > 0 }

    static let empty = WidgetSnapshot(ceremonyAt: nil, filmsTotal: 0, filmsWatched: 0, plan: [], savedAt: .distantPast)
}

/// The snapshot's file in the App Group container. A nil container keeps
/// nothing (previews and tests, and builds without the App Group).
nonisolated struct WidgetSnapshotStore: Sendable {
    static let appGroup = "group.com.oscars.tracker"
    static let fileName = "widget-snapshot.json"

    let directory: URL?

    static let live = WidgetSnapshotStore(directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup))
    static let none = WidgetSnapshotStore(directory: nil)

    func read() -> WidgetSnapshot? {
        guard let url = directory?.appending(path: Self.fileName), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Returns whether the snapshot changed, so the caller reloads timelines only then.
    @discardableResult
    func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = directory?.appending(path: Self.fileName) else { return false }
        if let old = read(), old.matches(snapshot) { return false }
        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        return (try? data.write(to: url, options: .atomic)) != nil
    }

    func clear() {
        guard let url = directory?.appending(path: Self.fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

extension WidgetSnapshot {
    /// Equal but for the save time.
    nonisolated func matches(_ other: WidgetSnapshot) -> Bool {
        var other = other
        other.savedAt = savedAt
        return self == other
    }
}
