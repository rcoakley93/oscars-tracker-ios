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
    /// Most people in a group, creator included; `group_member_limit`.
    var groupMemberLimit = 50
    /// Most groups a person creates or joins; `user_group_limit`.
    var userGroupLimit = 5
    /// Which list Films shows; `feature_flags.list_stage` (2.1). Missing means
    /// the nominees, as before 2.1.
    var listStage = ListStage.nominated
    /// Seasonal lines that replace the built-in ones (P10-04);
    /// `{"<key>": {"host": "…", "classic": "…"}}`. See `Copy.applying`.
    var copyOverrides: CopyOverrides = [:]

    static let defaults = AppConfig()

    /// Oscar night: winners revealed as they're announced (P6-02).
    static let liveMode = "live_mode"
    /// The ceremony on the Lock Screen and in the Dynamic Island (P6-03).
    static let liveActivity = "live_activity"

    func isEnabled(_ flag: String) -> Bool {
        featureFlags[flag] ?? false
    }
}

/// Written by older builds without the newer keys, so every field decodes
/// with its default: a saved season cache stays readable after an update.
extension AppConfig {
    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppConfig()
        minSupportedBuild = try c.decodeIfPresent(Int.self, forKey: .minSupportedBuild) ?? d.minSupportedBuild
        featureFlags = try c.decodeIfPresent([String: Bool].self, forKey: .featureFlags) ?? d.featureFlags
        runtimeBuckets = try c.decodeIfPresent([RuntimeBucket].self, forKey: .runtimeBuckets) ?? d.runtimeBuckets
        nominationsAt = try c.decodeIfPresent(Date.self, forKey: .nominationsAt)
        groupMemberLimit = try c.decodeIfPresent(Int.self, forKey: .groupMemberLimit) ?? d.groupMemberLimit
        userGroupLimit = try c.decodeIfPresent(Int.self, forKey: .userGroupLimit) ?? d.userGroupLimit
        listStage = (try? c.decodeIfPresent(ListStage.self, forKey: .listStage)) ?? d.listStage
        copyOverrides = (try? c.decodeIfPresent(CopyOverrides.self, forKey: .copyOverrides)) ?? d.copyOverrides
    }
}
