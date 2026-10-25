import AuthenticationServices
import SwiftUI

/// Profile (screens.md, 3.8): your account and the app's few settings.
/// Account, Voice, Notifications (P4-09 and P6-04), Past seasons, About,
/// Sign out and Delete account. A large sheet on compact widths, a page on
/// regular ones.
struct ProfileSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    @State private var deleting = false

    var body: some View {
        let profile = model.profile
        @Bindable var push = model.push
        NavigationStack {
            Form {
                Section("Account") {
                    NavigationLink {
                        UsernameEditor()
                    } label: {
                        LabeledContent("Username", value: profile.profile?.username ?? "—")
                    }
                    if let email = profile.account?.email {
                        LabeledContent("Email", value: email)
                    }
                    switch profile.account?.provider {
                    case .email:
                        NavigationLink("Change password") { PasswordEditor() }
                    case .apple:
                        LabeledContent("Signs in with", value: "Apple")
                    case .google:
                        LabeledContent("Signs in with", value: "Google")
                    case nil:
                        EmptyView()
                    }
                }

                Section {
                    Picker("Voice", selection: $voice) {
                        ForEach(Voice.allCases) { Text(Copy.for($0).label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .tint(.gold)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Voice")
                } footer: {
                    Text(Copy.for(voice).sample)
                        .font(.subheadline)
                        .foregroundStyle(.ink)
                        .contentTransition(.opacity)
                        .animation(.default, value: voice)
                        .padding(.top, Theme.Space.xs)
                }

                if model.isAdmin {
                    Section {
                        NavigationLink {
                            AdminView()
                        } label: {
                            Label("Ceremony night", systemImage: "trophy")
                        }
                        .accessibilityIdentifier("admin")
                    } header: {
                        Text("Admin")
                    } footer: {
                        Text("Winners, the season's dates and a push to everyone.")
                    }
                }

                Section {
                    NotificationsRow()
                    ForEach(NotificationPreferences.Reminder.allCases) { ReminderToggle(reminder: $0) }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Reminders arrive in your voice.")
                }

                if !pastSeasons.isEmpty {
                    Section("Past seasons") {
                        ForEach(pastSeasons) { SeasonRow(season: $0) }
                    }
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
                    Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right") {
                        Task {
                            await model.signOut()
                            dismiss()
                        }
                    }
                }
                Section {
                    Button("Delete account", systemImage: "trash", role: .destructive) { deleting = true }
                } footer: {
                    Text("Deletes your account, picks, watched films, plan and the groups you created. This can't be undone.")
                }
                #if DEBUG
                Section("Debug") {
                    NavigationLink("Moments") { MomentsGallery() }
                    NavigationLink("Design tokens") { TokensGallery() }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(.ground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
            .task { await profile.loadHistory() }
            .onChange(of: voice) { Task { await model.push.setVoice(voice) } }
            .errorAlert("Couldn't save that", error: $push.actionError)
            .sheet(isPresented: $deleting) {
                DeleteAccountSheet { dismiss() }
            }
        }
        .presentationDetents([.large])
        .presentationSizing(.page)
    }

    /// Seasons before this one.
    private var pastSeasons: [SeasonResult] {
        model.profile.history.filter { $0.ceremonyId != model.season.ceremony?.id }
    }
}

/// Whether notifications are on, with the way to turn them on.
private struct NotificationsRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch model.push.status {
        case .notDetermined:
            Button("Turn on notifications", systemImage: "bell") {
                Task { await model.push.ask() }
            }
        case .denied:
            Button("Turn on in Settings", systemImage: "gear") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
            }
        default:
            LabeledContent("Notifications", value: "On")
        }
    }
}

/// One reminder's switch (P6-04), saved to the server, which sends it.
private struct ReminderToggle: View {
    @Environment(AppModel.self) private var model
    let reminder: NotificationPreferences.Reminder

    var body: some View {
        let push = model.push
        Toggle(isOn: Binding(get: { push.preferences[reminder] }, set: { on in Task { await push.set(reminder, on) } })) {
            Label {
                Text(reminder.title)
                Text(reminder.detail)
            } icon: {
                Image(systemName: reminder.systemImage)
            }
        }
    }
}

/// "98th Academy Awards", then "3rd of 212 · 41 films · 15 correct".
private struct SeasonRow: View {
    let season: SeasonResult

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(season.name).foregroundStyle(.ink)
            Text(line).font(.subheadline).foregroundStyle(.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private var line: String {
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        let place = "\(ordinal.string(from: season.rank as NSNumber) ?? "\(season.rank)") of \(season.players.formatted())"
        let score = season.scoring == .weighted ? Copy.pointCount(season.points) : "\(season.correctCount) correct"
        return "\(place) · \(Copy.filmCount(season.watchedCount)) · \(score)"
    }
}

private struct UsernameEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""

    var body: some View {
        let profile = model.profile
        let problem = ProfileStore.usernameProblem(username)
        Form {
            Section {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
            } footer: {
                if let message = profile.actionError?.message ?? (username.isEmpty ? nil : problem) {
                    Text(message).foregroundStyle(.dangerText)
                } else {
                    Text("Shown on boards and to your groups.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle("Username")
        .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    guard let userID = model.session.userID else { return }
                    Task { if await profile.setUsername(username, userID: userID) { dismiss() } }
                }
                .disabled(problem != nil || username == profile.profile?.username || profile.isWorking)
            }
        }
        .onAppear {
            profile.actionError = nil
            username = profile.profile?.username ?? ""
        }
    }
}

private struct PasswordEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmation = ""

    var body: some View {
        let profile = model.profile
        let valid = PasswordRules.isValid(password) && password == confirmation
        Form {
            Section {
                SecureField("New password", text: $password).textContentType(.newPassword)
                SecureField("Confirm", text: $confirmation).textContentType(.newPassword)
            } footer: {
                if let error = profile.actionError {
                    Text(error.message).foregroundStyle(.dangerText)
                } else if !confirmation.isEmpty, password != confirmation {
                    Text("The passwords don't match.").foregroundStyle(.dangerText)
                } else {
                    Text("At least 8 characters, with a lowercase letter, an uppercase letter and a number.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle("Change password")
        .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    Task { if await profile.changePassword(password) { dismiss() } }
                }
                .disabled(!valid || profile.isWorking)
            }
        }
        .onAppear { profile.actionError = nil }
    }
}

/// Confirms deletion. A Sign in with Apple account confirms with Apple,
/// which gives the fresh code that revokes its tokens; others confirm with a
/// button. You're signed out only after the server has deleted everything.
private struct DeleteAccountSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onDeleted: () -> Void

    var body: some View {
        let profile = model.profile
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("This deletes your account, your picks, your watched films, your plan and the groups you created. It can't be undone.")
                    .foregroundStyle(.ink)
                if let error = profile.actionError {
                    Text(error.message).font(.subheadline).foregroundStyle(.dangerText)
                }
                Spacer()
                if profile.account?.provider == .apple {
                    Text("Confirm with Apple to finish. It also stops this app using your Apple ID.")
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        guard case .success(let authorization) = result,
                              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                              let code = credential.authorizationCode.flatMap({ String(data: $0, encoding: .utf8) }) else { return }
                        delete(appleCode: code)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(Capsule())
                    .disabled(profile.isWorking)
                } else {
                    Button(role: .destructive) {
                        delete(appleCode: nil)
                    } label: {
                        Text("Delete account").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.danger)
                    .controlSize(.large)
                    .disabled(profile.isWorking)
                }
            }
            .padding(Theme.Space.l)
            .overlay { if profile.isWorking { ProgressView() } }
            .navigationTitle("Delete your account?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .onAppear { profile.actionError = nil }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(profile.isWorking)
    }

    private func delete(appleCode: String?) {
        Task {
            if await model.deleteAccount(appleAuthorizationCode: appleCode) {
                dismiss()
                onDeleted()
            }
        }
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

#Preview("Dark") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.dark)
}

#Preview("Light") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.light)
}

#Preview("Large text") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview()).preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}

#Preview("Notifications off, watch plan on") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview {
            $0.preferences = NotificationPreferences(nominations: false, watchPlan: true, ballotLock: true, results: false)
        })
        .preferredColorScheme(.dark)
}

#Preview("Sign in with Apple") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview { $0.accountProvider = .apple }).preferredColorScheme(.dark)
}

#Preview("Admin") {
    Color.ground.sheet(isPresented: .constant(true)) { ProfileSheet() }
        .environment(AppModel.preview { $0.isAdmin = true }).preferredColorScheme(.dark)
}
