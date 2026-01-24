import SwiftUI

/// Quick action presets for the AI auto scheduler
enum QuickAction: String, CaseIterable, Identifiable {
    case fillGaps = "Fill Gaps"
    case rescheduleOverdue = "Reschedule Overdue"
    case reorganizePlan = "Reorganize Plan"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fillGaps: return "calendar.badge.plus"
        case .rescheduleOverdue: return "clock.arrow.circlepath"
        case .reorganizePlan: return "arrow.triangle.swap"
        }
    }

    var prompt: String {
        switch self {
        case .fillGaps: return "Fill in the gaps in my schedule with unwatched movies"
        case .rescheduleOverdue: return "Reschedule all overdue movies to available upcoming dates"
        case .reorganizePlan: return "Reorganize my entire watch plan for a better viewing experience"
        }
    }

    var description: String {
        switch self {
        case .fillGaps: return "Add movies to empty days"
        case .rescheduleOverdue: return "Move missed movies forward"
        case .reorganizePlan: return "Optimize your schedule"
        }
    }
}

/// Sheet for AI-powered automatic scheduling of movies.
struct AutoSchedulerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchPlanViewModel

    @State private var userPrompt: String = ""
    @State private var suggestedSchedule: [(movie: Movie, date: Date, reason: String?)] = []
    @State private var isGenerating = false
    @State private var isScheduling = false
    @State private var showPreview = false
    @FocusState private var isPromptFocused: Bool

    /// Get unwatched movies that aren't already in the plan
    private var availableMovies: [Movie] {
        let plannedMovieIds = Set(viewModel.watchPlanItems.map { $0.movieId })
        return viewModel.movies.filter { movie in
            !viewModel.watchedMovieIds.contains(movie.id) && !plannedMovieIds.contains(movie.id)
        }.sorted { ($0.runtimeMinutes ?? 0) < ($1.runtimeMinutes ?? 0) }
    }

    /// Check if there are overdue items
    private var hasOverdueItems: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return viewModel.watchPlanItems.contains { item in
            if let date = parseDate(item.plannedDate) {
                return calendar.startOfDay(for: date) < today
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showPreview {
                    previewSection
                } else {
                    promptSection
                }
            }
            .background(Color.appBackground)
            .navigationTitle(showPreview ? "AI Schedule Preview" : "AI Scheduler")
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

    // MARK: - Prompt Section

    private var promptSection: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Header
                aiHeader

                // Text Input
                promptInput

                // Quick Actions
                quickActionsSection

                // Stats Summary
                statsSummary
            }
            .padding()
        }
    }

    private var aiHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.goldPrimary, Color.goldLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("AI-Powered Scheduler")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Tell me how you'd like to organize your movie watching")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var promptInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like me to do?")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $userPrompt)
                    .focused($isPromptFocused)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPromptFocused ? Color.goldPrimary : Color.borderColor, lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)

                if userPrompt.isEmpty {
                    Text("e.g., 'Plan my weekends', 'I missed yesterday, fix it', 'Schedule short movies first'")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }

            // Generate button
            Button {
                Task {
                    await generateWithPrompt(userPrompt)
                }
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate Plan")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
                        ? Color.cardBackground
                        : Color.goldPrimary
                )
                .foregroundStyle(
                    userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
                        ? Color.textMuted
                        : .black
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
            .accessibilityLabel("Generate plan")
            .accessibilityHint(userPrompt.isEmpty ? "Enter a prompt first" : "Creates a suggested schedule based on your request")
        }
        .glassCard()
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headingSmall)
                .foregroundStyle(Color.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuickAction.allCases) { action in
                    quickActionButton(action)
                }
            }
        }
    }

    private func quickActionButton(_ action: QuickAction) -> some View {
        Button {
            Task {
                await generateWithPrompt(action.prompt)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldPrimary)

                Text(action.rawValue)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)

                Text(action.description)
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.5 : 1)
        .accessibilityLabel(action.rawValue)
        .accessibilityHint(action.description)
    }

    private var statsSummary: some View {
        HStack(spacing: 16) {
            statItem(
                value: "\(availableMovies.count)",
                label: "Unwatched",
                icon: "film"
            )

            statItem(
                value: "\(viewModel.watchPlanItems.count)",
                label: "Scheduled",
                icon: "calendar"
            )

            if hasOverdueItems {
                statItem(
                    value: "\(overdueCount)",
                    label: "Overdue",
                    icon: "exclamationmark.triangle",
                    isWarning: true
                )
            }
        }
        .padding()
        .glassCard()
    }

    private var overdueCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return viewModel.watchPlanItems.filter { item in
            if let date = parseDate(item.plannedDate) {
                return calendar.startOfDay(for: date) < today
            }
            return false
        }.count
    }

    private func statItem(value: String, label: String, icon: String, isWarning: Bool = false) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.headingMedium)
            }
            .foregroundStyle(isWarning ? Color.destructive : Color.goldPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeader

            Divider()
                .background(Color.borderColor)

            // Schedule preview list
            if suggestedSchedule.isEmpty {
                emptyPreviewState
            } else {
                schedulePreviewList
            }

            Spacer()

            // Confirm button
            if !suggestedSchedule.isEmpty {
                confirmButton
            }
        }
    }

    private var emptyPreviewState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)

            Text("No schedule generated")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Try a different prompt or check that you have movies available to schedule")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Suggested Schedule")
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
        return max(1, (Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1)
    }

    private var schedulePreviewList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(suggestedSchedule.enumerated()), id: \.element.movie.id) { index, item in
                    schedulePreviewRow(item.movie, date: item.date, reason: item.reason, index: index)
                }
            }
            .padding()
        }
    }

    private func schedulePreviewRow(_ movie: Movie, date: Date, reason: String?, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

                    if !movie.formattedRuntime.isEmpty {
                        Text(movie.formattedRuntime)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }

                Spacer()
            }

            // AI Reason
            if let reason = reason, !reason.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.goldPrimary)

                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                        .italic()
                }
                .padding(.leading, 62)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title) scheduled for \(formattedDate(date))\(reason != nil ? ", \(reason!)" : "")")
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

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

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

    // MARK: - AI Scheduling Logic

    /// Generate a schedule using the AI backend
    private func generateWithPrompt(_ prompt: String) async {
        isGenerating = true
        HapticManager.selection()

        // Call the AI auto-scheduler edge function
        if let schedule = await viewModel.callAutoScheduler(
            userPrompt: prompt,
            moviesPool: availableMovies,
            existingSchedule: viewModel.watchPlanItems
        ) {
            suggestedSchedule = schedule

            withAnimation(.easeInOut(duration: 0.3)) {
                showPreview = true
            }
        } else {
            HapticManager.error()
        }

        isGenerating = false
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
