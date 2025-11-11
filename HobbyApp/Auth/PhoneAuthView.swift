import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var biometricService = BiometricAuthenticationService.shared
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var countryCode = "+1" // Default to US/Canada
    @State private var showVerificationStep = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var focusedField: Field?
    
    let onSuccess: (Bool) -> Void // Bool indicates if this is a new user
    let onCancel: () -> Void
    
    enum Field: Hashable {
        case phoneNumber, verificationCode
    }
    
    // Popular country codes
    private let countryCodes = [
        ("+1", "🇺🇸🇨🇦", "US/CA"),
        ("+44", "🇬🇧", "UK"),
        ("+49", "🇩🇪", "Germany"),
        ("+33", "🇫🇷", "France"),
        ("+61", "🇦🇺", "Australia"),
        ("+81", "🇯🇵", "Japan"),
        ("+86", "🇨🇳", "China"),
        ("+91", "🇮🇳", "India"),
        ("+55", "🇧🇷", "Brazil"),
        ("+7", "🇷🇺", "Russia")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: BrandConstants.Spacing.lg) {
                // Header
                VStack(spacing: BrandConstants.Spacing.sm) {
                    Image(systemName: "phone.fill")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(BrandConstants.Colors.teal)
                    
                    Text(showVerificationStep ? "Enter Verification Code" : "Sign in with Phone")
                        .font(BrandConstants.Typography.title2)
                        .foregroundColor(BrandConstants.Colors.text)
                    
                    Text(showVerificationStep 
                         ? "We sent a 6-digit code to \(countryCode) \(phoneNumber)"
                         : "We'll send you a verification code")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, BrandConstants.Spacing.xl)
                
                if !showVerificationStep {
                    // Phone Number Input
                    VStack(spacing: BrandConstants.Spacing.md) {
                        // Country Code Picker
                        VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                            Text("Country")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                            
                            Menu {
                                ForEach(countryCodes, id: \.0) { code, flag, name in
                                    Button(action: {
                                        countryCode = code
                                    }) {
                                        HStack {
                                            Text("\(flag) \(code)")
                                            Text(name)
                                            Spacer()
                                            if countryCode == code {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(BrandConstants.Colors.teal)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    let selectedCountry = countryCodes.first { $0.0 == countryCode }
                                    Text("\(selectedCountry?.1 ?? "🌍") \(countryCode)")
                                        .foregroundColor(BrandConstants.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(BrandConstants.Colors.secondaryText)
                                        .font(BrandConstants.Typography.caption)
                                }
                                .padding(BrandConstants.Spacing.md)
                                .background(BrandConstants.Colors.background)
                                .cornerRadius(BrandConstants.CornerRadius.md)
                            }
                        }
                        
                        // Phone Number Input
                        VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                            Text("Phone Number")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(BrandConstants.Colors.text)
                                .padding(BrandConstants.Spacing.md)
                                .background(BrandConstants.Colors.background)
                                .cornerRadius(BrandConstants.CornerRadius.md)
                                .focused($focusedField, equals: .phoneNumber)
                                .submitLabel(.send)
                                .onSubmit {
                                    if isValidPhoneNumber {
                                        sendVerificationCode()
                                    }
                                }
                        }
                        
                        // Phone Number Validation
                        if !phoneNumber.isEmpty && !isValidPhoneNumber {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(BrandConstants.Colors.warning)
                                Text("Please enter a valid phone number")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.warning)
                                Spacer()
                            }
                        }
                    }
                } else {
                    // Verification Code Input
                    VStack(spacing: BrandConstants.Spacing.md) {
                        VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                            Text("Verification Code")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                            
                            TextField("000000", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .font(BrandConstants.Typography.title2)
                                .foregroundColor(BrandConstants.Colors.text)
                                .padding(BrandConstants.Spacing.md)
                                .background(BrandConstants.Colors.background)
                                .cornerRadius(BrandConstants.CornerRadius.md)
                                .focused($focusedField, equals: .verificationCode)
                                .submitLabel(.done)
                                .onSubmit {
                                    if verificationCode.count == 6 {
                                        verifyCode()
                                    }
                                }
                                .onChange(of: verificationCode) { oldValue, newValue in
                                    // Auto-verify when 6 digits are entered
                                    if newValue.count == 6 && oldValue.count < 6 {
                                        verifyCode()
                                    }
                                }
                        }
                        
                        // Resend Code Button
                        Button(action: {
                            sendVerificationCode()
                        }) {
                            Text("Resend Code")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(BrandConstants.Colors.teal)
                                .underline()
                        }
                        .disabled(isLoading)
                    }
                }
                
                // Error/Success Messages
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BrandConstants.Colors.error)
                        Text(errorMessage)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.error)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                if let successMessage = successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(BrandConstants.Colors.success)
                        Text(successMessage)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.success)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: BrandConstants.Spacing.md) {
                    if !showVerificationStep {
                        BrandedButton(
                            "Send Code",
                            icon: "paperplane.fill",
                            gradient: BrandConstants.Gradients.teal,
                            isLoading: isLoading,
                            isDisabled: !isValidPhoneNumber
                        ) {
                            sendVerificationCode()
                        }
                    } else {
                        BrandedButton(
                            "Verify & Sign In",
                            icon: "checkmark.circle.fill",
                            gradient: BrandConstants.Gradients.teal,
                            isLoading: isLoading,
                            isDisabled: verificationCode.count != 6
                        ) {
                            verifyCode()
                        }
                        
                        OutlineButton(
                            "Change Phone Number",
                            icon: "pencil",
                            borderColor: BrandConstants.Colors.secondaryText
                        ) {
                            withAnimation(BrandConstants.Animation.spring) {
                                showVerificationStep = false
                                verificationCode = ""
                                errorMessage = nil
                                successMessage = nil
                                focusedField = .phoneNumber
                            }
                        }
                    }
                    
                    // Cancel Button
                    TextButton("Cancel", color: BrandConstants.Colors.secondaryText) {
                        onCancel()
                    }
                }
                .padding(.horizontal, BrandConstants.Spacing.md)
                .padding(.bottom, BrandConstants.Spacing.xl)
            }
            .background(BrandConstants.Colors.surface)
            .navigationBarHidden(true)
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidPhoneNumber: Bool {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanNumber.count >= 10 && cleanNumber.count <= 15
    }
    
    private var fullPhoneNumber: String {
        return "\(countryCode)\(phoneNumber)"
    }
    
    // MARK: - Actions
    
    private func sendVerificationCode() {
        guard isValidPhoneNumber else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            await supabaseService.sendPhoneVerification(phoneNumber: fullPhoneNumber)
            
            if supabaseService.errorMessage == nil {
                withAnimation(BrandConstants.Animation.spring) {
                    showVerificationStep = true
                    focusedField = .verificationCode
                    successMessage = "Verification code sent!"
                }
                
                // Clear success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    successMessage = nil
                }
            } else {
                errorMessage = supabaseService.errorMessage
            }
            isLoading = false
        }
    }
    
    private func verifyCode() {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await supabaseService.verifyPhoneCode(phoneNumber: fullPhoneNumber, code: verificationCode)
            
            if supabaseService.isAuthenticated {
                biometricService.saveLastAuthenticationMethod("phone")
                onSuccess(false) // Phone auth typically means returning user
            } else {
                errorMessage = supabaseService.errorMessage ?? "Verification failed"
                isLoading = false
            }
        }
    }
}

#Preview {
    PhoneAuthView(
        onSuccess: { _ in },
        onCancel: { }
    )
    .environmentObject(SimpleSupabaseService.shared)
}