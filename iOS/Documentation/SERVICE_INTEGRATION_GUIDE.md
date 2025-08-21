# Service Integration Guide - Complete Implementation

## 🎯 Overview

This guide shows how all services are integrated to create a seamless user experience:
- **Supabase**: Real-time data and authentication
- **Stripe**: Payment processing
- **Push Notifications**: User engagement
- **Haptic Feedback**: Premium UX
- **Apple Watch**: Companion experience

## 🔄 Complete Integration Flow

### 1. App Launch & Authentication

```swift
// AppDelegate.swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize services
        ServiceContainer.shared.initialize()
        
        // Setup push notifications
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared
        
        // Configure Stripe
        StripeAPI.defaultPublishableKey = Configuration.stripePublishableKey
        
        return true
    }
    
    func application(_ application: UIApplication, 
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.updateDeviceToken(deviceToken)
    }
}
```

### 2. Main App Structure with Services

```swift
// HobbyistSwiftUIApp.swift
@main
struct HobbyistSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var dataService = SupabaseDataService.shared
    @StateObject private var paymentService = StripePaymentService.shared
    @StateObject private var notificationService = PushNotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(dataService)
                .environmentObject(paymentService)
                .environmentObject(notificationService)
                .environmentObject(HapticFeedbackService.shared)
                .onAppear {
                    setupServices()
                }
        }
    }
    
    private func setupServices() {
        Task {
            // Request notification permissions
            await notificationService.requestAuthorization()
            
            // Setup real-time subscriptions
            await dataService.setupRealTimeSubscriptions()
            
            // Load saved payment methods
            paymentService.loadSavedPaymentMethods()
        }
    }
}
```

### 3. Authentication Flow Integration

```swift
// LoginView.swift - Enhanced with services
struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataService: SupabaseDataService
    @EnvironmentObject var notificationService: PushNotificationService
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    func performLogin() {
        Task {
            do {
                // Perform authentication
                try await authManager.signIn(email: email, password: password)
                
                // Play success haptic
                hapticService.playLoginSuccess()
                
                // Load user data
                await dataService.fetchUserBookings()
                
                // Register for notifications
                await notificationService.requestAuthorization()
                
            } catch {
                // Play error haptic
                hapticService.playError()
            }
        }
    }
}
```

### 4. Class Discovery with Real-time Data

```swift
// HomeView.swift - Connected to Supabase
struct HomeView: View {
    @EnvironmentObject var dataService: SupabaseDataService
    @State private var featuredClasses: [ClassItem] = []
    @State private var nearbyClasses: [ClassItem] = []
    
    var body: some View {
        ScrollView {
            // Content...
        }
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }
    
    private func loadData() async {
        // Fetch featured classes
        featuredClasses = await dataService.fetchFeaturedClasses()
        
        // Fetch nearby classes based on location
        if let location = LocationManager.shared.currentLocation {
            nearbyClasses = await dataService.fetchNearbyClasses(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }
}
```

### 5. Complete Booking Flow with Payment

```swift
// BookingFlowView.swift - Full integration
struct BookingFlowView: View {
    @EnvironmentObject var dataService: SupabaseDataService
    @EnvironmentObject var paymentService: StripePaymentService
    @EnvironmentObject var notificationService: PushNotificationService
    @EnvironmentObject var hapticService: HapticFeedbackService
    @StateObject private var watchSync = BookingWatchSyncService()
    
    func processBooking() async {
        do {
            // Step 1: Prepare payment
            hapticService.playPaymentProcessing()
            watchSync.updatePaymentProgress(0.25)
            
            try await paymentService.preparePaymentSheet(
                for: viewModel.totalPrice,
                classId: classItem.id,
                className: classItem.name
            )
            
            // Step 2: Present payment sheet
            watchSync.updatePaymentProgress(0.5)
            let result = await paymentService.presentPaymentSheet(from: getRootViewController())
            
            switch result {
            case .success:
                // Step 3: Create booking in Supabase
                watchSync.updatePaymentProgress(0.75)
                let bookingId = try await dataService.createBooking(
                    classId: classItem.id,
                    participantCount: viewModel.participantCount,
                    totalAmount: viewModel.totalPrice,
                    paymentIntentId: paymentService.paymentSheet?.intentConfiguration.intentClientSecret ?? "",
                    specialRequests: viewModel.specialRequests
                )
                
                // Step 4: Complete booking
                watchSync.updatePaymentProgress(1.0)
                hapticService.playBookingSuccess()
                
                // Step 5: Schedule notifications
                await notificationService.scheduleBookingConfirmation(
                    bookingId: bookingId,
                    className: classItem.name,
                    confirmationCode: viewModel.confirmationCode
                )
                
                await notificationService.scheduleClassReminder(
                    classId: classItem.id,
                    className: classItem.name,
                    classTime: classItem.startTime
                )
                
                // Step 6: Sync with Apple Watch
                watchSync.sendBookingConfirmation(
                    classItem.name,
                    date: classItem.startTime,
                    confirmationCode: viewModel.confirmationCode
                )
                
                // Step 7: Navigate to confirmation
                viewModel.bookingComplete = true
                currentStep = 4
                
            case .canceled:
                hapticService.playWarning()
                
            case .failed(let error):
                hapticService.playError()
                showError(error)
            }
            
        } catch {
            hapticService.playError()
            showError(error)
        }
    }
}
```

### 6. Real-time Updates Integration

```swift
// ClassDetailView.swift - Live spot updates
struct ClassDetailView: View {
    @EnvironmentObject var dataService: SupabaseDataService
    @State private var classItem: ClassItem
    @State private var spotsAvailable: Int
    
    var body: some View {
        ScrollView {
            // Content showing spots available
            Text("\(spotsAvailable) spots left")
                .foregroundColor(spotsAvailable < 3 ? .red : .green)
        }
        .onAppear {
            subscribeToUpdates()
        }
    }
    
    private func subscribeToUpdates() {
        // Real-time subscription to class updates
        dataService.$classes
            .compactMap { classes in
                classes.first { $0.id == classItem.id }
            }
            .receive(on: DispatchQueue.main)
            .sink { updatedClass in
                self.spotsAvailable = updatedClass.spotsAvailable
                
                // Haptic feedback for spot changes
                if spotsAvailable < 3 {
                    HapticFeedbackService.shared.playWarning()
                }
            }
            .store(in: &cancellables)
    }
}
```

### 7. Push Notification Handling

```swift
// ContentView.swift - Handle deep links
struct ContentView: View {
    @EnvironmentObject var notificationService: PushNotificationService
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab content
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToClass)) { notification in
            if let classId = notification.userInfo?["class_id"] as? String {
                navigateToClass(classId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBooking)) { notification in
            if let bookingId = notification.userInfo?["booking_id"] as? String {
                navigateToBooking(bookingId)
            }
        }
    }
    
    private func navigateToClass(_ classId: String) {
        Task {
            if let classItem = await dataService.fetchClassById(classId) {
                navigationPath.append(classItem)
            }
        }
    }
}
```

### 8. Apple Pay Integration

```swift
// PaymentSelectionStep.swift - Apple Pay
struct PaymentSelectionStep: View {
    @EnvironmentObject var paymentService: StripePaymentService
    
    func processApplePayPayment() {
        Task {
            do {
                try await paymentService.processApplePayPayment(
                    for: viewModel.totalPrice,
                    classId: classItem.id,
                    className: classItem.name,
                    from: getRootViewController()
                )
                
                // Handle success
                viewModel.bookingComplete = true
                
            } catch {
                showError(error)
            }
        }
    }
}
```

## 📊 Data Flow Diagram

```
User Action → UI Layer → Service Layer → Backend
    ↓           ↓            ↓             ↓
  Haptic    ViewModel    Supabase     Edge Function
 Feedback               /Stripe API
    ↓           ↓            ↓             ↓
  Watch     State       Database     Notification
  Sync      Update       Update        Service
```

## 🔔 Notification Flow

1. **Booking Confirmation**
   - Payment Success → Create Booking → Send Notification → Update UI

2. **Class Reminder**
   - Schedule on Booking → Trigger 24h/1h before → Deep link to class

3. **Real-time Updates**
   - Database Change → WebSocket → UI Update → Optional Notification

## 💳 Payment Flow

1. **Initialize**
   - Create Payment Intent (Backend)
   - Prepare Payment Sheet (Frontend)

2. **Process**
   - Present Sheet/Apple Pay
   - Handle 3D Secure if needed
   - Confirm Payment

3. **Complete**
   - Create Booking Record
   - Send Confirmation
   - Update UI

## 🔐 Security Considerations

1. **API Keys**
   - Never expose Stripe secret key
   - Use environment variables
   - Rotate keys regularly

2. **Authentication**
   - Always verify user session
   - Use Supabase RLS policies
   - Implement proper error handling

3. **Payment Security**
   - PCI compliance via Stripe
   - Never store card details
   - Use payment methods API

## 🚀 Production Checklist

- [ ] Configure production Supabase URL
- [ ] Set production Stripe keys
- [ ] Configure push notification certificates
- [ ] Enable crash reporting
- [ ] Setup analytics tracking
- [ ] Configure deep linking
- [ ] Test payment flows
- [ ] Verify notification delivery
- [ ] Test offline capabilities
- [ ] Implement error recovery

## 📱 Testing Integration

```swift
// Integration Test Example
func testCompleteBookingFlow() async throws {
    // 1. Authenticate
    try await authManager.signIn(email: "test@example.com", password: "password")
    
    // 2. Fetch class
    let classes = await dataService.fetchClasses()
    let classItem = try XCTUnwrap(classes.first)
    
    // 3. Create payment intent
    let intent = try await paymentService.createPaymentIntent(
        amount: 25.0,
        classId: classItem.id,
        userId: authManager.currentUser.id,
        participantCount: 1
    )
    
    // 4. Confirm payment (test mode)
    // ... payment confirmation
    
    // 5. Create booking
    let bookingId = try await dataService.createBooking(
        classId: classItem.id,
        participantCount: 1,
        totalAmount: 25.0,
        paymentIntentId: intent.clientSecret
    )
    
    // 6. Verify booking created
    await dataService.fetchUserBookings()
    XCTAssertTrue(dataService.userBookings.contains { $0.id == bookingId })
}
```

## 🎯 Key Integration Points

1. **ServiceContainer** - Central dependency injection
2. **EnvironmentObject** - SwiftUI state propagation
3. **Combine Publishers** - Reactive data flow
4. **Async/Await** - Modern concurrency
5. **Real-time Subscriptions** - Live updates
6. **Deep Linking** - Navigation from notifications
7. **Haptic Coordination** - Multi-device feedback