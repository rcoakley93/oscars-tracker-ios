import Foundation
import Supabase

/// Manages authentication state and operations for the app.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private let supabase = SupabaseClientManager.shared.client

    init() {
        Task {
            await checkSession()
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

    /// Sign out the current user
    func signOut() async {
        isLoading = true

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
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

    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
