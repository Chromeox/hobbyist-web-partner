#!/bin/bash

# Supabase Setup and Verification Script
# This script helps you set up and verify your Supabase connection

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "🔧 Supabase Setup Assistant"
echo "=========================="
echo ""

# Check if .env.local exists
if [ ! -f "$CONFIG_DIR/.env.local" ]; then
    echo "❌ Configuration file not found!"
    echo ""
    echo "Please create $CONFIG_DIR/.env.local with your Supabase credentials."
    echo "You can copy the template:"
    echo ""
    echo "  cp $CONFIG_DIR/.env.template $CONFIG_DIR/.env.local"
    echo ""
    echo "Then edit .env.local with your actual values from:"
    echo "  1. Supabase Dashboard > Settings > API"
    echo "  2. Supabase Dashboard > Settings > Database"
    echo ""
    exit 1
fi

# Load environment variables
source "$CONFIG_DIR/.env.local"

echo "✅ Configuration file found"
echo ""

# Verify required variables
REQUIRED_VARS=(
    "SUPABASE_URL"
    "SUPABASE_ANON_KEY"
    "SUPABASE_PROJECT_ID"
)

MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Missing required environment variables:"
    for VAR in "${MISSING_VARS[@]}"; do
        echo "  - $VAR"
    done
    echo ""
    echo "Please add these to $CONFIG_DIR/.env.local"
    exit 1
fi

echo "✅ All required variables are set"
echo ""

# Test Supabase connection
echo "🔍 Testing Supabase connection..."
echo ""

# Test REST API connection
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    "$SUPABASE_URL/rest/v1/" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ REST API connection successful"
else
    echo "❌ REST API connection failed (HTTP $RESPONSE)"
    echo "   Please check your SUPABASE_URL and SUPABASE_ANON_KEY"
    exit 1
fi

# Check if Supabase CLI is installed
if command -v supabase &> /dev/null; then
    echo "✅ Supabase CLI is installed ($(supabase --version))"
    
    # Test CLI authentication if access token is provided
    if [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
        echo ""
        echo "🔍 Testing Supabase CLI authentication..."
        
        # Try to get project status
        if supabase projects list --token "$SUPABASE_ACCESS_TOKEN" &> /dev/null; then
            echo "✅ Supabase CLI authenticated successfully"
        else
            echo "⚠️  Supabase CLI authentication failed"
            echo "   Please check your SUPABASE_ACCESS_TOKEN"
        fi
    else
        echo "⚠️  SUPABASE_ACCESS_TOKEN not set - CLI management features will be limited"
    fi
else
    echo "⚠️  Supabase CLI not installed"
    echo ""
    echo "To install Supabase CLI, run:"
    echo "  brew install supabase/tap/supabase"
fi

echo ""
echo "🎉 Supabase setup verification complete!"
echo ""
echo "Your configuration:"
echo "  Project URL: ${SUPABASE_URL}"
echo "  Project ID: ${SUPABASE_PROJECT_ID}"
echo ""
echo "Next steps:"
echo "  1. Run './claude-safe-access.sh' to set up safe access for Claude"
echo "  2. Run './supabase-manage.sh status' to see detailed project info"