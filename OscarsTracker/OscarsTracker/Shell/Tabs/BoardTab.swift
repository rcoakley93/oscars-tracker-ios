import SwiftUI

/// Board: the leaderboard in the first column and the selected person in the
/// detail column on regular widths. P4-06 builds the podium and their picks.
struct BoardTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var navigation = model.navigation
        let board = model.leaderboard

        NavigationSplitView {
            LoadStateView(state: board.state, isEmpty: board.entries.isEmpty,
                          empty: ContentUnavailableView("No one on the board yet", systemImage: "trophy", description: Text("Watch a film to get on it."))) {
                List(board.entries, selection: $navigation.selectedPersonID) { entry in
                    let isYou = entry.userId == model.session.userID
                    HStack {
                        Text("\(entry.rank)").font(.headline).fontDesign(.rounded).frame(minWidth: 32)
                        Text(isYou ? "You" : entry.username).fontWeight(isYou ? .bold : .regular)
                        Spacer()
                        Text("\(entry.watchedCount) films").foregroundStyle(.inkMuted)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Number \(entry.rank), \(isYou ? "you" : entry.username), \(entry.watchedCount) films")
                    .tag(entry.userId)
                }
            }
            .tabChrome("Leaderboard")
            .navigationSplitViewColumnWidth(min: 320, ideal: 380)
        } detail: {
            if let entry = board.entries.first(where: { $0.userId == navigation.selectedPersonID }) {
                PersonDetail(entry: entry)
            } else {
                NothingSelected(title: "Choose someone", systemImage: "trophy")
            }
        }
    }
}

private struct PersonDetail: View {
    let entry: LeaderboardEntry

    var body: some View {
        List {
            LabeledContent("Rank", value: "\(entry.rank)")
            LabeledContent("Films watched", value: "\(entry.watchedCount)")
            LabeledContent("Prediction score", value: "\(entry.predictionScore)")
            Text("Their watched films, and their picks after the lock, come in Phase 4.")
                .font(.footnote).foregroundStyle(.inkMuted)
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(entry.username)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Dark") {
    BoardTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    BoardTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    BoardTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
