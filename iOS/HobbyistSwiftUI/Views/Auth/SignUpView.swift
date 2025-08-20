import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                            .padding(.top, 20)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Join thousands of fitness enthusiasts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 24)
                    
                    // Progress Indicator
                    ProgressBar(progress: viewModel.signUpProgress)
                        .padding(.horizontal)
                        .onChange(of: viewModel.signUpProgress) { oldValue, newValue in
                            if newValue > oldValue {
                                hapticService.playLight()
                            }
                        }
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your full name", text: $viewModel.name)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.name)
                                .focused($focusedField, equals: .name)
                                .onChange(of: focusedField) { _, newValue in
                                    if newValue == .name {
                                        hapticService.playSelection()
                                    }
                                }
                            
                            if !viewModel.name.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Name looks good")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $viewModel.email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .onChange(of: focusedField) { _, newValue in
                                    if newValue == .email {
                                        hapticService.playSelection()
                                    }
                                }
                                .onChange(of: viewModel.email) { _, _ in
                                    viewModel.validateEmail()
                                }
                            
                            if let error = viewModel.emailError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .transition(.opacity)
                                .onAppear {
                                    hapticService.playWarning()
                                }
                            } else if viewModel.emailValid {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Email is available")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity)
                                .onAppear {
                                    hapticService.playSuccess()
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
                                    TextField("Create a password", text: $viewModel.password)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Create a password", text: $viewModel.password)
                                        .textContentType(.newPassword)
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
                            .onChange(of: focusedField) { _, newValue in
                                if newValue == .password {
                                    hapticService.playSelection()
                                }
                            }
                            .onChange(of: viewModel.password) { _, _ in
                                viewModel.validatePassword()
                            }
                            
                            // Password Strength Indicator
                            if !viewModel.password.isEmpty {
                                PasswordStrengthView(strength: viewModel.passwordStrength)
                                    .onChange(of: viewModel.passwordStrength) { _, newStrength in
                                        hapticService.playPasswordStrength(newStrength)
                                    }
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .onChange(of: focusedField) { _, newValue in
                                    if newValue == .confirmPassword {
                                        hapticService.playSelection()
                                    }
                                }
                                .onChange(of: viewModel.confirmPassword) { _, _ in
                                    viewModel.validatePasswordMatch()
                                }
                            
                            if let error = viewModel.confirmPasswordError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .transition(.opacity)
                                .onAppear {
                                    hapticService.playWarning()
                                }
                            } else if viewModel.passwordsMatch {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Passwords match")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity)
                                .onAppear {
                                    hapticService.playSuccess()
                                }
                            }
                        }
                        
                        // Terms and Conditions
                        HStack {
                            Toggle("", isOn: $viewModel.agreedToTerms)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())
                                .onChange(of: viewModel.agreedToTerms) { _, _ in
                                    hapticService.playLight()
                                }
                            
                            Text("I agree to the ")
                                .font(.caption)
                            + Text("Terms & Conditions")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .underline()
                            + Text(" and ")
                                .font(.caption)
                            + Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .underline()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Up Button
                    Button {
                        Task {
                            hapticService.playMedium()
                            await viewModel.signUp()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Account")
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
                    
                    // Social Sign Up
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
                        
                        // Apple Sign Up
                        Button {
                            hapticService.playMedium()
                            Task {
                                await viewModel.signUpWithApple()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Sign up with Apple")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Google Sign Up
                        Button {
                            hapticService.playMedium()
                            Task {
                                await viewModel.signUpWithGoogle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("Sign up with Google")
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
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Button {
                            hapticService.playLight()
                            dismiss()
                        } label: {
                            Text("Sign In")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        hapticService.playLight()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("Continue") {
                    hapticService.playSuccess()
                    // Navigate to onboarding
                }
            } message: {
                Text("Your account has been created successfully!")
            }
            .onChange(of: viewModel.signUpSuccess) { _, success in
                if success {
                    hapticService.playGrandSuccess()
                }
            }
        }
    }
}

// Progress Bar Component
struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// Password Strength View
struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(strengthColor(for: index))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: strength)
            }
        }
        .frame(height: 4)
        
        HStack {
            Text(strength.description)
                .font(.caption2)
                .foregroundColor(strengthTextColor)
            Spacer()
        }
    }
    
    private func strengthColor(for index: Int) -> Color {
        switch strength {
        case .weak:
            return index == 0 ? .red : Color.secondary.opacity(0.2)
        case .fair:
            return index < 2 ? .orange : Color.secondary.opacity(0.2)
        case .good:
            return index < 3 ? .yellow : Color.secondary.opacity(0.2)
        case .strong:
            return .green
        }
    }
    
    private var strengthTextColor: Color {
        switch strength {
        case .weak: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return .green
        }
    }
}

// Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                .font(.system(size: 20))
        }
    }
}

// Password Strength Enum
enum PasswordStrength: CustomStringConvertible {
    case weak, fair, good, strong
    
    var description: String {
        switch self {
        case .weak: return "Weak password"
        case .fair: return "Fair password"
        case .good: return "Good password"
        case .strong: return "Strong password"
        }
    }
}

// SignUp ViewModel
class SignUpViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var showPassword = false
    @Published var agreedToTerms = false
    
    @Published var emailError: String?
    @Published var emailValid = false
    @Published var passwordStrength: PasswordStrength = .weak
    @Published var confirmPasswordError: String?
    @Published var passwordsMatch = false
    
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var signUpSuccess = false
    
    var signUpProgress: Double {
        var progress = 0.0
        if !name.isEmpty { progress += 0.25 }
        if emailValid { progress += 0.25 }
        if passwordStrength == .good || passwordStrength == .strong { progress += 0.25 }
        if passwordsMatch { progress += 0.25 }
        return progress
    }
    
    var isFormValid: Bool {
        !name.isEmpty &&
        emailValid &&
        (passwordStrength == .good || passwordStrength == .strong) &&
        passwordsMatch &&
        agreedToTerms
    }
    
    func validateEmail() {
        if email.isEmpty {
            emailError = nil
            emailValid = false
        } else if !email.contains("@") || !email.contains(".") {
            emailError = "Please enter a valid email"
            emailValid = false
        } else {
            // Simulate checking email availability
            emailError = nil
            emailValid = true
        }
    }
    
    func validatePassword() {
        if password.isEmpty {
            passwordStrength = .weak
        } else if password.count < 6 {
            passwordStrength = .weak
        } else if password.count < 8 {
            passwordStrength = .fair
        } else if password.count < 12 && containsSpecialCharacter() {
            passwordStrength = .good
        } else if password.count >= 12 && containsSpecialCharacter() && containsNumber() {
            passwordStrength = .strong
        } else {
            passwordStrength = .good
        }
    }
    
    func validatePasswordMatch() {
        if confirmPassword.isEmpty {
            confirmPasswordError = nil
            passwordsMatch = false
        } else if confirmPassword != password {
            confirmPasswordError = "Passwords don't match"
            passwordsMatch = false
        } else {
            confirmPasswordError = nil
            passwordsMatch = true
        }
    }
    
    private func containsSpecialCharacter() -> Bool {
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        return password.contains { specialCharacters.contains($0) }
    }
    
    private func containsNumber() -> Bool {
        return password.contains { $0.isNumber }
    }
    
    func signUp() async {
        isLoading = true
        
        // Simulate network call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isLoading = false
            showSuccess = true
            signUpSuccess = true
        }
    }
    
    func signUpWithApple() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            signUpSuccess = true
        }
    }
    
    func signUpWithGoogle() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            signUpSuccess = true
        }
    }
}

// Haptic Extension for Password Strength
extension HapticFeedbackService {
    func playPasswordStrength(_ strength: PasswordStrength) {
        switch strength {
        case .weak:
            playLight()
        case .fair:
            playMedium()
        case .good:
            playSuccess()
        case .strong:
            playGrandSuccess()
        }
    }
    
    func playGrandSuccess() {
        // Multi-stage celebration pattern
        playSuccess()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(HapticFeedbackService.shared)
    }
}