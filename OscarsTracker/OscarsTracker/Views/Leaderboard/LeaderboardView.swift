import SwiftUI

/// Leaderboard tab options
enum LeaderboardTab: String, CaseIterable {
    case moviesWatched = "Movies Watched"
    case correctPredictions = "Correct Predictions"
}

/// Leaderboard view showing global user rankings.
struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedTab: LeaderboardTab = .moviesWatched

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Leaderboard Tab", selection: $selectedTab) {
                    ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityLabel("Leaderboard category selector")

                // Content based on selected tab
                switch selectedTab {
                case .moviesWatched:
                    moviesWatchedContent
                case .correctPredictions:
                    correctPredictionsContent
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Leaderboard")
            .refreshable {
                await viewModel.loadData()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Movies Watched Tab Content

    private var moviesWatchedContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        loadingView
                    } else if viewModel.entries.isEmpty {
                        emptyStateView
                    } else {
                        leaderboardList
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.entries) { _, _ in
                scrollToCurrentUser(proxy: proxy)
            }
        }
    }

    // MARK: - Correct Predictions Tab Content

    private var correctPredictionsContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Color.goldPrimary)

            Text("Coming Soon")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            Text("Prediction rankings will be available after the Academy Awards ceremony.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Correct Predictions leaderboard coming soon after the Academy Awards ceremony")
    }

    // MARK: - Scroll to Current User

    private func scrollToCurrentUser(proxy: ScrollViewProxy) {
        guard let currentUserEntry = viewModel.currentUserEntry else { return }
        // Delay slightly to ensure view is rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(currentUserEntry.id, anchor: .center)
            }
        }
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.entries) { entry in
                LeaderboardRowView(
                    entry: entry,
                    isCurrentUser: viewModel.isCurrentUser(entry),
                    medalType: viewModel.medalType(for: entry.rank)
                )
                .id(entry.id)
            }
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading leaderboard...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("No rankings yet")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Start making predictions to see the leaderboard")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Row view for a single leaderboard entry on Movies Watched tab.
struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let medalType: MedalType?

    var body: some View {
        HStack(spacing: 16) {
            // Rank indicator
            rankView

            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.username)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(isCurrentUser ? Color.goldLight : Color.textPrimary)

                    if isCurrentUser {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.goldPrimary)
                    }
                }

                // Watched percentage (assuming total is stored or can be calculated)
                Text(watchedPercentageText)
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            // Watched count as primary metric
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.watchedCount)")
                    .font(.displaySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.goldPrimary)

                Text("watched")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.goldPrimary : Color.borderColor, lineWidth: isCurrentUser ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(entry.rank), \(entry.username), \(entry.watchedCount) movies watched\(isCurrentUser ? ", this is you" : "")")
    }

    /// Display watched percentage/count text
    private var watchedPercentageText: String {
        // Assuming a fixed total of nominated movies (e.g., 57 for typical Oscar year)
        // In production, this would come from the backend
        let totalMovies = 57
        let percentage = min(100, (entry.watchedCount * 100) / totalMovies)
        return "\(percentage)% complete"
    }

    @ViewBuilder
    private var rankView: some View {
        if let medal = medalType {
            // Medal for top 3
            ZStack {
                Circle()
                    .fill(medalColor(medal))
                    .frame(width: 44, height: 44)

                Text("\(entry.rank)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(medal == .gold ? Color.appBackground : Color.white)
            }
        } else {
            // Regular rank number
            ZStack {
                Circle()
                    .fill(Color.borderColor)
                    .frame(width: 44, height: 44)

                Text("\(entry.rank)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }

    private func medalColor(_ medal: MedalType) -> Color {
        switch medal {
        case .gold:
            return Color.goldPrimary
        case .silver:
            return Color(hue: 0, saturation: 0, brightness: 0.75) // Silver gray
        case .bronze:
            return Color(hue: 30/360, saturation: 0.7, brightness: 0.6) // Bronze color
        }
    }
}

#Preview {
    LeaderboardView()
        .preferredColorScheme(.dark)
}
