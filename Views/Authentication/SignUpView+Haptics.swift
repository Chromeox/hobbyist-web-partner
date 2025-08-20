import SwiftUI
import Combine

// MARK: - SignUpView with Premium Haptic Integration
struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @State private var currentStep = 1
    private let totalSteps = 4
    
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                SignUpProgressBar(
                    currentStep: currentStep,
                    totalSteps: totalSteps
                )
                .padding()
                
                // Step Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 1:
                            AccountDetailsStep(
                                viewModel: viewModel,
                                hapticService: hapticService
                            )
                        case 2:
                            PersonalInfoStep(
                                viewModel: viewModel,
                                hapticService: hapticService
                            )
                        case 3:
                            PreferencesStep(
                                viewModel: viewModel,
                                hapticService: hapticService
                            )
                        case 4:
                            ReviewStep(
                                viewModel: viewModel,
                                hapticService: hapticService
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 1 {
                        Button(action: previousStep) {
                            Text("Back")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: nextStep) {
                        Text(currentStep == totalSteps ? "Create Account" : "Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canProceed ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!canProceed)
                }
                .padding()
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.large)
            .onReceive(viewModel.$signUpState) { state in
                handleSignUpStateChange(state)
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return viewModel.isStep1Valid
        case 2:
            return viewModel.isStep2Valid
        case 3:
            return viewModel.isStep3Valid
        case 4:
            return true
        default:
            return false
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps {
            // Haptic: Step progression feedback
            hapticService.playAccountCreationStep(
                step: currentStep + 1,
                totalSteps: totalSteps
            )
            
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            // Final step - create account
            hapticService.prepareHaptics()
            viewModel.createAccount()
        }
    }
    
    private func previousStep() {
        if currentStep > 1 {
            // Haptic: Navigation feedback
            hapticService.playFormFieldFocus()
            
            withAnimation(.spring()) {
                currentStep -= 1
            }
        }
    }
    
    private func handleSignUpStateChange(_ state: SignUpState) {
        switch state {
        case .idle, .loading:
            break
            
        case .success:
            // Haptic: Grand success celebration
            hapticService.playSignUpSuccess()
            
        case .failure(let error):
            // Haptic: Error feedback
            hapticService.playFormValidationError()
        }
    }
}

// MARK: - Step 1: Account Details
struct AccountDetailsStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    let hapticService: HapticFeedbackServiceProtocol
    
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account Details")
                .font(.title2)
                .fontWeight(.bold)
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Email Address", systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("your@email.com", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
                    .onChange(of: viewModel.email) { newValue in
                        validateEmail(newValue)
                    }
                
                if viewModel.isEmailValid {
                    Label("Valid email", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .onAppear {
                            hapticService.playEmailValidation(isValid: true)
                        }
                } else if !viewModel.email.isEmpty {
                    Label("Invalid email format", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .onAppear {
                            hapticService.playEmailValidation(isValid: false)
                        }
                }
            }
            
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Username", systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Choose a username", text: $viewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .onTapGesture {
                            hapticService.playFormFieldFocus()
                        }
                        .onChange(of: viewModel.username) { newValue in
                            checkUsernameAvailability(newValue)
                        }
                    
                    if isCheckingUsername {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let available = usernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(available ? .green : .red)
                    }
                }
                
                if let available = usernameAvailable {
                    Label(
                        available ? "Username available" : "Username already taken",
                        systemImage: available ? "checkmark" : "xmark"
                    )
                    .font(.caption)
                    .foregroundColor(available ? .green : .red)
                }
            }
            
            // Password Field with Strength Indicator
            VStack(alignment: .leading, spacing: 8) {
                Label("Password", systemImage: "lock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Choose a strong password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
                    .onChange(of: viewModel.password) { newValue in
                        updatePasswordStrength(newValue)
                    }
                
                // Password Strength Indicator
                PasswordStrengthIndicator(
                    strength: viewModel.passwordStrength,
                    hapticService: hapticService
                )
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                Label("Confirm Password", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
                
                if !viewModel.confirmPassword.isEmpty {
                    if viewModel.passwordsMatch {
                        Label("Passwords match", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .onAppear {
                                hapticService.playFormFieldFocus()
                            }
                    } else {
                        Label("Passwords don't match", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .onAppear {
                                hapticService.playFormValidationError()
                            }
                    }
                }
            }
        }
    }
    
    private func validateEmail(_ email: String) {
        viewModel.isEmailValid = email.contains("@") && email.contains(".")
    }
    
    private func checkUsernameAvailability(_ username: String) {
        guard username.count >= 3 else {
            usernameAvailable = nil
            return
        }
        
        isCheckingUsername = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingUsername = false
            usernameAvailable = !["admin", "test", "user"].contains(username.lowercased())
            
            if let available = usernameAvailable {
                if available {
                    hapticService.playUsernameAvailable()
                } else {
                    hapticService.playUsernameUnavailable()
                }
            }
        }
    }
    
    private func updatePasswordStrength(_ password: String) {
        let oldStrength = viewModel.passwordStrength
        
        if password.isEmpty {
            viewModel.passwordStrength = .veryWeak
        } else if password.count < 6 {
            viewModel.passwordStrength = .weak
        } else if password.count < 10 {
            viewModel.passwordStrength = .medium
        } else if password.rangeOfCharacter(from: .decimalDigits) != nil &&
                  password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            viewModel.passwordStrength = .veryStrong
        } else {
            viewModel.passwordStrength = .strong
        }
        
        if oldStrength != viewModel.passwordStrength {
            hapticService.playPasswordStrengthChange(strength: viewModel.passwordStrength)
        }
    }
}

// MARK: - Step 2: Personal Information
struct PersonalInfoStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    let hapticService: HapticFeedbackServiceProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Information")
                .font(.title2)
                .fontWeight(.bold)
            
            // First Name
            VStack(alignment: .leading, spacing: 8) {
                Label("First Name", systemImage: "person.text.rectangle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter your first name", text: $viewModel.firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
            }
            
            // Last Name
            VStack(alignment: .leading, spacing: 8) {
                Label("Last Name", systemImage: "person.text.rectangle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter your last name", text: $viewModel.lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
            }
            
            // Date of Birth
            VStack(alignment: .leading, spacing: 8) {
                Label("Date of Birth", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                DatePicker(
                    "Select your birth date",
                    selection: $viewModel.dateOfBirth,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .onChange(of: viewModel.dateOfBirth) { _ in
                    hapticService.playFormFieldFocus()
                }
            }
            
            // Phone Number
            VStack(alignment: .leading, spacing: 8) {
                Label("Phone Number (Optional)", systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("(555) 123-4567", text: $viewModel.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                    .onTapGesture {
                        hapticService.playFormFieldFocus()
                    }
            }
        }
    }
}

// MARK: - Step 3: Preferences
struct PreferencesStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    let hapticService: HapticFeedbackServiceProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            // Interest Categories
            VStack(alignment: .leading, spacing: 12) {
                Label("What are you interested in?", systemImage: "star")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.availableInterests, id: \.self) { interest in
                    HStack {
                        Image(systemName: viewModel.selectedInterests.contains(interest) ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.selectedInterests.contains(interest) ? .blue : .gray)
                        
                        Text(interest)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleInterest(interest)
                    }
                }
            }
            
            // Notification Preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("Notifications", systemImage: "bell")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Toggle("Class Reminders", isOn: $viewModel.classReminders)
                    .onChange(of: viewModel.classReminders) { _ in
                        hapticService.playFormFieldFocus()
                    }
                
                Toggle("New Classes", isOn: $viewModel.newClassNotifications)
                    .onChange(of: viewModel.newClassNotifications) { _ in
                        hapticService.playFormFieldFocus()
                    }
                
                Toggle("Promotional Offers", isOn: $viewModel.promotionalEmails)
                    .onChange(of: viewModel.promotionalEmails) { _ in
                        hapticService.playFormFieldFocus()
                    }
            }
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if viewModel.selectedInterests.contains(interest) {
            viewModel.selectedInterests.remove(interest)
        } else {
            viewModel.selectedInterests.insert(interest)
        }
        hapticService.playFormFieldFocus()
    }
}

// MARK: - Step 4: Review
struct ReviewStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    let hapticService: HapticFeedbackServiceProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Your Information")
                .font(.title2)
                .fontWeight(.bold)
            
            // Account Summary
            VStack(alignment: .leading, spacing: 16) {
                ReviewItem(title: "Email", value: viewModel.email)
                ReviewItem(title: "Username", value: viewModel.username)
                ReviewItem(title: "Name", value: "\(viewModel.firstName) \(viewModel.lastName)")
                ReviewItem(title: "Interests", value: viewModel.selectedInterests.joined(separator: ", "))
            }
            
            // Terms and Conditions
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.acceptedTerms) {
                    Text("I accept the Terms & Conditions")
                        .font(.footnote)
                }
                .onChange(of: viewModel.acceptedTerms) { _ in
                    hapticService.playFormFieldFocus()
                }
                
                Toggle(isOn: $viewModel.acceptedPrivacy) {
                    Text("I accept the Privacy Policy")
                        .font(.footnote)
                }
                .onChange(of: viewModel.acceptedPrivacy) { _ in
                    hapticService.playFormFieldFocus()
                }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Creating your account...")
                        .padding()
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct SignUpProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    let hapticService: HapticFeedbackServiceProtocol
    
    var strengthColor: Color {
        switch strength {
        case .veryWeak: return .red
        case .weak: return .orange
        case .medium: return .yellow
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }
    
    var strengthText: String {
        switch strength {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= strength.rawValue ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            Text(strengthText)
                .font(.caption)
                .foregroundColor(strengthColor)
        }
    }
}

struct ReviewItem: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - View Model
class SignUpViewModel: ObservableObject {
    // Step 1
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isEmailValid = false
    @Published var passwordStrength: PasswordStrength = .veryWeak
    
    // Step 2
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = Date()
    @Published var phoneNumber = ""
    
    // Step 3
    @Published var selectedInterests = Set<String>()
    @Published var classReminders = true
    @Published var newClassNotifications = true
    @Published var promotionalEmails = false
    
    // Step 4
    @Published var acceptedTerms = false
    @Published var acceptedPrivacy = false
    
    // State
    @Published var signUpState: SignUpState = .idle
    @Published var isLoading = false
    
    let availableInterests = ["Fitness", "Yoga", "Art", "Music", "Cooking", "Photography", "Dance", "Language"]
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var isStep1Valid: Bool {
        isEmailValid && !username.isEmpty && passwordsMatch && passwordStrength.rawValue >= 2
    }
    
    var isStep2Valid: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
    var isStep3Valid: Bool {
        !selectedInterests.isEmpty
    }
    
    func createAccount() {
        isLoading = true
        signUpState = .loading
        
        // Simulate account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isLoading = false
            self?.signUpState = .success
        }
    }
}

enum SignUpState {
    case idle
    case loading
    case success
    case failure(String)
}