import SwiftUI

/// Ballot (screens.md, 3.4): pick a winner in every category before the
/// lock, then see how you did. On compact widths one column of category
/// cards, where picked categories collapse to a line and open on tap; on
/// regular widths the categories in the first column and the selected one's
/// nominees in the detail column. The selection is
/// `AppNavigation.selectedCategoryID`, so a fold mid-pick keeps it open.
struct BallotTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var navigation = model.navigation
        @Bindable var ballot = model.ballot

        NavigationSplitView {
            LoadStateView(state: ballot.state, isEmpty: ballot.categories.isEmpty, empty: preseason) {
                if sizeClass == .regular {
                    List(selection: $navigation.selectedCategoryID) {
                        BallotIntro().listRowBackground(Color.clear)
                        ForEach(ballot.categories) { category in
                            CategoryRow(category: category)
                                .tag(category.id)
                                .listRowBackground(Color.surface)
                        }
                    }
                } else {
                    BallotCards()
                }
            } placeholder: {
                BallotCards(isPlaceholder: true)
            }
            .tabChrome("Ballot")
            .toolbar {
                // After the lock, which of your groups the "62% picked" lines speak for.
                if model.season.isBallotLocked(), model.groups.groups.count > 1 {
                    ToolbarOverflowMenu {
                        Picker("Group picks", systemImage: "person.3", selection: Binding {
                            model.ballotGroup?.id ?? 0
                        } set: { id in
                            navigation.ballotGroupID = id
                        }) {
                            ForEach(model.groups.groups) { Text($0.name).tag($0.id) }
                        }
                    }
                    .visibilityPriority(.low)
                }
            }
            .safeAreaBar(edge: .top) { BallotStatusBar() }
            // A new choice in the menu, or joining, leaving or deleting the
            // group shown, reloads (or clears) the "62% picked" lines.
            .task(id: model.ballotGroup?.id) { await model.loadPickShares() }
            // The Ballot is a task, so its bar actions win over the tab bar
            // when the Duo's outer screen is short of room.
            .prefersToolbarItemsWhenCompressed()
            .toolbar { ShareCardToolbar() }
            .navigationSplitViewColumnWidth(min: 320, ideal: 360)
            .errorAlert("Couldn't save your pick", error: $ballot.actionError)
        } detail: {
            if let category = ballot.categories.first(where: { $0.id == navigation.selectedCategoryID }) ?? ballot.nextCategory {
                CategoryDetail(category: category)
                    .id(category.id)
            } else {
                NothingSelected(title: "Choose a category", systemImage: "checkmark.seal")
            }
        }
    }

    /// Before nominations: no categories yet.
    private var preseason: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView> {
        ContentUnavailableView(copy.ballotEmpty.title, systemImage: "envelope", description: Text(copy.ballotEmpty.body))
    }
}

/// The voice's line under the title, or your score once winners are in.
private struct BallotIntro: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    var body: some View {
        let ballot = model.ballot
        Group {
            if ballot.hasWinners {
                Text("\(ballot.score) \(ballot.score == 1 ? "point" : "points") so far")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.goldText)
                    .contentTransition(.numericText(value: Double(ballot.score)))
            } else if model.season.isBallotLocked() {
                Text(copy.locked)
            } else if ballot.isComplete {
                Text(copy.ballotComplete(ballot.categories.count))
            } else {
                Text(copy.ballotIntro(ballot.remaining))
            }
        }
        .font(.subheadline)
        .foregroundStyle(.inkMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "18 of 23 categories picked · Locks Sun, Mar 14, 7:00 PM" over a 6 pt gold
/// bar, pinned under the title; "Pens down" once the ballot locks.
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
                .foregroundStyle(.ink)
                .accessibilityIdentifier("ballot-status")
                GoldBar(progress: Double(ballot.pickedCount) / Double(max(ballot.categories.count, 1)))
                    .frame(height: 6)
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

/// A rounded track with the gold gradient filled to `progress`.
private struct GoldBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(.ink.opacity(0.12))
                .overlay(alignment: .leading) {
                    Capsule().fill(Theme.goldGradient)
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
        }
        .animation(.smooth, value: progress)
    }
}

/// Every category as a card, in order. Picked ones collapse to a line and
/// open on tap; the last pick fires gold dust (from the store's save).
private struct BallotCards: View {
    @Environment(AppModel.self) private var model
    var isPlaceholder = false
    /// Picked categories opened again by a tap.
    @State private var opened: Set<Int> = []
    @State private var scrolledID: Int?

    var body: some View {
        let ballot = model.ballot
        let locked = model.season.isBallotLocked()
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Space.m) {
                    BallotIntro()
                    if isPlaceholder {
                        ForEach(BallotCategory.placeholders) { CategoryCard(category: $0, isOpen: true, toggle: {}) }
                    } else {
                        ForEach(ballot.categories) { category in
                            let picked = ballot.pick(for: category.id) != nil
                            CategoryCard(category: category,
                                         isOpen: !picked && !locked && !ballot.hasWinners || opened.contains(category.id)) {
                                withAnimation(.smooth) {
                                    if opened.contains(category.id) { opened.remove(category.id) } else { opened.insert(category.id) }
                                }
                            }
                            .id(category.id)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollPosition(id: $scrolledID, anchor: .top)
            .overlay { GoldDust(trigger: ballot.completions).allowsHitTesting(false) }
            .moment(.ballotComplete, trigger: ballot.completions)
            // A category chosen elsewhere (a notification, search, a link) scrolls
            // to its card, at launch or while the Ballot is already open. After a
            // yield, so the lazy cards exist to scroll to.
            .onChange(of: model.navigation.selectedCategoryID, initial: true) { _, id in
                guard let id, id != scrolledID else { return }
                Task {
                    await Task.yield()
                    withAnimation(.smooth) { proxy.scrollTo(id, anchor: .top) }
                }
            }
            .onChange(of: scrolledID) { _, id in
                if let id { model.navigation.selectedCategoryID = id }
            }
            .onChange(of: ballot.picks) { old, new in
                // A fresh pick in an opened card closes it again.
                let changed = new.filter { old[$0.key] != $0.value }.map(\.key)
                withAnimation(.smooth) { opened.subtract(changed) }
            }
        }
    }
}

/// One category: its name, its points, then its nominees, or, collapsed,
/// your pick on one line.
private struct CategoryCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let category: BallotCategory
    let isOpen: Bool
    var toggle: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let ballot = model.ballot
        let pick = category.nominations.first { $0.id == ballot.pick(for: category.id) }
        let outcome = ballot.outcome(for: category)
        // The points go under the name at accessibility sizes, so the name keeps the width.
        let heading = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.xxs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            heading {
                Text(category.name)
                    .displayFont(.title3)
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CategoryPoints(category: category)
            }
            .contentShape(.rect)
            // Only a picked category collapses and opens again.
            .onTapGesture { if pick != nil { toggle() } }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: isOpen ? "Collapse" : "Show nominees") { if pick != nil { toggle() } }

            if isOpen {
                VStack(spacing: Theme.Space.xs) {
                    ForEach(category.nominations) { NomineeRow(category: category, nominee: $0) }
                }
            } else if let pick {
                PickSummary(category: category, pick: pick, outcome: outcome)
                    .onTapGesture(perform: toggle)
                    .accessibilityAction { toggle() }
            }
            GroupPickLine(category: category)
        }
        .padding(Theme.Space.m)
        .solidSurface()
    }
}

/// A collapsed category: your pick in gold, and once the winner is in,
/// whether you called it.
private struct PickSummary: View {
    @Environment(\.copy) private var copy
    let category: BallotCategory
    let pick: BallotNominee
    let outcome: BallotStore.Outcome?

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: outcome == .wrong ? "xmark.circle" : "checkmark.circle.fill")
                .foregroundStyle(outcome == .wrong ? AnyShapeStyle(.inkMuted) : AnyShapeStyle(Theme.goldGradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.title(in: category) ?? "Your pick")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(outcome == .wrong ? .inkMuted : .goldText)
                if let outcome {
                    Text(outcome == .correct ? copy.correct : copy.wrong)
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                } else if let detail = pick.detail(in: category) {
                    Text(detail).font(.footnote).foregroundStyle(.inkMuted)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your pick: \(pick.spokenName(in: category))")
        .accessibilityValue(outcome.map { $0 == .correct ? "Correct" : "Not this time" } ?? "")
        // A tap opens the nominees again, so VoiceOver hears it's a button.
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(outcome == nil ? "Shows the nominees, to change your pick" : "Shows the nominees")
    }
}

/// The sidebar row on regular widths: the category, your pick, and a check
/// (or, after winners, a trophy or a cross).
private struct CategoryRow: View {
    @Environment(AppModel.self) private var model
    let category: BallotCategory

    var body: some View {
        let pick = category.nominations.first { $0.id == model.ballot.pick(for: category.id) }
        let outcome = model.ballot.outcome(for: category)
        HStack {
            VStack(alignment: .leading) {
                Text(category.name).font(.headline).foregroundStyle(.ink)
                if let pick {
                    Text(pick.spokenName(in: category)).font(.footnote).foregroundStyle(outcome == .wrong ? .inkMuted : .goldText)
                }
            }
            Spacer()
            if model.ballot.points(for: category) != nil {
                CategoryPoints(category: category)
            }
            Image(systemName: outcome == .correct ? "trophy.fill" : outcome == .wrong ? "xmark.circle" : pick == nil ? "circle" : "checkmark.circle.fill")
                .foregroundStyle(pick == nil || outcome == .wrong ? AnyShapeStyle(.inkMuted) : AnyShapeStyle(Theme.goldGradient))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(pick == nil ? "No pick yet" : outcome == .correct ? "Correct" : outcome == .wrong ? "Not this time" : "Picked")
    }
}

/// The selected category on regular widths.
private struct CategoryDetail: View {
    let category: BallotCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                CategoryPoints(category: category)
                ForEach(category.nominations) { NomineeRow(category: category, nominee: $0) }
                GroupPickLine(category: category)
            }
            .padding(Theme.Space.m)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .background { AmbientBackground(posters: category.nominations.compactMap(\.movie?.posterUrl)) }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A nominee as one whole-row choice (screens.md, section 2): the film's
/// thumbnail, the person over the film for acting categories, and a circle
/// that fills with gold when it's your pick, with the voice's line under it.
/// Once the winner is in, a trophy on the winner and a cross on a wrong pick,
/// never red. Read-only after the lock.
private struct NomineeRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let category: BallotCategory
    let nominee: BallotNominee

    var body: some View {
        let ballot = model.ballot
        let picked = ballot.pick(for: category.id) == nominee.id
        let locked = model.season.isBallotLocked()
        let wrong = picked && ballot.outcome(for: category) == .wrong
        Button {
            guard let userID = model.session.userID else { return }
            Task { await ballot.choose(nominationID: nominee.id, in: category.id, userID: userID, locked: locked) }
        } label: {
            HStack(spacing: Theme.Space.s) {
                if let movie = nominee.movie {
                    PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail)
                        .frame(width: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(nominee.title(in: category) ?? "Nominee").font(.body.weight(.semibold)).foregroundStyle(.ink)
                    if let detail = nominee.detail(in: category) {
                        Text(detail).font(.subheadline).foregroundStyle(.inkMuted)
                    } else if !category.leadsWithPerson, let year = nominee.movie?.releaseYear {
                        Text(verbatim: String(year)).font(.subheadline).foregroundStyle(.inkMuted)
                    }
                    if picked, !locked, !ballot.hasWinners {
                        Text(copy.pickSaved(nominee.id))
                            .font(.footnote)
                            .foregroundStyle(.goldText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if nominee.isWinner {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Theme.goldGradient)
                        .accessibilityHidden(true)
                }
                Image(systemName: wrong ? "xmark.circle" : picked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(wrong ? AnyShapeStyle(.inkMuted) : picked ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.hairline))
                    .symbolEffect(.bounce, value: picked)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Theme.Space.s)
            .padding(.vertical, Theme.Space.xs)
            .frame(minHeight: 56)
            .background(Color.ground.opacity(0.35), in: Theme.shape(Theme.Radius.row))
            .overlay {
                if picked && !wrong {
                    Theme.shape(Theme.Radius.row).strokeBorder(.goldText, lineWidth: 1.5)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(locked || ballot.hasWinners)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nominee.spokenName(in: category))
        .accessibilityValue([picked ? "Your pick" : nil, nominee.isWinner ? "Winner" : nil].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(picked ? [.isButton, .isSelected] : .isButton)
        .moment(.pick, trigger: picked)
    }
}

/// "10 pts" before the winner; once it's in, what your pick earned: "+10 pts"
/// in gold when you called it, "0 pts" when you didn't.
private struct CategoryPoints: View {
    @Environment(AppModel.self) private var model
    let category: BallotCategory

    var body: some View {
        let earned = model.ballot.points(for: category)
        Group {
            if let earned, earned > 0 {
                Text(verbatim: "+\(earned) pts").foregroundStyle(.goldText)
            } else if let earned {
                Text(verbatim: "\(earned) pts").foregroundStyle(.inkMuted)
            } else {
                Text(verbatim: "\(category.pointsValue) pts").foregroundStyle(.goldText)
            }
        }
        .font(.subheadline.weight(.semibold))
        .accessibilityLabel(earned.map { "Earned \(Copy.pointCount($0))" } ?? Copy.pointCount(category.pointsValue))
    }
}

/// After the lock, the group's favourite: "62% of Movies LLC picked Hamnet."
private struct GroupPickLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let category: BallotCategory

    var body: some View {
        // Only for the group the Ballot speaks for now, never one you just left.
        if let group = model.ballot.sharesGroup, group.id == model.ballotGroup?.id,
           let top = model.ballot.topShare(for: category) {
            Label {
                Text(copy.groupPicked(top.percent, group.name, top.nominee.title(in: category) ?? "Nominee"))
            } icon: {
                Image(systemName: "person.3")
            }
            .font(.footnote)
            .foregroundStyle(.inkMuted)
            .accessibilityIdentifier("group-picked-\(category.id)")
        }
    }
}

extension BallotCategory {
    /// Stand-ins for the redacted cards while the ballot loads.
    static let placeholders: [BallotCategory] = (1...3).map { id in
        BallotCategory(id: -id, name: "Best Picture", pointsValue: 10, nominations: (1...3).map {
            BallotNominee(id: -(id * 10 + $0), movie: nil, personName: nil, isWinner: false)
        })
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

#Preview("Before nominations") {
    BallotTab().environment(AppModel.preview { $0.categories = [] }).preferredColorScheme(.dark)
}

#Preview("Loading") {
    BallotTab().environment(AppModel(data: SampleDataSource())).preferredColorScheme(.dark)
}

#Preview("Before lock") {
    // Picks open; no group shares until the lock.
    BallotTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("After lock") {
    BallotTab().environment(AppModel.preview { $0.passLock() }).preferredColorScheme(.dark)
}

#Preview("Winners in") {
    BallotTab().environment(AppModel.preview { $0.passLock(winners: true) }).preferredColorScheme(.dark)
}
