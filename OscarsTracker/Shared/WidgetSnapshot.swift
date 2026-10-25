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

    var ceremonyAt: Date?
    var filmsTotal: Int
    var filmsWatched: Int
    /// Unwatched films planned from today on, earliest first.
    var plan: [PlannedFilm]
    var savedAt: Date

    var filmsLeft: Int { max(filmsTotal - filmsWatched, 0) }

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
