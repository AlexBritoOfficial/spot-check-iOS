import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showSignup = false

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty && !isSubmitting }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Wordmark()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(SCFont.heading(32))
                            .foregroundStyle(SCColor.textPrimary)
                        Text("Sign in to add spots, save your favorites, and post reviews.")
                            .font(.system(size: 15))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                    .padding(.top, 48)

                    VStack(spacing: 16) {
                        SCTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            text: $email,
                            contentType: .emailAddress,
                            keyboard: .emailAddress
                        )

                        SCTextField(
                            label: "Password",
                            placeholder: "••••••••",
                            text: $password,
                            contentType: .password,
                            isSecure: true
                        ) {
                            Button("Forgot?") {}
                                .font(.system(size: 13))
                                .foregroundStyle(SCColor.accent)
                        }

                        if let error = authManager.lastError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(SCColor.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            Group {
                                if isSubmitting {
                                    ProgressView().tint(SCColor.background)
                                } else {
                                    Text("Sign in").font(SCFont.buttonLabel)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: SCMetric.controlHeight)
                        .background(canSubmit ? SCColor.accent : SCColor.accent.opacity(0.4))
                        .foregroundStyle(SCColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
                        .disabled(!canSubmit)
                        .padding(.top, 8)

                        HStack(spacing: 12) {
                            Rectangle().fill(SCColor.border).frame(height: 1)
                            Text("OR").font(SCFont.headingFixed(12)).foregroundStyle(SCColor.textSecondary)
                            Rectangle().fill(SCColor.border).frame(height: 1)
                        }

                        Button {
                            Task { await signInWithGoogle() }
                        } label: {
                            Text("Continue with Google")
                                .font(SCFont.buttonLabel)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: SCMetric.controlHeight)
                        .foregroundStyle(SCColor.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: SCRadius.control)
                                .stroke(SCColor.border, lineWidth: 1.5)
                        )
                        .disabled(isSubmitting)
                    }
                    .padding(.top, 32)

                    Spacer(minLength: 60)

                    HStack(spacing: 4) {
                        Spacer()
                        Text("New here?").foregroundStyle(SCColor.textSecondary)
                        Button("Create an account") { showSignup = true }
                            .font(SCFont.headingFixed(14))
                            .foregroundStyle(SCColor.accent)
                        Spacer()
                    }
                    .font(.system(size: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .padding(.bottom, 40)
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
            .background(SCColor.background)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden)
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
        }
    }

    private func signIn() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await authManager.signIn(email: email, password: password)
    }

    private func signInWithGoogle() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await authManager.signInWithGoogle()
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
