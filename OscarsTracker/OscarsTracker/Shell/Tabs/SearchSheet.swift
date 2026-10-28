import SwiftUI

/// Search (screens.md, 3.3): films and nominees by name, over the data
/// already loaded, no network. A sheet from the Films toolbar, so the tab bar
/// holds the five destinations on an iPhone (P4-14). Films are film rows
/// (opening one opens it); people come under their own header ("Jessie
/// Buckley · Actress in a Leading Role · Hamnet") and open their category on
/// the ballot. Before typing, the categories are suggestions.
struct SearchSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @FocusState private var isSearching: Bool

    var body: some View {
        @Bindable var navigation = model.navigation
        let results = SearchResults(query: navigation.searchText, films: model.films.list, categories: model.ballot.categories)

        NavigationStack {
            List {
                if !results.categories.isEmpty {
                    Section("Categories") {
                        ForEach(results.categories) { category in
                            Button {
                                openBallot(at: category.id)
                            } label: {
                                Label(category.name, systemImage: "checkmark.seal")
                                    .foregroundStyle(.ink)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Color.surface)
                }
                if !results.films.isEmpty {
                    Section("Films") {
                        ForEach(results.films) { movie in
                            FilmListRow(movie: movie) { open(movie) }
                        }
                    }
                    .listRowBackground(Color.surface)
                }
                if !results.people.isEmpty {
                    Section("People") {
                        ForEach(results.people, id: \.nominee.id) { result in
                            PersonRow(nominee: result.nominee, category: result.category) {
                                openBallot(at: result.category.id)
                            }
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .overlay {
                if results.query.isEmpty {
                    ContentUnavailableView(copy.searchEmpty, systemImage: "magnifyingglass")
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: results.query)
                }
            }
            .navigationTitle("Search")
            .scrollContentBackground(.hidden)
            .background { AmbientBackground(posters: results.films.compactMap(\.posterUrl)) }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { navigation.sheet = nil }
                }
                .visibilityPriority(.high)
            }
            .searchable(text: $navigation.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Films and nominees")
            .searchFocused($isSearching)
            .searchSuggestions {
                if results.query.isEmpty {
                    ForEach(model.ballot.categories) { category in
                        Label(category.name, systemImage: "checkmark.seal").searchCompletion(category.name)
                    }
                }
            }
            .onAppear { isSearching = true }
        }
    }

    /// Through Films' selection, so Films shows it as a sheet or in the detail
    /// column for the size class, and keeps it across a fold.
    private func open(_ movie: Movie) {
        model.navigation.sheet = nil
        model.navigation.tab = .films
        model.navigation.selectedMovieID = movie.id
    }

    private func openBallot(at categoryID: Int) {
        model.navigation.sheet = nil
        model.navigation.selectedCategoryID = categoryID
        model.navigation.tab = .ballot
    }
}

/// What a query finds: categories by name, films by title, and people by
/// name (acting nominees). Local and case- and accent-insensitive.
struct SearchResults {
    let query: String
    let categories: [BallotCategory]
    let films: [Movie]
    let people: [(category: BallotCategory, nominee: BallotNominee)]

    init(query: String, films: [Movie], categories: [BallotCategory]) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.query = query
        guard !query.isEmpty else {
            self.categories = []
            self.films = []
            self.people = []
            return
        }
        self.categories = categories.filter { $0.name.localizedStandardContains(query) }
        self.films = films
            .filter { $0.title.localizedStandardContains(query) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        self.people = categories.flatMap { category in
            category.nominations
                .filter { ($0.personName ?? "").localizedStandardContains(query) }
                .map { (category: category, nominee: $0) }
        }
    }

    var isEmpty: Bool { categories.isEmpty && films.isEmpty && people.isEmpty }
}

/// A nominated person: the film's thumbnail, the name, then the category and film.
private struct PersonRow: View {
    let nominee: BallotNominee
    let category: BallotCategory
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: Theme.Space.s) {
                if let movie = nominee.movie {
                    PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail)
                        .frame(width: 44)
                }
                VStack(alignment: .leading) {
                    Text(nominee.personName ?? "").font(.body.weight(.semibold)).foregroundStyle(.ink)
                    Text([category.name, nominee.movie?.title].compactMap { $0 }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(nominee.spokenName(in: category)), \(category.name)")
        .accessibilityHint("Opens the category on your ballot")
    }
}

#Preview("Dark") {
    SearchSheet().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    SearchSheet().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    SearchSheet().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Results") {
    let model = AppModel.preview()
    model.navigation.searchText = "a"
    return SearchSheet().environment(model).preferredColorScheme(.dark)
}
