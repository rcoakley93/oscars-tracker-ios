import SwiftUI

// Placeholder screens for the P3-05 shell. They use the real stores (and so
// the live data), in plain system lists styled with the tokens. Phase 4
// replaces each one with its finished screen.

/// Shows a store's loading and error states around its content.
struct LoadStateView<Content: View>: View {
    let state: LoadState
    let isEmpty: Bool
    var empty: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView>? = nil
    @ViewBuilder var content: Content
    @Environment(AppModel.self) private var model

    var body: some View {
        if isEmpty, state == .loading || state == .idle {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isEmpty, let error = state.error {
            ContentUnavailableView {
                Label("Couldn't load", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Try again") { Task { await model.refresh() } }
            }
        } else if isEmpty, let empty {
            empty
        } else {
            content
        }
    }
}

struct FilmsPlaceholder: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let films = model.films
        LoadStateView(state: films.state, isEmpty: films.movies.isEmpty) {
            List {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(films.watchedCount)").displayFont(.largeTitle)
                            .foregroundStyle(Theme.goldGradient)
                        Text("of \(films.movies.count) films").font(.title3.bold()).fontDesign(.rounded)
                    }
                    if let days = model.season.daysToCeremony() {
                        Text("\(days) days to the ceremony").foregroundStyle(.inkMuted)
                    }
                }
                Section("Still to watch") {
                    ForEach(films.toWatch) { FilmRow(movie: $0) }
                }
                Section("Watched") {
                    ForEach(films.watched) { FilmRow(movie: $0) }
                }
            }
        }
    }
}

private struct FilmRow: View {
    @Environment(AppModel.self) private var model
    let movie: Movie

    var body: some View {
        let watched = model.films.isWatched(movie.id)
        HStack {
            VStack(alignment: .leading) {
                Text(movie.title).font(.headline)
                Text([movie.releaseYear.map { String($0) }, Runtime.format(minutes: movie.runtimeMinutes)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote).foregroundStyle(.inkMuted)
            }
            Spacer()
            Button {
                guard let userID = model.session.userID else { return }
                Task { await model.films.toggleWatched(movie.id, userID: userID) }
            } label: {
                Image(systemName: watched ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(watched ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.inkMuted))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(movie.title), watched")
            .accessibilityValue(watched ? "Yes" : "No")
            .sensoryFeedback(.selection, trigger: watched)
        }
    }
}

struct PlanPlaceholder: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let plan = model.plan
        let overdue = plan.toReschedule(watchedIDs: model.films.watchedIDs)
        LoadStateView(state: plan.state, isEmpty: plan.items.isEmpty,
                      empty: ContentUnavailableView("No films planned yet", systemImage: "calendar", description: Text("Add films to your plan from the Films tab."))) {
            List {
                if !overdue.isEmpty {
                    Section {
                        Button("\(overdue.count) to reschedule · Move all to this week") {
                            Task { await plan.rescheduleAll(overdue) }
                        }
                    }
                }
                ForEach(plan.upcomingDays()) { day in
                    Section(day.day.startDate().formatted(.dateTime.weekday(.wide).month().day())) {
                        ForEach(day.items) { item in
                            Text(item.movie?.title ?? "Film \(item.movieId)")
                        }
                    }
                }
            }
        }
    }
}

struct BallotPlaceholder: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let ballot = model.ballot
        LoadStateView(state: ballot.state, isEmpty: ballot.categories.isEmpty,
                      empty: ContentUnavailableView("No categories yet", systemImage: "checkmark.seal", description: Text("Check back when nominations are announced."))) {
            List {
                Section {
                    Text("\(ballot.pickedCount) of \(ballot.categories.count) picked")
                    if let lock = model.season.ceremony?.ballotLockAt {
                        Text(model.season.isBallotLocked() ? "The ballot is locked." : "Locks \(lock.formatted(date: .abbreviated, time: .shortened))")
                            .foregroundStyle(.inkMuted)
                    }
                }
                ForEach(ballot.categories) { category in
                    Section(category.name) {
                        ForEach(category.nominations) { nominee in
                            NomineeRow(category: category, nominee: nominee)
                        }
                    }
                }
            }
        }
    }
}

private struct NomineeRow: View {
    @Environment(AppModel.self) private var model
    let category: BallotCategory
    let nominee: BallotNominee

    var body: some View {
        let picked = model.ballot.pick(for: category.id) == nominee.id
        Button {
            guard let userID = model.session.userID else { return }
            Task { await model.ballot.choose(nominationID: nominee.id, in: category.id, userID: userID, locked: model.season.isBallotLocked()) }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(nominee.personName ?? nominee.movie?.title ?? "Nominee").font(.headline)
                    if nominee.personName != nil, let film = nominee.movie?.title {
                        Text(film).font(.footnote).foregroundStyle(.inkMuted)
                    }
                }
                Spacer()
                if nominee.isWinner { Text("Winner").font(.caption.bold()).foregroundStyle(.goldText) }
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(picked ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.inkMuted))
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(picked ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: picked)
    }
}

struct BoardPlaceholder: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let board = model.leaderboard
        LoadStateView(state: board.state, isEmpty: board.entries.isEmpty,
                      empty: ContentUnavailableView("No one on the board yet", systemImage: "trophy", description: Text("Watch a film to get on it."))) {
            List(board.entries) { entry in
                HStack {
                    Text("\(entry.rank)").font(.headline).fontDesign(.rounded).frame(width: 32)
                    Text(entry.userId == model.session.userID ? "You" : entry.username)
                        .fontWeight(entry.userId == model.session.userID ? .bold : .regular)
                    Spacer()
                    Text("\(entry.watchedCount) films").foregroundStyle(.inkMuted)
                }
            }
        }
    }
}

struct GroupsPlaceholder: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let groups = model.groups
        LoadStateView(state: groups.state, isEmpty: groups.groups.isEmpty,
                      empty: ContentUnavailableView("No groups yet", systemImage: "person.3", description: Text("Create a group, or join one with an invite code."))) {
            List(groups.groups) { group in
                VStack(alignment: .leading) {
                    Text(group.name).font(.headline)
                    Text("Invite code \(group.inviteCode)").font(.footnote).foregroundStyle(.inkMuted)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Join a group", systemImage: "person.badge.plus") {
                    model.navigation.sheet = .joinGroup(code: nil)
                }
            }
        }
    }
}

#Preview("Films") {
    NavigationStack { FilmsPlaceholder().navigationTitle("Films") }
        .environment(AppModel.preview())
}
