import Foundation
import Observation

/// The global leaderboard. P2-05 replaces `get_leaderboard()` with one RPC for
/// every board; the app shows its ranks as they come.
@Observable
final class LeaderboardStore {
    private(set) var entries: [LeaderboardEntry] = []
    private(set) var state: LoadState = .idle

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load() async {
        state = .loading
        do {
            entries = try await data.leaderboard()
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func entry(for userID: String?) -> LeaderboardEntry? {
        entries.first { $0.userId == userID }
    }

    func reset() {
        entries = []
        state = .idle
    }
}
