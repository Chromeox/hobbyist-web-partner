import SwiftUI

struct LoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @FocusState private var focusedField: Field?

    let onLoginSuccess: () -> Void

    enum Field: Hashable {
        case fullName, email, password
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Hobbyist")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                            .focused($focusedField, equals: .fullName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            if formIsValid {
                                performAuthentication()
                            }
                        }
                }
                .padding(.horizontal)

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

                // Action Button
                Button(isSignUp ? "Create Account" : "Sign In") {
                    performAuthentication()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(formIsValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(supabaseService.isLoading || !formIsValid)
                .padding(.horizontal)

                // Toggle
                Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                    }
                    fullName = ""
                    focusedField = nil
                    supabaseService.errorMessage = nil
                }
                .foregroundColor(.blue)

                if supabaseService.isLoading {
                    ProgressView(isSignUp ? "Creating account..." : "Signing in...")
                        .padding()
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginSuccess: {})
    }
}