import SwiftUI

/// Sheet for adding a movie to the watch plan with improved calendar UX.
struct AddToPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var searchText = ""
    @State private var selectedMovie: Movie?
    @State private var selectedDate = Date()
    @State private var isAdding = false
    @State private var showCalendar = false
    @State private var showScheduledMoviesPopover = false
    @State private var popoverDate: Date?
    @State private var currentMonth = Date()

    private let calendar = Calendar.current

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

    /// Get dates that have scheduled movies
    private var scheduledDates: Set<Date> {
        var dates = Set<Date>()
        for item in viewModel.watchPlanItems {
            if let date = parseDate(item.plannedDate) {
                dates.insert(calendar.startOfDay(for: date))
            }
        }
        return dates
    }

    /// Get movies scheduled for a specific date
    private func moviesForDate(_ date: Date) -> [Movie] {
        let targetDate = calendar.startOfDay(for: date)
        return viewModel.watchPlanItems.compactMap { item -> Movie? in
            guard let itemDate = parseDate(item.plannedDate),
                  calendar.isDate(calendar.startOfDay(for: itemDate), inSameDayAs: targetDate) else {
                return nil
            }
            return item.movie
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showCalendar, selectedMovie != nil {
                    // Calendar view after movie selection
                    calendarSection
                } else {
                    // Movie selection view
                    moviePickerSection
                }

                Spacer()

                // Add Button (only visible when movie is selected)
                if selectedMovie != nil {
                    addButton
                }
            }
            .background(Color.appBackground)
            .navigationTitle(showCalendar ? "Select Date" : "Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(showCalendar ? "Back" : "Cancel") {
                        if showCalendar {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCalendar = false
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
        .frame(maxHeight: 400)
    }

    private func movieRow(_ movie: Movie) -> some View {
        Button {
            selectedMovie = movie
            HapticManager.selection()
            // Transition to calendar after short delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCalendar = true
                }
            }
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
                        if !movie.formattedRuntime.isEmpty {
                            Text(movie.formattedRuntime)
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(movie.title)
        .accessibilityHint("Double tap to select this movie and choose a date")
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Selected movie header
            if let movie = selectedMovie {
                selectedMovieHeader(movie)
            }

            Divider()
                .background(Color.borderColor)

            // Compact calendar
            compactCalendarView
        }
        .padding()
    }

    private func selectedMovieHeader(_ movie: Movie) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
                .frame(width: 50, height: 75)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.textMuted)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headingSmall)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if !movie.formattedRuntime.isEmpty {
                        Text(movie.formattedRuntime)
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
        .padding()
        .glassCard()
    }

    private var compactCalendarView: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.goldPrimary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(monthYearString(currentMonth))
                    .font(.headingSmall)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.goldPrimary)
                        .frame(width: 44, height: 44)
                }
            }

            // Day of week headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth(currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isPast = date < calendar.startOfDay(for: Date())
        let hasScheduledMovies = scheduledDates.contains(calendar.startOfDay(for: date))
        let scheduledMoviesForDay = moviesForDate(date)

        return Button {
            if hasScheduledMovies && !scheduledMoviesForDay.isEmpty {
                popoverDate = date
                showScheduledMoviesPopover = true
                HapticManager.light()
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(
                        isPast ? Color.textMuted.opacity(0.5) :
                            isSelected ? .black :
                            isToday ? Color.goldPrimary :
                            Color.textPrimary
                    )

                // Dot indicator for scheduled movies
                if hasScheduledMovies {
                    Circle()
                        .fill(isSelected ? Color.white : Color.goldPrimary)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 44)
            .background {
                if isSelected {
                    Circle()
                        .fill(Color.goldPrimary)
                        .frame(width: 40, height: 40)
                } else if isToday {
                    Circle()
                        .stroke(Color.goldPrimary, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isPast)
        .popover(isPresented: Binding(
            get: { showScheduledMoviesPopover && popoverDate != nil && calendar.isDate(date, inSameDayAs: popoverDate!) },
            set: { if !$0 { showScheduledMoviesPopover = false; popoverDate = nil } }
        )) {
            scheduledMoviesPopover(for: date)
        }
        .accessibilityLabel("\(dayNumber(date)), \(isSelected ? "selected" : "")\(hasScheduledMovies ? ", has \(scheduledMoviesForDay.count) scheduled movies" : "")")
        .accessibilityHint(isPast ? "Date in the past" : "Double tap to select this date")
    }

    private func scheduledMoviesPopover(for date: Date) -> some View {
        let movies = moviesForDate(date)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Scheduled for \(formattedDate(date))")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            ForEach(movies) { movie in
                HStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.goldPrimary)
                    Text(movie.title)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .presentationCompactAdaptation(.popover)
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
                        .tint(.black)
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Plan for \(formattedShortDate(selectedDate))")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.goldPrimary)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedMovie == nil || isAdding)
        .padding()
        .accessibilityLabel("Add movie to plan")
        .accessibilityHint("Double tap to add \(selectedMovie?.title ?? "") to your plan for \(formattedDate(selectedDate))")
    }

    // MARK: - Helper Functions

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth(_ date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = firstWeek.start

        // Add padding for days before month starts
        let firstDayOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        for _ in 1..<weekday {
            days.append(nil)
        }

        // Add all days in the month
        while currentDate < monthInterval.end {
            if calendar.isDate(currentDate, equalTo: date, toGranularity: .month) {
                days.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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
