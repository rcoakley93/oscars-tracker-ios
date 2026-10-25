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
    /// The limits come from the server (`app_config`, P6-07); nil if it didn't say.
    case groupFull(limit: Int?)
    case tooManyGroups(limit: Int?)
    case invalidCredentials
    case emailInUse
    case weakPassword
    case linkExpired
    /// A pick made offline reached the server after the lock.
    case offlinePickLocked
    /// An admin call (P6-01) from an account that isn't the admin.
    case adminsOnly
    /// The server's name filter refused a username or group name (P6-16).
    case nameNotAllowed
    /// A name broke the length or character rules on the server.
    case nameInvalid
    /// The group's creator blocked you.
    case blockedFromGroup
    case tooManyReports
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
        case .groupFull(let limit): limit.map { "That group is full (\($0) members)." } ?? "That group is full."
        case .tooManyGroups(let limit):
            limit.map { "You're in \($0) groups already, the most you can join." } ?? "You're in as many groups as you can join."
        case .invalidCredentials: "That email and password don't match."
        case .emailInUse: "There's already an account with that email. Try signing in."
        case .weakPassword: "Use at least 8 characters, with a lowercase letter, an uppercase letter and a number."
        case .linkExpired: "That link has expired or was already used. Ask for a new one."
        case .offlinePickLocked: "A pick you made offline reached us after the ballot locked, so it wasn't saved."
        case .adminsOnly: "Only the admin can do that."
        case .nameNotAllowed: "That name isn't allowed. Try another."
        case .nameInvalid: "That name doesn't fit the rules. Try another."
        case .blockedFromGroup: "You can't join that group."
        case .tooManyReports: "You've sent a lot of reports today. Try again tomorrow, or email support@oscarstracker.com."
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
            self = AppError(serverMessage: error.message, code: error.code, hint: error.hint)
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

    /// The `raise exception` messages from supabase/migrations (Phase 1). The
    /// group limits are matched by SQLSTATE (`GRP01` group full, `GRP02` too
    /// many groups; hints `group_full` and `group_limit`), as are moderation's
    /// (`GRP03` blocked, `NAM01` and `NAM02` names, `RPT01` reports; P6-16),
    /// never by their numbers, so the server can change them (P6-07). The
    /// message still carries the number in use.
    init(serverMessage: String, code: String? = nil, hint: String? = nil) {
        let text = serverMessage.lowercased()
        let limit = text.firstMatch(of: /limit of (\d+)/).flatMap { Int($0.1) }
        if code == "GRP01" || hint == "group_full" { self = .groupFull(limit: limit) }
        else if code == "GRP02" || hint == "group_limit" { self = .tooManyGroups(limit: limit) }
        else if code == "GRP03" || hint == "blocked" { self = .blockedFromGroup }
        else if code == "NAM01" || hint == "name_not_allowed" { self = .nameNotAllowed }
        else if code == "NAM02" || hint == "name_invalid" { self = .nameInvalid }
        else if code == "RPT01" || hint == "report_limit" { self = .tooManyReports }
        else if text.contains("ballot is locked") { self = .ballotLocked }
        else if text.contains("invalid invite code") { self = .invalidInviteCode }
        else if text.contains("already a member") { self = .alreadyInGroup }
        else if text.contains("creator of this group") { self = .ownGroup }
        // Before the server sent codes: "maximum limit of N members/groups".
        else if text.contains("maximum limit of"), text.contains("members") { self = .groupFull(limit: limit) }
        else if text.contains("maximum limit of"), text.contains("groups") { self = .tooManyGroups(limit: limit) }
        else if text.contains("not authenticated") { self = .notSignedIn }
        else if text.contains("admins only") { self = .adminsOnly }
        else { self = .server(serverMessage) }
    }
}

/// So SwiftUI's error alerts and anything that reads `localizedDescription`
/// get the friendly text, never a raw server message.
extension AppError: LocalizedError {
    var errorDescription: String? { message }
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
