O # Update Info.plist for Facebook

## After Getting Your Facebook Credentials

Once you have your Facebook App ID and Client Token from developers.facebook.com, you need to update your Info.plist file.

## Add to Info.plist

Add these entries to your `HobbyApp/Info.plist` file:

### 1. Facebook Configuration (add after existing keys)
```xml
<!-- Facebook Configuration -->
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID_HERE</string>

<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN_HERE</string>

<key>FacebookDisplayName</key>
<string>HobbyApp</string>
```

### 2. Facebook URL Scheme (add to existing CFBundleURLTypes array)

Find the existing `<key>CFBundleURLTypes</key>` section and add this dict to the array:

```xml
<dict>
    <key>CFBundleURLName</key>
    <string>com.hobbyist.bookingapp.facebook</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>fbYOUR_FACEBOOK_APP_ID_HERE</string>
    </array>
</dict>
```

### 3. App Transport Security (add to NSAppTransportSecurity if it exists)

Find or add the NSAppTransportSecurity section and add Facebook domains:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Your existing domains... -->
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
        <key>akamaihd.net</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## Example with Real Credentials

If your Facebook App ID is `123456789012345`, then:

- FacebookAppID: `123456789012345`
- URL Scheme: `fb123456789012345`

## Next Steps

1. Get credentials from developers.facebook.com
2. Replace YOUR_FACEBOOK_APP_ID_HERE with your actual App ID
3. Replace YOUR_FACEBOOK_CLIENT_TOKEN_HERE with your actual Client Token
4. Build and test Facebook login

## Testing

After updating Info.plist:
1. Clean build folder (Cmd+Shift+K)
2. Build project
3. Test Facebook login button in simulator
4. Check console for any Facebook SDK initialization messages