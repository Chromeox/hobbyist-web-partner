import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "figure.yoga")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                            .padding(.top, 40)
                        
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 32)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $viewModel.email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .onChange(of: focusedField) { newValue in
                                    if newValue == .email {
                                        hapticService.playSelection()
                                    }
                                }
                                .onChange(of: viewModel.email) { _ in
                                    viewModel.validateEmail()
                                }
                            
                            if let error = viewModel.emailError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                                    .onAppear {
                                        hapticService.playWarning()
                                    }
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if viewModel.showPassword {
                                    TextField("Enter your password", text: $viewModel.password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $viewModel.password)
                                        .textContentType(.password)
                                }
                                
                                Button {
                                    viewModel.showPassword.toggle()
                                    hapticService.playLight()
                                } label: {
                                    Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedTextFieldStyle())
                            .focused($focusedField, equals: .password)
                            .onChange(of: focusedField) { newValue in
                                if newValue == .password {
                                    hapticService.playSelection()
                                }
                            }
                            
                            if let error = viewModel.passwordError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                                    .onAppear {
                                        hapticService.playWarning()
                                    }
                            }
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                hapticService.playLight()
                                viewModel.showForgotPassword = true
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Login Button
                    Button {
                        Task {
                            hapticService.playMedium()
                            await viewModel.login()
                        }
                    } label: {
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
                        .background(viewModel.isFormValid ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Social Login
                    VStack(spacing: 16) {
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        // Apple Sign In
                        Button {
                            hapticService.playMedium()
                            Task {
                                await viewModel.signInWithApple()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Sign in with Apple")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Google Sign In
                        Button {
                            hapticService.playMedium()
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("Sign in with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            hapticService.playLight()
                        })
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .alert("Login Failed", isPresented: $viewModel.showError) {
                Button("OK") {
                    hapticService.playLight()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordView()
            }
            .onChange(of: viewModel.loginSuccess) { success in
                if success {
                    hapticService.playSuccess()
                }
            }
        }
    }
}

// Custom TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

// Forgot Password View
struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var emailSent = false
    @EnvironmentObject var hapticService: HapticFeedbackService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email and we'll send you a reset link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if !emailSent {
                    VStack(spacing: 16) {
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        Button {
                            hapticService.playMedium()
                            // Send reset email
                            emailSent = true
                            hapticService.playSuccess()
                        } label: {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(email.isEmpty)
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Email Sent!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Check your inbox for the password reset link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            hapticService.playLight()
                            dismiss()
                        } label: {
                            Text("Back to Login")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        hapticService.playLight()
                        dismiss()
                    }
                }
            }
        }
    }
}

// Login ViewModel
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var loginSuccess = false
    @Published var showForgotPassword = false
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && emailError == nil && passwordError == nil
    }
    
    func validateEmail() {
        if email.isEmpty {
            emailError = nil
        } else if !email.contains("@") || !email.contains(".") {
            emailError = "Please enter a valid email"
        } else {
            emailError = nil
        }
    }
    
    func login() async {
        isLoading = true
        
        // Simulate network call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isLoading = false
            // For demo purposes
            if email == "demo@example.com" && password == "password" {
                loginSuccess = true
            } else {
                showError = true
                errorMessage = "Invalid email or password"
            }
        }
    }
    
    func signInWithApple() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            loginSuccess = true
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            loginSuccess = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(HapticFeedbackService.shared)
    }
}