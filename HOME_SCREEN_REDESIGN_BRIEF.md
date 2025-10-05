# 🎨 HobbyApp Home/Discovery Screen Redesign Brief

## Overview
Redesign the main discovery/home screen to be more visually appealing with modern glassmorphic design, vibrant colors, and better visual hierarchy. The current design is functional but lacks the warmth and creativity expected from a hobby/arts discovery app.

---

## 📸 Current State Analysis

### Current Issues:
1. **Category cards** - Heavy dark gray backgrounds (#2C2C2E) lack visual interest
2. **Icons** - Simple SF Symbols on solid circles feel basic and flat
3. **Featured cards** - Plain gradient rectangles without depth or texture
4. **Overall aesthetic** - Doesn't convey the creative, warm, community-focused nature of the app
5. **Lack of depth** - No shadows, elevation, or layering
6. **Color usage** - Too monochromatic, doesn't leverage brand colors

### Current Implementation:
- File: `HobbyistSwiftUI/Views/MainTabView.swift` or similar
- Uses standard iOS dark mode styling
- Category cards: Dark gray with simple icon circles
- Featured cards: Basic gradient backgrounds
- Search bar: Standard iOS search field

---

## 🎯 Design Goals

1. **Glassmorphic aesthetic** - Frosted glass cards with blur effects
2. **Vibrant category colors** - Each category gets its own color identity
3. **Better depth** - Shadows, gradients, and layering
4. **Brand consistency** - Use BrandPrimary, BrandTeal, BrandCoral throughout
5. **Visual warmth** - Convey creativity and community
6. **Modern 2025 design** - Match current design trends

---

## 🎨 Brand Design System

### Colors (Already in Assets.xcassets)
```swift
struct BrandConstants {
    struct Colors {
        static let primary = Color("BrandPrimary")      // #2563EB - Deep Blue
        static let teal = Color("BrandTeal")            // #06B6D4 - Vibrant Teal
        static let coral = Color("BrandCoral")          // #FB7185 - Warm Coral
        static let gradientStart = Color("LandingGradientStart")  // Purple
        static let gradientEnd = Color("LandingGradientEnd")      // Pink
    }
}
```

### Category-Specific Colors
```swift
struct CategoryColors {
    static let ceramics = Color(hex: "#D97757")      // Warm terracotta/clay
    static let cooking = Color(hex: "#E8B44C")       // Golden yellow
    static let arts = Color(hex: "#B565D8")          // Rich purple
    static let photography = Color(hex: "#4A90E2")   // Sky blue
    static let music = Color(hex: "#52B788")         // Forest green
    static let movement = Color(hex: "#E63946")      // Vibrant red/pink
}
```

### Typography
- **Hero Title**: `.system(size: 32, weight: .bold)`
- **Section Title**: `.system(size: 24, weight: .bold)`
- **Card Title**: `.system(size: 18, weight: .semibold)`
- **Body**: `.system(size: 16, weight: .regular)`
- **Caption**: `.system(size: 14, weight: .medium)`

### Spacing
- xs: 4pt
- sm: 8pt
- md: 16pt
- lg: 24pt
- xl: 32pt

### Corner Radius
- sm: 12pt (small elements)
- md: 16pt (cards)
- lg: 20pt (large cards)
- xl: 24pt (modals)

---

## 📐 Component Specifications

### 1. Enhanced Header Section

```swift
struct DiscoveryHeader: View {
    @Binding var selectedLocation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Title with gradient
                    HStack(spacing: 0) {
                        Text("Discover")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(" Vancouver")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        BrandConstants.Colors.teal,
                                        BrandConstants.Colors.coral
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("Find your next creative adventure")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Location selector
                Button(action: {
                    // Show location picker
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(selectedLocation)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(BrandConstants.Colors.teal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(BrandConstants.Colors.teal.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
```

### 2. Glassmorphic Search Bar

```swift
struct GlassmorphicSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(
                    isFocused ? 
                        BrandConstants.Colors.teal : 
                        Color.white.opacity(0.6)
                )
            
            TextField("Search pottery, cooking, arts...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($isFocused)
                .submitLabel(.search)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isFocused ? 0.2 : 0.15),
                            Color.white.opacity(isFocused ? 0.12 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isFocused ? 
                                        BrandConstants.Colors.teal.opacity(0.5) :
                                        Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isFocused ? 
                BrandConstants.Colors.teal.opacity(0.3) : 
                Color.black.opacity(0.1),
            radius: isFocused ? 15 : 10,
            y: 5
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .padding(.horizontal, 20)
    }
}
```

### 3. Enhanced Category Card

```swift
struct EnhancedCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let classCount: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: color.opacity(0.4),
                            radius: isPressed ? 8 : 12,
                            y: isPressed ? 3 : 6
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(classCount) classes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .black.opacity(isPressed ? 0.15 : 0.1),
                        radius: isPressed ? 8 : 12,
                        y: isPressed ? 3 : 6
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

### 4. Enhanced Featured Class Card

```swift
struct EnhancedFeaturedCard: View {
    let title: String
    let location: String
    let studio: String
    let credits: Int
    let rating: Double
    let category: String
    let categoryColor: Color
    let imageGradient: [Color]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with gradient and icon
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: imageGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
                .overlay(
                    // Decorative icon
                    Image(systemName: icon)
                        .font(.system(size: 70, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.15))
                        .offset(x: 30, y: 20)
                        .rotationEffect(.degrees(-15))
                )
                
                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                )
                .padding(12)
            }
            
            // Details section
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BrandConstants.Colors.teal)
                        Text(location)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("at \(studio)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack {
                    Text("\(credits) credits")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BrandConstants.Colors.coral)
                    
                    Spacer()
                    
                    // Category badge
                    Text(category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(categoryColor.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
    }
}
```

### 5. Section Header Component

```swift
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BrandConstants.Colors.teal)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
```

---

## 📱 Complete Screen Layout

```swift
struct EnhancedDiscoveryView: View {
    @State private var searchText = ""
    @State private var selectedLocation = "All Vancouver"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                DiscoveryHeader(selectedLocation: $selectedLocation)
                
                // Search bar
                GlassmorphicSearchBar(searchText: $searchText)
                
                // Featured section
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Featured This Week",
                        actionTitle: "View All",
                        action: { /* Navigate */ }
                    )
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            EnhancedFeaturedCard(
                                title: "Pottery Wheel Basics",
                                location: "Commercial Drive",
                                studio: "Claymates Studio",
                                credits: 18,
                                rating: 4.8,
                                category: "Ceramics",
                                categoryColor: CategoryColors.ceramics,
                                imageGradient: [
                                    Color(hex: "#8B5A3C"),
                                    Color(hex: "#6B4423")
                                ],
                                icon: "paintpalette.fill"
                            )
                            .frame(width: 280)
                            
                            EnhancedFeaturedCard(
                                title: "Sourdough Bread Making",
                                location: "Gastown",
                                studio: "Culinary Studio",
                                credits: 20,
                                rating: 4.9,
                                category: "Cooking",
                                categoryColor: CategoryColors.cooking,
                                imageGradient: [
                                    Color(hex: "#D4A574"),
                                    Color(hex: "#B8860B")
                                ],
                                icon: "fork.knife"
                            )
                            .frame(width: 280)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Categories section
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Explore by Category",
                        actionTitle: nil,
                        action: nil
                    )
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        EnhancedCategoryCard(
                            title: "Ceramics",
                            icon: "paintpalette.fill",
                            color: CategoryColors.ceramics,
                            classCount: 12,
                            action: { /* Navigate */ }
                        )
                        
                        EnhancedCategoryCard(
                            title: "Cooking & Baking",
                            icon: "fork.knife",
                            color: CategoryColors.cooking,
                            classCount: 15,
                            action: { /* Navigate */ }
                        )
                        
                        EnhancedCategoryCard(
                            title: "Arts & Crafts",
                            icon: "paintbrush.fill",
                            color: CategoryColors.arts,
                            classCount: 10,
                            action: { /* Navigate */ }
                        )
                        
                        EnhancedCategoryCard(
                            title: "Photography",
                            icon: "camera.fill",
                            color: CategoryColors.photography,
                            classCount: 7,
                            action: { /* Navigate */ }
                        )
                        
                        EnhancedCategoryCard(
                            title: "Music & Sound",
                            icon: "music.note",
                            color: CategoryColors.music,
                            classCount: 9,
                            action: { /* Navigate */ }
                        )
                        
                        EnhancedCategoryCard(
                            title: "Movement",
                            icon: "figure.dance",
                            color: CategoryColors.movement,
                            classCount: 6,
                            action: { /* Navigate */ }
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Popular Studios section (if needed)
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Popular Studios",
                        actionTitle: "View All",
                        action: { /* Navigate */ }
                    )
                    
                    // Studio cards here
                }
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top, 8)
        }
        .background(
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1a1a2e"),
                    Color(hex: "#16213e"),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
```

---

## 🎨 Color Hex Extension

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## 📋 Implementation Checklist

### Phase 1: Setup
- [ ] Add Color hex extension
- [ ] Create CategoryColors struct
- [ ] Verify BrandConstants are accessible

### Phase 2: Components
- [ ] Create DiscoveryHeader component
- [ ] Create GlassmorphicSearchBar component
- [ ] Create EnhancedCategoryCard component
- [ ] Create EnhancedFeaturedCard component
- [ ] Create SectionHeader component

### Phase 3: Main View
- [ ] Create EnhancedDiscoveryView
- [ ] Replace existing home/discovery view
- [ ] Test all interactions
- [ ] Verify animations work smoothly

### Phase 4: Polish
- [ ] Add haptic feedback on button presses
- [ ] Test on different screen sizes
- [ ] Optimize performance
- [ ] Add accessibility labels

---

## 🎯 Success Criteria

- [ ] Visual consistency with LandingPageView design
- [ ] Glassmorphic effects applied throughout
- [ ] Category cards use vibrant, distinct colors
- [ ] Featured cards have depth and visual interest
- [ ] Search bar has focus states and animations
- [ ] All interactions feel smooth and responsive
- [ ] Dark gradient background creates proper atmosphere
- [ ] Brand colors (Teal, Coral, Primary) used consistently
- [ ] Typography hierarchy is clear
- [ ] Shadows and elevation create proper depth

---

## 📸 Visual Reference

Current design shows:
- Dark gray category cards (#2C2C2E)
- Simple icon circles
- Basic featured card gradients
- Standard search bar

New design will have:
- Glassmorphic category cards with gradient icon backgrounds
- Vibrant category-specific colors
- Enhanced featured cards with decorative elements
- Modern search bar with glow effects
- Better visual hierarchy and depth

---

*This design brief is ready for implementation in SwiftUI. All components follow iOS design patterns and use native SwiftUI features for optimal performance.*