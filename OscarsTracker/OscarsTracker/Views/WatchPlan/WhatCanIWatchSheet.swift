import SwiftUI

/// Runtime filter options for "What Can I Watch" functionality.
/// Matches web version time ranges exactly.
enum TimeOption: String, CaseIterable, Identifiable {
    case short = "Short"           // < 40 min
    case medium = "Medium"         // 40-90 min
    case standard = "Standard"     // 91-120 min
    case unlimited = "Unlimited"   // 3 longest unwatched movies

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .short: return "bolt.fill"
        case .medium: return "clock"
        case .standard: return "clock.fill"
        case .unlimited: return "infinity"
        }
    }

    var timeLabel: String {
        switch self {
        case .short: return "< 40m"
        case .medium: return "< 90m"
        case .standard: return "< 2h"
        case .unlimited: return "Any"
        }
    }

    var description: String {
        switch self {
        case .short: return "Quick watch"
        case .medium: return "Standard film"
        case .standard: return "Feature length"
        case .unlimited: return "3 longest movies"
        }
    }

    func matches(_ movie: Movie) -> Bool {
        guard let runtime = movie.runtimeMinutes else { return false }
        switch self {
        case .short: return runtime < 40
        case .medium: return runtime >= 40 && runtime < 90
        case .standard: return runtime >= 91 && runtime <= 120
        case .unlimited: return true  // Special handling for unlimited
        }
    }
}

/// Sheet for discovering what movies to watch based on available time.
/// Matches web version UI with 2x2 grid of time options and random recommendations.
struct WhatCanIWatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var selectedOption: TimeOption? = nil
    @State private var recommendedMovies: [Movie] = []
    @State private var isAddingMovie: Int? = nil

    /// Get unwatched movies that aren't already in the plan
    private var availableMovies: [Movie] {
        let plannedMovieIds = Set(viewModel.watchPlanItems.map { $0.movieId })
        return viewModel.movies.filter { movie in
            !viewModel.watchedMovieIds.contains(movie.id) && !plannedMovieIds.contains(movie.id)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedOption == nil {
                    // Time selection view
                    timeSelectionView
                } else {
                    // Recommendation view
                    recommendationView
                }
            }
            .background(Color.appBackground)
            .navigationTitle("What Can I Watch?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedOption == nil ? "Done" : "Back") {
                        if selectedOption == nil {
                            dismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedOption = nil
                                recommendedMovies = []
                            }
                        }
                    }
                    .foregroundStyle(selectedOption == nil ? Color.goldPrimary : Color.textMuted)
                }
            }
        }
    }

    // MARK: - Time Selection View

    private var timeSelectionView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.goldPrimary)

                Text("How much time do you have?")
                    .font(.headingMedium)
                    .foregroundStyle(Color.textPrimary)

                Text("Select a time range and I'll suggest a movie")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // 2x2 Grid of time options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(TimeOption.allCases) { option in
                    timeOptionButton(option)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Stats
            statsSection
        }
        .padding()
    }

    private func timeOptionButton(_ option: TimeOption) -> some View {
        let count = countForOption(option)
        let isDisabled = count == 0

        return Button {
            selectOption(option)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isDisabled ? Color.textMuted : Color.goldPrimary)

                VStack(spacing: 4) {
                    Text(option.rawValue)
                        .font(.headingSmall)
                        .foregroundStyle(isDisabled ? Color.textMuted : Color.textPrimary)

                    Text(option.timeLabel)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)

                    if count > 0 {
                        Text("\(count) movie\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.goldPrimary)
                    } else {
                        Text("None available")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel("\(option.rawValue), \(option.timeLabel), \(count) movies available")
        .accessibilityHint(isDisabled ? "No movies available" : "Double tap to see recommendations")
    }

    private func countForOption(_ option: TimeOption) -> Int {
        if option == .unlimited {
            // For unlimited, count all available movies (we show top 3)
            return min(3, availableMovies.count)
        }
        return availableMovies.filter { option.matches($0) }.count
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(availableMovies.count)")
                    .font(.headingMedium)
                    .foregroundStyle(Color.goldPrimary)
                Text("Unwatched")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(viewModel.watchPlanItems.count)")
                    .font(.headingMedium)
                    .foregroundStyle(Color.goldPrimary)
                Text("Planned")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Recommendation View

    private var recommendationView: some View {
        VStack(spacing: 0) {
            // Header
            recommendationHeader

            Divider()
                .background(Color.borderColor)

            // Recommended movies
            if recommendedMovies.isEmpty {
                emptyRecommendationState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recommendedMovies) { movie in
                            recommendedMovieCard(movie)
                        }
                    }
                    .padding()
                }
            }

            Spacer()

            // Try another button
            tryAnotherButton
        }
    }

    private var recommendationHeader: some View {
        VStack(spacing: 8) {
            if let option = selectedOption {
                HStack {
                    Image(systemName: option.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(Color.goldPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(option == .unlimited ? "Longest Movies" : "\(option.rawValue) Movies")
                            .font(.headingSmall)
                            .foregroundStyle(Color.textPrimary)

                        Text(option == .unlimited ? "Top 3 by runtime" : option.description)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .glassCard()
        .padding()
    }

    private var emptyRecommendationState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)

            Text("No movies found")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)

            if let option = selectedOption {
                Text(emptyStateMessage(for: option))
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func emptyStateMessage(for option: TimeOption) -> String {
        switch option {
        case .short:
            return "No short movies (under 40 minutes) available"
        case .medium:
            return "No medium-length movies (40-90 minutes) available"
        case .standard:
            return "No standard-length movies (91-120 minutes) available"
        case .unlimited:
            return "All movies are either watched or already in your plan"
        }
    }

    private func recommendedMovieCard(_ movie: Movie) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Poster placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .frame(width: 80, height: 120)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.textMuted)
                    )

                // Movie info
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.headingSmall)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        if !movie.formattedRuntime.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(movie.formattedRuntime)
                            }
                            .font(.bodyMedium)
                            .foregroundStyle(runtimeColor(for: movie))
                        }

                        if let year = movie.releaseYear {
                            Text("\(year)")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)
                        }
                    }

                    Spacer()
                }

                Spacer()
            }

            // Add to plan button
            Button {
                Task {
                    await quickAddToPlan(movie)
                }
            } label: {
                HStack {
                    if isAddingMovie == movie.id {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Plan")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.goldPrimary)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isAddingMovie != nil)
            .accessibilityLabel("Add \(movie.title) to plan")
            .accessibilityHint("Adds this movie to your watch plan for today")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
        )
    }

    private var tryAnotherButton: some View {
        Button {
            if let option = selectedOption {
                generateRecommendations(for: option)
            }
            HapticManager.selection()
        } label: {
            HStack {
                Image(systemName: "shuffle")
                Text("Try Another")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .foregroundStyle(Color.goldPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.goldPrimary.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding()
        .accessibilityLabel("Try another recommendation")
        .accessibilityHint("Shows a different random movie")
    }

    private func runtimeColor(for movie: Movie) -> Color {
        guard let runtime = movie.runtimeMinutes else { return Color.textMuted }
        if runtime < 40 { return Color.success }
        if runtime < 90 { return Color.goldPrimary }
        if runtime <= 120 { return Color.goldPrimary }
        return Color.destructive.opacity(0.8)
    }

    // MARK: - Actions

    private func selectOption(_ option: TimeOption) {
        HapticManager.selection()
        selectedOption = option
        generateRecommendations(for: option)

        withAnimation(.easeInOut(duration: 0.3)) {
            // Animation handled by view transition
        }
    }

    private func generateRecommendations(for option: TimeOption) {
        if option == .unlimited {
            // For unlimited, show 3 longest movies
            recommendedMovies = Array(
                availableMovies
                    .sorted { ($0.runtimeMinutes ?? 0) > ($1.runtimeMinutes ?? 0) }
                    .prefix(3)
            )
        } else {
            // For other options, pick a random movie matching the criteria
            let matchingMovies = availableMovies.filter { option.matches($0) }
            if let randomMovie = matchingMovies.randomElement() {
                recommendedMovies = [randomMovie]
            } else {
                recommendedMovies = []
            }
        }
    }

    private func quickAddToPlan(_ movie: Movie) async {
        isAddingMovie = movie.id
        HapticManager.selection()

        // Add to plan for today
        let success = await viewModel.addToPlan(movieId: movie.id, date: Date())

        isAddingMovie = nil

        if success {
            HapticManager.success()
            // Remove the movie from recommendations after adding
            recommendedMovies.removeAll { $0.id == movie.id }

            // If all movies added, go back to selection
            if recommendedMovies.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedOption = nil
                }
            }
        } else {
            HapticManager.error()
        }
    }
}

#Preview {
    WhatCanIWatchSheet(viewModel: WatchPlanViewModel())
        .preferredColorScheme(.dark)
}
