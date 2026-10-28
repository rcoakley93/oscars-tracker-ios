import SwiftUI

/// Films (screens.md, 3.1): the hero, then the films still to watch and the
/// ones you've watched as a poster grid, or by category. The films are the
/// list for the season's stage (P9-05): the contenders with our odds before
/// nominations, then the nominees. On compact widths a
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
        case shortest, longest, title, odds
        var id: String { rawValue }
        var label: String {
            switch self {
            case .shortest: "Shortest first"
            case .longest: "Longest first"
            case .title: "Title"
            case .odds: "Most likely first"
            }
        }

        /// The sorts a stage offers: odds only while there are odds.
        static func available(in stage: ListStage) -> [Sort] {
            stage.showsContenders ? allCases : allCases.filter { $0 != .odds }
        }

        /// The sort to use at `stage`: a saved odds sort reads as shortest first from nominations day.
        func resolved(in stage: ListStage) -> Sort {
            Self.available(in: stage).contains(self) ? self : .shortest
        }

        /// `movies` come by title. Films without a runtime or odds go last;
        /// odds ties keep title order.
        func sorted(_ movies: [Movie], odds: (Int) -> Double? = { _ in nil }) -> [Movie] {
            switch self {
            case .title: movies
            case .shortest: movies.sorted { ($0.runtimeMinutes ?? .max) < ($1.runtimeMinutes ?? .max) }
            case .longest: movies.sorted { ($0.runtimeMinutes ?? .min) > ($1.runtimeMinutes ?? .min) }
            case .odds:
                // Decorate first: a stable sort by a looked-up key.
                movies.enumerated().map { ($0.offset, $0.element, odds($0.element.id) ?? -1) }
                    .sorted { $0.2 != $1.2 ? $0.2 > $1.2 : $0.0 < $1.0 }
                    .map(\.1)
            }
        }
    }

    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("films.mode") private var mode: Mode = .all
    @AppStorage("films.sort") private var sort: Sort = .shortest
    @AppStorage(Self.hidesWatchedKey) private var hidesWatched = false
    /// The category filter's category id; 0 is every category.
    @AppStorage("films.category") private var categoryID = 0
    /// The last film marked watched, and a counter that tears its stub. The
    /// stub is drawn over the screen, because the tile moves to Watched at once.
    @State private var stubTitle = ""
    @State private var tears = 0

    var body: some View {
        @Bindable var navigation = model.navigation
        let films = model.films
        let stage = films.listStage
        let categories = films.listCategories
        let category = categories.first { $0.id == categoryID }

        NavigationSplitView(preferredCompactColumn: .constant(.sidebar)) {
            LoadStateView(state: films.state, isEmpty: films.list.isEmpty, empty: preseason) {
                switch mode {
                case .all:
                    FilmsGrid(sort: sort.resolved(in: stage), category: category, hidesWatched: hidesWatched, open: open,
                              onWatched: watched, showWatched: { hidesWatched = false })
                case .byCategory:
                    FilmsByCategory(category: category, open: open, onWatched: watched)
                }
            } placeholder: {
                FilmsGrid(sort: sort, hidesWatched: true, isPlaceholder: true, open: { _ in }, onWatched: { _ in })
            }
            .accessibilityHint(copy.filmsListHint)
            .overlay(alignment: .bottom) {
                TicketStub(title: stubTitle, trigger: tears).padding(.bottom, 120)
            }
            .tabChrome("Films", subtitle: model.season.ceremony.map { copy.filmsSubtitle(ceremony: $0.number, isRehearsal: model.season.isRehearsal) },
                       posters: films.list.compactMap(\.posterUrl))
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
                    Picker("Sort", systemImage: "arrow.up.arrow.down", selection: Binding { sort.resolved(in: stage) } set: { sort = $0 }) {
                        ForEach(Sort.available(in: stage)) { Text($0.label).tag($0) }
                    }
                    if !categories.isEmpty {
                        Picker("Category", systemImage: "line.3.horizontal.decrease", selection: Binding { category?.id ?? 0 } set: { categoryID = $0 }) {
                            Text("All categories").tag(0)
                            ForEach(categories) { Text($0.name).tag($0.id) }
                        }
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
        .onChange(of: sizeClass == .compact && navigation.tab == .films && navigation.selectedMovieID != nil, initial: true) {
            navigation.isFilmSheetOpen = $1
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
    /// Narrows the sections to one of the list's categories; the hero stays on the whole list.
    var category: ListCategory?
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
                        HeroCard(watched: films.watchedCount, total: films.list.count,
                                 phase: model.season.phase(hasNominees: films.hasNominees, now: now),
                                 shortlistsAt: model.season.config.shortlistsAt,
                                 now: now, results: heroResults,
                                 onFollow: model.canFollowCeremony ? { Task { await model.followCeremony() } } : nil,
                                 isFollowing: model.liveActivity.isFollowing)
                    }
                        .goldDust(trigger: films.completions)
                        .moment(.allWatched, trigger: films.completions)
                    let watched = filtered(films.watched)
                    section(category.map { "\(copy.toWatchHeading) · \($0.name)" } ?? copy.toWatchHeading, sorted(filtered(films.toWatch)))
                    GroupComparisonCard()
                    if !hidesWatched {
                        section(copy.watchedHeading, sorted(watched))
                    } else if !watched.isEmpty {
                        // Hidden watched films stay one tap away, not only in the overflow menu.
                        Button("Show watched films (\(watched.count))", systemImage: "eye", action: showWatched)
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

    private func filtered(_ movies: [Movie]) -> [Movie] {
        guard let category else { return movies }
        let ids = model.films.movieIDs(in: category.id)
        return movies.filter { ids.contains($0.id) }
    }

    private func sorted(_ movies: [Movie]) -> [Movie] {
        sort.sorted(movies) { model.films.odds(for: $0, in: category?.id) }
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
                        PosterTile(movie: movie, odds: isPlaceholder ? nil : model.films.odds(for: movie.id, in: category?.id),
                                   onOpen: { open(movie) }, onWatched: onWatched)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}

/// Each category with its progress and its films: the ballot's from
/// nominations day, the contenders' before, most likely first with our odds.
private struct FilmsByCategory: View {
    @Environment(AppModel.self) private var model
    /// Shows only this category, from the overflow menu's filter.
    var category: ListCategory?
    var open: (Movie) -> Void
    var onWatched: (String) -> Void

    var body: some View {
        let films = model.films
        List {
            ForEach(sections.filter { category == nil || $0.id == category?.id }) { section in
                Section {
                    ForEach(section.rows) { row in
                        FilmListRow(movie: row.movie, person: row.person, odds: row.odds, onOpen: { open(row.movie) }, onWatched: onWatched)
                            .listRowBackground(Color.surface)
                    }
                } header: {
                    HStack {
                        Text(section.name)
                        Spacer()
                        Text("\(section.rows.count { films.isWatched($0.movie.id) }) of \(section.rows.count)")
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }

    struct Row: Identifiable {
        let id: String
        let movie: Movie
        var person: String?
        var odds: Double?
    }

    struct CategorySection: Identifiable {
        let id: Int
        let name: String
        let rows: [Row]
    }

    /// The list's categories with their rows.
    private var sections: [CategorySection] {
        let films = model.films
        guard films.listStage.showsContenders else {
            return model.ballot.categories.map { category in
                CategorySection(id: category.id, name: category.name, rows: Self.films(in: category).map { Row(id: "\($0.id)", movie: $0) })
            }
        }
        let movies = Dictionary(films.movies.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return films.listCategories.map { category in
            let rows = films.contenders.filter { $0.categoryId == category.id }.sorted { $0.odds > $1.odds }.compactMap { contender in
                movies[contender.movieId].map {
                    Row(id: "\(contender.id)", movie: $0, person: contender.displayMode == .person ? contender.detailText : nil, odds: contender.odds)
                }
            }
            return CategorySection(id: category.id, name: category.name, rows: rows)
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

#Preview("Predicted") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.predicted) }).preferredColorScheme(.dark)
}

#Preview("Predicted, by category") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.predicted) })
        .defaultAppStorage({ let d = UserDefaults(suiteName: "preview.films.byCategory")!; d.set("byCategory", forKey: "films.mode"); return d }())
        .preferredColorScheme(.light)
}

#Preview("Shortlisted") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.shortlisted) }).preferredColorScheme(.dark)
}

#Preview("Predicted, rehearsal, Host") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.predicted); $0.isRehearsal = true })
        .environment(\.copy, Copy.for(.host, stage: .predicted)).preferredColorScheme(.dark)
}

#Preview("Shortlisted, Classic") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.shortlisted) })
        .environment(\.copy, Copy.for(.classic, stage: .shortlisted)).preferredColorScheme(.light)
}

#Preview("Nominated") {
    FilmsTab().environment(AppModel.preview { $0.useListStage(.nominated) }).preferredColorScheme(.dark)
}

#Preview("Error") {
    FilmsTab().environment(AppModel.preview { $0.failure = .offline }).preferredColorScheme(.dark)
}
