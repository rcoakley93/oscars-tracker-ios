import Foundation
import Observation

/// Your profile: username, email and sign-in method, password, past
/// seasons, and deleting the account.
@Observable
final class ProfileStore {
    private(set) var profile: Profile?
    private(set) var account: Account?
    private(set) var history: [SeasonResult] = []
    /// Past seasons opened from Profile (P12-06), by ceremony id.
    private(set) var archives: [Int: SeasonArchive] = [:]
    private(set) var archiveStates: [Int: LoadState] = [:]
    private(set) var state: LoadState = .idle
    private(set) var isWorking = false
    var actionError: AppError?

    private let data: any AppDataSource
    private let cache: OfflineCache

    init(data: any AppDataSource, cache: OfflineCache = .none) {
        self.data = data
        self.cache = cache
    }

    /// A signed-in account without a username goes through onboarding first.
    var needsUsername: Bool {
        state == .loaded && (profile?.username ?? "").isEmpty
    }

    func load(userID: String) async {
        state = .loading
        do {
            profile = try await data.profile(userID: userID)
            account = await data.account()
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// The message to show for a username, or nil when it's fine.
    static func usernameProblem(_ username: String) -> String? {
        ValidationService.validateUsername(username).errorMessage
    }

    func setUsername(_ username: String, userID: String) async -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.usernameProblem(trimmed) == nil else { return false }
        return await working {
            try await data.updateUsername(trimmed, userID: userID)
            profile = try await data.profile(userID: userID)
        }
    }

    /// Past seasons, for the Profile. Nothing to show is fine: it's your first.
    func loadHistory() async {
        history = (try? await data.seasonHistory()) ?? history
    }

    /// A past season's archive: the cached copy at once, then the server's,
    /// which is cached in turn. Offline with a cached copy is no error: a past
    /// season doesn't change.
    func loadArchive(ceremonyID: Int, userID: String) async {
        if archives[ceremonyID] == nil, let cached = cache.archive(ceremonyID: ceremonyID, for: userID) {
            archives[ceremonyID] = cached
        }
        archiveStates[ceremonyID] = .loading
        do {
            let archive = try await data.seasonArchive(ceremonyID: ceremonyID)
            archives[ceremonyID] = archive
            cache.save(archive, for: userID)
            archiveStates[ceremonyID] = .loaded
        } catch {
            archiveStates[ceremonyID] = archives[ceremonyID] == nil ? .failed(AppError(error)) : .loaded
        }
    }

    func archiveState(_ ceremonyID: Int) -> LoadState {
        archiveStates[ceremonyID] ?? .idle
    }

    /// For email accounts; the README's rules (8 characters, upper, lower, number).
    func changePassword(_ password: String) async -> Bool {
        guard PasswordRules.isValid(password) else {
            actionError = .weakPassword
            return false
        }
        return await working { try await data.updatePassword(password) }
    }

    /// Really deletes the account. A Sign in with Apple account first revokes
    /// its Apple tokens with a fresh authorization code, and nothing is
    /// deleted if that fails. The caller signs out only when this returns true.
    func deleteAccount(appleAuthorizationCode: String? = nil) async -> Bool {
        await working {
            if account?.provider == .apple {
                guard let code = appleAuthorizationCode else { throw AppError.server("Apple authorization code missing") }
                try await data.revokeApple(authorizationCode: code)
            }
            try await data.deleteAccount()
            profile = nil
            account = nil
            history = []
            archives = [:]
            archiveStates = [:]
        }
    }

    private func working(_ work: () async throws -> Void) async -> Bool {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await work()
            return true
        } catch {
            actionError = AppError(error)
            return false
        }
    }

    func reset() {
        profile = nil
        account = nil
        history = []
        archives = [:]
        archiveStates = [:]
        state = .idle
    }
}
