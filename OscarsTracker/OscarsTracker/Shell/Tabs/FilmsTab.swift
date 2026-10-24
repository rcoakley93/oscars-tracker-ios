import SwiftUI

/// Films (screens.md, 3.1): the hero, then the films still to watch and the
/// ones you've watched as a poster grid, or by category. On compact widths a
/// film opens in a sheet; on regular widths in the detail column. The
/// selection is `AppNavigation.selectedMovieID` either way, so a fold moves
/// the open film between the two.
struct FilmsTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case all, byCategory
        var id: String { rawValue }
        var label: String { self == .all ? "All films" : "By category" }
    }

    enum Sort: String, CaseIterable, Identifiable {
        case shortest, longest, title
        var id: String { rawValue }
        var label: String {
            switch self {
            case .shortest: "Shortest first"
            case .longest: "Longest first"
            case .title: "Title"
            }
        }

        /// Films without a runtime go last either way.
        func sorted(_ movies: [Movie]) -> [Movie] {
            switch self {
            case .title: movies
            case .shortest: movies.sorted { ($0.runtimeMinutes ?? .max) < ($1.runtimeMinutes ?? .max) }
            case .longest: movies.sorted { ($0.runtimeMinutes ?? .min) > ($1.runtimeMinutes ?? .min) }
            }
        }
    }

    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("films.mode") private var mode: Mode = .all
    @AppStorage("films.sort") private var sort: Sort = .shortest
    @AppStorage("films.hidesWatched") private var hidesWatched = false
    /// The last film marked watched, and a counter that tears its stub. The
    /// stub is drawn over the screen, because the tile moves to Watched at once.
    @State private var stubTitle = ""
    @State private var tears = 0

    var body: some View {
        @Bindable var navigation = model.navigation
        let films = model.films

        NavigationSplitView(preferredCompactColumn: .constant(.sidebar)) {
            LoadStateView(state: films.state, isEmpty: films.movies.isEmpty, empty: preseason) {
                switch mode {
                case .all:
                    FilmsGrid(sort: sort, hidesWatched: hidesWatched, open: open, onWatched: watched)
                case .byCategory:
                    FilmsByCategory(open: open, onWatched: watched)
                }
            } placeholder: {
                FilmsGrid(sort: sort, hidesWatched: true, isPlaceholder: true, open: { _ in }, onWatched: { _ in })
            }
            .overlay(alignment: .bottom) {
                TicketStub(title: stubTitle, trigger: tears).padding(.bottom, 120)
            }
            .tabChrome("Films", posters: films.movies.compactMap(\.posterUrl))
            .errorAlert("Couldn't save that", error: Bindable(films).actionError)
            .safeAreaBar(edge: .top) {
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, Theme.Space.xs)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") {
                        navigation.sheet = .search
                    }
                }
                .visibilityPriority(.high)
                ToolbarOverflowMenu {
                    Picker("Sort", systemImage: "arrow.up.arrow.down", selection: $sort) {
                        ForEach(Sort.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Hide watched", systemImage: "eye.slash", isOn: $hidesWatched)
                }
                .visibilityPriority(.low)
            }
            .navigationSplitViewColumnWidth(min: 380, ideal: 500, max: 640)
        } detail: {
            // Wide layouts open on the next film to watch rather than an empty column.
            if let movie = films.movies.first(where: { $0.id == navigation.selectedMovieID }) ?? films.toWatch.first {
                MovieDetail(movie: movie, layout: .column)
                    .id(movie.id)
            } else {
                NothingSelected(title: "Choose a film", systemImage: "film")
            }
        }
        .sheet(item: Binding {
            sizeClass == .compact ? films.movies.first { $0.id == navigation.selectedMovieID } : nil
        } set: { movie in
            if movie == nil, sizeClass == .compact { navigation.selectedMovieID = nil }
        }) { movie in
            MovieDetail(movie: movie, layout: .sheet)
        }
    }

    /// Before nominations: no films yet, with the date when `app_config` has it.
    private var preseason: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView> {
        let empty = copy.filmsPreseason(model.season.config.nominationsAt?.formatted(.dateTime.month(.abbreviated).day()))
        return ContentUnavailableView(empty.title, systemImage: "envelope", description: Text(empty.body))
    }

    private func open(_ movie: Movie) {
        model.navigation.selectedMovieID = movie.id
    }

    private func watched(_ title: String) {
        stubTitle = title
        tears += 1
    }
}

/// The hero and the poster grid: still to watch, then watched.
private struct FilmsGrid: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    let sort: FilmsTab.Sort
    let hidesWatched: Bool
    /// Stands in, redacted, while the films load.
    var isPlaceholder = false
    var open: (Movie) -> Void
    var onWatched: (String) -> Void

    private nonisolated struct Metrics: Equatable {
        var width: CGFloat = 0
        var fold: CGRect?
    }

    @State private var metrics = Metrics()

    var body: some View {
        let films = model.films
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if isPlaceholder {
                    HeroCard(watched: 0, total: Movie.placeholders.count, daysLeft: nil)
                    section(copy.toWatchHeading, Movie.placeholders)
                } else {
                    HeroCard(watched: films.watchedCount, total: films.movies.count, daysLeft: model.season.daysToCeremony())
                        .goldDust(trigger: films.completions)
                        .moment(.allWatched, trigger: films.completions)
                    section(copy.toWatchHeading, sort.sorted(films.toWatch))
                    GroupComparisonCard()
                    if !hidesWatched {
                        section(copy.watchedHeading, sort.sorted(films.watched))
                    }
                }
            }
            .padding(.horizontal, Theme.Space.m)
            .padding(.bottom, Theme.Space.xxl)
        }
        .onGeometryChange(for: Metrics.self) { proxy in
            Metrics(width: proxy.size.width, fold: FoldLayout.fold(in: proxy))
        } action: { metrics = $0 }
    }

    /// `max(3, width / 118)` (4 on regular widths), kept even across a fold;
    /// 2 at the accessibility text sizes, so titles stay readable.
    private var columns: Int {
        if typeSize > .accessibility1 { return 2 }
        let ideal = max(sizeClass == .regular ? 4 : 3, Int((metrics.width - 2 * Theme.Space.m) / 118))
        return FoldLayout.columns(ideal, fold: metrics.fold)
    }

    @ViewBuilder
    private func section(_ title: String, _ movies: [Movie]) -> some View {
        if !movies.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text(title)
                    .font(.title3.bold()).fontDesign(.rounded)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.s, alignment: .top), count: columns),
                          spacing: Theme.Space.m) {
                    ForEach(movies) { movie in
                        PosterTile(movie: movie, onOpen: { open(movie) }, onWatched: onWatched)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}

/// Each category with its progress and its films.
private struct FilmsByCategory: View {
    @Environment(AppModel.self) private var model
    var open: (Movie) -> Void
    var onWatched: (String) -> Void

    var body: some View {
        List {
            ForEach(model.ballot.categories) { category in
                let movies = Self.films(in: category)
                Section {
                    ForEach(movies) { movie in
                        FilmListRow(movie: movie, onOpen: { open(movie) }, onWatched: onWatched)
                            .listRowBackground(Color.surface)
                    }
                } header: {
                    HStack {
                        Text(category.name)
                        Spacer()
                        Text("\(movies.count { model.films.isWatched($0.id) }) of \(movies.count)")
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }

    /// The category's films, once each (a film can have two nominees).
    static func films(in category: BallotCategory) -> [Movie] {
        var seen = Set<Int>()
        return category.nominations.compactMap(\.movie).filter { seen.insert($0.id).inserted }
    }
}

/// Your standing in one of your groups, between the grid's sections: "2nd
/// of 6 in Movies LLC" and the gap to the person above. Tapping it opens the
/// group's board; with more than one group, a menu picks which.
private struct GroupComparisonCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @AppStorage("films.compareGroup") private var chosenGroupID = 0

    var body: some View {
        let groups = model.groups.groups
        if let userID = model.session.userID, let group = groups.first(where: { $0.id == chosenGroupID }) ?? groups.first {
            let standing = model.leaderboard.standing(in: group.id, userID: userID)
            HStack(alignment: .center, spacing: Theme.Space.s) {
                Button {
                    model.navigation.boardGroupID = group.id
                    model.navigation.boardMetric = .films
                    model.navigation.tab = .board
                } label: {
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        Text(standing.map { copy.compareRank($0.rank, $0.size, group.name) } ?? group.name)
                            .font(.headline)
                            .foregroundStyle(.ink)
                        Text(line(standing))
                            .font(.subheadline)
                            .foregroundStyle(.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the group's board")

                if groups.count > 1 {
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

    private func line(_ standing: LeaderboardStore.Standing?) -> String {
        switch standing?.position {
        case .first: copy.boardLeader
        case .tied(let name): copy.compareTied(name)
        case .behind(let name, let films): copy.compareGap(films, name)
        case nil: "Checking the board"
        }
    }
}

extension Movie {
    /// Stand-ins for the redacted grid while the films load.
    static let placeholders: [Movie] = (1...9).map {
        Movie(id: -$0, title: "Nominated film", posterUrl: nil, releaseYear: nil, runtimeMinutes: 120, createdAt: nil)
    }
}

#Preview("Dark") {
    FilmsTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    FilmsTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    FilmsTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("All watched") {
    FilmsTab().environment(AppModel.preview { data in data.watched = Set(SampleData.movies.map(\.id)) }).preferredColorScheme(.dark)
}

#Preview("Loading") {
    FilmsTab().environment(AppModel(data: SampleDataSource())).preferredColorScheme(.dark)
}

#Preview("Before nominations") {
    FilmsTab().environment(AppModel.preview { $0.movieList = [] }).preferredColorScheme(.dark)
}

#Preview("Error") {
    FilmsTab().environment(AppModel.preview { $0.failure = .offline }).preferredColorScheme(.dark)
}
