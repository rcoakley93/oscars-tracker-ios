import SwiftUI

/// Report and Block (screens.md, 3.11; guideline 1.2, P6-16). Straight in
/// both voices: no jokes about reporting.

/// Report a person or a group: why, an optional note, Send. Once sent it
/// thanks you and, for a person, offers to block them too.
struct ReportSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let target: ReportTarget
    @State private var reason: ReportReason = .offensiveName
    @State private var details = ""
    @State private var sent = false
    @State private var confirmsBlock = false

    var body: some View {
        let moderation = model.moderation
        NavigationStack {
            Form {
                if sent {
                    Section {
                        Label("Thanks. We'll look at it within a day.", systemImage: "checkmark.circle")
                            .foregroundStyle(.ink)
                    } footer: {
                        if case .person = target {
                            Text("You can also block \(target.name), so you won't see each other on boards.")
                        }
                    }
                    .listRowBackground(Color.surface)
                    if case .person(let id, let name) = target, !moderation.isBlocked(id) {
                        Section {
                            Button("Block \(name)", systemImage: "hand.raised", role: .destructive) { confirmsBlock = true }
                        }
                        .listRowBackground(Color.surface)
                        .blockConfirmation(isPresented: $confirmsBlock, userID: id, name: name) { dismiss() }
                    }
                } else {
                    Section("What's wrong?") {
                        Picker("Reason", selection: $reason) {
                            ForEach(ReportReason.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                    .listRowBackground(Color.surface)
                    Section {
                        TextField("Anything we should know (optional)", text: $details, axis: .vertical)
                            .lineLimit(3...6)
                            .onChange(of: details) {
                                if details.count > ModerationStore.detailsLimit { details = String(details.prefix(ModerationStore.detailsLimit)) }
                            }
                    } footer: {
                        if let error = moderation.reportError {
                            Text(error.message).foregroundStyle(.dangerText)
                        } else {
                            Text("Reports go to the Oscars Tracker team, never to \(target.name).")
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.ground)
            .navigationTitle(sent ? "Report sent" : "Report \(target.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if sent {
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                    .visibilityPriority(.high)
                } else {
                    ToolbarItemGroup(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") { dismiss() }
                    }
                    .visibilityPriority(.automatic)
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Send", systemImage: "paperplane") {
                            Task { sent = await moderation.report(target, reason: reason, details: details) }
                        }
                        .disabled(moderation.isWorking)
                    }
                    .visibilityPriority(.high)
                }
            }
            .onAppear { moderation.reportError = nil }
        }
        .presentationDetents([.medium, .large])
    }
}

extension View {
    /// Report and Block in the context menu and as accessibility actions,
    /// for anyone but you (and the redacted stand-ins while a board loads).
    func personActions(userID: String, name: String) -> some View {
        modifier(PersonActions(userID: userID, name: name))
    }

    /// "Block Sam?", saying what blocking does; `then` runs once it's done.
    func blockConfirmation(isPresented: Binding<Bool>, userID: String, name: String, then: @escaping () -> Void = {}) -> some View {
        modifier(BlockConfirmation(isPresented: isPresented, userID: userID, name: name, then: then))
    }
}

private struct PersonActions: ViewModifier {
    @Environment(AppModel.self) private var model
    let userID: String
    let name: String
    @State private var confirmsBlock = false

    func body(content: Content) -> some View {
        if userID == model.session.userID || userID.hasPrefix("placeholder") {
            content
        } else {
            content
                .contextMenu { PersonMenuItems(userID: userID, name: name, confirmsBlock: $confirmsBlock) }
                .accessibilityActions { PersonMenuItems(userID: userID, name: name, confirmsBlock: $confirmsBlock) }
                .blockConfirmation(isPresented: $confirmsBlock, userID: userID, name: name)
        }
    }
}

/// "Report Sam" and "Block Sam", for a context menu or an overflow menu.
struct PersonMenuItems: View {
    @Environment(AppModel.self) private var model
    let userID: String
    let name: String
    @Binding var confirmsBlock: Bool

    var body: some View {
        Button("Report \(name)", systemImage: "flag") {
            model.navigation.sheet = .report(.person(id: userID, name: name))
        }
        if !model.moderation.isBlocked(userID) {
            Button("Block \(name)", systemImage: "hand.raised", role: .destructive) { confirmsBlock = true }
        }
    }
}

private struct BlockConfirmation: ViewModifier {
    @Environment(AppModel.self) private var model
    @Binding var isPresented: Bool
    let userID: String
    let name: String
    let then: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog("Block \(name)?", isPresented: $isPresented, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                Task {
                    if await model.block(userID, name: name) { then() }
                }
            }
        } message: {
            Text("You won't see each other on boards, and they'll leave the groups you created. You can unblock them in your profile.")
        }
    }
}

/// Profile: the people you've blocked, each with Unblock.
struct BlockedPeopleSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let moderation = model.moderation
        Section {
            if moderation.blocked.isEmpty {
                Text("Nobody. Block someone from their menu on the Board or in a group.")
                    .foregroundStyle(.inkMuted)
            }
            ForEach(moderation.blocked) { person in
                HStack(spacing: Theme.Space.s) {
                    Avatar(name: person.name, url: person.avatarUrl, isYou: false)
                    Text(person.name).foregroundStyle(.ink).lineLimit(1)
                    Spacer(minLength: Theme.Space.xs)
                    Button("Unblock") { Task { await model.unblock(person.userId) } }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Unblock \(person.name)")
                }
            }
        } header: {
            Text("Blocked people")
        } footer: {
            Text("To report a name or a group, open its menu and choose Report, or email support@oscarstracker.com.")
        }
        .listRowBackground(Color.surface)
    }
}

#Preview("Report a person, Dark") {
    Color.ground.sheet(isPresented: .constant(true)) { ReportSheet(target: .person(id: "u-chris", name: "Chris")) }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Report a group, Light") {
    Color.ground.sheet(isPresented: .constant(true)) { ReportSheet(target: .group(id: 2, name: "Family pool")) }
        .environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Report, Large text") {
    Color.ground.sheet(isPresented: .constant(true)) { ReportSheet(target: .person(id: "u-chris", name: "Chris")) }
        .environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Report fails") {
    Color.ground.sheet(isPresented: .constant(true)) { ReportSheet(target: .person(id: "u-chris", name: "Chris")) }
        .environment(AppModel.preview { $0.failure = .tooManyReports }).preferredColorScheme(.dark)
}

#Preview("Blocked people") {
    let model = AppModel.preview { data in
        data.blocked = [BlockedUser(userId: "u-chris", username: "Chris", avatarUrl: nil, blockedAt: nil),
                        BlockedUser(userId: "u-gone", username: nil, avatarUrl: nil, blockedAt: nil)]
    }
    return List { BlockedPeopleSection() }
        .scrollContentBackground(.hidden).background(.ground)
        .environment(model).preferredColorScheme(.dark)
}
