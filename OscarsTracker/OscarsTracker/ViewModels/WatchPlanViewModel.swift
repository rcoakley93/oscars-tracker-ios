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
}
