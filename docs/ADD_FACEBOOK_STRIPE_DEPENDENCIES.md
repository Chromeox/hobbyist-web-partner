	# Add Facebook & Stripe SDKs to Xcode Project

## Current Dependencies Status
✅ Supabase Swift SDK  
✅ Google Sign-In  
❌ Facebook SDK (needs to be added)  
❌ Stripe SDK (needs to be added)  

## Step 1: Add Facebook SDK via Swift Package Manager

1. **Open Xcode** → Open your HobbyApp.xcodeproj
2. **Go to File → Add Package Dependencies**
3. **Enter URL**: `https://github.com/facebook/facebook-ios-sdk`
4. **Dependency Rule**: Up to Next Major Version (18.0.0 or latest)
5. **Select Products to Add**:
   - ✅ `FacebookCore`
   - ✅ `FacebookLogin` 
   - ✅ `FacebookShare` (optional)
6. **Click Add Package**

## Step 2: Add Stripe SDK via Swift Package Manager

1. **In Xcode → File → Add Package Dependencies**
2. **Enter URL**: `https://github.com/stripe/stripe-ios`
3. **Dependency Rule**: Up to Next Major Version (23.0.0 or latest)
4. **Select Products to Add**:
   - ✅ `StripePaymentSheet`
   - ✅ `StripeApplePay`
   - ✅ `StripePayments`
5. **Click Add Package**

## Step 3: Update Info.plist for Facebook

Add these entries to your `HobbyApp/Info.plist`:

```xml
<!-- Facebook Configuration -->
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>

<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>

<key>FacebookDisplayName</key>
<string>HobbyApp</string>

<!-- Add to existing CFBundleURLTypes array -->
<dict>
    <key>CFBundleURLName</key>
    <string>com.hobbyist.bookingapp.facebook</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>fbYOUR_FACEBOOK_APP_ID</string>
    </array>
</dict>

<!-- Add to existing NSAppTransportSecurity domains -->
<key>facebook.com</key>
<dict>
    <key>NSIncludesSubdomains</key>
    <true/>
    <key>NSExceptionRequiresForwardSecrecy</key>
    <false/>
</dict>
<key>fbcdn.net</key>
<dict>
    <key>NSIncludesSubdomains</key>
    <true/>
    <key>NSExceptionRequiresForwardSecrecy</key>
    <false/>
</dict>
```

## Step 4: Update HobbyAppApp.swift

Add imports and initialization:

```swift
import SwiftUI
import FacebookCore
import Supabase

@main
struct HobbyAppApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    
    init() {
        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .onOpenURL(perform: { url in
                    // Handle Facebook URL callbacks
                    ApplicationDelegate.shared.application(
                        UIApplication.shared,
                        open: url,
                        sourceApplication: nil,
                        annotation: [UIApplication.OpenURLOptionsKey.annotation]
                    )
                })
        }
    }
}
```

## Step 5: Update LoginView.swift imports

```swift
import SwiftUI
import FacebookLogin
import StripePaymentSheet
import Supabase
```

## Step 6: Test Integration

After adding dependencies:

1. **Clean Build Folder** (Cmd + Shift + K)
2. **Build Project** (Cmd + B)
3. **Run on Simulator** to test Facebook login button
4. **Test Stripe** payment flow with test cards

## Step 7: Create Facebook App

1. Go to https://developers.facebook.com
2. Create new App → Consumer
3. Add Facebook Login product
4. Get App ID and Client Token
5. Add platform: iOS with bundle ID `com.hobbyist.bookingapp`

## Expected Package.resolved Updates

After adding dependencies, your Package.resolved should include:

```json
{
  "identity": "facebook-ios-sdk",
  "kind": "remoteSourceControl",
  "location": "https://github.com/facebook/facebook-ios-sdk",
  "state": {
    "version": "18.0.0"
  }
},
{
  "identity": "stripe-ios",
  "kind": "remoteSourceControl", 
  "location": "https://github.com/stripe/stripe-ios",
  "state": {
    "version": "23.0.0"
  }
}
```

## Troubleshooting

**Build Errors**: Clean build folder and restart Xcode
**Package Resolution**: Delete Package.resolved and re-resolve
**Facebook Login**: Check App ID matches Info.plist
**Stripe Payments**: Verify live key is correctly set in Configuration.swift

## Next Steps

1. Add dependencies via Xcode
2. Update Info.plist with Facebook config
3. Create Facebook App and get credentials
4. Test both Facebook login and Stripe payments
5. Deploy to TestFlight for alpha testing