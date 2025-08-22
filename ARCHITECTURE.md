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
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let fullName: String
    // ...
}
```

### Views

SwiftUI views that define the UI:

```swift
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    
    var body: some View {
        // UI implementation
    }
}
```

### ViewModels

Business logic and state management:

```swift
@MainActor
class HomeViewModel: ObservableObject {
    @Published var classes: [ClassItem] = []
    @Published var isLoading = false
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    func loadClasses() async {
        // Business logic
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