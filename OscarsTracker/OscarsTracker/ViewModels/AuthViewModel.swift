import Foundation
import Supabase
import AuthenticationServices
import UIKit

/// Manages authentication state and operations for the app.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var needsOnboarding = false

    private let supabase = SupabaseClientManager.shared.client

    init() {
        Task {
            await checkSession()
        }
    }

    /// Sign in with Google OAuth
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get the OAuth URL from Supabase
            let url = try await supabase.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "oscarstracker://auth/callback")
            )

            // Open the URL in ASWebAuthenticationSession
            let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: "oscarstracker"
                ) { callbackURL, error in
                    if let error = error {
                        if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                            continuation.resume(throwing: AuthError.sessionNotFound)
                        } else {
                            continuation.resume(throwing: error)
                        }
                        return
                    }

                    guard let callbackURL = callbackURL else {
                        continuation.resume(throwing: AuthError.sessionNotFound)
                        return
                    }

                    continuation.resume(returning: callbackURL)
                }

                session.presentationContextProvider = WebAuthPresentationContextProvider.shared
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }

            // Handle the callback URL
            let session = try await supabase.auth.session(from: callbackURL)
            currentUser = session.user

            // Check if user has a profile (existing user) or needs onboarding (new user)
            await checkIfNeedsOnboarding()

            isAuthenticated = true
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // User cancelled, don't show error
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = mapGoogleAuthError(error)
        } catch {
            errorMessage = "Failed to sign in with Google. Please try again."
        }

        isLoading = false
    }

    /// Check if a new OAuth user needs onboarding
    private func checkIfNeedsOnboarding() async {
        guard let userId = currentUser?.id else { return }

        do {
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            // If no profile exists or username is empty, user needs onboarding
            if profiles.isEmpty || profiles.first?.username?.isEmpty == true {
                needsOnboarding = true
            } else {
                needsOnboarding = false
            }
        } catch {
            // If we can't check, assume they need onboarding
            needsOnboarding = true
        }
    }

    /// Map Google OAuth errors to user-friendly messages
    private func mapGoogleAuthError(_ error: AuthError) -> String {
        switch error {
        case .api(let apiError):
            if let message = apiError.message?.lowercased() {
                if message.contains("cancelled") || message.contains("canceled") {
                    return "Sign in was cancelled."
                }
                if message.contains("network") {
                    return "Network error. Please check your connection."
                }
            }
            return "Failed to sign in with Google. Please try again."
        case .sessionNotFound:
            return "Sign in was cancelled."
        default:
            return "Failed to sign in with Google. Please try again."
        }
    }

    /// Check if there's an existing session
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = mapAuthError(error)
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, confirmPassword: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard let passwordError = validatePassword(password) else {
            // Password is valid, continue
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                let response = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                currentUser = response.user
                isAuthenticated = true
                needsOnboarding = true
            } catch let error as AuthError {
                errorMessage = mapSignUpError(error)
            } catch {
                errorMessage = "An unexpected error occurred. Please try again."
            }

            isLoading = false
            return
        }

        errorMessage = passwordError
    }

    /// Sign out the current user
    func signOut() async {
        isLoading = true

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            needsOnboarding = false
        } catch {
            errorMessage = "Failed to sign out. Please try again."
        }

        isLoading = false
    }

    /// Validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Validate password strength requirements
    /// Returns nil if valid, or an error message if invalid
    func validatePassword(_ password: String) -> String? {
        if password.count < 8 {
            return "Password must be at least 8 characters long."
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        if !hasUppercase {
            return "Password must contain at least one uppercase letter."
        }
        if !hasLowercase {
            return "Password must contain at least one lowercase letter."
        }
        if !hasNumber {
            return "Password must contain at least one number."
        }

        return nil
    }

    /// Check password strength level (for UI indicator)
    func passwordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .none
        }

        var score = 0

        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }

        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }

    /// Map Supabase auth errors to user-friendly messages
    private func mapAuthError(_ error: AuthError) -> String {
        switch error {
        case .api(let apiError):
            if let message = apiError.message?.lowercased() {
                if message.contains("invalid") || message.contains("credentials") {
                    return "Invalid email or password. Please try again."
                }
                if message.contains("not found") {
                    return "No account found with this email."
                }
                if message.contains("too many") {
                    return "Too many attempts. Please try again later."
                }
            }
            return "Authentication failed. Please check your credentials."
        default:
            return "Authentication failed. Please try again."
        }
    }

    /// Map Supabase sign up errors to user-friendly messages
    private func mapSignUpError(_ error: AuthError) -> String {
        switch error {
        case .api(let apiError):
            if let message = apiError.message?.lowercased() {
                if message.contains("already registered") || message.contains("already exists") {
                    return "An account with this email already exists."
                }
                if message.contains("password") && message.contains("weak") {
                    return "Password is too weak. Please use a stronger password."
                }
                if message.contains("email") && message.contains("invalid") {
                    return "Please enter a valid email address."
                }
                if message.contains("too many") {
                    return "Too many attempts. Please try again later."
                }
            }
            return "Sign up failed. Please try again."
        default:
            return "Sign up failed. Please try again."
        }
    }

    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }

    /// Complete onboarding
    func completeOnboarding() {
        needsOnboarding = false
    }
}

/// Password strength levels for UI display
enum PasswordStrength {
    case none
    case weak
    case medium
    case strong

    var color: String {
        switch self {
        case .none:
            return "textMuted"
        case .weak:
            return "destructive"
        case .medium:
            return "goldPrimary"
        case .strong:
            return "green"
        }
    }

    var label: String {
        switch self {
        case .none:
            return ""
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
}

/// Provides the presentation context for ASWebAuthenticationSession
final class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    private override init() {
        super.init()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
