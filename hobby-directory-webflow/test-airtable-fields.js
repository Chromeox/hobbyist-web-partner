// Enhanced test to show ALL fields including empty ones
import Airtable from 'airtable';

const AIRTABLE_API_KEY = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';
const AIRTABLE_BASE_ID = 'appo3x0WjbCIhA0Lz';

const base = new Airtable({ apiKey: AIRTABLE_API_KEY }).base(AIRTABLE_BASE_ID);

console.log('🔍 Testing Airtable Fields...\n');

// Fetch all classes and collect ALL field names
base('Classes')
  .select({
    maxRecords: 10,
    view: 'Grid view'
  })
  .firstPage()
  .then(records => {
    console.log(`✅ Connected! Found ${records.length} classes\n`);

    // Collect all unique field names across all records
    const allFields = new Set();
    records.forEach(record => {
      Object.keys(record.fields).forEach(field => allFields.add(field));
    });

    console.log(`📋 TOTAL FIELDS FOUND: ${allFields.size}\n`);
    console.log('Field Names:');
    console.log('─'.repeat(50));

    Array.from(allFields).sort().forEach((field, index) => {
      console.log(`${(index + 1).toString().padStart(2)}. ${field}`);
    });

    console.log('\n' + '─'.repeat(50));

    // Expected fields
    const expectedFields = [
      'Name', 'Description', 'Date', 'Price', 'Status',
      'Studio', 'Category', 'Location',
      'Slug', 'Featured', 'Image_URL', 'Skill_Level',
      'Duration_Minutes', 'Spots_Remaining', 'Full_Address', 'Booking_Link',
      'Instagram_Post_URL'
    ];

    console.log('\n📊 Field Status:');
    console.log('─'.repeat(50));

    const missingFields = expectedFields.filter(f => !allFields.has(f));

    if (missingFields.length === 0) {
      console.log('✅ All expected fields present!');
    } else {
      console.log(`⚠️  Missing ${missingFields.length} fields:\n`);
      missingFields.forEach(field => {
        console.log(`   ❌ ${field}`);
      });
    }

    console.log('\n');
  })
  .catch(error => {
    console.error('❌ Connection failed:', error.message);
  });
