import SwiftUI

/// Watch plan view showing movies grouped by planned date.
struct WatchPlanView: View {
    @StateObject private var viewModel = WatchPlanViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats card
                    statsCard
                        .padding(.horizontal)

                    // Date grouped list
                    if viewModel.isLoading && viewModel.watchPlanItems.isEmpty {
                        loadingView
                    } else if viewModel.watchPlanItems.isEmpty {
                        emptyStateView
                    } else {
                        dateGroupedList
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Watch Plan")
            .refreshable {
                await viewModel.loadData()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: viewModel.plannedCount, label: "planned")
            Divider()
                .frame(height: 40)
                .background(Color.borderColor)
            statItem(value: viewModel.unplannedCount, label: "unplanned")
            Divider()
                .frame(height: 40)
                .background(Color.borderColor)
            statItem(value: viewModel.watchedCount, label: "watched")
        }
        .glassCard()
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headingLarge)
                .foregroundStyle(Color.goldPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Date Grouped List

    private var dateGroupedList: some View {
        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.groupedItems, id: \.date) { group in
                Section {
                    VStack(spacing: 12) {
                        ForEach(group.items) { item in
                            WatchPlanRowView(
                                item: item,
                                movie: viewModel.movie(for: item)
                            )
                        }
                    }
                    .padding(.horizontal)
                } header: {
                    dateHeader(label: group.label, isOverdue: group.label == "OVERDUE")
                }
            }
        }
    }

    private func dateHeader(label: String, isOverdue: Bool) -> some View {
        HStack {
            Text(label)
                .font(.headingSmall)
                .foregroundStyle(isOverdue ? Color.destructive : Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading watch plan...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("No movies planned")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Add movies to your watch plan to track when to watch them")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Row view for a single watch plan item.
struct WatchPlanRowView: View {
    let item: WatchPlanItem
    let movie: Movie?

    var body: some View {
        HStack(spacing: 12) {
            // Poster placeholder
            posterView

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie?.title ?? "Unknown Movie")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let runtime = movie?.formattedRuntime, !runtime.isEmpty {
                        Text(runtime)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                    if let year = movie?.releaseYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }

                if item.isMissed {
                    missedBadge
                }
            }

            Spacer()
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie?.title ?? "Unknown Movie"), \(item.isMissed ? "missed" : "planned")")
    }

    private var posterView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cardBackground)
            .frame(width: 60, height: 90)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textMuted)
            )
    }

    private var missedBadge: some View {
        Text("MISSED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.destructive)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    WatchPlanView()
        .preferredColorScheme(.dark)
}
