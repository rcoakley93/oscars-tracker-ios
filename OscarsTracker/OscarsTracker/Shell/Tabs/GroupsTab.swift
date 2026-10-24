import SwiftUI

/// Groups: your groups in the first column and the selected group in the
/// detail column on regular widths. Join and Create live in an Add menu.
/// P4-07 builds the real screen.
struct GroupsTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var navigation = model.navigation
        let groups = model.groups

        NavigationSplitView {
            LoadStateView(state: groups.state, isEmpty: groups.groups.isEmpty,
                          empty: ContentUnavailableView("No groups yet", systemImage: "person.3", description: Text("Create a group, or join one with an invite code."))) {
                List(groups.groups, selection: $navigation.selectedGroupID) { group in
                    VStack(alignment: .leading) {
                        Text(group.name).font(.headline)
                        Text("Invite code \(group.inviteCode)").font(.footnote).foregroundStyle(.inkMuted)
                    }
                    .tag(group.id)
                }
            }
            .tabChrome("Groups")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Add", systemImage: "plus") {
                        Button("Join a group", systemImage: "person.badge.plus") {
                            model.navigation.sheet = .joinGroup(code: nil)
                        }
                        Button("Create a group", systemImage: "plus.circle") {
                            model.navigation.sheet = .createGroup
                        }
                    }
                }
                .visibilityPriority(.high)
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 380)
        } detail: {
            if let group = groups.groups.first(where: { $0.id == navigation.selectedGroupID }) {
                GroupDetail(group: group)
            } else {
                NothingSelected(title: "Choose a group", systemImage: "person.3")
            }
        }
    }
}

private struct GroupDetail: View {
    @Environment(AppModel.self) private var model
    let group: PoolGroup

    var body: some View {
        List {
            Section("Board") {
                ForEach(model.leaderboard.entries(group.id)) { entry in
                    HStack {
                        Text(entry.username)
                        Spacer()
                        Text("\(entry.watchedCount) films").foregroundStyle(.inkMuted)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Section {
                LabeledContent("Invite code", value: group.inviteCode)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: group.id) { await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id) }
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
