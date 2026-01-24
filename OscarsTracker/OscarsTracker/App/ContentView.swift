import SwiftUI

/// Main tab navigation for the app.
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: Tab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        SwiftUI.Group {
            if horizontalSizeClass == .regular {
                // iPad: Use sidebar navigation
                iPadNavigationView
            } else {
                // iPhone: Use tab bar navigation
                iPhoneTabView
            }
        }
        .tint(.goldPrimary)
    }

    // MARK: - iPhone Tab View

    private var iPhoneTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardPlaceholderView()
                .tabItem {
                    Label("Dashboard", systemImage: "film.fill")
                }
                .tag(Tab.dashboard)

            WatchPlanPlaceholderView()
                .tabItem {
                    Label("Watch Plan", systemImage: "calendar")
                }
                .tag(Tab.watchPlan)

            BallotPlaceholderView()
                .tabItem {
                    Label("Ballot", systemImage: "checkmark.seal.fill")
                }
                .tag(Tab.ballot)

            LeaderboardPlaceholderView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(Tab.leaderboard)

            MoreMenuView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(Tab.more)
        }
    }

    // MARK: - iPad Sidebar Navigation

    private var iPadNavigationView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                Section {
                    sidebarButton(tab: .dashboard, label: "Dashboard", icon: "film.fill")
                    sidebarButton(tab: .watchPlan, label: "Watch Plan", icon: "calendar")
                    sidebarButton(tab: .ballot, label: "Ballot", icon: "checkmark.seal.fill")
                    sidebarButton(tab: .leaderboard, label: "Leaderboard", icon: "trophy.fill")
                }

                Section("More") {
                    sidebarButton(tab: .groups, label: "Groups", icon: "person.3.fill")
                    sidebarButton(tab: .profile, label: "Profile", icon: "person.circle.fill")
                }
            }
            .navigationTitle("Oscars Tracker")
            .listStyle(.sidebar)
        } detail: {
            // Detail view based on selection
            switch selectedTab {
            case .dashboard:
                DashboardPlaceholderView()
            case .watchPlan:
                WatchPlanPlaceholderView()
            case .ballot:
                BallotPlaceholderView()
            case .leaderboard:
                LeaderboardPlaceholderView()
            case .more:
                MoreMenuView()
            case .groups:
                GroupsPlaceholderView()
            case .profile:
                ProfilePlaceholderView()
            }
        }
    }

    // MARK: - Sidebar Button Helper

    private func sidebarButton(tab: Tab, label: String, icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Label(label, systemImage: icon)
        }
        .listRowBackground(selectedTab == tab ? Color.goldPrimary.opacity(0.2) : Color.clear)
    }
}

/// Tab enumeration for navigation state
enum Tab: Hashable {
    case dashboard
    case watchPlan
    case ballot
    case leaderboard
    case more
    case groups
    case profile
}

// MARK: - Placeholder Views

struct DashboardPlaceholderView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Hero
                    ProgressHeroView(
                        watchedCount: viewModel.watchedCount,
                        totalCount: viewModel.totalCount > 0 ? viewModel.totalCount : 42,
                        oscarDate: viewModel.oscarDate
                    )
                    .padding(.horizontal)

                    // View Mode Picker
                    viewModePicker
                        .padding(.horizontal)

                    // Content based on view mode
                    if viewModel.isLoading && viewModel.movies.isEmpty {
                        // Loading placeholder
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Color.goldPrimary)
                            Text("Loading movies...")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if viewModel.movies.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "film.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.goldPrimary)
                            Text("No movies found")
                                .font(.headingMedium)
                                .foregroundStyle(Color.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        // Content based on view mode
                        dashboardContent
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadData()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        VStack(spacing: 12) {
            Picker("View Mode", selection: $viewModel.viewMode) {
                ForEach(DashboardViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("View mode selector")

            // Grid/List toggle for Master List mode
            if viewModel.viewMode == .masterList {
                displayModePicker
            }
        }
    }

    // MARK: - Display Mode Picker (Grid/List)

    private var displayModePicker: some View {
        HStack(spacing: 8) {
            ForEach(MasterListDisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.masterListDisplayMode = mode
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode == .grid ? "square.grid.2x2" : "list.bullet")
                            .font(.system(size: 14))
                        Text(mode.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(viewModel.masterListDisplayMode == mode ? Color.black : Color.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.masterListDisplayMode == mode ? Color.goldPrimary : Color.secondaryBackground)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.rawValue) view")
                .accessibilityAddTraits(viewModel.masterListDisplayMode == mode ? .isSelected : [])
            }
            Spacer()
        }
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private var dashboardContent: some View {
        switch viewModel.viewMode {
        case .masterList:
            if viewModel.masterListDisplayMode == .grid {
                MovieGridView(
                    movies: viewModel.movies,
                    watchedMovieIds: viewModel.watchedMovieIds,
                    onToggleWatched: { movieId in
                        Task {
                            await viewModel.toggleWatched(movieId: movieId)
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else {
                // List mode - uses compact row view similar to Category view
                MovieListView(
                    movies: viewModel.movies,
                    watchedMovieIds: viewModel.watchedMovieIds,
                    onToggleWatched: { movieId in
                        Task {
                            await viewModel.toggleWatched(movieId: movieId)
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

        case .byCategory:
            if viewModel.categoriesWithMovies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.goldPrimary)
                    Text("No categories found")
                        .font(.headingMedium)
                        .foregroundStyle(Color.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                CategoryListView(
                    categoriesWithMovies: viewModel.categoriesWithMovies,
                    watchedMovieIds: viewModel.watchedMovieIds,
                    onToggleWatched: { movieId in
                        Task {
                            await viewModel.toggleWatched(movieId: movieId)
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

struct WatchPlanPlaceholderView: View {
    var body: some View {
        WatchPlanView()
    }
}

struct BallotPlaceholderView: View {
    var body: some View {
        BallotView()
    }
}

struct LeaderboardPlaceholderView: View {
    var body: some View {
        LeaderboardView()
    }
}

struct GroupsPlaceholderView: View {
    var body: some View {
        GroupsView()
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        ProfileView()
    }
}

/// More menu tab content with navigation to Groups and Profile.
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                List {
                    Section {
                        NavigationLink {
                            GroupsPlaceholderView()
                        } label: {
                            Label("Groups", systemImage: "person.3.fill")
                        }

                        NavigationLink {
                            ProfilePlaceholderView()
                        } label: {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                    }
                    .listRowBackground(Color.secondaryBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("More")
        }
    }
}

#Preview("iPhone") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    ContentView()
        .preferredColorScheme(.dark)
        .previewDevice("iPad Pro (11-inch) (4th generation)")
}
