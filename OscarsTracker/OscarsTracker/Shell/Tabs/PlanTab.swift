import SwiftUI

/// Watch plan (screens.md, 3.5): when you'll watch what, kept honest. On
/// compact widths an agenda by day, where films drag between days and swipe
/// to reschedule, mark watched or remove; on regular widths the calendar and
/// the selected day side by side in an arrangement (calendar above the day
/// when a Duo stands in tabletop pose). Past days' unwatched films collapse
/// into one "N to reschedule" bar at the top.
struct PlanTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("plan.hidesPast") private var hidesPast = true

    var body: some View {
        let plan = model.plan
        let overdue = plan.toReschedule(watchedIDs: model.films.watchedIDs)

        NavigationStack {
            LoadStateView(state: plan.state, isEmpty: plan.items.isEmpty && plan.state != .loaded) {
                if plan.items.isEmpty {
                    PlanEmpty()
                } else if sizeClass == .regular {
                    ArrangementView {
                        PlanCalendar()
                    } secondary: {
                        PlanSelectedDay()
                    }
                    .arrangementViewStyle(.split)
                } else {
                    PlanAgenda(hidesPast: hidesPast)
                }
            } placeholder: {
                PlanAgenda(hidesPast: true, isPlaceholder: true)
            }
            .tabChrome("Watch plan", posters: posters)
            .safeAreaBar(edge: .top) {
                if !overdue.isEmpty {
                    RescheduleBar(count: overdue.count) {
                        Task { await plan.rescheduleAll(overdue) }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("What can I watch?", systemImage: "clock") { model.navigation.sheet = .whatCanIWatch }
                    Button("Fill my plan", systemImage: "wand.and.sparkles") { model.navigation.sheet = .fillPlan }
                }
                .visibilityPriority(.high)
                ToolbarOverflowMenu {
                    Toggle("Hide past days", systemImage: "calendar.badge.minus", isOn: $hidesPast)
                }
                .visibilityPriority(.low)
            }
            .alert("Couldn't save your plan", isPresented: Binding { plan.actionError != nil } set: { if !$0 { plan.actionError = nil } }) {
                Button("OK") {}
            } message: {
                Text(plan.actionError?.message ?? "")
            }
        }
    }

    /// The ambient light comes from the films planned next.
    private var posters: [String] {
        model.plan.upcomingDays().flatMap(\.items).compactMap { model.plan.movie(for: $0, in: model.films.movies)?.posterUrl }
    }
}

/// "4 films to reschedule. · Move all to this week", pinned under the title.
private struct RescheduleBar: View {
    @Environment(\.copy) private var copy
    let count: Int
    var moveAll: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.s) {
                label
                Spacer(minLength: 0)
                button
            }
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                label
                button
            }
        }
        .padding(.horizontal, Theme.Space.m)
        .padding(.bottom, Theme.Space.xs)
    }

    private var label: some View {
        Label(copy.planReschedule(count), systemImage: "calendar.badge.clock")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.ink)
    }

    private var button: some View {
        Button("Move all to this week", action: moveAll)
            .buttonStyle(.glass)
            .controlSize(.small)
    }
}

/// No films planned at all.
private struct PlanEmpty: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    var body: some View {
        ContentUnavailableView {
            Label(copy.planEmpty.title, systemImage: "calendar")
        } description: {
            Text(copy.planEmpty.body)
        } actions: {
            Button { model.navigation.sheet = .addToDay(.today()) } label: {
                Label("Add a film", systemImage: "plus").foregroundStyle(.ground)
            }
            .buttonStyle(.glassProminent)
            Button("Fill my plan", systemImage: "wand.and.sparkles") { model.navigation.sheet = .fillPlan }
                .buttonStyle(.glass)
        }
    }
}

/// Today and the week ahead, every day shown, then later days with films.
/// Films drag between days (`reorderContainer`, each day a collection) and
/// swipe for Reschedule, Watched and Remove.
private struct PlanAgenda: View {
    @Environment(AppModel.self) private var model
    let hidesPast: Bool
    var isPlaceholder = false
    /// Kept across a fold or unfold, so the agenda stays where it was.
    @State private var scrolledDay: PlanDay?

    var body: some View {
        let plan = model.plan
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Space.l) {
                if isPlaceholder {
                    ForEach(0..<3, id: \.self) { offset in
                        PlanDaySection(day: PlanStore.Day(day: .today().adding(days: offset), items: []))
                    }
                } else {
                    if !hidesPast {
                        ForEach(plan.pastDays()) { day in
                            PlanDaySection(day: day, isPast: true)
                        }
                    }
                    ForEach(plan.agenda()) { day in
                        PlanDaySection(day: day)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, Theme.Space.m)
            .padding(.bottom, Theme.Space.xxl)
        }
        .scrollPosition(id: $scrolledDay, anchor: .top)
        .reorderContainer(for: WatchPlanItem.self, in: PlanDay.self) { difference in
            Task { await plan.move(difference.sources, to: difference.destination.collectionID) }
        }
        .swipeActionsContainer()
        .onAppear {
            if scrolledDay == nil, let day = model.navigation.selectedDay, day > .today() { scrolledDay = day }
        }
        .onChange(of: scrolledDay) { _, day in
            if let day { model.navigation.selectedDay = day }
        }
    }
}

/// A day: its name and total runtime, an add button, and its films (or
/// "Nothing planned").
struct PlanDaySection: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let day: PlanStore.Day
    var isPast = false

    var body: some View {
        let movies = day.items.compactMap { model.plan.movie(for: $0, in: model.films.movies) }
        let runtime = movies.compactMap(\.runtimeMinutes).reduce(0, +)
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Text(day.day.label)
                    .font(.headline)
                    .foregroundStyle(isPast ? .inkMuted : .ink)
                    .accessibilityAddTraits(.isHeader)
                if runtime > 0 {
                    Text(Runtime.format(minutes: runtime))
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.inkMuted)
                        .accessibilityLabel("\(Runtime.format(minutes: runtime)) planned")
                }
                Spacer(minLength: 0)
                if !isPast {
                    Button("Add a film to \(day.day.label)", systemImage: "plus") {
                        model.navigation.sheet = .addToDay(day.day)
                    }
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                if day.items.isEmpty {
                    Text(copy.planNothing)
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                        .padding(Theme.Space.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(day.items) { item in
                    if let movie = model.plan.movie(for: item, in: model.films.movies) {
                        PlanRow(item: item, movie: movie, day: day.day)
                        if item.id != day.items.last?.id {
                            Divider().padding(.leading, Theme.Space.m + 44 + Theme.Space.s)
                        }
                    }
                }
                .reorderable(collectionID: day.day)
            }
            .solidSurface(radius: Theme.Radius.row)
        }
        .id(day.day)
    }
}

/// A planned film: thumbnail, title and runtime, and the watched toggle
/// (a gold check once watched). Swipe or long-press for the rest.
private struct PlanRow: View {
    @Environment(AppModel.self) private var model
    let item: WatchPlanItem
    let movie: Movie
    let day: PlanDay

    var body: some View {
        let plan = model.plan
        let tomorrow = PlanDay.today().adding(days: 1)
        FilmListRow(movie: movie) { model.navigation.sheet = .movie(movie.id) }
            .padding(.horizontal, Theme.Space.m)
            .padding(.vertical, Theme.Space.xs)
            .contentShape(.rect)
            .swipeActions(edge: .trailing) {
                Button("Remove", systemImage: "trash", role: .destructive) { Task { await plan.remove(item.id) } }
                Button("Reschedule", systemImage: "calendar") { model.navigation.sheet = .reschedule(itemID: item.id) }
                    .tint(.inkMuted)
            }
            .swipeActions(edge: .leading) {
                Button(model.films.isWatched(movie.id) ? "Not watched" : "Watched", systemImage: "checkmark.circle") {
                    guard let userID = model.session.userID else { return }
                    Task { await model.films.toggleWatched(movie.id, userID: userID) }
                }
                .tint(.gold)
            }
            .contextMenu {
                if day != tomorrow {
                    Button("Move to tomorrow", systemImage: "sunrise") { Task { await plan.move(item.id, to: tomorrow) } }
                }
                Button("Reschedule", systemImage: "calendar") { model.navigation.sheet = .reschedule(itemID: item.id) }
                Button("Remove from plan", systemImage: "trash", role: .destructive) { Task { await plan.remove(item.id) } }
            }
            .accessibilityAction(named: "Move to tomorrow") { Task { await plan.move(item.id, to: tomorrow) } }
            .accessibilityAction(named: "Reschedule") { model.navigation.sheet = .reschedule(itemID: item.id) }
            .accessibilityAction(named: "Remove from plan") { Task { await plan.remove(item.id) } }
    }
}

/// The calendar on regular widths; choosing a day shows it beside.
private struct PlanCalendar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let selection = Binding<Date> {
            (model.navigation.selectedDay ?? .today()).startDate()
        } set: {
            model.navigation.selectedDay = PlanDay($0)
        }
        ScrollView {
            DatePicker("Day", selection: selection, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(Theme.Space.m)
                .solidSurface()
                .padding(Theme.Space.m)
        }
    }
}

/// The selected day on regular widths.
private struct PlanSelectedDay: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let day = model.navigation.selectedDay ?? .today()
        ScrollView {
            PlanDaySection(day: PlanStore.Day(day: day, items: model.plan.items(on: day)), isPast: day < .today())
                .padding(Theme.Space.m)
        }
        .reorderContainer(for: WatchPlanItem.self, in: PlanDay.self) { difference in
            Task { await model.plan.move(difference.sources, to: difference.destination.collectionID) }
        }
        .swipeActionsContainer()
    }
}

extension PlanDay {
    /// "Tonight", "Tomorrow", then "Thu, Feb 12".
    var label: String {
        let today = PlanDay.today()
        if self == today { return "Tonight" }
        if self == today.adding(days: 1) { return "Tomorrow" }
        return startDate().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

extension PlanStore {
    /// The item's film: from the plan's own join, or the films already loaded.
    func movie(for item: WatchPlanItem, in movies: [Movie]) -> Movie? {
        item.movie ?? movies.first { $0.id == item.movieId }
    }
}

#Preview("Dark") {
    PlanTab().environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    PlanTab().environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    PlanTab().environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Empty") {
    PlanTab().environment(AppModel.preview { $0.planItems = [] }).preferredColorScheme(.dark)
}

#Preview("Loading") {
    PlanTab().environment(AppModel(data: SampleDataSource())).preferredColorScheme(.dark)
}
