import Airtable from 'airtable';

const AIRTABLE_API_KEY = 'patFsYfcWo1hUENf6.8ed5d88b28ff7719b89c2835b37a6a6692cd5c8ff42a8b28f34e189c44221e21';
const AIRTABLE_BASE_ID = 'appo3x0WjbCIhA0Lz';

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
