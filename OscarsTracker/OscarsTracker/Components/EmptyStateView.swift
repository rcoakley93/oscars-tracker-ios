import SwiftUI

/// A reusable empty state view with icon, title, subtitle, and optional action button.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.goldPrimary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headingMedium)
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.gold)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint(actionTitle != nil ? "Double tap to \(actionTitle?.lowercased() ?? "take action")" : "")
    }
}

/// Empty state for Watch Plan when no movies are planned.
struct WatchPlanEmptyState: View {
    let onAddMovie: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "calendar",
            title: "No movies planned",
            subtitle: "Add movies to your watch plan to track when to watch them",
            actionTitle: "Add Movie",
            action: onAddMovie
        )
    }
}

/// Empty state for Groups when user has no groups.
struct GroupsEmptyState: View {
    let onCreateGroup: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "person.3.fill",
            title: "No groups yet",
            subtitle: "Create or join a group to track movies together with friends",
            actionTitle: "Create Group",
            action: onCreateGroup
        )
    }
}

/// Empty state for Leaderboard when no data is available.
struct LeaderboardEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "trophy.fill",
            title: "No rankings yet",
            subtitle: "Start making predictions to see the leaderboard"
        )
    }
}

/// Empty state for Ballot when no predictions are made.
struct BallotEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: "No predictions yet",
            subtitle: "Make your predictions for each category to compete for the top spot"
        )
    }
}

/// Empty state for Dashboard when no movies exist.
struct DashboardEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "film.fill",
            title: "No movies found",
            subtitle: "Check back soon for Oscar-nominated films"
        )
    }
}

/// Empty state for Profile stats when user has no activity.
struct ProfileEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "person.circle.fill",
            title: "Start watching",
            subtitle: "Track movies and make predictions to see your stats here"
        )
    }
}

/// Empty state for search results.
struct SearchEmptyState: View {
    let query: String

    var body: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results",
            subtitle: "No movies match \"\(query)\""
        )
    }
}

/// Empty state for category view when no categories exist.
struct CategoryEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "rectangle.stack.fill",
            title: "No categories found",
            subtitle: "Category data is not yet available"
        )
    }
}

#Preview("EmptyStateView") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        EmptyStateView(
            icon: "calendar",
            title: "No movies planned",
            subtitle: "Add movies to your watch plan to track when to watch them",
            actionTitle: "Add Movie",
            action: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("WatchPlanEmptyState") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        WatchPlanEmptyState(onAddMovie: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("GroupsEmptyState") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        GroupsEmptyState(onCreateGroup: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("LeaderboardEmptyState") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LeaderboardEmptyState()
    }
    .preferredColorScheme(.dark)
}

#Preview("SearchEmptyState") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SearchEmptyState(query: "Inception")
    }
    .preferredColorScheme(.dark)
}
