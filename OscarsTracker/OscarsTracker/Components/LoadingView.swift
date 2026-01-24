import SwiftUI

/// A standardized loading view with gold spinner.
struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
                .scaleEffect(1.2)

            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading, \(message)")
    }
}

/// A skeleton loading placeholder that pulses to indicate loading.
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.borderColor)
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .accessibilityHidden(true)
    }
}

/// A skeleton card that mimics a movie card during loading.
struct MovieCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster placeholder
            SkeletonView(height: 180, cornerRadius: 12)

            // Title placeholder
            SkeletonView(height: 16)

            // Runtime placeholder
            SkeletonView(width: 60, height: 12)
        }
    }
}

/// A skeleton row for list items during loading.
struct ListRowSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            SkeletonView(width: 60, height: 80, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                SkeletonView(height: 16)

                // Subtitle placeholder
                SkeletonView(width: 120, height: 12)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}

/// A skeleton view for the progress hero card.
struct ProgressHeroSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Percentage placeholder
            SkeletonView(width: 120, height: 48, cornerRadius: 8)

            // Progress bar placeholder
            SkeletonView(height: 12, cornerRadius: 6)

            // Stats row placeholder
            HStack {
                SkeletonView(width: 80, height: 16)
                Spacer()
                SkeletonView(width: 80, height: 16)
            }
        }
        .padding()
        .glassCard()
    }
}

/// A skeleton grid for movie cards during loading.
struct MovieGridSkeletonView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 5 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                MovieCardSkeletonView()
            }
        }
        .padding(.horizontal)
    }
}

/// A skeleton view for leaderboard rows.
struct LeaderboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 16) {
                    // Rank circle
                    SkeletonView(width: 44, height: 44, cornerRadius: 22)

                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView(width: 120, height: 16)
                        SkeletonView(width: 80, height: 12)
                    }

                    Spacer()

                    SkeletonView(width: 40, height: 24)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                )
            }
        }
    }
}

/// A skeleton view for ballot category cards.
struct BallotCategorySkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SkeletonView(width: 150, height: 20)
                        Spacer()
                        SkeletonView(width: 50, height: 16)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                )
            }
        }
    }
}

/// A skeleton view for watch plan items.
struct WatchPlanSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            SkeletonView(width: 100, height: 14)

            // Plan items
            ForEach(0..<3, id: \.self) { _ in
                ListRowSkeletonView()
            }
        }
    }
}

/// A skeleton view for profile information.
struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Avatar
            SkeletonView(width: 100, height: 100, cornerRadius: 50)

            // Username
            SkeletonView(width: 120, height: 24)

            // Email
            SkeletonView(width: 180, height: 16)

            // Stats card
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 8) {
                        SkeletonView(width: 40, height: 24)
                        SkeletonView(width: 60, height: 12)
                    }
                    if index < 2 {
                        Spacer()
                    }
                }
            }
            .padding()
            .glassCard()
        }
    }
}

/// A skeleton view for groups list.
struct GroupsSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            SkeletonView(width: 120, height: 14)

            // Group cards
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonView(width: 150, height: 20)
                    HStack {
                        SkeletonView(width: 80, height: 14)
                        Spacer()
                        SkeletonView(width: 60, height: 14)
                    }
                }
                .padding()
                .glassCard()
            }
        }
    }
}

#Preview("LoadingView") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LoadingView("Loading movies...")
    }
    .preferredColorScheme(.dark)
}

#Preview("Skeleton Views") {
    ScrollView {
        VStack(spacing: 24) {
            ProgressHeroSkeletonView()
            MovieGridSkeletonView()
        }
        .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
