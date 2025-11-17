#!/bin/bash

# Files that need fixing
files=(
  "app/api/bookings/route.ts"
  "app/api/categories/route.ts"
  "app/api/classes/meta/[id]/route.ts"
  "app/api/classes/meta/route.ts"
  "app/api/classes/route.ts"
  "app/api/credit-packs/[id]/route.ts"
  "app/api/credit-packs/route.ts"
  "app/api/data-import/route.ts"
  "app/api/instructors/approve/route.ts"
  "app/api/instructors/invite/route.ts"
  "app/api/instructors/profile/route.ts"
  "app/api/instructors/route.ts"
  "app/api/payouts/route.ts"
  "app/api/pricing/settings/route.ts"
  "app/api/stripe-webhooks/route.ts"
)

for file in "${files[@]}"; do
  echo "Fixing $file"

  # Remove the old Supabase import
  sed -i '' '/^import { createClient } from .@supabase\/supabase-js/d' "$file"

  # Add new import after NextResponse import
  sed -i '' '/^import { NextResponse }/a\
import { createServiceSupabase } from '\''@/lib/supabase'\'';
' "$file"

  # Remove the manual client creation lines (3 lines)
  sed -i '' '/^const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL/,/^const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);$/d' "$file"

  # Add comment where the client creation was removed
  sed -i '' '/^export const dynamic/a\
\
// Supabase client created lazily in each route handler with createServiceSupabase()
' "$file"

done

echo "Done! Updated all files to use createServiceSupabase()"
echo "Note: You'll need to add 'const supabase = createServiceSupabase();' inside each route handler function."
