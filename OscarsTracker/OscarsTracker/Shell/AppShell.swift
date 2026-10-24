import SwiftUI

/// The app's chrome (P3-05, P3-10): a tab view with the system's Liquid Glass
/// tab bar, which minimises on scroll and becomes a sidebar on regular widths
/// (iPhone Duo inner screen, iPad), the search tab, and the season ticker
/// above the bar.
///
/// Films, Ballot, Board and Groups are master and detail, so they're split
/// views: one column on compact widths (iPhone, the Duo's outer screen), two
/// on regular. Plan is two views with no navigation between them, so it's an
/// arrangement. Every selection lives in `AppNavigation`, so folding or
/// unfolding a Duo keeps it.
struct AppShell: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var navigation = model.navigation

        TabView(selection: $navigation.tab) {
            SwiftUI.Tab("Films", systemImage: "film", value: AppNavigation.Tab.films) {
                FilmsTab()
            }
            SwiftUI.Tab("Plan", systemImage: "calendar", value: AppNavigation.Tab.plan) {
                PlanTab()
            }
            SwiftUI.Tab("Ballot", systemImage: "checkmark.seal", value: AppNavigation.Tab.ballot) {
                BallotTab()
            }
            SwiftUI.Tab("Board", systemImage: "trophy", value: AppNavigation.Tab.board) {
                BoardTab()
            }
            SwiftUI.Tab("Groups", systemImage: "person.3", value: AppNavigation.Tab.groups) {
                GroupsTab()
            }
            SwiftUI.Tab(value: AppNavigation.Tab.search, role: .search) {
                SearchTab()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: model.isOffline || model.season.ticker(filmsLeft: model.films.toWatch.count, hasNominees: !model.films.movies.isEmpty) != .none) {
            SeasonTicker()
        }
        // Notifications are asked about after the first saved pick or
        // watched film, when they make sense, never at launch.
        .onChange(of: model.films.saves + model.ballot.saves) { _, saves in
            if saves > 0 { Task { await model.push.askAfterFirstSave() } }
        }
        // An invite link opened before sign-in (or before the app was
        // installed and signed up) opens the join sheet once you're in.
        .onChange(of: model.session.pendingInviteCode, initial: true) {
            guard let code = model.session.pendingInviteCode else { return }
            model.session.pendingInviteCode = nil
            navigation.tab = .groups
            navigation.sheet = .joinGroup(code: code)
        }
        .sheet(item: $navigation.sheet) { sheet in
            switch sheet {
            case .profile:
                ProfileSheet()
            case .movie(let id):
                if let movie = model.films.movies.first(where: { $0.id == id }) {
                    MovieDetail(movie: movie, layout: .sheet)
                }
            case .addToDay(let day):
                AddToDaySheet(day: day)
            case .reschedule(let itemID):
                RescheduleSheet(itemID: itemID)
            case .whatCanIWatch:
                WhatCanIWatchSheet()
            case .fillPlan:
                FillPlanSheet()
            case .joinGroup(let code):
                JoinGroupSheet(code: code)
            case .createGroup:
                CreateGroupSheet()
            }
        }
    }
}

// MARK: - Bars

extension View {
    /// The title, the season under it, the profile button and the ambient
    /// light for a tab's first column. Each tab adds its own items.
    /// The subtitle defaults to the ceremony's name.
    func tabChrome(_ title: String, subtitle: String? = nil, posters: [String] = []) -> some View {
        modifier(TabChrome(title: title, subtitle: subtitle, posters: posters))
    }
}

private struct TabChrome: ViewModifier {
    @Environment(AppModel.self) private var model
    let title: String
    var subtitle: String?
    var posters: [String]

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationSubtitle(subtitle ?? model.season.ceremony?.name ?? "")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Profile", systemImage: "person.crop.circle") {
                        model.navigation.sheet = .profile
                    }
                }
                .visibilityPriority(.automatic)
            }
            .scrollContentBackground(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background { AmbientBackground(posters: posters) }
            .refreshable { await model.refresh() }
    }
}

/// The detail column when nothing is selected yet.
struct NothingSelected: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ground)
    }
}

#Preview("Dark") {
    AppShell().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    AppShell().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    AppShell().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Error") {
    AppShell().environment(AppModel.preview { $0.failure = .offline }).preferredColorScheme(.dark)
}
