#!/bin/bash

# TestFlight Upload Status Monitoring Script
# Monitors App Store Connect processing status and sends notifications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUNDLE_ID="com.hobbyist.bookingapp"
LOGS_DIR="testflight-automation/logs"
MONITOR_LOG="$LOGS_DIR/upload-status-monitor-$(date +%Y%m%d-%H%M%S).log"
STATUS_FILE="$LOGS_DIR/current-build-status.json"

# Default values
TIMEOUT=1800  # 30 minutes
CHECK_INTERVAL=60  # 1 minute
BUILD_NUMBER=""
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}"
NOTIFICATION_CHANNEL="${SLACK_CHANNEL:-#ios-releases}"

# Create logs directory
mkdir -p "$LOGS_DIR"

# Logging functions
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MONITOR_LOG"
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

# Function to check build status using App Store Connect API
check_build_status() {
    local build_number="$1"
    local app_id="$2"
    
    # Use fastlane spaceship to check status
    local status_result=$(fastlane run spaceship_stats app_identifier:"$BUNDLE_ID" 2>/dev/null | grep -E "Processing|Valid|Invalid" | head -1 || echo "Unknown")
    
    # Alternative: Use direct API call if spaceship fails
    if [[ "$status_result" == "Unknown" ]]; then
        # Try to get status via App Store Connect API
        if command -v app-store-connect-cli &> /dev/null; then
            status_result=$(app-store-connect-cli builds list --app-id "$app_id" --build-number "$build_number" --format json | jq -r '.data[0].attributes.processingState' 2>/dev/null || echo "Unknown")
        fi
    fi
    
    echo "$status_result"
}

# Function to get build processing details
get_build_details() {
    local build_number="$1"
    
    # Get build details using fastlane
    local build_details=$(fastlane pilot builds app_identifier:"$BUNDLE_ID" build_number:"$build_number" 2>/dev/null || echo "{}")
    
    echo "$build_details"
}

# Function to send Slack notification
send_slack_notification() {
    local message="$1"
    local color="$2"
    local build_info="$3"
    
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        log_warning "Slack webhook URL not configured"
        return 0
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local payload=$(cat <<EOF
{
    "channel": "$NOTIFICATION_CHANNEL",
    "username": "TestFlight Monitor",
    "icon_emoji": ":airplane:",
    "attachments": [
        {
            "color": "$color",
            "title": "TestFlight Build Status Update",
            "text": "$message",
            "fields": [
                {
                    "title": "Bundle ID",
                    "value": "$BUNDLE_ID",
                    "short": true
                },
                {
                    "title": "Build Number",
                    "value": "$BUILD_NUMBER",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$timestamp",
                    "short": true
                },
                {
                    "title": "Monitor Log",
                    "value": "$MONITOR_LOG",
                    "short": true
                }
            ],
            "footer": "TestFlight Automation System",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
    
    curl -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$SLACK_WEBHOOK_URL" \
        --silent --output /dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "Slack notification sent"
    else
        log_error "Failed to send Slack notification"
    fi
}

# Function to send webhook notification
send_webhook_notification() {
    local event="$1"
    local status="$2"
    local details="$3"
    
    if [[ -z "$WEBHOOK_URL" ]]; then
        return 0
    fi
    
    local webhook_payload=$(cat <<EOF
{
    "event": "$event",
    "bundle_id": "$BUNDLE_ID",
    "build_number": "$BUILD_NUMBER",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "details": $details,
    "monitor_log": "$MONITOR_LOG"
}
EOF
)
    
    curl -X POST \
        -H "Content-Type: application/json" \
        -d "$webhook_payload" \
        "$WEBHOOK_URL" \
        --silent --output /dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "Webhook notification sent for event: $event"
    else
        log_error "Failed to send webhook notification for event: $event"
    fi
}

# Function to save status to file
save_status_to_file() {
    local status="$1"
    local timestamp="$2"
    local details="$3"
    
    local status_json=$(cat <<EOF
{
    "build_number": "$BUILD_NUMBER",
    "bundle_id": "$BUNDLE_ID",
    "status": "$status",
    "last_checked": "$timestamp",
    "monitor_start": "$MONITOR_START_TIME",
    "details": $details,
    "log_file": "$MONITOR_LOG"
}
EOF
)
    
    echo "$status_json" > "$STATUS_FILE"
}

# Function to get app ID from bundle identifier
get_app_id() {
    local bundle_id="$1"
    
    # Use fastlane to get app ID
    local app_id=$(fastlane run get_app_identifier app_identifier:"$bundle_id" 2>/dev/null | grep -o '"[^"]*"' | sed 's/"//g' | head -1)
    
    if [[ -z "$app_id" ]]; then
        log_warning "Could not determine App ID for bundle identifier: $bundle_id"
        echo ""
    else
        echo "$app_id"
    fi
}

# Main monitoring function
monitor_build_status() {
    local build_number="$1"
    local timeout="$2"
    local check_interval="$3"
    
    log_info "Starting monitoring for build $build_number (timeout: ${timeout}s, interval: ${check_interval}s)"
    
    local start_time=$(date +%s)
    local app_id=$(get_app_id "$BUNDLE_ID")
    local last_status=""
    local consecutive_errors=0
    local max_consecutive_errors=5
    
    while true; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        
        # Check timeout
        if [[ $elapsed_time -ge $timeout ]]; then
            log_error "Monitoring timeout reached after ${timeout} seconds"
            send_slack_notification "⏰ Build monitoring timed out after $((timeout / 60)) minutes" "warning" "{}"
            send_webhook_notification "monitoring_timeout" "timeout" "{}"
            return 1
        fi
        
        # Check build status
        local status=$(check_build_status "$build_number" "$app_id")
        local current_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local details="{}"
        
        # Reset error counter on successful check
        if [[ "$status" != "Error" ]]; then
            consecutive_errors=0
        fi
        
        case "$status" in
            *"PROCESSING"*|*"Processing"*|*"processing"*)
                if [[ "$last_status" != "PROCESSING" ]]; then
                    log_info "Build is processing... (${elapsed_time}s elapsed)"
                    send_slack_notification "🔄 Build $build_number is processing..." "good" "$details"
                    send_webhook_notification "build_processing" "processing" "$details"
                fi
                last_status="PROCESSING"
                ;;
                
            *"VALID"*|*"Valid"*|*"valid"*|*"READY"*|*"Ready"*|*"ready"*)
                log_success "Build processing completed successfully!"
                local build_details=$(get_build_details "$build_number")
                send_slack_notification "✅ Build $build_number processing completed! Ready for testing." "good" "$build_details"
                send_webhook_notification "build_ready" "ready" "$build_details"
                save_status_to_file "READY" "$current_timestamp" "$build_details"
                return 0
                ;;
                
            *"INVALID"*|*"Invalid"*|*"invalid"*|*"FAILED"*|*"Failed"*|*"failed"*)
                log_error "Build processing failed!"
                local build_details=$(get_build_details "$build_number")
                send_slack_notification "❌ Build $build_number processing failed! Check App Store Connect for details." "danger" "$build_details"
                send_webhook_notification "build_failed" "failed" "$build_details"
                save_status_to_file "FAILED" "$current_timestamp" "$build_details"
                return 1
                ;;
                
            *"Unknown"*|*"Error"*|"")
                consecutive_errors=$((consecutive_errors + 1))
                log_warning "Unable to determine build status (attempt $consecutive_errors/$max_consecutive_errors)"
                
                if [[ $consecutive_errors -ge $max_consecutive_errors ]]; then
                    log_error "Too many consecutive errors checking build status"
                    send_slack_notification "⚠️ Unable to check build status for build $build_number after $max_consecutive_errors attempts" "warning" "{}"
                    send_webhook_notification "monitoring_error" "error" "{}"
                    return 1
                fi
                ;;
                
            *)
                log_info "Build status: $status (${elapsed_time}s elapsed)"
                if [[ "$last_status" != "$status" ]]; then
                    send_slack_notification "📱 Build $build_number status: $status" "good" "$details"
                    send_webhook_notification "status_update" "$status" "$details"
                fi
                last_status="$status"
                ;;
        esac
        
        # Save current status
        save_status_to_file "$status" "$current_timestamp" "$details"
        
        # Wait before next check
        sleep "$check_interval"
    done
}

# Function to show script usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                    Show this help message"
    echo "  -b, --build-number NUMBER     Build number to monitor (required)"
    echo "  -t, --timeout SECONDS         Monitoring timeout in seconds (default: 1800)"
    echo "  -i, --interval SECONDS        Check interval in seconds (default: 60)"
    echo "  --bundle-id BUNDLE_ID         App bundle identifier (default: $BUNDLE_ID)"
    echo "  --slack-webhook URL           Slack webhook URL for notifications"
    echo "  --webhook-url URL             Generic webhook URL for notifications"
    echo "  --channel CHANNEL             Slack channel (default: $NOTIFICATION_CHANNEL)"
    echo "  --verbose                     Enable verbose logging"
    echo ""
    echo "Environment Variables:"
    echo "  SLACK_WEBHOOK_URL             Slack webhook URL"
    echo "  WEBHOOK_URL                   Generic webhook URL"
    echo "  SLACK_CHANNEL                 Slack channel for notifications"
    echo ""
    echo "Examples:"
    echo "  $0 --build-number 123"
    echo "  $0 -b 123 -t 3600 -i 30"
    echo "  $0 --build-number 123 --slack-webhook https://hooks.slack.com/..."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -i|--interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        --bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        --slack-webhook)
            SLACK_WEBHOOK_URL="$2"
            shift 2
            ;;
        --webhook-url)
            WEBHOOK_URL="$2"
            shift 2
            ;;
        --channel)
            NOTIFICATION_CHANNEL="$2"
            shift 2
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

# Validate required parameters
if [[ -z "$BUILD_NUMBER" ]]; then
    echo "Error: Build number is required"
    show_usage
    exit 1
fi

# Store monitor start time
MONITOR_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Start monitoring
log_info "Starting TestFlight upload status monitoring"
log_info "Build Number: $BUILD_NUMBER"
log_info "Bundle ID: $BUNDLE_ID"
log_info "Timeout: ${TIMEOUT}s"
log_info "Check Interval: ${CHECK_INTERVAL}s"
log_info "Log File: $MONITOR_LOG"

# Run the monitoring
monitor_build_status "$BUILD_NUMBER" "$TIMEOUT" "$CHECK_INTERVAL"
exit_code=$?

# Final status
if [[ $exit_code -eq 0 ]]; then
    log_success "Build monitoring completed successfully"
else
    log_error "Build monitoring failed or timed out"
fi

exit $exit_code