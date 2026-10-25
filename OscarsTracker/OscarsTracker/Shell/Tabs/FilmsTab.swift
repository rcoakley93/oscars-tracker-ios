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
    @AppStorage(Self.hidesWatchedKey) private var hidesWatched = false
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
                    FilmsGrid(sort: sort, hidesWatched: hidesWatched, open: open, onWatched: watched,
                              showWatched: { hidesWatched = false })
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
            .errorAlert("Couldn't follow the ceremony", error: Bindable(model.liveActivity).actionError)
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

    static let hidesWatchedKey = "films.hidesWatched"

    /// Build 182 and earlier: the Board's "Catch up" turned Hide watched on
    /// and nothing turned it off, so All films lost its Watched section for
    /// good. Clears it once; after that it's only the toggle's to change.
    static func clearCatchUpHidesWatched(in defaults: UserDefaults = .standard) {
        let key = "films.hidesWatched.cleared"
        guard !defaults.bool(forKey: key) else { return }
        defaults.removeObject(forKey: hidesWatchedKey)
        defaults.set(true, forKey: key)
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
    /// Turns Hide watched off, from the note that stands in for the section.
    var showWatched: () -> Void = {}

    /// Your score and the winners in, once the show has started.
    private var heroResults: HeroCard.Results? {
        let ballot = model.ballot
        guard !ballot.categories.isEmpty else { return nil }
        let announced = ballot.categories.count { $0.nominations.contains(where: \.isWinner) }
        return .init(score: ballot.score, announced: announced, categories: ballot.categories.count)
    }

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
                    HeroCard(watched: 0, total: Movie.placeholders.count)
                    section(copy.toWatchHeading, Movie.placeholders)
                } else {
                    TimelineView(.everyMinute) { context in
                        let now = context.date.addingTimeInterval(model.season.clockOffset)
                        HeroCard(watched: films.watchedCount, total: films.movies.count,
                                 phase: model.season.phase(hasNominees: !films.movies.isEmpty, now: now),
                                 now: now, results: heroResults,
                                 onFollow: model.canFollowCeremony ? { Task { await model.followCeremony() } } : nil,
                                 isFollowing: model.liveActivity.isFollowing)
                    }
                        .goldDust(trigger: films.completions)
                        .moment(.allWatched, trigger: films.completions)
                    section(copy.toWatchHeading, sort.sorted(films.toWatch))
                    GroupComparisonCard()
                    if !hidesWatched {
                        section(copy.watchedHeading, sort.sorted(films.watched))
                    } else if !films.watched.isEmpty {
                        // Hidden watched films stay one tap away, not only in the overflow menu.
                        Button("Show watched films (\(films.watched.count))", systemImage: "eye", action: showWatched)
                            .buttonStyle(.bordered)
                            .foregroundStyle(.ink)
                            .frame(maxWidth: .infinity)
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
