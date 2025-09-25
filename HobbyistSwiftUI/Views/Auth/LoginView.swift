import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
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

    let onLoginSuccess: () -> Void

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
                VStack(spacing: 16) {
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
                        .frame(maxWidth: .infinity)
                        .padding()
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
                        .shadow(color: formIsValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(supabaseService.isLoading || !formIsValid)
                    .scaleEffect(supabaseService.isLoading ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3), value: supabaseService.isLoading)

                    // Apple Sign In Button (only for sign in)
                    if !isSignUp {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.email, .fullName]
                            },
                            onCompletion: handleAppleSignIn
                        )
                        .frame(height: 50)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
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
                    // Successful login
                    onLoginSuccess()
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
        // This would integrate with AuthenticationManager's Apple Sign In method
        // For now, we'll use the simpler approach
        alertTitle = "Apple Sign In"
        alertMessage = "Apple Sign In integration coming soon! Please use email sign in for now."
        showAlert = true
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
        LoginView(onLoginSuccess: {})
    }
}