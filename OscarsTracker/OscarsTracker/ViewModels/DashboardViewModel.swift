import Foundation
import Supabase

/// View mode for dashboard display
enum DashboardViewMode: String, CaseIterable {
    case masterList = "Master List"
    case byCategory = "By Category"
}

/// Manages dashboard state and movie data.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var watchedMovieIds: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var viewMode: DashboardViewMode = .masterList
    @Published var categoriesWithMovies: [CategoryWithMovies] = []

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

            // Load categories and nominations for category view
            await loadCategoriesWithMovies()

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load movies. Pull to refresh."
        }
    }

    /// Load categories with their associated movies via nominations
    private func loadCategoriesWithMovies() async {
        do {
            // Load all categories
            let categoriesResponse: [Category] = try await supabase
                .from("categories")
                .select()
                .order("name")
                .execute()
                .value

            // Load nominations with movie data
            let nominationsResponse: [Nomination] = try await supabase
                .from("nominations")
                .select("*, movie:movies(*)")
                .execute()
                .value

            // Create a dictionary mapping movie IDs to movies for quick lookup
            let movieDict = Dictionary(uniqueKeysWithValues: movies.map { ($0.id, $0) })

            // Group nominations by category and extract unique movies
            var categoryMoviesDict: [Int: [Movie]] = [:]
            for nomination in nominationsResponse {
                guard let categoryId = nomination.categoryId,
                      let movieId = nomination.movieId else { continue }

                // Get movie from the nomination's embedded data or from our local dictionary
                let movie: Movie?
                if let nominationMovie = nomination.movie {
                    movie = nominationMovie
                } else {
                    movie = movieDict[movieId]
                }

                guard let validMovie = movie else { continue }

                if categoryMoviesDict[categoryId] == nil {
                    categoryMoviesDict[categoryId] = []
                }

                // Add movie if not already in the category (same movie can be nominated multiple times)
                if !categoryMoviesDict[categoryId]!.contains(where: { $0.id == validMovie.id }) {
                    categoryMoviesDict[categoryId]!.append(validMovie)
                }
            }

            // Create CategoryWithMovies array
            categoriesWithMovies = categoriesResponse.compactMap { category in
                guard let categoryMovies = categoryMoviesDict[category.id], !categoryMovies.isEmpty else {
                    return nil
                }
                return CategoryWithMovies(
                    id: category.id,
                    name: category.name,
                    movies: categoryMovies.sorted { $0.title < $1.title }
                )
            }
        } catch {
            // Silently fail - category view will just be empty
            categoriesWithMovies = []
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
