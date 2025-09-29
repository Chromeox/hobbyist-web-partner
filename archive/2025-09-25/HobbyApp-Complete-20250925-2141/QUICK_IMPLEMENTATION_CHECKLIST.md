# Quick Implementation Checklist

## 🎯 **When Designer Delivers Screens**

### **Step 1: Asset Extraction (15 minutes)**
- [ ] Export all icons as PDF vectors
- [ ] Export images in @1x, @2x, @3x formats
- [ ] Extract color palette (hex values)
- [ ] Note typography specifications
- [ ] Document spacing measurements

### **Step 2: Update Design System (30 minutes)**
- [ ] Add colors to `DesignTokens.swift`
- [ ] Update font specifications
- [ ] Adjust spacing values if needed
- [ ] Import assets into Xcode Assets.xcassets

### **Step 3: Component Customization (45 minutes)**
- [ ] Style `HobbyistButton` with designer colors
- [ ] Update `HobbyistCard` styling
- [ ] Customize navigation components
- [ ] Test components in previews

### **Step 4: Screen Implementation (Per Screen)**

#### **For Each New Screen:**
1. **Create View File** (5 minutes)
   ```swift
   struct NewScreenView: View {
       @StateObject private var viewModel = NewScreenViewModel()

       var body: some View {
           ScreenTemplate(title: "Screen Title") {
               // Content here
           }
       }
   }
   ```

2. **Build Layout Structure** (15 minutes)
   - Use VStack/HStack for basic layout
   - Add ScrollView if needed
   - Position major elements

3. **Add Components** (20 minutes)
   - Replace placeholders with `HobbyistCard`
   - Use `HobbyistButton` for actions
   - Add navigation elements

4. **Connect Data** (10 minutes)
   - Connect to existing ViewModels
   - Use database schema from `DATABASE_SYNC_GUIDE.md`
   - Test with real/mock data

5. **Polish & States** (15 minutes)
   - Add loading states using `LoadingScreenTemplate`
   - Add empty states using `EmptyStateTemplate`
   - Test error handling

---

## 🚀 **Vision-Based Implementation Strategy**

### **Use the Component Library:**
Instead of rebuilding everything, leverage what's ready:

```swift
// Quick screen implementation
ScreenTemplate(title: "Browse Classes") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]) {
            ForEach(viewModel.classes) { classItem in
                ClassCard(
                    className: classItem.name,
                    instructor: classItem.instructor,
                    time: classItem.time,
                    price: classItem.price
                ) {
                    // Navigate to detail
                }
            }
        }
        .padding()
    }
}
```

### **For Complex Layouts:**
1. **Screenshot the design** in Figma/Sketch
2. **Identify reusable components**
3. **Start with layout structure** (VStack/HStack)
4. **Add components from library**
5. **Adjust spacing using HobbyistSpacing**

---

## ⚡ **Priority Implementation Order**

### **Phase 1: Core Flow (Week 1)**
- [ ] Authentication screens (Login/Signup)
- [ ] Home/Dashboard screen
- [ ] Class browsing/search

### **Phase 2: Booking Flow (Week 2)**
- [ ] Class detail screen
- [ ] Booking confirmation
- [ ] Payment flow

### **Phase 3: User Management (Week 3)**
- [ ] Profile screen
- [ ] Booking history
- [ ] Settings

### **Phase 4: Polish (Week 4)**
- [ ] Animations and transitions
- [ ] Empty states and error handling
- [ ] Accessibility improvements

---

## 🔧 **Development Tips**

### **Use SwiftUI Previews Heavily:**
```swift
#Preview("Loading State") {
    NewScreenView()
        .onAppear {
            // Simulate loading
        }
}

#Preview("With Data") {
    NewScreenView()
        .onAppear {
            // Inject test data
        }
}
```

### **Test Multiple Device Sizes:**
- iPhone SE (small)
- iPhone 15 Pro (standard)
- iPhone 15 Pro Max (large)
- iPad (if supporting)

### **Dark Mode Testing:**
All components use semantic colors, so they should adapt automatically.

---

## 📱 **Integration with Existing Code**

Your ViewModels are ready to connect:
- `HomeViewModel` → Home screen
- `ClassDetailViewModel` → Class details
- `BookingViewModel` → Booking flow
- `SearchViewModel` → Search/browse

The Supabase integration is working (as per recent fixes), so data will flow seamlessly.

---

## 🎨 **Designer Collaboration Tips**

### **Ask for these deliverables:**
1. **Figma file** with Dev Mode enabled
2. **Component library** showing button states, cards, etc.
3. **Navigation flow** diagram
4. **Responsive behavior** notes
5. **Animation specifications** (if any)

### **Provide feedback loop:**
1. **Daily builds** showing progress
2. **Screen recordings** of implementation
3. **Questions about edge cases** (loading, errors, empty states)

---

## ✅ **Final Checklist Before Alpha**

- [ ] All screens implemented from designs
- [ ] Navigation flows working
- [ ] Data connecting from Supabase
- [ ] Loading/error states handled
- [ ] Tested on multiple device sizes
- [ ] Dark mode working
- [ ] Performance testing complete
- [ ] Ready for TestFlight!

---

**Remember**: The goal is rapid implementation, not pixel-perfect initially. Get the core functionality working first, then polish!