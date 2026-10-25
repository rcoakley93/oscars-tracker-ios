import Foundation
import Observation

/// The active season and the app's config (P4-10): `get_season_facts()` and
/// `app_config`, loaded at launch and on return to the foreground, and cached
/// so the app opens offline with the last good copy. Lock decisions use the
/// server's clock, so a phone set to the wrong time still agrees with it.
@Observable
final class SeasonStore {
    private(set) var ceremony: Ceremony?
    private(set) var config = AppConfig.defaults
    private(set) var isRehearsal = false
    private(set) var state: LoadState = .idle
    /// Server time minus this phone's time, from the last load.
    private(set) var clockOffset: TimeInterval = 0

    var runtimeBuckets: [RuntimeBucket] { config.runtimeBuckets }

    private let data: any AppDataSource
    private let cacheKey: String?

    /// `cacheKey` nil keeps nothing between launches (previews and tests).
    init(data: any AppDataSource, cacheKey: String? = nil) {
        self.data = data
        self.cacheKey = cacheKey
        if let cached = Cache.read(cacheKey) {
            ceremony = cached.facts?.ceremony
            isRehearsal = cached.facts?.isRehearsal ?? false
            config = cached.config
            clockOffset = cached.clockOffset
            state = .loaded
        }
    }

    func load() async {
        if ceremony == nil { state = .loading }
        do {
            async let facts = data.seasonFacts()
            async let config = data.appConfig()
            let (loadedFacts, loadedConfig) = try await (facts, config)
            ceremony = loadedFacts?.ceremony
            isRehearsal = loadedFacts?.isRehearsal ?? false
            clockOffset = loadedFacts.map { $0.serverNow.timeIntervalSinceNow } ?? 0
            self.config = loadedConfig
            state = .loaded
            Cache.write(Cache(facts: loadedFacts, config: loadedConfig, clockOffset: clockOffset), cacheKey)
        } catch {
            // Keep the cached season; say it failed only when there's nothing.
            if ceremony == nil { state = .failed(AppError(error)) }
        }
    }

    /// Now, by the server's clock.
    func serverNow() -> Date {
        Date.now.addingTimeInterval(clockOffset)
    }

    func isBallotLocked(at now: Date? = nil) -> Bool {
        ceremony?.isBallotLocked(at: now ?? serverNow()) ?? false
    }

    /// Whether this build is older than `min_supported_build`.
    func needsUpdate(build: Int? = Bundle.main.buildNumber) -> Bool {
        guard let build else { return false }
        return build < config.minSupportedBuild
    }

    /// What the season ticker says (screens.md, section 2).
    enum Ticker: Equatable {
        case none
        /// No nominees yet; the date when `app_config` knows it.
        case beforeNominations(Date?)
        /// Before the ballot locks: days to the ceremony and films left to watch.
        case season(days: Int, filmsLeft: Int)
        /// Less than a day before the lock.
        case lockDay(locksAt: Date)
        /// The show is on (the five hours from its start).
        case live
        /// The month after the show: your final standing.
        case after
    }

    /// The season's phase by the server's clock; the hero and the ticker both read it.
    func phase(hasNominees: Bool = true, now: Date? = nil) -> SeasonPhase {
        SeasonPhase.resolve(ceremony: ceremony, nominationsAt: config.nominationsAt, hasNominees: hasNominees, now: now ?? serverNow())
    }

    func ticker(filmsLeft: Int, hasNominees: Bool = true, now: Date? = nil) -> Ticker {
        switch phase(hasNominees: hasNominees, now: now) {
        case .none, .locked: .none
        case .beforeNominations(let date): .beforeNominations(date)
        case .season(let days), .finalWeek(let days): .season(days: days, filmsLeft: filmsLeft)
        case .lockDay(let locksAt): .lockDay(locksAt: locksAt)
        case .live: .live
        case .after: .after
        }
    }

    /// Whole days until the ceremony, in the viewer's time zone; nil once it's past.
    func daysToCeremony(now: Date? = nil) -> Int? {
        guard let ceremony else { return nil }
        let days = PlanDay.today(now: now ?? serverNow()).days(until: PlanDay(ceremony.ceremonyAt))
        return days >= 0 ? days : nil
    }

    /// The last good season, in UserDefaults.
    private struct Cache: Codable {
        let facts: SeasonFacts?
        let config: AppConfig
        let clockOffset: TimeInterval

        static func read(_ key: String?) -> Cache? {
            guard let key, let stored = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(Cache.self, from: stored)
        }

        static func write(_ cache: Cache, _ key: String?) {
            guard let key, let encoded = try? JSONEncoder().encode(cache) else { return }
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

extension Bundle {
    /// `CFBundleVersion` as a number, for `min_supported_build`.
    var buildNumber: Int? {
        (infoDictionary?["CFBundleVersion"] as? String).flatMap(Int.init)
    }
}
