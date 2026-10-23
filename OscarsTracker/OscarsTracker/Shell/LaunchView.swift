import SwiftUI

/// Shown for the moment it takes to restore the session.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: Theme.Space.l) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.goldGradient)
                .accessibilityHidden(true)
            Text("Oscars Tracker").displayFont(.title)
                .foregroundStyle(.ink)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ground)
    }
}

#Preview { LaunchView() }
