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
    @Published var showCreateSheet = false
    @Published var isCreating = false

    // Create group form
    @Published var newGroupName = ""

    private let supabase = SupabaseClientManager.shared.client

    /// Common profanity words to filter (basic list)
    private let profanityList: Set<String> = [
        "fuck", "shit", "ass", "bitch", "damn", "crap", "bastard",
        "dick", "pussy", "cock", "cunt", "whore", "slut", "fag",
        "nigger", "nigga", "retard", "nazi", "hitler"
    ]

    /// Initialize
    init() {}

    // MARK: - Group Name Validation

    /// Check if group name length is valid (3-30 characters)
    var isNameLengthValid: Bool {
        newGroupName.count >= 3 && newGroupName.count <= 30
    }

    /// Check if group name contains profanity
    var nameContainsProfanity: Bool {
        let lowercased = newGroupName.lowercased()
        return profanityList.contains { profanity in
            lowercased.contains(profanity)
        }
    }

    /// Check if group name is fully valid
    var isGroupNameValid: Bool {
        isNameLengthValid && !nameContainsProfanity
    }

    /// Validate group name and return error message if invalid
    func validateGroupName() -> String? {
        if newGroupName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter a group name."
        }

        if !isNameLengthValid {
            return "Group name must be 3-30 characters long."
        }

        if nameContainsProfanity {
            return "Group name contains inappropriate content."
        }

        return nil
    }

    /// Generate a random 6-character invite code
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

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

    /// Create a new group
    func createGroup() async -> Bool {
        guard isGroupNameValid else {
            errorMessage = validateGroupName()
            HapticManager.error()
            return false
        }

        guard let userId = currentUserId else {
            errorMessage = "Please sign in to create a group."
            HapticManager.error()
            return false
        }

        isCreating = true
        errorMessage = nil

        do {
            let inviteCode = generateInviteCode()
            let groupName = newGroupName.trimmingCharacters(in: .whitespaces)

            // Insert new group
            let newGroupData: [String: AnyJSON] = [
                "name": .string(groupName),
                "created_by": .string(userId),
                "invite_code": .string(inviteCode)
            ]

            let createdGroup: Group = try await supabase
                .from("groups")
                .insert(newGroupData)
                .select()
                .single()
                .execute()
                .value

            // Auto-add creator as member
            let memberData: [String: AnyJSON] = [
                "group_id": .integer(createdGroup.id),
                "user_id": .string(userId)
            ]

            try await supabase
                .from("group_members")
                .insert(memberData)
                .execute()

            // Reset form
            newGroupName = ""
            isCreating = false
            showCreateSheet = false

            HapticManager.success()

            // Reload data to show new group
            await loadData()

            return true
        } catch {
            isCreating = false
            errorMessage = "Failed to create group. Please try again."
            HapticManager.error()
            return false
        }
    }

    /// Reset create form
    func resetCreateForm() {
        newGroupName = ""
        errorMessage = nil
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
