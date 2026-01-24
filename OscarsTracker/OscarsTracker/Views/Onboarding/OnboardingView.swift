import SwiftUI

/// Onboarding view for new users to set up their username.
struct OnboardingView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = OnboardingViewModel()
    @FocusState private var isUsernameFocused: Bool

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Welcome section
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient.gold)
                        .goldGlow()

                    Text("Welcome!")
                        .font(.displayLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("Let's set up your profile")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.bottom, 20)

                // Username form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose a username")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)

                        TextField("", text: $viewModel.username)
                            .textFieldStyle(OscarsTextFieldStyle())
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($isUsernameFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                saveUsername()
                            }
                            .accessibilityLabel("Username")
                            .accessibilityHint("Enter your display name")

                        // Username requirements
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username requirements:")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)

                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isLengthValid ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isLengthValid ? Color.green : Color.textMuted)
                                Text("3-20 characters")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isLengthValid ? Color.textPrimary : Color.textMuted)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isFormatValid ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isFormatValid ? Color.green : Color.textMuted)
                                Text("Letters, numbers, underscores only")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isFormatValid ? Color.textPrimary : Color.textMuted)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: !viewModel.containsProfanity ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(!viewModel.containsProfanity ? Color.green : Color.destructive)
                                Text("No inappropriate content")
                                    .font(.caption)
                                    .foregroundStyle(!viewModel.containsProfanity ? Color.textPrimary : Color.destructive)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.destructive)
                            Text(errorMessage)
                                .font(.bodyMedium)
                                .foregroundStyle(Color.destructive)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(errorMessage)")
                    }
                }
                .glassCard()
                .padding(.horizontal)

                // Continue button
                Button {
                    saveUsername()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                        }
                        Text(viewModel.isLoading ? "Saving..." : "Continue")
                    }
                }
                .buttonStyle(.gold)
                .disabled(viewModel.isLoading || !viewModel.isUsernameValid)
                .opacity(viewModel.isUsernameValid ? 1 : 0.6)
                .padding(.horizontal)
                .accessibilityLabel("Continue")
                .accessibilityHint(viewModel.isUsernameValid ? "Double tap to continue" : "Enter a valid username first")

                Spacer()
                Spacer()
            }
            .padding(.horizontal)
        }
        .interactiveDismissDisabled()
        .onTapGesture {
            isUsernameFocused = false
        }
        .onAppear {
            isUsernameFocused = true
        }
    }

    private func saveUsername() {
        guard viewModel.isUsernameValid else { return }
        isUsernameFocused = false

        Task {
            guard let userId = authViewModel.currentUser?.id else {
                viewModel.errorMessage = "Unable to save username. Please try again."
                return
            }

            let success = await viewModel.saveUsername(userId: userId)
            if success {
                authViewModel.completeOnboarding()
            }
        }
    }
}

#Preview {
    OnboardingView(authViewModel: AuthViewModel())
        .preferredColorScheme(.dark)
}
