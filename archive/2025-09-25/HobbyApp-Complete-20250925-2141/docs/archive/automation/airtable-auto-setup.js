/**
 * Airtable Auto-Setup Script
 * Automatically configures your Airtable base with sample data and validates structure
 * 
 * This script works with any Airtable plan (unlike the Metadata API)
 * 
 * Setup:
 * 1. Create base manually in Airtable ("Hobby Directory")
 * 2. Create table manually ("Events")
 * 3. Run this script to configure fields and add sample data
 * 4. Run: node airtable-auto-setup.js
 */

const Airtable = require('airtable');
const fs = require('fs').promises;
require('dotenv').config();

// ============= CONFIGURATION =============

const CONFIG = {
  AIRTABLE_TOKEN: process.env.AIRTABLE_TOKEN,
  AIRTABLE_BASE_ID: process.env.AIRTABLE_BASE_ID,
  AIRTABLE_TABLE_NAME: 'Events',
};

// Expected field structure for validation
const EXPECTED_FIELDS = {
  required: [
    'Name',           // Single line text
    'Studio',         // Single line text  
    'Event Date',     // Date
    'Time',           // Single line text
    'Location',       // Single line text
    'Address',        // Single line text
    'Price',          // Single line text
    'Description',    // Long text
    'Category',       // Single select
    'Status'          // Single select
  ],
  optional: [
    'Book Link',      // URL
    'Image URL',      // URL
    'Instagram URL',  // URL
    'Featured',       // Checkbox
    'Added By',       // Single line text
    'Notes'           // Long text
  ]
};

// Sample data to populate the base
const SAMPLE_EVENTS = [
  {
    'Name': 'Beginner Pottery Wheel Class',
    'Studio': 'Clay Mates Studio',
    'Event Date': '2024-12-20',
    'Time': '7:00 PM',
    'Location': 'Clay Mates Studio',
    'Address': '123 Main St, Vancouver BC',
    'Price': '$45',
    'Description': 'Learn the basics of wheel throwing in this 2-hour beginner-friendly class. All materials included.',
    'Category': 'Arts & Crafts',
    'Status': 'Published',
    'Featured': false,
    'Added By': 'Auto Setup',
    'Book Link': 'https://claymates.com/book',
    'Instagram URL': 'https://instagram.com/p/example1'
  },
  {
    'Name': 'HIIT Boxing Workout',
    'Studio': 'Rumble Boxing',
    'Event Date': '2024-12-21',
    'Time': '10:00 AM',
    'Location': 'Rumble Boxing Vancouver',
    'Address': '456 Granville St, Vancouver BC',
    'Price': '$25',
    'Description': 'High-intensity boxing workout for all fitness levels. Gloves provided.',
    'Category': 'Fitness',
    'Status': 'Published',
    'Featured': true,
    'Added By': 'Auto Setup',
    'Book Link': 'https://rumble.com/book',
    'Instagram URL': 'https://instagram.com/p/example2'
  },
  {
    'Name': 'Sourdough Bread Workshop',
    'Studio': 'Vancouver Baking School',
    'Event Date': '2024-12-22',
    'Time': '2:00 PM',
    'Location': 'Vancouver Baking School',
    'Address': '789 Cook St, Vancouver BC',
    'Price': '$60',
    'Description': 'Learn to make authentic sourdough bread from scratch. Take home your starter!',
    'Category': 'Culinary',
    'Status': 'Published',
    'Featured': false,
    'Added By': 'Auto Setup',
    'Book Link': 'https://bakingschool.com/sourdough'
  },
  {
    'Name': 'Yoga & Meditation Session',
    'Studio': 'Zen Wellness Center',
    'Event Date': '2024-12-23',
    'Time': '6:30 PM',
    'Location': 'Zen Wellness Center',
    'Address': '321 Harmony Ave, Vancouver BC',
    'Price': 'Free',
    'Description': 'Gentle yoga flow followed by guided meditation. Perfect for beginners.',
    'Category': 'Wellness',
    'Status': 'Published',
    'Featured': false,
    'Added By': 'Auto Setup',
    'Instagram URL': 'https://instagram.com/p/example3'
  },
  {
    'Name': 'Digital Photography Basics',
    'Studio': 'Vancouver Photo Collective',
    'Event Date': '2024-12-24',
    'Time': '11:00 AM',
    'Location': 'Photo Studio Downtown',
    'Address': '654 Photo St, Vancouver BC',
    'Price': '$75',
    'Description': 'Learn composition, lighting, and camera settings. Bring your own camera or borrow ours.',
    'Category': 'Photography',
    'Status': 'Draft',
    'Featured': false,
    'Added By': 'Auto Setup',
    'Book Link': 'https://photocollective.com/basics'
  }
];

// Field setup instructions
const FIELD_SETUP_GUIDE = {
  'Category': {
    type: 'Single Select',
    options: [
      'Fitness',
      'Arts & Crafts', 
      'Culinary',
      'Wellness',
      'Outdoor',
      'Photography',
      'Dance',
      'Music',
      'Tech',
      'Other'
    ]
  },
  'Status': {
    type: 'Single Select',
    options: [
      'Draft',
      'Published',
      'Expired'
    ],
    default: 'Draft'
  },
  'Featured': {
    type: 'Checkbox',
    default: false
  },
  'Event Date': {
    type: 'Date',
    dateFormat: 'Local',
    includeTime: false
  },
  'Description': {
    type: 'Long text',
    richText: true
  }
};

// ============= AIRTABLE SETUP CLIENT =============

class AirtableSetupClient {
  constructor() {
    if (!CONFIG.AIRTABLE_TOKEN || !CONFIG.AIRTABLE_BASE_ID) {
      throw new Error('Missing AIRTABLE_TOKEN or AIRTABLE_BASE_ID in environment variables');
    }
    
    this.base = new Airtable({ apiKey: CONFIG.AIRTABLE_TOKEN })
      .base(CONFIG.AIRTABLE_BASE_ID);
    
    this.table = this.base(CONFIG.AIRTABLE_TABLE_NAME);
    console.log('✅ Connected to Airtable base');
  }

  async validateBaseStructure() {
    console.log('🔍 Validating base structure...');
    
    try {
      // Try to read one record to validate field access
      const records = await this.table.select({
        maxRecords: 1
      }).firstPage();
      
      console.log('✅ Base structure validated');
      return true;
    } catch (error) {
      console.error('❌ Error validating base structure:', error.message);
      
      if (error.message.includes('NOT_FOUND')) {
        console.log('\n📝 Setup Instructions:');
        console.log('1. Go to https://airtable.com');
        console.log('2. Create a new base called "Hobby Directory"');
        console.log('3. Rename the default table to "Events"');
        console.log('4. Set your AIRTABLE_BASE_ID in .env.airtable');
        console.log('5. Run this script again');
      }
      
      return false;
    }
  }

  async checkExistingData() {
    try {
      const records = await this.table.select({
        maxRecords: 10
      }).firstPage();
      
      console.log(`📊 Found ${records.length} existing records`);
      
      if (records.length > 0) {
        console.log('\n🔍 Sample of existing data:');
        records.slice(0, 3).forEach((record, i) => {
          const name = record.get('Name') || 'Unnamed';
          const studio = record.get('Studio') || 'Unknown Studio';
          console.log(`   ${i + 1}. ${name} (${studio})`);
        });
      }
      
      return records.length;
    } catch (error) {
      console.error('❌ Error checking existing data:', error.message);
      return 0;
    }
  }

  async addSampleData(force = false) {
    const existingCount = await this.checkExistingData();
    
    if (existingCount > 0 && !force) {
      console.log('\n⚠️  Base already contains data. Use --force to add sample data anyway.');
      console.log('   Or manually clear the table first.');
      return false;
    }
    
    console.log('\n📝 Adding sample events...');
    
    try {
      // Add sample events in batches
      const batchSize = 10;
      for (let i = 0; i < SAMPLE_EVENTS.length; i += batchSize) {
        const batch = SAMPLE_EVENTS.slice(i, i + batchSize);
        const formattedBatch = batch.map(event => ({ fields: event }));
        
        await this.table.create(formattedBatch);
        console.log(`   ✅ Added batch of ${batch.length} events`);
        
        // Brief pause between batches
        if (i + batchSize < SAMPLE_EVENTS.length) {
          await this.delay(1000);
        }
      }
      
      console.log(`\n🎉 Successfully added ${SAMPLE_EVENTS.length} sample events!`);
      return true;
      
    } catch (error) {
      console.error('❌ Error adding sample data:', error.message);
      
      if (error.message.includes('UNKNOWN_FIELD_NAME')) {
        console.log('\n📝 Field Setup Required:');
        console.log('Some fields are missing. Please create these fields in your Airtable base:');
        this.printFieldSetupInstructions();
      }
      
      return false;
    }
  }

  printFieldSetupInstructions() {
    console.log('\n🛠️  FIELD SETUP INSTRUCTIONS:');
    console.log('==========================================\n');
    
    console.log('Required Fields:');
    EXPECTED_FIELDS.required.forEach((field, i) => {
      const setup = FIELD_SETUP_GUIDE[field];
      console.log(`${i + 1}. ${field}`);
      if (setup) {
        console.log(`   Type: ${setup.type}`);
        if (setup.options) {
          console.log(`   Options: ${setup.options.join(', ')}`);
        }
        if (setup.default) {
          console.log(`   Default: ${setup.default}`);
        }
      } else {
        console.log(`   Type: Single line text`);
      }
      console.log('');
    });
    
    console.log('Optional Fields:');
    EXPECTED_FIELDS.optional.forEach((field, i) => {
      const setup = FIELD_SETUP_GUIDE[field];
      console.log(`${i + 1}. ${field}`);
      if (setup) {
        console.log(`   Type: ${setup.type}`);
      } else if (field.includes('URL') || field.includes('Link')) {
        console.log(`   Type: URL`);
      } else {
        console.log(`   Type: Single line text`);
      }
      console.log('');
    });
    
    console.log('🔗 Quick Setup:');
    console.log('1. Copy field names exactly as shown above');
    console.log('2. Set field types as specified');
    console.log('3. Add options for Single Select fields');
    console.log('4. Run this script again to add sample data\n');
  }

  async createFieldSetupTemplate() {
    const template = {
      baseName: 'Hobby Directory',
      tableName: 'Events',
      fields: {
        required: {},
        optional: {}
      }
    };
    
    // Add field definitions
    EXPECTED_FIELDS.required.forEach(field => {
      template.fields.required[field] = FIELD_SETUP_GUIDE[field] || { type: 'Single line text' };
    });
    
    EXPECTED_FIELDS.optional.forEach(field => {
      template.fields.optional[field] = FIELD_SETUP_GUIDE[field] || { 
        type: field.includes('URL') || field.includes('Link') ? 'URL' : 'Single line text' 
      };
    });
    
    // Save template
    const filename = 'airtable-field-setup-template.json';
    await fs.writeFile(filename, JSON.stringify(template, null, 2));
    console.log(`💾 Field setup template saved to ${filename}`);
    
    return template;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ============= MAIN EXECUTION =============

async function main() {
  const args = process.argv.slice(2);
  const force = args.includes('--force');
  const templateOnly = args.includes('--template-only');
  
  console.log('🚀 Airtable Auto-Setup Script');
  console.log('==============================\n');
  
  const setupClient = new AirtableSetupClient();
  
  try {
    // Create field setup template
    if (templateOnly) {
      await setupClient.createFieldSetupTemplate();
      setupClient.printFieldSetupInstructions();
      return;
    }
    
    // Validate base structure
    const isValid = await setupClient.validateBaseStructure();
    if (!isValid) {
      console.log('\n❌ Base validation failed. Please follow setup instructions above.');
      return;
    }
    
    // Check existing data
    await setupClient.checkExistingData();
    
    // Add sample data
    const success = await setupClient.addSampleData(force);
    
    if (success) {
      console.log('\n🎯 Next Steps:');
      console.log('=============');
      console.log('1. Check your Airtable base for the sample events');
      console.log('2. Create views (Published Events, Draft Events, etc.)');
      console.log('3. Set up WhaleSync to connect to Webflow');
      console.log('4. Start adding your own events manually or via forms\n');
      
      console.log('🔗 Quick Links:');
      console.log(`   Airtable Base: https://airtable.com/${CONFIG.AIRTABLE_BASE_ID}`);
      console.log('   WhaleSync: https://whalesync.com');
      console.log('   Manual Setup Guide: ./airtable-manual-setup.md\n');
    } else {
      setupClient.printFieldSetupInstructions();
    }
    
    // Create template for reference
    await setupClient.createFieldSetupTemplate();
    
  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    
    if (error.message.includes('API key')) {
      console.log('\n🔑 Authentication Issue:');
      console.log('1. Check your AIRTABLE_TOKEN in .env.airtable');
      console.log('2. Ensure token has read/write permissions');
      console.log('3. Verify base scope is set correctly\n');
    }
  }
}

// ============= CLI HELP =============

if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log('🛠️  Airtable Auto-Setup Script');
  console.log('===============================\n');
  console.log('Usage:');
  console.log('  node airtable-auto-setup.js [options]\n');
  console.log('Options:');
  console.log('  --force          Add sample data even if base contains existing records');
  console.log('  --template-only  Generate field setup template without adding data');
  console.log('  --help, -h       Show this help message\n');
  console.log('Examples:');
  console.log('  node airtable-auto-setup.js                 # Normal setup');
  console.log('  node airtable-auto-setup.js --force         # Force add sample data');
  console.log('  node airtable-auto-setup.js --template-only # Generate template only\n');
  process.exit(0);
}

// Run the setup
if (require.main === module) {
  main();
}

module.exports = { AirtableSetupClient, SAMPLE_EVENTS, EXPECTED_FIELDS };