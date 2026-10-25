import Foundation

/// The active season from `get_season_facts()` (P2-07): the ceremony, its
/// lock, and the server's clock, so a phone with the wrong time still locks
/// the ballot when the server does. Testers get the rehearsal ceremony.
nonisolated struct SeasonFacts: Codable, Equatable, Sendable {
    let id: Int
    let number: Int
    let name: String
    let ceremonyAt: Date
    let ballotLockAt: Date
    let isLocked: Bool
    let isRehearsal: Bool
    let serverNow: Date

    enum CodingKeys: String, CodingKey {
        case id, number, name
        case ceremonyAt = "ceremony_at"
        case ballotLockAt = "ballot_lock_at"
        case isLocked = "is_locked"
        case isRehearsal = "is_rehearsal"
        case serverNow = "server_now"
    }

    var ceremony: Ceremony {
        Ceremony(id: id, number: number, name: name, ceremonyAt: ceremonyAt, ballotLockAt: ballotLockAt, isActive: true)
    }
}

/// `app_config` (P2-06): what the season can change without a release.
nonisolated struct AppConfig: Codable, Equatable, Sendable {
    /// Builds below this (`CFBundleVersion`) are asked to update.
    var minSupportedBuild = 0
    var featureFlags: [String: Bool] = [:]
    var runtimeBuckets = RuntimeBucket.defaults
    /// When the nominations are announced, for the ticker before them; optional.
    var nominationsAt: Date?

    static let defaults = AppConfig()

    /// Oscar night: winners revealed as they're announced (P6-02).
    static let liveMode = "live_mode"

    func isEnabled(_ flag: String) -> Bool {
        featureFlags[flag] ?? false
    }
}
