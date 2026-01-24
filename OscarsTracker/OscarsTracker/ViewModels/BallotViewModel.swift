import Foundation
import Supabase

/// Manages ballot state and data.
@MainActor
final class BallotViewModel: ObservableObject {
    @Published var categories: [CategoryWithNominations] = []
    @Published var movies: [Movie] = []
    @Published var predictions: [Int: Int] = [:] // categoryId -> nominationId
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var isLocked = false

    private let supabase = SupabaseClientManager.shared.client

    /// The date when the ballot locks (Oscars ceremony start - March 2, 2025 at 5:00 PM PT)
    let ballotLockDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 2
        components.hour = 17
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")
        return Calendar.current.date(from: components) ?? Date()
    }()

    /// Check if ballot is currently locked
    func checkLockStatus() {
        isLocked = Date() >= ballotLockDate
    }

    /// Categories sorted by points value (highest first)
    var sortedCategories: [CategoryWithNominations] {
        categories.sorted { ($0.pointsValue ?? 0) > ($1.pointsValue ?? 0) }
    }

    /// Total number of categories
    var totalCategories: Int {
        categories.count
    }

    /// Number of categories with predictions
    var predictedCategories: Int {
        predictions.count
    }

    /// Initialize
    init() {}

    /// Load categories and nominations from Supabase
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all movies first for reference
            let moviesResponse: [Movie] = try await supabase
                .from("movies")
                .select()
                .execute()
                .value

            movies = moviesResponse

            // Load categories
            let categoriesResponse: [Category] = try await supabase
                .from("categories")
                .select()
                .order("points_value", ascending: false)
                .execute()
                .value

            // Load nominations
            let nominationsResponse: [Nomination] = try await supabase
                .from("nominations")
                .select()
                .execute()
                .value

            // Load user predictions if logged in
            if let userId = try? await supabase.auth.session.user.id.uuidString {
                let predictionsResponse: [UserPrediction] = try await supabase
                    .from("user_predictions")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value

                // Convert to dictionary for easy lookup
                var predictionsMap: [Int: Int] = [:]
                for prediction in predictionsResponse {
                    predictionsMap[prediction.categoryId] = prediction.nominationId
                }
                predictions = predictionsMap
            }

            // Group nominations by category and attach movie data
            var categoryMap: [Int: [Nomination]] = [:]
            for nomination in nominationsResponse {
                guard let categoryId = nomination.categoryId else { continue }
                var mutableNomination = nomination
                if let movieId = nomination.movieId {
                    mutableNomination.movie = movies.first { $0.id == movieId }
                }
                categoryMap[categoryId, default: []].append(mutableNomination)
            }

            // Build CategoryWithNominations array
            categories = categoriesResponse.map { category in
                CategoryWithNominations(
                    id: category.id,
                    name: category.name,
                    pointsValue: category.pointsValue,
                    nominations: categoryMap[category.id] ?? []
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load categories. Pull to refresh."
        }
    }

    /// Get movie for a nomination
    func movie(for nomination: Nomination) -> Movie? {
        if let movieId = nomination.movieId {
            return movies.first { $0.id == movieId }
        }
        return nil
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Check if a nomination is selected for its category
    func isSelected(nomination: Nomination) -> Bool {
        guard let categoryId = nomination.categoryId else { return false }
        return predictions[categoryId] == nomination.id
    }

    /// Check if any winner has been announced for a category
    func hasWinner(for category: CategoryWithNominations) -> Bool {
        category.nominations.contains { $0.isWinner == true }
    }

    /// Get the winning nomination for a category
    func winningNomination(for category: CategoryWithNominations) -> Nomination? {
        category.nominations.first { $0.isWinner == true }
    }

    /// Check if the user's prediction was correct for a category
    func isPredictionCorrect(for category: CategoryWithNominations) -> Bool {
        guard let userPredictionId = predictions[category.id],
              let winner = winningNomination(for: category) else {
            return false
        }
        return userPredictionId == winner.id
    }

    /// Check if the user's prediction was incorrect (made a prediction but didn't pick winner)
    func isPredictionIncorrect(for category: CategoryWithNominations) -> Bool {
        guard hasWinner(for: category),
              let _ = predictions[category.id] else {
            return false
        }
        return !isPredictionCorrect(for: category)
    }

    /// Points earned for a specific category
    func pointsEarned(for category: CategoryWithNominations) -> Int {
        if isPredictionCorrect(for: category) {
            return category.pointsValue ?? 0
        }
        return 0
    }

    /// Total points earned across all categories
    var totalPointsEarned: Int {
        categories.reduce(0) { total, category in
            total + pointsEarned(for: category)
        }
    }

    /// Maximum possible points
    var maxPossiblePoints: Int {
        categories.reduce(0) { total, category in
            total + (category.pointsValue ?? 0)
        }
    }

    /// Select a nomination as prediction for a category
    func selectPrediction(nomination: Nomination) async {
        // Don't allow changes if ballot is locked
        guard !isLocked else {
            HapticManager.error()
            return
        }

        guard let categoryId = nomination.categoryId else { return }

        // Optimistic update
        let previousPrediction = predictions[categoryId]
        predictions[categoryId] = nomination.id

        // Haptic feedback
        HapticManager.light()

        do {
            guard let userId = try? await supabase.auth.session.user.id.uuidString else {
                // Rollback if no user
                if let previous = previousPrediction {
                    predictions[categoryId] = previous
                } else {
                    predictions.removeValue(forKey: categoryId)
                }
                return
            }

            // Upsert prediction to Supabase
            let predictionData: [String: AnyJSON] = [
                "user_id": .string(userId),
                "category_id": .integer(categoryId),
                "nomination_id": .integer(nomination.id)
            ]

            try await supabase
                .from("user_predictions")
                .upsert(predictionData, onConflict: "user_id,category_id")
                .execute()

        } catch {
            // Rollback on error
            if let previous = previousPrediction {
                predictions[categoryId] = previous
            } else {
                predictions.removeValue(forKey: categoryId)
            }
            HapticManager.error()
            errorMessage = "Failed to save prediction. Please try again."
        }
    }
}
