//
//  SettingsView.swift
//  CallyFS
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var auth = AuthService.shared
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        accountCard
                        aiCard
                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                }
            }
            .onAppear { auth.refreshLocalState() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(AppTheme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Account

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md),
                                 fallback: AppTheme.Colors.surfaceHighlight)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Account")
                        .font(AppTheme.Typography.callout(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(auth.isSignedIn
                         ? "Signed in\(auth.displayName.map { " as \($0)" } ?? "")"
                         : "Sign in to use AI features")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Spacer()
                if auth.isSignedIn {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.success)
                }
            }

            if auth.isSignedIn {
                Button {
                    HapticManager.shared.warning()
                    isSigningOut = true
                    Task {
                        await AuthService.shared.signOut()
                        isSigningOut = false
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        if isSigningOut {
                            ProgressView().tint(AppTheme.Colors.error).scaleEffect(0.8)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(AppTheme.Typography.footnote(weight: .semibold))
                        }
                        Text("Sign Out")
                            .font(AppTheme.Typography.subheadline(weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg),
                                 fallback: AppTheme.Colors.surfaceHighlight)
                }
                .disabled(isSigningOut)
            } else {
                SignInBlock()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }

    // MARK: - AI features

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md),
                                 fallback: AppTheme.Colors.surfaceHighlight)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Features")
                        .font(AppTheme.Typography.callout(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Nutrition analysis & meal plans")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Spacer()
            }

            Text("AI nutrition analysis and meal plans are powered by CallyFS servers. There's nothing to set up — these features work automatically.")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }
}

// MARK: - Sign-in block (shared by Settings and onboarding)

/// The app's auth entry point: email/password (always available) plus Sign in
/// with Apple once `APIConfig.appleSignInEnabled` is flipped on.
struct SignInBlock: View {
    var prefillName: String = ""
    var onSignedIn: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            EmailSignInBlock(prefillName: prefillName, onSignedIn: onSignedIn)
            if APIConfig.appleSignInEnabled {
                AppleSignInBlock(onSignedIn: onSignedIn)
            }
        }
    }
}

/// Email/password sign-in and account creation against the backend
/// (POST /v1/auth/login and /v1/auth/register).
struct EmailSignInBlock: View {
    var prefillName: String = ""
    var onSignedIn: (() -> Void)? = nil

    private enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case register = "Create Account"
    }

    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 8
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            if mode == .register {
                authField {
                    TextField("Name (optional)", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }
            }

            authField {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            authField {
                SecureField("Password (min 8 characters)", text: $password)
                    .textContentType(mode == .register ? .newPassword : .password)
            }

            Button {
                submit()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if isSubmitting {
                        ProgressView().tint(AppTheme.Colors.background).scaleEffect(0.8)
                    }
                    Text(mode.rawValue)
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                }
                .foregroundColor(AppTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .fill(AppTheme.Colors.textPrimary)
                        .opacity(isFormValid && !isSubmitting ? 1 : 0.4)
                )
            }
            .disabled(!isFormValid || isSubmitting)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            if name.isEmpty { name = prefillName }
        }
    }

    private func authField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(AppTheme.Typography.subheadline())
            .foregroundColor(AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(AppTheme.Colors.surfaceHighlight)
            )
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                switch mode {
                case .signIn:
                    try await AuthService.shared.login(email: trimmedEmail, password: password)
                case .register:
                    try await AuthService.shared.register(
                        email: trimmedEmail,
                        password: password,
                        displayName: name
                    )
                }
                isSubmitting = false
                HapticManager.shared.success()
                onSignedIn?()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Apple Sign-In block (shared by Settings and onboarding)

/// Sign in with Apple button wired to the backend session exchange. On success
/// `AuthService.shared` flips to signed-in, which any observing view picks up.
struct AppleSignInBlock: View {
    var onSignedIn: (() -> Void)? = nil

    @State private var isExchanging = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .overlay {
                if isExchanging {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .fill(Color.black.opacity(0.35))
                    ProgressView().tint(.white)
                }
            }
            .disabled(isExchanging)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            // The user closing the sheet isn't an error worth surfacing.
            if let authError = error as? ASAuthorizationError, authError.code == .canceled { return }
            errorMessage = "Sign in didn't complete. Please try again."
            HapticManager.shared.error()

        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  let codeData = credential.authorizationCode,
                  let authorizationCode = String(data: codeData, encoding: .utf8)
            else {
                errorMessage = "Couldn't read your Apple credentials. Please try again."
                HapticManager.shared.error()
                return
            }

            errorMessage = nil
            isExchanging = true
            Task {
                do {
                    try await AuthService.shared.signIn(
                        identityToken: identityToken,
                        authorizationCode: authorizationCode,
                        fullName: credential.fullName
                    )
                    isExchanging = false
                    HapticManager.shared.success()
                    onSignedIn?()
                } catch {
                    isExchanging = false
                    errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
