# Contributing to HobbyistSwiftUI

Thank you for your interest in contributing to HobbyistSwiftUI! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## 📜 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints and experiences

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- GitHub account
- Basic knowledge of SwiftUI and MVVM architecture

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   git clone https://github.com/YOUR_USERNAME/HobbyistSwiftUI.git
   cd HobbyistSwiftUI
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/Chromeox/HobbyistSwiftUI.git
   ```

3. **Install dependencies**
   ```bash
   cd iOS
   swift package resolve
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your development keys
   ```

## 💻 Development Workflow

### Branch Naming Convention

- `feature/` - New features (e.g., `feature/add-social-login`)
- `fix/` - Bug fixes (e.g., `fix/booking-crash`)
- `refactor/` - Code refactoring (e.g., `refactor/payment-service`)
- `docs/` - Documentation updates (e.g., `docs/update-readme`)
- `test/` - Test additions/fixes (e.g., `test/booking-tests`)

### Development Process

1. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow MVVM architecture patterns
   - Add appropriate comments for complex logic

3. **Test your changes**
   ```bash
   swift test
   # Also test in Xcode with different devices
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add amazing new feature"
   ```

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or fixes
- `chore:` - Maintenance tasks

Examples:
```
feat: Add user profile photo upload
fix: Resolve crash when booking without credits
docs: Update installation instructions
refactor: Simplify payment service logic
```

## 🎨 Code Style

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### Naming Conventions
```swift
// Classes and structs: PascalCase
class BookingService { }
struct UserProfile { }

// Variables and functions: camelCase
let userName = "John"
func loadUserData() { }

// Constants: camelCase (not SCREAMING_SNAKE_CASE)
let maximumRetryCount = 3

// Protocols: PascalCase, often ending in 'able', 'ible', or 'ing'
protocol Bookable { }
protocol DataLoading { }
```

#### Code Organization
```swift
// MARK: - Properties
private let service: BookingService
@Published var isLoading = false

// MARK: - Lifecycle
init(service: BookingService) {
    self.service = service
}

// MARK: - Public Methods
func bookClass(_ classItem: ClassItem) async throws {
    // Implementation
}

// MARK: - Private Methods
private func validateBooking() -> Bool {
    // Implementation
}
```

#### SwiftUI Best Practices
```swift
struct ClassDetailView: View {
    @StateObject private var viewModel: ClassDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                detailsSection
                bookingSection
            }
            .padding()
        }
        .navigationTitle("Class Details")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        // Implementation
    }
}
```

### File Organization

```
iOS/HobbyistSwiftUI/
├── Models/
│   ├── User.swift         # One model per file
│   ├── Class.swift
│   └── Booking.swift
├── Views/
│   ├── Main/              # Group related views
│   │   ├── HomeView.swift
│   │   └── MainTabView.swift
│   └── Auth/
│       ├── LoginView.swift
│       └── SignUpView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   └── AuthViewModel.swift
└── Services/
    ├── AuthenticationManager.swift
    └── DataService.swift
```

## 🧪 Testing

### Test Requirements

- All new features must include unit tests
- Maintain >70% code coverage
- Test both success and failure scenarios
- Include integration tests for critical paths

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter BookingTests

# Generate coverage report
xcodebuild test -scheme HobbyistSwiftUI -enableCodeCoverage YES
```

### Writing Tests

```swift
import XCTest
@testable import HobbyistSwiftUI

final class BookingServiceTests: XCTestCase {
    var sut: BookingService!
    var mockDataService: MockDataService!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        sut = BookingService(dataService: mockDataService)
    }
    
    override func tearDown() {
        sut = nil
        mockDataService = nil
        super.tearDown()
    }
    
    func testBookingCreation() async throws {
        // Given
        let classItem = ClassItem.mock
        
        // When
        let booking = try await sut.createBooking(for: classItem)
        
        // Then
        XCTAssertEqual(booking.classId, classItem.id)
        XCTAssertEqual(booking.status, .confirmed)
    }
}
```

## 🔄 Pull Request Process

### Before Submitting

1. **Update from upstream**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**
   ```bash
   swift test
   ```

3. **Check code style**
   ```bash
   swiftlint
   ```

4. **Update documentation** if needed

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] UI tested on iPhone and iPad
- [ ] Tested on iOS 16.0+

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No warnings in Xcode
```

### Review Process

1. Submit PR with clear description
2. Address reviewer feedback promptly
3. Keep PR focused on single concern
4. Ensure CI checks pass

## 🐛 Reporting Issues

### Bug Reports

Include:
- iOS version
- Device model
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/videos if applicable
- Crash logs if available

### Feature Requests

Include:
- Clear use case
- Proposed solution
- Alternative solutions considered
- Mockups/wireframes if applicable

## 📚 Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Style Guide](https://google.github.io/swift/)
- [MVVM Best Practices](https://www.raywenderlich.com/34-design-patterns-by-tutorials-mvvm)
- [Supabase Documentation](https://supabase.com/docs)

## 🙋 Getting Help

- Check existing issues and discussions
- Join our Discord server (coming soon)
- Contact maintainers via GitHub issues

---

Thank you for contributing to HobbyistSwiftUI! 🎉