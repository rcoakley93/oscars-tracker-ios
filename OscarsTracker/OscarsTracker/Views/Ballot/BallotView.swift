import SwiftUI

/// Ballot view showing all award categories with expandable nominations.
struct BallotView: View {
    @StateObject private var viewModel = BallotViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.categories.isEmpty {
                        loadingView
                    } else if viewModel.categories.isEmpty {
                        emptyStateView
                    } else {
                        categoryGrid
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Ballot")
            .refreshable {
                await viewModel.loadData()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        let columns = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.sortedCategories) { category in
                CategoryCard(
                    category: category,
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading categories...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("No categories found")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Pull to refresh to load award categories")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Expandable card showing a category and its nominations.
struct CategoryCard: View {
    let category: CategoryWithNominations
    @ObservedObject var viewModel: BallotViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Category header (always visible)
            categoryHeader

            // Nominations (shown when expanded)
            if isExpanded {
                nominationsList
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(category.pointsValue ?? 0) points, \(isExpanded ? "expanded" : "collapsed")")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
    }

    private var categoryHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
            HapticManager.selection()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Text("\(category.pointsValue ?? 0) pts")
                            .font(.caption)
                            .foregroundStyle(Color.goldPrimary)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)

                        Text("\(category.nominations.count) nominees")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textMuted)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    private var nominationsList: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.borderColor)

            VStack(spacing: 12) {
                ForEach(category.nominations) { nomination in
                    NominationRow(
                        nomination: nomination,
                        movie: viewModel.movie(for: nomination)
                    )
                }
            }
            .padding()
        }
    }
}

/// Row view for a single nomination.
struct NominationRow: View {
    let nomination: Nomination
    let movie: Movie?

    var body: some View {
        HStack(spacing: 12) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.cardBackground)
                .frame(width: 40, height: 60)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textMuted)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(movie?.title ?? "Unknown Movie")
                    .font(.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                if let detailText = nomination.detailText, !detailText.isEmpty {
                    Text(detailText)
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Winner badge (if applicable)
            if nomination.isWinner == true {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.goldPrimary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie?.title ?? "Unknown Movie"), \(nomination.detailText ?? "")")
    }
}

#Preview {
    BallotView()
        .preferredColorScheme(.dark)
}
