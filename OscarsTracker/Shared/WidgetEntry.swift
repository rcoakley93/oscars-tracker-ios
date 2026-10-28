import Foundation
import WidgetKit

/// One moment of a widget's timeline: what it shows from `date` until the
/// next entry. The provider hands WidgetKit one per local midnight, plus one
/// at each turn of the season (lock day, the lock, the show), so the widget
/// rolls over without the app running.
nonisolated struct WidgetEntry: TimelineEntry, Equatable, Sendable {
    /// Where the season is at `date` (P11-02), from the snapshot's dates.
    enum Phase: Equatable, Sendable {
        /// Nothing written yet: the app hasn't loaded a season.
        case empty
        /// Contenders or shortlists, before the nominees are in.
        case contenders(daysToNominations: Int?, shortlisted: Bool)
        /// Nominees are in and the ballot is open.
        case season(daysToCeremony: Int)
        /// Less than a day before the ballot locks.
        case lockDay(locksAt: Date)
        /// The ballot is locked and the show isn't over.
        case showtime(startsAt: Date)
        /// The month after the show.
        case results
        /// After that, until the next season's first snapshot.
        case offSeason
    }

    static let lockDayLength: TimeInterval = 24 * 60 * 60
    static let showLength: TimeInterval = 5 * 60 * 60
    static let resultsLength: TimeInterval = 30 * 24 * 60 * 60

    let date: Date
    let phase: Phase
    let filmsWatched: Int
    let filmsTotal: Int
    let posters: [WidgetSnapshot.PosterColor]
    let categoriesPicked: Int
    let categoriesTotal: Int
    let results: WidgetSnapshot.Results?
    let ceremonyNumber: Int?
    let nominationsAt: Date?
    /// The unwatched film planned for this day, if any.
    let tonight: String?
    /// More than one is planned for tonight.
    let tonightExtra: Int
    /// The next film planned after today, for when nothing is on tonight.
    let next: WidgetSnapshot.PlannedFilm?

    var filmsLeft: Int { max(filmsTotal - filmsWatched, 0) }

    static func make(_ snapshot: WidgetSnapshot, at date: Date, calendar: Calendar = .current) -> WidgetEntry {
        let today = PlanDay(date, calendar: calendar)
        let tonight = snapshot.plan.filter { $0.day == today }
        return WidgetEntry(date: date, phase: phase(snapshot, at: date, calendar: calendar),
                           filmsWatched: min(snapshot.filmsWatched, snapshot.filmsTotal), filmsTotal: snapshot.filmsTotal,
                           posters: snapshot.posters ?? [], categoriesPicked: snapshot.categoriesPicked ?? 0,
                           categoriesTotal: snapshot.categoriesTotal ?? 0, results: snapshot.results,
                           ceremonyNumber: snapshot.ceremonyNumber, nominationsAt: snapshot.nominationsAt,
                           tonight: tonight.first?.title, tonightExtra: max(tonight.count - 1, 0),
                           next: snapshot.plan.first { $0.day > today })
    }

    static func phase(_ snapshot: WidgetSnapshot, at date: Date, calendar: Calendar = .current) -> Phase {
        let today = PlanDay(date, calendar: calendar)
        func days(until day: Date) -> Int { today.days(until: PlanDay(day, calendar: calendar), calendar: calendar) }
        guard let ceremonyAt = snapshot.ceremonyAt else {
            return snapshot.filmsTotal > 0 ? .contenders(daysToNominations: nil, shortlisted: snapshot.stage == .shortlisted) : .empty
        }
        let locksAt = snapshot.ballotLockAt ?? ceremonyAt
        if date >= ceremonyAt.addingTimeInterval(showLength) {
            return date < ceremonyAt.addingTimeInterval(resultsLength) ? .results : .offSeason
        }
        if date >= locksAt { return .showtime(startsAt: ceremonyAt) }
        if !snapshot.hasNominees {
            let toNominations = snapshot.nominationsAt.map(days(until:)).flatMap { $0 >= 0 ? $0 : nil }
            return .contenders(daysToNominations: toNominations, shortlisted: snapshot.stage == .shortlisted)
        }
        if locksAt.timeIntervalSince(date) < lockDayLength { return .lockDay(locksAt: locksAt) }
        return .season(daysToCeremony: max(days(until: ceremonyAt), 0))
    }

    /// An entry now, one at each of the next `days` local midnights, and one
    /// at each turn of the season in between.
    static func timeline(_ snapshot: WidgetSnapshot, now: Date = .now, days: Int = 7, calendar: Calendar = .current) -> [WidgetEntry] {
        let today = PlanDay(now, calendar: calendar)
        let midnights = (1...max(days, 1)).map { today.adding(days: $0, calendar: calendar).startDate(calendar: calendar) }
        var turns: [Date] = []
        if let ceremonyAt = snapshot.ceremonyAt {
            let locksAt = snapshot.ballotLockAt ?? ceremonyAt
            turns = [locksAt.addingTimeInterval(-lockDayLength), locksAt, ceremonyAt,
                     ceremonyAt.addingTimeInterval(showLength), ceremonyAt.addingTimeInterval(resultsLength)]
        }
        let last = midnights.last ?? now
        let dates = Set(midnights + turns.filter { $0 > now && $0 < last })
        return ([now] + dates.sorted()).map { make(snapshot, at: $0, calendar: calendar) }
    }

    /// The WidgetKit refresh date after the last entry.
    static func refreshDate(now: Date = .now, days: Int = 7, calendar: Calendar = .current) -> Date {
        PlanDay(now, calendar: calendar).adding(days: days + 1, calendar: calendar).startDate(calendar: calendar)
    }
}

// MARK: - Samples, for previews and the widget gallery

extension WidgetEntry {
    private static let posterSamples: [WidgetSnapshot.PosterColor] = [
        .init(red: 0.78, green: 0.47, blue: 0.16), .init(red: 0.12, green: 0.31, blue: 0.37), .init(red: 0.48, green: 0.12, blue: 0.17),
        .init(red: 0.54, green: 0.35, blue: 0.20), .init(red: 0.17, green: 0.29, blue: 0.42), .init(red: 0.75, green: 0.54, blue: 0.29),
        .init(red: 0.31, green: 0.42, blue: 0.23), .init(red: 0.42, green: 0.25, blue: 0.42), .init(red: 0.69, green: 0.33, blue: 0.23),
        .init(red: 0.18, green: 0.36, blue: 0.35), .init(red: 0.60, green: 0.48, blue: 0.31), .init(red: 0.23, green: 0.25, blue: 0.42),
    ]

    private static func sample(_ phase: Phase, watched: Int, of total: Int, picked: Int = 0, results: WidgetSnapshot.Results? = nil,
                               tonight: String? = nil, extra: Int = 0, next: WidgetSnapshot.PlannedFilm? = nil) -> WidgetEntry {
        WidgetEntry(date: .now, phase: phase, filmsWatched: watched, filmsTotal: total, posters: posterSamples,
                    categoriesPicked: picked, categoriesTotal: 24, results: results, ceremonyNumber: 99,
                    nominationsAt: .now.addingTimeInterval(86 * 86400), tonight: tonight, tonightExtra: extra, next: next)
    }

    static let contenders = sample(.contenders(daysToNominations: 86, shortlisted: false), watched: 7, of: 40, tonight: "Project Hail Mary")
    static let shortlists = sample(.contenders(daysToNominations: 32, shortlisted: true), watched: 14, of: 52,
                                   next: .init(title: "Digger", day: PlanDay(.now.addingTimeInterval(2 * 86400))))
    static let sample = sample(.season(daysToCeremony: 38), watched: 22, of: 60, picked: 9, tonight: "Wuthering Heights", extra: 1)
    static let lockDay = sample(.lockDay(locksAt: .now.addingTimeInterval(4 * 3600 + 12 * 60)), watched: 51, of: 60, picked: 21)
    static let showtime = sample(.showtime(startsAt: .now.addingTimeInterval(3600)), watched: 54, of: 60, picked: 24)
    static let results = sample(.results, watched: 54, of: 60, picked: 24, results: .init(correct: 15, total: 24, rank: 3, ranked: 212))
    static let offSeason = sample(.offSeason, watched: 54, of: 60, picked: 24, results: .init(correct: 15, total: 24, rank: 3, ranked: 212))
    static let empty = WidgetEntry(date: .now, phase: .empty, filmsWatched: 0, filmsTotal: 0, posters: [], categoriesPicked: 0,
                                   categoriesTotal: 0, results: nil, ceremonyNumber: nil, nominationsAt: nil, tonight: nil,
                                   tonightExtra: 0, next: nil)

    /// Every state, for previews.
    static let allSamples: [(name: String, entry: WidgetEntry)] = [
        ("Contenders", contenders), ("Shortlists", shortlists), ("Nominated", sample), ("Lock day", lockDay),
        ("Showtime", showtime), ("Results", results), ("Off season", offSeason), ("Empty", empty),
    ]
}
