import SwiftUI

/// A new account picks a username before anything else.
struct UsernameView: View {
    @Environment(AppModel.self) private var model
    @State private var username = ""

    var body: some View {
        let problem = username.isEmpty ? nil : ProfileStore.usernameProblem(username)
        VStack(spacing: Theme.Space.l) {
            Text("Pick a username").displayFont(.title)
                .foregroundStyle(.ink)
            Text("It's how your friends see you on the leaderboard.")
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if let problem {
                Text(problem).font(.footnote).foregroundStyle(.dangerText)
            } else if let error = model.profile.actionError {
                Text(error.message).font(.footnote).foregroundStyle(.dangerText)
            }
            Button("Continue") {
                guard let userID = model.session.userID else { return }
                Task { _ = await model.profile.setUsername(username, userID: userID) }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(username.isEmpty || problem != nil || model.profile.isWorking)
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ground)
    }
}

#Preview { UsernameView().environment(AppModel.preview()) }
