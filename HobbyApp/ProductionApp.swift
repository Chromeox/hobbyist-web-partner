import SwiftUI
// Stripe removed - using credits-only system for alpha
// import Stripe

// Production-ready app entry point
// This is now the main entry point for the production app
@main
struct ProductionHobbyistApp: App {
    init() {
        // Stripe configuration disabled - using credits only
        // StripeAPI.defaultPublishableKey = Configuration.shared.stripePublishableKey
        print("✅ ProductionApp initialized (credits-only mode)")
    }
    @StateObject private var supabaseService = SimpleSupabaseService.shared

    var body: some Scene {
        WindowGroup {
            ProductionContentView()
                .environmentObject(supabaseService)
                .onAppear {
                    configureAppAppearance()
                }
        }
    }

    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        print("✅ Production app appearance configured")
    }
}

struct ProductionContentView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    @State private var showOnboarding = false
    @State private var hasCompletedOnboarding = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if showOnboarding {
                // Use new modular onboarding if feature flag is enabled
                if featureFlagManager.isEnabled(.onboardingModule) {
                    OnboardingCoordinator {
                        showOnboarding = false
                        hasCompletedOnboarding = true
                    }
                } else {
                    // Fallback to original onboarding
                    ProductionOnboardingView {
                        showOnboarding = false
                        hasCompletedOnboarding = true
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                }
            } else if supabaseService.isAuthenticated {
                ProductionMainTabView()
            } else {
                ProductionLoginView()
            }
        }
        .onAppear {
            initializeApp()
        }
    }

    private func initializeApp() {
        // Show loading screen for minimum 2.5 seconds for branding
        Task {
            // Initialize services and check authentication in parallel
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    // Minimum loading time for branding
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                }

                group.addTask {
                    // Check onboarding status
                    await checkOnboardingStatus()
                }
            }

            // Update UI on main thread
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func checkOnboardingStatus() async {
        await MainActor.run {
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

            // Show onboarding for first-time users
            if !hasCompletedOnboarding && supabaseService.isAuthenticated {
                showOnboarding = true
            }
        }
    }
}

struct ProductionOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "figure.yoga",
                    title: "Discover Your Passion",
                    subtitle: "Explore hundreds of hobby classes",
                    description: "From pottery to yoga, cooking to dance - find your next adventure with expert instructors in Vancouver."
                )
                .tag(0)

                OnboardingPage(
                    icon: "calendar.badge.plus",
                    title: "Book with Confidence",
                    subtitle: "Simple scheduling made easy",
                    description: "Secure booking, instant confirmations, and flexible scheduling. Manage all your classes in one place."
                )
                .tag(1)

                OnboardingPage(
                    icon: "heart.circle.fill",
                    title: "Your Hobby Journey",
                    subtitle: "Track progress & connect",
                    description: "Save favorites, write reviews, and join a community of passionate learners on their hobby journey."
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            VStack(spacing: BrandConstants.Spacing.lg) {
                // Page Indicator
                HStack(spacing: BrandConstants.Spacing.sm) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? BrandConstants.Colors.primary : BrandConstants.Colors.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Navigation
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation { currentPage -= 1 }
                        }
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                    }

                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button("Next") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding(.horizontal, BrandConstants.Spacing.lg)
                        .padding(.vertical, BrandConstants.Spacing.md)
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                    } else {
                        Button("Get Started") {
                            onComplete()
                        }
                        .padding(.horizontal, BrandConstants.Spacing.lg)
                        .padding(.vertical, BrandConstants.Spacing.md)
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, BrandConstants.Spacing.xxl)
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String

    var body: some View {
        VStack(spacing: BrandConstants.Spacing.xl) {
            Spacer()

            Image(systemName: icon)
                .font(BrandConstants.Typography.heroTitle)
                .foregroundColor(BrandConstants.Colors.primary)

            VStack(spacing: BrandConstants.Spacing.md) {
                Text(title)
                    .font(BrandConstants.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(BrandConstants.Typography.title2)
                    .foregroundColor(BrandConstants.Colors.primary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

struct ProductionLoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @Namespace private var toggleNamespace
    @FocusState private var focusedField: Field?

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isPasswordVisible = false
    @State private var animateBadge = false

    private enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
    }

    private enum Field: Hashable {
        case fullName, email, password
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BrandConstants.Colors.primary,
                    BrandConstants.Colors.teal.opacity(0.85),
                    BrandConstants.Colors.coral.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BrandConstants.Spacing.lg) {
                    headerSection
                        .padding(.top, 40)

                    modeSwitcher
                        .padding(.horizontal, BrandConstants.Spacing.xl)

                    formSection

                    primaryActionButton

                    supplementalButtons

                    if supabaseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                focusedField = nil
            }
        }
        .alert(
            supabaseService.errorMessage ?? "",
            isPresented: .constant(supabaseService.errorMessage != nil),
            actions: {
                Button("OK") {
                    supabaseService.errorMessage = nil
                }
            },
            message: {
                Text("Please check your credentials and try again.")
            }
        )
        .onAppear {
            guard !animateBadge else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                animateBadge = true
            }
        }
    }

    private var formIsValid: Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        if mode == .signUp {
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
        }

        return true
    }

    private var headerSection: some View {
        VStack(spacing: BrandConstants.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(BrandConstants.Colors.surface.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .scaleEffect(animateBadge ? 1.05 : 0.95)

                Circle()
                    .fill(BrandConstants.Colors.surface.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateBadge ? 0.98 : 1.02)
                    .blur(radius: 2)

                Image(systemName: "figure.yoga")
                    .font(BrandConstants.Typography.heroTitle)
                    .foregroundColor(BrandConstants.Colors.surface)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: BrandConstants.Spacing.sm) {
                Text(mode == .signUp ? "Create Your Account" : "Welcome Back")
                    .font(BrandConstants.Typography.largeTitle)
                    .foregroundStyle(Color.white)

                Text(mode == .signUp ? "Join the community and start booking classes instantly." :
                        "Sign in to continue your creative journey.")
                    .font(BrandConstants.Typography.body)
                    .foregroundStyle(BrandConstants.Colors.surface.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BrandConstants.Spacing.xl)
            }
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases, id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        mode = value
                        focusedField = nil
                        password = ""
                        if mode == .signIn {
                            fullName = ""
                        }
                    }
                } label: {
                    Text(value.rawValue)
                        .font(BrandConstants.Typography.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(mode == value ? .black : .white.opacity(0.7))
                        .background(
                            ZStack {
                                if mode == value {
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                                        .fill(Color.white)
                                        .matchedGeometryEffect(id: "modeSelection", in: toggleNamespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(BrandConstants.Colors.surface.opacity(0.2))
        .clipShape(Capsule())
    }

    private var formSection: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            Group {
                if mode == .signUp {
                    AuthTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $fullName,
                        textContentType: .name,
                        capitalization: .words,
                        focusState: _focusedField,
                        field: .fullName,
                        onSubmit: { focusedField = .email }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                AuthTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress,
                    capitalization: .never,
                    focusState: _focusedField,
                    field: .email,
                    onSubmit: { focusedField = .password }
                )

                AuthTextField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    isSecure: !isPasswordVisible,
                    trailingIcon: AnyView(
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPasswordVisible.toggle()
                            }
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    ),
                    textContentType: .password,
                    focusState: _focusedField,
                    field: .password,
                    submitLabel: .go,
                    onSubmit: handlePrimaryAction
                )
            }

            if mode == .signIn {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Placeholder for future password reset flow
                    }
                    .font(BrandConstants.Typography.caption)
                    .foregroundStyle(BrandConstants.Colors.surface.opacity(0.9))
                }
            }
        }
        .padding(BrandConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.xl)
                .fill(BrandConstants.Colors.surface.opacity(0.15))
                .background(.ultraThinMaterial.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.xl))
        )
        .overlay(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.xl)
                .stroke(BrandConstants.Colors.surface.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 12)
    }

    private var primaryActionButton: some View {
        Button(action: handlePrimaryAction) {
            HStack {
                Spacer()
                Text(mode == .signUp ? "Create Account" : "Sign In")
                    .font(BrandConstants.Typography.headline)
                Image(systemName: "arrow.right.circle.fill")
                    .font(BrandConstants.Typography.title3)
                Spacer()
            }
            .padding(.vertical, 16)
            .foregroundStyle(Color.black)
            .background(
                LinearGradient(
                    colors: [Color.white, BrandConstants.Colors.surface.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
            .opacity(formIsValid ? 1 : 0.6)
        }
        .padding(.horizontal, 32)
        .disabled(!formIsValid || supabaseService.isLoading)
        .padding(.top, 10)
    }

    private var supplementalButtons: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            Text("or continue with")
                .font(BrandConstants.Typography.subheadline)
                .foregroundStyle(BrandConstants.Colors.surface.opacity(0.8))

            HStack(spacing: BrandConstants.Spacing.md) {
                socialButton(icon: "apple.logo")
                socialButton(icon: "globe")
                socialButton(icon: "sparkles")
            }
        }
    }

    private func socialButton(icon: String) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.headline)
                .foregroundStyle(Color.white)
                .frame(width: 48, height: 48)
                .background(BrandConstants.Colors.surface.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func handlePrimaryAction() {
        focusedField = nil

        Task {
            switch mode {
            case .signIn:
                await supabaseService.signIn(
                    email: email,
                    password: password
                )
            case .signUp:
                await supabaseService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )
            }
        }
    }
}

private struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var capitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var trailingIcon: AnyView? = nil
    var focusState: FocusState<ProductionLoginView.Field?>.Binding
    let field: ProductionLoginView.Field
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: BrandConstants.Spacing.md) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.headline)
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 22)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .foregroundColor(BrandConstants.Colors.surface)
            .textInputAutocapitalization(capitalization)
            .disableAutocorrection(true)
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .focused(focusState, equals: field)
            .submitLabel(submitLabel)
            .onSubmit {
                onSubmit?()
            }

            if let trailingIcon {
                trailingIcon
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(BrandConstants.Colors.surface.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .stroke(BrandConstants.Colors.surface.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md))
    }
}

struct ProductionMainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductionHomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass" : "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            BookingsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "calendar" : "calendar")
                    Text("Bookings")
                }
                .tag(2)

            ProductionProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ProductionHomeView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BrandConstants.Spacing.lg) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(BrandConstants.Typography.title2)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)

                                Text(supabaseService.currentUser?.name ?? "Hobbyist")
                                    .font(BrandConstants.Typography.largeTitle)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(BrandConstants.Typography.title2)
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Quick Stats
                    HStack(spacing: BrandConstants.Spacing.md) {
                        StatCard(icon: "calendar", value: "3", label: "Upcoming", color: .blue)
                        StatCard(icon: "star.fill", value: "12", label: "Completed", color: .yellow)
                    }
                    .padding(.horizontal)

                    // Featured Classes
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Featured Classes")
                                .font(BrandConstants.Typography.title3)
                                .fontWeight(.semibold)

                            Spacer()

                            Button("See All") {}
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BrandConstants.Spacing.md) {
                                ForEach(0..<3, id: \.self) { _ in
                                    FeaturedClassCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(BrandConstants.Typography.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: BrandConstants.Spacing.md) {
                            QuickActionButton(icon: "magnifyingglass", title: "Browse Classes", color: .blue)
                            QuickActionButton(icon: "calendar.badge.plus", title: "My Bookings", color: .purple)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: BrandConstants.Spacing.sm) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title2)
                .foregroundColor(color)

            Text(value)
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)

            Text(label)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(BrandConstants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

struct FeaturedClassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.6), .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 120)
                .cornerRadius(BrandConstants.CornerRadius.sm)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Yoga")
                    .font(BrandConstants.Typography.headline)

                Text("with Sarah Johnson")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(BrandConstants.Colors.primary)

                Text("$25")
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
            }
        }
        .frame(width: 200)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(BrandConstants.Typography.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
    }
}

struct ProductionProfileView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var featureFlagManager = FeatureFlagManager.shared

    var body: some View {
        Group {
            if featureFlagManager.isEnabled(.profileModule) {
                // Use new modular profile system
                ProfileCoordinator()
            } else {
                // Fallback to original profile view
                NavigationStack {
                    ScrollView {
                        VStack(spacing: BrandConstants.Spacing.lg) {
                            // Profile Header
                            VStack(spacing: BrandConstants.Spacing.md) {
                                Image(systemName: "person.circle.fill")
                                    .font(BrandConstants.Typography.heroTitle)
                                    .foregroundColor(BrandConstants.Colors.primary)

                                VStack(spacing: BrandConstants.Spacing.xs) {
                                    Text(supabaseService.currentUser?.name ?? "User")
                                        .font(BrandConstants.Typography.title2)
                                        .fontWeight(.bold)

                                    Text(supabaseService.currentUser?.email ?? "")
                                        .font(BrandConstants.Typography.subheadline)
                                        .foregroundColor(BrandConstants.Colors.secondaryText)
                                }
                            }

                            // Profile Menu
                            VStack(spacing: BrandConstants.Spacing.md) {
                                ProfileMenuItem(icon: "person.crop.circle", title: "Edit Profile")
                                ProfileMenuItem(icon: "calendar", title: "My Bookings")
                                ProfileMenuItem(icon: "heart", title: "Favorites")
                                ProfileMenuItem(icon: "gear", title: "Settings")
                                ProfileMenuItem(icon: "questionmark.circle", title: "Help & Support")
                            }
                            .padding(.horizontal)

                            // Sign Out
                            Button("Sign Out") {
                                Task {
                                    await supabaseService.signOut()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(BrandConstants.Colors.error)
                            .cornerRadius(BrandConstants.CornerRadius.md)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(BrandConstants.Typography.title2)
                    .foregroundColor(BrandConstants.Colors.primary)
                    .frame(width: 32)

                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(BrandConstants.CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
}

#Preview("Production App") {
    ProductionContentView()
        .environmentObject(SimpleSupabaseService.shared)
}

#Preview("Onboarding") {
    ProductionOnboardingView(onComplete: {})
}

#Preview("Login") {
    ProductionLoginView()
        .environmentObject(SimpleSupabaseService.shared)
}
