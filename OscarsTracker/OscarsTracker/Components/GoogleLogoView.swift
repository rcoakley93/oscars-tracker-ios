import SwiftUI

/// A custom Google "G" logo view using SwiftUI shapes
/// Renders the multicolored Google logo without requiring an image asset
struct GoogleLogoView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let strokeWidth = size * 0.18

            ZStack {
                // Blue segment (right side, top portion)
                Circle()
                    .trim(from: 0.125, to: 0.375)
                    .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))

                // Green segment (right side, bottom portion)
                Circle()
                    .trim(from: 0.375, to: 0.5)
                    .stroke(Color(red: 52/255, green: 168/255, blue: 83/255), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))

                // Yellow segment (bottom)
                Circle()
                    .trim(from: 0.5, to: 0.625)
                    .stroke(Color(red: 251/255, green: 188/255, blue: 5/255), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))

                // Red segment (left side and top)
                Circle()
                    .trim(from: 0.625, to: 0.875)
                    .stroke(Color(red: 234/255, green: 67/255, blue: 53/255), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))

                // Blue bar extending from the right
                Rectangle()
                    .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
                    .frame(width: size * 0.4, height: strokeWidth)
                    .offset(x: size * 0.15, y: 0)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-90))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            GoogleLogoView()
                .frame(width: 24, height: 24)

            GoogleLogoView()
                .frame(width: 48, height: 48)

            GoogleLogoView()
                .frame(width: 100, height: 100)
        }
    }
    .preferredColorScheme(.dark)
}
