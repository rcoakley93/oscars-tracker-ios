import SwiftUI

/// The app's chrome (P3-05): a tab view with the system's Liquid Glass tab
/// bar, which minimizes on scroll and becomes a sidebar on regular widths
/// (iPhone Duo inner screen, iPad). Each tab has its own navigation stack
/// with a large title and a profile button.
struct AppShell: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var navigation = model.navigation

        TabView(selection: $navigation.tab) {
            SwiftUI.Tab("Films", systemImage: "film", value: AppNavigation.Tab.films) {
                TabStack(title: "Films", posters: model.films.movies.compactMap(\.posterUrl)) { FilmsPlaceholder() }
            }
            SwiftUI.Tab("Plan", systemImage: "calendar", value: AppNavigation.Tab.plan) {
                TabStack(title: "Watch plan") { PlanPlaceholder() }
            }
            SwiftUI.Tab("Ballot", systemImage: "checkmark.seal", value: AppNavigation.Tab.ballot) {
                TabStack(title: "Ballot") { BallotPlaceholder() }
            }
            SwiftUI.Tab("Board", systemImage: "trophy", value: AppNavigation.Tab.board) {
                TabStack(title: "Leaderboard") { BoardPlaceholder() }
            }
            SwiftUI.Tab("Groups", systemImage: "person.3", value: AppNavigation.Tab.groups) {
                TabStack(title: "Groups") { GroupsPlaceholder() }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(item: $navigation.sheet) { sheet in
            switch sheet {
            case .profile:
                ProfileSheet()
            default:
                ComingSoonSheet()
            }
        }
    }
}

/// One tab's navigation stack: a large title over the ground, with the
/// season's name above it and a profile button in the toolbar.
private struct TabStack<Content: View>: View {
    @Environment(AppModel.self) private var model
    let title: String
    /// Posters that light the ambient backdrop; none gives the theatre gradient.
    var posters: [String] = []
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationSubtitle(model.season.ceremony?.name ?? "")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Profile", systemImage: "person.crop.circle") {
                            model.navigation.sheet = .profile
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background { AmbientBackground(posters: posters) }
                .refreshable { await model.refresh() }
        }
    }
}

/// Sheets that Phase 4 builds (movie, join and create group, add to plan).
private struct ComingSoonSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("Coming in Phase 4", systemImage: "hammer", description: Text("This sheet is part of the next build."))
                .toolbar { Button("Done") { dismiss() } }
        }
        .presentationDetents([.medium])
    }
}

#Preview("iPhone") {
    AppShell().environment(AppModel.preview())
}
