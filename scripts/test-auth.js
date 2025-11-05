#!/usr/bin/env node

/**
 * Test Demo Authentication
 * Quickly debug authentication issues
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('🧪 Testing Demo Authentication...\n');

async function testAuth() {
  try {
    const demoEmail = 'demo@hobbyist.app';
    const demoPassword = 'DemoPass123!';

    console.log('📧 Demo credentials:');
    console.log(`   Email: ${demoEmail}`);
    console.log(`   Password: ${demoPassword}\n`);

    // Try to sign in
    console.log('🔐 Attempting sign in...');
    const { data, error } = await supabase.auth.signInWithPassword({
      email: demoEmail,
      password: demoPassword,
    });

    if (error) {
      console.error('❌ Sign in failed:', error.message);

      if (error.message.includes('Invalid login credentials')) {
        console.log('\n🔧 User doesn\'t exist, attempting signup...');

        const { data: signupData, error: signupError } = await supabase.auth.signUp({
          email: demoEmail,
          password: demoPassword,
          options: {
            data: {
              full_name: 'Demo Studio User',
              user_type: 'studio'
            }
          }
        });

        if (signupError) {
          console.error('❌ Signup failed:', signupError.message);
          return;
        }

        console.log('✅ Demo user created successfully');
        console.log('📧 Check your email for confirmation (if email confirmation is enabled)');

        // Try signing in again
        console.log('\n🔐 Attempting sign in after signup...');
        const { data: signinData, error: signinError } = await supabase.auth.signInWithPassword({
          email: demoEmail,
          password: demoPassword,
        });

        if (signinError) {
          console.error('❌ Sign in after signup failed:', signinError.message);
          if (signinError.message.includes('Email not confirmed')) {
            console.log('⚠️  Email confirmation required. Check Supabase settings to disable email confirmation for easier testing.');
          }
          return;
        }

        console.log('✅ Sign in after signup successful');
      }
      return;
    }

    console.log('✅ Authentication successful');
    console.log(`👤 User ID: ${data.user.id}`);
    console.log(`📧 Email: ${data.user.email}`);
    console.log(`✅ Demo authentication working!`);

  } catch (error) {
    console.error('💥 Unexpected error:', error.message);
  }
}

testAuth().then(() => {
  console.log('\n🎯 Authentication test complete!');
  process.exit(0);
}).catch(error => {
  console.error('💥 Test failed:', error);
  process.exit(1);
});