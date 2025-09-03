#!/bin/bash

# Supabase Migration Apply Script
# This script will apply all pending migrations to your Supabase database

echo "======================================"
echo "  Supabase Migration Apply Script"
echo "======================================"
echo ""
echo "This script will apply migrations 03-08 to your Supabase database."
echo ""
echo "Please enter your database password"
echo "(You can find it in the Supabase Dashboard > Settings > Database)"
echo ""
read -s -p "Database password: " DB_PASSWORD
echo ""
echo ""

# Project details
PROJECT_ID="mcjqvdzdhtcvbrejvrtp"
DB_HOST="aws-0-us-west-1.pooler.supabase.com"
DB_URL="postgresql://postgres.${PROJECT_ID}:${DB_PASSWORD}@${DB_HOST}:6543/postgres"

echo "Connecting to database..."
echo ""

# Apply migrations using db push
PGPASSWORD="${DB_PASSWORD}" /opt/homebrew/opt/supabase/bin/supabase db push --password "${DB_PASSWORD}" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migrations applied successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Enable real-time on key tables"
    echo "2. Create edge functions"
    echo "3. Configure storage buckets"
    echo "4. Insert test data"
else
    echo ""
    echo "❌ Failed to apply migrations. Please check your password and try again."
    echo "   You can reset your password at:"
    echo "   https://supabase.com/dashboard/project/${PROJECT_ID}/settings/database"
fi