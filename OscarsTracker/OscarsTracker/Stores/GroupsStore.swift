import Foundation
import Observation

/// Your groups and their leaderboards.
@Observable
final class GroupsStore {
    private(set) var groups: [PoolGroup] = []
    private(set) var boards: [Int: [GroupLeaderboardEntry]] = [:]
    private(set) var state: LoadState = .idle
    private(set) var isWorking = false
    var actionError: AppError?

    private let data: any AppDataSource

    init(data: any AppDataSource) {
        self.data = data
    }

    func load(userID: String) async {
        state = .loading
        do {
            groups = try await data.myGroups(userID: userID)
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func loadBoard(for groupID: Int) async {
        do {
            boards[groupID] = try await data.groupLeaderboard(groupID: groupID)
        } catch {
            actionError = AppError(error)
        }
    }

    /// The message to show for a group name, or nil when it's fine.
    static func nameProblem(_ name: String) -> String? {
        ValidationService.validateGroupName(name).errorMessage
    }

    func create(name: String, userID: String) async -> PoolGroup? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.nameProblem(trimmed) == nil else { return nil }
        return await working {
            let group = try await data.createGroup(name: trimmed, userID: userID)
            groups.append(group)
            groups.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return group
        }
    }

    /// Joins through the `join_group` RPC, which checks the code on the server.
    func join(code: String, userID: String) async -> JoinedGroup? {
        await working {
            let joined = try await data.joinGroup(inviteCode: code)
            groups = try await data.myGroups(userID: userID)
            return joined
        }
    }

    func leave(_ groupID: Int, userID: String) async {
        _ = await working {
            try await data.leaveGroup(groupID: groupID, userID: userID)
            groups.removeAll { $0.id == groupID }
        }
    }

    func delete(_ groupID: Int) async {
        _ = await working {
            try await data.deleteGroup(groupID: groupID)
            groups.removeAll { $0.id == groupID }
        }
    }

    func remove(member userID: String, from groupID: Int) async {
        _ = await working {
            try await data.removeMember(userID: userID, groupID: groupID)
            boards[groupID]?.removeAll { $0.userId == userID }
        }
    }

    private func working<T>(_ work: () async throws -> T) async -> T? {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            return try await work()
        } catch {
            actionError = AppError(error)
            return nil
        }
    }

    func reset() {
        groups = []
        boards = [:]
        state = .idle
    }
}
