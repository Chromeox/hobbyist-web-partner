#!/bin/bash

# Swift Package Manager Dependency Update Script for HobbyistSwiftUI
# This script manages Swift Package dependencies for the iOS app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists swift; then
        print_error "Swift is not installed. Please install Xcode and command line tools."
        exit 1
    fi
    
    if ! command_exists xcodebuild; then
        print_error "xcodebuild is not found. Please install Xcode."
        exit 1
    fi
    
    print_success "All prerequisites are installed."
}

# Function to resolve dependencies
resolve_dependencies() {
    print_status "Resolving Swift Package dependencies..."
    
    cd "$(dirname "$0")"
    
    # Using swift package resolve
    if swift package resolve; then
        print_success "Dependencies resolved successfully."
    else
        print_error "Failed to resolve dependencies."
        exit 1
    fi
}

# Function to update dependencies
update_dependencies() {
    print_status "Updating Swift Package dependencies to latest compatible versions..."
    
    cd "$(dirname "$0")"
    
    # Update all dependencies
    if swift package update; then
        print_success "Dependencies updated successfully."
    else
        print_error "Failed to update dependencies."
        exit 1
    fi
}

# Function to update specific dependency
update_specific_dependency() {
    local package_name=$1
    print_status "Updating $package_name..."
    
    cd "$(dirname "$0")"
    
    if swift package update "$package_name"; then
        print_success "$package_name updated successfully."
    else
        print_error "Failed to update $package_name."
        exit 1
    fi
}

# Function to show current dependency versions
show_versions() {
    print_status "Current dependency versions:"
    
    cd "$(dirname "$0")"
    
    if [ -f "Package.resolved" ]; then
        echo ""
        echo "Supabase Swift:"
        grep -A 2 '"supabase-swift"' Package.resolved | grep '"version"' | awk -F'"' '{print "  Version: " $4}'
        
        echo "Stripe iOS:"
        grep -A 2 '"stripe-ios"' Package.resolved | grep '"version"' | awk -F'"' '{print "  Version: " $4}'
        
        echo "Kingfisher:"
        grep -A 2 '"Kingfisher"' Package.resolved | grep '"version"' | awk -F'"' '{print "  Version: " $4}'
        
        echo "SwiftLint:"
        grep -A 2 '"SwiftLint"' Package.resolved | grep '"version"' | awk -F'"' '{print "  Version: " $4}'
        echo ""
    else
        print_warning "Package.resolved not found. Run 'resolve' first."
    fi
}

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    
    cd "$(dirname "$0")"
    
    if swift package clean; then
        print_success "Build artifacts cleaned."
    else
        print_warning "Failed to clean build artifacts."
    fi
}

# Function to reset package cache
reset_cache() {
    print_status "Resetting Swift Package cache..."
    
    cd "$(dirname "$0")"
    
    if swift package reset; then
        print_success "Package cache reset."
    else
        print_warning "Failed to reset package cache."
    fi
}

# Function to integrate with Xcode project
xcode_integrate() {
    print_status "Integrating packages with Xcode project..."
    
    cd "$(dirname "$0")"
    
    # Generate Xcode project if needed
    if [ ! -d "HobbyistSwiftUI.xcodeproj" ]; then
        print_warning "Xcode project not found in current directory."
        print_status "Note: Open the existing .xcodeproj file and add packages through Xcode's File > Add Package Dependencies menu."
    else
        print_status "Opening Xcode project..."
        open HobbyistSwiftUI.xcodeproj
        print_success "Xcode project opened. Add packages through File > Add Package Dependencies if needed."
    fi
}

# Function to run SwiftLint
run_swiftlint() {
    print_status "Running SwiftLint..."
    
    cd "$(dirname "$0")"
    
    if swift package plugin --allow-writing-to-package-directory swiftlint; then
        print_success "SwiftLint analysis complete."
    else
        print_warning "SwiftLint encountered issues. Check the output above."
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "========================================="
    echo "   Swift Package Manager - Dependency Manager"
    echo "   HobbyistSwiftUI iOS App"
    echo "========================================="
    echo ""
    echo "1. Resolve dependencies"
    echo "2. Update all dependencies"
    echo "3. Update specific dependency"
    echo "4. Show current versions"
    echo "5. Clean build artifacts"
    echo "6. Reset package cache"
    echo "7. Integrate with Xcode"
    echo "8. Run SwiftLint"
    echo "9. Full update (resolve + update + versions)"
    echo "0. Exit"
    echo ""
}

# Main script execution
main() {
    check_prerequisites
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select an option: " choice
            
            case $choice in
                1)
                    resolve_dependencies
                    ;;
                2)
                    update_dependencies
                    ;;
                3)
                    echo "Available packages:"
                    echo "  - supabase-swift"
                    echo "  - stripe-ios"
                    echo "  - Kingfisher"
                    echo "  - SwiftLint"
                    read -p "Enter package name: " package
                    update_specific_dependency "$package"
                    ;;
                4)
                    show_versions
                    ;;
                5)
                    clean_build
                    ;;
                6)
                    reset_cache
                    ;;
                7)
                    xcode_integrate
                    ;;
                8)
                    run_swiftlint
                    ;;
                9)
                    resolve_dependencies
                    update_dependencies
                    show_versions
                    ;;
                0)
                    print_status "Exiting..."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Please try again."
                    ;;
            esac
        done
    else
        # Command line argument mode
        case $1 in
            resolve)
                resolve_dependencies
                ;;
            update)
                if [ -n "$2" ]; then
                    update_specific_dependency "$2"
                else
                    update_dependencies
                fi
                ;;
            versions)
                show_versions
                ;;
            clean)
                clean_build
                ;;
            reset)
                reset_cache
                ;;
            xcode)
                xcode_integrate
                ;;
            lint)
                run_swiftlint
                ;;
            full)
                resolve_dependencies
                update_dependencies
                show_versions
                ;;
            *)
                echo "Usage: $0 [resolve|update [package]|versions|clean|reset|xcode|lint|full]"
                echo ""
                echo "Commands:"
                echo "  resolve              - Resolve all dependencies"
                echo "  update [package]     - Update all or specific package"
                echo "  versions             - Show current dependency versions"
                echo "  clean                - Clean build artifacts"
                echo "  reset                - Reset package cache"
                echo "  xcode                - Integrate with Xcode project"
                echo "  lint                 - Run SwiftLint"
                echo "  full                 - Full update (resolve + update + versions)"
                echo ""
                echo "Run without arguments for interactive mode."
                exit 1
                ;;
        esac
    fi
}

# Run the main function
main "$@"