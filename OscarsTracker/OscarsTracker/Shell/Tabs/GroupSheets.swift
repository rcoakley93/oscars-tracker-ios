import SwiftUI

// Join and Create (screens.md, 3.7), opened from `AppNavigation.sheet`.

/// Join with a six-character code, typed or from an invite link. On success
/// the group opens and the gold dust falls (from the store, after the server
/// says yes).
struct JoinGroupSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss
    @State private var code: String
    @State private var joined: String?
    @FocusState private var focused: Bool

    init(code: String?) {
        _code = State(initialValue: code.map(InviteLink.normalized) ?? "")
    }

    var body: some View {
        let groups = model.groups
        NavigationStack {
            Form {
                Section {
                    TextField("ABC123", text: Binding { code } set: { code = InviteLink.normalized($0) })
                        .font(.title2.monospaced().weight(.semibold))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textContentType(nil)
                        .focused($focused)
                        .submitLabel(.join)
                        .onSubmit(join)
                        .accessibilityLabel("Invite code")
                        .disabled(joined != nil)
                } footer: {
                    Text(joined ?? groups.actionError?.message ?? "Six letters and numbers, from the invite.")
                        .foregroundStyle(joined != nil ? AnyShapeStyle(.goldText) : groups.actionError != nil ? AnyShapeStyle(.dangerText) : AnyShapeStyle(.inkMuted))
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Join a group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button(joined == nil ? "Cancel" : "Done", systemImage: joined == nil ? "xmark" : "checkmark") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    if joined == nil {
                        Button("Join", systemImage: "checkmark", action: join)
                            .disabled(!InviteLink.isValid(code) || groups.isWorking)
                    }
                }
            }
            .goldDust(trigger: groups.joins)
            .onAppear {
                groups.actionError = nil
                focused = code.isEmpty
            }
        }
        .presentationDetents([.medium])
    }

    private func join() {
        guard InviteLink.isValid(code), let userID = model.session.userID else { return }
        Task {
            guard let group = await model.groups.join(code: code, userID: userID) else { return }
            joined = copy.groupsJoined(group.groupName)
            model.navigation.tab = .groups
            model.navigation.selectedGroupID = group.groupId
            AccessibilityNotification.Announcement(joined ?? "").post()
        }
    }
}

/// Name a new group; it opens with you as its creator.
struct CreateGroupSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var edited = false
    @FocusState private var focused: Bool

    var body: some View {
        let groups = model.groups
        let problem = GroupsStore.nameProblem(name.trimmingCharacters(in: .whitespacesAndNewlines))
        NavigationStack {
            Form {
                Section {
                    TextField("Group name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(create)
                        .onChange(of: name) { edited = true }
                } footer: {
                    if let message = groups.actionError?.message ?? (edited ? problem : nil) {
                        Text(message).foregroundStyle(.dangerText)
                    } else {
                        Text("You can invite up to 11 friends.")
                    }
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Create a group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Create", systemImage: "checkmark", action: create)
                        .disabled(problem != nil || groups.isWorking)
                }
            }
            .onAppear {
                groups.actionError = nil
                focused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func create() {
        guard let userID = model.session.userID else { return }
        Task {
            guard let group = await model.groups.create(name: name, userID: userID) else { return }
            model.navigation.tab = .groups
            model.navigation.selectedGroupID = group.id
            dismiss()
        }
    }
}

#Preview("Join") {
    Color.ground.sheet(isPresented: .constant(true)) { JoinGroupSheet(code: "friend") }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Create") {
    Color.ground.sheet(isPresented: .constant(true)) { CreateGroupSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}
