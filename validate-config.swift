#!/usr/bin/env swift

import Foundation

/// Quick configuration validation script
/// Run with: swift validate-config.swift

print("🔍 HobbyApp Configuration Validator")
print("=====================================")

// Load the plist file
guard let path = Bundle.main.path(forResource: "Config-Dev", ofType: "plist") else {
    print("❌ Config-Dev.plist not found")
    print("   Expected location: HobbyApp/Config-Dev.plist")
    exit(1)
}

guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
    print("❌ Config-Dev.plist is not valid")
    exit(1)
}

print("✅ Config-Dev.plist found and readable")

// Required keys for basic functionality
let requiredKeys = [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY", 
    "STRIPE_PUBLISHABLE_KEY",
    "GOOGLE_CLIENT_ID",
    "ENVIRONMENT"
]

var validationErrors: [String] = []
var warnings: [String] = []

// Check required keys
for key in requiredKeys {
    guard let value = dict[key] as? String, !value.isEmpty else {
        validationErrors.append("Missing or empty required key: \(key)")
        continue
    }
    
    // Check for placeholder values
    if value.contains("YOUR_") || value.contains("placeholder") || value.contains("your-") {
        warnings.append("Key \(key) contains placeholder value: \(value)")
    } else {
        print("✅ \(key): ✓")
    }
}

// Validate Supabase URL format
if let supabaseURL = dict["SUPABASE_URL"] as? String {
    if !supabaseURL.hasPrefix("https://") {
        validationErrors.append("SUPABASE_URL must use HTTPS")
    }
    if !supabaseURL.contains("supabase.co") {
        warnings.append("SUPABASE_URL doesn't appear to be a Supabase URL")
    }
}

// Validate Stripe key format
if let stripeKey = dict["STRIPE_PUBLISHABLE_KEY"] as? String {
    if !stripeKey.hasPrefix("pk_") {
        validationErrors.append("STRIPE_PUBLISHABLE_KEY must start with 'pk_'")
    }
    if stripeKey.hasPrefix("pk_test_") {
        print("ℹ️  Using Stripe test key (development mode)")
    } else if stripeKey.hasPrefix("pk_live_") {
        warnings.append("Using Stripe live key in development config")
    }
}

// Check environment setting
if let environment = dict["ENVIRONMENT"] as? String {
    if environment != "development" {
        warnings.append("ENVIRONMENT is set to '\(environment)' but this is Config-Dev.plist")
    }
}

// Print results
print("\n📊 Validation Results")
print("=====================")

if validationErrors.isEmpty {
    print("✅ All required keys are present and valid")
} else {
    print("❌ Found \(validationErrors.count) validation error(s):")
    for error in validationErrors {
        print("   • \(error)")
    }
}

if !warnings.isEmpty {
    print("\n⚠️  Found \(warnings.count) warning(s):")
    for warning in warnings {
        print("   • \(warning)")
    }
}

// Feature flags summary
print("\n🚀 Feature Flags")
print("================")
let featureFlags = [
    "ENABLE_LOGGING",
    "ENABLE_DEBUG_MENU", 
    "MOCK_DATA_ENABLED",
    "CERTIFICATE_PINNING",
    "ENABLE_APPLE_PAY",
    "ENABLE_PUSH_NOTIFICATIONS"
]

for flag in featureFlags {
    if let enabled = dict[flag] as? Bool {
        let status = enabled ? "✅ ON" : "❌ OFF"
        print("   \(flag): \(status)")
    }
}

print("\n🔧 Configuration Summary")
print("========================")
print("Environment: \(dict["ENVIRONMENT"] as? String ?? "unknown")")
print("API Base URL: \(dict["API_BASE_URL"] as? String ?? "unknown")")
print("Bundle ID: \(dict["BUNDLE_ID"] as? String ?? "unknown")")

if validationErrors.isEmpty && warnings.count <= 3 {
    print("\n🎉 Configuration looks good for development!")
    print("   Ready to build and test the app.")
    exit(0)
} else {
    print("\n🔧 Configuration needs attention before building.")
    exit(validationErrors.isEmpty ? 0 : 1)
}