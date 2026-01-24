import SwiftUI

@main
struct OscarsTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isCheckingSession {
                    // Show splash screen while checking authentication
                    SplashView()
                        .transition(.opacity)
                } else if authViewModel.isAuthenticated {
                    ContentView()
                        .sheet(isPresented: $authViewModel.needsOnboarding) {
                            OnboardingView(authViewModel: authViewModel)
                        }
                        .transition(.opacity)
                } else {
                    LoginView(authViewModel: authViewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isCheckingSession)
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .preferredColorScheme(.dark)
            .environmentObject(authViewModel)
        }
    }
}
