import SwiftUI
import UniformTypeIdentifiers

/// Watch plan view showing movies grouped by planned date.
struct WatchPlanView: View {
    @StateObject private var viewModel = WatchPlanViewModel()
    @State private var showAddSheet = false
    @State private var showAutoSchedulerSheet = false
    @State private var showWhatCanIWatchSheet = false
    @State private var itemToReschedule: WatchPlanItem?
    @State private var itemToRemove: WatchPlanItem?
    @State private var showRemoveConfirmation = false
    @State private var draggedItem: WatchPlanItem?
    @State private var highlightedDateGroup: Date?

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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        Button {
                            showWhatCanIWatchSheet = true
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.goldPrimary)
                        }
                        .accessibilityLabel("What Can I Watch")
                        .accessibilityHint("Find movies based on available time")

                        Button {
                            showAutoSchedulerSheet = true
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.goldPrimary)
                        }
                        .accessibilityLabel("Auto Scheduler")
                        .accessibilityHint("Opens auto scheduler to automatically plan movies")
                    }
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showAddSheet) {
                AddToPlanSheet(viewModel: viewModel)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showAutoSchedulerSheet) {
                AutoSchedulerSheet(viewModel: viewModel)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showWhatCanIWatchSheet) {
                WhatCanIWatchSheet(viewModel: viewModel)
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
            .alert("Remove from Plan", isPresented: $showRemoveConfirmation, presenting: itemToRemove) { item in
                Button("Cancel", role: .cancel) {
                    itemToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    Task {
                        await removeFromPlan(item)
                    }
                }
            } message: { item in
                Text("Are you sure you want to remove \"\(viewModel.movie(for: item)?.title ?? "this movie")\" from your watch plan?")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    private func markAsWatched(_ item: WatchPlanItem) async {
        let success = await viewModel.markWatchedAndRemove(itemId: item.id, movieId: item.movieId)
        if success {
            HapticManager.success()
        } else {
            HapticManager.error()
        }
    }

    private func removeFromPlan(_ item: WatchPlanItem) async {
        let success = await viewModel.removeFromPlan(itemId: item.id)
        if success {
            HapticManager.success()
        } else {
            HapticManager.error()
        }
        itemToRemove = nil
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
                            DraggableWatchPlanRow(
                                item: item,
                                movie: viewModel.movie(for: item),
                                isDragging: draggedItem?.id == item.id,
                                onDragStart: {
                                    draggedItem = item
                                    HapticManager.medium()
                                },
                                onDragEnd: {
                                    draggedItem = nil
                                    highlightedDateGroup = nil
                                },
                                onReschedule: {
                                    itemToReschedule = item
                                    HapticManager.selection()
                                },
                                onMarkWatched: {
                                    Task {
                                        await markAsWatched(item)
                                    }
                                },
                                onRemove: {
                                    itemToRemove = item
                                    showRemoveConfirmation = true
                                    HapticManager.selection()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .dropDestination(for: WatchPlanItemTransfer.self) { items, _ in
                        guard let droppedItem = items.first,
                              group.label != "OVERDUE" else { return false }

                        Task {
                            let success = await viewModel.reschedule(itemId: droppedItem.itemId, to: group.date)
                            if success {
                                HapticManager.success()
                            } else {
                                HapticManager.error()
                            }
                        }
                        return true
                    } isTargeted: { isTargeted in
                        if group.label != "OVERDUE" {
                            highlightedDateGroup = isTargeted ? group.date : nil
                        }
                    }
                } header: {
                    dateHeader(
                        label: group.label,
                        isOverdue: group.label == "OVERDUE",
                        isHighlighted: highlightedDateGroup == group.date
                    )
                }
            }
        }
    }

    private func dateHeader(label: String, isOverdue: Bool, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.headingSmall)
                .foregroundStyle(isOverdue ? Color.destructive : (isHighlighted ? Color.goldPrimary : Color.textPrimary))
            Spacer()
            if isHighlighted {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Color.goldPrimary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isHighlighted ? Color.goldPrimary.opacity(0.1) : Color.appBackground)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
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

/// Transferable data for drag and drop of watch plan items.
struct WatchPlanItemTransfer: Codable, Transferable {
    let itemId: Int
    let movieId: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .watchPlanItem)
    }
}

extension UTType {
    static var watchPlanItem: UTType {
        UTType(exportedAs: "com.oscars.tracker.watchplanitem")
    }
}

/// Draggable wrapper for watch plan row with visual feedback.
struct DraggableWatchPlanRow: View {
    let item: WatchPlanItem
    let movie: Movie?
    let isDragging: Bool
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?
    var onReschedule: (() -> Void)?
    var onMarkWatched: (() -> Void)?
    var onRemove: (() -> Void)?

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        WatchPlanRowView(
            item: item,
            movie: movie,
            onReschedule: onReschedule,
            onMarkWatched: onMarkWatched,
            onRemove: onRemove
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .rotationEffect(.degrees(isDragging ? 2 : 0))
        .shadow(color: isDragging ? Color.goldPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .draggable(WatchPlanItemTransfer(itemId: item.id, movieId: item.movieId)) {
            // Drag preview
            WatchPlanDragPreview(movie: movie)
                .onAppear {
                    onDragStart?()
                }
        }
        .onDrop(of: [.watchPlanItem], isTargeted: nil) { _ in
            onDragEnd?()
            return false
        }
    }
}

/// Preview shown while dragging a watch plan item.
struct WatchPlanDragPreview: View {
    let movie: Movie?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "film")
                .foregroundStyle(Color.goldPrimary)
            Text(movie?.title ?? "Movie")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.goldPrimary, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

/// Row view for a single watch plan item.
struct WatchPlanRowView: View {
    let item: WatchPlanItem
    let movie: Movie?
    var onReschedule: (() -> Void)?
    var onMarkWatched: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
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

                // Drag handle indicator
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textMuted.opacity(0.5))

                // Remove button (X)
                if let onRemove = onRemove {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textMuted)
                            .frame(width: 28, height: 28)
                            .background(Color.cardBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(movie?.title ?? "movie") from plan")
                }
            }

            // Action buttons row
            HStack(spacing: 8) {
                // Watched button
                if let onMarkWatched = onMarkWatched {
                    Button {
                        onMarkWatched()
                    } label: {
                        Label("Watched", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.success)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark \(movie?.title ?? "movie") as watched")
                }

                // Move button
                if let onReschedule = onReschedule {
                    Button {
                        onReschedule()
                    } label: {
                        Label("Move", systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.goldPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.goldPrimary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Move \(movie?.title ?? "movie") to different date")
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie?.title ?? "Unknown Movie"), \(item.isMissed ? "missed" : "planned")")
        .accessibilityHint("Long press and drag to reschedule, or use action buttons")
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
