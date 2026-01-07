import SwiftUI

@main
struct OscarsTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                } else {
                    LoginView(authViewModel: authViewModel)
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authViewModel)
        }
    }
}
