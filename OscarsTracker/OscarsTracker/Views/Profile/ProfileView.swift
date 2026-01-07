import SwiftUI

/// Profile view displaying user information and stats.
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading && viewModel.profile == nil {
                        loadingView
                    } else if viewModel.profile == nil {
                        emptyStateView
                    } else {
                        profileHeader
                        statsCard
                        accountSection
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .refreshable {
                await viewModel.loadData()
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar placeholder
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.textMuted)
                )
                .overlay(
                    Circle()
                        .stroke(Color.goldPrimary, lineWidth: 3)
                )

            // Username
            Text(viewModel.profile?.username ?? "User")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            // Member since
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)

                Text("Member since \(viewModel.memberSinceFormatted())")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile for \(viewModel.profile?.username ?? "User"), member since \(viewModel.memberSinceFormatted())")
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                StatItemView(
                    value: viewModel.watchedCount,
                    label: "Watched",
                    icon: "eye.fill"
                )

                Divider()
                    .frame(height: 60)
                    .background(Color.borderColor)

                StatItemView(
                    value: viewModel.predictionsMade,
                    label: "Predictions",
                    icon: "checkmark.seal.fill"
                )

                Divider()
                    .frame(height: 60)
                    .background(Color.borderColor)

                StatItemView(
                    value: viewModel.correctPredictions,
                    label: "Correct",
                    icon: "star.fill"
                )
            }
        }
        .padding()
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your stats: \(viewModel.watchedCount) watched, \(viewModel.predictionsMade) predictions, \(viewModel.correctPredictions) correct")
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 16) {
            Text("Account")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityLabel("Sign out of your account")
        }
        .padding()
        .glassCard()
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.goldPrimary)
            Text("Loading profile...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.goldPrimary)
            Text("Profile not found")
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Pull to refresh to load your profile")
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

/// Individual stat item display.
struct StatItemView: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.goldPrimary)

            Text("\(value)")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
