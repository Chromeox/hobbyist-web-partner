#!/usr/bin/env node

/**
 * Check Current Database Schema
 * This helps us understand the existing table structure
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('🔍 Checking Current Database Schema...\n');

async function checkSchema() {
  try {
    // Check what tables exist
    console.log('📋 Checking existing tables...');

    const { data: tables, error: tablesError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .order('table_name');

    if (tablesError) {
      console.error('❌ Error checking tables:', tablesError.message);
      return;
    }

    console.log('✅ Found tables:');
    tables.forEach(table => {
      console.log(`   • ${table.table_name}`);
    });

    // Check auth.users if available
    console.log('\n👥 Checking auth.users...');
    try {
      const { data: authUsers, error: authError } = await supabase
        .from('auth.users')
        .select('id, email')
        .limit(1);

      if (authError) {
        console.log('⚠️  auth.users not accessible:', authError.message);
      } else {
        console.log('✅ auth.users table accessible');
      }
    } catch (error) {
      console.log('⚠️  auth.users not available');
    }

    // Check if we have user_profiles or similar
    const userTables = tables.filter(t =>
      t.table_name.includes('user') ||
      t.table_name.includes('profile') ||
      t.table_name.includes('instructor')
    );

    if (userTables.length > 0) {
      console.log('\n👤 User-related tables found:');
      for (const table of userTables) {
        console.log(`\n📄 ${table.table_name}:`);

        try {
          const { data: columns, error: columnsError } = await supabase
            .from('information_schema.columns')
            .select('column_name, data_type, is_nullable')
            .eq('table_schema', 'public')
            .eq('table_name', table.table_name)
            .order('ordinal_position');

          if (columns) {
            columns.forEach(col => {
              console.log(`   • ${col.column_name} (${col.data_type}${col.is_nullable === 'YES' ? ', nullable' : ''})`);
            });
          }
        } catch (error) {
          console.log(`   ⚠️  Could not read columns for ${table.table_name}`);
        }
      }
    }

    // Check sample data from key tables
    console.log('\n📊 Checking sample data...');

    // Try to get sample from instructors table
    try {
      const { data: instructors, error: instError } = await supabase
        .from('instructors')
        .select('*')
        .limit(2);

      if (instructors && instructors.length > 0) {
        console.log('✅ Sample instructor data:');
        console.log(JSON.stringify(instructors[0], null, 2));
      } else {
        console.log('⚠️  No instructor data found');
      }
    } catch (error) {
      console.log('⚠️  Could not access instructors table');
    }

    // Try to get sample from user_profiles
    try {
      const { data: profiles, error: profilesError } = await supabase
        .from('user_profiles')
        .select('*')
        .limit(2);

      if (profiles && profiles.length > 0) {
        console.log('✅ Sample user_profiles data:');
        console.log(JSON.stringify(profiles[0], null, 2));
      } else {
        console.log('⚠️  No user_profiles data found');
      }
    } catch (error) {
      console.log('⚠️  Could not access user_profiles table');
    }

  } catch (error) {
    console.error('❌ Schema check failed:', error.message);
  }
}

checkSchema().then(() => {
  console.log('\n🎯 Schema check complete!');
  process.exit(0);
}).catch(error => {
  console.error('💥 Unexpected error:', error);
  process.exit(1);
});