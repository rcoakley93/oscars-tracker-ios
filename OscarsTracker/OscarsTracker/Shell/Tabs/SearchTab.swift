import SwiftUI

/// The search tab: films and nominees from the data already loaded, no
/// network. Choosing a result opens it in its tab. P4-02 builds the real
/// screen with posters.
struct SearchTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var navigation = model.navigation
        let query = navigation.searchText.trimmingCharacters(in: .whitespaces)
        let films = query.isEmpty ? [] : model.films.movies.filter { $0.title.localizedStandardContains(query) }
        let nominees = query.isEmpty ? [] : model.ballot.categories.flatMap { category in
            category.nominations
                .filter { ($0.personName ?? "").localizedStandardContains(query) }
                .map { (category: category, nominee: $0) }
        }

        NavigationStack {
            List {
                if !films.isEmpty {
                    Section("Films") {
                        ForEach(films) { movie in
                            Button {
                                navigation.selectedMovieID = movie.id
                                navigation.tab = .films
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(movie.title).font(.headline)
                                    Text(movie.facts).font(.footnote).foregroundStyle(.inkMuted)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !nominees.isEmpty {
                    Section("Nominees") {
                        ForEach(nominees, id: \.nominee.id) { result in
                            Button {
                                navigation.selectedCategoryID = result.category.id
                                navigation.tab = .ballot
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(result.nominee.spokenName).font(.headline)
                                    Text(result.category.name).font(.footnote).foregroundStyle(.inkMuted)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlay {
                if query.isEmpty {
                    ContentUnavailableView("Search the season", systemImage: "magnifyingglass", description: Text("Films and nominees, from any tab."))
                } else if films.isEmpty && nominees.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Search")
            .scrollContentBackground(.hidden)
            .background { AmbientBackground() }
            .searchable(text: $navigation.searchText, prompt: "Films and nominees")
            .searchToolbarBehavior(.minimize)
        }
    }
}

#Preview("Dark") {
    SearchTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    SearchTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    SearchTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
