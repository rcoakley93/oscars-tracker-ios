import SwiftUI

/// Main tab navigation for the app.
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: Tab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
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
            List(selection: $selectedTab) {
                Section {
                    NavigationLink(value: Tab.dashboard) {
                        Label("Dashboard", systemImage: "film.fill")
                    }

                    NavigationLink(value: Tab.watchPlan) {
                        Label("Watch Plan", systemImage: "calendar")
                    }

                    NavigationLink(value: Tab.ballot) {
                        Label("Ballot", systemImage: "checkmark.seal.fill")
                    }

                    NavigationLink(value: Tab.leaderboard) {
                        Label("Leaderboard", systemImage: "trophy.fill")
                    }
                }

                Section("More") {
                    NavigationLink(value: Tab.groups) {
                        Label("Groups", systemImage: "person.3.fill")
                    }

                    NavigationLink(value: Tab.profile) {
                        Label("Profile", systemImage: "person.circle.fill")
                    }
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
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Dashboard")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Track your Oscar movie progress")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct WatchPlanPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Watch Plan")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Plan when to watch each movie")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Watch Plan")
        }
    }
}

struct BallotPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Ballot")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Make your predictions")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Ballot")
        }
    }
}

struct LeaderboardPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Leaderboard")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("See how you rank")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Leaderboard")
        }
    }
}

struct GroupsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Groups")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Compete with friends")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Groups")
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.goldPrimary)
                    Text("Profile")
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Manage your account")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .navigationTitle("Profile")
        }
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
