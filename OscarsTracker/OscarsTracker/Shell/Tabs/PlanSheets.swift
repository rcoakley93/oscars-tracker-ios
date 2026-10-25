import SwiftUI

// The watch plan's sheets (screens.md, 3.5), opened from `AppNavigation.sheet`.

/// Films you haven't watched or planned yet; choosing one plans it for `day`.
struct AddToDaySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let day: PlanDay
    @State private var query = ""

    var body: some View {
        let planned = model.plan.plannedMovieIDs()
        let films = PlanFiller.shortestFirst(model.films.toWatch.filter { !planned.contains($0.id) })
            .filter { query.isEmpty || $0.title.localizedStandardContains(query) }
        NavigationStack {
            List(films) { movie in
                Button {
                    guard let userID = model.session.userID else { return }
                    Task { await model.plan.add(movieID: movie.id, on: day, userID: userID) }
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Space.s) {
                        PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail).frame(width: 44)
                        VStack(alignment: .leading) {
                            Text(movie.title).foregroundStyle(.ink)
                            Text(verbatim: movie.facts).font(.subheadline).foregroundStyle(.inkMuted)
                            if let planned = model.plan.plannedDay(of: movie.id) {
                                // Already on another day (a past one, say): choosing it moves it here.
                                Text("Planned \(planned.label)").font(.footnote).foregroundStyle(.inkMuted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.surface)
            }
            .overlay {
                if films.isEmpty {
                    ContentUnavailableView(query.isEmpty ? "Every film is planned or watched" : "No matches",
                                           systemImage: "film")
                }
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $query, prompt: "Films")
            .navigationTitle("Add to \(day.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Moves one planned film to another day.
struct RescheduleSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let itemID: Int
    @State private var date = PlanDay.today().adding(days: 1).startDate()

    var body: some View {
        let item = model.plan.items.first { $0.id == itemID }
        let title = item.flatMap { model.plan.movie(for: $0, in: model.films.movies)?.title } ?? "Film"
        NavigationStack {
            DatePicker("Day", selection: $date, in: PlanDay.today().startDate()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(Theme.Space.m)
                .navigationTitle("Move \(title)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Move", systemImage: "checkmark") {
                            let day = PlanDay(date)
                            Task { await model.plan.move(itemID, to: day) }
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

/// "What can I watch?": how much time you have, then the unwatched films
/// that fit, longest first, each one tap from tonight's plan. The choices
/// come from `app_config.runtime_buckets`.
struct WhatCanIWatchSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int?

    var body: some View {
        let options = model.season.runtimeBuckets.map(\.minutes.upperBound)
        let chosen = minutes ?? options.last ?? 120
        let fits = PlanFiller.fits(model.films.toWatch, in: chosen)
        NavigationStack {
            List {
                Section {
                    Picker("Time you have", selection: Binding { chosen } set: { minutes = $0 }) {
                        ForEach(options, id: \.self) { Text(Runtime.format(minutes: $0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text(fits.first.map { copy.planFit($0.title, Runtime.format(minutes: $0.runtimeMinutes)) } ?? copy.planNoFit)
                        .font(.subheadline)
                        .foregroundStyle(.ink)
                        .padding(.top, Theme.Space.xs)
                }
                if !fits.isEmpty {
                    Section("Fits") {
                        ForEach(fits) { movie in
                            HStack(spacing: Theme.Space.s) {
                                PosterImage(movie: movie, radius: Theme.Radius.thumbnail, size: .thumbnail).frame(width: 44)
                                VStack(alignment: .leading) {
                                    Text(movie.title).foregroundStyle(.ink)
                                    Text(Runtime.format(minutes: movie.runtimeMinutes)).font(.subheadline).foregroundStyle(.inkMuted)
                                }
                                Spacer(minLength: Theme.Space.xs)
                                Button("Tonight") {
                                    guard let userID = model.session.userID else { return }
                                    Task { await model.plan.add(movieID: movie.id, on: .today(), userID: userID) }
                                    dismiss()
                                }
                                .buttonStyle(.glass)
                                .accessibilityLabel("Plan \(movie.title) for tonight")
                            }
                            .listRowBackground(Color.surface)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("What can I watch?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// "Fill my plan": spreads the unwatched, unplanned films over the days left
/// before the ceremony, shortest first, skipping the days you're busy.
/// Deterministic and local; it replaces the old AI auto-scheduler.
struct FillPlanSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss
    @AppStorage("plan.fill.perDay") private var perDay = 1
    /// Busy weekdays, "1,7" (1 = Sunday).
    @AppStorage("plan.fill.busy") private var busy = ""
    @State private var done: String?
    /// A save that failed, shown here because the Plan tab's alert sits behind this sheet.
    @State private var failure: String?
    @State private var isFilling = false

    var body: some View {
        let assignments = self.assignments
        let days = Set(assignments.map(\.day)).count
        NavigationStack {
            Form {
                Section {
                    Button {
                        guard let userID = model.session.userID else { return }
                        guard !isFilling else { return }
                        isFilling = true
                        Task {
                            defer { isFilling = false }
                            failure = nil
                            let added = await model.plan.fill(assignments, userID: userID)
                            if let error = model.plan.actionError {
                                failure = error.message
                                model.plan.actionError = nil
                            }
                            if added > 0 {
                                done = copy.planFillDone(added, Set(assignments.prefix(added).map(\.day)).count)
                            }
                        }
                    } label: {
                        Label("Fill my plan", systemImage: "wand.and.sparkles")
                            .foregroundStyle(.ground)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(assignments.isEmpty || done != nil || isFilling)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text(failure ?? done ?? (assignments.isEmpty ? copy.planFillNothing : summary(films: assignments.count, days: days)))
                        .font(.subheadline)
                        .foregroundStyle(.ink)
                        .padding(.top, Theme.Space.xs)
                }
                Section {
                    Stepper("\(perDay) \(perDay == 1 ? "film" : "films") a day", value: $perDay, in: 1...3)
                }
                Section("Skip these days") {
                    ForEach(Calendar.current.weekdayOrder, id: \.self) { weekday in
                        Toggle(Calendar.current.weekdaySymbols[weekday - 1], isOn: Binding {
                            busyDays.contains(weekday)
                        } set: { isBusy in
                            var days = busyDays
                            if isBusy { days.insert(weekday) } else { days.remove(weekday) }
                            busy = days.sorted().map(String.init).joined(separator: ",")
                        })
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Fill my plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button(done == nil ? "Cancel" : "Done", systemImage: done == nil ? "xmark" : "checkmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var busyDays: Set<Int> {
        Set(busy.split(separator: ",").compactMap { Int($0) })
    }

    /// From today to the day before the ceremony (30 days if it isn't known).
    private var assignments: [PlanFiller.Assignment] {
        let today = PlanDay.today()
        let last = model.season.ceremony.map { PlanDay($0.ceremonyAt).adding(days: -1) } ?? today.adding(days: 29)
        // Any film already on the plan is skipped, on a past day or a coming one.
        let planned = model.plan.allPlannedMovieIDs
        return PlanFiller.fill(
            films: model.films.toWatch.filter { !planned.contains($0.id) },
            from: today, through: last, perDay: perDay, busyWeekdays: busyDays,
            alreadyPlanned: model.plan.countsByDay(from: today))
    }

    /// "Plans 12 films over 9 days, until Mar 13."
    private func summary(films: Int, days: Int) -> String {
        let last = assignments.map(\.day).max().map { $0.startDate().formatted(.dateTime.month(.abbreviated).day()) } ?? ""
        return "Plans \(Copy.filmCount(films)) over \(Copy.days(days)), until \(last)."
    }
}

extension Calendar {
    /// Weekdays (1 = Sunday) in this calendar's order, Monday first where that's the custom.
    var weekdayOrder: [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }
}

#Preview("What can I watch?") {
    Color.ground.sheet(isPresented: .constant(true)) { WhatCanIWatchSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Fill my plan") {
    Color.ground.sheet(isPresented: .constant(true)) { FillPlanSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Add to a day") {
    Color.ground.sheet(isPresented: .constant(true)) { AddToDaySheet(day: .today()) }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}
