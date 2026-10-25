import SwiftUI

/// Your standing in a group (P6-07): "2nd of 6 in Movies LLC", the gap to the
/// person just above you and the lead over the person just below. On Films it
/// shows one of your groups, a menu picks which, and a tap opens the board; on
/// a group's own screen (`group` given) it is that group, with no menu.
struct GroupComparisonCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @AppStorage("films.compareGroup") private var chosenGroupID = 0
    var group: PoolGroup?

    var body: some View {
        let groups = model.groups.groups
        if let userID = model.session.userID,
           let group = group ?? groups.first(where: { $0.id == chosenGroupID }) ?? groups.first {
            let standing = model.leaderboard.standing(in: group.id, userID: userID)
            let size = model.leaderboard.entries(group.id).count
            HStack(alignment: .center, spacing: Theme.Space.s) {
                content(standing, size: size, group: group)
                if self.group == nil, groups.count > 1 {
                    Menu {
                        Picker("Group", selection: Binding { group.id } set: { chosenGroupID = $0 }) {
                            ForEach(groups) { Text($0.name).tag($0.id) }
                        }
                    } label: {
                        Label("Group", systemImage: "person.3")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.inkMuted)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
            .padding(.vertical, Theme.Space.s)
            .padding(.horizontal, Theme.Space.m)
            .solidSurface()
            .redacted(reason: standing == nil ? .placeholder : [])
            .task(id: group.id) {
                if model.leaderboard.boards[group.id] == nil {
                    await model.leaderboard.load(ceremonyID: model.season.ceremony?.id, groupID: group.id)
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ standing: LeaderboardStore.Standing?, size: Int, group: PoolGroup) -> some View {
        let text = VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(standing.map { copy.compareRank($0.rank, $0.size, group.name) } ?? group.name)
                .font(.headline)
                .foregroundStyle(.ink)
            ForEach(Self.lines(standing, size: size, copy: copy), id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        if self.group == nil {
            Button {
                model.navigation.boardGroupID = group.id
                model.navigation.boardMetric = .films
                model.navigation.tab = .board
            } label: { text }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the group's board")
        } else {
            text
        }
    }

    /// The card's lines under the rank: the gap above you, then the lead over
    /// the person below. Alone in the group there's neither.
    static func lines(_ standing: LeaderboardStore.Standing?, size: Int, copy: Copy) -> [String] {
        guard let standing else { return ["Checking the board"] }
        if size <= 1 { return [copy.boardAlone] }
        var lines: [String] = []
        switch standing.position {
        case .first: lines.append(copy.boardLeader)
        case .tied(let name): lines.append(copy.compareTied(name))
        case .behind(let name, let films): lines.append(copy.compareGap(films, name))
        }
        if let chaser = standing.chaser { lines.append(copy.compareChaser(chaser.by, chaser.name)) }
        return lines
    }
}

#Preview("Dark") {
    CardPreview().preferredColorScheme(.dark)
}

#Preview("Light") {
    CardPreview().preferredColorScheme(.light)
}

#Preview("Large text") {
    CardPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("First place") {
    CardPreview(board: [.sample(SampleDataSource.userID, "filmbuff", watched: 31, rank: 1),
                        .sample("u-sam", "Sam", watched: 28, rank: 2),
                        .sample("u-jo", "Jo", watched: 12, rank: 3)])
}

#Preview("Last place") {
    CardPreview(board: [.sample("u-sam", "Sam", watched: 28, rank: 1),
                        .sample("u-jo", "Jo", watched: 20, rank: 2),
                        .sample(SampleDataSource.userID, "filmbuff", watched: 4, rank: 3)])
}

#Preview("Tie") {
    CardPreview(board: [.sample("u-sam", "Sam", watched: 20, rank: 1),
                        .sample(SampleDataSource.userID, "filmbuff", watched: 20, rank: 1),
                        .sample("u-jo", "Jo", watched: 9, rank: 3)])
}

#Preview("Solo group") {
    CardPreview(board: [.sample(SampleDataSource.userID, "filmbuff", watched: 12, rank: 1)])
}

private struct CardPreview: View {
    var board: [BoardEntry]?
    var body: some View {
        List {
            GroupComparisonCard(group: PoolGroup(id: 1, name: "Movies LLC", createdBy: SampleDataSource.userID, inviteCode: "OSCAR9", createdAt: nil))
                .listRowInsets(.init()).listRowBackground(Color.clear)
        }
        .environment(AppModel.preview { data in if let board { data.board = board } })
    }
}
