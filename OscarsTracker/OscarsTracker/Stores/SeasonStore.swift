import Foundation
import Observation

/// The active ceremony: its name, the ceremony time and the ballot lock.
/// Phase 2 (P2-07) moves this to a server RPC that also reports the lock.
@Observable
final class SeasonStore {
    private(set) var ceremony: Ceremony?
    private(set) var state: LoadState = .idle

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load() async {
        state = .loading
        do {
            ceremony = try await data.activeCeremony()
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func isBallotLocked(at now: Date = .now) -> Bool {
        ceremony?.isBallotLocked(at: now) ?? false
    }

    /// What the season ticker says. Until the season facts land (P4-10) it
    /// knows only the season and lock day, from the ballot lock; nominations
    /// day, live and after show nothing.
    enum Ticker: Equatable {
        case none
        /// Before the ballot locks: days to the ceremony and films left to watch.
        case season(days: Int, filmsLeft: Int)
        /// Less than a day before the lock.
        case lockDay(locksAt: Date)
    }

    func ticker(filmsLeft: Int, now: Date = .now) -> Ticker {
        guard let ceremony, now < ceremony.ballotLockAt else { return .none }
        if ceremony.ballotLockAt.timeIntervalSince(now) < 24 * 60 * 60 {
            return .lockDay(locksAt: ceremony.ballotLockAt)
        }
        guard let days = daysToCeremony(now: now) else { return .none }
        return .season(days: days, filmsLeft: filmsLeft)
    }

    /// Whole days until the ceremony, in the viewer's time zone; nil once it's past.
    func daysToCeremony(now: Date = .now) -> Int? {
        guard let ceremony else { return nil }
        let days = PlanDay.today(now: now).days(until: PlanDay(ceremony.ceremonyAt))
        return days >= 0 ? days : nil
    }
}
