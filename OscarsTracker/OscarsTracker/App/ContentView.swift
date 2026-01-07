import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "film")
                }

            Text("Watch Plan")
                .tabItem {
                    Label("Watch Plan", systemImage: "calendar")
                }

            Text("Ballot")
                .tabItem {
                    Label("Ballot", systemImage: "checkmark.seal")
                }

            Text("Leaderboard")
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy")
                }

            Text("More")
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
        .tint(.goldPrimary)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
