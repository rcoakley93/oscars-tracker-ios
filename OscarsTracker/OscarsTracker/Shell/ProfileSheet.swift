import SwiftUI

/// Profile essentials for the shell: who you are, sign out and delete the
/// account. P4-08 builds the full screen (voice, notifications, seasons).
struct ProfileSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Username", value: model.profile.profile?.username ?? "—")
                }
                Section {
                    Picker("Voice", selection: $voice) {
                        ForEach(Voice.allCases) { option in
                            VStack(alignment: .leading) {
                                Text(Copy.for(option).label)
                                Text(Copy.for(option).sample).font(.footnote).foregroundStyle(.inkMuted)
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Voice")
                } footer: {
                    Text("How the app talks to you. Errors are always plain.")
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.versionLine)
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        Link("themoviedb.org", destination: URL(string: "https://www.themoviedb.org")!)
                    }
                    .font(.footnote)
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        Text("Where-to-watch data from JustWatch.")
                        Link("justwatch.com", destination: URL(string: "https://www.justwatch.com/us")!)
                    }
                    .font(.footnote)
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
                #if DEBUG
                Section("Debug") {
                    NavigationLink("Moments") { MomentsGallery() }
                    NavigationLink("Design tokens") { TokensGallery() }
                }
                #endif
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

extension Bundle {
    /// "1.4 (27)".
    var versionLine: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview { ProfileSheet().environment(AppModel.preview()) }
