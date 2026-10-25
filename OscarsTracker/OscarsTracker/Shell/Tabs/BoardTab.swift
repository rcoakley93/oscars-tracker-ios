import SwiftUI

/// Board (screens.md, 3.6): where you stand, and how far from the top. The
/// red-carpet podium for the top three, the gap to the person above you with
/// a way to catch up, then everyone else. Global or one of your groups, by
/// films watched or, once the ballot locks, by predictions. On regular widths
/// the selected person's season fills the detail column.
struct BoardTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    var body: some View {
        @Bindable var navigation = model.navigation
        let board = model.leaderboard
        let groupID = navigation.boardGroupID
        let entries = board.entries(groupID)

        NavigationSplitView {
            LoadStateView(state: board.state(groupID), isEmpty: entries.isEmpty,
                          empty: ContentUnavailableView(copy.boardEmpty, systemImage: "trophy")) {
                BoardList(groupID: groupID, entries: entries)
            } placeholder: {
                BoardList(groupID: groupID, entries: BoardEntry.placeholders)
            }
            .tabChrome("Leaderboard", subtitle: subtitle(groupID: groupID, size: entries.count))
            .safeAreaBar(edge: .top) {
                Picker("Rank by", selection: $navigation.boardMetric) {
                    Text("Films watched").tag(LeaderboardStore.Metric.films)
                    Text("Predictions").tag(LeaderboardStore.Metric.predictions)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, Theme.Space.xs)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Group", systemImage: "person.3") {
                        Picker("Group", selection: $navigation.boardGroupID) {
                            Text("Global").tag(Int?.none)
                            ForEach(model.groups.groups) { Text($0.name).tag(Int?.some($0.id)) }
                        }
                    }
                }
                .visibilityPriority(.high)
                if model.ballot.hasWinners { ShareCardToolbar() }
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 380)
            .task(id: BoardKey(ceremonyID: model.season.ceremony?.id, groupID: groupID)) {
                if board.boards[groupID] == nil {
                    await board.load(ceremonyID: model.season.ceremony?.id, groupID: groupID)
                }
            }
            .onChange(of: model.groups.groups) {
                // You left the group the board was showing.
                if let groupID, model.groups.state == .loaded, !model.groups.groups.contains(where: { $0.id == groupID }) {
                    navigation.boardGroupID = nil
                }
            }
        } detail: {
            // Wide layouts open on your own season rather than an empty column.
            if let entry = entries.first(where: { $0.userId == navigation.selectedPersonID })
                ?? entries.first(where: { $0.userId == model.session.userID }) {
                PersonDetail(entry: entry, metric: navigation.boardMetric).id(entry.userId)
            } else {
                NothingSelected(title: "Choose someone", systemImage: "trophy")
            }
        }
    }

    /// "Movies LLC · 6 people", or "Everyone · 1,204 people".
    private func subtitle(groupID: Int?, size: Int) -> String {
        let name = model.groups.groups.first { $0.id == groupID }?.name ?? "Everyone"
        guard size > 0 else { return name }
        return "\(name) · \(size.formatted()) \(size == 1 ? "person" : "people")"
    }
}

private struct BoardKey: Hashable {
    let ceremonyID: Int?
    let groupID: Int?
}

/// The podium, the gap card and the rows, in one list so every row can be
/// selected for the detail column.
private struct BoardList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let groupID: Int?
    let entries: [BoardEntry]

    var body: some View {
        @Bindable var navigation = model.navigation
        let metric = navigation.boardMetric
        let ranked = LeaderboardStore.ranked(entries, by: metric)
        let podium = ranked.count >= 2 ? Array(ranked.prefix(3)) : []
        let rest = ranked.dropFirst(podium.count)
        let userID = model.session.userID

        List(selection: $navigation.selectedPersonID) {
            if metric == .predictions, !model.season.isBallotLocked() {
                Section {
                    Label(copy.boardPredictionsLocked, systemImage: "lock")
                        .foregroundStyle(.ink)
                }
                .listRowBackground(Color.surface)
            } else {
                if !podium.isEmpty {
                    Section {
                        Podium(places: podium, metric: metric, userID: userID) { navigation.selectedPersonID = $0 }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: Theme.Space.s, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                if ranked.count == 1, groupID != nil {
                    Section {
                        Text(copy.boardAlone).foregroundStyle(.ink)
                    }
                    .listRowBackground(Color.surface)
                } else if let userID {
                    GapCard(groupID: groupID, userID: userID, metric: metric)
                }
                Section {
                    ForEach(rest, id: \.entry.userId) { place in
                        BoardRow(rank: place.rank, entry: place.entry, metric: metric, isYou: place.entry.userId == userID)
                            .tag(place.entry.userId)
                            .listRowBackground(Color.surface)
                            .personActions(userID: place.entry.userId, name: place.entry.username)
                    }
                }
            }
        }
        .animation(.default, value: entries)
    }
}

/// The red carpet: three velvet steps, the leader's tallest and crowned with
/// the trophy, second on the left and third on the right. The screen's only
/// velvet. VoiceOver reads it as one element.
private struct Podium: View {
    let places: [(rank: Int, entry: BoardEntry)]
    let metric: LeaderboardStore.Metric
    let userID: String?
    let select: (String) -> Void

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1
    private let heights: [CGFloat] = [128, 92, 68]

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Space.xs) {
            ForEach([1, 0, 2].filter { $0 < places.count }, id: \.self) { index in
                step(index)
            }
        }
        .padding(.horizontal, Theme.Space.m)
        // Three columns on a phone can't hold accessibility sizes; the rows
        // below and VoiceOver's label carry the same facts at full size.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityActions {
            ForEach(places, id: \.entry.userId) { place in
                Button("Open \(name(place.entry))") { select(place.entry.userId) }
            }
        }
    }

    private func step(_ index: Int) -> some View {
        let place = places[index]
        let isYou = place.entry.userId == userID
        return Button {
            select(place.entry.userId)
        } label: {
            VStack(spacing: Theme.Space.xxs) {
                Avatar(name: place.entry.username, url: place.entry.avatarUrl, size: (index == 0 ? 64 : 52) * min(scale, 1.4), isYou: isYou)
                Text(name(place.entry))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isYou ? AnyShapeStyle(.goldText) : AnyShapeStyle(.ink))
                    .lineLimit(1)
                Text(BoardRow.value(place.entry, metric))
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                ZStack(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.thumbnail, topTrailingRadius: Theme.Radius.thumbnail, style: .continuous)
                        .fill(Color.velvet.gradient)
                    VStack(spacing: Theme.Space.xxs) {
                        if index == 0 {
                            Image(systemName: "trophy.fill").foregroundStyle(.gold)
                        }
                        Text(verbatim: "\(place.rank)")
                            .displayFont(.title2)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(.top, Theme.Space.s)
                }
                .frame(height: heights[index])
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .personActions(userID: place.entry.userId, name: place.entry.username)
    }

    private func name(_ entry: BoardEntry) -> String {
        entry.userId == userID ? "You" : entry.username
    }

    /// "Podium: Sam first with 31 films, you second with 29, Jordan third with 24".
    private var label: String {
        let words = ["first", "second", "third"]
        let parts = places.enumerated().map { index, place in
            let who = place.entry.userId == userID ? "you" : place.entry.username
            let value = index == 0 ? BoardRow.value(place.entry, metric) : "\(LeaderboardStore.value(place.entry, metric))"
            return "\(who) \(words[min(place.rank, 3) - 1]) with \(value)"
        }
        return "Podium: " + parts.joined(separator: ", ")
    }
}

/// How far you are from the person above you, with a way to close it.
private struct GapCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @AppStorage("films.hidesWatched") private var hidesWatched = false
    let groupID: Int?
    let userID: String
    let metric: LeaderboardStore.Metric

    var body: some View {
        if let standing = model.leaderboard.standing(in: groupID, userID: userID, metric: metric) {
            Section {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(line(standing.position))
                        .font(.body)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if metric == .films, standing.position != .first, !model.films.toWatch.isEmpty {
                        Button("Catch up", systemImage: "film") {
                            hidesWatched = true
                            model.navigation.tab = .films
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.ink)
                        .fontWeight(.semibold)
                        .accessibilityHint("Shows the films you haven't watched")
                    }
                }
                .padding(.vertical, Theme.Space.xxs)
            }
            .listRowBackground(Color.surface)
        }
    }

    private func line(_ position: LeaderboardStore.Standing.Position) -> String {
        switch position {
        case .first: copy.boardLeader
        case .tied(let name): copy.compareTied(name)
        case .behind(let name, let gap): metric == .films ? copy.compareGap(gap, name) : copy.scoreGap(gap, name)
        }
    }
}

/// A board row: rank, avatar, name (gold when it's you) and the count.
struct BoardRow: View {
    let rank: Int
    let entry: BoardEntry
    let metric: LeaderboardStore.Metric
    let isYou: Bool

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Text(verbatim: "\(rank)")
                .displayFont(.headline)
                .foregroundStyle(.inkMuted)
                .frame(minWidth: 28, alignment: .leading)
            Avatar(name: entry.username, url: entry.avatarUrl, isYou: isYou)
            Text(isYou ? "You" : entry.username)
                .font(.body.weight(isYou ? .semibold : .regular))
                .foregroundStyle(isYou ? AnyShapeStyle(.goldText) : AnyShapeStyle(.ink))
                .lineLimit(1)
            Spacer(minLength: Theme.Space.xs)
            Text(Self.value(entry, metric))
                .foregroundStyle(.inkMuted)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Number \(rank), \(isYou ? "you" : entry.username), \(Self.value(entry, metric))")
    }

    /// "29 films", "3 correct" or "12 points".
    static func value(_ entry: BoardEntry, _ metric: LeaderboardStore.Metric) -> String {
        switch (metric, entry.scoring) {
        case (.films, _): Copy.filmCount(entry.watchedCount)
        case (.predictions, .traditional): "\(entry.correctCount) correct"
        case (.predictions, .weighted): Copy.pointCount(entry.points)
        }
    }
}

/// One person's season: their numbers, then their picks after the lock or
/// the nominees they've watched before it. Their films and picks show only
/// to people who share a group with them.
private struct PersonDetail: View {
    @Environment(AppModel.self) private var model
    let entry: BoardEntry
    let metric: LeaderboardStore.Metric
    @State private var confirmsBlock = false

    var body: some View {
        let isYou = entry.userId == model.session.userID
        let locked = model.season.isBallotLocked()
        let loaded = model.leaderboard.people[entry.userId]
        List {
            Section {
                LabeledContent("Films watched", value: "\(entry.watchedCount)")
                if locked {
                    LabeledContent(entry.scoring == .weighted ? "Points" : "Correct picks",
                                   value: "\(entry.scoring == .weighted ? entry.points : entry.correctCount)")
                }
            }
            .listRowBackground(Color.surface)

            switch loaded {
            case .some(.some(let person)):
                if locked {
                    picks(person)
                } else {
                    watched(person)
                }
            case .some(.none):
                Section {
                    Text("Their films and picks show to people in their groups.")
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                }
                .listRowBackground(Color.clear)
            case .none:
                Section {
                    ProgressView().frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(isYou ? "You" : entry.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isYou {
                ToolbarOverflowMenu {
                    PersonMenuItems(userID: entry.userId, name: entry.username, confirmsBlock: $confirmsBlock)
                }
            }
        }
        .blockConfirmation(isPresented: $confirmsBlock, userID: entry.userId, name: entry.username)
        // Again whenever a refresh clears the people loaded so far.
        .task(id: loaded == nil) { await model.leaderboard.loadPerson(entry.userId) }
    }

    private func picks(_ person: BoardPerson) -> some View {
        Section("Picks") {
            ForEach(model.ballot.categories.filter { person.picks[$0.id] != nil }) { category in
                if let nominee = category.nominations.first(where: { $0.id == person.picks[category.id] }) {
                    PickRow(category: category, nominee: nominee, hasWinner: category.nominations.contains(where: \.isWinner))
                        .listRowBackground(Color.surface)
                }
            }
        }
    }

    private func watched(_ person: BoardPerson) -> some View {
        Section("Watched") {
            ForEach(model.films.movies.filter { person.watchedMovieIDs.contains($0.id) }) { movie in
                HStack(spacing: Theme.Space.s) {
                    PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail).frame(width: 36)
                    Text(movie.title).foregroundStyle(.ink)
                }
                .listRowBackground(Color.surface)
            }
        }
    }
}

/// A category and someone's pick in it, with the trophy or the cross once the
/// winner is in (never colour alone).
private struct PickRow: View {
    let category: BallotCategory
    let nominee: BallotNominee
    let hasWinner: Bool

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name).font(.footnote).foregroundStyle(.inkMuted)
                Text(nominee.title(in: category) ?? "Nominee")
                    .foregroundStyle(.ink)
                if let detail = nominee.detail(in: category) {
                    Text(detail).font(.subheadline).foregroundStyle(.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if nominee.isWinner {
                Image(systemName: "trophy.fill").foregroundStyle(.gold).accessibilityLabel("Won")
            } else if hasWinner {
                Image(systemName: "xmark").foregroundStyle(.inkMuted).accessibilityLabel("Didn't win")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension BoardEntry {
    /// Stand-ins for the redacted board while it loads.
    static let placeholders: [BoardEntry] = (1...6).map {
        BoardEntry(rank: $0, userId: "placeholder-\($0)", username: "Someone", avatarUrl: nil, watchedCount: 30 - $0 * 3,
                   correctCount: 0, points: 0, score: 0, scoring: .traditional, isCreator: false)
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

#Preview("Alone in a group") {
    let model = AppModel.preview()
    model.navigation.boardGroupID = 2
    return BoardTab().environment(model).preferredColorScheme(.dark)
}

#Preview("Predictions before the lock") {
    let model = AppModel.preview()
    model.navigation.boardMetric = .predictions
    return BoardTab().environment(model).preferredColorScheme(.dark)
}

#Preview("Someone blocked") {
    let model = AppModel.preview { data in
        data.blocked = [BlockedUser(userId: "u-jordan", username: "Jordan", avatarUrl: nil, blockedAt: nil)]
    }
    return BoardTab().environment(model).preferredColorScheme(.dark)
}

#Preview("After winners") {
    let model = AppModel.preview { data in
        data.ceremony = Ceremony(id: 2, number: 99, name: "99th Academy Awards", ceremonyAt: .now.addingTimeInterval(-3600),
                                 ballotLockAt: .now.addingTimeInterval(-7200), isActive: true)
        data.board = [
            .sample(SampleDataSource.userID, "filmbuff", watched: 29, rank: 1, score: 14),
            .sample("u-sam", "Sam", watched: 31, rank: 2, score: 12),
            .sample("u-jordan", "Jordan", watched: 24, rank: 2, score: 12),
            .sample("u-alex", "Alex", watched: 19, rank: 4, score: 9),
        ]
    }
    model.navigation.boardMetric = .predictions
    return BoardTab().environment(model).preferredColorScheme(.dark)
}
