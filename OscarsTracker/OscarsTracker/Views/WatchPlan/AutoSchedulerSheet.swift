import SwiftUI

/// Sheet for automatically scheduling unwatched movies.
struct AutoSchedulerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var selectedMovieIds: Set<Int> = []
    @State private var suggestedSchedule: [(movie: Movie, date: Date)] = []
    @State private var isScheduling = false
    @State private var showPreview = false

    /// Get unwatched movies that aren't already in the plan
    private var availableMovies: [Movie] {
        let plannedMovieIds = Set(viewModel.watchPlanItems.map { $0.movieId })
        return viewModel.movies.filter { movie in
            !viewModel.watchedMovieIds.contains(movie.id) && !plannedMovieIds.contains(movie.id)
        }.sorted { ($0.runtimeMinutes ?? 0) < ($1.runtimeMinutes ?? 0) }
    }

    /// Selected movies from the available list
    private var selectedMovies: [Movie] {
        availableMovies.filter { selectedMovieIds.contains($0.id) }
    }

    /// Check if all movies are selected
    private var allSelected: Bool {
        !availableMovies.isEmpty && selectedMovieIds.count == availableMovies.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showPreview {
                    previewSection
                } else {
                    movieSelectionSection
                }
            }
            .background(Color.appBackground)
            .navigationTitle(showPreview ? "Schedule Preview" : "Auto Scheduler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(showPreview ? "Back" : "Cancel") {
                        if showPreview {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPreview = false
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    // MARK: - Movie Selection Section

    private var movieSelectionSection: some View {
        VStack(spacing: 0) {
            // Header with select all
            selectAllHeader

            Divider()
                .background(Color.borderColor)

            // Movie list
            if availableMovies.isEmpty {
                emptyStateView
            } else {
                movieListView
            }

            Spacer()

            // Generate schedule button
            generateButton
        }
    }

    private var selectAllHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Movies to Schedule")
                    .font(.headingSmall)
                    .foregroundStyle(Color.textPrimary)
                Text("\(selectedMovieIds.count) of \(availableMovies.count) selected")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if allSelected {
                        selectedMovieIds.removeAll()
                    } else {
                        selectedMovieIds = Set(availableMovies.map { $0.id })
                    }
                }
                HapticManager.selection()
            } label: {
                Text(allSelected ? "Deselect All" : "Select All")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.goldPrimary)
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("All caught up!")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("All movies are either watched or already scheduled")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var movieListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(availableMovies) { movie in
                    movieSelectionRow(movie)
                }
            }
            .padding()
        }
    }

    private func movieSelectionRow(_ movie: Movie) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedMovieIds.contains(movie.id) {
                    selectedMovieIds.remove(movie.id)
                } else {
                    selectedMovieIds.insert(movie.id)
                }
            }
            HapticManager.light()
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedMovieIds.contains(movie.id) ? Color.goldPrimary : Color.borderColor, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if selectedMovieIds.contains(movie.id) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.goldPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }

                // Poster placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cardBackground)
                    .frame(width: 40, height: 60)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textMuted)
                    )

                // Movie info
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        if let runtime = movie.formattedRuntime, !runtime.isEmpty {
                            Text(runtime)
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                        }
                        if let year = movie.releaseYear {
                            Text("\(year)")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedMovieIds.contains(movie.id) ? Color.goldPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(movie.title), \(selectedMovieIds.contains(movie.id) ? "selected" : "not selected")")
        .accessibilityHint("Double tap to toggle selection")
    }

    private var generateButton: some View {
        Button {
            generateSchedule()
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Generate Schedule")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedMovieIds.isEmpty ? Color.cardBackground : Color.goldPrimary
            )
            .foregroundStyle(selectedMovieIds.isEmpty ? Color.textMuted : .black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedMovieIds.isEmpty)
        .padding()
        .accessibilityLabel("Generate schedule")
        .accessibilityHint(selectedMovieIds.isEmpty ? "Select movies first" : "Creates a suggested viewing schedule for \(selectedMovieIds.count) movies")
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeader

            Divider()
                .background(Color.borderColor)

            // Schedule preview list
            schedulePreviewList

            Spacer()

            // Confirm button
            confirmButton
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggested Schedule")
                        .font(.headingSmall)
                        .foregroundStyle(Color.textPrimary)
                    Text("\(suggestedSchedule.count) movies over \(daysSpan) days")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                }

                Spacer()
            }

            // Total runtime
            let totalMinutes = suggestedSchedule.reduce(0) { $0 + ($1.movie.runtimeMinutes ?? 0) }
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            Text("Total runtime: \(hours)h \(minutes)m")
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .padding()
        .glassCard()
        .padding()
    }

    private var daysSpan: Int {
        guard let firstDate = suggestedSchedule.first?.date,
              let lastDate = suggestedSchedule.last?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0 + 1
    }

    private var schedulePreviewList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(suggestedSchedule.enumerated()), id: \.element.movie.id) { index, item in
                    schedulePreviewRow(item.movie, date: item.date, index: index)
                }
            }
            .padding()
        }
    }

    private func schedulePreviewRow(_ movie: Movie, date: Date, index: Int) -> some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(dayOfWeek(date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textMuted)
                Text(dayNumber(date))
                    .font(.headingMedium)
                    .foregroundStyle(Color.goldPrimary)
                Text(monthAbbrev(date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textMuted)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Poster placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.cardBackground)
                .frame(width: 40, height: 60)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textMuted)
                )

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                if let runtime = movie.formattedRuntime, !runtime.isEmpty {
                    Text(runtime)
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title) scheduled for \(formattedDate(date))")
    }

    private var confirmButton: some View {
        Button {
            Task {
                await confirmSchedule()
            }
        } label: {
            HStack {
                if isScheduling {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirm Schedule")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.goldPrimary)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isScheduling)
        .padding()
        .accessibilityLabel("Confirm schedule")
        .accessibilityHint("Adds all scheduled movies to your watch plan")
    }

    // MARK: - Helper Functions

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthAbbrev(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Scheduling Logic

    /// Generate a suggested schedule for selected movies
    private func generateSchedule() {
        HapticManager.selection()

        let movies = selectedMovies
        guard !movies.isEmpty else { return }

        // Get existing planned dates to avoid conflicts
        let existingDates = Set(viewModel.watchPlanItems.compactMap { item -> Date? in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: item.plannedDate) else { return nil }
            return Calendar.current.startOfDay(for: date)
        })

        // Calculate Oscar date (March 15, 2025 as deadline)
        let calendar = Calendar.current
        var oscarComponents = DateComponents()
        oscarComponents.year = 2025
        oscarComponents.month = 3
        oscarComponents.day = 15
        let oscarDate = calendar.date(from: oscarComponents) ?? Date()

        // Start from today
        var currentDate = calendar.startOfDay(for: Date())
        var schedule: [(movie: Movie, date: Date)] = []

        // Sort movies by runtime (shorter first) for better distribution
        let sortedMovies = movies.sorted { ($0.runtimeMinutes ?? 0) < ($1.runtimeMinutes ?? 0) }

        for movie in sortedMovies {
            // Find next available date that doesn't conflict
            while existingDates.contains(currentDate) || schedule.contains(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            // Don't schedule past Oscar date
            if currentDate > oscarDate {
                // Wrap around to fill gaps if possible
                break
            }

            schedule.append((movie: movie, date: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        suggestedSchedule = schedule

        withAnimation(.easeInOut(duration: 0.3)) {
            showPreview = true
        }
    }

    /// Confirm and save the generated schedule
    private func confirmSchedule() async {
        isScheduling = true

        let success = await viewModel.bulkAddToPlan(movies: suggestedSchedule.map { ($0.movie.id, $0.date) })

        isScheduling = false

        if success {
            HapticManager.success()
            dismiss()
        } else {
            HapticManager.error()
        }
    }
}

#Preview {
    AutoSchedulerSheet(viewModel: WatchPlanViewModel())
        .preferredColorScheme(.dark)
}
