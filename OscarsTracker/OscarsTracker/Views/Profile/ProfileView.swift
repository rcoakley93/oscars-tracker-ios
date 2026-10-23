import SwiftUI

/// Profile view displaying user information and stats.
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
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
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                        // Reset auth state to navigate to login
                        authViewModel.isAuthenticated = false
                        authViewModel.currentUser = nil
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data including watch history, predictions, and group memberships will be permanently deleted.")
            }
            .sheet(isPresented: $viewModel.showChangePasswordSheet) {
                ChangePasswordSheet(viewModel: viewModel)
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
                    .foregroundStyle(Color.destructiveLight)
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

            // Change Password success message
            if let successMessage = viewModel.changePasswordSuccessMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                    Text(successMessage)
                        .foregroundStyle(Color.success)
                }
                .font(.caption)
                .transition(.opacity.combined(with: .scale))
            }

            // Change Password button
            Button {
                viewModel.openChangePasswordSheet()
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Change Password")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityLabel("Change your password")
            .accessibilityHint("Tap to change your account password")

            // Sign Out button
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

            // Delete Account button
            Button {
                showDeleteAccountConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isDeletingAccount {
                        ProgressView()
                            .tint(.white)
                        Text("Deleting...")
                    } else {
                        Image(systemName: "trash.fill")
                        Text("Delete Account")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(DestructiveButtonStyle())
            .disabled(viewModel.isDeletingAccount)
            .accessibilityLabel("Delete your account")
            .accessibilityHint("This will permanently delete your account and all associated data")
        }
        .padding()
        .glassCard()
        .animation(.easeInOut(duration: 0.2), value: viewModel.changePasswordSuccessMessage)
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

/// Sheet for changing user password
struct ChangePasswordSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @FocusState private var focusedField: PasswordField?

    enum PasswordField {
        case current
        case new
        case confirm
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient.gold)
                            .goldGlow()

                        Text("Change Password")
                            .font(.displaySmall)
                            .foregroundStyle(Color.textPrimary)

                        Text("Enter your current password and choose a new one")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // Form
                    VStack(spacing: 20) {
                        // Current password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            SecureField("", text: $viewModel.currentPassword)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.password)
                                .focused($focusedField, equals: .current)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .new
                                }
                                .accessibilityLabel("Current password")
                                .accessibilityHint("Enter your current password")
                        }

                        // New password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            SecureField("", text: $viewModel.newPassword)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .new)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .confirm
                                }
                                .accessibilityLabel("New password")
                                .accessibilityHint("Enter your new password")

                            // Password strength indicator
                            ChangePasswordStrengthView(strength: viewModel.newPasswordStrength)
                        }

                        // Confirm new password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            SecureField("", text: $viewModel.confirmNewPassword)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirm)
                                .submitLabel(.go)
                                .onSubmit {
                                    changePassword()
                                }
                                .accessibilityLabel("Confirm new password")
                                .accessibilityHint("Re-enter your new password")

                            // Password match indicator
                            if !viewModel.confirmNewPassword.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(viewModel.passwordsMatch ? Color.success : Color.destructiveLight)
                                    Text(viewModel.passwordsMatch ? "Passwords match" : "Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.passwordsMatch ? Color.success : Color.destructiveLight)
                                }
                            }
                        }

                        // Password requirements
                        ChangePasswordRequirementsView(viewModel: viewModel)

                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.destructiveLight)
                                Text(errorMessage)
                                    .font(.bodyMedium)
                                    .foregroundStyle(Color.destructiveLight)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Error: \(errorMessage)")
                        }
                    }
                    .glassCard()

                    // Change Password button
                    Button {
                        changePassword()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isChangingPassword {
                                ProgressView()
                                    .tint(.black)
                                Text("Changing Password...")
                            } else {
                                Text("Change Password")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .disabled(!viewModel.isChangePasswordFormValid || viewModel.isChangingPassword)
                    .opacity(viewModel.isChangePasswordFormValid ? 1 : 0.6)
                    .accessibilityLabel("Change password")
                    .accessibilityHint(viewModel.isChangePasswordFormValid ? "Tap to change your password" : "Fill in all fields correctly first")
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelChangePassword()
                    }
                    .foregroundStyle(Color.goldLight)
                }
            }
            .interactiveDismissDisabled(viewModel.isChangingPassword)
        }
        .onAppear {
            focusedField = .current
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: viewModel.currentPassword) { _, _ in
            viewModel.errorMessage = nil
        }
        .onChange(of: viewModel.newPassword) { _, _ in
            viewModel.errorMessage = nil
        }
        .onChange(of: viewModel.confirmNewPassword) { _, _ in
            viewModel.errorMessage = nil
        }
    }

    private func changePassword() {
        focusedField = nil
        Task {
            await viewModel.changePassword()
        }
    }
}

/// Password strength indicator for change password sheet
struct ChangePasswordStrengthView: View {
    let strength: PasswordStrength

    var body: some View {
        HStack(spacing: 8) {
            // Strength bars
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(height: 4)
                }
            }

            // Strength label
            if strength != .none {
                Text(strength.label)
                    .font(.caption)
                    .foregroundStyle(strengthColor)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
    }

    private func barColor(for index: Int) -> Color {
        switch strength {
        case .none:
            return Color.borderColor
        case .weak:
            return index == 0 ? Color.destructiveLight : Color.borderColor
        case .medium:
            return index <= 1 ? Color.goldPrimary : Color.borderColor
        case .strong:
            return Color.success
        }
    }

    private var strengthColor: Color {
        switch strength {
        case .none:
            return Color.textMuted
        case .weak:
            return Color.destructiveLight
        case .medium:
            return Color.goldPrimary
        case .strong:
            return Color.success
        }
    }
}

/// Password requirements checklist for change password
struct ChangePasswordRequirementsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password requirements:")
                .font(.caption)
                .foregroundStyle(Color.textMuted)

            ChangePasswordRequirementRow(
                met: viewModel.isNewPasswordLengthValid,
                text: "At least 8 characters"
            )
            ChangePasswordRequirementRow(
                met: viewModel.newPasswordHasUppercase,
                text: "One uppercase letter"
            )
            ChangePasswordRequirementRow(
                met: viewModel.newPasswordHasLowercase,
                text: "One lowercase letter"
            )
            ChangePasswordRequirementRow(
                met: viewModel.newPasswordHasNumber,
                text: "One number"
            )
        }
        .padding(.top, 4)
    }
}

/// Individual requirement row for change password
struct ChangePasswordRequirementRow: View {
    let met: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(met ? Color.success : Color.textMuted)
            Text(text)
                .font(.caption)
                .foregroundStyle(met ? Color.textPrimary : Color.textMuted)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
