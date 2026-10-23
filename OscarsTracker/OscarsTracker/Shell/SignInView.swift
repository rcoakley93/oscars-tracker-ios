import SwiftUI

/// Email and password sign-in and sign-up. P3-09 adds Sign in with Apple,
/// Google and forgot password, and the finished design.
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @State private var email = ""
    @State private var password = ""
    @State private var creatingAccount = false
    @State private var checkEmail = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        let session = model.session
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                VStack(spacing: Theme.Space.s) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.goldGradient)
                        .accessibilityHidden(true)
                    Text("Oscars Tracker").displayFont(.largeTitle)
                        .foregroundStyle(.ink)
                    Text("Track the nominees, make your picks, beat your friends.")
                        .font(.body)
                        .foregroundStyle(.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Space.xxl)

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
                    }
                }
                .textFieldStyle(.roundedBorder)

                if let error = session.error {
                    Text(error.message)
                        .font(.footnote)
                        .foregroundStyle(.dangerText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if session.isWorking { ProgressView() } else { Text(creatingAccount ? "Create account" : "Sign in") }
                    }
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
        if model.session.userID != nil { await model.refresh() }
    }
}

#Preview { SignInView().environment(AppModel.preview(signedIn: false)) }
