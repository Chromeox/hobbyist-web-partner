#!/usr/bin/env node

/**
 * Test Script for Real-time Messaging System
 *
 * This script tests the messaging service without needing the full UI.
 * Run after deploying the messaging tables migration.
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase credentials in .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('🧪 Testing Messaging System...\n');

async function testMessagingSystem() {
  try {
    // Test 1: Check if tables exist
    console.log('📋 Test 1: Checking database tables...');

    const { data: conversations, error: convError } = await supabase
      .from('conversations')
      .select('*')
      .limit(1);

    if (convError) {
      console.error('❌ Conversations table not found:', convError.message);
      console.log('💡 Please deploy the migration first:');
      console.log('   1. Visit: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp');
      console.log('   2. Go to SQL Editor → New Query');
      console.log('   3. Copy content from: migrations/messaging_tables.sql');
      console.log('   4. Run the query');
      return;
    }

    const { data: messages, error: msgError } = await supabase
      .from('messages')
      .select('*')
      .limit(1);

    if (msgError) {
      console.error('❌ Messages table not found:', msgError.message);
      return;
    }

    console.log('✅ Database tables exist');
    console.log(`   • Conversations: ${conversations?.length || 0} found`);
    console.log(`   • Messages: ${messages?.length || 0} found\n`);

    // Test 2: Check users and instructors
    console.log('👥 Test 2: Checking users and instructors...');

    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, email, role')
      .limit(5);

    const { data: instructors, error: instructorsError } = await supabase
      .from('instructors')
      .select('id, user_id, business_name, verified')
      .limit(5);

    if (users && users.length > 0) {
      console.log('✅ Users found:');
      users.forEach(user => {
        console.log(`   • ${user.email} (${user.role})`);
      });
    } else {
      console.log('⚠️  No users found - messaging will need users to work');
    }

    if (instructors && instructors.length > 0) {
      console.log('✅ Instructors found:');
      instructors.forEach(instructor => {
        console.log(`   • ${instructor.business_name || 'Unnamed'} (${instructor.verified ? 'verified' : 'unverified'})`);
      });
    } else {
      console.log('⚠️  No instructors found - create some for testing');
    }
    console.log('');

    // Test 3: Test real-time subscription
    console.log('⚡ Test 3: Testing real-time subscriptions...');

    const channel = supabase.channel('test-messaging')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversations',
        },
        (payload) => {
          console.log('📨 Real-time conversation update:', payload.eventType);
        }
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'messages',
        },
        (payload) => {
          console.log('💬 Real-time message update:', payload.eventType);
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log('✅ Real-time subscriptions active');
        } else {
          console.log(`⚠️  Subscription status: ${status}`);
        }
      });

    // Wait a moment for subscription to connect
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Test 4: Create a test conversation (if we have users)
    if (users && users.length >= 2 && instructors && instructors.length >= 1) {
      console.log('\n💬 Test 4: Creating test conversation...');

      const studioUser = users.find(u => u.role === 'admin') || users[0];
      const instructor = instructors[0];

      const { data: conversation, error: createError } = await supabase
        .from('conversations')
        .insert({
          studio_id: studioUser.id,
          instructor_id: instructor.id,
          type: 'individual',
          name: `Test Chat - ${new Date().toLocaleTimeString()}`,
          participants: [studioUser.id, instructor.user_id]
        })
        .select()
        .single();

      if (createError) {
        console.error('❌ Failed to create test conversation:', createError.message);
      } else {
        console.log('✅ Test conversation created:', conversation.id);

        // Test 5: Send a test message
        console.log('\n📤 Test 5: Sending test message...');

        const { data: message, error: messageError } = await supabase
          .from('messages')
          .insert({
            conversation_id: conversation.id,
            sender_id: studioUser.id,
            content: `Test message sent at ${new Date().toLocaleString()}`
          })
          .select()
          .single();

        if (messageError) {
          console.error('❌ Failed to send test message:', messageError.message);
        } else {
          console.log('✅ Test message sent:', message.id);
        }
      }
    } else {
      console.log('⚠️  Skipping conversation test - need users and instructors');
    }

    // Clean up
    await new Promise(resolve => setTimeout(resolve, 1000));
    await supabase.removeChannel(channel);

    console.log('\n🎉 Messaging system test complete!');
    console.log('\n📋 Next steps:');
    console.log('   1. Deploy the migration if tables were missing');
    console.log('   2. Create test users and instructors if needed');
    console.log('   3. Visit http://localhost:3001/dashboard/messages');
    console.log('   4. Test the messaging interface');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testMessagingSystem().then(() => {
  process.exit(0);
}).catch(error => {
  console.error('💥 Unexpected error:', error);
  process.exit(1);
});