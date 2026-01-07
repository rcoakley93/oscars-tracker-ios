import SwiftUI

/// Watch plan view showing movies grouped by planned date.
struct WatchPlanView: View {
    @StateObject private var viewModel = WatchPlanViewModel()
    @State private var showAddSheet = false
    @State private var itemToReschedule: WatchPlanItem?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats card
                        statsCard
                            .padding(.horizontal)

                        // Date grouped list
                        if viewModel.isLoading && viewModel.watchPlanItems.isEmpty {
                            loadingView
                        } else if viewModel.watchPlanItems.isEmpty {
                            emptyStateView
                        } else {
                            dateGroupedList
                        }
                    }
                    .padding(.vertical)
                    // Extra padding at bottom for FAB
                    .padding(.bottom, 80)
                }
                .background(Color.appBackground)

                // Floating Action Button
                floatingAddButton
            }
            .navigationTitle("Watch Plan")
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showAddSheet) {
                AddToPlanSheet(viewModel: viewModel)
                    .presentationDetents([.large])
            }
            .sheet(item: $itemToReschedule) { item in
                RescheduleSheet(
                    item: item,
                    movie: viewModel.movie(for: item),
                    viewModel: viewModel,
                    onDismiss: { itemToReschedule = nil }
                )
                .presentationDetents([.medium])
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Floating Action Button

    private var floatingAddButton: some View {
        Button {
            showAddSheet = true
            HapticManager.selection()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(Color.goldPrimary)
                .clipShape(Circle())
                .shadow(color: Color.goldPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add movie to plan")
        .accessibilityHint("Opens a sheet to add a movie to your watch plan")
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: viewModel.plannedCount, label: "planned")
            Divider()
                .frame(height: 40)
                .background(Color.borderColor)
            statItem(value: viewModel.unplannedCount, label: "unplanned")
            Divider()
                .frame(height: 40)
                .background(Color.borderColor)
            statItem(value: viewModel.watchedCount, label: "watched")
        }
        .glassCard()
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headingLarge)
                .foregroundStyle(Color.goldPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Date Grouped List

    private var dateGroupedList: some View {
        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.groupedItems, id: \.date) { group in
                Section {
                    VStack(spacing: 12) {
                        ForEach(group.items) { item in
                            WatchPlanRowView(
                                item: item,
                                movie: viewModel.movie(for: item),
                                onReschedule: {
                                    itemToReschedule = item
                                    HapticManager.selection()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                } header: {
                    dateHeader(label: group.label, isOverdue: group.label == "OVERDUE")
                }
            }
        }
    }

    private func dateHeader(label: String, isOverdue: Bool) -> some View {
        HStack {
            Text(label)
                .font(.headingSmall)
                .foregroundStyle(isOverdue ? Color.destructive : Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading watch plan...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("No movies planned")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Add movies to your watch plan to track when to watch them")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Row view for a single watch plan item.
struct WatchPlanRowView: View {
    let item: WatchPlanItem
    let movie: Movie?
    var onReschedule: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Poster placeholder
            posterView

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie?.title ?? "Unknown Movie")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let runtime = movie?.formattedRuntime, !runtime.isEmpty {
                        Text(runtime)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                    if let year = movie?.releaseYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }

                if item.isMissed {
                    missedBadge
                }
            }

            Spacer()

            // Move button
            if let onReschedule = onReschedule {
                Button {
                    onReschedule()
                } label: {
                    Label("Move", systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.goldPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.goldPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Move \(movie?.title ?? "movie") to different date")
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie?.title ?? "Unknown Movie"), \(item.isMissed ? "missed" : "planned")")
        .accessibilityHint("Double tap to reschedule")
    }

    private var posterView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cardBackground)
            .frame(width: 60, height: 90)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textMuted)
            )
    }

    private var missedBadge: some View {
        Text("MISSED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.destructive)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Sheet for rescheduling a watch plan item.
struct RescheduleSheet: View {
    let item: WatchPlanItem
    let movie: Movie?
    @ObservedObject var viewModel: WatchPlanViewModel
    let onDismiss: () -> Void

    @State private var selectedDate: Date
    @State private var isRescheduling = false

    init(item: WatchPlanItem, movie: Movie?, viewModel: WatchPlanViewModel, onDismiss: @escaping () -> Void) {
        self.item = item
        self.movie = movie
        self.viewModel = viewModel
        self.onDismiss = onDismiss

        // Parse current date or use today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.date(from: item.plannedDate) ?? Date()
        _selectedDate = State(initialValue: currentDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Movie info header
                movieHeader

                // Date picker
                DatePicker(
                    "New date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.goldPrimary)
                .labelsHidden()

                Spacer()

                // Reschedule button
                rescheduleButton
            }
            .padding()
            .background(Color.appBackground)
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    private var movieHeader: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
                .frame(width: 50, height: 75)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textMuted)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(movie?.title ?? "Unknown Movie")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                if let runtime = movie?.formattedRuntime, !runtime.isEmpty {
                    Text(runtime)
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rescheduleButton: some View {
        Button {
            Task {
                await rescheduleItem()
            }
        } label: {
            HStack {
                if isRescheduling {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Move to Date")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.goldPrimary)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isRescheduling)
        .accessibilityLabel("Move movie to selected date")
    }

    private func rescheduleItem() async {
        isRescheduling = true

        let success = await viewModel.reschedule(itemId: item.id, to: selectedDate)

        isRescheduling = false

        if success {
            HapticManager.success()
            onDismiss()
        } else {
            HapticManager.error()
        }
    }
}

#Preview {
    WatchPlanView()
        .preferredColorScheme(.dark)
}
