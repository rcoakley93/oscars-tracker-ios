import SwiftUI

/// Sign up view with email, password, and password confirmation fields.
struct SignUpView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // Header with back button
                    HStack {
                        Button {
                            showSignUp = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundStyle(Color.goldPrimary)
                        }
                        .accessibilityLabel("Back to login")

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Logo/Title section
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient.gold)
                            .goldGlow()

                        Text("Create Account")
                            .font(.displayLarge)
                            .foregroundStyle(Color.textPrimary)

                        Text("Join the Oscar prediction community")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(.bottom, 10)

                    // Sign up form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            TextField("", text: $email)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                                .accessibilityLabel("Email address")
                                .accessibilityHint("Enter your email address")
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            SecureField("", text: $password)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .confirmPassword
                                }
                                .accessibilityLabel("Password")
                                .accessibilityHint("Enter a strong password")

                            // Password strength indicator
                            PasswordStrengthView(strength: authViewModel.passwordStrength(password))
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textMuted)

                            SecureField("", text: $confirmPassword)
                                .textFieldStyle(OscarsTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.go)
                                .onSubmit {
                                    signUp()
                                }
                                .accessibilityLabel("Confirm password")
                                .accessibilityHint("Re-enter your password")

                            // Password match indicator
                            if !confirmPassword.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(passwordsMatch ? Color.green : Color.destructive)
                                    Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(passwordsMatch ? Color.green : Color.destructive)
                                }
                            }
                        }

                        // Password requirements
                        PasswordRequirementsView(password: password)

                        // Error message
                        if let errorMessage = authViewModel.errorMessage {
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

                    // Sign Up button
                    Button {
                        signUp()
                    } label: {
                        HStack(spacing: 8) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                            }
                            Text(authViewModel.isLoading ? "Creating Account..." : "Sign Up")
                        }
                    }
                    .buttonStyle(.gold)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    .padding(.horizontal)
                    .accessibilityLabel("Sign Up")
                    .accessibilityHint(isFormValid ? "Double tap to create account" : "Fill in all fields first")

                    // Sign in link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)

                        Button("Sign In") {
                            showSignUp = false
                        }
                        .font(.headingMedium)
                        .foregroundStyle(Color.goldPrimary)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: email) { _, _ in
            authViewModel.clearError()
        }
        .onChange(of: password) { _, _ in
            authViewModel.clearError()
        }
        .onChange(of: confirmPassword) { _, _ in
            authViewModel.clearError()
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && passwordsMatch
    }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private func signUp() {
        focusedField = nil
        Task {
            await authViewModel.signUp(email: email, password: password, confirmPassword: confirmPassword)
        }
    }
}

/// Password strength indicator view
struct PasswordStrengthView: View {
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
            return index == 0 ? Color.destructive : Color.borderColor
        case .medium:
            return index <= 1 ? Color.goldPrimary : Color.borderColor
        case .strong:
            return Color.green
        }
    }

    private var strengthColor: Color {
        switch strength {
        case .none:
            return Color.textMuted
        case .weak:
            return Color.destructive
        case .medium:
            return Color.goldPrimary
        case .strong:
            return Color.green
        }
    }
}

/// Password requirements checklist view
struct PasswordRequirementsView: View {
    let password: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password requirements:")
                .font(.caption)
                .foregroundStyle(Color.textMuted)

            RequirementRow(
                met: password.count >= 8,
                text: "At least 8 characters"
            )
            RequirementRow(
                met: password.range(of: "[A-Z]", options: .regularExpression) != nil,
                text: "One uppercase letter"
            )
            RequirementRow(
                met: password.range(of: "[a-z]", options: .regularExpression) != nil,
                text: "One lowercase letter"
            )
            RequirementRow(
                met: password.range(of: "[0-9]", options: .regularExpression) != nil,
                text: "One number"
            )
        }
        .padding(.top, 4)
    }
}

/// Individual requirement row
struct RequirementRow: View {
    let met: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(met ? Color.green : Color.textMuted)
            Text(text)
                .font(.caption)
                .foregroundStyle(met ? Color.textPrimary : Color.textMuted)
        }
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel(), showSignUp: .constant(true))
        .preferredColorScheme(.dark)
}
