import SwiftUI

// MARK: - OnboardingView with Premium Haptic Integration
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0
    
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: onboardingPages[currentPage].gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    Button("Skip") {
                        skipOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                }
                
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingPages[index],
                            hapticService: hapticService,
                            onMilestone: { milestone in
                                handleMilestone(milestone)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { newPage in
                    handlePageChange(to: newPage)
                }
                
                // Progress and Navigation
                VStack(spacing: 24) {
                    // Progress Dots
                    OnboardingProgressDots(
                        currentPage: currentPage,
                        totalPages: onboardingPages.count
                    )
                    
                    // Action Button
                    Button(action: handleActionButton) {
                        Text(actionButtonTitle)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(onboardingPages[currentPage].gradientColors.first)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 32)
                    .disabled(viewModel.isProcessing)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            hapticService.prepareHaptics()
            // Initial feature highlight
            hapticService.playFeatureHighlight()
        }
        .sheet(isPresented: $viewModel.showPermissionRequest) {
            PermissionRequestView(
                permission: viewModel.currentPermission,
                hapticService: hapticService,
                onGrant: { granted in
                    handlePermissionResult(granted)
                }
            )
        }
    }
    
    private var actionButtonTitle: String {
        if currentPage == onboardingPages.count - 1 {
            return "Get Started"
        } else {
            return "Next"
        }
    }
    
    private var progress: Float {
        Float(currentPage + 1) / Float(onboardingPages.count)
    }
    
    private func handlePageChange(to page: Int) {
        // Calculate and play progress haptic
        let progress = Float(page + 1) / Float(onboardingPages.count)
        hapticService.playOnboardingProgress(progress: progress)
        
        // Check for milestone pages
        if page == 2 {
            // Preferences page
            hapticService.playOnboardingMilestone(milestone: .preferencesSet)
        } else if page == 3 {
            // First class viewed simulation
            hapticService.playOnboardingMilestone(milestone: .firstClassViewed)
        }
    }
    
    private func handleActionButton() {
        if currentPage < onboardingPages.count - 1 {
            // Next page
            withAnimation(.spring()) {
                currentPage += 1
            }
        } else {
            // Complete onboarding
            completeOnboarding()
        }
    }
    
    private func skipOnboarding() {
        // Light haptic for skip
        hapticService.playFormFieldFocus()
        
        // Skip to completion
        withAnimation {
            currentPage = onboardingPages.count - 1
        }
    }
    
    private func completeOnboarding() {
        // Grand finale haptic
        hapticService.playOnboardingComplete()
        
        // Mark onboarding as complete
        viewModel.completeOnboarding()
    }
    
    private func handleMilestone(_ milestone: OnboardingMilestone) {
        hapticService.playOnboardingMilestone(milestone: milestone)
        viewModel.recordMilestone(milestone)
    }
    
    private func handlePermissionResult(_ granted: Bool) {
        if granted {
            hapticService.playOnboardingMilestone(milestone: .notificationsEnabled)
        } else {
            hapticService.playFormValidationError()
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let hapticService: HapticFeedbackServiceProtocol
    let onMilestone: (OnboardingMilestone) -> Void
    
    @State private var animateContent = false
    @State private var interactionCount = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated Icon/Illustration
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateContent)
                
                Image(systemName: page.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(animateContent ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateContent)
            }
            .onTapGesture {
                handleInteraction()
            }
            
            // Title
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Interactive Elements
            if let interactiveElement = page.interactiveElement {
                InteractiveOnboardingElement(
                    element: interactiveElement,
                    hapticService: hapticService,
                    onInteraction: {
                        handleElementInteraction(interactiveElement)
                    }
                )
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
            
            // Feature highlight for important pages
            if page.isImportant {
                hapticService.playFeatureHighlight()
            }
        }
    }
    
    private func handleInteraction() {
        interactionCount += 1
        
        // Progressive haptic feedback based on interaction
        if interactionCount == 1 {
            hapticService.playFormFieldFocus()
        } else if interactionCount == 3 {
            hapticService.playFeatureHighlight()
        } else if interactionCount >= 5 {
            // Easter egg: reward curious users
            onMilestone(.firstClassViewed)
            interactionCount = 0
        }
    }
    
    private func handleElementInteraction(_ element: InteractiveElement) {
        switch element {
        case .profileSetup:
            onMilestone(.profileCreated)
        case .preferences:
            onMilestone(.preferencesSet)
        case .notifications:
            onMilestone(.notificationsEnabled)
        case .payment:
            onMilestone(.paymentAdded)
        case .classPreview:
            onMilestone(.firstClassViewed)
        }
    }
}

// MARK: - Interactive Elements
struct InteractiveOnboardingElement: View {
    let element: InteractiveElement
    let hapticService: HapticFeedbackServiceProtocol
    let onInteraction: () -> Void
    
    @State private var isInteracting = false
    
    var body: some View {
        Group {
            switch element {
            case .profileSetup:
                ProfileSetupElement(
                    hapticService: hapticService,
                    onComplete: onInteraction
                )
                
            case .preferences:
                PreferencesSelectionElement(
                    hapticService: hapticService,
                    onComplete: onInteraction
                )
                
            case .notifications:
                NotificationPermissionElement(
                    hapticService: hapticService,
                    onComplete: onInteraction
                )
                
            case .payment:
                PaymentPreviewElement(
                    hapticService: hapticService,
                    onComplete: onInteraction
                )
                
            case .classPreview:
                ClassPreviewElement(
                    hapticService: hapticService,
                    onComplete: onInteraction
                )
            }
        }
    }
}

// MARK: - Interactive Element Views
struct ProfileSetupElement: View {
    let hapticService: HapticFeedbackServiceProtocol
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var hasInteracted = false
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onTapGesture {
                    if !hasInteracted {
                        hasInteracted = true
                        hapticService.playFormFieldFocus()
                        onComplete()
                    }
                }
            
            if !name.isEmpty {
                Text("Welcome, \(name)! 👋")
                    .foregroundColor(.white)
                    .onAppear {
                        hapticService.playFeatureHighlight()
                    }
            }
        }
    }
}

struct PreferencesSelectionElement: View {
    let hapticService: HapticFeedbackServiceProtocol
    let onComplete: () -> Void
    
    @State private var selectedCategories = Set<String>()
    @State private var hasCompleted = false
    
    let categories = ["Fitness", "Yoga", "Art", "Music", "Cooking"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Select your interests:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: selectedCategories.contains(category),
                            action: {
                                toggleCategory(category)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        
        hapticService.playFormFieldFocus()
        
        if !hasCompleted && selectedCategories.count >= 2 {
            hasCompleted = true
            onComplete()
        }
    }
}

struct NotificationPermissionElement: View {
    let hapticService: HapticFeedbackServiceProtocol
    let onComplete: () -> Void
    
    @State private var showingPermission = false
    
    var body: some View {
        Button(action: {
            hapticService.playFormFieldFocus()
            showingPermission = true
            
            // Simulate permission request
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onComplete()
            }
        }) {
            HStack {
                Image(systemName: "bell.badge")
                Text("Enable Notifications")
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
            .foregroundColor(.white)
        }
    }
}

struct PaymentPreviewElement: View {
    let hapticService: HapticFeedbackServiceProtocol
    let onComplete: () -> Void
    
    @State private var hasInteracted = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "creditcard")
                    .font(.largeTitle)
                Text("Secure Payment")
                    .font(.headline)
            }
            .foregroundColor(.white)
            
            Text("Add payment methods easily and securely")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .onTapGesture {
            if !hasInteracted {
                hasInteracted = true
                hapticService.playFeatureHighlight()
                onComplete()
            }
        }
    }
}

struct ClassPreviewElement: View {
    let hapticService: HapticFeedbackServiceProtocol
    let onComplete: () -> Void
    
    @State private var currentClass = 0
    let sampleClasses = ["Yoga Flow", "Pottery Basics", "Guitar 101", "Cooking Masterclass"]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(sampleClasses[currentClass])
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                currentClass = (currentClass + 1) % sampleClasses.count
                hapticService.playFormFieldFocus()
                
                if currentClass == 2 {
                    onComplete()
                }
            }) {
                Text("Browse Classes →")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .foregroundColor(.white)
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.white.opacity(0.2))
                .foregroundColor(isSelected ? Color.blue : .white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Progress Dots
struct OnboardingProgressDots: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                    .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

// MARK: - Permission Request View
struct PermissionRequestView: View {
    let permission: PermissionType
    let hapticService: HapticFeedbackServiceProtocol
    let onGrant: (Bool) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: permission.icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text(permission.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(permission.description)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    hapticService.playFormFieldFocus()
                    onGrant(true)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Allow")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    hapticService.playFormValidationError()
                    onGrant(false)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Not Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Data Models
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let gradientColors: [Color]
    let interactiveElement: InteractiveElement?
    let isImportant: Bool
}

enum InteractiveElement {
    case profileSetup
    case preferences
    case notifications
    case payment
    case classPreview
}

enum PermissionType {
    case notifications
    case location
    case camera
    
    var icon: String {
        switch self {
        case .notifications: return "bell.badge"
        case .location: return "location"
        case .camera: return "camera"
        }
    }
    
    var title: String {
        switch self {
        case .notifications: return "Stay Updated"
        case .location: return "Find Classes Near You"
        case .camera: return "Share Your Journey"
        }
    }
    
    var description: String {
        switch self {
        case .notifications:
            return "Get reminders for your upcoming classes and discover new opportunities"
        case .location:
            return "See classes and instructors in your area for in-person sessions"
        case .camera:
            return "Take photos of your creations and share them with the community"
        }
    }
}

// Sample onboarding pages
let onboardingPages = [
    OnboardingPage(
        title: "Welcome to HobbyistSwiftUI",
        description: "Discover amazing classes and learn new skills from passionate instructors",
        iconName: "sparkles",
        gradientColors: [Color.blue, Color.purple],
        interactiveElement: .profileSetup,
        isImportant: true
    ),
    OnboardingPage(
        title: "Find Your Passion",
        description: "Browse hundreds of classes across various categories tailored to your interests",
        iconName: "magnifyingglass.circle.fill",
        gradientColors: [Color.purple, Color.pink],
        interactiveElement: .preferences,
        isImportant: false
    ),
    OnboardingPage(
        title: "Book with Confidence",
        description: "Easy booking, secure payments, and instant confirmations for all your classes",
        iconName: "checkmark.shield.fill",
        gradientColors: [Color.pink, Color.orange],
        interactiveElement: .payment,
        isImportant: true
    ),
    OnboardingPage(
        title: "Never Miss a Class",
        description: "Get timely reminders and manage your schedule effortlessly",
        iconName: "bell.badge.fill",
        gradientColors: [Color.orange, Color.yellow],
        interactiveElement: .notifications,
        isImportant: false
    ),
    OnboardingPage(
        title: "Start Your Journey",
        description: "Join thousands of learners and begin your creative adventure today",
        iconName: "star.fill",
        gradientColors: [Color.yellow, Color.green],
        interactiveElement: .classPreview,
        isImportant: true
    )
]

// MARK: - View Model
class OnboardingViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var showPermissionRequest = false
    @Published var currentPermission: PermissionType = .notifications
    @Published var completedMilestones = Set<OnboardingMilestone>()
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        // Navigate to main app
    }
    
    func recordMilestone(_ milestone: OnboardingMilestone) {
        completedMilestones.insert(milestone)
    }
}