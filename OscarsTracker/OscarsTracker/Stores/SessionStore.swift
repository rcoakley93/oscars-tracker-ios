import CryptoKit
import Foundation
import Observation

/// Who is signed in: Sign in with Apple, Google, or email and password,
/// plus the forgot-password link.
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
    /// Set after a reset-password link signs you in; the app asks for a new
    /// password before anything else.
    private(set) var isChoosingNewPassword = false

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

    @discardableResult
    func signInWithApple(idToken: String, nonce: String) async -> Bool {
        await perform {
            state = .signedIn(userID: try await data.signInWithApple(idToken: idToken, nonce: nonce))
        }
    }

    @discardableResult
    func signInWithGoogle() async -> Bool {
        await perform {
            state = .signedIn(userID: try await data.signInWithGoogle())
        }
    }

    /// Shows an Apple sign-in failure the same way as the others.
    func appleSignInFailed(_ error: Error) {
        let error = AppError(error)
        self.error = error == .cancelled ? nil : error
    }

    @discardableResult
    func sendPasswordReset(email: String) async -> Bool {
        await perform {
            try await data.sendPasswordReset(email: email.trimmingCharacters(in: .whitespaces))
        }
    }

    /// An invite code from a link, kept (across sign-up too) until you're in
    /// the app, which then opens the join sheet with it.
    var pendingInviteCode: String? {
        get { access(keyPath: \.pendingInviteCode); return UserDefaults.standard.string(forKey: Self.inviteKey) }
        set { withMutation(keyPath: \.pendingInviteCode) { UserDefaults.standard.set(newValue, forKey: Self.inviteKey) } }
    }

    private static let inviteKey = "invite.pending"

    /// Handles invite links (keeping the code) and `oscarstracker://` links
    /// from auth emails, and returns whether it signed you in. A
    /// reset-password link then asks for a new password.
    @discardableResult
    func open(_ url: URL) async -> Bool {
        if let code = InviteLink.code(in: url) {
            pendingInviteCode = code
            return false
        }
        guard url.scheme == "oscarstracker" else { return false }
        let isReset = url.host() == "reset-password"
        return await perform {
            state = .signedIn(userID: try await data.openAuthLink(url))
            isChoosingNewPassword = isReset
        }
    }

    @discardableResult
    func chooseNewPassword(_ password: String) async -> Bool {
        guard PasswordRules.isValid(password) else {
            error = .weakPassword
            return false
        }
        let saved = await perform { try await data.updatePassword(password) }
        if saved { isChoosingNewPassword = false }
        return saved
    }

    func signOut() async {
        try? await data.signOut()
        state = .signedOut
        isChoosingNewPassword = false
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
            let error = AppError(error)
            self.error = error == .cancelled ? nil : error
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

/// The nonce for Sign in with Apple: Apple gets its SHA-256, Supabase the
/// raw value, so a stolen ID token can't be replayed.
nonisolated enum AppleNonce {
    static func make(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in characters.randomElement(using: &generator)! })
    }

    static func sha256(_ nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
