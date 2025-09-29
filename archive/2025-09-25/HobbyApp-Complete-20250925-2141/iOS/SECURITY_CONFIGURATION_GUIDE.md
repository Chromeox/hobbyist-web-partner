# 🔒 HobbyistSwiftUI Security Configuration Guide

## Production Deployment Security Checklist

This guide provides step-by-step instructions for securely configuring and deploying the HobbyistSwiftUI iOS application.

---

## 📋 Pre-Deployment Security Checklist

### 1. Certificate Pinning Setup

```bash
# Generate certificate pins for your domains
openssl s_client -connect your-domain.supabase.co:443 | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

Add the generated hash to `AppConfiguration.swift`:
```swift
certificatePins: [
    "YOUR_GENERATED_HASH_HERE",
    "BACKUP_HASH_FOR_ROTATION"
]
```

### 2. Supabase Configuration

#### Never commit these values:
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_KEY

#### Setup Instructions:

1. **Create Config-Prod.plist** (DO NOT commit to git):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://YOUR_PROJECT.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_ANON_KEY</string>
</dict>
</plist>
```

2. **Add to .gitignore**:
```
Config-*.plist
*.mobileprovision
*.p12
*.p8
```

### 3. Keychain Configuration

The app will automatically create secure keychain entries on first launch for:
- Authentication tokens
- API keys
- Session data
- Encryption keys

No manual configuration needed, but verify Keychain access in Xcode:
- Capabilities → Keychain Sharing → Enable

### 4. App Transport Security

In `Info.plist`, ensure:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>supabase.co</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.3</string>
        </dict>
    </dict>
</dict>
```

---

## 🚀 Environment Configuration

### Development
```swift
// Automatically configured when DEBUG flag is set
// Uses mock services when --use-mock-services argument is passed
```

### Staging (TestFlight)
```swift
// Automatically detected via Bundle.main.appStoreReceiptURL
// Uses staging configuration with relaxed security for testing
```

### Production
```swift
// All security features enabled:
// - Certificate pinning enforced
// - Jailbreak detection active
// - Anti-debugging enabled
// - Screen recording detection active
```

---

## 🔐 Security Features Configuration

### 1. Jailbreak Detection

**Enabled by default in production**. To customize response:

```swift
// In AppDelegate or SceneDelegate
if SecurityManager.shared.isJailbroken {
    // Option 1: Show warning but allow usage
    showSecurityWarning()
    
    // Option 2: Restrict features
    disableSensitiveFeatures()
    
    // Option 3: Block app usage (recommended for financial apps)
    showSecurityBlockScreen()
    exit(0)
}
```

### 2. Anti-Debugging Protection

**Automatically enabled in production builds**. No configuration needed.

To test in development:
```swift
#if DEBUG
SecurityManager.shared.enableAntiDebugging() // Will terminate if debugger attached
#endif
```

### 3. Screen Recording Protection

Configure sensitive views:
```swift
class SensitiveViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide content when recording
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenRecording),
            name: Notification.Name("ScreenRecordingDetected"),
            object: nil
        )
    }
    
    @objc func handleScreenRecording() {
        // Hide sensitive content
        sensitiveDataView.isHidden = SecurityManager.shared.isScreenBeingRecorded
    }
}
```

### 4. Biometric Authentication

Enable for sensitive operations:
```swift
// For payments
SecurityManager.shared.authenticateWithBiometrics(
    reason: "Authenticate to complete payment"
) { success, error in
    if success {
        processPayment()
    }
}

// For viewing sensitive data
SecurityManager.shared.authenticateWithBiometrics(
    reason: "Authenticate to view booking details"
) { success, error in
    if success {
        showBookingDetails()
    }
}
```

---

## 📊 Security Monitoring

### Enable Security Logging

```swift
// In AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Perform security check
    let securityResult = SecurityManager.shared.performSecurityCheck()
    
    // Log security events
    if !securityResult.isSecure {
        for issue in securityResult.issues {
            // Log to analytics
            AnalyticsService.shared.trackEvent(
                "security_issue_detected",
                parameters: [
                    "issue": issue.message,
                    "severity": "\(issue.severity)",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )
            
            // Log to crash reporting
            CrashReportingService.shared.log(
                "Security Issue: \(issue.message) - Severity: \(issue.severity)"
            )
        }
    }
    
    return true
}
```

### Monitor API Requests

All API requests are automatically monitored for:
- Certificate validation failures
- Unusual request patterns
- Rate limit violations
- Authentication failures

---

## 🚨 Emergency Response

### If Security Breach Detected:

1. **Immediate Actions**:
```swift
// Force logout all users
AuthenticationService.shared.forceLogoutAllSessions()

// Clear all sensitive data
SecurityManager.shared.clearSensitiveData()

// Invalidate all tokens
KeychainService.shared.deleteAll()
```

2. **Remote Kill Switch** (implement in Supabase Edge Function):
```javascript
// Edge function to disable app
export async function disableApp(req: Request) {
    // Return specific error code that app recognizes
    return new Response(JSON.stringify({
        error: "APP_DISABLED",
        message: "Security update required"
    }), { status: 503 })
}
```

3. **App Response**:
```swift
// Handle kill switch
if response.error == "APP_DISABLED" {
    showUpdateRequiredScreen()
    disableAllFeatures()
}
```

---

## 🔄 Certificate Rotation

When rotating certificates:

1. **Add new certificate pin** before old one expires:
```swift
CertificatePinningService.shared.addCertificatePin("NEW_PIN_HASH")
```

2. **Deploy app update** with both pins

3. **After all users updated**, remove old pin:
```swift
CertificatePinningService.shared.removeCertificatePin("OLD_PIN_HASH")
```

---

## 📱 App Store Submission

### Required for App Store:

1. **Privacy Policy URL** - Must cover:
   - Data collection practices
   - Data sharing policies
   - User rights (GDPR/CCPA)
   - Contact information

2. **Export Compliance** (in Info.plist):
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<true/>
<key>ITSEncryptionExportComplianceCode</key>
<string>YOUR_COMPLIANCE_CODE</string>
```

3. **App Privacy Details** - Declare in App Store Connect:
   - User data collected
   - Device identifiers used
   - Analytics data collected
   - Crash data collected

---

## 🧪 Security Testing

### Before Each Release:

1. **Run Security Audit**:
```bash
# Use a security scanning tool
swiftlint analyze --compiler-log-path build.log

# Check for hardcoded secrets
grep -r "api_key\|secret\|password" --include="*.swift" .
```

2. **Test Security Features**:
- [ ] Jailbreak detection works
- [ ] Certificate pinning blocks invalid certificates
- [ ] Biometric authentication functions
- [ ] Screen recording detection works
- [ ] Keychain storage is encrypted
- [ ] No sensitive data in logs

3. **Penetration Testing** (recommended):
- Use tools like OWASP ZAP
- Test with jailbroken device
- Attempt MITM attacks
- Try to extract Keychain data

---

## 📞 Security Contacts

**Report Security Issues**:
- Email: security@yourcompany.com
- Bug Bounty: https://yourcompany.com/security

**Emergency Response Team**:
- Primary: [Contact Name]
- Secondary: [Contact Name]
- Escalation: [Contact Name]

---

## 🔄 Regular Security Tasks

### Weekly:
- Review security logs
- Check for unusual API patterns
- Monitor crash reports for security issues

### Monthly:
- Update dependencies
- Review security advisories
- Test emergency response procedures

### Quarterly:
- Full security audit
- Certificate rotation planning
- Penetration testing

---

## 📚 Additional Resources

- [Apple Security Best Practices](https://developer.apple.com/documentation/security)
- [OWASP Mobile Security Guide](https://owasp.org/www-project-mobile-security-guide/)
- [Supabase Security](https://supabase.com/docs/guides/platform/security)
- [iOS Security White Paper](https://www.apple.com/business/docs/iOS_Security_Guide.pdf)

---

⚠️ **Remember**: Security is an ongoing process, not a one-time setup. Regularly review and update security measures as new threats emerge.