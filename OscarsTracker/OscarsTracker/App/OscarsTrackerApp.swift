import SwiftUI

@main
struct OscarsTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .sheet(isPresented: $authViewModel.needsOnboarding) {
                            OnboardingView(authViewModel: authViewModel)
                        }
                } else {
                    LoginView(authViewModel: authViewModel)
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authViewModel)
        }
    }
}
