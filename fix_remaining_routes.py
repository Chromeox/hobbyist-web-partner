import re
import os

files_to_fix = [
    "app/api/credit-packs/[id]/route.ts",
    "app/api/credit-packs/route.ts",
    "app/api/payouts/route.ts",
    "app/api/pricing/settings/route.ts",
    "app/api/stripe-webhooks/route.ts",
    "app/api/instructors/route.ts",
    "app/api/instructors/profile/route.ts",
    "app/api/instructors/invite/route.ts",
    "app/api/instructors/approve/route.ts",
    "app/api/data-import/route.ts",
]

lazy_init = """// Lazy initialization to avoid build-time evaluation
const getSupabase = () => {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(supabaseUrl, supabaseServiceRoleKey);
};"""

for file_path in files_to_fix:
    if not os.path.exists(file_path):
        print(f"✗ File not found: {file_path}")
        continue
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace module-level initialization with lazy init
    pattern = r'(\/\/ Initialize Supabase.*?\n)?const supabaseUrl = process\.env\.NEXT_PUBLIC_SUPABASE_URL!;\nconst supabaseServiceRoleKey = process\.env\.SUPABASE_SERVICE_ROLE_KEY!;\nconst supabase = createClient\(supabaseUrl, supabaseServiceRoleKey\);'
    content = re.sub(pattern, lazy_init, content, flags=re.DOTALL)
    
    # Add getSupabase() call to each handler
    handlers = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
    for handler in handlers:
        # Pattern to match handler function start
        pattern = fr'(export async function {handler}\(request: Request\) {{\n  try {{\n)'
        replacement = fr'\1    const supabase = getSupabase();\n'
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"✓ Fixed {file_path}")

print("Done!")
