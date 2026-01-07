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

            VStack(spacing: 8) {
                ForEach(category.nominations) { nomination in
                    NominationRow(
                        nomination: nomination,
                        movie: viewModel.movie(for: nomination),
                        isSelected: viewModel.isSelected(nomination: nomination),
                        onSelect: {
                            Task {
                                await viewModel.selectPrediction(nomination: nomination)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

/// Row view for a single nomination with radio button selection.
struct NominationRow: View {
    let nomination: Nomination
    let movie: Movie?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio button indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.goldPrimary : Color.borderColor, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.goldPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

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
                        .foregroundStyle(isSelected ? Color.goldPrimary : Color.textPrimary)
                        .lineLimit(2)

                    if let detailText = nomination.detailText, !detailText.isEmpty {
                        Text(detailText)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Checkmark for selected (in addition to radio)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.goldPrimary)
                }

                // Winner badge (if applicable)
                if nomination.isWinner == true {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.goldPrimary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.goldPrimary.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.goldPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie?.title ?? "Unknown Movie"), \(nomination.detailText ?? ""), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this prediction")
    }
}

#Preview {
    BallotView()
        .preferredColorScheme(.dark)
}
