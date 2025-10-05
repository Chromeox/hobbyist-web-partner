#!/bin/bash

# Avatar Storage Deployment Script
# This script deploys the avatar storage bucket and RLS policies to Supabase

set -e  # Exit on error

echo "======================================"
echo "Avatar Storage Deployment"
echo "======================================"
echo ""

# Supabase connection details
DB_HOST="aws-0-us-west-1.pooler.supabase.com"
DB_PORT="6543"
DB_NAME="postgres"
DB_USER="postgres.mcjqvdzdhtcvbrejvrtp"
DB_PASSWORD="tLTLwu0Sx8TUuCjl"

CONNECTION_STRING="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

echo "🔗 Connecting to Supabase..."
echo "   Host: ${DB_HOST}"
echo "   Database: ${DB_NAME}"
echo ""

# Step 1: Run the migration
echo "📦 Step 1: Creating avatars bucket and RLS policies..."
PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" \
  -f supabase/migrations/20250105000000_create_avatars_storage.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
else
    echo "❌ Migration failed!"
    exit 1
fi

echo ""

# Step 2: Validate the setup
echo "🔍 Step 2: Validating avatar storage configuration..."
PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" \
  -f supabase/migrations/validate_avatar_storage.sql

if [ $? -eq 0 ]; then
    echo "✅ Validation completed successfully!"
else
    echo "⚠️  Validation encountered issues. Check the output above."
fi

echo ""
echo "======================================"
echo "✨ Deployment Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Review the validation output above"
echo "  2. Build and run your iOS app"
echo "  3. Test profile picture upload in Edit Profile"
echo ""
echo "Documentation: supabase/AVATAR_STORAGE_SETUP.md"
echo ""
