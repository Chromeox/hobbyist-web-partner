# HobbyistSwiftUI Architecture

## Overview

HobbyistSwiftUI follows the **MVVM (Model-View-ViewModel)** architectural pattern with **Dependency Injection** for better testability and maintainability.

## 🏗 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  (HomeView, ClassDetailView, BookingView, ProfileView)      │
└─────────────────┬───────────────────────────────────────────┘
                  │ @StateObject / @ObservedObject
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModels                            │
│  (HomeViewModel, ClassDetailViewModel, BookingViewModel)     │
└─────────────────┬───────────────────────────────────────────┘
                  │ Dependency Injection
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Container                        │
│            (Centralized Dependency Management)               │
└─────────────────┬───────────────────────────────────────────┘
                  │
        ┌─────────┴──────────┬──────────┬───────────┐
        ▼                    ▼          ▼           ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Auth Service  │  │ Data Service  │  │Payment Service│  │ Cache Service │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └───────────────┘
        │                  │                   │
        └──────────────────┴───────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Supabase   │
                    │   Backend   │
                    └─────────────┘
```

## 📁 Project Structure

```
iOS/HobbyistSwiftUI/
├── App/
│   ├── HobbyistSwiftUIApp.swift    # App entry point
│   └── ContentView.swift           # Root view
├── Models/
│   ├── User.swift                  # User data model
│   ├── Class.swift                 # Class data model
│   ├── Booking.swift               # Booking data model
│   └── Payment.swift               # Payment models
├── Views/
│   ├── Main/
│   │   ├── HomeView.swift
│   │   ├── MainTabView.swift
│   │   └── ClassDetailView.swift
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   └── Booking/
│       └── BookingFlowView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── AuthViewModel.swift
│   └── BookingViewModel.swift
├── Services/
│   ├── ServiceContainer.swift      # DI container
│   ├── AuthenticationManager.swift
│   ├── SupabaseDataService.swift
│   └── StripePaymentService.swift
├── Utils/
│   ├── Extensions/
│   └── Helpers/
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

## 🎯 Core Components

### Models

Data structures that represent the app's domain entities:

```swift
// User.swift - Complete example with all properties
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    var profileImageUrl: String?
    var phoneNumber: String?
    var bio: String?
    var isEmailVerified: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case createdAt = "created_at"
        case profileImageUrl = "profile_image_url"
        case phoneNumber = "phone_number"
        case bio
        case isEmailVerified = "is_email_verified"
    }
}

// Booking.swift - Example with computed properties
struct Booking: Identifiable, Codable {
    let id: String
    let classId: String
    let userId: String
    let status: BookingStatus
    let confirmationCode: String
    let classStartDate: Date
    let totalAmount: Double
    
    // Computed properties for business logic
    var canBeCancelled: Bool {
        status == .confirmed && 
        classStartDate.timeIntervalSinceNow > 24 * 60 * 60
    }
    
    var refundAmount: Double {
        guard canBeCancelled else { return 0 }
        let hoursUntilClass = classStartDate.timeIntervalSinceNow / 3600
        
        if hoursUntilClass > 72 {
            return totalAmount // Full refund
        } else if hoursUntilClass > 48 {
            return totalAmount * 0.75 // 75% refund
        } else {
            return totalAmount * 0.5 // 50% refund
        }
    }
}
```

### Views

SwiftUI views that define the UI:

```swift
// HomeView.swift - Complete view with error handling and loading states
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedCategory: ClassCategory?
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading classes...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task { await viewModel.loadClasses() }
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        CategoryFilterView(
                            selectedCategory: $selectedCategory,
                            onCategorySelected: { category in
                                viewModel.filterByCategory(category)
                            }
                        )
                        
                        ForEach(viewModel.filteredClasses) { classItem in
                            NavigationLink(value: classItem) {
                                ClassCardView(classItem: classItem)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover Classes")
            .navigationDestination(for: ClassItem.self) { classItem in
                ClassDetailView(classItem: classItem)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.refreshClasses()
            }
        }
        .task {
            await viewModel.loadClasses()
        }
    }
}

// ClassCardView.swift - Reusable component
struct ClassCardView: View {
    let classItem: ClassItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image with gradient overlay
            AsyncImage(url: URL(string: classItem.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(height: 200)
            .clipped()
            .overlay(alignment: .topTrailing) {
                PriceTag(price: classItem.price, credits: classItem.creditCost)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(classItem.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label(classItem.instructor.name, systemImage: "person")
                    Spacer()
                    Label("\(classItem.duration) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    DifficultyBadge(level: classItem.difficulty)
                    Spacer()
                    AvailabilityIndicator(
                        available: classItem.availableSpots,
                        total: classItem.maxParticipants
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.1),
            radius: 8,
            y: 4
        )
    }
}
```

### ViewModels

Business logic and state management:

```swift
// HomeViewModel.swift - Complete implementation with filtering and error handling
@MainActor
class HomeViewModel: ObservableObject {
    @Published var classes: [ClassItem] = []
    @Published var filteredClasses: [ClassItem] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var selectedFilters = FilterOptions()
    
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private var loadTask: Task<Void, Never>?
    
    init(
        dataService: DataServiceProtocol = ServiceContainer.shared.dataService,
        analyticsService: AnalyticsServiceProtocol = ServiceContainer.shared.analyticsService
    ) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func loadClasses() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        loadTask = Task {
            isLoading = true
            error = nil
            
            do {
                let fetchedClasses = try await dataService.fetchClasses()
                
                // Check for task cancellation
                guard !Task.isCancelled else { return }
                
                self.classes = fetchedClasses
                self.applyFilters()
                
                // Track analytics
                analyticsService.track("classes_loaded", properties: [
                    "count": fetchedClasses.count,
                    "source": "home_screen"
                ])
            } catch let error as AppError {
                self.error = error
            } catch {
                self.error = .unknown(error.localizedDescription)
            }
            
            isLoading = false
        }
    }
    
    func refreshClasses() async {
        // Force refresh from server
        await loadClasses()
    }
    
    func filterByCategory(_ category: ClassCategory?) {
        selectedFilters.category = category
        applyFilters()
    }
    
    private func applyFilters() {
        filteredClasses = classes.filter { classItem in
            // Category filter
            if let category = selectedFilters.category,
               classItem.category != category {
                return false
            }
            
            // Price filter
            if let maxPrice = selectedFilters.maxPrice,
               classItem.price > maxPrice {
                return false
            }
            
            // Difficulty filter
            if let difficulty = selectedFilters.difficulty,
               classItem.difficulty != difficulty {
                return false
            }
            
            // Availability filter
            if selectedFilters.showOnlyAvailable && !classItem.isAvailable {
                return false
            }
            
            return true
        }
    }
    
    deinit {
        loadTask?.cancel()
    }
}

// FilterOptions.swift - Filtering model
struct FilterOptions {
    var category: ClassCategory?
    var maxPrice: Double?
    var difficulty: DifficultyLevel?
    var showOnlyAvailable = true
    var sortBy: SortOption = .dateAscending
    
    enum SortOption {
        case dateAscending
        case dateDescending
        case priceAscending
        case priceDescending
        case popularity
    }
}
```

### Services

External dependencies and data sources:

```swift
protocol DataServiceProtocol {
    func fetchClasses() async throws -> [ClassItem]
}

class SupabaseDataService: DataServiceProtocol {
    func fetchClasses() async throws -> [ClassItem] {
        // Supabase implementation
    }
}
```

### Service Container

Centralized dependency injection:

```swift
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private(set) var authManager: AuthenticationManager!
    private(set) var dataService: DataServiceProtocol!
    
    func configure() {
        authManager = AuthenticationManager()
        dataService = SupabaseDataService()
    }
}
```

## 🔄 Data Flow

1. **User Interaction** → View receives user input
2. **View → ViewModel** → View calls ViewModel method
3. **ViewModel → Service** → ViewModel uses injected service
4. **Service → API** → Service makes network request
5. **API → Service** → Service receives response
6. **Service → ViewModel** → Service returns data to ViewModel
7. **ViewModel → View** → ViewModel updates @Published properties
8. **View Update** → SwiftUI re-renders with new data

## 💉 Dependency Injection

### Benefits
- **Testability**: Easy to mock services for testing
- **Flexibility**: Swap implementations without changing code
- **Separation of Concerns**: Clear boundaries between layers

### Implementation

```swift
// Protocol definition
protocol PaymentServiceProtocol {
    func processPayment(_ amount: Double) async throws
}

// Concrete implementation
class StripePaymentService: PaymentServiceProtocol {
    func processPayment(_ amount: Double) async throws {
        // Stripe implementation
    }
}

// Mock for testing
class MockPaymentService: PaymentServiceProtocol {
    func processPayment(_ amount: Double) async throws {
        // Mock implementation
    }
}

// Usage in ViewModel
class BookingViewModel: ObservableObject {
    private let paymentService: PaymentServiceProtocol
    
    init(paymentService: PaymentServiceProtocol = ServiceContainer.shared.paymentService) {
        self.paymentService = paymentService
    }
}
```

## 🔐 Security Architecture

### Authentication Flow

```
┌──────────┐     ┌───────────────┐     ┌──────────┐
│   User   │────▶│ Auth Manager  │────▶│ Supabase │
└──────────┘     └───────────────┘     └──────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │   Keychain    │
                 └───────────────┘
```

### Data Security
- **Keychain**: Secure storage for sensitive data
- **TLS 1.3**: All network communications encrypted
- **Row Level Security**: Database-level access control
- **Token Management**: Automatic refresh and validation

## 🎮 State Management

### Local State
- `@State`: View-specific state
- `@StateObject`: ViewModel ownership
- `@ObservedObject`: Shared ViewModel reference
- `@EnvironmentObject`: App-wide shared state

### Global State
- **AuthenticationManager**: User session state
- **NavigationManager**: Navigation state
- **ServiceContainer**: Service instances

## 🚀 Performance Optimizations

### Lazy Loading
```swift
LazyVStack {
    ForEach(classes) { classItem in
        ClassRowView(classItem: classItem)
    }
}
```

### Image Caching
- Kingfisher for efficient image loading and caching
- Thumbnail generation for list views
- Progressive loading for detail views

### Data Caching
```swift
class CacheService {
    private let cache = NSCache<NSString, AnyObject>()
    
    func set(_ object: AnyObject, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
    }
}
```

## 🧪 Testing Architecture

### Unit Tests
```swift
// Test ViewModel with mock service
func testLoadClasses() async {
    let mockService = MockDataService()
    let viewModel = HomeViewModel(dataService: mockService)
    
    await viewModel.loadClasses()
    
    XCTAssertFalse(viewModel.classes.isEmpty)
}
```

### Integration Tests
- Test actual service implementations
- Verify API interactions
- Validate data transformations

### UI Tests
- User flow testing
- Accessibility testing
- Performance testing

## 📊 Analytics Architecture

```swift
protocol AnalyticsServiceProtocol {
    func track(_ event: String, properties: [String: Any]?)
}

class AnalyticsService: AnalyticsServiceProtocol {
    func track(_ event: String, properties: [String: Any]?) {
        // Firebase Analytics implementation
    }
}
```

## 🔄 Migration Strategy

### Database Migrations
- Versioned migration files in `supabase/migrations/`
- Rollback capabilities
- Data validation scripts

### App Updates
- Version checking on launch
- Force update capability
- Graceful degradation for older versions

## 📱 Platform Support

### iOS
- Minimum: iOS 16.0
- Target: iOS 17.0+
- Universal app (iPhone & iPad)

### Future Platforms
- watchOS companion app (planned)
- macOS Catalyst support (planned)
- visionOS support (planned)

## 🎨 Design System

### Colors
- Semantic colors using Color assets
- Dark mode support
- Dynamic color adaptation

### Typography
- SF Pro Display for headers
- SF Pro Text for body
- Dynamic Type support

### Components
- Reusable view components
- Consistent spacing system
- Adaptive layouts

## 🔌 Third-Party Integrations

### Supabase
- Authentication
- Real-time database
- File storage
- Edge functions

### Stripe
- Payment processing
- Subscription management
- Invoice generation

### Firebase
- Crashlytics
- Analytics
- Performance monitoring

## 📈 Scalability Considerations

### Horizontal Scaling
- Stateless service design
- Load balancer ready
- CDN for static assets

### Vertical Scaling
- Efficient algorithms
- Memory management
- Background processing

### Database Scaling
- Indexed queries
- Connection pooling
- Read replicas (future)

---

For more detailed information about specific components, refer to the inline documentation in the source code.