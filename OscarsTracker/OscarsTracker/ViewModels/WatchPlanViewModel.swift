import Foundation
import Supabase

/// Manages watch plan state and data.
@MainActor
final class WatchPlanViewModel: ObservableObject {
    @Published var watchPlanItems: [WatchPlanItem] = []
    @Published var movies: [Movie] = []
    @Published var watchedMovieIds: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseClientManager.shared.client

    /// Count of planned movies
    var plannedCount: Int {
        watchPlanItems.count
    }

    /// Count of unplanned (unwatched movies not in plan)
    var unplannedCount: Int {
        let plannedMovieIds = Set(watchPlanItems.map { $0.movieId })
        return movies.filter { !watchedMovieIds.contains($0.id) && !plannedMovieIds.contains($0.id) }.count
    }

    /// Count of watched movies
    var watchedCount: Int {
        watchedMovieIds.count
    }

    /// Group items by date
    var groupedItems: [(date: Date, label: String, items: [WatchPlanItem])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        var groups: [Date: [WatchPlanItem]] = [:]
        var overdueItems: [WatchPlanItem] = []

        for item in watchPlanItems {
            if let date = parseDate(item.plannedDate) {
                let startOfDay = calendar.startOfDay(for: date)
                if startOfDay < today {
                    overdueItems.append(item)
                } else {
                    groups[startOfDay, default: []].append(item)
                }
            }
        }

        var result: [(date: Date, label: String, items: [WatchPlanItem])] = []

        // Add overdue section first if there are overdue items
        if !overdueItems.isEmpty {
            result.append((date: Date.distantPast, label: "OVERDUE", items: overdueItems))
        }

        // Sort remaining dates and add them
        let sortedDates = groups.keys.sorted()
        for date in sortedDates {
            let label: String
            if calendar.isDate(date, inSameDayAs: today) {
                label = "TODAY"
            } else if calendar.isDate(date, inSameDayAs: tomorrow) {
                label = "TOMORROW"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMM d"
                label = formatter.string(from: date).uppercased()
            }
            result.append((date: date, label: label, items: groups[date]!))
        }

        return result
    }

    /// Initialize
    init() {}

    /// Load watch plan items from Supabase
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all movies first
            let moviesResponse: [Movie] = try await supabase
                .from("movies")
                .select()
                .execute()
                .value

            movies = moviesResponse

            // Load watched movies
            if let userId = supabase.auth.currentUser?.id {
                let watchedResponse: [UserWatched] = try await supabase
                    .from("user_watched")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                    .value

                watchedMovieIds = Set(watchedResponse.map { $0.movieId })

                // Load watch plan items
                let planResponse: [WatchPlanItem] = try await supabase
                    .from("watch_plan")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                    .value

                // Attach movie data to each plan item
                watchPlanItems = planResponse.map { item in
                    var mutableItem = item
                    mutableItem.movie = movies.first { $0.id == item.movieId }
                    return mutableItem
                }
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load watch plan. Pull to refresh."
        }
    }

    /// Get movie for an item
    func movie(for item: WatchPlanItem) -> Movie? {
        movies.first { $0.id == item.movieId }
    }

    /// Parse date string to Date
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Mark a movie as watched and remove from watch plan
    /// - Parameters:
    ///   - itemId: The ID of the watch plan item
    ///   - movieId: The ID of the movie to mark as watched
    /// - Returns: True if successful, false otherwise
    func markWatchedAndRemove(itemId: Int, movieId: Int) async -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            errorMessage = "Not logged in"
            return false
        }

        // Optimistic update - remove from list
        let originalItems = watchPlanItems
        let originalWatchedIds = watchedMovieIds
        watchPlanItems.removeAll { $0.id == itemId }

        // Add to watched set
        watchedMovieIds.insert(movieId)

        do {
            // Insert into user_watched
            let watchedData: [String: AnyJSON] = [
                "user_id": .string(userId.uuidString),
                "movie_id": .integer(movieId)
            ]

            try await supabase
                .from("user_watched")
                .insert(watchedData)
                .execute()

            // Delete from watch_plan
            try await supabase
                .from("watch_plan")
                .delete()
                .eq("id", value: itemId)
                .execute()

            return true
        } catch {
            // Rollback on error
            watchPlanItems = originalItems
            watchedMovieIds = originalWatchedIds
            errorMessage = "Failed to mark as watched"
            return false
        }
    }

    /// Remove a movie from the watch plan without marking watched
    /// - Parameter itemId: The ID of the watch plan item to remove
    /// - Returns: True if successful, false otherwise
    func removeFromPlan(itemId: Int) async -> Bool {
        guard supabase.auth.currentUser != nil else {
            errorMessage = "Not logged in"
            return false
        }

        // Optimistic update
        let originalItems = watchPlanItems
        watchPlanItems.removeAll { $0.id == itemId }

        do {
            try await supabase
                .from("watch_plan")
                .delete()
                .eq("id", value: itemId)
                .execute()

            return true
        } catch {
            // Rollback on error
            watchPlanItems = originalItems
            errorMessage = "Failed to remove from plan"
            return false
        }
    }

    /// Reschedule a watch plan item to a new date
    /// - Parameters:
    ///   - itemId: The ID of the watch plan item
    ///   - date: The new planned date
    /// - Returns: True if successful, false otherwise
    func reschedule(itemId: Int, to date: Date) async -> Bool {
        guard supabase.auth.currentUser != nil else {
            errorMessage = "Not logged in"
            return false
        }

        // Format date as yyyy-MM-dd
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // Optimistic update
        let originalItems = watchPlanItems
        if let index = watchPlanItems.firstIndex(where: { $0.id == itemId }) {
            var updatedItem = watchPlanItems[index]
            // Create a new item with updated date (WatchPlanItem is a struct)
            updatedItem = WatchPlanItem(
                id: updatedItem.id,
                userId: updatedItem.userId,
                movieId: updatedItem.movieId,
                plannedDate: dateString,
                createdAt: updatedItem.createdAt
            )
            updatedItem.movie = originalItems[index].movie
            watchPlanItems[index] = updatedItem
        }

        do {
            // Update in Supabase
            try await supabase
                .from("watch_plan")
                .update(["planned_date": dateString])
                .eq("id", value: itemId)
                .execute()

            return true
        } catch {
            // Rollback on error
            watchPlanItems = originalItems
            errorMessage = "Failed to reschedule movie"
            return false
        }
    }

    /// Add a movie to the watch plan
    /// - Parameters:
    ///   - movieId: The ID of the movie to add
    ///   - date: The planned date
    /// - Returns: True if successful, false otherwise
    func addToPlan(movieId: Int, date: Date) async -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            errorMessage = "Not logged in"
            return false
        }

        // Format date as yyyy-MM-dd
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // Create insert data
        let insertData: [String: AnyJSON] = [
            "user_id": .string(userId.uuidString),
            "movie_id": .integer(movieId),
            "planned_date": .string(dateString)
        ]

        do {
            // Insert into watch_plan table
            let response: [WatchPlanItem] = try await supabase
                .from("watch_plan")
                .insert(insertData)
                .select()
                .execute()
                .value

            // Add the new item to local state
            if let newItem = response.first {
                var mutableItem = newItem
                mutableItem.movie = movies.first { $0.id == movieId }
                watchPlanItems.append(mutableItem)
            }

            return true
        } catch {
            errorMessage = "Failed to add movie to plan"
            return false
        }
    }

    /// Bulk add movies to the watch plan
    /// - Parameter movies: Array of (movieId, date) tuples to add
    /// - Returns: True if all successful, false otherwise
    func bulkAddToPlan(movies: [(movieId: Int, date: Date)]) async -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            errorMessage = "Not logged in"
            return false
        }

        guard !movies.isEmpty else { return true }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Create array of insert data
        let insertData: [[String: AnyJSON]] = movies.map { movieId, date in
            [
                "user_id": .string(userId.uuidString),
                "movie_id": .integer(movieId),
                "planned_date": .string(formatter.string(from: date))
            ]
        }

        do {
            // Bulk insert into watch_plan table
            let response: [WatchPlanItem] = try await supabase
                .from("watch_plan")
                .insert(insertData)
                .select()
                .execute()
                .value

            // Add all new items to local state with movie data attached
            for newItem in response {
                var mutableItem = newItem
                mutableItem.movie = self.movies.first { $0.id == newItem.movieId }
                watchPlanItems.append(mutableItem)
            }

            return true
        } catch {
            errorMessage = "Failed to add movies to plan"
            return false
        }
    }
}
