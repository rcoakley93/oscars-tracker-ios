import SwiftUI

/// Shown instead of the app when this build is below `min_supported_build`
/// (P4-10): the season changed something old builds can't handle.
struct UpdateRequiredView: View {
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6758015289")!

    var body: some View {
        ContentUnavailableView {
            Label("Update to keep playing", systemImage: "arrow.down.app")
        } description: {
            Text("This version of Oscars Tracker is too old for this season. The update is free and keeps your picks and films.")
        } actions: {
            Link(destination: Self.appStoreURL) {
                Text("Open the App Store").foregroundStyle(.ground)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ground)
    }
}

#Preview("Dark") {
    UpdateRequiredView().preferredColorScheme(.dark)
}

#Preview("Light") {
    UpdateRequiredView().preferredColorScheme(.light)
}
