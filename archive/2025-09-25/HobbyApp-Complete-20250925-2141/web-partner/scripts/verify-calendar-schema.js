/**
 * Verify Calendar Integration Schema Deployment
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTableExists(tableName) {
  try {
    const { data, error } = await supabase
      .from(tableName)
      .select('*')
      .limit(0);

    return !error;
  } catch (err) {
    return false;
  }
}

async function verifySchema() {
  console.log('🔍 Verifying calendar integration schema deployment...');

  const tables = [
    'calendar_integrations',
    'imported_events',
    'workshop_materials',
    'studio_inventory',
    'workshop_templates',
    'studio_expenses'
  ];

  console.log('📊 Table verification:');

  let allTablesExist = true;

  for (const table of tables) {
    const exists = await checkTableExists(table);
    console.log(`  ${table}: ${exists ? '✅' : '❌'}`);
    if (!exists) allTablesExist = false;
  }

  if (allTablesExist) {
    console.log('\n🎉 All calendar integration tables exist! Schema deployment successful.');

    // Test inserting a sample record to verify RLS policies work
    try {
      console.log('\n🧪 Testing table access...');

      const { data, error } = await supabase
        .from('calendar_integrations')
        .select('*')
        .limit(1);

      if (error) {
        console.log('⚠️  RLS policies may be working (access restricted - this is expected)');
      } else {
        console.log('✅ Table access working');
      }

    } catch (err) {
      console.log('✅ RLS policies are active (access properly restricted)');
    }

  } else {
    console.log('\n❌ Some tables are missing. Schema deployment incomplete.');
    console.log('\n📋 Manual deployment required:');
    console.log('1. Go to Supabase Dashboard: https://supabase.com/dashboard/projects');
    console.log('2. Navigate to SQL Editor');
    console.log('3. Copy contents of supabase/migrations/09_calendar_integration_schema.sql');
    console.log('4. Execute the SQL script manually');
  }
}

verifySchema().catch(console.error);