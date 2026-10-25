import SwiftUI

/// The app's mark: the gold emblem from the app icon, on a clear ground so it
/// sits on the ambient background in light and dark.
struct BrandMark: View {
    var size: CGFloat = 96

    var body: some View {
        Image("BrandLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview { BrandMark().padding().background(.ground) }
