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

    /// Whole days until the ceremony, in the viewer's time zone; nil once it's past.
    func daysToCeremony(now: Date = .now) -> Int? {
        guard let ceremony else { return nil }
        let days = PlanDay.today(now: now).days(until: PlanDay(ceremony.ceremonyAt))
        return days >= 0 ? days : nil
    }
}
