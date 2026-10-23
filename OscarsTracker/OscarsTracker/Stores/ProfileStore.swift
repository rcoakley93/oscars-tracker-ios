import Foundation
import Observation

/// Your profile: username, and deleting the account.
@Observable
final class ProfileStore {
    private(set) var profile: Profile?
    private(set) var state: LoadState = .idle
    private(set) var isWorking = false
    var actionError: AppError?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    /// A signed-in account without a username goes through onboarding first.
    var needsUsername: Bool {
        state == .loaded && (profile?.username ?? "").isEmpty
    }

    func load(userID: String) async {
        state = .loading
        do {
            profile = try await data.profile(userID: userID)
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

    /// Really deletes the account. The caller signs out only when this returns true.
    func deleteAccount() async -> Bool {
        await working {
            try await data.deleteAccount()
            profile = nil
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
        state = .idle
    }
}
