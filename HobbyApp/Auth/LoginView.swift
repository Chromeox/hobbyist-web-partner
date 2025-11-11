import SwiftUI
import FacebookLogin
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
    @State private var showPhoneAuth = false
    @State private var hasAttemptedAutoLogin = false
    @State private var showQuickLoginOptions = false
    @State private var agreedToTerms = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
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

            // Subtle background texture for visual interest without distraction
            Circle()
                .fill(BrandConstants.Colors.surface.opacity(0.02))
                .frame(width: 300, height: 300)
                .offset(x: 0, y: -200)
                .accessibilityHidden(true)

            NavigationStack {
                ScrollView {
                    VStack(spacing: BrandConstants.Spacing.lg) {
                    Spacer(minLength: BrandConstants.Spacing.md)

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
                                .accessibilityHidden(true)

                            // Inner gradient circle
                            Circle()
                                .fill(LinearGradient(
                                    colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .accessibilityHidden(true)

                            // Large background icon
                            Image(systemName: "figure.yoga")
                                .font(BrandConstants.Typography.largeTitle).fontWeight(.ultraLight)
                                .foregroundColor(BrandConstants.Colors.surface.opacity(0.3))
                                .offset(x: 5, y: 5)
                                .accessibilityHidden(true)

                            // Foreground icon
                            Image(systemName: "figure.yoga")
                                .font(BrandConstants.Typography.largeTitle).fontWeight(.light)
                                .foregroundColor(BrandConstants.Colors.surface)
                                .accessibilityHidden(true)
                        }
                        .accessibilityLabel("HobbyApp logo")
                        .accessibilityHint("App logo for HobbyApp")

                        VStack(spacing: 8) {
                            Text(isSignUp ? "Get Started" : "Welcome Back!")
                                .font(BrandConstants.Typography.title1)
                                .foregroundColor(BrandConstants.Colors.surface)
                                .accessibilityAddTraits(.isHeader)

                            Text(isSignUp ? "Create your account" : "Sign in to continue")
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(BrandConstants.Colors.surface.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .accessibilityHint(isSignUp ? "Fill out the form below to create a new account" : "Enter your credentials to sign in")
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
                                        .accessibilityHidden(true)
                                    TextField("Full Name", text: $fullName)
                                        .textContentType(.name)
                                        .foregroundColor(BrandConstants.Colors.text)
                                        .focused($focusedField, equals: .fullName)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .email
                                        }
                                        .accessibilityLabel("Full name")
                                        .accessibilityHint("Enter your full name for account creation")
                                }
                                .padding(14)
                                .background(BrandConstants.Colors.background)
                                .cornerRadius(BrandConstants.CornerRadius.md)
                            }

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
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
                                    .accessibilityLabel("Email address")
                                    .accessibilityHint("Enter your email address")
                            }
                            .padding(14)
                            .background(BrandConstants.Colors.background)
                            .cornerRadius(BrandConstants.CornerRadius.md)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
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
                                    .accessibilityLabel("Password")
                                    .accessibilityHint(isSignUp ? "Enter a password with at least 6 characters" : "Enter your password")
                            }
                            .padding(14)
                            .background(BrandConstants.Colors.background)
                            .cornerRadius(BrandConstants.CornerRadius.md)
                        }

                        // Forgot Password Button (only for sign in)
                        if !isSignUp {
                            HStack {
                                Spacer()
                                TextButton("Forgot Password?", color: BrandConstants.Colors.teal) {
                                    resetEmail = email
                                    showPasswordReset = true
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        ZStack {
                            // Enhanced glassmorphic background for calming effect
                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                .fill(BrandConstants.Colors.surface.opacity(0.15))
                                .background(.ultraThinMaterial)
                                .cornerRadius(BrandConstants.CornerRadius.lg)

                            // Softer border for reduced visual tension
                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                .strokeBorder(BrandConstants.Colors.surface.opacity(0.2), lineWidth: 0.5)
                        }
                        .shadow(color: BrandConstants.Colors.text.opacity(0.08), radius: 16, x: 0, y: 8)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)

                // Validation hints
                if !email.isEmpty && !isValidEmail(email) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BrandConstants.Colors.warning)
                            .accessibilityHidden(true)
                        Text("Please enter a valid email address")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.warning)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Error: Please enter a valid email address")
                    .accessibilityAddTraits(.isStaticText)
                }

                if isSignUp && !password.isEmpty && password.count < 6 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BrandConstants.Colors.warning)
                            .accessibilityHidden(true)
                        Text("Password must be at least 6 characters")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.warning)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Error: Password must be at least 6 characters")
                    .accessibilityAddTraits(.isStaticText)
                }

                // Terms and Privacy Agreement (Sign Up only)
                if isSignUp {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                                HapticFeedbackService.shared.playLight()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(BrandConstants.Typography.title3)
                                    .foregroundColor(agreedToTerms ? BrandConstants.Colors.primary : BrandConstants.Colors.secondaryText)
                            }
                            .accessibilityLabel(agreedToTerms ? "Terms accepted" : "Terms not accepted")
                            .accessibilityAddTraits(.isButton)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                                
                                HStack(spacing: 4) {
                                    Button("Terms of Service") {
                                        showTermsSheet = true
                                    }
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.teal)
                                    .underline()
                                    
                                    Text("and")
                                        .font(BrandConstants.Typography.caption)
                                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                                    
                                    Button("Privacy Policy") {
                                        showPrivacySheet = true
                                    }
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.teal)
                                    .underline()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Terms agreement: \(agreedToTerms ? "accepted" : "not accepted"). Tap to toggle agreement or view terms.")
                }

                    // Enhanced Action Buttons Section - Optimized for Alpha Testing
                    VStack(spacing: BrandConstants.Spacing.lg) {
                            // Main Action Button - Using BrandedButton style
                            BrandedButton(
                                isSignUp ? "Create Account" : "Sign In",
                                icon: "arrow.right.circle.fill",
                                isLoading: supabaseService.isLoading,
                                isDisabled: !formIsValid
                            ) {
                                performAuthentication()
                            }

                            // Quick Continue Button for returning users
                            if !isSignUp && showQuickLoginOptions && !email.isEmpty {
                                BrandedButton(
                                    "Continue as \(email.components(separatedBy: "@").first?.capitalized ?? "User")",
                                    icon: "person.circle.fill",
                                    gradient: BrandConstants.Gradients.primary,
                                    isLoading: supabaseService.isLoading
                                ) {
                                    if biometricService.canUseBiometrics() {
                                        performBiometricAuthentication()
                                    } else {
                                        // Focus on password field for quick entry
                                        focusedField = .password
                                    }
                                }
                            }

                            // Face ID Button - Prominent for auto-login
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
                                    .frame(maxWidth: .infinity, minHeight: 54)
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
                                .frame(maxWidth: .infinity, minHeight: 54)
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
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundColor(BrandConstants.Colors.text)
                                .background(BrandConstants.Colors.surface.opacity(0.95))
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                        .stroke(BrandConstants.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(supabaseService.isLoading)

                            // Facebook Sign In Button - Blue branded style
                            Button(action: {
                                print("📘 Facebook Sign In button tapped!")
                                performFacebookSignIn()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "f.square.fill")
                                        .font(BrandConstants.Typography.title3).fontWeight(.medium)

                                    Text(isSignUp ? "Sign up with Facebook" : "Sign in with Facebook")
                                        .font(BrandConstants.Typography.body).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundColor(BrandConstants.Colors.surface)
                                .background(Color(red: 0.255, green: 0.412, blue: 0.882)) // Facebook Blue
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                            }
                            .disabled(supabaseService.isLoading)

                            // Phone Number Sign In Button - Teal outlined
                            Button(action: {
                                print("📱 Phone Number Sign In button tapped!")
                                performPhoneSignIn()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(BrandConstants.Typography.title3).fontWeight(.medium)

                                    Text(isSignUp ? "Sign up with Phone" : "Sign in with Phone")
                                        .font(BrandConstants.Typography.body).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundColor(BrandConstants.Colors.teal)
                                .background(BrandConstants.Colors.surface.opacity(0.95))
                                .cornerRadius(BrandConstants.CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                        .stroke(BrandConstants.Colors.teal, lineWidth: 2)
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
                                    .foregroundColor(BrandConstants.Colors.surface.opacity(0.8))
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(BrandConstants.Colors.surface.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal)

                            // Toggle Button - TextButton style
                            Button(action: {
                                withAnimation(BrandConstants.Animation.gentleSpring) {
                                    isSignUp.toggle()
                                }
                                withAnimation(BrandConstants.Animation.fast) {
                                    fullName = ""
                                    agreedToTerms = false
                                    focusedField = nil
                                    supabaseService.errorMessage = nil
                                }
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
                }
                .scrollDismissesKeyboard(.interactively)
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
            .fullScreenCover(isPresented: $showPhoneAuth) {
                PhoneAuthView(
                    onSuccess: { isNewUser in
                        showPhoneAuth = false
                        onLoginSuccess(isNewUser)
                    },
                    onCancel: {
                        showPhoneAuth = false
                    }
                )
                .environmentObject(supabaseService)
            }
            .sheet(isPresented: $showTermsSheet) {
                NavigationStack {
                    TermsOfServiceView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTermsSheet = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showPrivacySheet) {
                NavigationStack {
                    PrivacyPolicyView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showPrivacySheet = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            withAnimation(BrandConstants.Animation.gentleSpring.delay(0.1)) {
                // Subtle entrance animation for calming effect
            }
            attemptAutoLogin()
        }
    }

    // MARK: - Auto-Login Implementation
    
    private func attemptAutoLogin() {
        guard !hasAttemptedAutoLogin else { return }
        hasAttemptedAutoLogin = true
        
        print("🚀 Attempting auto-login...")
        
        // Pre-populate email field with last successful login
        if let lastEmail = biometricService.getLastUserEmail() {
            email = lastEmail
            print("📧 Pre-populated email: \(lastEmail)")
        }
        
        // Attempt automatic biometric authentication if available
        if biometricService.canUseBiometricsIndependently() {
            print("🔐 Attempting automatic biometric authentication...")
            Task {
                // Small delay to allow UI to settle
                try? await Task.sleep(nanoseconds: 500_000_000)
                performBiometricAuthentication()
            }
        } else {
            // Show quick login options for returning users
            showQuickLoginOptions = !email.isEmpty
            print("⚡ Showing quick login options for: \(email)")
        }
    }

    private var formIsValid: Bool {
        let emailValid = isValidEmail(email)

        if isSignUp {
            return emailValid && !password.isEmpty && !fullName.isEmpty && password.count >= 6 && agreedToTerms
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
                            biometricService.saveLastAuthenticationMethod("biometric")
                            HapticFeedbackService.shared.playSuccess()
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
                        biometricService.saveLastAuthenticationMethod("biometric")
                        HapticFeedbackService.shared.playSuccess()
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
                        biometricService.saveLastAuthenticationMethod("email")
                        HapticFeedbackService.shared.playSuccess()
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
                    biometricService.saveLastAuthenticationMethod("email")
                    HapticFeedbackService.shared.playSuccess()
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

    // MARK: - Facebook Sign In Handler
    private func performFacebookSignIn() {
        print("📘 Starting Facebook Sign In flow")
        
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["email", "public_profile"], from: nil) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Facebook Sign In error: \(error.localizedDescription)")
                    self?.alertTitle = "Facebook Sign In Failed"
                    self?.alertMessage = error.localizedDescription
                    self?.showAlert = true
                    return
                }
                
                guard let result = result, !result.isCancelled else {
                    print("🔵 Facebook Sign In cancelled by user")
                    return
                }
                
                if let token = result.token?.tokenString {
                    print("✅ Facebook Sign In successful")
                    Task {
                        await self?.handleFacebookSignIn(accessToken: token)
                    }
                } else {
                    print("❌ Failed to get Facebook access token")
                    self?.alertTitle = "Facebook Sign In Failed"
                    self?.alertMessage = "Failed to get authentication token"
                    self?.showAlert = true
                }
            }
        }
    }
    
    private func handleFacebookSignIn(accessToken: String) async {
        print("📘 Processing Facebook Sign In with Supabase...")
        
        // Integrate with Supabase Facebook auth
        await supabaseService.signInWithFacebook(accessToken: accessToken)
        
        DispatchQueue.main.async {
            if let errorMessage = self.supabaseService.errorMessage {
                self.alertTitle = "Facebook Sign In Failed"
                self.alertMessage = errorMessage
                self.showAlert = true
            } else if self.supabaseService.isAuthenticated {
                // Determine if this is a new user by checking if we have user preferences
                Task {
                    let hasPreferences = await self.supabaseService.fetchUserPreferences() != nil
                    self.biometricService.saveLastAuthenticationMethod("facebook")
                    HapticFeedbackService.shared.playSuccess()
                    self.onLoginSuccess(!hasPreferences) // true if new user (no preferences)
                }
            }
        }
    }
    
    // MARK: - Phone Number Sign In Handler
    private func performPhoneSignIn() {
        print("📱 Starting Phone Number Sign In flow")
        showPhoneAuth = true
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

        // Integrate with Supabase Google auth
        await supabaseService.signInWithGoogle(idToken: idToken, user: user)

        DispatchQueue.main.async {
            if let errorMessage = self.supabaseService.errorMessage {
                self.alertTitle = "Google Sign In Failed"
                self.alertMessage = errorMessage
                self.showAlert = true
            } else if self.supabaseService.isAuthenticated {
                // Determine if this is a new user by checking if we have user preferences
                Task {
                    let hasPreferences = await self.supabaseService.fetchUserPreferences() != nil
                    self.biometricService.saveLastAuthenticationMethod("google")
                    HapticFeedbackService.shared.playSuccess()
                    self.onLoginSuccess(!hasPreferences) // true if new user (no preferences)
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
            biometricService.saveLastAuthenticationMethod("apple")
            HapticFeedbackService.shared.playSuccess()
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