import SwiftUI
import UIKit

/// Main groups view showing My Groups and Joined Groups sections.
struct GroupsView: View {
    @StateObject private var viewModel = GroupsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading && viewModel.myGroups.isEmpty && viewModel.joinedGroups.isEmpty {
                        loadingView
                    } else if viewModel.myGroups.isEmpty && viewModel.joinedGroups.isEmpty {
                        emptyStateView
                    } else {
                        groupsList
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showJoinSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.goldPrimary)
                    }
                    .accessibilityLabel("Join group")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.goldPrimary)
                    }
                    .accessibilityLabel("Create group")
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateGroupSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showJoinSheet) {
                JoinGroupSheet(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Groups List

    private var groupsList: some View {
        VStack(spacing: 24) {
            // My Groups Section
            if !viewModel.myGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "My Groups", count: viewModel.myGroups.count)

                    ForEach(viewModel.myGroups) { group in
                        NavigationLink {
                            GroupLeaderboardView(group: group)
                        } label: {
                            GroupCard(
                                group: group,
                                onCopyCode: {
                                    viewModel.copyInviteCode(group.inviteCode)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Joined Groups Section
            if !viewModel.joinedGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "Joined Groups", count: viewModel.joinedGroups.count)

                    ForEach(viewModel.joinedGroups) { group in
                        NavigationLink {
                            GroupLeaderboardView(group: group)
                        } label: {
                            GroupCard(
                                group: group,
                                onCopyCode: {
                                    viewModel.copyInviteCode(group.inviteCode)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.goldLight)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.goldPrimary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading groups...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("No groups yet")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Create a group or join one using an invite code")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Card view for displaying a single group.
struct GroupCard: View {
    let group: GroupWithMemberCount
    var onCopyCode: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            // Group icon
            ZStack {
                Circle()
                    .fill(Color.goldPrimary.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.goldPrimary)
            }

            // Group info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(group.name)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    if group.isOwner {
                        Text("Owner")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.goldLight)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.goldPrimary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                HStack(spacing: 12) {
                    // Member count
                    Label("\(group.memberCount) members", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)

                    // Invite code
                    HStack(spacing: 4) {
                        Text(group.inviteCode)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(Color.textMuted)

                        Button {
                            onCopyCode?()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.goldPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy invite code")
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textMuted)
        }
        .padding()
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name), \(group.memberCount) members, invite code: \(group.inviteCode)")
        .accessibilityHint("Double tap to view group leaderboard")
    }
}

/// Placeholder for group leaderboard view.
struct GroupLeaderboardView: View {
    let group: GroupWithMemberCount

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.goldPrimary)
                Text(group.name)
                    .font(.displayMedium)
                    .foregroundStyle(Color.textPrimary)
                Text("Group leaderboard coming soon")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Sheet for creating a new group.
struct CreateGroupSheet: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(Color.goldPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.3.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.goldPrimary)
                    }
                    .padding(.top, 20)

                    // Instructions
                    Text("Create a new group to compete with friends")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Group name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textMuted)

                        TextField("Enter group name", text: $viewModel.newGroupName)
                            .textFieldStyle(OscarsTextFieldStyle())
                            .textContentType(.organizationName)
                            .autocorrectionDisabled()
                            .focused($isNameFocused)
                            .accessibilityLabel("Group name")
                            .accessibilityHint("Enter a name for your new group")

                        // Validation feedback
                        if !viewModel.newGroupName.isEmpty {
                            HStack(spacing: 8) {
                                validationRow(
                                    isValid: viewModel.isNameLengthValid,
                                    text: "3-30 characters"
                                )
                            }
                            HStack(spacing: 8) {
                                validationRow(
                                    isValid: !viewModel.nameContainsProfanity,
                                    text: "No inappropriate content"
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.destructiveLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Create button
                    Button {
                        Task {
                            await viewModel.createGroup()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isCreating {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isCreating ? "Creating..." : "Create Group")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.gold)
                    .disabled(!viewModel.isGroupNameValid || viewModel.isCreating)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetCreateForm()
                        dismiss()
                    }
                    .foregroundStyle(Color.textMuted)
                }
            }
        }
        .onAppear {
            isNameFocused = true
        }
        .interactiveDismissDisabled(viewModel.isCreating)
    }

    private func validationRow(isValid: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(isValid ? Color.success : Color.textMuted)

            Text(text)
                .font(.caption)
                .foregroundStyle(isValid ? Color.success : Color.textMuted)
        }
    }
}

/// Sheet for joining a group with invite code.
struct JoinGroupSheet: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(Color.goldPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.goldPrimary)
                    }
                    .padding(.top, 20)

                    // Instructions
                    Text("Enter an invite code to join a group")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Invite code input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textMuted)

                        TextField("Enter 6-character code", text: $viewModel.inviteCodeInput)
                            .textFieldStyle(OscarsTextFieldStyle())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isCodeFocused)
                            .onChange(of: viewModel.inviteCodeInput) { _, newValue in
                                // Auto uppercase and limit to 6 characters
                                let uppercased = newValue.uppercased()
                                if uppercased.count > 6 {
                                    viewModel.inviteCodeInput = String(uppercased.prefix(6))
                                } else if uppercased != newValue {
                                    viewModel.inviteCodeInput = uppercased
                                }
                            }
                            .accessibilityLabel("Invite code")
                            .accessibilityHint("Enter a 6-character invite code to join a group")

                        // Validation feedback
                        if !viewModel.inviteCodeInput.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isInviteCodeValid ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(viewModel.isInviteCodeValid ? Color.success : Color.textMuted)

                                Text("6 alphanumeric characters")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isInviteCodeValid ? Color.success : Color.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.destructiveLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Join button
                    Button {
                        Task {
                            await viewModel.joinGroup()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isJoining {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isJoining ? "Joining..." : "Join Group")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.gold)
                    .disabled(!viewModel.isInviteCodeValid || viewModel.isJoining)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetJoinForm()
                        dismiss()
                    }
                    .foregroundStyle(Color.textMuted)
                }
            }
        }
        .onAppear {
            isCodeFocused = true
        }
        .interactiveDismissDisabled(viewModel.isJoining)
    }
}

#Preview {
    GroupsView()
        .preferredColorScheme(.dark)
}
