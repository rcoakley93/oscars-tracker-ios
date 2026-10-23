import Foundation

/// One Academy Awards ceremony: a season. 98 is the 2026 season, 99 the 2027 one.
nonisolated struct Ceremony: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let number: Int
    let name: String
    let ceremonyAt: Date
    let ballotLockAt: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, number, name
        case ceremonyAt = "ceremony_at"
        case ballotLockAt = "ballot_lock_at"
        case isActive = "is_active"
    }

    /// Whether the ballot is locked at `now`. The server enforces the lock; this
    /// only decides what the app shows.
    func isBallotLocked(at now: Date = .now) -> Bool {
        now >= ballotLockAt
    }
}
