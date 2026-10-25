import Foundation

/// Where the season is, from the ceremony's own dates and the clock: the one
/// function the hero and the season ticker both read (P6-06). No dates are
/// written down here; `Ceremony.ballotLockAt` and `Ceremony.ceremonyAt` decide.
enum SeasonPhase: Equatable {
    /// No season facts (or the show is long gone).
    case none
    /// No nominees yet: the shortlists, with the date when `app_config` knows it.
    case beforeNominations(Date?)
    /// Nominees are in; more than a week to the ceremony.
    case season(days: Int)
    /// The last seven days before the ceremony.
    case finalWeek(days: Int)
    /// Less than a day before the ballot locks.
    case lockDay(locksAt: Date)
    /// The ballot is locked and the show hasn't started.
    case locked(days: Int)
    /// The show is on (the hours from its start).
    case live
    /// The month after the show: results and the recap.
    case after

    static let showLength: TimeInterval = 5 * 60 * 60
    static let afterLength: TimeInterval = 30 * 24 * 60 * 60
    static let lockDayLength: TimeInterval = 24 * 60 * 60
    static let finalWeekDays = 7

    static func resolve(ceremony: Ceremony?, nominationsAt: Date? = nil, hasNominees: Bool = true,
                        now: Date, calendar: Calendar = .current) -> SeasonPhase {
        guard let ceremony else { return .none }
        if !hasNominees, now < ceremony.ballotLockAt { return .beforeNominations(nominationsAt) }
        let showEnd = ceremony.ceremonyAt.addingTimeInterval(showLength)
        if now >= showEnd {
            return now < ceremony.ceremonyAt.addingTimeInterval(afterLength) ? .after : .none
        }
        if now >= ceremony.ceremonyAt { return .live }
        let days = max(0, PlanDay.today(calendar: calendar, now: now).days(until: PlanDay(ceremony.ceremonyAt, calendar: calendar)))
        if now >= ceremony.ballotLockAt { return .locked(days: days) }
        if ceremony.ballotLockAt.timeIntervalSince(now) < lockDayLength { return .lockDay(locksAt: ceremony.ballotLockAt) }
        return days <= finalWeekDays ? .finalWeek(days: days) : .season(days: days)
    }

    /// Films a day is a useful figure while it can still be met: before the
    /// lock, outside the last day, and not past a pace nobody could keep.
    static func showsPace(_ phase: SeasonPhase, filmsLeft: Int, days: Int) -> Bool {
        switch phase {
        case .season, .finalWeek:
            filmsLeft > 0 && days > 0 && Double(filmsLeft) / Double(days) <= 4
        default:
            false
        }
    }
}
