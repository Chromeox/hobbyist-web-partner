#!/bin/bash

echo "==================================================="
echo "📱 HobbyistSwiftUI App Integrity Check"
echo "==================================================="
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "---------------------------------------------------"
    echo "🔍 $1"
    echo "---------------------------------------------------"
}

# iOS App Checks
print_section "iOS App Structure Analysis"

echo "✅ Checking for duplicate views in ContentView.swift..."
if grep -q "struct HomeView\|struct ClassesView\|struct BookingsView\|struct ProfileView" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/ContentView.swift; then
    echo "⚠️  WARNING: Found duplicate view definitions in ContentView.swift"
    echo "   These views are already defined in separate files"
fi

echo ""
echo "✅ Checking for missing view connections..."
missing_views=()

# Check if views are properly referenced
for view in "HomeView" "DiscoverView" "BookingsView" "ProfileView" "SearchView" "SettingsView"; do
    if ! grep -r "$view()" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/ --include="*.swift" | grep -v "struct $view" > /dev/null; then
        missing_views+=("$view")
    fi
done

if [ ${#missing_views[@]} -gt 0 ]; then
    echo "⚠️  WARNING: The following views may not be properly connected:"
    for view in "${missing_views[@]}"; do
        echo "   - $view"
    done
else
    echo "✅ All views appear to be connected"
fi

print_section "UI/Styling Issues"

echo "✅ Checking for missing accent colors..."
if ! grep -r "accentColor\|tintColor" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Views/ --include="*.swift" > /dev/null; then
    echo "⚠️  WARNING: No accent color configuration found in views"
fi

echo ""
echo "✅ Checking for inconsistent navigation patterns..."
nav_styles=$(grep -r "NavigationView\|NavigationStack" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Views/ --include="*.swift" | wc -l)
echo "   Found $nav_styles navigation container usages"

print_section "Database Configuration"

echo "✅ Checking Supabase initialization..."
if grep -q "SupabaseManager.shared.initialize" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/HobbyistSwiftUIApp.swift; then
    echo "✅ Supabase initialization found in app startup"
else
    echo "⚠️  WARNING: Supabase may not be initialized at app startup"
fi

echo ""
echo "✅ Checking for configuration files..."
config_files=()
for file in "Config-Dev.plist" "Config-Staging.plist" "Config-Production.plist" ".env"; do
    if [ -f ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/$file ] || [ -f ~/HobbyistSwiftUI/$file ]; then
        config_files+=("$file")
    fi
done

if [ ${#config_files[@]} -eq 0 ]; then
    echo "⚠️  WARNING: No configuration files found"
    echo "   The app needs Config-Dev.plist or .env for Supabase credentials"
else
    echo "✅ Found configuration files: ${config_files[@]}"
fi

print_section "Service Container Integrity"

echo "✅ Checking ServiceContainer implementation..."
if grep -q "class ServiceContainer" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Services/ServiceContainer.swift; then
    echo "✅ ServiceContainer class exists"
    
    # Check for service registrations
    services=("authService" "dataService" "paymentService" "notificationService")
    for service in "${services[@]}"; do
        if grep -q "$service" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Services/ServiceContainer.swift; then
            echo "   ✅ $service registered"
        else
            echo "   ⚠️  $service not found in ServiceContainer"
        fi
    done
fi

print_section "Authentication Flow"

echo "✅ Checking AuthenticationManager..."
if grep -q "class AuthenticationManager" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Services/AuthenticationManager.swift; then
    echo "✅ AuthenticationManager exists"
    
    # Check for multiple auth services
    auth_count=$(find ~/HobbyistSwiftUI/iOS -name "*.swift" -exec grep -l "auth.*Service\|Auth.*Manager" {} \; | wc -l)
    if [ $auth_count -gt 2 ]; then
        echo "⚠️  WARNING: Found $auth_count auth-related files (should be consolidated)"
    fi
fi

print_section "Web Portal Structure Analysis"

echo "✅ Checking web portal pages..."
web_pages=("dashboard" "onboarding" "auth")
for page in "${web_pages[@]}"; do
    if [ -d ~/HobbyistSwiftUI/web-partner/app/$page ]; then
        echo "   ✅ /$page page exists"
    else
        echo "   ⚠️  /$page page missing"
    fi
done

echo ""
echo "✅ Checking Supabase configuration in web portal..."
if [ -f ~/HobbyistSwiftUI/web-partner/.env.local ]; then
    echo "✅ .env.local exists"
    if grep -q "NEXT_PUBLIC_SUPABASE_URL" ~/HobbyistSwiftUI/web-partner/.env.local; then
        echo "   ✅ Supabase URL configured"
    else
        echo "   ⚠️  Supabase URL not configured"
    fi
else
    echo "⚠️  WARNING: .env.local not found - database connection not configured"
fi

print_section "Component Connection Issues"

echo "✅ Checking for unconnected view models..."
viewmodels=$(find ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/ViewModels -name "*.swift" -exec basename {} .swift \;)
for vm in $viewmodels; do
    if ! grep -r "@StateObject.*$vm\|@ObservedObject.*$vm\|@EnvironmentObject.*$vm" ~/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Views/ --include="*.swift" > /dev/null; then
        echo "   ⚠️  $vm may not be connected to any view"
    fi
done

print_section "Summary"

echo ""
echo "🎯 Key Issues Found:"
echo ""

# iOS Issues
echo "iOS App:"
echo "  1. ContentView has duplicate view definitions (should use MainTabView views)"
echo "  2. Missing database configuration files (Config-Dev.plist or .env)"
echo "  3. Supabase initialization not found in app startup"
echo "  4. Some view models may not be connected to views"
echo ""

echo "Web Portal:"
echo "  1. Missing .env.local for database configuration"
echo "  2. Need to verify all page routes are connected"
echo ""

echo "==================================================="
echo "📋 Recommended Actions:"
echo "==================================================="
echo ""
echo "1. Remove duplicate view definitions from ContentView.swift"
echo "2. Create Config-Dev.plist with Supabase credentials:"
echo "   - supabaseURL: https://mcjqvdzdhtcvbrejvrtp.supabase.co"
echo "   - supabaseAnonKey: [your anon key]"
echo ""
echo "3. Initialize Supabase in HobbyistSwiftUIApp.swift:"
echo "   - Add SupabaseManager.shared.initialize() in init()"
echo ""
echo "4. Create web-partner/.env.local with:"
echo "   NEXT_PUBLIC_SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co"
echo "   NEXT_PUBLIC_SUPABASE_ANON_KEY=[your anon key]"
echo ""
echo "5. Test all navigation flows in iOS Simulator"
echo "6. Verify web portal authentication flow"
echo ""
echo "==================================================="