import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    Button {
                        hapticService.playLight()
                        viewModel.skipOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(20)
                    }
                    .padding()
                }
                
                // Page Content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    ProfileSetupPage(viewModel: viewModel)
                        .tag(1)
                    
                    PreferencesPage(viewModel: viewModel)
                        .tag(2)
                    
                    NotificationsPage(viewModel: viewModel)
                        .tag(3)
                    
                    PaymentSetupPage(viewModel: viewModel)
                        .tag(4)
                    
                    CompletionPage(viewModel: viewModel)
                        .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldValue, newValue in
                    if newValue > oldValue {
                        viewModel.updateProgress(for: newValue)
                        hapticService.playOnboardingProgress(viewModel.progress)
                    }
                }
                
                // Custom Page Indicator & Continue Button
                VStack(spacing: 20) {
                    // Progress Dots
                    HStack(spacing: 8) {
                        ForEach(0..<6) { index in
                            Circle()
                                .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                        }
                    }
                    
                    // Continue Button
                    Button {
                        hapticService.playMedium()
                        if currentPage < 5 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            viewModel.completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < 5 ? "Continue" : "Get Started")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(currentPage == 1 && viewModel.profileImage == nil)
                }
                .padding(.bottom, 30)
            }
        }
        .onChange(of: viewModel.milestoneReached) { _, milestone in
            if let milestone = milestone {
                hapticService.playOnboardingMilestone(milestone)
            }
        }
    }
}

// Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text("Welcome to HobbyistSwiftUI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Discover and book amazing fitness classes near you")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// Profile Setup Page
struct ProfileSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Set Up Your Profile")
                .font(.title)
                .fontWeight(.bold)
            
            // Profile Image Picker
            Button {
                hapticService.playLight()
                showImagePicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                            Text("Add Photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Name and Bio Fields
            VStack(spacing: 16) {
                TextField("Display Name", text: $viewModel.displayName)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .onChange(of: viewModel.displayName) { _, _ in
                        hapticService.playLight()
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.profileImage)
                .onDisappear {
                    if viewModel.profileImage != nil {
                        hapticService.playSuccess()
                    }
                }
        }
    }
}

// Preferences Page
struct PreferencesPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    let fitnessTypes = [
        ("Yoga", "figure.yoga"),
        ("Pilates", "figure.pilates"),
        ("Cycling", "figure.outdoor.cycle"),
        ("Swimming", "figure.pool.swim"),
        ("Running", "figure.run"),
        ("Dance", "figure.dance"),
        ("Boxing", "figure.boxing"),
        ("CrossFit", "figure.strengthtraining.functional")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Your Fitness Interests")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Select activities you're interested in")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(fitnessTypes, id: \.0) { type, icon in
                    Button {
                        hapticService.playSelection()
                        if viewModel.selectedInterests.contains(type) {
                            viewModel.selectedInterests.remove(type)
                        } else {
                            viewModel.selectedInterests.insert(type)
                        }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(
                                    viewModel.selectedInterests.contains(type) 
                                    ? .white 
                                    : .accentColor
                                )
                            
                            Text(type)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    viewModel.selectedInterests.contains(type)
                                    ? .white
                                    : .primary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    viewModel.selectedInterests.contains(type)
                                    ? Color.accentColor
                                    : Color(.systemGray6)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onChange(of: viewModel.selectedInterests.count) { _, count in
            if count >= 3 && !viewModel.preferencesSet {
                viewModel.preferencesSet = true
                viewModel.milestoneReached = .preferencesSet
            }
        }
    }
}

// Notifications Page
struct NotificationsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce)
            
            VStack(spacing: 16) {
                Text("Stay Updated")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Get notified about new classes, schedule changes, and exclusive offers")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                // Notification Preferences
                Toggle(isOn: $viewModel.classReminders) {
                    Label("Class Reminders", systemImage: "clock.fill")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: viewModel.classReminders) { _, _ in
                    hapticService.playLight()
                }
                
                Toggle(isOn: $viewModel.newClassAlerts) {
                    Label("New Class Alerts", systemImage: "sparkles")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: viewModel.newClassAlerts) { _, _ in
                    hapticService.playLight()
                }
                
                Toggle(isOn: $viewModel.promotionalOffers) {
                    Label("Special Offers", systemImage: "tag.fill")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: viewModel.promotionalOffers) { _, _ in
                    hapticService.playLight()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button {
                hapticService.playMedium()
                showingPermissionAlert = true
                viewModel.notificationsEnabled = true
                viewModel.milestoneReached = .notificationsEnabled
            } label: {
                Text("Enable Notifications")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Allow") {
                hapticService.playSuccess()
            }
            Button("Not Now", role: .cancel) {
                hapticService.playLight()
            }
        } message: {
            Text("HobbyistSwiftUI would like to send you notifications")
        }
    }
}

// Payment Setup Page
struct PaymentSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "creditcard.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 16) {
                Text("Payment Method")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Add a payment method to book classes seamlessly")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                // Apple Pay Button
                Button {
                    hapticService.playMedium()
                    viewModel.paymentMethodAdded = true
                    viewModel.milestoneReached = .paymentAdded
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Set up Apple Pay")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Add Card Button
                Button {
                    hapticService.playMedium()
                    viewModel.showPaymentSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Credit/Debit Card")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                }
                
                // Skip for Now
                Button {
                    hapticService.playLight()
                } label: {
                    Text("I'll add later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .sheet(isPresented: $viewModel.showPaymentSheet) {
            PaymentMethodSheet()
        }
    }
}

// Completion Page
struct CompletionPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .scaleEffect(showConfetti ? 1.2 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.1 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                        .scaleEffect(showConfetti ? 1.0 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showConfetti)
                }
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start exploring amazing fitness classes in your area")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Quick Stats
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        StatItem(icon: "star.fill", value: "\(viewModel.selectedInterests.count)", label: "Interests")
                        StatItem(icon: "bell.fill", value: viewModel.notificationsEnabled ? "On" : "Off", label: "Notifications")
                        StatItem(icon: "creditcard.fill", value: viewModel.paymentMethodAdded ? "Added" : "Skip", label: "Payment")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            
            // Confetti Effect (simplified)
            if showConfetti {
                ForEach(0..<20) { index in
                    ConfettiPiece()
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: -100...0)
                        )
                        .animation(
                            .easeOut(duration: Double.random(in: 2...3))
                            .delay(Double(index) * 0.05),
                            value: showConfetti
                        )
                }
            }
        }
        .onAppear {
            withAnimation {
                showConfetti = true
            }
            hapticService.playOnboardingComplete()
        }
    }
}

// Stat Item Component
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// Confetti Piece
struct ConfettiPiece: View {
    @State private var yPosition: CGFloat = -50
    
    var body: some View {
        Rectangle()
            .fill(Color.accentColor.opacity(Double.random(in: 0.6...1.0)))
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(Double.random(in: 0...360)))
            .offset(y: yPosition)
            .onAppear {
                withAnimation {
                    yPosition = UIScreen.main.bounds.height + 100
                }
            }
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Payment Method Sheet (simplified)
struct PaymentMethodSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Payment Method")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Placeholder for Stripe payment sheet
                Text("Stripe Payment Sheet Integration")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        hapticService.playSuccess()
                        dismiss()
                    }
                }
            }
        }
    }
}

// Onboarding Milestones
enum OnboardingMilestone {
    case profileCreated
    case preferencesSet
    case firstClassViewed
    case notificationsEnabled
    case paymentAdded
}

// Onboarding ViewModel
class OnboardingViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep = 0
    
    // Profile
    @Published var profileImage: UIImage?
    @Published var displayName = ""
    @Published var bio = ""
    
    // Preferences
    @Published var selectedInterests: Set<String> = []
    @Published var preferencesSet = false
    
    // Notifications
    @Published var notificationsEnabled = false
    @Published var classReminders = true
    @Published var newClassAlerts = true
    @Published var promotionalOffers = false
    
    // Payment
    @Published var paymentMethodAdded = false
    @Published var showPaymentSheet = false
    
    // Milestones
    @Published var milestoneReached: OnboardingMilestone?
    
    func updateProgress(for page: Int) {
        progress = Double(page) / 5.0
    }
    
    func skipOnboarding() {
        // Handle skip logic
    }
    
    func completeOnboarding() {
        // Handle completion logic
    }
}

// Haptic Extensions for Onboarding
extension HapticFeedbackService {
    func playOnboardingProgress(_ progress: Double) {
        let intensity = 0.2 + (progress * 0.5)
        // Play haptic with calculated intensity
        if progress == 0.25 || progress == 0.5 || progress == 0.75 {
            playSuccess()
        } else {
            playLight()
        }
    }
    
    func playOnboardingMilestone(_ milestone: OnboardingMilestone) {
        switch milestone {
        case .profileCreated, .preferencesSet:
            playSuccess()
        case .firstClassViewed:
            playMedium()
        case .notificationsEnabled, .paymentAdded:
            playNotification(.success)
        }
    }
    
    func playOnboardingComplete() {
        // Grand finale pattern
        playSuccess()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(HapticFeedbackService.shared)
    }
}