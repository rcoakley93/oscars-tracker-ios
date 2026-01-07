import SwiftUI

/// Profile view displaying user information and stats.
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSignOutConfirmation = false
    @FocusState private var isUsernameFieldFocused: Bool

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

            // Username with edit functionality
            if viewModel.isEditingUsername {
                usernameEditView
            } else {
                usernameDisplayView
            }

            // Success message
            if let successMessage = viewModel.usernameSuccessMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                    Text(successMessage)
                        .foregroundStyle(Color.success)
                }
                .font(.caption)
                .transition(.opacity.combined(with: .scale))
            }

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
        .animation(.easeInOut(duration: 0.2), value: viewModel.isEditingUsername)
        .animation(.easeInOut(duration: 0.2), value: viewModel.usernameSuccessMessage)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile for \(viewModel.profile?.username ?? "User"), member since \(viewModel.memberSinceFormatted())")
    }

    // MARK: - Username Display

    private var usernameDisplayView: some View {
        HStack(spacing: 8) {
            Text(viewModel.profile?.username ?? "User")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            Button {
                viewModel.startEditingUsername()
                isUsernameFieldFocused = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldPrimary)
            }
            .accessibilityLabel("Edit username")
            .accessibilityHint("Tap to edit your username")
        }
    }

    // MARK: - Username Edit View

    private var usernameEditView: some View {
        VStack(spacing: 12) {
            // Text field
            TextField("Username", text: $viewModel.editedUsername)
                .textFieldStyle(OscarsTextFieldStyle())
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isUsernameFieldFocused)
                .frame(maxWidth: 250)
                .accessibilityLabel("Username")
                .accessibilityHint("Enter your new username")

            // Validation indicators
            VStack(alignment: .leading, spacing: 4) {
                validationRow(
                    isValid: viewModel.isUsernameLengthValid,
                    text: "3-20 characters"
                )
                validationRow(
                    isValid: viewModel.isUsernameFormatValid,
                    text: "Letters, numbers, underscores only"
                )
                validationRow(
                    isValid: !viewModel.usernameContainsProfanity,
                    text: "No inappropriate content"
                )
            }
            .font(.caption)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.destructive)
                    .multilineTextAlignment(.center)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.cancelEditingUsername()
                    isUsernameFieldFocused = false
                }
                .buttonStyle(GoldOutlineButtonStyle())
                .accessibilityLabel("Cancel editing")

                Button {
                    Task {
                        await viewModel.saveUsername()
                        isUsernameFieldFocused = false
                    }
                } label: {
                    if viewModel.isSavingUsername {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.black)
                            Text("Saving...")
                        }
                    } else {
                        Text("Save")
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(!viewModel.isEditedUsernameValid || viewModel.isSavingUsername)
                .accessibilityLabel("Save username")
                .accessibilityHint(viewModel.isEditedUsernameValid ? "Tap to save your new username" : "Enter a valid username to save")
            }
        }
    }

    // MARK: - Validation Row Helper

    private func validationRow(isValid: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isValid ? Color.success : Color.textMuted)
            Text(text)
                .foregroundStyle(isValid ? Color.success : Color.textMuted)
        }
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
