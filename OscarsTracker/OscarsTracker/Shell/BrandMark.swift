import SwiftUI

/// The app's mark: a velvet envelope with a gold seal (never the statuette).
struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        Image(systemName: "envelope.fill")
            .font(.system(size: size))
            .foregroundStyle(.velvet)
            .overlay(alignment: .center) {
                Circle()
                    .fill(RadialGradient(colors: [.goldStart, .goldMid, .gold], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.16))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(y: size * 0.06)
            }
            .accessibilityHidden(true)
    }
}

#Preview { BrandMark().padding().background(.ground) }
