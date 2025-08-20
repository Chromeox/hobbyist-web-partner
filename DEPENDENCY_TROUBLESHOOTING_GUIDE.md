# Dependency Troubleshooting Guide

## HobbyistSwiftUI Dependency Management & Issue Resolution

This comprehensive guide provides solutions for common dependency-related issues encountered during development and deployment of HobbyistSwiftUI.

## Overview of Dependencies

### Primary Dependencies
- **Supabase Swift**: v2.5.1 (Database and authentication)
- **Stripe iOS**: v23.27.4 (Payment processing)

### Development Tools
- **SwiftLint**: v0.59.1 (Code quality enforcement)
- **SwiftFormat**: v0.57.2 (Code formatting)

## Common Issues & Solutions

### 1. Package Resolution Timeouts

#### Symptoms
```
error: terminated(128): git clone --bare --quiet ... 
Timeout waiting for network
```

#### Root Cause
Network timeouts during package resolution, often caused by:
- Slow internet connection
- Version range conflicts
- Large repository downloads

#### Solution
```swift
// Use exact version constraints in Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", exact: "2.5.1"),
    .package(url: "https://github.com/stripe/stripe-ios", exact: "23.27.4")
]
```

#### Prevention Commands
```bash
# Clear package cache
rm -rf ~/.swiftpm/repositories
rm -rf .build

# Resolve with timeout extension
swift package resolve --timeout 300

# Alternative: Download dependencies manually
git clone https://github.com/supabase/supabase-swift.git
git clone https://github.com/stripe/stripe-ios.git
```

### 2. Import Resolution Errors

#### Symptoms
```
error: cannot find 'X' in scope
Bundle executable not found
```

#### Root Cause
Missing import statements or incorrect target dependencies

#### Solution
```swift
// Ensure proper imports in affected files
import Foundation
import Combine
import UIKit           // Required for UIApplication references
import Supabase        // Database operations
import StripeCore      // Payment processing
import StripePaymentSheet  // Payment UI components
```

#### Project Configuration Fix
```bash
# Verify Xcode project integration
open HobbyistSwiftUI.xcodeproj

# Check Build Phases > Link Binary With Libraries
# Ensure all package products are properly linked:
# - Supabase
# - StripePaymentSheet
# - StripeApplePay
```

### 3. Xcode Project Integration Issues

#### Symptoms
```
Module 'X' not found
Package product 'Y' is not available
```

#### Root Cause
Mismatched package references in Xcode project file

#### Solution Steps
1. **Remove existing package references**:
   - Open Xcode > Project Navigator
   - Select project root > Package Dependencies
   - Remove all existing packages

2. **Re-add packages with correct URLs**:
   ```
   Supabase: https://github.com/supabase/supabase-swift
   Stripe: https://github.com/stripe/stripe-ios
   ```

3. **Verify product dependencies**:
   - Target > Build Phases > Link Binary With Libraries
   - Add required package products

#### Automation Script
```bash
#!/bin/bash
# reset_package_dependencies.sh

echo "Resetting package dependencies..."

# Clean existing packages
rm -rf .build
rm -rf .swiftpm

# Reset package resolution
swift package reset
swift package resolve

echo "Package dependencies reset complete"
```

### 4. Version Conflicts

#### Symptoms
```
error: package dependency is ambiguous
Multiple versions of package 'X' found
```

#### Root Cause
Conflicting version requirements between dependencies

#### Resolution Strategy
```swift
// Package.swift - Use exact versions to prevent conflicts
let package = Package(
    name: "HobbyistSwiftUI",
    platforms: [.iOS(.v16)],
    dependencies: [
        // Exact versions prevent resolution conflicts
        .package(url: "https://github.com/supabase/supabase-swift", exact: "2.5.1"),
        .package(url: "https://github.com/stripe/stripe-ios", exact: "23.27.4")
    ],
    targets: [
        .target(
            name: "HobbyistSwiftUI",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
                .product(name: "StripeApplePay", package: "stripe-ios")
            ]
        )
    ]
)
```

### 5. Build Phase Configuration

#### Symptoms
```
Linker command failed with exit code 1
Framework not found
```

#### Root Cause
Incorrect build phase configuration or missing frameworks

#### Solution Checklist
```bash
# Verify build settings
1. Build Phases > Compile Sources
   - All .swift files included
   - No duplicate entries

2. Build Phases > Link Binary With Libraries
   - Package products properly linked
   - No missing frameworks

3. Build Settings > Search Paths
   - Framework Search Paths configured
   - Library Search Paths set correctly
```

### 6. Environment Configuration Issues

#### Symptoms
```
Configuration key not found
Environment variable missing
```

#### Root Cause
Inconsistent environment setup across development stages

#### Solution Implementation
```swift
// Configuration.swift - Robust environment handling
public struct Configuration {
    public static func validateConfiguration() throws {
        guard !currentEnvironment.supabaseURL.isEmpty else {
            throw ConfigurationError.missingSupabaseURL
        }
        
        guard !currentEnvironment.supabaseKey.isEmpty else {
            throw ConfigurationError.missingSupabaseKey
        }
    }
    
    public static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return ProcessInfo.processInfo.environment["APP_ENV"] == "staging" ? .staging : .production
        #endif
    }
}

public enum Environment {
    case development, staging, production
    
    public var supabaseURL: String {
        switch self {
        case .development:
            return ProcessInfo.processInfo.environment["SUPABASE_DEV_URL"] ?? "dev-default-url"
        case .staging:
            return ProcessInfo.processInfo.environment["SUPABASE_STAGING_URL"] ?? "staging-default-url"
        case .production:
            return ProcessInfo.processInfo.environment["SUPABASE_PROD_URL"] ?? "prod-default-url"
        }
    }
}
```

### 7. SwiftLint Integration Problems

#### Symptoms
```
Command failed: swiftlint
Configuration file not found
```

#### Root Cause
Missing or incorrect SwiftLint configuration

#### Solution
```yaml
# .swiftlint.yml configuration
disabled_rules:
  - line_length
  - file_length
  
opt_in_rules:
  - empty_count
  - force_unwrapping
  
included:
  - Sources
  - ComponentLibrary
  - Services
  
excluded:
  - .build
  - DerivedData
  - Pods

line_length:
  warning: 120
  error: 150

file_length:
  warning: 400
  error: 1000
```

## Advanced Troubleshooting

### Dependency Validation Script

```bash
#!/bin/bash
# validate_dependencies.sh

echo "🔍 HobbyistSwiftUI Dependency Validation"
echo "========================================"

# 1. Check Swift Package Manager
echo "1. Checking Swift Package Manager..."
if swift package --version > /dev/null 2>&1; then
    echo "✅ Swift Package Manager available"
else
    echo "❌ Swift Package Manager not found"
    exit 1
fi

# 2. Validate package resolution
echo "2. Validating package resolution..."
if swift package resolve > /dev/null 2>&1; then
    echo "✅ Package resolution successful"
else
    echo "❌ Package resolution failed"
    echo "Try: rm -rf .build && swift package resolve"
fi

# 3. Check import statements
echo "3. Validating import statements..."
grep -r "import Supabase" . --include="*.swift" > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Supabase imports found"
else
    echo "⚠️  No Supabase imports detected"
fi

grep -r "import Stripe" . --include="*.swift" > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Stripe imports found"
else
    echo "⚠️  No Stripe imports detected"
fi

# 4. Validate Xcode project integration
echo "4. Checking Xcode project configuration..."
if [ -f "HobbyistSwiftUI.xcodeproj/project.pbxproj" ]; then
    if grep -q "XCRemoteSwiftPackageReference" HobbyistSwiftUI.xcodeproj/project.pbxproj; then
        echo "✅ Package references found in Xcode project"
    else
        echo "❌ No package references in Xcode project"
    fi
else
    echo "❌ Xcode project file not found"
fi

# 5. Environment configuration
echo "5. Validating environment configuration..."
if [ -f "Configuration.swift" ]; then
    echo "✅ Configuration.swift found"
else
    echo "❌ Configuration.swift missing"
fi

# 6. Code quality tools
echo "6. Checking code quality tools..."
if command -v swiftlint > /dev/null 2>&1; then
    echo "✅ SwiftLint installed ($(swiftlint version))"
else
    echo "⚠️  SwiftLint not installed"
fi

if command -v swiftformat > /dev/null 2>&1; then
    echo "✅ SwiftFormat installed ($(swiftformat --version))"
else
    echo "⚠️  SwiftFormat not installed"
fi

echo "========================================"
echo "✅ Dependency validation complete"
```

### Emergency Recovery Procedures

#### Complete Dependency Reset
```bash
#!/bin/bash
# emergency_reset.sh

echo "🚨 Emergency Dependency Reset"

# 1. Backup current state
cp Package.swift Package.swift.backup
cp HobbyistSwiftUI.xcodeproj/project.pbxproj project.pbxproj.backup

# 2. Clean all dependency artifacts
rm -rf .build
rm -rf .swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*HobbyistSwiftUI*

# 3. Reset package state
swift package reset
swift package clean

# 4. Fresh package resolution
swift package resolve

# 5. Rebuild Xcode project integration
open HobbyistSwiftUI.xcodeproj
echo "Manually re-add package dependencies in Xcode"
```

## Prevention Best Practices

### 1. Dependency Pinning Strategy
- Always use exact version constraints for critical dependencies
- Regular dependency audits (monthly)
- Document version compatibility matrix

### 2. Environment Isolation
- Separate development, staging, and production configurations
- Use environment variables for sensitive data
- Validate configuration on app startup

### 3. Build Pipeline Integration
```yaml
# .github/workflows/dependency-check.yml
name: Dependency Validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Dependencies
        run: ./validate_dependencies.sh
      - name: Check for Vulnerabilities
        run: swift package audit
```

### 4. Regular Maintenance Schedule
- **Weekly**: SwiftLint validation
- **Monthly**: Dependency updates review
- **Quarterly**: Major version compatibility assessment

## Contact & Support

For dependency-related issues not covered in this guide:

1. **Check project logs**: `swift package show-dependencies`
2. **Validate configuration**: Run `./validate_dependencies.sh`
3. **Emergency reset**: Use `./emergency_reset.sh` as last resort

---

**Last Updated**: August 15, 2025  
**Guide Version**: 3.3  
**Dependency Status**: ✅ All dependencies validated and working