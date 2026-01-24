import Foundation
import Supabase

/// Manages onboarding state and username validation.
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var username = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseClientManager.shared.client

    /// Common profanity words to filter (basic list)
    private let profanityList: Set<String> = [
        "fuck", "shit", "ass", "bitch", "damn", "crap", "bastard",
        "dick", "pussy", "cock", "cunt", "whore", "slut", "fag",
        "nigger", "nigga", "retard", "nazi", "hitler"
    ]

    /// Check if username length is valid (3-20 characters)
    var isLengthValid: Bool {
        username.count >= 3 && username.count <= 20
    }

    /// Check if username format is valid (alphanumeric and underscores only)
    var isFormatValid: Bool {
        let usernameRegex = #"^[A-Za-z0-9_]+$"#
        return username.range(of: usernameRegex, options: .regularExpression) != nil
    }

    /// Check if username contains profanity
    var containsProfanity: Bool {
        let lowercased = username.lowercased()
        return profanityList.contains { profanity in
            lowercased.contains(profanity)
        }
    }

    /// Check if username is fully valid
    var isUsernameValid: Bool {
        isLengthValid && isFormatValid && !containsProfanity
    }

    /// Validate username and return error message if invalid
    func validateUsername() -> String? {
        if username.isEmpty {
            return "Please enter a username."
        }

        if !isLengthValid {
            return "Username must be 3-20 characters long."
        }

        if !isFormatValid {
            return "Username can only contain letters, numbers, and underscores."
        }

        if containsProfanity {
            return "Username contains inappropriate content."
        }

        return nil
    }

    /// Save username to the profiles table
    func saveUsername(userId: UUID) async -> Bool {
        guard isUsernameValid else {
            errorMessage = validateUsername()
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            // Upsert the profile with the username
            try await supabase
                .from("profiles")
                .upsert([
                    "id": userId.uuidString,
                    "username": username
                ])
                .execute()

            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = "Failed to save username. Please try again."
            return false
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
