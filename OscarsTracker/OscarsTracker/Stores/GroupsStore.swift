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

    /// Where you stand in a group by films watched: your rank, the group's
    /// size, and how you compare with the nearest person above you.
    struct Standing: Equatable {
        enum Position: Equatable {
            case first
            /// Level at the top with someone else.
            case tied(with: String)
            /// `films` behind `name`, the nearest person with more.
            case behind(String, films: Int)
        }

        let rank: Int
        let size: Int
        let position: Position
    }

    /// Nil until the group's board is loaded, or if you're not on it.
    func standing(in groupID: Int, userID: String) -> Standing? {
        guard let board = boards[groupID], let me = board.first(where: { $0.userId == userID }) else { return nil }
        let others = board.filter { $0.userId != userID }
        let position: Standing.Position
        if let above = others.filter({ $0.watchedCount > me.watchedCount }).min(by: { $0.watchedCount < $1.watchedCount }) {
            position = .behind(above.username, films: above.watchedCount - me.watchedCount)
        } else if let level = others.first(where: { $0.watchedCount == me.watchedCount }) {
            position = .tied(with: level.username)
        } else {
            position = .first
        }
        return Standing(rank: me.rank, size: board.count, position: position)
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
