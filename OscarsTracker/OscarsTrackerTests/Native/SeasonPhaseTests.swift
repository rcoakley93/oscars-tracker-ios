import Foundation
import Testing
@testable import OscarsTracker

@Suite("Season phase")
struct SeasonPhaseTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let ceremonyAt = Date(timeIntervalSince1970: 1_800_000_000)
    private var lockAt: Date { ceremonyAt.addingTimeInterval(-2 * 3600) }
    private var ceremony: Ceremony {
        Ceremony(id: 1, number: 99, name: "99th Academy Awards", ceremonyAt: ceremonyAt, ballotLockAt: lockAt, isActive: true)
    }
    private let nominationsAt = Date(timeIntervalSince1970: 1_790_000_000)

    private func phase(_ now: Date, hasNominees: Bool = true) -> SeasonPhase {
        SeasonPhase.resolve(ceremony: ceremony, nominationsAt: nominationsAt, hasNominees: hasNominees, now: now, calendar: calendar)
    }

    @Test func noSeasonFactsMeansNoPhase() {
        #expect(SeasonPhase.resolve(ceremony: nil, now: ceremonyAt) == .none)
    }

    @Test func showsTheShortlistUntilNominees() {
        #expect(phase(ceremonyAt.addingTimeInterval(-60 * 86400), hasNominees: false) == .beforeNominations(nominationsAt))
    }

    @Test func countsDaysThenTurnsFinalWeek() {
        #expect(phase(ceremonyAt.addingTimeInterval(-30 * 86400)) == .season(days: 30))
        if case .finalWeek(let days) = phase(ceremonyAt.addingTimeInterval(-5 * 86400)) { #expect((4...5).contains(days)) } else { Issue.record("not final week") }
        if case .season = phase(ceremonyAt.addingTimeInterval(-9 * 86400)) {} else { Issue.record("not season") }
    }

    @Test func lockDayStartsADayBeforeTheLock() {
        #expect(phase(lockAt.addingTimeInterval(-3 * 3600)) == .lockDay(locksAt: lockAt))
        #expect(phase(lockAt.addingTimeInterval(-24 * 3600 - 1)) != .lockDay(locksAt: lockAt))
    }

    @Test func lockedBetweenTheLockAndTheShow() {
        if case .locked = phase(lockAt.addingTimeInterval(60)) {} else { Issue.record("not locked") }
    }

    @Test func liveThenAfterThenNothing() {
        #expect(phase(ceremonyAt.addingTimeInterval(60)) == .live)
        #expect(phase(ceremonyAt.addingTimeInterval(6 * 3600)) == .after)
        #expect(phase(ceremonyAt.addingTimeInterval(40 * 86400)) == .none)
    }

    @Test func paceOnlyWhileItCanBeMet() {
        #expect(SeasonPhase.showsPace(.season(days: 30), filmsLeft: 20, days: 30))
        #expect(!SeasonPhase.showsPace(.season(days: 30), filmsLeft: 0, days: 30))
        #expect(!SeasonPhase.showsPace(.finalWeek(days: 2), filmsLeft: 30, days: 2))
        #expect(!SeasonPhase.showsPace(.lockDay(locksAt: lockAt), filmsLeft: 3, days: 1))
        #expect(!SeasonPhase.showsPace(.live, filmsLeft: 3, days: 0))
    }
}
