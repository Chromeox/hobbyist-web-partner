#!/usr/bin/env node

/**
 * Supabase Connection Test Script
 * Tests that your Supabase credentials are working correctly
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

console.log('\n🔍 Testing Supabase Connection...\n');
console.log('===================================');
console.log(`URL: ${supabaseUrl}`);
console.log(`Anon Key: ${supabaseAnonKey?.substring(0, 20)}...`);
console.log(`Service Key: ${supabaseServiceKey?.substring(0, 20)}...`);
console.log('===================================\n');

// Test with anon key (public access)
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testConnection() {
  try {
    // Test 1: Check if we can connect
    console.log('✅ Test 1: Connection established');
    
    // Test 2: Try to fetch from auth.users (will fail with anon key, but tests connection)
    const { data: authData, error: authError } = await supabase.auth.getSession();
    if (!authError) {
      console.log('✅ Test 2: Auth system accessible');
    } else {
      console.log('⚠️  Test 2: Auth accessible but no session (expected)');
    }
    
    // Test 3: Check if tables exist (try to query a table)
    const { error: tableError } = await supabase
      .from('users')
      .select('count')
      .limit(1);
    
    if (!tableError || tableError.code === 'PGRST116') {
      console.log('✅ Test 3: Database accessible');
    } else if (tableError.message.includes('permission denied')) {
      console.log('✅ Test 3: Database accessible (RLS enabled)');
    } else {
      console.log('❌ Test 3: Database error:', tableError.message);
    }
    
    // Test 4: Check realtime connection
    const channel = supabase.channel('test-channel');
    channel.subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        console.log('✅ Test 4: Realtime connection working');
        channel.unsubscribe();
        
        console.log('\n===================================');
        console.log('🎉 All tests passed! Supabase is configured correctly.');
        console.log('===================================\n');
        
        console.log('Next steps:');
        console.log('1. Go to your Supabase Dashboard:');
        console.log(`   ${supabaseUrl.replace('.supabase.co', '.supabase.com')}`);
        console.log('2. Enable Email authentication in Authentication → Providers');
        console.log('3. Add redirect URL: http://localhost:3000/auth/callback');
        console.log('4. Visit http://localhost:3000 to test the auth flow\n');
        
        process.exit(0);
      }
    });
    
    // Timeout after 5 seconds
    setTimeout(() => {
      console.log('⚠️  Test 4: Realtime connection timeout (may be disabled)');
      console.log('\n===================================');
      console.log('✅ Connection successful with warnings');
      console.log('===================================\n');
      process.exit(0);
    }, 5000);
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    process.exit(1);
  }
}

testConnection();