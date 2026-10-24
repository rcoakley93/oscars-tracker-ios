import SwiftUI

/// Launch, sign-in, onboarding or the app, from the session's state.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        ZStack {
            if model.season.needsUpdate() {
                UpdateRequiredView()
            } else {
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
        }
        .animation(.smooth, value: model.session.state)
        .animation(.smooth, value: model.profile.needsUsername)
        // Ink, not gold: gold is earned (progress, your picks, wins), so the
        // places that are gold say so themselves.
        .tint(.ink)
        .environment(\.copy, Copy.for(voice))
        .asyncImageURLSession(.posters)
        .onOpenURL { url in
            Task {
                if await model.session.open(url) { await model.refresh() }
            }
        }
        .fullScreenCover(isPresented: .constant(model.session.isChoosingNewPassword)) {
            NewPasswordView()
        }
        #if DEBUG
        .fullScreenCover(isPresented: Binding { model.navigation.debugGallery != nil } set: { if !$0 { model.navigation.debugGallery = nil } }) {
            NavigationStack {
                switch model.navigation.debugGallery {
                case "moments": MomentsGallery()
                case "envelope": EnvelopeReveal(category: "Best Picture", winner: "Hamnet", outcome: .correct) {}
                default: TokensGallery().navigationTitle("Design tokens")
                }
            }
        }
        #endif
    }
}

#Preview("Signed in") {
    RootView().environment(AppModel.preview())
}

#Preview("Signed out") {
    RootView().environment(AppModel.preview(signedIn: false))
}
