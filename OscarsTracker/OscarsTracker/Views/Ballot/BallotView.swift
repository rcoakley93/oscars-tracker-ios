import SwiftUI
import Kingfisher

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
                        ballotProgressCard
                        countdownTimer
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

    // MARK: - Progress Card

    private var ballotProgressCard: some View {
        BallotProgressCard(
            predictedCount: viewModel.predictedCategories,
            totalCategories: viewModel.totalCategories
        )
    }

    // MARK: - Countdown Timer

    private var countdownTimer: some View {
        CountdownTimerView(
            lockDate: viewModel.ballotLockDate,
            isLocked: viewModel.isLocked,
            onLock: {
                viewModel.checkLockStatus()
            }
        )
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

/// Progress card showing ballot completion progress.
struct BallotProgressCard: View {
    let predictedCount: Int
    let totalCategories: Int

    private var progress: Double {
        guard totalCategories > 0 else { return 0 }
        return Double(predictedCount) / Double(totalCategories)
    }

    private var percentageString: String {
        let percent = progress * 100
        return String(format: "%.0f%%", percent)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldPrimary)

                Text("Ballot Progress")
                    .font(.headingMedium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text(percentageString)
                    .font(.displaySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.goldPrimary)
            }

            // Progress bar
            BallotProgressBar(progress: progress)
                .frame(height: 8)

            // Count text
            Text("\(predictedCount) of \(totalCategories) categories predicted")
                .font(.bodySmall)
                .foregroundStyle(Color.textMuted)
        }
        .padding()
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ballot progress: \(predictedCount) of \(totalCategories) categories predicted, \(percentageString) complete")
    }
}

/// Gold gradient progress bar for ballot.
struct BallotProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.borderColor)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient.gold)
                    .frame(width: max(0, geometry.size.width * progress))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

/// Countdown timer view showing time until ballot locks.
struct CountdownTimerView: View {
    let lockDate: Date
    let isLocked: Bool
    let onLock: () -> Void

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    private var days: Int {
        Int(timeRemaining) / 86400
    }

    private var hours: Int {
        (Int(timeRemaining) % 86400) / 3600
    }

    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }

    private var seconds: Int {
        Int(timeRemaining) % 60
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "clock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(isLocked ? Color.destructiveLight : Color.goldPrimary)

                Text(isLocked ? "Ballot Locked" : "Time Remaining")
                    .font(.headingSmall)
                    .foregroundStyle(Color.textPrimary)

                Spacer()
            }

            if isLocked {
                // Locked state
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.destructiveLight)

                    Text("Predictions are now locked")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
            } else {
                // Countdown display
                HStack(spacing: 16) {
                    TimeUnitView(value: days, unit: "DAYS")
                    TimeUnitView(value: hours, unit: "HRS")
                    TimeUnitView(value: minutes, unit: "MIN")
                    TimeUnitView(value: seconds, unit: "SEC")
                }
            }
        }
        .padding()
        .glassCard()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? "Ballot is locked, predictions cannot be changed" : "Time remaining: \(days) days, \(hours) hours, \(minutes) minutes, \(seconds) seconds")
    }

    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeRemaining() {
        let remaining = lockDate.timeIntervalSince(Date())
        if remaining <= 0 {
            timeRemaining = 0
            onLock()
            stopTimer()
        } else {
            timeRemaining = remaining
        }
    }
}

/// Individual time unit display.
struct TimeUnitView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.goldPrimary)

            Text(unit)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textMuted)
        }
        .frame(minWidth: 50)
    }
}

/// Expandable card showing a category and its nominations.
struct CategoryCard: View {
    let category: CategoryWithNominations
    @ObservedObject var viewModel: BallotViewModel
    @State private var isExpanded = false

    private var hasWinner: Bool {
        viewModel.hasWinner(for: category)
    }

    private var isPredictionCorrect: Bool {
        viewModel.isPredictionCorrect(for: category)
    }

    private var isPredictionIncorrect: Bool {
        viewModel.isPredictionIncorrect(for: category)
    }

    private var pointsEarned: Int {
        viewModel.pointsEarned(for: category)
    }

    /// Check if this is an actor/performer category
    private var isActorCategory: Bool {
        let actorKeywords = ["actor", "actress"]
        let lowercaseName = category.name.lowercased()
        return actorKeywords.contains { lowercaseName.contains($0) }
    }

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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    hasWinner ? (isPredictionCorrect ? Color.success : (isPredictionIncorrect ? Color.destructive.opacity(0.5) : Color.clear)) : Color.clear,
                    lineWidth: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(category.pointsValue ?? 0) points, \(isExpanded ? "expanded" : "collapsed")\(hasWinner ? ", winner announced" : "")")
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
                    HStack(spacing: 8) {
                        Text(category.name)
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.leading)

                        // Prediction result indicator
                        if hasWinner {
                            if isPredictionCorrect {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.success)
                            } else if isPredictionIncorrect {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.destructiveLight)
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        // Points - show earned if winner, otherwise potential
                        if hasWinner {
                            Text("+\(pointsEarned) pts")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(isPredictionCorrect ? Color.success : Color.textMuted)
                        } else {
                            Text("\(category.pointsValue ?? 0) pts")
                                .font(.caption)
                                .foregroundStyle(Color.goldLight)
                        }

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
                        isActorCategory: isActorCategory,
                        isSelected: viewModel.isSelected(nomination: nomination),
                        isWinner: nomination.isWinner == true,
                        isUserCorrect: viewModel.isSelected(nomination: nomination) && nomination.isWinner == true,
                        isUserIncorrect: viewModel.isSelected(nomination: nomination) && viewModel.hasWinner(for: category) && nomination.isWinner != true,
                        isLocked: viewModel.isLocked,
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
/// For actor categories, displays actor name as primary and movie title as secondary.
struct NominationRow: View {
    let nomination: Nomination
    let movie: Movie?
    let isActorCategory: Bool
    let isSelected: Bool
    let isWinner: Bool
    let isUserCorrect: Bool
    let isUserIncorrect: Bool
    let isLocked: Bool
    let onSelect: () -> Void

    /// Background color based on prediction result
    private var backgroundColor: Color {
        if isUserCorrect {
            return Color.success.opacity(0.15)
        } else if isUserIncorrect {
            return Color.destructive.opacity(0.1)
        } else if isWinner {
            return Color.goldPrimary.opacity(0.1)
        } else if isSelected {
            return Color.goldPrimary.opacity(0.1)
        }
        return Color.clear
    }

    /// Border color based on prediction result
    private var borderColor: Color {
        if isUserCorrect {
            return Color.success.opacity(0.5)
        } else if isUserIncorrect {
            return Color.destructive.opacity(0.3)
        } else if isWinner {
            return Color.goldPrimary.opacity(0.5)
        } else if isSelected {
            return Color.goldPrimary.opacity(0.3)
        }
        return Color.clear
    }

    /// Text color for movie title
    private var titleColor: Color {
        if isUserCorrect {
            return Color.success
        } else if isUserIncorrect {
            return Color.destructiveLight
        } else if isWinner {
            return Color.goldPrimary
        } else if isSelected {
            return Color.goldPrimary
        }
        return Color.textPrimary
    }

    /// Primary headline text - actor name for actor categories, movie title otherwise
    private var primaryText: String {
        if isActorCategory, let actorName = nomination.detailText, !actorName.isEmpty {
            return actorName
        }
        return movie?.title ?? "Unknown Movie"
    }

    /// Secondary text - movie title for actor categories, detail text otherwise
    private var secondaryText: String? {
        if isActorCategory, let actorName = nomination.detailText, !actorName.isEmpty {
            // For actor categories, show movie title as secondary
            return movie?.title
        }
        // For non-actor categories, show detail text if available
        if let detailText = nomination.detailText, !detailText.isEmpty {
            return detailText
        }
        return nil
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio button indicator (or result indicator)
                ZStack {
                    if isUserCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.success)
                    } else if isUserIncorrect {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.destructiveLight)
                    } else {
                        Circle()
                            .stroke(isSelected ? Color.goldPrimary : Color.borderColor, lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(Color.goldPrimary)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                // Movie poster with Kingfisher image loading
                posterView

                VStack(alignment: .leading, spacing: 2) {
                    // Primary text: actor name for actor categories, movie title otherwise
                    Text(primaryText)
                        .font(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundStyle(titleColor)
                        .lineLimit(2)

                    // Secondary text: movie title for actor categories, detail text otherwise
                    if let secondary = secondaryText {
                        Text(secondary)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Winner badge (shown prominently)
                if isWinner {
                    WinnerBadge()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isWinner ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? (isWinner ? 1.0 : 0.6) : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isLocked ? "Ballot is locked, selections cannot be changed" : "Double tap to \(isSelected ? "deselect" : "select") this prediction")
    }

    private var accessibilityLabelText: String {
        let statusText = "\(isSelected ? "selected" : "not selected")\(isWinner ? ", winner" : "")\(isUserCorrect ? ", correct prediction" : "")\(isUserIncorrect ? ", incorrect prediction" : "")"
        if isActorCategory, let actorName = nomination.detailText, !actorName.isEmpty {
            return "\(actorName) in \(movie?.title ?? "Unknown Movie"), \(statusText)"
        }
        return "\(movie?.title ?? "Unknown Movie"), \(nomination.detailText ?? ""), \(statusText)"
    }

    // MARK: - Poster View

    /// Poster image with Kingfisher loading and fallback placeholder
    private var posterView: some View {
        SwiftUI.Group {
            if let posterUrl = movie?.posterUrl, let url = URL(string: posterUrl) {
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
        .frame(width: 40, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.goldPrimary.opacity(0.5) : Color.borderColor.opacity(0.3), lineWidth: 1)
        )
    }

    /// Fallback placeholder when poster URL is nil or image fails to load
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.cardBackground)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textMuted)
            )
    }
}

/// Badge showing winner status with trophy icon.
struct WinnerBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 12))
            Text("WINNER")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(Color.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.goldPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    BallotView()
        .preferredColorScheme(.dark)
}
