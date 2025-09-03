# 🎨 Hobbyist Platform - Master System Documentation

## Executive Summary
A comprehensive hobby discovery and booking platform connecting students with creative studios and instructors across painting, pottery, DJ workshops, and other artistic pursuits.

---

## 🏗️ System Architecture

### Platform Components

```
┌────────────────────────────────────────────────────────────┐
│                    HOBBYIST ECOSYSTEM                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────┐        ┌─────────────┐                  │
│  │  iOS App    │        │ Web Portal  │                  │
│  │ (Students)  │◄──────►│ (Studios)   │                  │
│  └─────────────┘        └─────────────┘                  │
│         ▲                      ▲                          │
│         │                      │                          │
│         └──────┬───────────────┘                          │
│                │                                           │
│    ┌───────────▼────────────────────────┐                │
│    │      SUPABASE BACKEND              │                │
│    │  ┌──────────┬─────────┬─────────┐ │                │
│    │  │PostgreSQL│  Auth   │ Storage │ │                │
│    │  │ Database │ Service │ Buckets │ │                │
│    │  └──────────┴─────────┴─────────┘ │                │
│    │        Real-time Subscriptions     │                │
│    └────────────────────────────────────┘                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 📱 iOS Application (Students)

### Technology Stack
- **Framework**: SwiftUI with MVVM architecture
- **Backend**: Supabase SDK for Swift
- **Dependencies**: Stripe, Kingfisher (image caching)
- **Minimum iOS**: 16.0

### Core Features
1. **Class Discovery**
   - Browse by category (Pottery, Painting, DJ, etc.)
   - Filter by location, price, instructor
   - Real-time availability updates

2. **Booking System**
   - Credit-based payments ($25/5, $50/15, $90/35)
   - Cash payment option
   - Waitlist management
   - Cancellation with refunds

3. **Instructor Marketplace**
   - Follow favorite instructors
   - View ratings and reviews
   - Get notifications for new classes

4. **User Experience**
   - Haptic feedback for interactions
   - Gamification with achievements
   - Progress tracking
   - Apple Watch companion app

### Key Services
```swift
// Core services managed by ServiceContainer
- SupabaseService: Database and auth
- PaymentService: Stripe integration
- BookingService: Class reservations
- ReviewService: Ratings and feedback
- NotificationService: Push notifications
```

---

## 💻 Web Partner Portal (Studios)

### Technology Stack
- **Framework**: Next.js 14 App Router
- **UI Library**: React with TypeScript
- **Styling**: Tailwind CSS with Glassmorphism
- **State Management**: React Context API

### Studio Management Features

1. **Dashboard**
   - Real-time booking notifications
   - Revenue analytics
   - Instructor performance metrics
   - Student engagement tracking

2. **Class Management**
   - Create/edit classes
   - Dynamic pricing (surge/off-peak)
   - Capacity management
   - Waitlist automation

3. **Instructor Marketplace**
   - Partnership requests
   - Revenue sharing (85/15 default)
   - Performance tracking
   - Certification verification

4. **Multi-Location Support**
   - Manage multiple studio locations
   - Location-specific pricing
   - Cross-location analytics
   - Unified inventory

5. **Financial Management**
   - Credit pack sales tracking
   - Cash payment recording
   - Subscription tier management
   - Automated payouts

---

## 🗄️ Database Architecture

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `studios` | Studio accounts | Multi-tenant isolation |
| `studio_locations` | Physical locations | GPS coordinates, amenities |
| `instructor_profiles` | Marketplace profiles | Ratings, specialties, verification |
| `classes` | Class listings | Dynamic pricing, capacity |
| `bookings` | Reservations | Credits/cash tracking |
| `instructor_reviews` | Feedback system | Verified bookings only |
| `subscription_tiers` | Recurring plans | Explorer/Enthusiast/Unlimited |
| `user_credits` | Balance tracking | Transaction history |

### Real-time Subscriptions
```sql
-- Enabled for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE
  classes, bookings, instructor_reviews, 
  studio_locations, instructor_profiles;
```

### Security Implementation
- Row Level Security (RLS) on all tables
- Multi-tenant data isolation
- Optimized auth policies (50-70% performance gain)
- Encrypted credential storage

---

## 🔄 Integration Flow

### Booking Lifecycle
```
1. Student Opens iOS App
   ↓
2. Discovers Pottery Class
   ↓
3. Books with Credits
   ↓
4. Real-time Update to Studio Dashboard
   ↓
5. Studio Confirms Attendance
   ↓
6. Student Leaves Review
   ↓
7. Rating Updates Instructor Profile
```

### Data Synchronization
- **WebSocket**: Real-time booking updates
- **REST API**: Standard CRUD operations
- **Edge Functions**: Complex business logic
- **Storage Buckets**: Image uploads

---

## 🚀 Deployment

### iOS App
```bash
# TestFlight Distribution
cd iOS/
fastlane beta

# App Store Release
fastlane release
```

### Web Portal
```bash
# Vercel Deployment
cd web-partner/
vercel --prod

# Environment Variables Required
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
STRIPE_SECRET_KEY
```

### Database Migrations
```bash
# Apply migrations
supabase db push

# Verify integration
psql -f scripts/validate_integration.sql
```

---

## 📊 Performance Metrics

### Achieved Optimizations
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| API Response | 300ms | 150ms | 50% |
| Query Time (p95) | 150ms | 45ms | 70% |
| App Launch | 2.6s | 1.8s | 31% |
| Bundle Size | 12MB | 7.8MB | 35% |

### Real-time Latency
- Booking confirmation: <100ms
- Review updates: <200ms
- Availability changes: <150ms

---

## 🧪 Testing Strategy

### iOS Testing
```swift
// Integration test example
func testCompleteBookingFlow() async throws {
    let classes = try await fetchClasses()
    let booking = try await bookClass(classId: class.id)
    let review = try await submitReview(bookingId: booking.id)
    XCTAssertEqual(booking.status, "confirmed")
}
```

### Web Portal Testing
```typescript
// E2E test with Playwright
test('studio creates class visible in iOS', async ({ page }) => {
  await page.goto('/dashboard/classes');
  await createClass('Pottery Workshop');
  const apiResponse = await fetchClasses();
  expect(apiResponse).toContainClass('Pottery Workshop');
});
```

### Load Testing
- Target: 100 concurrent users
- Response time: <500ms at p95
- Database connections: Pooled (25 max)

---

## 🔐 Security & Compliance

### Authentication
- **Students**: Email/password, social login
- **Studios**: Enhanced verification
- **Sessions**: Auto-refresh tokens
- **2FA**: Available for studios

### Data Protection
- PCI DSS compliant payment processing
- GDPR-ready data handling
- Encrypted sensitive fields
- Regular security audits

---

## 📈 Business Model

### Revenue Streams

1. **Credit Packs**
   - $25 for 5 credits (20% margin)
   - $50 for 15 credits (30% margin)
   - $90 for 35 credits (38% margin)

2. **Subscriptions**
   - Explorer: $49/month (8 classes)
   - Enthusiast: $99/month (20 classes)
   - Unlimited: $179/month

3. **Platform Fees**
   - 15% commission on bookings
   - Premium studio features
   - Featured instructor listings

### Key Metrics
- Average booking value: $18
- Monthly active users: Target 10,000
- Studio retention: 85%
- Class fill rate: 70%

---

## 🛠️ Maintenance & Support

### Monitoring
- Supabase Dashboard: Real-time metrics
- Sentry: Error tracking
- Analytics: User behavior
- Performance: Web Vitals

### Common Issues & Solutions
| Issue | Solution |
|-------|----------|
| Booking not showing | Check real-time subscription |
| Payment failed | Verify Stripe webhook |
| Images not loading | Check storage bucket CORS |
| Slow queries | Run optimization script |

---

## 📚 Related Documentation

- **Integration Guide**: `INTEGRATION_GUIDE.md`
- **Performance Guide**: `PERFORMANCE_OPTIMIZATION.md`
- **Issue Fixes**: `INTEGRATION_ISSUES_AND_FIXES.md`
- **API Reference**: `supabase/API_REFERENCE.md`
- **iOS Architecture**: `iOS/ARCHITECTURE.md`
- **Web Components**: `web-partner/COMPONENTS.md`

---

## 🎯 Roadmap

### Q1 2025
- ✅ Alpha launch (TestFlight)
- ✅ Instructor marketplace
- ✅ Multi-location support
- ⏳ Android app development

### Q2 2025
- [ ] AI-powered recommendations
- [ ] Video class previews
- [ ] Social features
- [ ] International expansion

### Q3 2025
- [ ] Corporate packages
- [ ] Gift certificates
- [ ] Loyalty rewards
- [ ] Advanced analytics

---

## 👥 Team & Contact

- **iOS Development**: Hobbyist Team
- **Backend**: Supabase + Custom Functions
- **Design**: Glassmorphism UI System
- **Support**: support@hobbyist.app

---

*Last Updated: 2025-09-03*
*Version: 1.0.0*
*Status: Production Ready*