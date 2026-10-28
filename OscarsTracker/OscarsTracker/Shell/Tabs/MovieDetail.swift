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
    /// Opens at medium, or large once more than three offers load (sheet 3.2).
    @State private var detent: PresentationDetent = .medium

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
                    groupsSeen
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
                if layout == .sheet {
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                    .visibilityPriority(.high)
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .task(id: movie.id) {
            await model.films.loadOffers(for: movie.id)
            if (model.films.offers[movie.id]?.count ?? 0) > 3 {
                withAnimation(.smooth) { detent = .large }
            }
        }
        .task(id: model.films.isWatched(movie.id)) {
            await model.films.loadSeen(for: movie.id)
        }
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
                let contending = model.films.contending(movie.id)
                if contending.isEmpty {
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
                } else {
                    // A contender isn't nominated yet, so its chips aren't gold (P9-05).
                    WrappingStack {
                        ForEach(contending) { contender in
                            Text(Self.chip(contender))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.surface, in: Capsule())
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Contending in " + contending.map { "\(Self.categoryLabel($0)), \(Copy.odds($0.percent))" }.formatted())
                    ContendersCredit()
                }
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
        let offers = model.films.offers[movie.id]
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Where to watch").font(.headline).foregroundStyle(.ink).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                if let offers, offers.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text(copy.noProviders).font(.subheadline).foregroundStyle(.ink)
                        Link("Check JustWatch", destination: justWatchURL).font(.subheadline.weight(.semibold))
                    }
                    .padding(Theme.Space.m)
                } else {
                    let rows = offers ?? WatchOffer.placeholders
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, offer in
                        if index > 0 { Divider().padding(.leading, Theme.Space.m + 32 + Theme.Space.s) }
                        OfferRow(offer: offer)
                    }
                    .redacted(reason: offers == nil ? .placeholder : [])
                    .accessibilityHidden(offers == nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .solidSurface(radius: Theme.Radius.row)
            if let offers, !offers.isEmpty {
                Link(destination: justWatchURL) {
                    Text("Data from JustWatch").font(.caption).foregroundStyle(.inkMuted)
                }
            }
        }
    }

    private var justWatchURL: URL {
        let query = movie.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.justwatch.com/us/search?q=\(query)")!
    }

    /// "4 of 6 in Movies LLC have seen it", one line per group.
    @ViewBuilder
    private var groupsSeen: some View {
        if let seen = model.films.seen[movie.id], !seen.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(seen) { group in
                    Label(copy.groupSeen(group.seenCount, group.memberCount, group.groupName), systemImage: "person.3")
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                        .contentTransition(.numericText())
                }
            }
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

    /// "Best Picture · 72%", "Sound · Shortlisted · 64%"; acting categories name the person.
    static func chip(_ contender: Contender) -> String {
        [categoryLabel(contender), contender.stage == .shortlisted ? "Shortlisted" : nil, "\(contender.percent)%"]
            .compactMap { $0 }.joined(separator: " · ")
    }

    private static func categoryLabel(_ contender: Contender) -> String {
        guard contender.displayMode == .person, let person = contender.detailText, !person.isEmpty else { return contender.categoryName }
        return "\(contender.categoryName) (\(person))"
    }

    private func toggleWatched() {
        guard let userID = model.session.userID else { return }
        if !model.films.isWatched(movie.id) { tears += 1 }
        Task { await model.films.toggleWatched(movie.id, userID: userID) }
    }
}

/// A provider's logo and name, what the offer is, and its kind in gold.
private struct OfferRow: View {
    let offer: WatchOffer
    @ScaledMetric(relativeTo: .body) private var logo: CGFloat = 32

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            AsyncImage(url: offer.logoURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Text(offer.provider.name.prefix(1))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.inkMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.surface)
                }
            }
            .frame(width: logo, height: logo)
            .clipShape(Theme.shape(Theme.Radius.thumbnail))
            .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(offer.provider.name).font(.body).foregroundStyle(.ink)
                Text(offer.kind.detail).font(.footnote).foregroundStyle(.inkMuted)
            }
            Spacer(minLength: Theme.Space.xs)
            Text(offer.kind.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.goldText)
        }
        .padding(.horizontal, Theme.Space.m)
        .padding(.vertical, Theme.Space.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(offer.provider.name), \(offer.kind.label.lowercased()), \(offer.kind.detail.lowercased())")
    }
}

extension WatchOffer {
    /// Stand-ins for the redacted rows while offers load.
    static let placeholders: [WatchOffer] = (1...2).map {
        WatchOffer(id: -$0, availabilityType: "streaming", provider: .init(name: "Streaming service", logoPath: nil))
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

#Preview("No offers") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[6], layout: .sheet)
    }
    .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Many offers") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[0], layout: .sheet)
    }
    .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Column, watched") {
    MovieDetail(movie: SampleData.movies[0], layout: .column)
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Contender") {
    Color.ground.sheet(isPresented: .constant(true)) {
        MovieDetail(movie: SampleData.movies[5], layout: .sheet)
    }
    .environment(AppModel.preview { $0.useListStage(.shortlisted) }).preferredColorScheme(.dark)
}
