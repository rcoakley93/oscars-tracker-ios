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
        case shortest, title
        var id: String { rawValue }
        var label: String { self == .title ? "Title" : "Shortest first" }
    }

    @Environment(AppModel.self) private var model
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
            LoadStateView(state: films.state, isEmpty: films.movies.isEmpty) {
                switch mode {
                case .all:
                    FilmsGrid(sort: sort, hidesWatched: hidesWatched, open: open, onWatched: watched)
                case .byCategory:
                    FilmsByCategory(open: open, onWatched: watched)
                }
            }
            .overlay(alignment: .bottom) {
                TicketStub(title: stubTitle, trigger: tears).padding(.bottom, 120)
            }
            .tabChrome("Films", posters: films.movies.compactMap(\.posterUrl))
            .safeAreaBar(edge: .top) {
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, Theme.Space.xs)
            }
            .toolbar {
                ToolbarOverflowMenu {
                    Picker("Sort", systemImage: "arrow.up.arrow.down", selection: $sort) {
                        ForEach(Sort.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Hide watched", systemImage: "eye.slash", isOn: $hidesWatched)
                }
                .visibilityPriority(.low)
            }
            .navigationSplitViewColumnWidth(min: 380, ideal: 440)
        } detail: {
            if let movie = films.movies.first(where: { $0.id == navigation.selectedMovieID }) {
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
    let sort: FilmsTab.Sort
    let hidesWatched: Bool
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
                HeroCard(watched: films.watchedCount, total: films.movies.count, daysLeft: model.season.daysToCeremony())
                section(copy.toWatchHeading, sorted(films.toWatch))
                if !hidesWatched {
                    section(copy.watchedHeading, sorted(films.watched))
                }
            }
            .padding(.horizontal, Theme.Space.m)
            .padding(.bottom, Theme.Space.xxl)
        }
        .onGeometryChange(for: Metrics.self) { proxy in
            Metrics(width: proxy.size.width, fold: FoldLayout.fold(in: proxy))
        } action: { metrics = $0 }
    }

    /// `max(3, width / 118)` (4 on regular widths), kept even across a fold.
    private var columns: Int {
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

    private func sorted(_ movies: [Movie]) -> [Movie] {
        switch sort {
        case .title: movies
        case .shortest: movies.sorted { ($0.runtimeMinutes ?? .max) < ($1.runtimeMinutes ?? .max) }
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

#Preview("Error") {
    FilmsTab().environment(AppModel.preview { $0.failure = .offline }).preferredColorScheme(.dark)
}
