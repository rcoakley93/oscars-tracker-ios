import SwiftUI

/// Leaderboard view showing global user rankings.
struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
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
                .background(Color.appBackground)
                .navigationTitle("Leaderboard")
                .refreshable {
                    await viewModel.loadData()
                }
                .onChange(of: viewModel.entries) { _, _ in
                    scrollToCurrentUser(proxy: proxy)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
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

/// Row view for a single leaderboard entry.
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
                        .foregroundStyle(isCurrentUser ? Color.goldPrimary : Color.textPrimary)

                    if isCurrentUser {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.goldPrimary)
                    }
                }

                // Stats row
                HStack(spacing: 12) {
                    Label("\(entry.watchedCount) watched", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)

                    Label("\(entry.predictionScore) correct", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.predictionScore)")
                    .font(.displaySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.goldPrimary)

                Text("pts")
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
        .accessibilityLabel("Rank \(entry.rank), \(entry.username), \(entry.predictionScore) points, \(entry.watchedCount) movies watched\(isCurrentUser ? ", this is you" : "")")
    }

    private var rankView: some View {
        Group {
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
