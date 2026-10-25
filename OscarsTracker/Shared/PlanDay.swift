import Foundation

/// A calendar day in the viewer's own time zone, as the watch plan stores it
/// (`planned_date`, "yyyy-MM-dd"). Deadlines such as the ballot lock are
/// instants instead (`Date`), and are never turned into a `PlanDay`.
nonisolated struct PlanDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The calendar day that `date` falls on, in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Parses "yyyy-MM-dd". Returns nil for anything else.
    init?(_ string: String) {
        let parts = string.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), (1...31).contains(day) else { return nil }
        self.init(year: year, month: month, day: day)
    }

    static func today(calendar: Calendar = .current, now: Date = .now) -> PlanDay {
        PlanDay(now, calendar: calendar)
    }

    /// "yyyy-MM-dd", the form the database stores.
    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Midnight at the start of this day, in `calendar`'s time zone.
    func startDate(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    func adding(days: Int, calendar: Calendar = .current) -> PlanDay {
        PlanDay(calendar.date(byAdding: .day, value: days, to: startDate(calendar: calendar)) ?? .distantPast, calendar: calendar)
    }

    /// Whole days from `self` to `other` (negative when `other` is earlier).
    func days(until other: PlanDay, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: startDate(calendar: calendar), to: other.startDate(calendar: calendar)).day ?? 0
    }

    static func < (lhs: PlanDay, rhs: PlanDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let day = PlanDay(string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a yyyy-MM-dd day: \(string)"))
        }
        self = day
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// "2h 6m", "45m", "2h". One formatter for every runtime in the app.
nonisolated enum Runtime {
    static func format(minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "" }
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest)m" }
        if rest == 0 { return "\(hours)h" }
        return "\(hours)h \(rest)m"
    }
}
