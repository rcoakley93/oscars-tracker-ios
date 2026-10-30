import Foundation

/// Which push reminders you get, and in which voice (P6-04). The server
/// sends them (pg_cron), so it keeps the voice and the time zone your watch
/// plan's "today" means. Without a saved row the server uses `defaults`.
nonisolated struct NotificationPreferences: Codable, Equatable, Sendable {
    var nominations = true
    var watchPlan = false
    var ballotLock = true
    var results = true
    var odds = true
    var voice = Voice.host.rawValue
    var timeZone = "America/New_York"

    static let defaults = NotificationPreferences()

    /// One switch on Profile.
    enum Reminder: CaseIterable, Identifiable, Sendable {
        case nominations, odds, watchPlan, ballotLock, results
        var id: Self { self }

        var title: String {
            switch self {
            case .nominations: "Nominations are out"
            case .odds: "Odds jumps"
            case .watchPlan: "Today's watch plan"
            case .ballotLock: "Ballot lock"
            case .results: "Your results"
            }
        }

        var detail: String {
            switch self {
            case .nominations: "When the nominees are announced."
            case .odds: "When a film you haven't watched climbs past 75%."
            case .watchPlan: "At 9am, the films you planned for the day."
            case .ballotLock: "24 hours and 1 hour before picks lock."
            case .results: "Your score and rank once every winner is in."
            }
        }

        var systemImage: String {
            switch self {
            case .nominations: "envelope.open"
            case .odds: "chart.line.uptrend.xyaxis"
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
            case .odds: odds
            case .watchPlan: watchPlan
            case .ballotLock: ballotLock
            case .results: results
            }
        }
        set {
            switch reminder {
            case .nominations: nominations = newValue
            case .odds: odds = newValue
            case .watchPlan: watchPlan = newValue
            case .ballotLock: ballotLock = newValue
            case .results: results = newValue
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case nominations, results, odds, voice
        case watchPlan = "watch_plan"
        case ballotLock = "ballot_lock"
        case timeZone = "time_zone"
    }

    init(nominations: Bool = true, watchPlan: Bool = false, ballotLock: Bool = true, results: Bool = true,
         odds: Bool = true, voice: String = Voice.host.rawValue, timeZone: String = "America/New_York") {
        self.nominations = nominations
        self.watchPlan = watchPlan
        self.ballotLock = ballotLock
        self.results = results
        self.odds = odds
        self.voice = voice
        self.timeZone = timeZone
    }

    /// Rows and caches from before the odds switch have no `odds`: it's on.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            nominations: try c.decode(Bool.self, forKey: .nominations),
            watchPlan: try c.decode(Bool.self, forKey: .watchPlan),
            ballotLock: try c.decode(Bool.self, forKey: .ballotLock),
            results: try c.decode(Bool.self, forKey: .results),
            odds: try c.decodeIfPresent(Bool.self, forKey: .odds) ?? true,
            voice: try c.decode(String.self, forKey: .voice),
            timeZone: try c.decode(String.self, forKey: .timeZone)
        )
    }
}
