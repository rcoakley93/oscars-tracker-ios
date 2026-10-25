import Foundation

/// Which push reminders you get, and in which voice (P6-04). The server
/// sends them (pg_cron), so it keeps the voice and the time zone your watch
/// plan's "today" means. Without a saved row the server uses `defaults`.
nonisolated struct NotificationPreferences: Codable, Equatable, Sendable {
    var nominations = true
    var watchPlan = false
    var ballotLock = true
    var results = true
    var voice = Voice.host.rawValue
    var timeZone = "America/New_York"

    static let defaults = NotificationPreferences()

    /// One switch on Profile.
    enum Reminder: CaseIterable, Identifiable, Sendable {
        case nominations, watchPlan, ballotLock, results
        var id: Self { self }

        var title: String {
            switch self {
            case .nominations: "Nominations are out"
            case .watchPlan: "Today's watch plan"
            case .ballotLock: "Ballot lock"
            case .results: "Your results"
            }
        }

        var detail: String {
            switch self {
            case .nominations: "When the nominees are announced."
            case .watchPlan: "At 9am, the films you planned for the day."
            case .ballotLock: "24 hours and 1 hour before picks lock."
            case .results: "Your score and rank once every winner is in."
            }
        }

        var systemImage: String {
            switch self {
            case .nominations: "envelope.open"
            case .watchPlan: "calendar"
            case .ballotLock: "lock"
            case .results: "trophy"
            }
        }
    }

    subscript(reminder: Reminder) -> Bool {
        get {
            switch reminder {
            case .nominations: nominations
            case .watchPlan: watchPlan
            case .ballotLock: ballotLock
            case .results: results
            }
        }
        set {
            switch reminder {
            case .nominations: nominations = newValue
            case .watchPlan: watchPlan = newValue
            case .ballotLock: ballotLock = newValue
            case .results: results = newValue
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case nominations, results, voice
        case watchPlan = "watch_plan"
        case ballotLock = "ballot_lock"
        case timeZone = "time_zone"
    }
}
