import Foundation
import Observation

/// Reporting and blocking (guideline 1.2, P6-16): the people you've blocked,
/// and reports of people and groups. `AppModel.block` reloads the boards and
/// groups after a block, since the server hides blocked people there.
@Observable
final class ModerationStore {
    private(set) var blocked: [BlockedUser] = []
    private(set) var state: LoadState = .idle
    private(set) var isWorking = false
    /// Counts reports the server accepted, for the "Thanks" confirmation.
    private(set) var reportsSent = 0
    /// A block or unblock that failed, for the screen's alert.
    var actionError: AppError?
    /// A report that failed, which the report sheet shows itself.
    var reportError: AppError?

    /// The longest note a report takes (`reports.details`).
    static let detailsLimit = 500

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load() async {
        state = .loading
        do {
            blocked = try await data.blockedUsers()
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func isBlocked(_ userID: String) -> Bool {
        blocked.contains { $0.userId == userID }
    }

    /// Sends a report; an empty note is no note.
    func report(_ target: ReportTarget, reason: ReportReason, details: String) async -> Bool {
        let note = String(details.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.detailsLimit))
        isWorking = true
        reportError = nil
        defer { isWorking = false }
        do {
            switch target {
            case .person(let id, _): try await data.reportUser(id, reason: reason, details: note.isEmpty ? nil : note)
            case .group(let id, _): try await data.reportGroup(id, reason: reason, details: note.isEmpty ? nil : note)
            }
            reportsSent += 1
            return true
        } catch {
            reportError = AppError(error)
            return false
        }
    }

    /// Shows them as blocked at once and takes it back if the server refuses.
    func block(_ userID: String, name: String) async -> Bool {
        guard !isBlocked(userID) else { return true }
        blocked.insert(BlockedUser(userId: userID, username: name, avatarUrl: nil, blockedAt: .now), at: 0)
        let done = await working { try await data.blockUser(userID) }
        if !done { blocked.removeAll { $0.userId == userID } }
        return done
    }

    func unblock(_ userID: String) async -> Bool {
        guard let index = blocked.firstIndex(where: { $0.userId == userID }) else { return true }
        let removed = blocked.remove(at: index)
        let done = await working { try await data.unblockUser(userID) }
        if !done { blocked.insert(removed, at: min(index, blocked.count)) }
        return done
    }

    private func working(_ work: () async throws -> Void) async -> Bool {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await work()
            return true
        } catch {
            actionError = AppError(error)
            return false
        }
    }

    func reset() {
        blocked = []
        state = .idle
        reportsSent = 0
        actionError = nil
        reportError = nil
    }
}
