import SwiftUI

/// Admin (screens.md, 3.10; P6-01): ceremony night from the couch. The
/// categories in ceremony order, each a `Menu` of its nominees where one tap
/// marks the winner, with Undo in the top bar. The ceremony, its seed status
/// and "Send a push" below. 56 pt rows and no sheets, for one hand.
struct AdminView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var admin = model.admin
        List {
            if admin.categories.isEmpty, let error = admin.state.error {
                ContentUnavailableView {
                    Label("Couldn't load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    Button("Try again") { Task { await admin.load() } }
                }
            } else if admin.categories.isEmpty, admin.state == .loading || admin.state == .idle {
                Section { ForEach(BallotCategory.placeholders) { WinnerRow(category: $0) } }
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            } else if admin.categories.isEmpty {
                ContentUnavailableView("No categories yet", systemImage: "trophy",
                                       description: Text("Seed this ceremony's nominations first."))
            } else {
                Section {
                    ForEach(admin.categories) { WinnerRow(category: $0) }
                } header: {
                    Text("Winners · \(admin.decidedCount) of \(admin.categories.count)")
                }
            }

            if let ceremony = admin.ceremony {
                CeremonySection(ceremony: ceremony)
            }
            PushSection()
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .safeAreaBar(edge: .top) { UndoBar() }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await admin.load() }
        .task { await admin.load() }
        .errorAlert("Couldn't save that", error: $admin.actionError)
    }
}

/// The last change and its Undo, while there is one.
private struct UndoBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let admin = model.admin
        if let change = admin.lastChange, let category = admin.category(change.categoryID) {
            HStack(spacing: Theme.Space.s) {
                Text(line(change, in: category))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.ink)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Undo", systemImage: "arrow.uturn.backward") {
                    Task { await admin.undo() }
                }
                .buttonStyle(.glass)
                .disabled(admin.isPending(change.categoryID))
                .accessibilityHint("Puts back \(category.name)'s winner as it was")
            }
            .padding(.horizontal, Theme.Space.m)
            .padding(.bottom, Theme.Space.xs)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .transition(.opacity)
        }
    }

    private func line(_ change: AdminStore.WinnerChange, in category: BallotCategory) -> String {
        let names = category.nominations.filter { change.current.contains($0.id) }.map(\.adminName)
        return names.isEmpty ? "\(category.name): cleared" : "\(category.name): \(names.formatted(.list(type: .and)))"
    }
}

/// A category: its name and winner. A tap opens its nominees; one more marks
/// the winner. A tie and clearing the winner are in the same menu.
private struct WinnerRow: View {
    @Environment(AppModel.self) private var model
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 56
    let category: BallotCategory

    var body: some View {
        let winners = category.nominations.filter(\.isWinner)
        Menu {
            ForEach(category.nominations) { nominee in
                Button {
                    Task { await model.admin.markWinner(nominee.id, in: category.id) }
                } label: {
                    if nominee.isWinner {
                        Label(nominee.adminName, systemImage: "trophy.fill")
                    } else {
                        Text(nominee.adminName)
                    }
                }
            }
            if !winners.isEmpty {
                let others = category.nominations.filter { !$0.isWinner }
                if !others.isEmpty {
                    Menu("Add a tie", systemImage: "equal") {
                        ForEach(others) { nominee in
                            Button(nominee.adminName) {
                                Task { await model.admin.markWinner(nominee.id, in: category.id, tie: true) }
                            }
                        }
                    }
                }
                Button("Clear winner", systemImage: "xmark", role: .destructive) {
                    Task { await model.admin.clearWinner(in: category.id) }
                }
            }
        } label: {
            HStack(spacing: Theme.Space.s) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.ink)
                    Text(winners.isEmpty ? "Tap to set the winner" : winners.map(\.adminName).formatted(.list(type: .and)))
                        .font(.subheadline)
                        .foregroundStyle(winners.isEmpty ? .inkMuted : .goldText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: winners.isEmpty ? "chevron.up.chevron.down" : "trophy.fill")
                    .font(winners.isEmpty ? .footnote : .title3)
                    .foregroundStyle(winners.isEmpty ? AnyShapeStyle(.inkMuted) : AnyShapeStyle(Theme.goldGradient))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: height)
            .contentShape(.rect)
        }
        // Plain, so the row's text keeps its colours: gold only on a winner.
        .buttonStyle(.plain)
        // One change at a time per category, until the server answers.
        .disabled(model.admin.isPending(category.id))
        .accessibilityLabel(category.name)
        .accessibilityValue(winners.isEmpty ? "No winner yet" : "Winner: \(winners.map(\.spokenName).formatted(.list(type: .and)))")
        .accessibilityHint("Shows the nominees, to mark the winner")
        .moment(.correct, trigger: winners.map(\.id))
    }
}

/// The ceremony the winners belong to: which one, whether it's active, its
/// seed status and its dates.
private struct CeremonySection: View {
    @Environment(AppModel.self) private var model
    let ceremony: AdminCeremony
    @State private var ceremonyAt = Date.now
    @State private var ballotLockAt = Date.now

    var body: some View {
        let admin = model.admin
        Section {
            if admin.ceremonies.count > 1 {
                Picker("Ceremony", selection: Binding(get: { ceremony.id }, set: { id in Task { await admin.select(ceremonyID: id) } })) {
                    ForEach(admin.ceremonies) { Text($0.name).tag($0.id) }
                }
            }
            LabeledContent("Seeded", value: ceremony.seedLine)
            if ceremony.isActive {
                LabeledContent("Status", value: ceremony.isRehearsal ? "Active for testers" : "Active")
            } else {
                Button("Make active", systemImage: "checkmark.circle") {
                    Task {
                        if await admin.makeActive(ceremony.id) { await model.season.load() }
                    }
                }
            }
            DatePicker("Ceremony", selection: $ceremonyAt)
            DatePicker("Ballot locks", selection: $ballotLockAt)
            if ceremonyAt != ceremony.ceremonyAt || ballotLockAt != ceremony.ballotLockAt {
                Button("Save dates", systemImage: "calendar.badge.checkmark") {
                    Task {
                        if await admin.setDates(ceremonyAt: ceremonyAt, ballotLockAt: ballotLockAt) { await model.season.load() }
                    }
                }
            }
        } header: {
            Text("Ceremony")
        } footer: {
            Text("The ballot locks for everyone at the lock time, on the server's clock.")
        }
        .task(id: ceremony) {
            ceremonyAt = ceremony.ceremonyAt
            ballotLockAt = ceremony.ballotLockAt
        }
    }
}

/// A push to every device, confirmed first.
private struct PushSection: View {
    @Environment(AppModel.self) private var model
    @State private var title = ""
    @State private var message = ""
    @State private var destination: PushDestination = .home
    @State private var confirming = false
    @State private var sent = false

    var body: some View {
        let admin = model.admin
        let ready = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        Section {
            TextField("Title", text: $title)
            TextField("Message", text: $message, axis: .vertical)
                .lineLimit(1...4)
            Picker("Opens", selection: $destination) {
                ForEach(PushDestination.allCases) { Text($0.title).tag($0) }
            }
            Button("Send a push", systemImage: sent ? "checkmark" : "paperplane") { confirming = true }
                .disabled(!ready || admin.isSendingPush)
                .confirmationDialog("Send this to ^[\(admin.deviceCount) device](inflect: true)?", isPresented: $confirming, titleVisibility: .visible) {
                    Button("Send to everyone") {
                        Task {
                            if await admin.sendPush(title: title, body: message, destination: destination) {
                                title = ""
                                message = ""
                                sent = true
                            }
                        }
                    }
                } message: {
                    Text(title)
                }
        } header: {
            Text("Send a push")
        } footer: {
            Text(sent ? "Sent. It reaches phones within a minute." : "Goes to everyone with notifications on.")
        }
        .onChange(of: title) { if !title.isEmpty { sent = false } }
    }
}

extension BallotNominee {
    /// "Jessie Buckley (Hamnet)" for acting categories, else the film.
    var adminName: String {
        if let person = personName, !person.isEmpty {
            if let film = movie?.title { return "\(person) (\(film))" }
            return person
        }
        return movie?.title ?? "Nominee"
    }
}

private func adminPreview(_ configure: @escaping (SampleDataSource) -> Void = { _ in }) -> some View {
    NavigationStack { AdminView() }
        .environment(AppModel.preview { data in
            data.isAdmin = true
            configure(data)
        })
}

#Preview("Dark") {
    adminPreview().preferredColorScheme(.dark)
}

#Preview("Light") {
    adminPreview().preferredColorScheme(.light)
}

#Preview("Large text") {
    adminPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Winners in") {
    adminPreview { data in
        data.categories = data.categories.map { $0.withWinners([$0.nominations[0].id]) }
    }
    .preferredColorScheme(.dark)
}

#Preview("Full ballot") {
    adminPreview { data in
        data.categories = SampleData.fullBallot
    }
    .preferredColorScheme(.dark)
}

#Preview("Nothing seeded") {
    adminPreview { $0.categories = [] }.preferredColorScheme(.dark)
}

#Preview("Error") {
    adminPreview { $0.failure = .offline }.preferredColorScheme(.dark)
}
