import SwiftUI
import Kingfisher

/// Displays movies grouped by award category with watch toggle support.
struct CategoryListView: View {
    let categoriesWithMovies: [CategoryWithMovies]
    let watchedMovieIds: Set<Int>
    let onToggleWatched: (Int) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Use 2-column layout on iPad
    private var useGridLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        if useGridLayout {
            // iPad: 2-column grid layout
            iPadGridLayout
        } else {
            // iPhone: Standard list layout
            iPhoneListLayout
        }
    }

    // MARK: - iPad Grid Layout

    private var iPadGridLayout: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
            ForEach(categoriesWithMovies) { category in
                VStack(alignment: .leading, spacing: 12) {
                    CategoryHeaderView(categoryName: category.name, movieCount: category.movies.count)
                    categoryMoviesGrid(for: category)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - iPhone List Layout

    private var iPhoneListLayout: some View {
        LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
            ForEach(categoriesWithMovies) { category in
                Section {
                    categoryMoviesGrid(for: category)
                } header: {
                    CategoryHeaderView(categoryName: category.name, movieCount: category.movies.count)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Category Movies Grid

    @ViewBuilder
    private func categoryMoviesGrid(for category: CategoryWithMovies) -> some View {
        VStack(spacing: 12) {
            ForEach(category.nominees) { nominee in
                CategoryMovieRow(
                    nominee: nominee,
                    isActorCategory: category.isActorCategory,
                    isWatched: watchedMovieIds.contains(nominee.movie.id),
                    onToggleWatched: {
                        onToggleWatched(nominee.movie.id)
                    }
                )
            }
        }
    }
}

/// Header view for a category section.
struct CategoryHeaderView: View {
    let categoryName: String
    let movieCount: Int

    var body: some View {
        HStack {
            Text(categoryName)
                .font(.headingSmall)
                .foregroundStyle(Color.goldPrimary)

            Spacer()

            Text("\(movieCount) \(movieCount == 1 ? "movie" : "movies")")
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.appBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryName), \(movieCount) movies")
    }
}

/// A row displaying a movie with watch toggle in the category list.
/// For actor categories, displays actor name as primary and movie title as secondary.
struct CategoryMovieRow: View {
    let nominee: CategoryNominee
    let isActorCategory: Bool
    let isWatched: Bool
    let onToggleWatched: () -> Void

    private var movie: Movie { nominee.movie }

    /// Primary headline text - actor name for actor categories, movie title otherwise
    private var headlineText: String {
        if isActorCategory, let actorName = nominee.detailText, !actorName.isEmpty {
            return actorName
        }
        return movie.title
    }

    /// Subheadline text - movie title (year) for actor categories, year/runtime otherwise
    private var subheadlineText: String? {
        if isActorCategory, let actorName = nominee.detailText, !actorName.isEmpty {
            // Show "Movie Title (2025)" format
            if let year = movie.releaseYear {
                return "\(movie.title) (\(year))"
            }
            return movie.title
        }
        return nil  // Non-actor categories don't need this
    }

    var body: some View {
        HStack(spacing: 12) {
            // Poster thumbnail
            posterThumbnail

            // Movie/Actor info
            VStack(alignment: .leading, spacing: 4) {
                // Primary headline (actor name or movie title)
                Text(headlineText)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                // Subheadline for actor categories (movie title with year)
                if let subheadline = subheadlineText {
                    Text(subheadline)
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                }

                // Runtime info (shown for all categories)
                HStack(spacing: 8) {
                    // For non-actor categories, show year here
                    if !isActorCategory || subheadlineText == nil {
                        if let year = movie.releaseYear {
                            Text(verbatim: "\(year)")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                        }
                    }

                    if !movie.formattedRuntime.isEmpty {
                        Text(movie.formattedRuntime)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }

            Spacer()

            // Watch toggle button
            watchToggleButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWatched ? Color.goldPrimary.opacity(0.5) : Color.borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap to toggle watched status")
    }

    private var accessibilityLabelText: String {
        if isActorCategory, let actorName = nominee.detailText, !actorName.isEmpty {
            return "\(actorName) in \(movie.title), \(isWatched ? "watched" : "not watched")"
        }
        return "\(movie.title), \(isWatched ? "watched" : "not watched")"
    }

    // MARK: - Subviews

    private var posterThumbnail: some View {
        SwiftUI.Group {
            if let posterUrl = movie.posterUrl, let url = URL(string: posterUrl) {
                KFImage(url)
                    .placeholder {
                        posterPlaceholder
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } else {
                posterPlaceholder
            }
        }
        .frame(width: 50, height: 75)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isWatched ? Color.goldPrimary : Color.borderColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondaryBackground)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textMuted)
            )
    }

    private var watchToggleButton: some View {
        Button(action: onToggleWatched) {
            Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 28))
                .foregroundStyle(isWatched ? Color.goldPrimary : Color.textMuted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isWatched ? "Mark as unwatched" : "Mark as watched")
    }
}

#Preview {
    ScrollView {
        CategoryListView(
            categoriesWithMovies: [
                CategoryWithMovies(
                    id: 1,
                    name: "Best Picture",
                    nominees: [
                        CategoryNominee(id: 1, movie: Movie(id: 1, title: "The Brutalist", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 215, createdAt: nil), detailText: nil),
                        CategoryNominee(id: 2, movie: Movie(id: 2, title: "Anora", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 139, createdAt: nil), detailText: nil),
                        CategoryNominee(id: 3, movie: Movie(id: 3, title: "Conclave", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 120, createdAt: nil), detailText: nil)
                    ]
                ),
                CategoryWithMovies(
                    id: 2,
                    name: "Best Actor",
                    nominees: [
                        CategoryNominee(id: 4, movie: Movie(id: 1, title: "The Brutalist", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 215, createdAt: nil), detailText: "Adrien Brody"),
                        CategoryNominee(id: 5, movie: Movie(id: 4, title: "A Complete Unknown", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 140, createdAt: nil), detailText: "Timothée Chalamet"),
                        CategoryNominee(id: 6, movie: Movie(id: 5, title: "Sing Sing", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 107, createdAt: nil), detailText: "Colman Domingo")
                    ]
                )
            ],
            watchedMovieIds: [1, 3],
            onToggleWatched: { _ in }
        )
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
