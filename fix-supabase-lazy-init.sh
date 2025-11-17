#!/bin/bash

# Files that need to be fixed
files=(
  "app/api/classes/route.ts"
  "app/api/credit-packs/[id]/route.ts"
  "app/api/credit-packs/route.ts"
  "app/api/payouts/route.ts"
  "app/api/pricing/settings/route.ts"
  "app/api/stripe-webhooks/route.ts"
  "app/api/instructors/route.ts"
  "app/api/instructors/profile/route.ts"
  "app/api/instructors/invite/route.ts"
  "app/api/instructors/approve/route.ts"
  "app/api/data-import/route.ts"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "Processing $file..."
    
    # Create a temporary file
    tmp_file="${file}.tmp"
    
    # Read the file and apply transformations
    awk '
    BEGIN { in_supabase_init = 0; printed_lazy = 0 }
    
    # Detect start of module-level Supabase initialization
    /^(\/\/ Initialize Supabase|const supabaseUrl = process\.env\.NEXT_PUBLIC_SUPABASE_URL)/ {
      if (!printed_lazy) {
        print "// Lazy initialization to avoid build-time evaluation"
        print "const getSupabase = () => {"
        print "  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;"
        print "  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;"
        print "  return createClient(supabaseUrl, supabaseServiceRoleKey);"
        print "};"
        print ""
        printed_lazy = 1
        in_supabase_init = 1
      }
      next
    }
    
    # Skip the old initialization lines
    /^const supabaseServiceRoleKey = process\.env\.SUPABASE_SERVICE_ROLE_KEY/ { next }
    /^const supabase = createClient\(supabaseUrl, supabaseServiceRoleKey\);/ { 
      in_supabase_init = 0
      next
    }
    
    # Skip empty comment lines after initialization
    /^\/\/ $/ && in_supabase_init { next }
    
    # Add getSupabase() call at start of each handler function
    /^export async function (GET|POST|PUT|DELETE|PATCH)\(/ {
      print $0
      getline
      print $0
      if ($0 ~ /try \{/) {
        print "    const supabase = getSupabase();"
      }
      next
    }
    
    # Print all other lines
    { print }
    ' "$file" > "$tmp_file"
    
    # Replace original file
    mv "$tmp_file" "$file"
    echo "✓ Fixed $file"
  else
    echo "✗ File not found: $file"
  fi
done

echo "Done!"
