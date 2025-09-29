#!/usr/bin/env node

// Simple test to verify Supabase connection from web portal
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

console.log('Testing Supabase Connection...');
console.log('URL:', supabaseUrl);
console.log('Key:', supabaseKey ? '***' + supabaseKey.slice(-10) : 'NOT SET');

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase configuration in .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
  try {
    // Test basic connection
    console.log('\n🔍 Testing connection...');
    const { data, error } = await supabase.from('users').select('count').limit(1);
    
    if (error) {
      console.error('❌ Connection failed:', error.message);
      
      if (error.message.includes('relation "users" does not exist')) {
        console.log('💡 This might be expected if the users table hasn\'t been created yet');
      }
      
      return false;
    }
    
    console.log('✅ Successfully connected to Supabase!');
    console.log('Data:', data);
    return true;
    
  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
    return false;
  }
}

async function testAuth() {
  try {
    console.log('\n🔐 Testing authentication...');
    const { data: { user }, error } = await supabase.auth.getUser();
    
    // Auth session missing is expected when not logged in - this is normal
    if (error && error.message !== 'Auth session missing!') {
      console.error('❌ Auth test failed:', error.message);
      return false;
    }
    
    console.log('✅ Authentication system is accessible');
    console.log('Current user:', user ? 'Authenticated' : 'Anonymous (expected)');
    return true;
    
  } catch (err) {
    console.error('❌ Auth error:', err.message);
    return false;
  }
}

async function main() {
  const connectionSuccess = await testConnection();
  const authSuccess = await testAuth();
  
  console.log('\n📊 Test Results:');
  console.log('Connection:', connectionSuccess ? '✅' : '❌');
  console.log('Authentication:', authSuccess ? '✅' : '❌');
  
  if (connectionSuccess && authSuccess) {
    console.log('\n🎉 Web portal is properly configured for Supabase!');
    process.exit(0);
  } else {
    console.log('\n❌ Configuration issues detected. Please check your setup.');
    process.exit(1);
  }
}

main().catch(console.error);