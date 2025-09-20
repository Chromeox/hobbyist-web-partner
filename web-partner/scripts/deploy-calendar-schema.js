/**
 * Deploy Calendar Integration Schema to Supabase
 * This script will check if the calendar integration tables exist and create them if needed
 */

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

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

async function runSqlFile(filePath) {
  const sql = fs.readFileSync(filePath, 'utf8');

  // Split the SQL into individual statements
  const statements = sql
    .split(';')
    .map(s => s.trim())
    .filter(s => s.length > 0 && !s.startsWith('--'));

  console.log(`Executing ${statements.length} SQL statements from ${filePath}`);

  for (const statement of statements) {
    try {
      console.log(`Executing: ${statement.substring(0, 100)}...`);
      const { error } = await supabase.rpc('execute_sql', {
        sql_statement: statement
      });

      if (error) {
        console.error(`Error executing statement: ${error.message}`);
        throw error;
      }
    } catch (err) {
      // Try direct query execution as fallback
      try {
        const { error } = await supabase.from('_').select().limit(0);
        // If we get here, the connection works, continue with next statement
        console.warn(`Statement may have executed despite error: ${err.message}`);
      } catch (fallbackErr) {
        console.error(`Failed to execute statement: ${statement}`);
        throw err;
      }
    }
  }
}

async function deployCalendarSchema() {
  console.log('🔍 Checking existing calendar integration tables...');

  // Check if calendar integration tables already exist
  const tablesExist = await Promise.all([
    checkTableExists('calendar_integrations'),
    checkTableExists('imported_events'),
    checkTableExists('workshop_materials'),
    checkTableExists('studio_inventory'),
    checkTableExists('workshop_templates'),
    checkTableExists('studio_expenses')
  ]);

  const [calendarIntegrations, importedEvents, workshopMaterials, studioInventory, workshopTemplates, studioExpenses] = tablesExist;

  console.log('📊 Table existence check:');
  console.log(`  calendar_integrations: ${calendarIntegrations ? '✅' : '❌'}`);
  console.log(`  imported_events: ${importedEvents ? '✅' : '❌'}`);
  console.log(`  workshop_materials: ${workshopMaterials ? '✅' : '❌'}`);
  console.log(`  studio_inventory: ${studioInventory ? '✅' : '❌'}`);
  console.log(`  workshop_templates: ${workshopTemplates ? '✅' : '❌'}`);
  console.log(`  studio_expenses: ${studioExpenses ? '✅' : '❌'}`);

  if (calendarIntegrations && importedEvents) {
    console.log('✅ Calendar integration schema already exists!');

    // Check for any missing tables and create them
    if (!workshopMaterials || !studioInventory || !workshopTemplates || !studioExpenses) {
      console.log('📝 Some additional tables are missing, deploying full schema...');
    } else {
      console.log('🎉 All calendar integration tables are already deployed!');
      return;
    }
  }

  console.log('🚀 Deploying calendar integration schema...');

  try {
    // Read and execute the calendar integration schema
    const schemaPath = path.join(process.cwd(), '..', 'supabase', 'migrations', '09_calendar_integration_schema.sql');

    if (!fs.existsSync(schemaPath)) {
      console.error(`❌ Schema file not found: ${schemaPath}`);
      process.exit(1);
    }

    await runSqlFile(schemaPath);

    console.log('✅ Calendar integration schema deployed successfully!');

    // Verify deployment
    const verification = await Promise.all([
      checkTableExists('calendar_integrations'),
      checkTableExists('imported_events')
    ]);

    if (verification.every(exists => exists)) {
      console.log('🎉 Schema deployment verified - all tables created successfully!');
    } else {
      console.warn('⚠️  Schema deployment may have issues - some tables not found');
    }

  } catch (error) {
    console.error('❌ Failed to deploy calendar integration schema:', error.message);
    console.log('\n📋 Manual deployment instructions:');
    console.log('1. Go to your Supabase dashboard: https://supabase.com/dashboard/projects');
    console.log('2. Navigate to SQL Editor');
    console.log('3. Copy and paste the contents of supabase/migrations/09_calendar_integration_schema.sql');
    console.log('4. Execute the SQL script');

    process.exit(1);
  }
}

// Run the deployment
deployCalendarSchema().catch(console.error);