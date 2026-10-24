import AuthenticationServices
import SwiftUI

/// Sign in with Apple, Google, or email and password, and forgot password.
/// Apple comes first (guideline 4.8 asks for it alongside Google).
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var creatingAccount = false
    @State private var checkEmail = false
    @State private var forgotPassword = false
    @State private var appleNonce = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        let session = model.session
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                VStack(spacing: Theme.Space.s) {
                    BrandMark()
                    Text("Oscars Tracker").displayFont(.largeTitle)
                        .foregroundStyle(.ink)
                    Text("Track the nominees, make your picks, beat your friends.")
                        .font(.body)
                        .foregroundStyle(.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Space.xxl)

                VStack(spacing: Theme.Space.s) {
                    SignInWithAppleButton(creatingAccount ? .signUp : .signIn) { request in
                        appleNonce = AppleNonce.make()
                        request.requestedScopes = [.email]
                        request.nonce = AppleNonce.sha256(appleNonce)
                    } onCompletion: { result in
                        Task { await finishApple(result) }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(Capsule())

                    Button {
                        Task {
                            await session.signInWithGoogle()
                            await refreshIfSignedIn()
                        }
                    } label: {
                        Text("Continue with Google")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
                .disabled(session.isWorking)

                HStack(spacing: Theme.Space.s) {
                    Rectangle().fill(.hairline).frame(height: 0.5)
                    Text("or with email").font(.footnote).foregroundStyle(.inkMuted).fixedSize()
                    Rectangle().fill(.hairline).frame(height: 0.5)
                }

                VStack(spacing: Theme.Space.s) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    SecureField("Password", text: $password)
                        .textContentType(creatingAccount ? .newPassword : .password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await submit() } }
                    if creatingAccount {
                        Text("At least 8 characters, with a lowercase letter, an uppercase letter and a number.")
                            .font(.footnote)
                            .foregroundStyle(.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Button("Forgot password?") { forgotPassword = true }
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                    }
                }
                .textFieldStyle(.roundedBorder)

                if let error = session.error, !forgotPassword {
                    Text(error.message)
                        .font(.footnote)
                        .foregroundStyle(.dangerText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await submit() }
                } label: {
                    ZStack {
                        if session.isWorking { ProgressView().tint(.ground) } else { Text(creatingAccount ? "Create account" : "Sign in") }
                    }
                    // Dark on the ink fill: in dark mode the tint is cream.
                    .foregroundStyle(.ground)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || session.isWorking)

                Button(creatingAccount ? "I already have an account" : "Create an account") {
                    creatingAccount.toggle()
                    session.clearError()
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
            }
            .padding(Theme.Space.l)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.ground)
        .alert("Check your email", isPresented: $checkEmail) {
            Button("OK") {}
        } message: {
            Text("We sent a link to \(email). Open it to finish creating your account, then sign in.")
        }
        .sheet(isPresented: $forgotPassword) {
            ForgotPasswordSheet(email: email)
        }
    }

    private func finishApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let token = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                model.session.appleSignInFailed(AppError.server("Apple returned no identity token"))
                return
            }
            await model.session.signInWithApple(idToken: token, nonce: appleNonce)
            await refreshIfSignedIn()
        case .failure(let error):
            model.session.appleSignInFailed(error)
        }
    }

    private func submit() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        if creatingAccount {
            if await model.session.signUp(email: email, password: password) == .checkEmail {
                checkEmail = true
                creatingAccount = false
            }
        } else {
            await model.session.signIn(email: email, password: password)
        }
        await refreshIfSignedIn()
    }

    private func refreshIfSignedIn() async {
        if model.session.userID != nil { await model.refresh() }
    }
}

/// Emails a reset link. The link opens the app at "Choose a new password".
struct ForgotPasswordSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var email: String
    @State private var sent = false

    var body: some View {
        let session = model.session
        NavigationStack {
            Form {
                if sent {
                    Section {
                        Label("Check \(email) for a link to choose a new password. Open it on this iPhone.", systemImage: "envelope.badge")
                            .foregroundStyle(.ink)
                    }
                } else {
                    Section {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } footer: {
                        if let error = session.error {
                            Text(error.message).foregroundStyle(.dangerText)
                        } else {
                            Text("We'll email you a link to choose a new password.")
                        }
                    }
                }
            }
            .navigationTitle("Forgot password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(sent ? "Done" : "Cancel", role: .cancel) { dismiss() }
                }
                if !sent {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send link") {
                            Task { sent = await session.sendPasswordReset(email: email) }
                        }
                        .disabled(!ValidationService.isValidEmail(email.trimmingCharacters(in: .whitespaces)) || session.isWorking)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { session.clearError() }
    }
}

/// After a reset-password link signs you in.
struct NewPasswordView: View {
    @Environment(AppModel.self) private var model
    @State private var password = ""

    var body: some View {
        let session = model.session
        NavigationStack {
            Form {
                Section {
                    SecureField("New password", text: $password)
                        .textContentType(.newPassword)
                } footer: {
                    if let error = session.error {
                        Text(error.message).foregroundStyle(.dangerText)
                    } else {
                        Text("At least 8 characters, with a lowercase letter, an uppercase letter and a number.")
                    }
                }
            }
            .navigationTitle("Choose a new password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await session.chooseNewPassword(password) }
                    }
                    .disabled(!PasswordRules.isValid(password) || session.isWorking)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview("Sign in") { SignInView().environment(AppModel.preview(signedIn: false)) }
#Preview("New password") { NewPasswordView().environment(AppModel.preview()) }
