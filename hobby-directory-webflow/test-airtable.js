// Quick test to verify Airtable connection
import Airtable from 'airtable';

const AIRTABLE_API_KEY = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';
const AIRTABLE_BASE_ID = 'appo3x0WjbCIhA0Lz';

const base = new Airtable({ apiKey: AIRTABLE_API_KEY }).base(AIRTABLE_BASE_ID);

console.log('🔍 Testing Airtable connection...\n');

// Fetch first 5 classes
base('Classes')
  .select({
    maxRecords: 5,
    view: 'Grid view' // or your default view name
  })
  .firstPage()
  .then(records => {
    console.log(`✅ Successfully connected! Found ${records.length} classes:\n`);

    records.forEach(record => {
      console.log(`📅 ${record.fields.name || record.fields.title || 'Untitled Class'}`);
      console.log(`   Fields available:`, Object.keys(record.fields).join(', '));
      console.log('');
    });
  })
  .catch(error => {
    console.error('❌ Connection failed:', error.message);
    console.error('\nPossible issues:');
    console.error('- Base ID might be incorrect');
    console.error('- API key might not have access to this base');
    console.error('- Table name might not be "Classes"');
  });
