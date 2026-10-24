import SwiftUI

/// A film (screens.md, 3.2): its poster and nominations, the one primary
/// action (Mark as watched), where to watch it and when you'll watch it. A
/// sheet on compact widths; the detail column on regular ones, with the
/// sections side by side when they fit.
struct MovieDetail: View {
    enum Layout { case sheet, column }

    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    let movie: Movie
    let layout: Layout

    @ScaledMetric(relativeTo: .title) private var sheetPoster: CGFloat = 112
    @ScaledMetric(relativeTo: .title) private var columnPoster: CGFloat = 160
    @State private var tears = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    header
                    watchButton
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: Theme.Space.xl) {
                            whereToWatch.frame(minWidth: 280)
                            plan.frame(minWidth: 280)
                        }
                        VStack(alignment: .leading, spacing: Theme.Space.xl) {
                            whereToWatch
                            plan
                        }
                    }
                }
                .padding(Theme.Space.m)
                .frame(maxWidth: 760, alignment: .leading)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background { AmbientBackground(posters: movie.posterUrl.map { [$0] } ?? []) }
            .overlay(alignment: .bottom) {
                TicketStub(title: movie.title, trigger: tears).padding(.bottom, Theme.Space.xxl)
            }
            .navigationTitle(layout == .column ? movie.title : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink("Share", item: movie.title)
                }
                .visibilityPriority(.automatic)
                if layout == .sheet {
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                    .visibilityPriority(.high)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    private var header: some View {
        // The poster goes above the title at accessibility sizes, so the
        // title keeps the full width and never breaks inside a word.
        let stack = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.m))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Space.m))
        return stack {
            PosterImage(movie: movie)
                .frame(width: min(layout == .sheet ? sheetPoster : columnPoster, 200))
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(movie.title)
                    .displayFont(.title)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: movie.facts)
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                WrappingStack {
                    ForEach(nominations, id: \.self) { name in
                        Text(name)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.goldText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.gold.opacity(0.14), in: Capsule())
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Nominated for \(nominations.formatted())")
            }
        }
    }

    private var watchButton: some View {
        let watched = model.films.isWatched(movie.id)
        return VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Group {
                if watched {
                    Button(action: toggleWatched) {
                        Label("Watched · Undo", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                } else {
                    Button(action: toggleWatched) {
                        Label(copy.markWatched, systemImage: "ticket").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.gold)
                }
            }
            .controlSize(.large)
            .moment(watched ? .watched : .unwatched, trigger: watched)
            if !watched {
                Text(copy.watchHint).font(.footnote).foregroundStyle(.inkMuted)
            }
        }
    }

    private var whereToWatch: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Where to watch").font(.headline).foregroundStyle(.ink).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(copy.noProviders).font(.subheadline).foregroundStyle(.ink)
                if let url = URL(string: "https://www.justwatch.com/us/search?q=\(movie.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    Link("Check JustWatch", destination: url).font(.subheadline.weight(.semibold))
                }
            }
            .padding(Theme.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .solidSurface(radius: Theme.Radius.row)
        }
    }

    @ViewBuilder
    private var plan: some View {
        if !model.films.isWatched(movie.id) {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Add to your plan").font(.headline).foregroundStyle(.ink).accessibilityAddTraits(.isHeader)
                AddToPlanChips(movie: movie)
            }
        }
    }

    private var nominations: [String] {
        model.ballot.categories
            .filter { category in category.nominations.contains { $0.movie?.id == movie.id } }
            .map(\.name)
    }

    private func toggleWatched() {
        guard let userID = model.session.userID else { return }
        if !model.films.isWatched(movie.id) { tears += 1 }
        Task { await model.films.toggleWatched(movie.id, userID: userID) }
    }
}

#Preview("Dark") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[1], layout: .sheet)
    }
    .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[1], layout: .sheet)
    }
    .environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[1], layout: .sheet)
    }
    .environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Column, watched") {
    MovieDetail(movie: SampleData.movies[0], layout: .column)
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}
