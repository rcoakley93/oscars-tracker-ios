import Foundation
import Supabase

/// Manages dashboard state and movie data.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var watchedMovieIds: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseClientManager.shared.client

    /// Oscar ceremony date (March 15, 2026)
    let oscarDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        return Calendar.current.date(from: components) ?? Date()
    }()

    /// Count of watched movies
    var watchedCount: Int {
        watchedMovieIds.count
    }

    /// Total movie count
    var totalCount: Int {
        movies.count
    }

    /// Initialize and load data
    init() {}

    /// Load movies and watched status from Supabase
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all movies
            let moviesResponse: [Movie] = try await supabase
                .from("movies")
                .select()
                .execute()
                .value

            movies = moviesResponse

            // Load watched movies for current user
            if let userId = supabase.auth.currentUser?.id {
                let watchedResponse: [UserWatched] = try await supabase
                    .from("user_watched")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                    .value

                watchedMovieIds = Set(watchedResponse.map { $0.movieId })
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load movies. Pull to refresh."
        }
    }

    /// Toggle watched status for a movie
    func toggleWatched(movieId: Int) async {
        guard let userId = supabase.auth.currentUser?.id else { return }

        // Haptic feedback on toggle
        HapticManager.light()

        // Optimistic update
        let wasWatched = watchedMovieIds.contains(movieId)
        if wasWatched {
            watchedMovieIds.remove(movieId)
        } else {
            watchedMovieIds.insert(movieId)
        }

        do {
            if wasWatched {
                // Remove from watched
                try await supabase
                    .from("user_watched")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("movie_id", value: movieId)
                    .execute()
            } else {
                // Add to watched
                try await supabase
                    .from("user_watched")
                    .insert([
                        "user_id": userId.uuidString,
                        "movie_id": String(movieId)
                    ])
                    .execute()
            }
        } catch {
            // Rollback on error with error haptic
            HapticManager.error()
            if wasWatched {
                watchedMovieIds.insert(movieId)
            } else {
                watchedMovieIds.remove(movieId)
            }
            errorMessage = "Failed to update watched status."
        }
    }

    /// Check if a movie is watched
    func isWatched(_ movieId: Int) -> Bool {
        watchedMovieIds.contains(movieId)
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
