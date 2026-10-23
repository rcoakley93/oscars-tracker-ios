import Foundation
import Observation

/// Who is signed in. Email and password for now; Sign in with Apple and
/// Google arrive in P3-09.
@Observable
final class SessionStore {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(userID: String)
    }

    enum SignUpResult: Equatable {
        case signedIn
        /// The project asked for email confirmation before the first sign-in.
        case checkEmail
    }

    private(set) var state: State = .checking
    private(set) var isWorking = false
    private(set) var error: AppError?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    var userID: String? {
        if case .signedIn(let id) = state { id } else { nil }
    }

    func restore() async {
        state = (await data.currentUserID()).map { .signedIn(userID: $0) } ?? .signedOut
    }

    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        await perform {
            let id = try await data.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            state = .signedIn(userID: id)
        }
    }

    func signUp(email: String, password: String) async -> SignUpResult? {
        guard PasswordRules.isValid(password) else {
            error = .weakPassword
            return nil
        }
        var result: SignUpResult?
        await perform {
            if let id = try await data.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password) {
                state = .signedIn(userID: id)
                result = .signedIn
            } else {
                result = .checkEmail
            }
        }
        return result
    }

    func signOut() async {
        try? await data.signOut()
        state = .signedOut
    }

    /// After the account is deleted elsewhere (ProfileStore), the session is gone.
    func didDeleteAccount() {
        state = .signedOut
    }

    func clearError() {
        error = nil
    }

    @discardableResult
    private func perform(_ work: () async throws -> Void) async -> Bool {
        isWorking = true
        error = nil
        defer { isWorking = false }
        do {
            try await work()
            return true
        } catch {
            self.error = AppError(error)
            return false
        }
    }
}

/// The Supabase password policy (season plan P1-05): at least 8 characters,
/// with a lowercase letter, an uppercase letter and a digit.
nonisolated enum PasswordRules {
    static func isValid(_ password: String) -> Bool {
        password.count >= 8
            && password.contains(where: \.isLowercase)
            && password.contains(where: \.isUppercase)
            && password.contains(where: \.isNumber)
    }
}
