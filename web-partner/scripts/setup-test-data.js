#!/usr/bin/env node

/**
 * Setup Test Data for Messaging System
 * Creates test instructor and user profiles for messaging
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables');
  console.log('Please check .env.local for:');
  console.log('- NEXT_PUBLIC_SUPABASE_URL');
  console.log('- SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('🔧 Setting up test data for messaging system...\n');

async function setupTestData() {
  try {
    // Create test instructor profile
    console.log('👨‍🏫 Creating test instructor...');

    const testInstructor = {
      id: 'test-instructor-001',
      name: 'Sarah Johnson',
      email: 'sarah@yogastudio.com',
      business_name: "Sarah's Yoga Studio",
      phone: '+1-604-555-0123',
      bio: 'Certified yoga instructor with 10+ years experience. Specializing in Hatha and Vinyasa yoga.',
      specialties: ['Hatha Yoga', 'Vinyasa', 'Meditation'],
      experience_years: 10,
      verified: true,
      status: 'approved',
      location: 'Vancouver, BC',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Check if instructors table exists and create instructor
    try {
      const { data: existingInstructor, error: checkError } = await supabase
        .from('instructors')
        .select('id')
        .eq('id', testInstructor.id)
        .single();

      if (existingInstructor) {
        console.log('✅ Test instructor already exists');
      } else {
        const { data: instructor, error: instructorError } = await supabase
          .from('instructors')
          .insert(testInstructor)
          .select()
          .single();

        if (instructorError) {
          console.log('⚠️  Could not create instructor (table may not exist)');
          console.log('   Creating user_profiles instead...');

          // Try creating in user_profiles instead
          const profileData = {
            id: testInstructor.id,
            email: testInstructor.email,
            full_name: testInstructor.name,
            user_type: 'instructor',
            business_name: testInstructor.business_name,
            phone: testInstructor.phone,
            verified: true,
            created_at: new Date().toISOString()
          };

          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .insert(profileData)
            .select()
            .single();

          if (profileError) {
            console.log('⚠️  Could not create user profile either');
            console.log('   We\'ll create instructor data directly in conversations');
          } else {
            console.log('✅ Test instructor profile created in user_profiles');
          }
        } else {
          console.log('✅ Test instructor created successfully');
          console.log(`   📧 ${instructor.email}`);
          console.log(`   🏢 ${instructor.business_name}`);
        }
      }
    } catch (error) {
      console.log('⚠️  Instructor table access issue, will create minimal test data');
    }

    // Create test conversation with the instructor
    console.log('\n💬 Creating test conversation...');

    const testConversation = {
      studio_id: null, // Will be set when user logs in
      instructor_id: testInstructor.id,
      type: 'individual',
      name: `Chat with ${testInstructor.name}`,
      participants: [testInstructor.id],
      last_message: 'Welcome! Ready to discuss your yoga classes?',
      last_message_at: new Date().toISOString()
    };

    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .insert(testConversation)
      .select()
      .single();

    if (convError) {
      console.log('⚠️  Could not create test conversation:', convError.message);
    } else {
      console.log('✅ Test conversation created');
      console.log(`   💬 "${conversation.name}"`);

      // Add welcome message
      const welcomeMessage = {
        conversation_id: conversation.id,
        sender_id: testInstructor.id,
        content: 'Hi! I\'m Sarah from Sarah\'s Yoga Studio. Looking forward to working with you! Feel free to ask about scheduling, payments, or any other questions.',
        created_at: new Date().toISOString()
      };

      const { data: message, error: msgError } = await supabase
        .from('messages')
        .insert(welcomeMessage)
        .select()
        .single();

      if (msgError) {
        console.log('⚠️  Could not create welcome message:', msgError.message);
      } else {
        console.log('✅ Welcome message added');
      }
    }

    console.log('\n🎉 Test data setup complete!');
    console.log('\n📋 Next steps:');
    console.log('1. Sign in at: http://localhost:3001/auth/signin');
    console.log('2. Visit messages: http://localhost:3001/dashboard/messages');
    console.log('3. You should see the conversation with Sarah');
    console.log('4. Send a test message to verify real-time messaging');

  } catch (error) {
    console.error('❌ Error setting up test data:', error.message);
  }
}

setupTestData().then(() => {
  console.log('\n✨ Test data setup finished!');
  process.exit(0);
}).catch(error => {
  console.error('💥 Unexpected error:', error);
  process.exit(1);
});