import SwiftUI
import Combine

// MARK: - LoginView Haptic Integration Example
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var loginAttempts = 0
    
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and Welcome Text
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onTapGesture {
                            // Haptic: Field focus feedback
                            hapticService.playFormFieldFocus()
                        }
                        .onChange(of: email) { _ in
                            // Clear any previous validation errors
                            viewModel.emailError = nil
                        }
                    
                    if let error = viewModel.emailError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .onAppear {
                                // Haptic: Validation error feedback
                                hapticService.playFormValidationError()
                            }
                    }
                }
                .padding(.horizontal)
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                            // Haptic: Toggle feedback
                            hapticService.playFormFieldFocus()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        // Haptic: Field focus feedback
                        hapticService.playFormFieldFocus()
                    }
                    
                    if let error = viewModel.passwordError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .onAppear {
                                // Haptic: Validation error feedback
                                hapticService.playFormValidationError()
                            }
                    }
                }
                .padding(.horizontal)
                
                // Forgot Password
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Haptic: Selection feedback
                        hapticService.playFormFieldFocus()
                        viewModel.showForgotPassword()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Login Button
                Button(action: performLogin) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!isFormValid || viewModel.isLoading)
                }
                .padding(.horizontal)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Social Login Options
                VStack(spacing: 12) {
                    SocialLoginButton(
                        title: "Continue with Apple",
                        icon: "applelogo",
                        action: {
                            hapticService.playFormFieldFocus()
                            viewModel.signInWithApple()
                        }
                    )
                    
                    SocialLoginButton(
                        title: "Continue with Google",
                        icon: "globe",
                        action: {
                            hapticService.playFormFieldFocus()
                            viewModel.signInWithGoogle()
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        hapticService.playFormFieldFocus()
                        viewModel.showSignUp()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .font(.footnote)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(viewModel.$loginState) { state in
                handleLoginStateChange(state)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func performLogin() {
        // Validate form first
        guard isFormValid else {
            hapticService.playFormValidationError()
            return
        }
        
        // Prepare haptics for result
        hapticService.prepareHaptics()
        
        // Perform login
        viewModel.login(email: email, password: password)
        loginAttempts += 1
    }
    
    private func handleLoginStateChange(_ state: LoginState) {
        switch state {
        case .idle:
            break
            
        case .loading:
            // Could play a subtle loading haptic here
            break
            
        case .success:
            // Haptic: Success celebration
            hapticService.playLoginSuccess()
            
        case .failure(let error):
            // Haptic: Failure feedback with intensity based on attempts
            hapticService.playLoginFailure()
            
            // Additional haptic if multiple failures
            if loginAttempts >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hapticService.playFormValidationError()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct SocialLoginButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - View Model
class LoginViewModel: ObservableObject {
    @Published var loginState: LoginState = .idle
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var emailError: String?
    @Published var passwordError: String?
    
    func login(email: String, password: String) {
        isLoading = true
        loginState = .loading
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            
            // Simulate validation
            if email == "test@example.com" && password == "password123" {
                self?.loginState = .success
            } else {
                self?.loginState = .failure("Invalid email or password")
                self?.errorMessage = "Invalid email or password"
                self?.showError = true
            }
        }
    }
    
    func signInWithApple() {
        // Apple Sign In implementation
    }
    
    func signInWithGoogle() {
        // Google Sign In implementation
    }
    
    func showSignUp() {
        // Navigate to sign up
    }
    
    func showForgotPassword() {
        // Show forgot password flow
    }
}

enum LoginState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
    
    static func == (lhs: LoginState, rhs: LoginState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            return true
        case (.failure(let l), .failure(let r)):
            return l == r
        default:
            return false
        }
    }
}