#!/usr/bin/env swift

import Foundation

// Test to verify iOS Supabase configuration is properly set up
print("🔍 Testing iOS Supabase Configuration...")

// Test 1: Check if Config-Dev.plist exists
let bundle = Bundle.main
if let configPath = Bundle.main.path(forResource: "Config-Dev", ofType: "plist") {
    print("✅ Config-Dev.plist found at: \(configPath)")
    
    if let configDict = NSDictionary(contentsOfFile: configPath) as? [String: Any] {
        // Test 2: Check required keys
        let requiredKeys = ["SUPABASE_URL", "SUPABASE_ANON_KEY"]
        var allKeysPresent = true
        
        for key in requiredKeys {
            if let value = configDict[key] as? String, !value.isEmpty {
                if key == "SUPABASE_ANON_KEY" {
                    print("✅ \(key): ***\(value.suffix(10))")
                } else {
                    print("✅ \(key): \(value)")
                }
            } else {
                print("❌ Missing or empty: \(key)")
                allKeysPresent = false
            }
        }
        
        // Test 3: Validate values
        if let supabaseURL = configDict["SUPABASE_URL"] as? String {
            if supabaseURL.hasPrefix("https://") && supabaseURL.contains("supabase.co") {
                print("✅ Supabase URL format is valid")
            } else {
                print("❌ Invalid Supabase URL format")
                allKeysPresent = false
            }
        }
        
        if let supabaseKey = configDict["SUPABASE_ANON_KEY"] as? String {
            if supabaseKey.contains("YOUR_") || supabaseKey.contains("placeholder") {
                print("❌ Supabase key contains placeholder values")
                allKeysPresent = false
            } else if supabaseKey.count > 50 {
                print("✅ Supabase key format appears valid")
            } else {
                print("❌ Supabase key appears too short")
                allKeysPresent = false
            }
        }
        
        // Test 4: Summary
        print("\n📊 Configuration Test Results:")
        print("Config file exists: ✅")
        print("Required keys present: \(allKeysPresent ? "✅" : "❌")")
        print("Values valid: \(allKeysPresent ? "✅" : "❌")")
        
        if allKeysPresent {
            print("\n🎉 iOS Supabase configuration is properly set up!")
            print("The app should be able to connect to Supabase.")
        } else {
            print("\n❌ Configuration issues detected.")
            print("Please check your Config-Dev.plist file.")
        }
        
    } else {
        print("❌ Could not parse Config-Dev.plist")
    }
} else {
    print("❌ Config-Dev.plist not found")
    print("Please create it from Config-Dev.plist.template")
}

// Test 5: Check if template exists for reference
if Bundle.main.path(forResource: "Config-Dev.plist.template", ofType: nil) != nil {
    print("✅ Template file exists for reference")
} else {
    print("⚠️ Template file not found")
}