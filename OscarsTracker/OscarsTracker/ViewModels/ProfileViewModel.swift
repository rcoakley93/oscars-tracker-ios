import Combine
import Foundation
import Supabase

/// Manages profile state and data.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var watchedCount: Int = 0
    @Published var predictionsMade: Int = 0
    @Published var correctPredictions: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Edit username state
    @Published var isEditingUsername = false
    @Published var editedUsername = ""
    @Published var isSavingUsername = false
    @Published var usernameSuccessMessage: String?

    private let supabase = SupabaseClientManager.shared.client

    /// Common profanity words to filter (basic list)
    private let profanityList: Set<String> = [
        "fuck", "shit", "ass", "bitch", "damn", "crap", "bastard",
        "dick", "pussy", "cock", "cunt", "whore", "slut", "fag",
        "nigger", "nigga", "retard", "nazi", "hitler"
    ]

    /// Initialize
    init() {}

    /// Load profile data from Supabase
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let userId = try? await supabase.auth.session.user.id.uuidString else {
                isLoading = false
                errorMessage = "Not logged in"
                return
            }

            // Load profile
            let profileResponse: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            profile = profileResponse.first

            // Load watched count
            let watchedResponse: [UserWatched] = try await supabase
                .from("user_watched")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            watchedCount = watchedResponse.count

            // Load predictions made count
            let predictionsResponse: [UserPrediction] = try await supabase
                .from("user_predictions")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            predictionsMade = predictionsResponse.count

            // Correct predictions require joining with nominations where is_winner = true
            // For now, we'll calculate this when winners are announced
            // This would typically be a Supabase RPC call
            correctPredictions = 0

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load profile. Pull to refresh."
        }
    }

    /// Format the member since date
    func memberSinceFormatted() -> String {
        guard let createdAt = profile?.createdAt else {
            return "Unknown"
        }

        // Parse ISO 8601 date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }

        return "Unknown"
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Username Editing

    /// Check if username length is valid (3-20 characters)
    var isUsernameLengthValid: Bool {
        editedUsername.count >= 3 && editedUsername.count <= 20
    }

    /// Check if username format is valid (alphanumeric and underscores only)
    var isUsernameFormatValid: Bool {
        let usernameRegex = #"^[A-Za-z0-9_]+$"#
        return editedUsername.range(of: usernameRegex, options: .regularExpression) != nil
    }

    /// Check if username contains profanity
    var usernameContainsProfanity: Bool {
        let lowercased = editedUsername.lowercased()
        return profanityList.contains { profanity in
            lowercased.contains(profanity)
        }
    }

    /// Check if username is fully valid
    var isEditedUsernameValid: Bool {
        isUsernameLengthValid && isUsernameFormatValid && !usernameContainsProfanity
    }

    /// Start editing username
    func startEditingUsername() {
        editedUsername = profile?.username ?? ""
        isEditingUsername = true
        usernameSuccessMessage = nil
        errorMessage = nil
    }

    /// Cancel editing username
    func cancelEditingUsername() {
        isEditingUsername = false
        editedUsername = ""
        errorMessage = nil
    }

    /// Save the edited username to Supabase
    func saveUsername() async {
        guard isEditedUsernameValid else {
            errorMessage = validateUsername()
            HapticManager.error()
            return
        }

        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            errorMessage = "Not logged in"
            HapticManager.error()
            return
        }

        isSavingUsername = true
        errorMessage = nil
        usernameSuccessMessage = nil

        do {
            try await supabase
                .from("profiles")
                .update(["username": editedUsername])
                .eq("id", value: userId)
                .execute()

            // Update local profile
            if var updatedProfile = profile {
                updatedProfile.username = editedUsername
                profile = updatedProfile
            }

            isSavingUsername = false
            isEditingUsername = false
            usernameSuccessMessage = "Username updated!"
            HapticManager.success()

            // Clear success message after a delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                usernameSuccessMessage = nil
            }
        } catch {
            isSavingUsername = false
            errorMessage = "Failed to update username. Please try again."
            HapticManager.error()
        }
    }

    /// Validate username and return error message if invalid
    private func validateUsername() -> String? {
        if editedUsername.isEmpty {
            return "Please enter a username."
        }

        if !isUsernameLengthValid {
            return "Username must be 3-20 characters long."
        }

        if !isUsernameFormatValid {
            return "Username can only contain letters, numbers, and underscores."
        }

        if usernameContainsProfanity {
            return "Username contains inappropriate content."
        }

        return nil
    }

    /// Sign out the current user
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signOut()

            // Clear local state
            profile = nil
            watchedCount = 0
            predictionsMade = 0
            correctPredictions = 0

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to sign out. Please try again."
            HapticManager.error()
        }
    }

    // MARK: - Change Password

    @Published var showChangePasswordSheet = false
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""
    @Published var isChangingPassword = false
    @Published var changePasswordSuccessMessage: String?

    /// Check if new password length is valid (8+ characters)
    var isNewPasswordLengthValid: Bool {
        newPassword.count >= 8
    }

    /// Check if new password has uppercase letter
    var newPasswordHasUppercase: Bool {
        newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    /// Check if new password has lowercase letter
    var newPasswordHasLowercase: Bool {
        newPassword.range(of: "[a-z]", options: .regularExpression) != nil
    }

    /// Check if new password has number
    var newPasswordHasNumber: Bool {
        newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }

    /// Check if passwords match
    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmNewPassword
    }

    /// Check if all password requirements are met
    var isNewPasswordValid: Bool {
        isNewPasswordLengthValid && newPasswordHasUppercase && newPasswordHasLowercase && newPasswordHasNumber
    }

    /// Check if form is valid for submission
    var isChangePasswordFormValid: Bool {
        !currentPassword.isEmpty && isNewPasswordValid && passwordsMatch
    }

    /// Password strength level for UI indicator
    var newPasswordStrength: PasswordStrength {
        if newPassword.isEmpty {
            return .none
        }

        var score = 0

        if newPassword.count >= 8 { score += 1 }
        if newPassword.count >= 12 { score += 1 }
        if newPasswordHasUppercase { score += 1 }
        if newPasswordHasLowercase { score += 1 }
        if newPasswordHasNumber { score += 1 }
        if newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }

        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }

    /// Open change password sheet
    func openChangePasswordSheet() {
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        errorMessage = nil
        changePasswordSuccessMessage = nil
        showChangePasswordSheet = true
    }

    /// Cancel change password
    func cancelChangePassword() {
        showChangePasswordSheet = false
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        errorMessage = nil
    }

    /// Change password via Supabase auth
    func changePassword() async {
        guard isChangePasswordFormValid else {
            errorMessage = "Please fill in all fields correctly."
            HapticManager.error()
            return
        }

        isChangingPassword = true
        errorMessage = nil
        changePasswordSuccessMessage = nil

        do {
            // Get current user email for re-authentication
            guard let email = try? await supabase.auth.session.user.email else {
                errorMessage = "Unable to verify your account. Please try again."
                isChangingPassword = false
                HapticManager.error()
                return
            }

            // Verify current password by attempting to sign in
            do {
                _ = try await supabase.auth.signIn(
                    email: email,
                    password: currentPassword
                )
            } catch {
                errorMessage = "Current password is incorrect."
                isChangingPassword = false
                HapticManager.error()
                return
            }

            // Update password
            try await supabase.auth.update(user: UserAttributes(password: newPassword))

            isChangingPassword = false
            showChangePasswordSheet = false
            changePasswordSuccessMessage = "Password changed successfully!"
            HapticManager.success()

            // Clear form
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""

            // Clear success message after delay
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                changePasswordSuccessMessage = nil
            }
        } catch {
            isChangingPassword = false
            errorMessage = mapChangePasswordError(error)
            HapticManager.error()
        }
    }

    /// Map password change errors to user-friendly messages
    private func mapChangePasswordError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("weak") || errorMessage.contains("password") {
            return "New password is too weak. Please use a stronger password."
        }
        if errorMessage.contains("same") {
            return "New password must be different from current password."
        }
        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return "Network error. Please check your connection."
        }

        return "Failed to change password. Please try again."
    }

    // MARK: - Delete Account

    @Published var isDeletingAccount = false

    /// Delete user account via Supabase RPC
    func deleteAccount() async {
        isDeletingAccount = true
        errorMessage = nil

        do {
            // Call delete_user RPC function to cascade delete all user data
            try await supabase.rpc("delete_user").execute()

            // Sign out after deletion
            try await supabase.auth.signOut()

            // Clear local state
            profile = nil
            watchedCount = 0
            predictionsMade = 0
            correctPredictions = 0

            isDeletingAccount = false
            HapticManager.success()
        } catch {
            isDeletingAccount = false
            errorMessage = mapDeleteAccountError(error)
            HapticManager.error()
        }
    }

    /// Map delete account errors to user-friendly messages
    private func mapDeleteAccountError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return "Network error. Please check your connection."
        }
        if errorMessage.contains("permission") || errorMessage.contains("denied") {
            return "Permission denied. Please try again later."
        }
        if errorMessage.contains("not found") {
            return "Account not found. You may already be signed out."
        }

        return "Failed to delete account. Please try again."
    }
}
