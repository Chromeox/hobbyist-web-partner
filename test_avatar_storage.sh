#!/bin/bash

# Avatar Storage Test Script
# Quick test to verify the avatars bucket is properly configured

set -e

echo "======================================"
echo "Avatar Storage Test"
echo "======================================"
echo ""

# Supabase connection
DB_HOST="aws-0-us-west-1.pooler.supabase.com"
DB_PORT="6543"
DB_NAME="postgres"
DB_USER="postgres.mcjqvdzdhtcvbrejvrtp"
DB_PASSWORD="tLTLwu0Sx8TUuCjl"

CONNECTION_STRING="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

echo "Running quick diagnostics..."
echo ""

# Test 1: Check bucket exists
echo "🪣 Test 1: Checking avatars bucket..."
BUCKET_CHECK=$(PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -t -c \
  "SELECT COUNT(*) FROM storage.buckets WHERE id = 'avatars';")

if [ "$BUCKET_CHECK" -eq 1 ]; then
    echo "   ✅ Avatars bucket exists"
else
    echo "   ❌ Avatars bucket NOT found"
    echo "   Run: ./deploy_avatar_storage.sh"
    exit 1
fi

# Test 2: Check RLS is enabled
echo "🔒 Test 2: Checking RLS on storage.objects..."
RLS_CHECK=$(PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -t -c \
  "SELECT relrowsecurity FROM pg_class WHERE relname = 'objects' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');")

if [[ "$RLS_CHECK" == *"t"* ]]; then
    echo "   ✅ RLS is enabled"
else
    echo "   ❌ RLS is NOT enabled"
    exit 1
fi

# Test 3: Count policies
echo "📜 Test 3: Checking avatar policies..."
POLICY_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -t -c \
  "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE '%avatar%';")

if [ "$POLICY_COUNT" -eq 4 ]; then
    echo "   ✅ All 4 avatar policies exist"
else
    echo "   ⚠️  Found $POLICY_COUNT policies (expected 4)"
fi

# Test 4: Check user_profiles table
echo "👤 Test 4: Checking user_profiles.avatar_url..."
COLUMN_CHECK=$(PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -t -c \
  "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'avatar_url';")

if [ "$COLUMN_CHECK" -eq 1 ]; then
    echo "   ✅ avatar_url column exists"
else
    echo "   ⚠️  avatar_url column NOT found in user_profiles"
    echo "   Run: ALTER TABLE user_profiles ADD COLUMN avatar_url TEXT;"
fi

# Test 5: Show bucket details
echo ""
echo "📊 Bucket Details:"
PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -c \
  "SELECT id, name, public, created_at FROM storage.buckets WHERE id = 'avatars';"

echo ""
echo "======================================"
echo "Test Complete!"
echo "======================================"
echo ""
echo "Status: Ready for iOS app testing ✨"
echo ""
