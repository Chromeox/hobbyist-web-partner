#!/usr/bin/env node

// Quick database connection test for Supabase
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://mcjqvdzdhtcvbrejvrtp.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5MDIzNzksImV4cCI6MjA2NDQ3ODM3OX0.puthoId8ElCgYzuyKJTTyzR9FeXmVA-Tkc8RV1rqdkc';

console.log('🔍 Testing Supabase Database Connection...\n');

async function testConnection() {
    try {
        const supabase = createClient(supabaseUrl, supabaseKey);

        console.log('✅ Supabase client created successfully');

        // Test basic table access
        console.log('📋 Testing table access...');

        const { data: classes, error: classError } = await supabase
            .from('classes')
            .select('id, name')
            .limit(3);

        if (classError) {
            console.log('⚠️  Classes table error:', classError.message);
        } else {
            console.log('✅ Classes table accessible:', classes?.length || 0, 'records found');
        }

        // Test credit system
        const { data: creditPacks, error: creditError } = await supabase
            .from('credit_packs')
            .select('name, credits, price')
            .limit(3);

        if (creditError) {
            console.log('⚠️  Credit packs error:', creditError.message);
        } else {
            console.log('✅ Credit packs accessible:', creditPacks?.length || 0, 'packages found');
            creditPacks?.forEach(pack => {
                console.log(`   • ${pack.name}: ${pack.credits} credits for $${pack.price}`);
            });
        }

        // Test new credit rollover table
        const { data: rollovers, error: rolloverError } = await supabase
            .from('credit_rollovers')
            .select('id')
            .limit(1);

        if (rolloverError) {
            console.log('⚠️  Credit rollovers error:', rolloverError.message);
        } else {
            console.log('✅ Credit rollovers table accessible (new migration deployed!)');
        }

        console.log('\n🎉 Database Connection Test Complete!');
        console.log('🚀 Your iOS app should now connect successfully to the fully deployed backend');

    } catch (error) {
        console.error('❌ Connection test failed:', error.message);
    }
}

testConnection();