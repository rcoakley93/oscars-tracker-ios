import SwiftUI

/// A past season's archive (screens.md 3.8, P12-06), pushed from Profile ›
/// Past seasons: where you finished on each board, that season's badges,
/// your ballot with right and wrong picks and the winners, and the films you
/// watched. Read from the cache offline once it has been opened.
struct SeasonArchiveView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    let ceremonyID: Int
    let title: String

    var body: some View {
        let profile = model.profile
        let archive = profile.archives[ceremonyID]
        Group {
            if let archive {
                content(archive)
            } else if let error = profile.archiveState(ceremonyID).error {
                ContentUnavailableView {
                    Label("Couldn't load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    Button("Try again") { Task { await load() } }
                }
            } else {
                content(SampleData.archive98)
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard let userID = model.session.userID else { return }
        await model.profile.loadArchive(ceremonyID: ceremonyID, userID: userID)
    }

    private func content(_ archive: SeasonArchive) -> some View {
        List {
            Section("Results") {
                ForEach(archive.boards) { ArchiveBoardRow(board: $0) }
            }

            if !archive.badges.isEmpty {
                Section("Badges") {
                    ArchiveBadges(badges: archive.badges)
                }
            }

            Section {
                if archive.picksMade == 0 {
                    Text(Copy.for(voice).archiveNoBallot).foregroundStyle(.inkMuted)
                }
                ForEach(archive.ballot) { ArchivePickRow(category: $0, showsPick: archive.picksMade > 0) }
            } header: {
                Text("Ballot")
            } footer: {
                if archive.picksMade > 0 {
                    Text("\(archive.correctPicks) of \(archive.picksMade) picks right")
                }
            }

            Section {
                if archive.watched.isEmpty {
                    Text("No films watched.").foregroundStyle(.inkMuted)
                } else {
                    ArchiveWatchedGrid(films: archive.watched)
                }
            } header: {
                Text("Watched")
            } footer: {
                Text("\(archive.watched.count) of \(Copy.filmCount(archive.ceremony.filmCount))")
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// "Everyone" or the group's name, then "3rd of 212" and the score.
private struct ArchiveBoardRow: View {
    let board: SeasonArchive.Board

    var body: some View {
        LabeledContent {
            Text(board.scoring == .weighted ? Copy.pointCount(board.points) : "\(board.correctCount) right")
        } label: {
            Text(board.groupName ?? "Everyone").foregroundStyle(.ink)
            Text(place)
                // A board you won is earned gold.
                .foregroundStyle(board.rank == 1 ? .goldText : .inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private var place: String {
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        return "\(ordinal.string(from: board.rank as NSNumber) ?? "\(board.rank)") of \(board.players.formatted())"
    }
}

/// The season's badges. The slot for P12-04's badge art: until it lands,
/// a medal in the tier's colour and the badge's key.
private struct ArchiveBadges: View {
    let badges: [UserBadge]

    var body: some View {
        WrappingStack(spacing: Theme.Space.xs) {
            ForEach(badges, id: \.self) { badge in
                HStack(spacing: Theme.Space.xxs) {
                    Image(systemName: "medal.fill")
                        .foregroundStyle(badge.tier == 3 ? .gold : .inkMuted)
                    Text(badge.badgeKey.replacing("_", with: " ").capitalized)
                        .foregroundStyle(.ink)
                }
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Space.s)
                .padding(.vertical, Theme.Space.xs)
                .background(.ground, in: .capsule)
                .accessibilityLabel("\(badge.badgeKey.replacing("_", with: " ")), \(badge.tierName)")
            }
        }
        .padding(.vertical, Theme.Space.xxs)
    }
}

/// A category, your pick (person first in acting categories) and whether it
/// was right; a wrong or missing pick shows the winner under it.
private struct ArchivePickRow: View {
    let category: SeasonArchive.Category
    /// False when the season has no picks at all, so each row doesn't repeat "No pick".
    let showsPick: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(category.name).font(.subheadline).foregroundStyle(.inkMuted)
                if let pick = category.pick {
                    nominee(pick).foregroundStyle(.ink)
                } else if showsPick {
                    Text("No pick").foregroundStyle(.inkMuted)
                }
                if category.isCorrect != true, !category.winners.isEmpty {
                    Text("Won: \(category.winners.map { $0.title(personFirst: category.personFirst) }.formatted(.list(type: .and)))")
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                }
            }
            Spacer(minLength: 0)
            mark
        }
        .accessibilityElement(children: .combine)
    }

    private func nominee(_ nominee: SeasonArchive.Nominee) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(nominee.title(personFirst: category.personFirst))
            if let subtitle = nominee.subtitle(personFirst: category.personFirst) {
                Text(subtitle).font(.footnote).foregroundStyle(.inkMuted)
            }
        }
    }

    @ViewBuilder private var mark: some View {
        switch category.isCorrect {
        case true?:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.gold).accessibilityLabel("Right")
        case false?:
            Image(systemName: "xmark.circle").foregroundStyle(.inkMuted).accessibilityLabel("Wrong")
        case nil:
            EmptyView()
        }
    }
}

/// Small posters of the films you watched, in the order you watched them:
/// four across on a phone, more on wider screens.
private struct ArchiveWatchedGrid: View {
    let films: [SeasonArchive.Film]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72, maximum: 120), spacing: Theme.Space.xs)], spacing: Theme.Space.xs) {
            ForEach(films) { film in
                PosterImage(movie: film.movie)
            }
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(films.map(\.title).formatted(.list(type: .and)))
    }
}

#Preview("Dark") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("No picks") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview { $0.archives = [1: SampleData.archiveNoPicks] }).preferredColorScheme(.dark)
}

#Preview("No group") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview { $0.archives = [1: SampleData.archiveNoGroup] }).preferredColorScheme(.light)
}

#Preview("Couldn't load") {
    NavigationStack { SeasonArchiveView(ceremonyID: 1, title: "98th Academy Awards") }
        .environment(AppModel.preview { $0.archives = [:] }).preferredColorScheme(.dark)
}
