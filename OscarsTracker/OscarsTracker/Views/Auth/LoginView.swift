import SwiftUI

/// Login view with email and password fields for user authentication.
struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Logo/Title section
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(LinearGradient.gold)
                            .goldGlow()

                        Text("Oscars Tracker")
                            .font(.displayLarge)
                            .foregroundStyle(Color.textPrimary)

                        Text("Track your Oscar journey")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(.bottom, 20)

                    // Login form
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
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    signIn()
                                }
                                .accessibilityLabel("Password")
                                .accessibilityHint("Enter your password")
                        }

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

                    // Sign In button
                    Button {
                        signIn()
                    } label: {
                        HStack(spacing: 8) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                            }
                            Text(authViewModel.isLoading ? "Signing In..." : "Sign In")
                        }
                    }
                    .buttonStyle(.gold)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    .padding(.horizontal)
                    .accessibilityLabel("Sign In")
                    .accessibilityHint(isFormValid ? "Double tap to sign in" : "Enter email and password first")

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textMuted)

                        Button("Sign Up") {
                            showSignUp = true
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
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView(authViewModel: authViewModel, showSignUp: $showSignUp)
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
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        focusedField = nil
        Task {
            await authViewModel.signIn(email: email, password: password)
        }
    }
}

/// Custom text field style matching the app's design system
struct OscarsTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.secondaryBackground)
            .foregroundStyle(Color.textPrimary)
            .font(.bodyLarge)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
        .preferredColorScheme(.dark)
}
