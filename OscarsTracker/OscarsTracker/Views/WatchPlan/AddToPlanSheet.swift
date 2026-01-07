import SwiftUI

/// Sheet for adding a movie to the watch plan.
struct AddToPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var searchText = ""
    @State private var selectedMovie: Movie?
    @State private var selectedDate = Date()
    @State private var isAdding = false

    /// Filter unwatched movies that aren't already in the plan
    private var availableMovies: [Movie] {
        let plannedMovieIds = Set(viewModel.watchPlanItems.map { $0.movieId })
        return viewModel.movies.filter { movie in
            // Not watched and not already planned
            !viewModel.watchedMovieIds.contains(movie.id) && !plannedMovieIds.contains(movie.id)
        }
    }

    /// Filtered movies based on search text
    private var filteredMovies: [Movie] {
        if searchText.isEmpty {
            return availableMovies
        }
        return availableMovies.filter { movie in
            movie.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Movie Picker Section
                moviePickerSection

                Divider()
                    .background(Color.borderColor)

                // Date Picker Section
                datePickerSection

                Spacer()

                // Add Button
                addButton
            }
            .background(Color.appBackground)
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    // MARK: - Movie Picker Section

    private var moviePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Movie")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textMuted)
                TextField("Search movies...", text: $searchText)
                    .foregroundStyle(Color.textPrimary)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Movie list
            if filteredMovies.isEmpty {
                emptyStateView
            } else {
                movieListView
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 32))
                .foregroundStyle(Color.textMuted)
            Text(availableMovies.isEmpty ? "No movies available" : "No matching movies")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
            if availableMovies.isEmpty {
                Text("All movies are either watched or already planned")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var movieListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredMovies) { movie in
                    movieRow(movie)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private func movieRow(_ movie: Movie) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMovie = movie
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 12) {
                // Poster placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cardBackground)
                    .frame(width: 40, height: 60)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textMuted)
                    )

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

                // Selection indicator
                if selectedMovie?.id == movie.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.goldPrimary)
                } else {
                    Circle()
                        .stroke(Color.borderColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedMovie?.id == movie.id ? Color.goldPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(movie.title), \(selectedMovie?.id == movie.id ? "selected" : "not selected")")
        .accessibilityHint("Double tap to select this movie")
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            DatePicker(
                "Planned date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.goldPrimary)
            .labelsHidden()
        }
        .padding()
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            Task {
                await addMovieToPlan()
            }
        } label: {
            HStack {
                if isAdding {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Add to Plan")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedMovie != nil ? Color.goldPrimary : Color.cardBackground
            )
            .foregroundStyle(selectedMovie != nil ? .black : Color.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedMovie == nil || isAdding)
        .padding()
        .accessibilityLabel("Add movie to plan")
        .accessibilityHint(selectedMovie == nil ? "Select a movie first" : "Double tap to add \(selectedMovie?.title ?? "") to your plan")
    }

    // MARK: - Actions

    private func addMovieToPlan() async {
        guard let movie = selectedMovie else { return }

        isAdding = true

        let success = await viewModel.addToPlan(movieId: movie.id, date: selectedDate)

        isAdding = false

        if success {
            HapticManager.success()
            dismiss()
        } else {
            HapticManager.error()
        }
    }
}

#Preview {
    AddToPlanSheet(viewModel: WatchPlanViewModel())
        .preferredColorScheme(.dark)
}
