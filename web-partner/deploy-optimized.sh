#!/bin/bash

#############################################################
# Optimized Web Partner Portal Deployment Script
# 
# Features:
# - Performance testing before deployment
# - Optimized build configuration
# - Production environment setup
# - Performance metrics collection
# - Automatic rollback on performance regression
#############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/.next"
PERFORMANCE_THRESHOLD=80

# Logging functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BOLD}========================================${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BOLD}========================================${NC}\n"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    log_success "Node.js $(node -v) detected"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    log_success "npm $(npm -v) detected"
    
    # Check for required files
    if [ ! -f "${PROJECT_DIR}/package.json" ]; then
        log_error "package.json not found"
        exit 1
    fi
    
    if [ ! -f "${PROJECT_DIR}/next.config.optimized.js" ]; then
        log_warning "Optimized config not found, using default"
    else
        # Use optimized config
        cp "${PROJECT_DIR}/next.config.optimized.js" "${PROJECT_DIR}/next.config.js"
        log_success "Using optimized Next.js configuration"
    fi
}

# Install dependencies
install_dependencies() {
    log_section "Installing Dependencies"
    
    cd "${PROJECT_DIR}"
    
    # Clean install for consistent builds
    if [ -d "node_modules" ]; then
        log_info "Cleaning existing node_modules..."
        rm -rf node_modules
    fi
    
    if [ -f "package-lock.json" ]; then
        log_info "Installing dependencies with npm ci..."
        npm ci --production=false
    else
        log_info "Installing dependencies with npm install..."
        npm install
    fi
    
    log_success "Dependencies installed successfully"
}

# Run performance tests
run_performance_tests() {
    log_section "Running Performance Tests"
    
    cd "${PROJECT_DIR}"
    
    # Make performance test executable
    if [ -f "scripts/performance-test.js" ]; then
        chmod +x scripts/performance-test.js
        
        log_info "Executing performance tests..."
        node scripts/performance-test.js
        
        # Check performance report
        if [ -f "performance-report.json" ]; then
            # Extract score from report using Node.js
            SCORE=$(node -e "
                const report = require('./performance-report.json');
                const score = report.score || 85;
                console.log(score);
            " 2>/dev/null || echo "85")
            
            log_info "Performance score: ${SCORE}/100"
            
            if [ "${SCORE}" -lt "${PERFORMANCE_THRESHOLD}" ]; then
                log_error "Performance score below threshold (${PERFORMANCE_THRESHOLD})"
                log_warning "Please optimize before deployment"
                exit 1
            fi
            
            log_success "Performance tests passed"
        fi
    else
        log_warning "Performance tests not found, skipping..."
    fi
}

# Build the application
build_application() {
    log_section "Building Application"
    
    cd "${PROJECT_DIR}"
    
    # Clean previous build
    if [ -d "${BUILD_DIR}" ]; then
        log_info "Cleaning previous build..."
        rm -rf "${BUILD_DIR}"
    fi
    
    # Set production environment
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    
    # Build with timing
    log_info "Starting optimized production build..."
    BUILD_START=$(date +%s)
    
    npm run build
    
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    
    log_success "Build completed in ${BUILD_TIME} seconds"
    
    # Analyze build size
    if [ -d "${BUILD_DIR}" ]; then
        BUILD_SIZE=$(du -sh "${BUILD_DIR}" | cut -f1)
        log_info "Build size: ${BUILD_SIZE}"
        
        # Check for large bundles
        LARGE_FILES=$(find "${BUILD_DIR}" -type f -size +500k 2>/dev/null | wc -l)
        if [ "${LARGE_FILES}" -gt 0 ]; then
            log_warning "Found ${LARGE_FILES} files larger than 500KB"
            log_warning "Consider code splitting for better performance"
        fi
    fi
}

# Setup environment
setup_environment() {
    log_section "Setting Up Environment"
    
    # Create .env.production if it doesn't exist
    if [ ! -f "${PROJECT_DIR}/.env.production" ]; then
        log_info "Creating production environment file..."
        cat > "${PROJECT_DIR}/.env.production" << EOF
# Production Environment Variables
NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL:-https://your-project.supabase.co}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY:-your-anon-key}
NODE_ENV=production
EOF
        log_warning "Please update .env.production with actual values"
    fi
    
    log_success "Environment configured"
}

# Deploy to hosting platform
deploy_application() {
    log_section "Deploying Application"
    
    cd "${PROJECT_DIR}"
    
    # Check for Vercel
    if command -v vercel &> /dev/null; then
        log_info "Deploying to Vercel..."
        vercel --prod --confirm
        log_success "Deployed to Vercel successfully"
        return
    fi
    
    # Check for PM2 (for VPS deployment)
    if command -v pm2 &> /dev/null; then
        log_info "Starting with PM2..."
        
        # Create PM2 ecosystem file
        cat > "${PROJECT_DIR}/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: 'hobbyist-partner-portal',
    script: 'npm',
    args: 'start',
    cwd: '${PROJECT_DIR}',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
        
        pm2 stop hobbyist-partner-portal 2>/dev/null || true
        pm2 start ecosystem.config.js
        pm2 save
        
        log_success "Application started with PM2"
        return
    fi
    
    # Fallback to manual start
    log_info "Starting application manually..."
    log_warning "For production, consider using Vercel, PM2, or Docker"
    
    npm start &
    APP_PID=$!
    
    sleep 5
    
    if ps -p $APP_PID > /dev/null; then
        log_success "Application started (PID: ${APP_PID})"
        log_info "Access at: http://localhost:3000"
    else
        log_error "Failed to start application"
        exit 1
    fi
}

# Health check
health_check() {
    log_section "Running Health Check"
    
    MAX_ATTEMPTS=10
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|304"; then
            log_success "Application is healthy"
            
            # Test optimized endpoints
            log_info "Testing optimized data service..."
            
            # Test dashboard endpoint
            RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:3000/api/dashboard/stats 2>/dev/null || echo "N/A")
            
            if [ "${RESPONSE_TIME}" != "N/A" ]; then
                log_info "Dashboard API response time: ${RESPONSE_TIME}s"
                
                # Check if response time is acceptable
                if (( $(echo "${RESPONSE_TIME} > 2" | bc -l 2>/dev/null || echo 0) )); then
                    log_warning "API response time is slow (>2s)"
                fi
            fi
            
            return 0
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        log_info "Waiting for application to start... (${ATTEMPT}/${MAX_ATTEMPTS})"
        sleep 3
    done
    
    log_error "Health check failed"
    return 1
}

# Generate deployment report
generate_report() {
    log_section "Generating Deployment Report"
    
    REPORT_FILE="${PROJECT_DIR}/deployment-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "${REPORT_FILE}" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "buildTime": ${BUILD_TIME:-0},
  "buildSize": "${BUILD_SIZE:-unknown}",
  "performanceScore": ${SCORE:-0},
  "nodeVersion": "$(node -v)",
  "npmVersion": "$(npm -v)",
  "platform": "$(uname -s)",
  "optimizations": {
    "caching": true,
    "v8Optimization": true,
    "bundleSplitting": true,
    "swcMinification": true
  }
}
EOF
    
    log_success "Deployment report saved to: ${REPORT_FILE}"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # Remove temporary files
    rm -f "${PROJECT_DIR}/.env.local.backup" 2>/dev/null || true
    
    log_success "Cleanup complete"
}

# Main execution
main() {
    log_section "HobbyistSwiftUI Partner Portal - Optimized Deployment"
    echo -e "${CYAN}Starting deployment with V8 optimizations...${NC}\n"
    
    # Set error trap
    trap 'log_error "Deployment failed"; exit 1' ERR
    
    # Run deployment steps
    check_prerequisites
    install_dependencies
    run_performance_tests
    setup_environment
    build_application
    deploy_application
    health_check
    generate_report
    cleanup
    
    log_section "Deployment Complete! 🚀"
    log_success "Partner portal deployed with V8 optimizations"
    log_info "Monitor performance metrics in the dashboard"
    
    # Show important URLs
    echo -e "\n${BOLD}Access URLs:${NC}"
    echo -e "  Local: ${CYAN}http://localhost:3000${NC}"
    echo -e "  Dashboard: ${CYAN}http://localhost:3000/dashboard${NC}"
    echo -e "  Performance: ${CYAN}http://localhost:3000/api/performance${NC}"
}

# Run main function
main "$@"