import SwiftUI

/// A film's poster from TMDB at the size it's shown, or its title on a
/// surface while it loads or when there's none. Loads through the poster
/// session set at the root (`URLSession.posters`), from its cache first.
/// Decorative: the tile or row around it is labelled.
struct PosterImage: View {
    let movie: Movie
    var radius: CGFloat = Theme.Radius.tile
    var size: PosterSize = .tile

    var body: some View {
        Color.surface
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay {
                AsyncImage(request: size.request(movie.posterUrl)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Text(movie.title)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.inkMuted)
                            .multilineTextAlignment(.center)
                            .padding(Theme.Space.xs)
                    }
                }
            }
            .clipShape(Theme.shape(radius))
            .accessibilityHidden(true)
    }
}

/// A film in the Films grid: poster, title and runtime, and our odds for a
/// contender (P9-05). Tapping opens the film; the circle on the corner marks
/// it watched (a gold check once it is).
struct PosterTile: View {
    @Environment(AppModel.self) private var model
    let movie: Movie
    /// Our odds, 0 to 1, before nominations; never gold, as a guess isn't earned.
    var odds: Double?
    var onOpen: () -> Void
    var onWatched: (String) -> Void

    var body: some View {
        let watched = model.films.isWatched(movie.id)
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    PosterImage(movie: movie)
                    Text(movie.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.ink)
                        .lineLimit(2, reservesSpace: true)
                    Text(Runtime.format(minutes: movie.runtimeMinutes))
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                    if let odds {
                        OddsText(percent: Contender.percent(odds))
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel([movie.title, Runtime.format(minutes: movie.runtimeMinutes), odds.map { Copy.oddsSpoken(Contender.percent($0)) },
                                 watched ? "watched" : "not watched"].compactMap { $0 }.joined(separator: ", "))
            .accessibilityHint("Opens the film")
        }
        .overlay(alignment: .topTrailing) {
            WatchedButton(movie: movie, onWatched: onWatched, style: .badge)
        }
        .contextMenu { FilmActions(movie: movie, onOpen: onOpen, onWatched: onWatched) }
    }
}

/// The context menu on a film (screens.md, section 2): mark watched, add
/// to tonight's or tomorrow's plan, open, share.
struct FilmActions: View {
    @Environment(AppModel.self) private var model
    let movie: Movie
    var onOpen: () -> Void
    var onWatched: (String) -> Void

    var body: some View {
        let watched = model.films.isWatched(movie.id)
        Button(watched ? "Mark as not watched" : "Mark as watched", systemImage: watched ? "circle" : "checkmark.circle") {
            guard let userID = model.session.userID else { return }
            if !watched { onWatched(movie.title) }
            Task {
                await model.films.toggleWatched(movie.id, userID: userID)
                await model.checkBadges()
            }
        }
        if !watched {
            Menu("Add to plan", systemImage: "calendar.badge.plus") {
                Button("Tonight", systemImage: "moon") { plan(.today()) }
                Button("Tomorrow", systemImage: "sunrise") { plan(.today().adding(days: 1)) }
            }
        }
        Button("Open", systemImage: "film", action: onOpen)
    }

    private func plan(_ day: PlanDay) {
        guard let userID = model.session.userID else { return }
        Task { await model.plan.add(movieID: movie.id, on: day, userID: userID) }
    }
}

/// A film in a list (By category, Search, Plan): thumbnail, title, year and
/// runtime, and the watched toggle. A contender in an acting category leads
/// with the person, and a contender shows our odds.
struct FilmListRow: View {
    let movie: Movie
    var person: String?
    var odds: Double?
    var onOpen: () -> Void
    var onWatched: (String) -> Void = { _ in }

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Button(action: onOpen) {
                HStack(spacing: Theme.Space.s) {
                    PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail)
                        .frame(width: 44)
                    VStack(alignment: .leading) {
                        if let person, !person.isEmpty {
                            Text(person).font(.body.weight(.semibold)).foregroundStyle(.ink)
                            Text(movie.title).font(.subheadline).foregroundStyle(.inkMuted)
                        } else {
                            Text(movie.title).font(.body).foregroundStyle(.ink)
                            Text(verbatim: movie.facts).font(.subheadline).foregroundStyle(.inkMuted)
                        }
                        if let odds {
                            Text(Copy.odds(Contender.percent(odds))).font(.subheadline).foregroundStyle(.inkMuted)
                                .accessibilityLabel(Copy.oddsSpoken(Contender.percent(odds)))
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the film")
            WatchedButton(movie: movie, onWatched: onWatched)
        }
        .accessibilityElement(children: .contain)
        .contextMenu { FilmActions(movie: movie, onOpen: onOpen, onWatched: onWatched) }
    }
}

/// The circle that marks a film watched: its own button, at least 44 points,
/// gold once watched. `.badge` sits on a poster, over a material.
struct WatchedButton: View {
    enum Style { case plain, badge }

    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let movie: Movie
    var onWatched: (String) -> Void = { _ in }
    var style: Style = .plain

    var body: some View {
        let watched = model.films.isWatched(movie.id)
        Button {
            guard let userID = model.session.userID else { return }
            if !watched { onWatched(movie.title) }
            Task {
                await model.films.toggleWatched(movie.id, userID: userID)
                await model.checkBadges()
            }
        } label: {
            Image(systemName: watched ? "checkmark.circle.fill" : "circle")
                .font(style == .badge ? .title3 : .title2)
                .foregroundStyle(watched ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(style == .badge ? .white : .inkMuted))
                .background {
                    if style == .badge { Circle().fill(.black.opacity(watched ? 0.0 : 0.35)).padding(2) }
                }
                .symbolEffect(.bounce, value: watched)
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

extension Movie {
    /// "2025 · 2h 6m": the year and runtime, whichever are known.
    var facts: String {
        [releaseYear.map { String($0) }, Runtime.format(minutes: runtimeMinutes)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// "72%" under a poster: our odds and nothing around them.
struct OddsText: View {
    let percent: Int

    var body: some View {
        Text(Copy.odds(percent))
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(.inkMuted)
    }
}
