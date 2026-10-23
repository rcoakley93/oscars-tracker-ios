import SwiftUI

/// Shown for the moment it takes to restore the session.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: Theme.Space.l) {
            BrandMark(size: 72)
            Text("Oscars Tracker").displayFont(.title)
                .foregroundStyle(.ink)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AmbientBackground() }
    }
}

#Preview { LaunchView() }
