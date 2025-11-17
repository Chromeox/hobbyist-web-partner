#!/bin/bash

# Add dynamic config to all API routes
find app/api -name "route.ts" | while read file; do
  # Check if file already has dynamic export
  if ! grep -q "export const dynamic" "$file"; then
    echo "Adding dynamic config to $file"
    # Add after the last import or at the beginning
    if grep -q "^import" "$file"; then
      # Find the line number of the last import
      last_import=$(grep -n "^import" "$file" | tail -1 | cut -d: -f1)
      # Insert after last import + 1 blank line
      sed -i '' "${last_import}a\\
\\
export const dynamic = 'force-dynamic';\\
" "$file"
    else
      # No imports, add at top
      sed -i '' '1i\\
export const dynamic = '\''force-dynamic'\'';\\
\\
' "$file"
    fi
  else
    echo "Skipping $file (already has dynamic config)"
  fi
done

echo "Done! Added dynamic config to all API routes."
