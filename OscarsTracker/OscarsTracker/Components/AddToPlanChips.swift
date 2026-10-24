import SwiftUI

/// Tonight, Tomorrow and Pick a date, as glass chips that morph into one
/// "Planned for Tuesday · Undo" capsule for three seconds (screens.md,
/// section 2). The movie sheet's one custom glass; bordered buttons under
/// Reduce Transparency or Increase Contrast.
struct AddToPlanChips: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let movie: Movie

    @Namespace private var glass
    @State private var planned: PlanDay?
    @State private var choosingDate = false
    @State private var date = Date.now

    var body: some View {
        Group {
            if reduceTransparency || contrast == .increased {
                chips.buttonStyle(.bordered)
            } else {
                GlassEffectContainer(spacing: Theme.Space.xs) {
                    chips.buttonStyle(.glass)
                }
            }
        }
        .sheet(isPresented: $choosingDate) {
            NavigationStack {
                DatePicker("Day", selection: $date, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("Pick a date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .confirmationAction) {
                            Button("Add", systemImage: "plus") {
                                choosingDate = false
                                plan(on: PlanDay(date))
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var chips: some View {
        HStack(spacing: Theme.Space.xs) {
            if let planned {
                Button {
                    undo(planned)
                } label: {
                    Text("Planned for \(planned.startDate(), format: .dateTime.weekday(.wide)) · Undo")
                        .frame(maxWidth: .infinity)
                }
                .glassEffectID("confirm", in: glass)
                .accessibilityHint("Removes it from your plan")
            } else {
                Button("Tonight") { plan(on: .today()) }
                    .glassEffectID("tonight", in: glass)
                Button("Tomorrow") { plan(on: PlanDay.today().adding(days: 1)) }
                    .glassEffectID("tomorrow", in: glass)
                Button("Pick a date", systemImage: "calendar") { choosingDate = true }
                    .glassEffectID("pick", in: glass)
            }
        }
        .controlSize(.large)
    }

    private func plan(on day: PlanDay) {
        guard let userID = model.session.userID else { return }
        withAnimation(.smooth) { planned = day }
        Task {
            await model.plan.add(movieID: movie.id, on: day, userID: userID)
            try? await Task.sleep(for: .seconds(3))
            if planned == day { withAnimation(.smooth) { planned = nil } }
        }
    }

    private func undo(_ day: PlanDay) {
        withAnimation(.smooth) { planned = nil }
        guard let item = model.plan.items(on: day).last(where: { $0.movieId == movie.id }) else { return }
        Task { await model.plan.remove(item.id) }
    }
}
