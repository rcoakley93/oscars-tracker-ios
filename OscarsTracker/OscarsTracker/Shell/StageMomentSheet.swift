import SwiftUI

/// The first launch after the list changes stage (P10-03): what changed, in
/// the voice and for the new stage, then the films added since the last one.
/// A film opens on Films; "Show the list" goes there too.
struct StageMomentSheet: View {
    let moment: StageMoment
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss

    private var added: [Movie] {
        let movies = Dictionary(model.films.movies.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return moment.addedIDs.compactMap { movies[$0] }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                if !added.isEmpty {
                    Section(copy.stageMomentAdded) {
                        ForEach(added) { movie in
                            FilmListRow(movie: movie, odds: model.films.odds(for: movie.id)) { open(movie) }
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.ground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
                .visibilityPriority(.high)
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Show the list", systemImage: "film.stack", action: showList)
                }
                .visibilityPriority(.low)
            }
        }
        .presentationDetents(added.isEmpty ? [.medium] : [.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(copy.stageMomentTitle).font(.title2.bold()).foregroundStyle(.ink)
            Text(copy.stageMomentBody(moment.made, moment.watched, moment.total)).font(.body).foregroundStyle(.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func open(_ movie: Movie) {
        showList()
        model.navigation.selectedMovieID = movie.id
    }

    private func showList() {
        model.navigation.sheet = nil
        model.navigation.tab = .films
    }
}

#if DEBUG
extension StageMoment {
    /// For previews: the sample season's contender-only films as the new arrivals.
    static func sample(_ stage: ListStage) -> StageMoment {
        StageMoment(stage: stage, made: stage == .predicted ? 0 : 3, watched: stage == .predicted ? 0 : 4,
                    total: 12, addedIDs: stage == .nominated ? [1, 2] : [11, 12])
    }
}

private struct StageMomentPreview: View {
    let stage: ListStage
    var voice = Voice.host

    var body: some View {
        Color.clear.sheet(isPresented: .constant(true)) {
            StageMomentSheet(moment: .sample(stage)).environment(\.copy, .for(voice, stage: stage))
        }
        .environment(AppModel.preview { $0.useListStage(stage) })
    }
}

#Preview("Predicted") { StageMomentPreview(stage: .predicted).preferredColorScheme(.dark) }
#Preview("Shortlisted") { StageMomentPreview(stage: .shortlisted).preferredColorScheme(.dark) }
#Preview("Nominated") { StageMomentPreview(stage: .nominated).preferredColorScheme(.dark) }
#Preview("Shortlisted · Classic") { StageMomentPreview(stage: .shortlisted, voice: .classic).preferredColorScheme(.dark) }
#Preview("Dark") { StageMomentPreview(stage: .shortlisted).preferredColorScheme(.dark) }
#Preview("Light") { StageMomentPreview(stage: .shortlisted).preferredColorScheme(.light) }
#Preview("Large text") {
    StageMomentPreview(stage: .shortlisted).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
#endif
