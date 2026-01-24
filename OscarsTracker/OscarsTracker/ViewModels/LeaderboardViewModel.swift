import Foundation
import Supabase

/// Manages leaderboard state and data.
@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var currentUserId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalMovieCount: Int = 0

    private let supabase = SupabaseClientManager.shared.client

    /// Initialize
    init() {}

    /// Load leaderboard data from Supabase RPC
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID
            if let userId = try? await supabase.auth.session.user.id.uuidString {
                currentUserId = userId
            }

            // Fetch total movie count and leaderboard entries in parallel
            async let movieCountTask: Int = supabase
                .from("movies")
                .select("id", head: true, count: .exact)
                .execute()
                .count ?? 0

            async let leaderboardTask: [LeaderboardEntry] = supabase
                .rpc("get_leaderboard")
                .execute()
                .value

            let (movieCount, leaderboardEntries) = try await (movieCountTask, leaderboardTask)

            totalMovieCount = movieCount
            entries = leaderboardEntries
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load leaderboard. Pull to refresh."
        }
    }

    /// Check if an entry is the current user
    func isCurrentUser(_ entry: LeaderboardEntry) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return entry.userId == currentUserId
    }

    /// Get medal type for rank
    func medalType(for rank: Int) -> MedalType? {
        switch rank {
        case 1:
            return .gold
        case 2:
            return .silver
        case 3:
            return .bronze
        default:
            return nil
        }
    }

    /// Get the current user's entry (for scrolling)
    var currentUserEntry: LeaderboardEntry? {
        guard let currentUserId = currentUserId else { return nil }
        return entries.first { $0.userId == currentUserId }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

/// Medal types for top 3 positions
enum MedalType {
    case gold
    case silver
    case bronze

    var color: String {
        switch self {
        case .gold:
            return "goldPrimary"
        case .silver:
            return "silver"
        case .bronze:
            return "bronze"
        }
    }

    var icon: String {
        switch self {
        case .gold:
            return "medal.fill"
        case .silver:
            return "medal.fill"
        case .bronze:
            return "medal.fill"
        }
    }
}
