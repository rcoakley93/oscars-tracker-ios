import AuthenticationServices
import Foundation
import Supabase

/// Errors the app shows to people. Messages are written once, plainly, in
/// both voices (docs/design/voice.md: no jokes in errors that cost the user
/// something).
nonisolated enum AppError: Error, Equatable, Sendable {
    case offline
    case notSignedIn
    case ballotLocked
    case invalidInviteCode
    case alreadyInGroup
    case ownGroup
    case groupFull
    case tooManyGroups
    case invalidCredentials
    case emailInUse
    case weakPassword
    case linkExpired
    /// The person closed the Apple or Google sheet: show nothing.
    case cancelled
    case server(String)

    var message: String {
        switch self {
        case .offline: "You're offline. We'll try again when you're back."
        case .notSignedIn: "Please sign in again."
        case .ballotLocked: "The ballot is locked, so picks can't change now."
        case .invalidInviteCode: "That invite code didn't match a group. Check it and try again."
        case .alreadyInGroup: "You're already in that group."
        case .ownGroup: "That's your own group, so you're already in it."
        case .groupFull: "That group is full (12 members)."
        case .tooManyGroups: "You're in 5 groups already, the most you can join."
        case .invalidCredentials: "That email and password don't match."
        case .emailInUse: "There's already an account with that email. Try signing in."
        case .weakPassword: "Use at least 8 characters, with a lowercase letter, an uppercase letter and a number."
        case .linkExpired: "That link has expired or was already used. Ask for a new one."
        case .cancelled: ""
        case .server: "Something went wrong on our side. Please try again."
        }
    }

    /// Maps errors from Supabase and the network to something people can act on.
    init(_ error: Error) {
        if let error = error as? AppError {
            self = error
            return
        }
        if let error = error as? URLError,
           [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .dataNotAllowed].contains(error.code) {
            self = .offline
            return
        }
        if let error = error as? ASAuthorizationError, error.code == .canceled {
            self = .cancelled
            return
        }
        if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
            self = .cancelled
            return
        }
        if let error = error as? PostgrestError {
            self = AppError(serverMessage: error.message)
            return
        }
        if let error = error as? AuthError {
            let text = String(describing: error).lowercased()
            if text.contains("invalid login") || text.contains("invalid_credentials") { self = .invalidCredentials; return }
            if text.contains("already registered") || text.contains("user_already_exists") { self = .emailInUse; return }
            if text.contains("weak_password") || text.contains("password should") { self = .weakPassword; return }
            if text.contains("otp_expired") || text.contains("flow_state") || text.contains("code verifier") { self = .linkExpired; return }
            if text.contains("session") && text.contains("missing") { self = .notSignedIn; return }
            self = .server(String(describing: error))
            return
        }
        self = .server(String(describing: error))
    }

    /// The `raise exception` messages from supabase/migrations (Phase 1).
    init(serverMessage: String) {
        let text = serverMessage.lowercased()
        if text.contains("ballot is locked") { self = .ballotLocked }
        else if text.contains("invalid invite code") { self = .invalidInviteCode }
        else if text.contains("already a member") { self = .alreadyInGroup }
        else if text.contains("creator of this group") { self = .ownGroup }
        else if text.contains("maximum limit of 12 members") { self = .groupFull }
        else if text.contains("maximum limit of 5 groups") { self = .tooManyGroups }
        else if text.contains("not authenticated") { self = .notSignedIn }
        else { self = .server(serverMessage) }
    }
}

/// Where a store's data stands. Views show a skeleton, the content or an
/// error from this; data already loaded stays visible while it refreshes.
nonisolated enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(AppError)

    var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
