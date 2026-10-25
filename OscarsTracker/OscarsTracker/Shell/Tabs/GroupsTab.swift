import SwiftUI

/// Groups (screens.md, 3.7): play with friends. Your groups as rows (name,
/// size, your rank), Join and Create in an Add menu, and the group's board,
/// invite and admin in the detail column on regular widths.
struct GroupsTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    var body: some View {
        @Bindable var navigation = model.navigation
        let groups = model.groups

        NavigationSplitView {
            LoadStateView(state: groups.state, isEmpty: groups.groups.isEmpty) {
                List(groups.groups, selection: $navigation.selectedGroupID) { group in
                    GroupRow(group: group)
                        .tag(group.id)
                        .listRowBackground(Color.surface)
                        .contextMenu {
                            if group.createdBy != model.session.userID {
                                Button("Report group", systemImage: "flag") {
                                    navigation.sheet = .report(.group(id: group.id, name: group.name))
                                }
                            }
                        }
                }
            } placeholder: {
                List(PoolGroup.placeholders) { GroupRow(group: $0).listRowBackground(Color.surface) }
            }
            .overlay {
                if groups.groups.isEmpty, groups.state == .loaded {
                    ContentUnavailableView {
                        Label(copy.groupsEmpty.title, systemImage: "person.3")
                    } description: {
                        Text(copy.groupsEmpty.body)
                    } actions: {
                        Button("Join a group", systemImage: "link") { navigation.sheet = .joinGroup(code: nil) }
                            .buttonStyle(.glass)
                        Button("Create a group", systemImage: "person.3") { navigation.sheet = .createGroup }
                            .buttonStyle(.glass)
                    }
                }
            }
            .tabChrome("Groups")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Add", systemImage: "plus") {
                        Button("Join a group", systemImage: "link") { navigation.sheet = .joinGroup(code: nil) }
                        Button("Create a group", systemImage: "person.3") { navigation.sheet = .createGroup }
                    }
                }
                .visibilityPriority(.high)
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 380)
            .goldDust(trigger: groups.joins)
        } detail: {
            // Wide layouts open on your first group rather than an empty column.
            if let group = groups.groups.first(where: { $0.id == navigation.selectedGroupID }) ?? groups.groups.first {
                GroupDetail(group: group).id(group.id)
            } else {
                NothingSelected(title: "Choose a group", systemImage: "person.3")
            }
        }
    }
}

/// "Movies LLC", then "6 people · You're 2nd".
private struct GroupRow: View {
    @Environment(AppModel.self) private var model
    let group: PoolGroup

    var body: some View {
        let board = model.leaderboard.entries(group.id)
        let standing = model.session.userID.flatMap { model.leaderboard.standing(in: group.id, userID: $0) }
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(group.name).font(.headline).foregroundStyle(.ink)
            Text(detail(size: board.count, standing: standing))
                .font(.subheadline)
                .foregroundStyle(.inkMuted)
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
        .task(id: group.id) {
            guard group.id > 0, model.leaderboard.boards[group.id] == nil else { return }
            await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id)
        }
    }

    private func detail(size: Int, standing: LeaderboardStore.Standing?) -> String {
        guard size > 0 else { return "Loading the board" }
        guard let standing, size > 1 else { return size == 1 ? "Just you" : "\(size) people" }
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        return "\(size) people · You're \(ordinal.string(from: standing.rank as NSNumber) ?? "\(standing.rank)")"
    }
}

/// One group: its board, the invite code, and Leave; for the creator,
/// Remove (swipe) and Delete; for everyone else, Report group. Each person
/// has Report and Block in their context menu. Invite is pinned to the top
/// bar so it never overflows on the Duo.
private struct GroupDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let group: PoolGroup
    @State private var confirmsDelete = false
    @State private var confirmsLeave = false

    var body: some View {
        let userID = model.session.userID
        let isCreator = group.createdBy == userID
        let ranked = LeaderboardStore.ranked(model.leaderboard.entries(group.id), by: .films)

        List {
            Section {
                GroupComparisonCard(group: group)
                    .listRowInsets(.init()).listRowBackground(Color.clear)
            }
            Section("Board") {
                if ranked.count == 1 {
                    Text(copy.boardAlone).foregroundStyle(.ink).listRowBackground(Color.surface)
                }
                ForEach(ranked, id: \.entry.userId) { place in
                    BoardRow(rank: place.rank, entry: place.entry, metric: .films, isYou: place.entry.userId == userID)
                        .badge(place.entry.isCreator ? Text("Creator") : nil)
                        .listRowBackground(Color.surface)
                        .swipeActions {
                            if isCreator, place.entry.userId != userID {
                                Button("Remove", systemImage: "person.badge.minus", role: .destructive) {
                                    Task { await remove(place.entry.userId) }
                                }
                            }
                        }
                        .accessibilityActions {
                            if isCreator, place.entry.userId != userID {
                                Button("Remove \(place.entry.username)") { Task { await remove(place.entry.userId) } }
                            }
                        }
                        .personActions(userID: place.entry.userId, name: place.entry.username)
                }
            }
            Section {
                LabeledContent("Invite code") {
                    Text(verbatim: group.inviteCode)
                        .font(.body.monospaced().weight(.semibold))
                        .foregroundStyle(.ink)
                        .textSelection(.enabled)
                }
                .listRowBackground(Color.surface)
            } footer: {
                Text("Up to \(model.season.config.groupMemberLimit) people. Friends join from the invite, or with the code in Groups → Add → Join a group.")
            }
            Section {
                Button("Open on the Board", systemImage: "trophy") {
                    model.navigation.boardGroupID = group.id
                    model.navigation.tab = .board
                }
                .listRowBackground(Color.surface)
                if !isCreator {
                    Button("Leave group", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        confirmsLeave = true
                    }
                    .listRowBackground(Color.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id) }
        .toolbar {
            ToolbarItem(placement: .topBarPinnedTrailing) {
                InviteButton(group: group)
            }
            ToolbarOverflowMenu {
                if isCreator {
                    Button("Delete group", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                } else {
                    Button("Report group", systemImage: "flag") {
                        model.navigation.sheet = .report(.group(id: group.id, name: group.name))
                    }
                }
            }
        }
        .confirmationDialog("Delete \(group.name)?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete group", role: .destructive) {
                Task {
                    await model.groups.delete(group.id)
                    if model.groups.actionError == nil { model.navigation.selectedGroupID = nil }
                }
            }
        } message: {
            Text("Everyone in it loses the group's board. This can't be undone.")
        }
        .confirmationDialog("Leave \(group.name)?", isPresented: $confirmsLeave, titleVisibility: .visible) {
            Button("Leave group", role: .destructive) {
                guard let userID else { return }
                Task {
                    await model.groups.leave(group.id, userID: userID)
                    if model.groups.actionError == nil { model.navigation.selectedGroupID = nil }
                }
            }
        } message: {
            Text("You can join again with the invite code.")
        }
        .errorAlert("Couldn't change the group", error: Bindable(model.groups).actionError)
        .task { await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id) }
    }

    private func remove(_ userID: String) async {
        await model.groups.remove(member: userID, from: group.id)
        await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id)
    }
}

/// Shares the invite link, or the code alone until the website exists.
struct InviteButton: View {
    let group: PoolGroup

    var body: some View {
        let message = "Join \(group.name) on Oscars Tracker. Invite code: \(group.inviteCode)"
        if let url = InviteLink.url(code: group.inviteCode) {
            ShareLink(item: url, subject: Text(Copy.inviteSubject), message: Text(message)) {
                Label("Invite", systemImage: "square.and.arrow.up")
            }
        } else {
            ShareLink(item: message, subject: Text(Copy.inviteSubject)) {
                Label("Invite", systemImage: "square.and.arrow.up")
            }
        }
    }
}

extension PoolGroup {
    /// Stand-ins for the redacted list while groups load.
    static let placeholders: [PoolGroup] = (1...3).map {
        PoolGroup(id: -$0, name: "Group name", createdBy: "", inviteCode: "XXXXXX", createdAt: nil)
    }
}

#Preview("Dark") {
    GroupsTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    GroupsTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    GroupsTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("No groups") {
    GroupsTab().environment(AppModel.preview { $0.groups = [] }).preferredColorScheme(.dark)
}

#Preview("Group detail") {
    let model = AppModel.preview()
    model.navigation.selectedGroupID = 1
    return NavigationStack { GroupDetail(group: PoolGroup(id: 1, name: "Movies LLC", createdBy: SampleDataSource.userID, inviteCode: "OSCAR9", createdAt: nil)) }.environment(model).preferredColorScheme(.dark)
}

#Preview("Someone else's group") {
    let model = AppModel.preview()
    model.navigation.selectedGroupID = 2
    return NavigationStack { GroupDetail(group: PoolGroup(id: 2, name: "Family pool", createdBy: "someone-else", inviteCode: "FAMILY", createdAt: nil)) }.environment(model).preferredColorScheme(.light)
}
