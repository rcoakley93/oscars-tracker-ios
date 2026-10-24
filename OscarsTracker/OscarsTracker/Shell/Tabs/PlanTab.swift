import SwiftUI

/// Plan: the agenda on compact widths; on regular widths the calendar and the
/// selected day side by side in an arrangement (calendar above the day when a
/// Duo stands in tabletop pose). P4-04 builds the real screen.
struct PlanTab: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let plan = model.plan
        let overdue = plan.toReschedule(watchedIDs: model.films.watchedIDs)

        NavigationStack {
            LoadStateView(state: plan.state, isEmpty: plan.items.isEmpty,
                          empty: ContentUnavailableView("No films planned yet", systemImage: "calendar", description: Text("Add films to your plan from the Films tab."))) {
                if sizeClass == .regular {
                    ArrangementView {
                        PlanCalendar()
                    } secondary: {
                        PlanDayList()
                    }
                    .arrangementViewStyle(.split)
                } else {
                    PlanAgenda()
                }
            }
            .tabChrome("Watch plan")
            .safeAreaBar(edge: .top) {
                if !overdue.isEmpty {
                    Button("\(overdue.count) to reschedule · Move all to this week", systemImage: "calendar.badge.clock") {
                        Task { await plan.rescheduleAll(overdue) }
                    }
                    .buttonStyle(.glass)
                    .padding(.bottom, Theme.Space.xs)
                }
            }
        }
    }
}

/// Today and later, day by day. Opens at the day selected in the calendar,
/// so unfolding and folding a Duo comes back to the same place.
private struct PlanAgenda: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(model.plan.upcomingDays()) { day in
                    Section {
                        ForEach(day.items) { item in
                            Text(item.movie?.title ?? "Film \(item.movieId)")
                        }
                    } header: {
                        Text(day.day.startDate().formatted(.dateTime.weekday(.wide).month().day()))
                            .accessibilityAddTraits(.isHeader)
                    }
                    .id(day.day)
                }
            }
            .onAppear {
                if let day = model.navigation.selectedDay { proxy.scrollTo(day, anchor: .top) }
            }
        }
    }
}

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
        }
    }
}

private struct PlanDayList: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let day = model.navigation.selectedDay ?? .today()
        let items = model.plan.items(on: day)
        List {
            Section {
                if items.isEmpty {
                    Text("Nothing planned").foregroundStyle(.inkMuted)
                }
                ForEach(items) { item in
                    Text(item.movie?.title ?? "Film \(item.movieId)")
                }
            } header: {
                Text(day.startDate().formatted(.dateTime.weekday(.wide).month().day()))
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .scrollContentBackground(.hidden)
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
