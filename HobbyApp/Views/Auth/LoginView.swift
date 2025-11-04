import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var biometricService = BiometricAuthenticationService.shared
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showPasswordReset = false
    @State private var resetEmail = ""
    @State private var showingPasswordResetAlert = false
    @FocusState private var focusedField: Field?

    let onLoginSuccess: (Bool) -> Void // Bool indicates if this is a new user (true) or returning user (false)

    enum Field: Hashable {
        case fullName, email, password
    }

    var body: some View {
        ZStack {
            // Brand gradient background
            BrandConstants.Gradients.landing
                .ignoresSafeArea()

            // Decorative floating circles
            Circle()
                .fill(BrandConstants.Colors.surface.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -300)

            Circle()
                .fill(BrandConstants.Colors.surface.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 150, y: -400)

            Circle()
                .fill(BrandConstants.Colors.surface.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 100, y: 450)

            NavigationStack {
                VStack(spacing: 20) {
                    Spacer(minLength: 20)

                    // Enhanced Logo Section - Compact
                    VStack(spacing: 16) {
                        // Logo with brand gradient background and pulsing animation
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .fill(LinearGradient(
                                    colors: [BrandConstants.Colors.surface.opacity(0.2), BrandConstants.Colors.surface.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)

                            // Inner gradient circle
                            Circle()
                                .fill(LinearGradient(
                                    colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)

                            // Large background icon
                            Image(systemName: "figure.yoga")
                                .font(BrandConstants.Typography.largeTitle).fontWeight(.ultraLight)
                                .foregroundColor(BrandConstants.Colors.surface.opacity(0.3))
                                .offset(x: 5, y: 5)

                            // Foreground icon
                            Image(systemName: "figure.yoga")
                                .font(BrandConstants.Typography.largeTitle).fontWeight(.light)
                                .foregroundColor(BrandConstants.Colors.surface)
                        }

                        VStack(spacing: 8) {
                            Text(isSignUp ? "Get Started" : "Welcome Back!")
                                .font(BrandConstants.Typography.title1)
                                .foregroundColor(BrandConstants.Colors.surface)

                            Text(isSignUp ? "Create your account" : "Sign in to continue")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Glassmorphic Form Card - Compact
                    VStack(spacing: 14) {
                        VStack(spacing: 12) {
                            if isSignUp {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(BrandConstants.Colors.primary)
                                        .frame(width: 24)
                                    TextField("Full Name", text: $fullName)
                                        .textContentType(.name)
                                        .foregroundColor(BrandConstants.Colors.text)
                                        .focused($focusedField, equals: .fullName)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .email
                                        }
                                }
                                .padding(14)
                                .background(BrandConstants.Colors.background)
                                .cornerRadius(BrandConstants.CornerRadius.md)
                            }

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 24)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundColor(BrandConstants.Colors.text)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(BrandConstants.CornerRadius.md)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 24)
                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .foregroundColor(BrandConstants.Colors.text)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        if formIsValid {
                                            performAuthentication()
                                        }
                                    }
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(BrandConstants.CornerRadius.md)
                        }

                        // Forgot Password Button (only for sign in)
                        if !isSignUp {
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    resetEmail = email
                                    showPasswordReset = true
                                }
                                .font(BrandConstants.Typography.footnote)
                                .foregroundColor(BrandConstants.Colors.teal)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        ZStack {
                            // Glassmorphic background with blur effect
                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                .fill(BrandConstants.Colors.surface.opacity(0.18))
                                .background(.ultraThinMaterial)
                                .cornerRadius(BrandConstants.CornerRadius.lg)

                            // Subtle border
                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                .strokeBorder(BrandConstants.Colors.surface.opacity(0.3), lineWidth: 1)
                        }
                        .shadow(color: BrandConstants.Colors.text.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)

                // Validation hints
                if !email.isEmpty && !isValidEmail(email) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BrandConstants.Colors.warning)
                        Text("Please enter a valid email address")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.warning)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                if isSignUp && !password.isEmpty && password.count < 6 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BrandConstants.Colors.warning)
                        Text("Password must be at least 6 characters")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.warning)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                    // Enhanced Action Buttons Section - Compact
                    VStack(spacing: 10) {
                            // Main Action Button - Using BrandedButton style
                            Button(action: {
                                performAuthentication()
                            }) {
                                HStack(spacing: 12) {
                                    if supabaseService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: BrandConstants.Colors.surface))
                                            .scaleEffect(0.8)
                                    }

                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(BrandConstants.Typography.body).fontWeight(.semibold)

                                    if !supabaseService.isLoading {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(BrandConstants.Typography.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundColor(BrandConstants.Colors.surface)
                                .background(
                                    formIsValid && !supabaseService.isLoading ?
                                        BrandConstants.Gradients.primary :
                                        LinearGradient(
                                            colors: [BrandConstants.Colors.secondaryText, BrandConstants.Colors.secondaryText.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                                .shadow(
                                    color: formIsValid ? BrandConstants.Colors.primary.opacity(0.3) : .clear,
                                    radius: 8,
                                    y: 4
                                )
                            }
                            .disabled(supabaseService.isLoading || !formIsValid)
                            .scaleEffect(supabaseService.isLoading ? 0.95 : 1.0)
                            .animation(BrandConstants.Animation.spring, value: supabaseService.isLoading)

                            // Face ID Button - OutlineButton style
                            let _ = print("🔐 Face ID condition check - isSignUp: \(isSignUp), canUseBiometricsIndependently: \(biometricService.canUseBiometricsIndependently())")
                            if !isSignUp && (biometricService.canUseBiometricsIndependently() || (!email.isEmpty && biometricService.canUseBiometrics())) {
                                Button(action: {
                                    performBiometricAuthentication()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: biometricService.biometricType == .faceID ? "faceid" : "touchid")
                                            .font(BrandConstants.Typography.title3)

                                        if biometricService.canUseBiometricsIndependently(), let lastUser = biometricService.getLastUserEmail() {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Sign in with \(biometricService.biometricTypeDescription())")
                                                    .font(BrandConstants.Typography.subheadline)
                                                    .fontWeight(.semibold)
                                                Text("as \(lastUser)")
                                                    .font(BrandConstants.Typography.caption)
                                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                                            }
                                        } else {
                                            Text("Sign in with \(biometricService.biometricTypeDescription())")
                                                .font(BrandConstants.Typography.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(BrandConstants.CornerRadius.lg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                            .stroke(BrandConstants.Colors.primary, lineWidth: 2)
                                    )
                                }
                                .disabled(supabaseService.isLoading)
                            }

                            // Custom Apple Sign In Button - Black branded style
                            let _ = print("🍎 Apple Sign In button - isSignUp: \(isSignUp), will show: \(isSignUp ? "Sign Up" : "Sign In")")
                            Button(action: {
                                print("🍎 Custom Apple Sign In button tapped!")
                                performCustomAppleSignIn()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "applelogo")
                                        .font(BrandConstants.Typography.title3).fontWeight(.medium)

                                    Text(isSignUp ? "Sign up with Apple" : "Sign in with Apple")
                                        .font(BrandConstants.Typography.body).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundColor(BrandConstants.Colors.surface)
                                .background(BrandConstants.Colors.text)
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                            }
                            .disabled(supabaseService.isLoading)

                            // Google Sign In Button - White outlined
                            Button(action: {
                                print("🔵 Google Sign In button tapped!")
                                performGoogleSignIn()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .font(BrandConstants.Typography.title3).fontWeight(.medium)

                                    Text(isSignUp ? "Sign up with Google" : "Sign in with Google")
                                        .font(BrandConstants.Typography.body).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundColor(BrandConstants.Colors.text)
                                .background(BrandConstants.Colors.surface.opacity(0.95))
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                        .stroke(BrandConstants.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(supabaseService.isLoading)
                        }
                        .padding(.horizontal, BrandConstants.Spacing.md)

                    // Enhanced Toggle Section - Compact
                    VStack(spacing: 10) {
                            // Divider with "or"
                            HStack {
                                Rectangle()
                                    .fill(BrandConstants.Colors.surface.opacity(0.3))
                                    .frame(height: 1)

                                Text("or")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.surface.opacity(0.7))
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(BrandConstants.Colors.surface.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal)

                            // Toggle Button - TextButton style
                            Button(action: {
                                withAnimation(BrandConstants.Animation.spring) {
                                    isSignUp.toggle()
                                }
                                fullName = ""
                                focusedField = nil
                                supabaseService.errorMessage = nil
                            }) {
                                HStack {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .font(BrandConstants.Typography.subheadline)
                                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.8))

                                    Text(isSignUp ? "Sign In" : "Sign Up")
                                        .font(BrandConstants.Typography.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(BrandConstants.Colors.teal)
                                        .underline()
                                }
                            }
                        }

                    Spacer(minLength: 24)
                }
                .onTapGesture {
                    focusedField = nil
                }
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Allow simultaneous gestures for Apple Sign In button
                        }
                )
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("Reset Password", isPresented: $showPasswordReset) {
                TextField("Email", text: $resetEmail)
                Button("Send Reset Link") {
                    performPasswordReset()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your email address to receive a password reset link")
            }
            .alert("Password Reset", isPresented: $showingPasswordResetAlert) {
                Button("OK") { }
            } message: {
                Text("If an account with that email exists, we've sent you a password reset link")
            }
        }
    }

    private var formIsValid: Bool {
        let emailValid = isValidEmail(email)

        if isSignUp {
            return emailValid && !password.isEmpty && !fullName.isEmpty && password.count >= 6
        } else {
            return emailValid && !password.isEmpty
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func performBiometricAuthentication() {
        print("🔐 Face ID button tapped!")
        print("🔐 Email: '\(email)'")
        print("🔐 Can use biometrics independently: \(biometricService.canUseBiometricsIndependently())")
        print("🔐 Biometric type: \(biometricService.biometricType)")

        Task {
            let success = await biometricService.authenticateWithBiometrics(
                reason: "Sign in to HobbyApp with \(biometricService.biometricTypeDescription())"
            )

            if success {
                // Try independent authentication first (using stored session)
                if biometricService.canUseBiometricsIndependently(),
                   let lastUserEmail = biometricService.getLastUserEmail(),
                   let sessionToken = biometricService.getStoredSessionToken(for: lastUserEmail) {

                    print("🔐 Using stored session for independent biometric sign in")
                    // TODO: Implement session restoration with Supabase
                    // For now, use stored credentials as fallback
                    if let storedPassword = biometricService.getStoredCredentials(for: lastUserEmail) {
                        await supabaseService.signIn(email: lastUserEmail, password: storedPassword)

                        if let _ = supabaseService.errorMessage {
                            // Session/credentials expired, clean up and request normal login
                            biometricService.deleteStoredSession(for: lastUserEmail)
                            biometricService.deleteStoredCredentials(for: lastUserEmail)
                            alertTitle = "Session Expired"
                            alertMessage = "Please sign in with your email and password to update your saved authentication."
                            showAlert = true
                        } else if supabaseService.isAuthenticated {
                            print("✅ Independent biometric authentication successful")
                            onLoginSuccess(false) // Existing user
                        }
                    } else {
                        // No fallback credentials available
                        biometricService.deleteStoredSession(for: lastUserEmail)
                        alertTitle = "Authentication Required"
                        alertMessage = "Please sign in with your email and password to refresh your saved authentication."
                        showAlert = true
                    }
                }
                // Fallback to email-based credential authentication
                else if !email.isEmpty, let storedPassword = biometricService.getStoredCredentials(for: email) {
                    print("🔐 Using email-based stored credentials for biometric sign in")
                    await supabaseService.signIn(email: email, password: storedPassword)

                    if let _ = supabaseService.errorMessage {
                        // If stored credentials failed, prompt user to sign in normally
                        alertTitle = "Credentials Updated"
                        alertMessage = "Please sign in with your current password to update your saved credentials."
                        showAlert = true
                        biometricService.deleteStoredCredentials(for: email)
                    } else if supabaseService.isAuthenticated {
                        onLoginSuccess(false) // Existing user
                    }
                } else {
                    // No stored authentication available
                    if email.isEmpty && !biometricService.hasStoredUser() {
                        alertTitle = "Email Required"
                        alertMessage = "Please enter your email address to sign in with \(biometricService.biometricTypeDescription())."
                    } else {
                        alertTitle = "No Saved Credentials"
                        alertMessage = "Please sign in with your password first to enable \(biometricService.biometricTypeDescription()) for future logins."
                    }
                    showAlert = true
                }
            }
        }
    }

    private func performAuthentication() {
        focusedField = nil // Dismiss keyboard

        Task {
            if isSignUp {
                await supabaseService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )

                if let errorMessage = supabaseService.errorMessage {
                    // Show error alert
                    alertTitle = "Signup Failed"
                    alertMessage = errorMessage
                    showAlert = true
                } else {
                    // Check if user is immediately authenticated (no email verification required)
                    if supabaseService.isAuthenticated {
                        // Successful signup with immediate authentication - new user
                        onLoginSuccess(true)
                    } else {
                        // Show success alert with email verification instructions
                        alertTitle = "Account Created!"
                        alertMessage = "Please check your email (\(email)) for a verification link before signing in."
                        showAlert = true

                        // Switch to login mode after successful signup
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isSignUp = false
                            fullName = ""
                            password = ""
                        }
                    }
                }
            } else {
                await supabaseService.signIn(
                    email: email,
                    password: password
                )

                if let errorMessage = supabaseService.errorMessage {
                    // Show error alert
                    alertTitle = "Login Failed"
                    alertMessage = errorMessage
                    showAlert = true
                } else if supabaseService.isAuthenticated {
                    // Successful login - save both credentials and session for biometric auth
                    if biometricService.canUseBiometrics() {
                        let credentialsSaved = biometricService.saveCredentials(email: email, password: password)
                        let sessionSaved = biometricService.saveLastUserSession(email: email, sessionToken: "placeholder_session_token")

                        if credentialsSaved && sessionSaved {
                            print("✅ Credentials and session saved for biometric authentication")
                        }
                    }

                    // Successful login - returning user
                    onLoginSuccess(false)
                }
            }
        }
    }

    // MARK: - Custom Apple Sign In Handler
    private func performCustomAppleSignIn() {
        print("🍎 Starting custom Apple Sign In flow")

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = appleSignInCoordinator
        authorizationController.presentationContextProvider = appleSignInCoordinator

        // Set up the completion handler
        appleSignInCoordinator.completion = { result in
            DispatchQueue.main.async {
                self.handleAppleSignIn(result: result)
            }
        }

        authorizationController.performRequests()
    }

    // MARK: - Google Sign In Handler
    private func performGoogleSignIn() {
        print("🔵 Starting Google Sign In flow")

        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("❌ Could not find presenting view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                print("❌ Google Sign In error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.alertTitle = "Google Sign In Failed"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
                return
            }

            guard let result = result,
                  let idToken = result.user.idToken?.tokenString else {
                print("❌ Failed to get Google ID token")
                DispatchQueue.main.async {
                    self.alertTitle = "Google Sign In Failed"
                    self.alertMessage = "Failed to get authentication token"
                    self.showAlert = true
                }
                return
            }

            print("✅ Google Sign In successful")
            print("🔵 User email: \(result.user.profile?.email ?? "No email")")
            print("🔵 User name: \(result.user.profile?.name ?? "No name")")

            Task {
                await self.handleGoogleSignIn(idToken: idToken, user: result.user)
            }
        }
    }

    private func handleGoogleSignIn(idToken: String, user: GIDGoogleUser) async {
        print("🔵 Processing Google Sign In with Supabase...")

        // Here you would integrate with your Supabase service
        // For now, let's just show success
        DispatchQueue.main.async {
            self.alertTitle = "Google Sign In Success!"
            self.alertMessage = "Successfully signed in with Google. Integration with Supabase coming next!"
            self.showAlert = true
        }

        // TODO: Add Supabase Google auth integration
        // await supabaseService.signInWithGoogle(idToken: idToken)
    }

    // MARK: - Apple Sign In Handler
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await performAppleSignIn(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            alertTitle = "Apple Sign In Failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func performAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        await supabaseService.signInWithApple(credential: credential)

        if let errorMessage = supabaseService.errorMessage {
            alertTitle = "Apple Sign In Failed"
            alertMessage = errorMessage
            showAlert = true
        } else if supabaseService.isAuthenticated {
            // Determine if this is a new user by checking if we have user preferences
            let hasPreferences = await supabaseService.fetchUserPreferences() != nil
            onLoginSuccess(!hasPreferences) // true if new user (no preferences)
        }
    }

    // MARK: - Password Reset
    private func performPasswordReset() {
        guard !resetEmail.isEmpty, isValidEmail(resetEmail) else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }

        Task {
            // Here we would call the actual password reset method
            // For now, show success message
            showingPasswordResetAlert = true
        }
    }
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    var completion: ((Result<ASAuthorization, Error>) -> Void)?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple Sign In authorization completed successfully")
        completion?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Apple Sign In authorization failed with error: \(error)")
        completion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginSuccess: { _ in })
    }
}