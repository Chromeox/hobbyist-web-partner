import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var biometricService = BiometricAuthenticationService.shared
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
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Enhanced Logo Section
                VStack(spacing: 20) {
                    // Logo with gradient background
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)

                        Image(systemName: "figure.yoga")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }

                    VStack(spacing: 8) {
                        Text("Hobbyist")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(LinearGradient(
                                colors: [.primary, .secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))

                        Text(isSignUp ? "Create your account to discover Vancouver's best hobby classes" : "Welcome back! Let's find your next creative adventure")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }

                // Enhanced Form Section
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        if isSignUp {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                TextField("Full Name", text: $fullName)
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .email
                                    }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    if formIsValid {
                                        performAuthentication()
                                    }
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Forgot Password Button (only for sign in)
                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                resetEmail = email
                                showPasswordReset = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                }

                // Validation hints
                if !email.isEmpty && !isValidEmail(email) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                if isSignUp && !password.isEmpty && password.count < 6 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                // Enhanced Action Buttons Section
                VStack(spacing: 12) {
                    // Main Action Button
                    Button(action: {
                        performAuthentication()
                    }) {
                        HStack {
                            if supabaseService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: isSignUp ? "person.badge.plus" : "person.crop.circle.fill")
                            }

                            Text(isSignUp ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                colors: formIsValid && !supabaseService.isLoading ?
                                    [.blue, .blue.opacity(0.8)] :
                                    [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: formIsValid ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .disabled(supabaseService.isLoading || !formIsValid)
                    .scaleEffect(supabaseService.isLoading ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3), value: supabaseService.isLoading)

                    // Face ID Button (independent authentication)
                    let _ = print("🔐 Face ID condition check - isSignUp: \(isSignUp), canUseBiometricsIndependently: \(biometricService.canUseBiometricsIndependently())")
                    if !isSignUp && (biometricService.canUseBiometricsIndependently() || (!email.isEmpty && biometricService.canUseBiometrics())) {
                        Button(action: {
                            performBiometricAuthentication()
                        }) {
                            HStack {
                                Image(systemName: biometricService.biometricType == .faceID ? "faceid" : "touchid")
                                    .font(.system(size: 18))

                                if biometricService.canUseBiometricsIndependently(), let lastUser = biometricService.getLastUserEmail() {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sign in with \(biometricService.biometricTypeDescription())")
                                            .fontWeight(.medium)
                                        Text("as \(lastUser)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Sign in with \(biometricService.biometricTypeDescription())")
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .disabled(supabaseService.isLoading)
                    }

                    // Apple Sign In Button (adapts to current form state)
                    let _ = print("🍎 Apple Sign In button - isSignUp: \(isSignUp), will show: \(isSignUp ? "Sign Up" : "Sign In")")
                    SignInWithAppleButton(
                        isSignUp ? .signUp : .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.email, .fullName]
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .frame(height: 50)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    .id("apple-sign-in-\(isSignUp ? "signup" : "signin")")
                }
                .padding(.horizontal)

                // Enhanced Toggle Section
                VStack(spacing: 12) {
                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)

                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)

                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Toggle Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                        }
                        fullName = ""
                        focusedField = nil
                        supabaseService.errorMessage = nil
                    }) {
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)

                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .onTapGesture {
                focusedField = nil
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginSuccess: { _ in })
    }
}