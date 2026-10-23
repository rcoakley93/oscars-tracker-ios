import SwiftUI

/// Launch, sign-in, onboarding or the app, from the session's state.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        ZStack {
            switch model.session.state {
            case .checking:
                LaunchView()
            case .signedOut:
                SignInView()
            case .signedIn:
                if model.profile.needsUsername {
                    UsernameView()
                } else {
                    AppShell()
                }
            }
        }
        .animation(.smooth, value: model.session.state)
        .animation(.smooth, value: model.profile.needsUsername)
        .tint(.goldOnGlass)
        .environment(\.copy, Copy.for(voice))
        .onOpenURL { url in
            Task {
                if await model.session.open(url) { await model.refresh() }
            }
        }
        .fullScreenCover(isPresented: .constant(model.session.isChoosingNewPassword)) {
            NewPasswordView()
        }
    }
}

#Preview("Signed in") {
    RootView().environment(AppModel.preview())
}

#Preview("Signed out") {
    RootView().environment(AppModel.preview(signedIn: false))
}
