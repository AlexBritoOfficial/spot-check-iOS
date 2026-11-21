import SwiftUI

struct SignupView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var homeCity = ""
    @State private var isSubmitting = false

    private var canSubmit: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && !homeCity.isEmpty && !isSubmitting
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(SCColor.textPrimary)
                    }
                    Spacer()
                    Wordmark(size: 16)
                    Spacer()
                    Color.clear.frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Create an account")
                        .font(SCFont.heading(30))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("Join the crew — add spots, save favorites, post reviews.")
                        .font(.system(size: 15))
                        .foregroundStyle(SCColor.textSecondary)
                }
                .padding(.top, 28)

                VStack(spacing: 14) {
                    SCTextField(label: "Username", placeholder: "e.g. rider.nguyen", text: $username, contentType: .username)
                    SCTextField(label: "Email", placeholder: "you@example.com", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                    SCTextField(label: "Password", placeholder: "••••••••", text: $password, contentType: .password, isSecure: true)
                    SCTextField(label: "Home city", placeholder: "e.g. Portland, OR", text: $homeCity, contentType: .addressCity)

                    if let error = authManager.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(SCColor.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await signUp() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(SCColor.background)
                            } else {
                                Text("Create account").font(SCFont.buttonLabel)
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
                }
                .padding(.top, 26)

                Spacer(minLength: 40)

                HStack(spacing: 4) {
                    Spacer()
                    Text("Already have an account?").foregroundStyle(SCColor.textSecondary)
                    Button("Sign in") { dismiss() }
                        .font(SCFont.headingFixed(14))
                        .foregroundStyle(SCColor.accent)
                    Spacer()
                }
                .font(.system(size: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
            .padding(.bottom, 32)
            .frame(minHeight: UIScreen.main.bounds.height - 80)
        }
        .background(SCColor.background)
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden)
    }

    private func signUp() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await authManager.signUp(email: email, password: password, username: username, homeCity: homeCity)
    }
}

#Preview {
    NavigationStack {
        SignupView()
            .environment(AuthManager())
    }
}
