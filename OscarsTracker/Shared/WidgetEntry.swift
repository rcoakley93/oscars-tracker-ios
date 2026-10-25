import Foundation
import WidgetKit

/// One moment of a widget's timeline: what it shows from `date` until the
/// next entry. The provider hands WidgetKit one per local midnight, so the
/// day count and tonight's film roll over without the app running.
nonisolated struct WidgetEntry: TimelineEntry, Equatable, Sendable {
    let date: Date
    /// Whole days to the ceremony; nil when there's no ceremony or it's past.
    let daysToCeremony: Int?
    let filmsLeft: Int
    let filmsTotal: Int
    /// The unwatched film planned for this day, if any.
    let tonight: String?
    /// More than one is planned for tonight.
    let tonightExtra: Int

    var filmsWatched: Int { filmsTotal - filmsLeft }
    var hasSeason: Bool { filmsTotal > 0 || daysToCeremony != nil }

    static func make(_ snapshot: WidgetSnapshot, at date: Date, calendar: Calendar = .current) -> WidgetEntry {
        let today = PlanDay(date, calendar: calendar)
        var days: Int?
        if let ceremonyAt = snapshot.ceremonyAt {
            let n = today.days(until: PlanDay(ceremonyAt, calendar: calendar), calendar: calendar)
            days = n >= 0 ? n : nil
        }
        let tonight = snapshot.plan.filter { $0.day == today }
        return WidgetEntry(date: date, daysToCeremony: days, filmsLeft: snapshot.filmsLeft, filmsTotal: snapshot.filmsTotal,
                           tonight: tonight.first?.title, tonightExtra: max(tonight.count - 1, 0))
    }

    /// An entry now and one at each of the next `days` local midnights.
    static func timeline(_ snapshot: WidgetSnapshot, now: Date = .now, days: Int = 7, calendar: Calendar = .current) -> [WidgetEntry] {
        let today = PlanDay(now, calendar: calendar)
        let midnights = (1...max(days, 1)).map { today.adding(days: $0, calendar: calendar).startDate(calendar: calendar) }
        return ([now] + midnights).map { make(snapshot, at: $0, calendar: calendar) }
    }

    /// The WidgetKit refresh date after the last entry.
    static func refreshDate(now: Date = .now, days: Int = 7, calendar: Calendar = .current) -> Date {
        PlanDay(now, calendar: calendar).adding(days: days + 1, calendar: calendar).startDate(calendar: calendar)
    }

    static let sample = WidgetEntry(date: .now, daysToCeremony: 38, filmsLeft: 38, filmsTotal: 60, tonight: "Hamnet", tonightExtra: 0)
    static let empty = WidgetEntry(date: .now, daysToCeremony: nil, filmsLeft: 0, filmsTotal: 0, tonight: nil, tonightExtra: 0)
}
