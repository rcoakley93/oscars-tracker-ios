import SwiftUI

/// Reusable calendar view for watch plan scheduling with scheduled movie indicators.
struct PlanCalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var currentMonth = Date()
    @State private var showScheduledMoviesPopover = false
    @State private var popoverDate: Date?

    private let calendar = Calendar.current

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
            // Try to get movie from item first, fallback to looking up by movieId
            if let movie = item.movie {
                return movie
            }
            return viewModel.movies.first { $0.id == item.movieId }
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    var body: some View {
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
                    Text("\(movie.title)\(!movie.formattedRuntime.isEmpty ? " (\(movie.formattedRuntime))" : "")")
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
}
