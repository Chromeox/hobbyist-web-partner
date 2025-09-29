#!/bin/bash

# Swift Package Dependency Update Pipeline
# Automated security validation and update system for HobbyistSwiftUI iOS app
# Version: 1.0.0
# Created: 2025-09-11

set -e

# Configuration
PROJECT_DIR="/Users/chromefang.exe/HobbyApp/iOS"
PACKAGE_FILE="$PROJECT_DIR/Package.swift"
RESOLVED_FILE="$PROJECT_DIR/Package.resolved"
BACKUP_DIR="$PROJECT_DIR/Backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$PROJECT_DIR/Logs/dependency_update_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Create necessary directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting Swift Package Dependency Update Pipeline"

# Step 1: Create backup
log "Creating backup of current configuration..."
cp "$PACKAGE_FILE" "$BACKUP_DIR/"
if [ -f "$RESOLVED_FILE" ]; then
    cp "$RESOLVED_FILE" "$BACKUP_DIR/"
fi
success "Backup created at: $BACKUP_DIR"

# Step 2: Check for available updates
log "Checking for available package updates..."

# Function to get latest version from GitHub API
get_latest_version() {
    local repo=$1
    local current_version=$2
    
    log "Checking $repo (current: $current_version)"
    
    # Get latest release from GitHub API
    local latest=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -n "$latest" ]; then
        echo "$latest"
    else
        warning "Could not fetch latest version for $repo"
        echo "$current_version"
    fi
}

# Get current versions from Package.swift
SUPABASE_CURRENT=$(grep -A 1 "supabase-swift" "$PACKAGE_FILE" | grep "exact:" | sed -E 's/.*"([^"]+)".*/\1/')
STRIPE_CURRENT=$(grep -A 1 "stripe-ios" "$PACKAGE_FILE" | grep "exact:" | sed -E 's/.*"([^"]+)".*/\1/')
KINGFISHER_CURRENT=$(grep -A 1 "Kingfisher" "$PACKAGE_FILE" | grep "exact:" | sed -E 's/.*"([^"]+)".*/\1/')

# Check for latest versions
SUPABASE_LATEST=$(get_latest_version "supabase/supabase-swift" "$SUPABASE_CURRENT")
STRIPE_LATEST=$(get_latest_version "stripe/stripe-ios" "$STRIPE_CURRENT")
KINGFISHER_LATEST=$(get_latest_version "onevcat/Kingfisher" "$KINGFISHER_CURRENT")

log "Version comparison:"
log "Supabase: $SUPABASE_CURRENT -> $SUPABASE_LATEST"
log "Stripe: $STRIPE_CURRENT -> $STRIPE_LATEST"
log "Kingfisher: $KINGFISHER_CURRENT -> $KINGFISHER_LATEST"

# Step 3: Security vulnerability check
log "Performing security vulnerability assessment..."

# Function to check for known vulnerabilities
check_security() {
    local package=$1
    local version=$2
    
    log "Security check: $package@$version"
    
    # This is a placeholder for more sophisticated security checking
    # In a production environment, you would integrate with:
    # - GitHub Security Advisories API
    # - Snyk API
    # - OWASP Dependency Check
    # - Custom vulnerability databases
    
    # For now, we'll do basic checks
    local advisory_check=$(curl -s "https://api.github.com/repos/$package/security-advisories" 2>/dev/null || echo "[]")
    
    if [ "$advisory_check" != "[]" ] && [ "$advisory_check" != "" ]; then
        warning "Security advisories found for $package - please review manually"
        return 1
    fi
    
    return 0
}

# Perform security checks
SECURITY_ISSUES=0

if ! check_security "supabase/supabase-swift" "$SUPABASE_LATEST"; then
    ((SECURITY_ISSUES++))
fi

if ! check_security "stripe/stripe-ios" "$STRIPE_LATEST"; then
    ((SECURITY_ISSUES++))
fi

if ! check_security "onevcat/Kingfisher" "$KINGFISHER_LATEST"; then
    ((SECURITY_ISSUES++))
fi

if [ $SECURITY_ISSUES -gt 0 ]; then
    warning "$SECURITY_ISSUES security issues detected. Manual review recommended."
fi

# Step 4: Update Package.swift if newer versions available
UPDATES_AVAILABLE=false

if [ "$SUPABASE_CURRENT" != "$SUPABASE_LATEST" ]; then
    log "Updating Supabase from $SUPABASE_CURRENT to $SUPABASE_LATEST"
    sed -i.bak "s/exact: \"$SUPABASE_CURRENT\"/exact: \"$SUPABASE_LATEST\"/g" "$PACKAGE_FILE"
    UPDATES_AVAILABLE=true
fi

if [ "$STRIPE_CURRENT" != "$STRIPE_LATEST" ]; then
    log "Updating Stripe from $STRIPE_CURRENT to $STRIPE_LATEST"
    sed -i.bak "s/exact: \"$STRIPE_CURRENT\"/exact: \"$STRIPE_LATEST\"/g" "$PACKAGE_FILE"
    UPDATES_AVAILABLE=true
fi

if [ "$KINGFISHER_CURRENT" != "$KINGFISHER_LATEST" ]; then
    log "Updating Kingfisher from $KINGFISHER_CURRENT to $KINGFISHER_LATEST"
    sed -i.bak "s/exact: \"$KINGFISHER_CURRENT\"/exact: \"$KINGFISHER_LATEST\"/g" "$PACKAGE_FILE"
    UPDATES_AVAILABLE=true
fi

# Step 5: Package resolution and validation
if [ "$UPDATES_AVAILABLE" = true ]; then
    log "Updates detected. Resolving packages..."
    
    cd "$PROJECT_DIR"
    
    # Remove resolved file to force fresh resolution
    if [ -f "$RESOLVED_FILE" ]; then
        rm "$RESOLVED_FILE"
    fi
    
    # Resolve packages
    log "Resolving Swift packages..."
    if swift package resolve --verbose; then
        success "Package resolution completed successfully"
    else
        error "Package resolution failed"
        log "Restoring backup..."
        cp "$BACKUP_DIR/Package.swift" "$PACKAGE_FILE"
        if [ -f "$BACKUP_DIR/Package.resolved" ]; then
            cp "$BACKUP_DIR/Package.resolved" "$RESOLVED_FILE"
        fi
        exit 1
    fi
    
    # Step 6: Build validation
    log "Performing build validation..."
    if xcodebuild -project HobbyistSwiftUI.xcodeproj -scheme HobbyistSwiftUI -destination 'platform=iOS Simulator,name=iPhone 15' build; then
        success "Build validation passed"
    else
        error "Build validation failed"
        log "Restoring backup..."
        cp "$BACKUP_DIR/Package.swift" "$PACKAGE_FILE"
        if [ -f "$BACKUP_DIR/Package.resolved" ]; then
            cp "$BACKUP_DIR/Package.resolved" "$RESOLVED_FILE"
        fi
        exit 1
    fi
    
    success "All dependency updates completed successfully!"
    
    # Generate update report
    cat > "$PROJECT_DIR/Logs/dependency_update_report_$(date +%Y%m%d_%H%M%S).md" << EOF
# Dependency Update Report
Generated: $(date)

## Updates Applied
- Supabase Swift SDK: $SUPABASE_CURRENT -> $SUPABASE_LATEST
- Stripe iOS SDK: $STRIPE_CURRENT -> $STRIPE_LATEST
- Kingfisher: $KINGFISHER_CURRENT -> $KINGFISHER_LATEST

## Security Assessment
- Security issues detected: $SECURITY_ISSUES
- Build validation: PASSED
- Package resolution: PASSED

## Backup Location
$BACKUP_DIR

## Next Steps
1. Run comprehensive test suite
2. Deploy to TestFlight for validation
3. Monitor for any runtime issues
EOF
    
else
    log "No updates available. All packages are current."
fi

log "Dependency update pipeline completed"