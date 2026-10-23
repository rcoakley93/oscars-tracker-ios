import SwiftUI

/// Films: the list in the first column and the selected film in the detail
/// column on regular widths (P4-02 and P4-03 build the grid and the film page).
struct FilmsTab: View {
    enum Sort: String, CaseIterable, Identifiable {
        case title, shortest
        var id: String { rawValue }
        var label: String { self == .title ? "Title" : "Shortest first" }
    }

    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @AppStorage("films.sort") private var sort: Sort = .title
    @AppStorage("films.hidesWatched") private var hidesWatched = false
    /// The last film marked watched, and a counter that tears its stub. The
    /// stub is drawn over the list, because the row moves to Watched at once.
    @State private var stubTitle = ""
    @State private var tears = 0

    var body: some View {
        @Bindable var navigation = model.navigation
        let films = model.films

        NavigationSplitView {
            LoadStateView(state: films.state, isEmpty: films.movies.isEmpty) {
                List(selection: $navigation.selectedMovieID) {
                    Section {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(films.watchedCount)").displayFont(.largeTitle)
                                .foregroundStyle(Theme.goldGradient)
                            Text("of \(films.movies.count) films").font(.title3.bold()).fontDesign(.rounded)
                        }
                        .accessibilityElement(children: .combine)
                        Text(films.toWatch.isEmpty ? copy.allWatched : copy.progressSummary(films.watchedCount, films.movies.count))
                    }
                    Section(copy.toWatchHeading) {
                        ForEach(sorted(films.toWatch)) { movie in
                            FilmRow(movie: movie) { stubTitle = $0; tears += 1 }.tag(movie.id)
                        }
                    }
                    if !hidesWatched {
                        Section(copy.watchedHeading) {
                            ForEach(sorted(films.watched)) { movie in
                                FilmRow(movie: movie) { _ in }.tag(movie.id)
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    TicketStub(title: stubTitle, trigger: tears).padding(.bottom, 120)
                }
            }
            .tabChrome("Films", posters: films.movies.compactMap(\.posterUrl))
            .toolbar {
                ToolbarOverflowMenu {
                    Picker("Sort", systemImage: "arrow.up.arrow.down", selection: $sort) {
                        ForEach(Sort.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Hide watched", systemImage: "eye.slash", isOn: $hidesWatched)
                }
                .visibilityPriority(.low)
            }
            .navigationSplitViewColumnWidth(min: 380, ideal: 420)
        } detail: {
            if let id = navigation.selectedMovieID, let movie = films.movies.first(where: { $0.id == id }) {
                FilmDetail(movie: movie)
            } else {
                NothingSelected(title: "Choose a film", systemImage: "film")
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

private struct FilmRow: View {
    @Environment(AppModel.self) private var model
    let movie: Movie
    var onWatched: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(movie.title).font(.headline)
                Text(movie.facts).font(.footnote).foregroundStyle(.inkMuted)
            }
            Spacer()
            WatchedButton(movie: movie, onWatched: onWatched)
        }
        .accessibilityElement(children: .contain)
    }
}

/// The circle that marks a film watched: a separate button from the row,
/// at least 44 points, gold once it's watched.
struct WatchedButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let movie: Movie
    var onWatched: (String) -> Void = { _ in }

    var body: some View {
        let watched = model.films.isWatched(movie.id)
        Button {
            guard let userID = model.session.userID else { return }
            if !watched { onWatched(movie.title) }
            Task { await model.films.toggleWatched(movie.id, userID: userID) }
        } label: {
            Image(systemName: watched ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(watched ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.inkMuted))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copy.markWatched)
        .accessibilityValue(watched ? copy.watched : "Not watched")
        .accessibilityAddTraits(watched ? .isSelected : [])
        .moment(watched ? .watched : .unwatched, trigger: watched)
    }
}

/// The selected film in the detail column (P4-03 builds the real page).
private struct FilmDetail: View {
    let movie: Movie

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text(movie.title).displayFont(.title).accessibilityAddTraits(.isHeader)
                Text(movie.facts).foregroundStyle(.inkMuted)
                HStack {
                    Text("Watched").font(.headline)
                    Spacer()
                    WatchedButton(movie: movie)
                }
                .padding(Theme.Space.m)
                .solidSurface(radius: Theme.Radius.row)
                Text("Where to watch, the nominations and Add to plan come in Phase 4.")
                    .font(.footnote).foregroundStyle(.inkMuted)
            }
            .padding(Theme.Space.m)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .background(.ground)
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Movie {
    /// "2025 · 2h 6m": the year and runtime, whichever are known.
    var facts: String {
        [releaseYear.map { String($0) }, Runtime.format(minutes: runtimeMinutes)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
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
