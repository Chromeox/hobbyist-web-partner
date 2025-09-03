#!/bin/bash

# Fix Migration Order Script
# This ensures base tables exist before applying the flexible pricing migration

echo "🔧 Fixing Migration Order for HobbyistSwiftUI"
echo "=============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${BLUE}This script will create the base tables if they don't exist${NC}"
echo "Then apply the flexible pricing migration properly."
echo ""

# Create a base migration that ensures user_credits exists
cat > supabase/migrations/20240820_base_tables.sql << 'EOF'
-- Base Tables Migration
-- Creates tables that other migrations depend on

-- Create user_credits table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_credits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_credits INTEGER DEFAULT 0,
    used_credits INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON user_credits(user_id);

-- Enable RLS
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policy
CREATE POLICY IF NOT EXISTS "Users can view own credits" 
    ON user_credits FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own credits" 
    ON user_credits FOR UPDATE 
    USING (auth.uid() = user_id);

-- Create other base tables that might be missing
CREATE TABLE IF NOT EXISTS studios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration INTEGER, -- in minutes
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    booking_date TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'confirmed',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies
CREATE POLICY IF NOT EXISTS "Studios viewable by all" 
    ON studios FOR SELECT 
    USING (true);

CREATE POLICY IF NOT EXISTS "Classes viewable by all" 
    ON classes FOR SELECT 
    USING (true);

CREATE POLICY IF NOT EXISTS "Users can view own bookings" 
    ON bookings FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can create own bookings" 
    ON bookings FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE user_credits IS 'Base table for user credit management';
COMMENT ON TABLE studios IS 'Studios offering classes';
COMMENT ON TABLE classes IS 'Classes offered by studios';
COMMENT ON TABLE bookings IS 'User bookings for classes';
EOF

echo -e "${GREEN}✅ Created base tables migration${NC}"
echo ""

# Now apply migrations in order
echo "Now I'll apply the migrations in the correct order."
echo "You'll be prompted for your database password."
echo ""

echo -e "${YELLOW}Running migrations...${NC}"
if supabase db push --include-all; then
    echo -e "${GREEN}✅ All migrations applied successfully!${NC}"
    echo ""
    
    # Verify the tables exist
    echo "Verifying tables..."
    echo "You'll need to enter your password again to verify:"
    
    supabase db dump --schema public | grep -E "CREATE TABLE|user_credits|credit_packs|subscription_plans" | head -20
    
    echo ""
    echo -e "${GREEN}🎉 Success! Your database is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Deploy edge functions: supabase functions deploy --all"
    echo "2. Configure API keys in .env.local"
    echo "3. Set up Stripe products"
else
    echo -e "${YELLOW}⚠️ Migration had issues. Let's try a different approach...${NC}"
    echo ""
    echo "Try running this command manually:"
    echo "supabase db reset"
    echo ""
    echo "This will reset your database and apply all migrations fresh."
fi