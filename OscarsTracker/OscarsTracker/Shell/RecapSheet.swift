import SwiftUI

/// The results recap (P6-10): after the show, your score in gold, how many
/// winners you called, your place, and every announced category with your
/// pick marked. Gold dust once when you called at least one; nothing for a
/// shut-out, because gold is earned.
struct RecapSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss
    @State private var burst = 0
    @ScaledMetric(relativeTo: .largeTitle) private var scoreSize: CGFloat = 72

    private var decided: [BallotCategory] { model.ballot.categories.filter { !$0.winnerIDs.isEmpty } }
    private var isFinal: Bool { !model.ballot.categories.isEmpty && decided.count == model.ballot.categories.count }
    private var called: Int { model.ballot.calledCount }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                Section {
                    ForEach(decided) { category in
                        LiveBoardRow(category: category, pick: model.ballot.pick(for: category.id))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.ground)
            .navigationTitle("Recap")
            .navigationSubtitle(model.season.ceremony?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
                .visibilityPriority(.high)
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Share score", systemImage: "square.and.arrow.up") {
                        model.navigation.sheet = .shareCard
                    }
                    .disabled(model.shareCard == nil)
                }
                .visibilityPriority(.low)
            }
        }
        .presentationDetents([.large])
        .task {
            guard called > 0 else { return }
            try? await Task.sleep(for: .milliseconds(350))
            burst += 1
        }
        .moment(.correct, trigger: burst)
    }

    private var header: some View {
        VStack(spacing: Theme.Space.xs) {
            Text(copy.recapEyebrow(isFinal)).font(.system(.title3, design: .serif)).foregroundStyle(.goldText)
            Text(model.ballot.score, format: .number)
                .font(.system(size: scoreSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .foregroundStyle(Theme.goldGradient)
                .goldDust(trigger: burst)
            Text(copy.heroAfter(isFinal)).font(.subheadline).foregroundStyle(.inkMuted)
            Text(copy.callTally(called, decided.count, isFinal)).font(.headline).multilineTextAlignment(.center)
            if let line = standingLine {
                Text(line).font(.subheadline.monospacedDigit()).foregroundStyle(.inkMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// Your place on your first group's board, else the global one.
    private var standingLine: String? {
        guard let userID = model.session.userID else { return nil }
        let boards = model.groups.groups.map { (Optional($0.id), $0.name) } + [(nil, "everyone")]
        for (groupID, name) in boards {
            if let standing = model.leaderboard.standing(in: groupID, userID: userID, metric: .predictions) {
                return Copy.rankLine(standing.rank, standing.size, name)
            }
        }
        return nil
    }
}

#Preview("Dark") {
    Color.clear.sheet(isPresented: .constant(true)) { RecapSheet() }
        .environment(AppModel.livePreview(queued: false)).preferredColorScheme(.dark)
}

#Preview("Light") {
    Color.clear.sheet(isPresented: .constant(true)) { RecapSheet() }
        .environment(AppModel.livePreview(queued: false)).preferredColorScheme(.light)
}

#Preview("Large text") {
    Color.clear.sheet(isPresented: .constant(true)) { RecapSheet() }
        .environment(AppModel.livePreview(queued: false)).preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}
