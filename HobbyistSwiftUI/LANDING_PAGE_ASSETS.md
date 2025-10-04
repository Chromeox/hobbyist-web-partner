# Landing Page Assets Guide

## 📦 Asset Catalog Structure

I've created the following asset catalog structure for your landing page:

```
HobbyistSwiftUI/Assets.xcassets/
├── LandingPage/
│   ├── HeroIllustration.imageset/
│   ├── CreativeWorkspace.imageset/
│   └── GroupLearning.imageset/
└── Colors/
    ├── LandingGradientStart.colorset/
    └── LandingGradientEnd.colorset/
```

## 🖼️ Image Assets

### 1. Hero Illustration
**Asset Name:** `HeroIllustration`
**Recommended Image URL:**
```
https://images.unsplash.com/photo-1662845114342-256fdc45981d?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTAwNDR8MHwxfHNlYXJjaHwyfHxwZW9wbGUlMjBjcmVhdGl2ZSUyMGFydCUyMHBvdHRlcnklMjBwYWludGluZyUyMGNyYWZ0c3xlbnwwfDF8fHwxNzU5NjE2ODE5fDA&ixlib=rb-4.1.0&q=85
```
**Attribution:** Taya Kucherova on Unsplash
**Description:** Person holding a clay pot - perfect for the hero section showing creative pottery work

**Alternative Options:**
- Option 2: `https://images.unsplash.com/photo-1729189566223-601d6957ef07` (Person at pottery table)
- Option 3: `https://images.unsplash.com/photo-1622691078858-58f9eb8825e0` (Person with wooden stick/tool)

### 2. Creative Workspace
**Asset Name:** `CreativeWorkspace`
**Recommended Image URL:**
```
https://images.unsplash.com/photo-1650065962232-e4b7f95ebf1f?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTAwNDR8MHwxfHNlYXJjaHw0fHxhcnQlMjBjcmFmdHMlMjBwb3R0ZXJ5JTIwY3JlYXRpdmUlMjB3b3Jrc3BhY2UlMjBzdXBwbGllc3xlbnwwfDB8fHwxNzU5NjE2ODE5fDA&ixlib=rb-4.1.0&q=85
```
**Attribution:** Chris Linnett on Unsplash
**Description:** Group of clay pots on table - great for showing variety of creative work

**Alternative Options:**
- Option 2: `https://images.unsplash.com/photo-1520408222757-6f9f95d87d5d` (White clay vases)
- Option 3: `https://images.unsplash.com/photo-1668276453336-108fca9cf2f3` (Shelf with vases and lamp)

### 3. Group Learning
**Asset Name:** `GroupLearning`
**Recommended Image URL:**
```
https://images.unsplash.com/photo-1621846323386-a60faf26f962?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTAwNDR8MHwxfHNlYXJjaHwyfHxwZW9wbGUlMjBwb3R0ZXJ5JTIwY2xhc3MlMjBsZWFybmluZyUyMHdvcmtzaG9wJTIwaGFuZHN8ZW58MHwwfHx8MTc1OTYxNjgxOXww&ixlib=rb-4.1.0&q=85
```
**Attribution:** Quino Al on Unsplash
**Description:** Person making clay pot - shows hands-on learning experience

**Alternative Options:**
- Option 2: `https://images.unsplash.com/photo-1719852255246-898f965e04e4` (Person making vase)
- Option 3: `https://images.unsplash.com/photo-1548151900-2ffe559eba9e` (Person forming artwork)

## 🎨 Color Assets

### Landing Gradient Colors
I've created two color assets for the gradient background:

1. **LandingGradientStart** - Purple/Lavender (#CC99CC)
   - Light mode: RGB(204, 153, 204)
   - Dark mode: RGB(153, 102, 153)

2. **LandingGradientEnd** - Pink/Rose (#E6B3CC)
   - Light mode: RGB(230, 179, 204)
   - Dark mode: RGB(179, 128, 153)

## 📱 How to Use in SwiftUI

### Using Images
```swift
// In your SwiftUI view
Image("HeroIllustration")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(height: 400)
```

### Using Gradient Colors
```swift
LinearGradient(
    colors: [
        Color("LandingGradientStart"),
        Color("LandingGradientEnd")
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

## 🔄 For Figma/Claude Workflow

### Step 1: Download Images
Download the images from the URLs above and save them as:
- `hero@2x.png` (or @1x, @3x for different scales)
- `workspace@2x.png`
- `group@2x.png`

Place them in the respective `.imageset` folders.

### Step 2: Import to Figma
1. Create a new Figma file for your landing page design
2. Import the downloaded images
3. Use the color values above for gradients and backgrounds
4. Design your landing page layout

### Step 3: Export from Figma
Once you have your design ready in Figma:
1. Export the design as PNG or use Figma's developer handoff
2. Feed the Figma file to Claude for SwiftUI code generation
3. Claude will generate the SwiftUI code using these asset names

## 🎯 Recommended Landing Page Layout

```swift
struct LandingPageView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("LandingGradientStart"),
                    Color("LandingGradientEnd")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
                
                // Progress bar
                ProgressView(value: 1.0)
                    .tint(.white)
                    .padding(.horizontal)
                
                Spacer()
                
                // Hero illustration
                Image("HeroIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 350)
                    .padding()
                
                // Speech bubbles overlay
                HStack {
                    Text("Let's create!")
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Text("Let's go!")
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 40)
                .offset(y: -50)
                
                Spacer()
                
                // Content card
                VStack(spacing: 20) {
                    Text("Start Creating Now 🚀")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Discover Vancouver's most creative hobby classes today! 🎨")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Log In") {}
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        
                        Button("Sign Up") {}
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    Button("Continue as Guest") {}
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.black, lineWidth: 2)
                        )
                        .cornerRadius(20)
                }
                .padding(30)
                .background(.white)
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }
        }
    }
}
```

## 📝 Next Steps

1. **Download the images** from the URLs provided above
2. **Place them** in the corresponding `.imageset` folders
3. **Open Xcode** and verify the assets appear in the asset catalog
4. **Use in Figma** to create your design mockup
5. **Feed to Claude** with the design for SwiftUI code generation

## 🎨 Design Tips

- Use the purple-to-pink gradient for a modern, welcoming feel
- Keep the hero image prominent (350-400pt height)
- Use speech bubbles to add personality
- Make buttons large and easy to tap (minimum 44pt height)
- Add subtle shadows for depth
- Consider adding decorative elements (stars, sparkles) as SF Symbols
