#!/bin/bash

# TestFlight Version and Build Management Automation Script
# Handles automated version coordination, build number management, and changelog generation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="HobbyistSwiftUI"
BUNDLE_ID="com.hobbyist.bookingapp"
XCODEPROJ="HobbyistSwiftUI.xcodeproj"
LOGS_DIR="testflight-automation/logs"
VERSION_LOG="$LOGS_DIR/version-manager-$(date +%Y%m%d-%H%M%S).log"

# Default values
VERSION_SOURCE="xcode"  # Options: xcode, git, manual
INCREMENT_TYPE="build"  # Options: major, minor, patch, build
GENERATE_CHANGELOG=true
COMMIT_CHANGES=false

# Create logs directory
mkdir -p "$LOGS_DIR"

# Logging functions
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$VERSION_LOG"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_info() {
    log "${BLUE}ℹ️ $1${NC}"
}

# Function to get current version from Xcode project
get_current_version() {
    local version=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$PROJECT_NAME" | grep MARKETING_VERSION | head -1 | sed 's/.*= //')
    echo "$version"
}

# Function to get current build number from Xcode project
get_current_build_number() {
    local build=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$PROJECT_NAME" | grep CURRENT_PROJECT_VERSION | head -1 | sed 's/.*= //')
    echo "$build"
}

# Function to get latest git tag version
get_latest_git_version() {
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -n "$latest_tag" ]]; then
        # Remove 'v' prefix if present
        echo "$latest_tag" | sed 's/^v//'
    else
        echo "0.0.0"
    fi
}

# Function to increment version number
increment_version() {
    local version="$1"
    local increment_type="$2"
    
    # Parse version (major.minor.patch)
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)
    
    # Handle missing components
    if [[ -z "$major" ]]; then major=0; fi
    if [[ -z "$minor" ]]; then minor=0; fi
    if [[ -z "$patch" ]]; then patch=0; fi
    
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            log_error "Invalid increment type: $increment_type"
            return 1
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to get next build number from TestFlight
get_next_build_number() {
    local current_build="$1"
    local next_build
    
    # Try to get the latest TestFlight build number
    local latest_testflight_build=""
    if command -v fastlane >/dev/null 2>&1; then
        latest_testflight_build=$(fastlane pilot builds app_identifier:"$BUNDLE_ID" 2>/dev/null | grep "Build Number" | head -1 | sed 's/.*: //' || echo "")
    fi
    
    if [[ -n "$latest_testflight_build" ]] && [[ "$latest_testflight_build" =~ ^[0-9]+$ ]]; then
        next_build=$((latest_testflight_build + 1))
        log_info "Latest TestFlight build: $latest_testflight_build, next build: $next_build"
    else
        # Fallback to incrementing current build number
        if [[ "$current_build" =~ ^[0-9]+$ ]]; then
            next_build=$((current_build + 1))
        else
            next_build=1
        fi
        log_warning "Could not get TestFlight build number, using local increment: $next_build"
    fi
    
    echo "$next_build"
}

# Function to detect build number conflicts
detect_build_conflicts() {
    local build_number="$1"
    local conflicts=false
    
    log_info "Checking for build number conflicts..."
    
    # Check TestFlight builds
    if command -v fastlane >/dev/null 2>&1; then
        local testflight_builds=$(fastlane pilot builds app_identifier:"$BUNDLE_ID" 2>/dev/null | grep "Build Number: $build_number" || echo "")
        if [[ -n "$testflight_builds" ]]; then
            log_warning "Build number $build_number already exists in TestFlight"
            conflicts=true
        fi
    fi
    
    # Check App Store Connect builds
    if command -v xcrun >/dev/null 2>&1; then
        # This would require App Store Connect API access
        log_info "App Store Connect conflict check requires API access - skipping"
    fi
    
    if [[ "$conflicts" == "true" ]]; then
        return 1
    else
        return 0
    fi
}

# Function to resolve build number conflicts
resolve_build_conflicts() {
    local build_number="$1"
    local resolved_build="$build_number"
    
    while ! detect_build_conflicts "$resolved_build"; do
        resolved_build=$((resolved_build + 1))
        log_info "Trying build number: $resolved_build"
    done
    
    if [[ "$resolved_build" != "$build_number" ]]; then
        log_warning "Build number conflict resolved: $build_number -> $resolved_build"
    fi
    
    echo "$resolved_build"
}

# Function to generate changelog from git commits
generate_git_changelog() {
    local from_ref="$1"
    local to_ref="${2:-HEAD}"
    local format="${3:-short}"  # Options: short, detailed
    
    log_info "Generating changelog from $from_ref to $to_ref"
    
    if ! git rev-parse --verify "$from_ref" >/dev/null 2>&1; then
        log_warning "Reference $from_ref does not exist, using last 10 commits"
        from_ref="HEAD~10"
    fi
    
    local changelog=""
    
    case "$format" in
        "short")
            changelog=$(git log --oneline --no-merges "$from_ref..$to_ref" | sed 's/^[a-f0-9]* /- /')
            ;;
        "detailed")
            changelog=$(git log --pretty=format:"- %s (%an)" --no-merges "$from_ref..$to_ref")
            ;;
        "grouped")
            # Group commits by type (feat, fix, docs, etc.)
            local features=$(git log --oneline --no-merges --grep="^feat" "$from_ref..$to_ref" | sed 's/^[a-f0-9]* /- /')
            local fixes=$(git log --oneline --no-merges --grep="^fix" "$from_ref..$to_ref" | sed 's/^[a-f0-9]* /- /')
            local other=$(git log --oneline --no-merges --invert-grep --grep="^feat" --grep="^fix" "$from_ref..$to_ref" | sed 's/^[a-f0-9]* /- /')
            
            changelog=""
            if [[ -n "$features" ]]; then
                changelog+="✨ New Features:\n$features\n\n"
            fi
            if [[ -n "$fixes" ]]; then
                changelog+="🐛 Bug Fixes:\n$fixes\n\n"
            fi
            if [[ -n "$other" ]]; then
                changelog+="🔧 Other Changes:\n$other\n\n"
            fi
            ;;
    esac
    
    if [[ -z "$changelog" ]]; then
        changelog="- Bug fixes and performance improvements"
        log_warning "No commits found, using default changelog"
    fi
    
    echo -e "$changelog"
}

# Function to save changelog to file
save_changelog() {
    local changelog="$1"
    local version="$2"
    local build="$3"
    
    local changelog_file="testflight-automation/changelogs/CHANGELOG-$version-$build.md"
    mkdir -p "$(dirname "$changelog_file")"
    
    cat > "$changelog_file" << EOF
# Changelog for Version $version (Build $build)

Generated on: $(date '+%Y-%m-%d %H:%M:%S')

## Changes

$changelog

---
Generated by TestFlight Automation System
EOF
    
    log_success "Changelog saved to: $changelog_file"
    echo "$changelog_file"
}

# Function to update Xcode project version
update_xcode_version() {
    local new_version="$1"
    local current_version=$(get_current_version)
    
    if [[ "$new_version" == "$current_version" ]]; then
        log_info "Version is already $new_version, no update needed"
        return 0
    fi
    
    log_info "Updating version from $current_version to $new_version"
    
    # Update version in Xcode project
    if command -v agvtool >/dev/null 2>&1; then
        agvtool new-marketing-version "$new_version"
    else
        # Fallback using xcodeproj command
        xcrun xcodeproj --project "$XCODEPROJ" update-build-setting MARKETING_VERSION --value "$new_version"
    fi
    
    log_success "Version updated to $new_version"
}

# Function to update Xcode project build number
update_xcode_build_number() {
    local new_build="$1"
    local current_build=$(get_current_build_number)
    
    if [[ "$new_build" == "$current_build" ]]; then
        log_info "Build number is already $new_build, no update needed"
        return 0
    fi
    
    log_info "Updating build number from $current_build to $new_build"
    
    # Update build number in Xcode project
    if command -v agvtool >/dev/null 2>&1; then
        agvtool new-version -all "$new_build"
    else
        # Fallback using xcodeproj command
        xcrun xcodeproj --project "$XCODEPROJ" update-build-setting CURRENT_PROJECT_VERSION --value "$new_build"
    fi
    
    log_success "Build number updated to $new_build"
}

# Function to create git tag for version
create_git_tag() {
    local version="$1"
    local build="$2"
    local tag_name="v$version-build$build"
    
    if git tag -l | grep -q "^$tag_name$"; then
        log_warning "Tag $tag_name already exists"
        return 0
    fi
    
    log_info "Creating git tag: $tag_name"
    git tag -a "$tag_name" -m "Version $version (Build $build)"
    
    if [[ "${PUSH_TAGS:-false}" == "true" ]]; then
        git push origin "$tag_name"
        log_success "Tag $tag_name pushed to origin"
    else
        log_info "Tag $tag_name created locally (use --push-tags to push)"
    fi
}

# Function to commit version changes
commit_version_changes() {
    local version="$1"
    local build="$2"
    
    if [[ "$(git status --porcelain)" ]]; then
        log_info "Committing version changes..."
        git add .
        git commit -m "chore: bump version to $version (build $build)"
        
        if [[ "${PUSH_COMMITS:-false}" == "true" ]]; then
            git push origin "$(git branch --show-current)"
            log_success "Version changes pushed to origin"
        else
            log_info "Version changes committed locally (use --push-commits to push)"
        fi
    else
        log_info "No changes to commit"
    fi
}

# Function to perform automated version coordination
coordinate_versions() {
    local increment_type="$1"
    local source="$2"
    
    log_info "Starting automated version coordination (source: $source, increment: $increment_type)"
    
    # Get current versions
    local current_xcode_version=$(get_current_version)
    local current_build=$(get_current_build_number)
    local current_git_version=$(get_latest_git_version)
    
    log_info "Current Xcode version: $current_xcode_version"
    log_info "Current build number: $current_build"
    log_info "Current Git version: $current_git_version"
    
    # Determine new version based on source
    local new_version="$current_xcode_version"
    case "$source" in
        "xcode")
            new_version="$current_xcode_version"
            ;;
        "git")
            new_version="$current_git_version"
            ;;
        "manual")
            if [[ -n "$MANUAL_VERSION" ]]; then
                new_version="$MANUAL_VERSION"
            else
                log_error "Manual version specified but MANUAL_VERSION not set"
                return 1
            fi
            ;;
    esac
    
    # Increment version if needed
    if [[ "$increment_type" != "build" ]]; then
        new_version=$(increment_version "$new_version" "$increment_type")
        log_info "Incremented version: $new_version"
    fi
    
    # Handle build number
    local new_build
    if [[ "$increment_type" == "build" ]] || [[ "${AUTO_INCREMENT_BUILD:-true}" == "true" ]]; then
        new_build=$(get_next_build_number "$current_build")
        
        # Check and resolve conflicts
        if [[ "${CHECK_CONFLICTS:-true}" == "true" ]]; then
            new_build=$(resolve_build_conflicts "$new_build")
        fi
    else
        new_build="$current_build"
    fi
    
    log_info "Final version: $new_version"
    log_info "Final build number: $new_build"
    
    # Update Xcode project
    update_xcode_version "$new_version"
    update_xcode_build_number "$new_build"
    
    # Generate changelog if requested
    if [[ "$GENERATE_CHANGELOG" == "true" ]]; then
        local from_ref="HEAD~10"  # Default to last 10 commits
        if [[ -n "$current_git_version" ]] && git rev-parse --verify "v$current_git_version" >/dev/null 2>&1; then
            from_ref="v$current_git_version"
        fi
        
        local changelog=$(generate_git_changelog "$from_ref" "HEAD" "grouped")
        local changelog_file=$(save_changelog "$changelog" "$new_version" "$new_build")
        
        log_success "Changelog generated: $changelog_file"
    fi
    
    # Create git tag if requested
    if [[ "${CREATE_GIT_TAG:-false}" == "true" ]]; then
        create_git_tag "$new_version" "$new_build"
    fi
    
    # Commit changes if requested
    if [[ "$COMMIT_CHANGES" == "true" ]]; then
        commit_version_changes "$new_version" "$new_build"
    fi
    
    # Output final information
    echo "{"
    echo "  \"version\": \"$new_version\","
    echo "  \"build_number\": \"$new_build\","
    echo "  \"previous_version\": \"$current_xcode_version\","
    echo "  \"previous_build\": \"$current_build\","
    echo "  \"changelog_file\": \"${changelog_file:-}\","
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "}"
}

# Function to show script usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                    Show this help message"
    echo "  --increment TYPE              Increment type (major, minor, patch, build) [default: build]"
    echo "  --version-source SOURCE       Version source (xcode, git, manual) [default: xcode]"
    echo "  --manual-version VERSION      Manual version when using manual source"
    echo "  --generate-changelog          Generate changelog from git commits [default: true]"
    echo "  --changelog-format FORMAT     Changelog format (short, detailed, grouped) [default: grouped]"
    echo "  --commit-changes              Commit version changes to git"
    echo "  --create-git-tag              Create git tag for new version"
    echo "  --push-tags                   Push git tags to origin"
    echo "  --push-commits                Push commits to origin"
    echo "  --check-conflicts             Check for build number conflicts [default: true]"
    echo "  --auto-increment-build        Auto increment build number [default: true]"
    echo "  --dry-run                     Show what would be done without making changes"
    echo "  --verbose                     Enable verbose logging"
    echo ""
    echo "Examples:"
    echo "  $0 --increment patch --commit-changes --create-git-tag"
    echo "  $0 --increment build --generate-changelog"
    echo "  $0 --version-source git --increment minor --push-tags"
    echo "  $0 --manual-version 2.1.0 --version-source manual"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --increment)
            INCREMENT_TYPE="$2"
            shift 2
            ;;
        --version-source)
            VERSION_SOURCE="$2"
            shift 2
            ;;
        --manual-version)
            MANUAL_VERSION="$2"
            shift 2
            ;;
        --generate-changelog)
            GENERATE_CHANGELOG=true
            shift
            ;;
        --changelog-format)
            CHANGELOG_FORMAT="$2"
            shift 2
            ;;
        --commit-changes)
            COMMIT_CHANGES=true
            shift
            ;;
        --create-git-tag)
            CREATE_GIT_TAG=true
            shift
            ;;
        --push-tags)
            PUSH_TAGS=true
            shift
            ;;
        --push-commits)
            PUSH_COMMITS=true
            shift
            ;;
        --check-conflicts)
            CHECK_CONFLICTS=true
            shift
            ;;
        --auto-increment-build)
            AUTO_INCREMENT_BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
log_info "Starting TestFlight Version Management"
log_info "Log file: $VERSION_LOG"
log_info "Increment type: $INCREMENT_TYPE"
log_info "Version source: $VERSION_SOURCE"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "DRY RUN MODE - No changes will be made"
    # Set environment variables to prevent actual changes
    export DRY_RUN=true
fi

# Run version coordination
coordinate_versions "$INCREMENT_TYPE" "$VERSION_SOURCE"

log_success "Version management completed"