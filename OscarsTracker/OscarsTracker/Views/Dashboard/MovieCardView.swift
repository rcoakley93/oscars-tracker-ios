import SwiftUI
import Kingfisher

/// A card displaying a movie poster with title, runtime, and watched status.
struct MovieCardView: View {
    let movie: Movie
    let isWatched: Bool
    let onTap: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster with watched indicator
                ZStack(alignment: .topTrailing) {
                    posterImage

                    if isWatched {
                        watchedIndicator
                    }
                }

                // Movie info
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !movie.formattedRuntime.isEmpty {
                        Text(movie.formattedRuntime)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title), \(isWatched ? "watched" : "not watched")")
        .accessibilityHint("Double tap to toggle watched status")
    }

    // MARK: - Subviews

    private var posterImage: some View {
        SwiftUI.Group {
            if let posterUrl = movie.posterUrl, let url = URL(string: posterUrl) {
                KFImage(url)
                    .placeholder {
                        posterPlaceholder
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                posterPlaceholder
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isWatched ? Color.goldPrimary : Color.borderColor, lineWidth: isWatched ? 2 : 1)
        )
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cardBackground)
            .aspectRatio(2/3, contentMode: .fit)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.textMuted)
            )
    }

    private var watchedIndicator: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(Color.goldPrimary)
            .background(
                Circle()
                    .fill(Color.appBackground)
                    .padding(2)
            )
            .padding(8)
    }
}

/// Grid layout for displaying movies.
struct MovieGridView: View {
    let movies: [Movie]
    let watchedMovieIds: Set<Int>
    let onToggleWatched: (Int) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 5 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(movies) { movie in
                MovieCardView(
                    movie: movie,
                    isWatched: watchedMovieIds.contains(movie.id),
                    onTap: {
                        onToggleWatched(movie.id)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

/// List layout for displaying movies in compact rows.
/// Reuses similar styling to CategoryMovieRow for consistency.
struct MovieListView: View {
    let movies: [Movie]
    let watchedMovieIds: Set<Int>
    let onToggleWatched: (Int) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(movies) { movie in
                MovieListRow(
                    movie: movie,
                    isWatched: watchedMovieIds.contains(movie.id),
                    onToggleWatched: {
                        onToggleWatched(movie.id)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

/// A compact row for displaying a movie in list mode.
/// Similar to CategoryMovieRow for consistency.
struct MovieListRow: View {
    let movie: Movie
    let isWatched: Bool
    let onToggleWatched: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Poster thumbnail
            posterThumbnail

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = movie.releaseYear {
                        Text(verbatim: "\(year)")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
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
        .accessibilityLabel("\(movie.title), \(isWatched ? "watched" : "not watched")")
        .accessibilityHint("Double tap to toggle watched status")
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

#Preview("Grid View") {
    ScrollView {
        MovieGridView(
            movies: [
                Movie(id: 1, title: "The Brutalist", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 215, createdAt: nil),
                Movie(id: 2, title: "Anora", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 139, createdAt: nil),
                Movie(id: 3, title: "Conclave", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 120, createdAt: nil),
                Movie(id: 4, title: "Emilia Pérez", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 130, createdAt: nil)
            ],
            watchedMovieIds: [1, 3],
            onToggleWatched: { _ in }
        )
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("List View") {
    ScrollView {
        MovieListView(
            movies: [
                Movie(id: 1, title: "The Brutalist", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 215, createdAt: nil),
                Movie(id: 2, title: "Anora", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 139, createdAt: nil),
                Movie(id: 3, title: "Conclave", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 120, createdAt: nil),
                Movie(id: 4, title: "Emilia Pérez", posterUrl: nil, releaseYear: 2024, runtimeMinutes: 130, createdAt: nil)
            ],
            watchedMovieIds: [1, 3],
            onToggleWatched: { _ in }
        )
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
