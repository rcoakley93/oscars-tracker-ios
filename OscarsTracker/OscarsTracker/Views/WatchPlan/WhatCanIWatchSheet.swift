import SwiftUI

/// Runtime filter options for "What Can I Watch" functionality.
enum RuntimeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case short = "Short"       // < 90 min
    case medium = "Medium"     // 90-120 min
    case long = "Long"         // > 120 min

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "film.stack"
        case .short: return "clock"
        case .medium: return "clock.fill"
        case .long: return "clock.badge.checkmark"
        }
    }

    var description: String {
        switch self {
        case .all: return "Any length"
        case .short: return "Under 90 min"
        case .medium: return "90-120 min"
        case .long: return "Over 2 hours"
        }
    }

    func matches(_ movie: Movie) -> Bool {
        guard let runtime = movie.runtimeMinutes else { return self == .all }
        switch self {
        case .all: return true
        case .short: return runtime < 90
        case .medium: return runtime >= 90 && runtime <= 120
        case .long: return runtime > 120
        }
    }
}

/// Sheet for discovering what movies to watch based on available time.
struct WhatCanIWatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var selectedFilter: RuntimeFilter = .all
    @State private var isAddingMovie: Int? = nil

    /// Get unwatched movies that aren't already in the plan
    private var availableMovies: [Movie] {
        let plannedMovieIds = Set(viewModel.watchPlanItems.map { $0.movieId })
        return viewModel.movies.filter { movie in
            !viewModel.watchedMovieIds.contains(movie.id) && !plannedMovieIds.contains(movie.id)
        }
    }

    /// Filtered movies based on selected runtime filter
    private var filteredMovies: [Movie] {
        availableMovies
            .filter { selectedFilter.matches($0) }
            .sorted { ($0.runtimeMinutes ?? 0) < ($1.runtimeMinutes ?? 0) }
    }

    /// Count of movies for each filter
    private func countForFilter(_ filter: RuntimeFilter) -> Int {
        availableMovies.filter { filter.matches($0) }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Runtime filter section
                filterSection

                Divider()
                    .background(Color.borderColor)

                // Movie list
                if filteredMovies.isEmpty {
                    emptyStateView
                } else {
                    movieListView
                }
            }
            .background(Color.appBackground)
            .navigationTitle("What Can I Watch?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.goldPrimary)
                }
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How much time do you have?")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RuntimeFilter.allCases) { filter in
                        filterChip(filter)
                    }
                }
            }
        }
        .padding()
    }

    private func filterChip(_ filter: RuntimeFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = countForFilter(filter)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))

                Text(filter.rawValue)
                    .font(.bodyMedium)

                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .black.opacity(0.7) : Color.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.goldPrimary : Color.cardBackground)
            .foregroundStyle(isSelected ? .black : Color.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.rawValue), \(filter.description), \(count) movies")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)

            Text("No movies found")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)

            Text(emptyStateMessage)
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "All movies are either watched or already in your plan"
        case .short:
            return "No short movies (under 90 min) available"
        case .medium:
            return "No medium-length movies (90-120 min) available"
        case .long:
            return "No long movies (over 2 hours) available"
        }
    }

    // MARK: - Movie List

    private var movieListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary header
                summaryHeader

                ForEach(filteredMovies) { movie in
                    movieRow(movie)
                }
            }
            .padding()
        }
    }

    private var summaryHeader: some View {
        let totalRuntime = filteredMovies.reduce(0) { $0 + ($1.runtimeMinutes ?? 0) }
        let hours = totalRuntime / 60
        let minutes = totalRuntime % 60

        return HStack {
            Image(systemName: "film")
                .foregroundStyle(Color.goldPrimary)

            Text("\(filteredMovies.count) movies")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text("\(hours)h \(minutes)m total")
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .padding(12)
        .background(Color.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func movieRow(_ movie: Movie) -> some View {
        HStack(spacing: 12) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
                .frame(width: 50, height: 75)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textMuted)
                )

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let runtime = movie.formattedRuntime, !runtime.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(runtime)
                        }
                        .font(.caption)
                        .foregroundStyle(runtimeColor(for: movie))
                    }

                    if let year = movie.releaseYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }

            Spacer()

            // Quick add button
            Button {
                Task {
                    await quickAddToPlan(movie)
                }
            } label: {
                if isAddingMovie == movie.id {
                    ProgressView()
                        .tint(Color.goldPrimary)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.goldPrimary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isAddingMovie != nil)
            .accessibilityLabel("Add \(movie.title) to plan")
            .accessibilityHint("Adds this movie to your watch plan for today")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
    }

    private func runtimeColor(for movie: Movie) -> Color {
        guard let runtime = movie.runtimeMinutes else { return Color.textMuted }
        if runtime < 90 { return Color.success }
        if runtime <= 120 { return Color.goldPrimary }
        return Color.destructive.opacity(0.8)
    }

    // MARK: - Actions

    private func quickAddToPlan(_ movie: Movie) async {
        isAddingMovie = movie.id
        HapticManager.selection()

        // Add to plan for today
        let success = await viewModel.addToPlan(movieId: movie.id, date: Date())

        isAddingMovie = nil

        if success {
            HapticManager.success()
        } else {
            HapticManager.error()
        }
    }
}

#Preview {
    WhatCanIWatchSheet(viewModel: WatchPlanViewModel())
        .preferredColorScheme(.dark)
}
