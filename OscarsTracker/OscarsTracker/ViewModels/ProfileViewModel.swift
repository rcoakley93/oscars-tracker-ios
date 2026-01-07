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

    private let supabase = SupabaseClientManager.shared.client

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
}
