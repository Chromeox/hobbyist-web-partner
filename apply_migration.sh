#!/bin/bash

# Secure migration application script
# This script applies the migrations without storing the password

echo "🚀 Applying Supabase Migrations"
echo "================================"
echo ""
echo "This script will apply the database migrations to your Supabase project."
echo ""

# Navigate to project directory
cd /Users/chromefang.exe/HobbyistSwiftUI

# Prompt for password securely (won't be visible when typing)
echo "Please enter your database password:"
read -s DB_PASSWORD

echo ""
echo "Applying migrations..."

# Apply migrations with the password
PGPASSWORD="$DB_PASSWORD" /opt/homebrew/opt/supabase/bin/supabase db push

# Clear the password variable immediately
unset DB_PASSWORD
unset PGPASSWORD

echo ""
echo "✅ Migration process complete!"
echo ""
echo "You can verify the migration worked by:"
echo "1. Refreshing your dashboard at http://localhost:3000/dashboard"
echo "2. The Supabase connection test should show 'Database fully configured'"