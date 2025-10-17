# HobbyistSwiftUI 🎨

A modern iOS application for discovering and booking hobby classes, built with SwiftUI and powered by Supabase.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-2.5.1-green.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

## 🌟 Features

### For Students
- **Browse Classes**: Discover hobby classes across 12+ categories
- **Smart Search**: Filter by location, price, difficulty, and schedule
- **Secure Booking**: Book classes with Apple Pay or credit cards
- **Credit System**: Purchase credit packs for better value
- **Gamification**: Earn achievements and track progress
- **Reviews**: Read and write class reviews
- **Notifications**: Get reminders for upcoming classes

### For Instructors
- **Class Management**: Create and manage class offerings
- **Student Analytics**: Track attendance and engagement
- **Revenue Dashboard**: Monitor earnings and payouts
- **Rating System**: Build reputation through reviews

### Technical Highlights
- **SwiftUI**: 100% SwiftUI with iOS 16+ features
- **MVVM Architecture**: Clean separation of concerns
- **Dependency Injection**: Testable and maintainable code
- **Real-time Updates**: Powered by Supabase
- **Secure Payments**: Stripe integration with PCI compliance
- **Offline Support**: Local caching and sync
- **Accessibility**: Full VoiceOver and Dynamic Type support

## 📱 Screenshots

*Coming soon*

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Supabase account
- Stripe account (for payments)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Chromeox/HobbyistSwiftUI.git
cd HobbyistSwiftUI
```

2. Open the Xcode project:
```bash
open iOS/HobbyistSwiftUI.xcodeproj
```

3. Configure environment:
```bash
cp iOS/.env.example iOS/.env
# Edit .env with your Supabase and Stripe keys
cp HobbyApp/Config-Dev.plist.template HobbyApp/Config-Dev.plist
# Populate the plist with Supabase URL/anon key (kept local, gitignored)
```

4. Install dependencies:
```bash
cd iOS
swift package resolve
```

5. Build and run:
- Select your target device/simulator
- Press ⌘R to build and run

## 🏗 Architecture

The app follows **MVVM** (Model-View-ViewModel) architecture with dependency injection:

```
iOS/HobbyistSwiftUI/
├── Models/          # Data models
├── Views/           # SwiftUI views
├── ViewModels/      # Business logic
├── Services/        # API and data services
├── Utils/           # Helpers and extensions
└── Resources/       # Assets and configs
```

### Key Components
- **ServiceContainer**: Dependency injection container
- **AuthenticationManager**: User authentication and session
- **SupabaseDataService**: Backend API integration
- **StripePaymentService**: Payment processing

## 🔧 Configuration

### Supabase Setup
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run migrations from `supabase/migrations/`
3. Configure Row Level Security policies
4. Add your Supabase URL and anon key to environment

### Stripe Setup
1. Create a Stripe account at [stripe.com](https://stripe.com)
2. Configure webhook endpoints
3. Add publishable key to iOS app
4. Add secret key to Supabase Edge Functions

## 📊 Project Structure

```
HobbyistSwiftUI/
├── iOS/                    # iOS application
│   ├── HobbyistSwiftUI/   # Source code
│   ├── Package.swift      # SPM dependencies
│   └── Documentation/     # iOS docs
├── supabase/              # Backend
│   ├── migrations/        # Database schema
│   └── functions/         # Edge functions
├── web-partner/           # Partner portal
│   └── app/              # Next.js application
└── docs/                  # Documentation
```

## 🎮 Gamification System

The app includes a comprehensive achievement system to boost engagement:

- **Attendance Achievements**: Reward consistent class attendance
- **Exploration Achievements**: Encourage trying new categories
- **Social Achievements**: Promote community engagement
- **Milestone Achievements**: Celebrate user journey milestones

## 💳 Credit System

Three-tier credit pack system for cost-effective bookings:
- **Starter Pack**: 5 credits for $25
- **Popular Pack**: 15 credits for $50 (includes 3 bonus)
- **Premium Pack**: 35 credits for $90 (includes 10 bonus)

## 🔒 Security

- **Row Level Security**: All database tables protected
- **API Key Management**: Secure storage in Keychain
- **Payment Security**: PCI DSS compliant via Stripe
- **Data Encryption**: TLS 1.3 for all communications

## 📈 Analytics

Built-in analytics track:
- User engagement metrics
- Class popularity trends
- Revenue analytics
- Conversion funnels

## 🧪 Testing

```bash
# Run unit tests
swift test

# Run UI tests
xcodebuild test -scheme HobbyistSwiftUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📄 License

This project is private and proprietary. All rights reserved.

## 🤝 Support

For support, please contact the development team.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/swiftui/)
- Powered by [Supabase](https://supabase.com)
- Payments by [Stripe](https://stripe.com)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

---

**Current Version**: 1.0.0 (Alpha)  
**Last Updated**: August 2024
