import SwiftUI

/// Ballot: every category in one list on compact widths; on regular widths
/// the categories in the first column and the selected one's nominees in the
/// detail column. The selection is `AppNavigation.selectedCategoryID`, so a
/// fold mid-pick keeps the category open. P4-05 builds the real screen.
struct BallotTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var navigation = model.navigation
        let ballot = model.ballot

        NavigationSplitView {
            LoadStateView(state: ballot.state, isEmpty: ballot.categories.isEmpty,
                          empty: ContentUnavailableView("No categories yet", systemImage: "checkmark.seal", description: Text("Check back when nominations are announced."))) {
                if sizeClass == .regular {
                    List(selection: $navigation.selectedCategoryID) {
                        ForEach(ballot.categories) { category in
                            CategoryRow(category: category).tag(category.id)
                        }
                    }
                } else {
                    // One list of every category, opened at the category that
                    // was open in the detail column before the fold.
                    ScrollViewReader { proxy in
                        List {
                            ForEach(ballot.categories) { category in
                                Section(category.name) {
                                    ForEach(category.nominations) { NomineeRow(category: category, nominee: $0) }
                                }
                                .id(category.id)
                            }
                        }
                        .onAppear {
                            if let id = navigation.selectedCategoryID { proxy.scrollTo(id, anchor: .top) }
                        }
                    }
                }
            }
            .tabChrome("Ballot")
            .safeAreaBar(edge: .top) { BallotStatusBar() }
            // The Ballot is a task, so its bar actions win over the tab bar
            // when the Duo's outer screen is short of room.
            .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
            .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        } detail: {
            if let category = ballot.categories.first(where: { $0.id == navigation.selectedCategoryID }) ?? ballot.nextCategory {
                CategoryDetail(category: category)
            } else {
                NothingSelected(title: "Choose a category", systemImage: "checkmark.seal")
            }
        }
    }
}

/// "18 of 23 categories picked · Locks Sun, Mar 14, 7:00 PM" over a gold bar,
/// pinned under the title.
private struct BallotStatusBar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    var body: some View {
        let ballot = model.ballot
        if !ballot.categories.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Group {
                    if model.season.isBallotLocked() {
                        Text(copy.locked)
                    } else if let lock = model.season.ceremony?.ballotLockAt {
                        Text("\(copy.ballotProgress(ballot.pickedCount, ballot.categories.count)) · Locks \(lock, format: .dateTime.weekday(.abbreviated).month().day().hour().minute())")
                    } else {
                        Text(copy.ballotProgress(ballot.pickedCount, ballot.categories.count))
                    }
                }
                .font(.footnote.weight(.medium))
                ProgressView(value: Double(ballot.pickedCount), total: Double(ballot.categories.count))
                    .tint(.gold)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Theme.Space.m)
            .padding(.bottom, Theme.Space.xs)
            // Pinned over the list, so it stops growing before it can
            // cover the picks it counts.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct CategoryRow: View {
    @Environment(AppModel.self) private var model
    let category: BallotCategory

    var body: some View {
        let pick = category.nominations.first { $0.id == model.ballot.pick(for: category.id) }
        HStack {
            VStack(alignment: .leading) {
                Text(category.name).font(.headline)
                if let pick {
                    Text(pick.spokenName).font(.footnote).foregroundStyle(.goldText)
                }
            }
            Spacer()
            Image(systemName: pick == nil ? "circle" : "checkmark.circle.fill")
                .foregroundStyle(pick == nil ? AnyShapeStyle(.inkMuted) : AnyShapeStyle(Theme.goldGradient))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(pick == nil ? "No pick yet" : "Picked")
    }
}

private struct CategoryDetail: View {
    let category: BallotCategory

    var body: some View {
        List {
            ForEach(category.nominations) { NomineeRow(category: category, nominee: $0) }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NomineeRow: View {
    @Environment(AppModel.self) private var model
    let category: BallotCategory
    let nominee: BallotNominee

    var body: some View {
        let picked = model.ballot.pick(for: category.id) == nominee.id
        Button {
            guard let userID = model.session.userID else { return }
            Task { await model.ballot.choose(nominationID: nominee.id, in: category.id, userID: userID, locked: model.season.isBallotLocked()) }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(nominee.personName ?? nominee.movie?.title ?? "Nominee").font(.headline)
                    if nominee.personName != nil, let film = nominee.movie?.title {
                        Text(film).font(.footnote).foregroundStyle(.inkMuted)
                    }
                }
                Spacer()
                if nominee.isWinner {
                    Label("Winner", systemImage: "star.fill").font(.caption.bold()).foregroundStyle(.goldText)
                }
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(picked ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.inkMuted))
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nominee.spokenName)
        .accessibilityValue([picked ? "Your pick" : nil, nominee.isWinner ? "Winner" : nil].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(picked ? [.isButton, .isSelected] : .isButton)
        .sensoryFeedback(.selection, trigger: picked)
    }
}

extension BallotNominee {
    /// "Jessie Buckley, in Hamnet" for acting categories, else the film.
    var spokenName: String {
        if let person = personName, !person.isEmpty {
            if let film = movie?.title { return "\(person), in \(film)" }
            return person
        }
        return movie?.title ?? "Nominee"
    }
}

#Preview("Dark") {
    BallotTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    BallotTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    BallotTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
