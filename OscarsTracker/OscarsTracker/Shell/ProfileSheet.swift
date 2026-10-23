import SwiftUI

/// Profile essentials for the shell: who you are, sign out and delete the
/// account. P4-08 builds the full screen (voice, notifications, seasons).
struct ProfileSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Username", value: model.profile.profile?.username ?? "—")
                }
                Section {
                    Button("Sign out") {
                        Task {
                            await model.signOut()
                            dismiss()
                        }
                    }
                }
                Section {
                    Button("Delete account", role: .destructive) { confirmDelete = true }
                } footer: {
                    Text("Deletes your account, picks, watched films, plan and groups you created. This can't be undone.")
                }
                if let error = model.profile.actionError {
                    Section { Text(error.message).foregroundStyle(.dangerText) }
                }
            }
            .navigationTitle("Profile")
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete account", role: .destructive) {
                    Task {
                        if await model.deleteAccount() { dismiss() }
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview { ProfileSheet().environment(AppModel.preview()) }
