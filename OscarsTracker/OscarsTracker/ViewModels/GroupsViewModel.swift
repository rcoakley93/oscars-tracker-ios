import Foundation
import Supabase
import UIKit

/// Model for displaying a group with member count.
struct GroupWithMemberCount: Identifiable {
    let id: Int
    let name: String
    let inviteCode: String
    let createdBy: String
    let memberCount: Int

    var isOwner: Bool = false
}

/// Manages groups state and data.
@MainActor
final class GroupsViewModel: ObservableObject {
    @Published var myGroups: [GroupWithMemberCount] = []
    @Published var joinedGroups: [GroupWithMemberCount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?

    private let supabase = SupabaseClientManager.shared.client

    /// Initialize
    init() {}

    /// Load groups from Supabase
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id.uuidString else {
                isLoading = false
                errorMessage = "Please sign in to view groups."
                return
            }
            currentUserId = userId

            // Load all groups
            let allGroups: [Group] = try await supabase
                .from("groups")
                .select()
                .execute()
                .value

            // Load all group members
            let allMembers: [GroupMember] = try await supabase
                .from("group_members")
                .select()
                .execute()
                .value

            // Count members per group
            var memberCounts: [Int: Int] = [:]
            var userGroupIds: Set<Int> = []

            for member in allMembers {
                guard let groupId = member.groupId else { continue }
                memberCounts[groupId, default: 0] += 1

                if member.userId == userId {
                    userGroupIds.insert(groupId)
                }
            }

            // Split groups into my groups (created by me) and joined groups (member but not creator)
            var myGroupsList: [GroupWithMemberCount] = []
            var joinedGroupsList: [GroupWithMemberCount] = []

            for group in allGroups {
                let isCreator = group.createdBy == userId
                let isMember = userGroupIds.contains(group.id)

                if !isCreator && !isMember {
                    // User is neither creator nor member - skip
                    continue
                }

                let groupWithCount = GroupWithMemberCount(
                    id: group.id,
                    name: group.name,
                    inviteCode: group.inviteCode,
                    createdBy: group.createdBy,
                    memberCount: memberCounts[group.id] ?? 0,
                    isOwner: isCreator
                )

                if isCreator {
                    myGroupsList.append(groupWithCount)
                } else if isMember {
                    joinedGroupsList.append(groupWithCount)
                }
            }

            myGroups = myGroupsList.sorted { $0.name < $1.name }
            joinedGroups = joinedGroupsList.sorted { $0.name < $1.name }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load groups. Pull to refresh."
        }
    }

    /// Copy invite code to clipboard
    func copyInviteCode(_ code: String) {
        UIPasteboard.general.string = code
        HapticManager.success()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
