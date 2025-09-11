/**
 * Update Google Sheets Headers to Match Airtable
 * Run this in your Apps Script to update the headers
 */

function updateHeadersToMatchAirtable() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName('Events Staging');
  
  // Your Airtable field names exactly
  const airtableHeaders = [
    'name',                  // Event name
    'slug',                  // URL slug (we'll auto-generate)
    'studio',                // Studio/Instructor name
    'location',              // Venue name
    'address',               // Full address
    'Event Date',            // Date of event
    'Time',                  // Time of event
    'price',                 // Price
    'Description',           // Main description (rewritten)
    'Image URL',             // Main image
    'Book Link',             // Booking URL
    'Tags',                  // Categories/tags
    'Webflow status',        // Publishing status
    'Sync to webflow',       // Yes/No flag
    'dynamic label',         // Auto-generated label
    'original caption',      // Original description from scraping
    'instagram URL',         // Link to Instagram post
    'Source',                // Where it came from (Instagram/Website)
    'Event Images',          // Additional images (comma-separated URLs)
    'attachment summary',    // Summary of attachments
    // Add helper columns for our workflow
    'Scraped At',            // When we scraped it
    'Review Status',         // Our internal review status
    'Quality Score',         // Auto-calculated quality
    'Review Notes'           // Manual review notes
  ];
  
  // Clear existing headers
  sheet.getRange(1, 1, 1, sheet.getMaxColumns()).clear();
  
  // Set new headers
  sheet.getRange(1, 1, 1, airtableHeaders.length).setValues([airtableHeaders]);
  
  // Format headers
  const headerRange = sheet.getRange(1, 1, 1, airtableHeaders.length);
  headerRange.setBackground('#4285F4');
  headerRange.setFontColor('#FFFFFF');
  headerRange.setFontWeight('bold');
  headerRange.setWrap(true);
  
  // Set column widths for better visibility
  sheet.setColumnWidth(1, 200);  // name
  sheet.setColumnWidth(2, 150);  // slug
  sheet.setColumnWidth(3, 150);  // studio
  sheet.setColumnWidth(4, 150);  // location
  sheet.setColumnWidth(5, 200);  // address
  sheet.setColumnWidth(9, 300);  // Description
  sheet.setColumnWidth(16, 300); // original caption
  
  // Add data validation for status columns
  const webflowStatusRange = sheet.getRange(2, 13, 999, 1); // Column M
  const webflowStatusRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Draft', 'Published', 'Archived'])
    .setAllowInvalid(false)
    .build();
  webflowStatusRange.setDataValidation(webflowStatusRule);
  
  const syncRange = sheet.getRange(2, 14, 999, 1); // Column N
  const syncRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Yes', 'No'])
    .setAllowInvalid(false)
    .build();
  syncRange.setDataValidation(syncRule);
  
  const reviewStatusRange = sheet.getRange(2, 23, 999, 1); // Column W
  const reviewRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Scraped', 'Pending Review', 'Approved', 'Rejected'])
    .setAllowInvalid(false)
    .build();
  reviewStatusRange.setDataValidation(reviewRule);
  
  SpreadsheetApp.getUi().alert('✅ Headers updated to match Airtable!');
}

// Helper function to generate slug from name
function generateSlug(name) {
  if (!name) return '';
  return name.toLowerCase()
    .replace(/[^\w\s-]/g, '')  // Remove special characters
    .replace(/\s+/g, '-')       // Replace spaces with hyphens
    .replace(/-+/g, '-')        // Remove duplicate hyphens
    .trim();
}

// Updated function to add data with proper field mapping
function addEventWithAirtableFields(eventData) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  const lastRow = sheet.getLastRow();
  
  // Map incoming data to Airtable fields
  const row = [
    eventData.name || '',
    generateSlug(eventData.name),  // Auto-generate slug
    eventData.studio || eventData.instructor || '',
    eventData.venue || eventData.location || '',
    eventData.address || '',
    eventData.date || '',
    eventData.time || '',
    eventData.price || '',
    eventData.description_rewritten || eventData.description || '',
    eventData.image_url || '',
    eventData.booking_url || '',
    eventData.tags || eventData.category || '',
    'Draft',  // Default Webflow status
    'No',     // Default don't sync yet
    '',       // dynamic label (auto-generated)
    eventData.original_caption || eventData.description_original || '',
    eventData.instagram_url || '',
    eventData.source || 'Instagram',
    eventData.event_images || '',
    '',  // attachment summary
    new Date().toISOString(),  // Scraped At
    'Scraped',  // Review Status
    calculateQualityScore(eventData),  // Quality Score
    ''   // Review Notes
  ];
  
  sheet.getRange(lastRow + 1, 1, 1, row.length).setValues([row]);
  
  return lastRow + 1;
}

// Calculate quality score based on data completeness
function calculateQualityScore(data) {
  let score = 0;
  
  if (data.name) score += 20;
  if (data.date || data.Event_Date) score += 15;
  if (data.venue || data.location) score += 15;
  if (data.description || data.description_rewritten) score += 20;
  if (data.image_url) score += 10;
  if (data.price) score += 10;
  if (data.booking_url) score += 10;
  
  return score;
}

// Updated CSV export function for Airtable import
function exportForAirtable() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName('Events Staging');
  
  // Get only approved events
  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];
  const approvedData = allData.filter((row, index) => {
    return index > 0 && row[22] === 'Approved'; // Review Status column
  });
  
  if (approvedData.length === 0) {
    SpreadsheetApp.getUi().alert('No approved events to export');
    return;
  }
  
  // Only export the columns that Airtable needs (first 20 columns)
  const airtableData = approvedData.map(row => row.slice(0, 20));
  
  // Update sync flag for exported events
  approvedData.forEach(row => {
    row[13] = 'Yes'; // Set "Sync to webflow" to Yes
    row[12] = 'Published'; // Set "Webflow status" to Published
  });
  
  // Create CSV content
  const csvContent = [
    headers.slice(0, 20).join(','),  // Airtable columns only
    ...airtableData.map(row => 
      row.map(cell => {
        // Escape quotes and wrap in quotes if contains comma
        const value = String(cell).replace(/"/g, '""');
        return value.includes(',') ? `"${value}"` : value;
      }).join(',')
    )
  ].join('\n');
  
  // Save to Drive
  const timestamp = new Date().toISOString().split('T')[0];
  const blob = Utilities.newBlob(csvContent, 'text/csv', `airtable_import_${timestamp}.csv`);
  const file = DriveApp.createFile(blob);
  
  // Show success message with download link
  const html = `
    <div>
      <h3>✅ Export Complete!</h3>
      <p>${approvedData.length} events exported for Airtable</p>
      <p><a href="${file.getUrl()}" target="_blank">Download CSV File</a></p>
      <ol>
        <li>Download the CSV file</li>
        <li>Go to your Airtable base</li>
        <li>Click "Add records" → "Import CSV"</li>
        <li>Upload the file</li>
        <li>Map fields (should auto-match)</li>
        <li>Click "Import"</li>
      </ol>
    </div>
  `;
  
  const htmlOutput = HtmlService.createHtmlOutput(html)
    .setWidth(400)
    .setHeight(300);
  
  SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Export for Airtable');
  
  return file.getUrl();
}

// Update the menu to include new export function
function updateMenu() {
  const ui = SpreadsheetApp.getUi();
  
  ui.createMenu('🎯 Hobby Directory')
    .addItem('📥 Import Instagram Data', 'importInstagramData')
    .addItem('🌐 Scrape Websites', 'scrapeWebsites')
    .addItem('🤖 Rewrite Descriptions', 'rewriteDescriptions')
    .addItem('📧 Send Review Email', 'sendReviewEmail')
    .addItem('✅ Approve Selected', 'approveSelected')
    .addSeparator()
    .addItem('📤 Export for Airtable', 'exportForAirtable')
    .addItem('🔄 Run Full Pipeline', 'runFullPipeline')
    .addSeparator()
    .addItem('🔧 Update Headers', 'updateHeadersToMatchAirtable')
    .addItem('⚙️ Settings', 'showSettings')
    .addToUi();
}

// Run this to update everything
function applyAirtableUpdates() {
  updateHeadersToMatchAirtable();
  updateMenu();
  SpreadsheetApp.getUi().alert('✅ Sheet updated for Airtable compatibility!');
}