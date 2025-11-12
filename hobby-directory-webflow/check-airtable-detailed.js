import Airtable from 'airtable';

// Load from environment variables
const AIRTABLE_API_KEY = process.env.AIRTABLE_API_KEY;
const AIRTABLE_BASE_ID = process.env.AIRTABLE_BASE_ID || 'appo3x0WjbCIhA0Lz';

if (!AIRTABLE_API_KEY) {
  console.error('❌ Error: AIRTABLE_API_KEY environment variable is required');
  process.exit(1);
}

const base = new Airtable({ apiKey: AIRTABLE_API_KEY }).base(AIRTABLE_BASE_ID);

console.log('🔍 Detailed Airtable Analysis\n');

// Fetch ALL records to see full field list
base('Classes')
  .select({
    maxRecords: 10,
    view: 'Grid view'
  })
  .firstPage()
  .then(records => {
    console.log(`✅ Found ${records.length} classes\n`);
    
    // Collect all unique fields across all records
    const allFields = new Set();
    records.forEach(record => {
      Object.keys(record.fields).forEach(field => allFields.add(field));
    });
    
    console.log('📋 All Fields in Airtable Classes Table:');
    console.log('─────────────────────────────────────');
    Array.from(allFields).sort().forEach(field => {
      console.log(`  • ${field}`);
    });
    
    console.log('\n📝 Sample Record (first class):');
    console.log('─────────────────────────────────────');
    if (records.length > 0) {
      const sample = records[0].fields;
      Object.keys(sample).forEach(key => {
        const value = typeof sample[key] === 'object' ? JSON.stringify(sample[key]) : sample[key];
        console.log(`  ${key}: ${value}`);
      });
    }
  })
  .catch(error => {
    console.error('❌ Error:', error.message);
  });
