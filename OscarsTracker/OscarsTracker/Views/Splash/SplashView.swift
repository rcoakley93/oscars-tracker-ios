import SwiftUI

/// Launch splash screen displayed during authentication check
struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // App logo/icon
                appLogo

                // App name
                Text("Oscars Tracker")
                    .font(.displayLarge)
                    .foregroundStyle(Color.goldPrimary)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 10)

                // Loading indicator
                ProgressView()
                    .tint(Color.goldPrimary)
                    .scaleEffect(1.2)
                    .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }

    // MARK: - App Logo

    private var appLogo: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.goldPrimary.opacity(0.3))
                .frame(width: 160, height: 160)
                .blur(radius: 30)

            // App icon logo
            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color.goldPrimary.opacity(0.5), radius: 12, x: 0, y: 6)
        }
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
