/**
 * Fresh Sheet Setup - Ensures Perfect Airtable Alignment
 * Run this ONCE on your empty sheet to set up everything correctly
 */

function setupFreshSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName('Events Staging') || ss.getActiveSheet();
  
  // Clear everything first
  sheet.clear();
  
  // Set up correct headers matching Airtable exactly
  const headers = [
    'name',              // Event name
    'slug',              // URL slug
    'studio',            // Organization name
    'location',          // Venue name
    'address',           // Full address
    'Event Date',        // YYYY-MM-DD format
    'Time',              // HH:MM AM/PM format
    'price',             // With "$"
    'Description',       // AI rewritten
    'Image URL',         // Main image
    'Book Link',         // Registration URL
    'Tags',              // Comma-separated
    'Webflow status',    // Published/Draft
    'Sync to webflow',   // Yes/No
    'dynamic label',     // New/This Week/etc
    'original caption',  // Instagram caption
    'instagram URL',     // Post link
    'Source',            // Instagram/Manual
    'Event Images',      // Additional images
    'attachment summary',// Attachment info
    'confidence_score',  // 0-1 decimal
    'indicators_found',  // Detection indicators
    'Scraped At',        // Timestamp
    'Rewrite Status',    // Completed/Pending
    'Quality Score'      // 0-100
  ];
  
  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setValues([headers]);
  
  // Format header row
  headerRange.setBackground('#4285f4');
  headerRange.setFontColor('#ffffff');
  headerRange.setFontWeight('bold');
  headerRange.setFontSize(11);
  
  // Set column widths for readability
  sheet.setColumnWidth(1, 200);  // name
  sheet.setColumnWidth(2, 150);  // slug
  sheet.setColumnWidth(3, 150);  // studio
  sheet.setColumnWidth(4, 200);  // location
  sheet.setColumnWidth(5, 250);  // address
  sheet.setColumnWidth(6, 100);  // Event Date
  sheet.setColumnWidth(7, 80);   // Time
  sheet.setColumnWidth(8, 70);   // price
  sheet.setColumnWidth(9, 300);  // Description
  sheet.setColumnWidth(10, 200); // Image URL
  sheet.setColumnWidth(11, 200); // Book Link
  sheet.setColumnWidth(12, 150); // Tags
  sheet.setColumnWidth(16, 400); // original caption
  
  // Freeze header row
  sheet.setFrozenRows(1);
  
  // Create data validation for specific columns
  const validation = SpreadsheetApp.newDataValidation();
  
  // Webflow status dropdown
  const statusValidation = validation.requireValueInList(['Draft', 'Published'], true).build();
  sheet.getRange('M2:M1000').setDataValidation(statusValidation);
  
  // Sync to webflow dropdown
  const syncValidation = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Yes', 'No'], true).build();
  sheet.getRange('N2:N1000').setDataValidation(syncValidation);
  
  // Source dropdown
  const sourceValidation = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Instagram', 'Manual', 'Website', 'Facebook'], true).build();
  sheet.getRange('R2:R1000').setDataValidation(sourceValidation);
  
  // Rewrite Status dropdown
  const rewriteValidation = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Pending', 'Completed', 'Error', 'Skipped'], true).build();
  sheet.getRange('X2:X1000').setDataValidation(rewriteValidation);
  
  // Add conditional formatting for confidence scores
  const confidenceRange = sheet.getRange('U2:U1000');
  const rules = [];
  
  // Green for high confidence (>= 0.7)
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenNumberGreaterThanOrEqualTo(0.7)
    .setBackground('#b7e1cd')
    .setRanges([confidenceRange])
    .build());
  
  // Yellow for medium confidence (0.4 - 0.69)
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenNumberBetween(0.4, 0.69)
    .setBackground('#ffe599')
    .setRanges([confidenceRange])
    .build());
  
  // Red for low confidence (< 0.4)
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenNumberLessThan(0.4)
    .setBackground('#f4c7c3')
    .setRanges([confidenceRange])
    .build());
  
  sheet.setConditionalFormatRules(rules);
  
  console.log('✅ Fresh sheet setup complete!');
  
  SpreadsheetApp.getUi().alert(
    '✅ Sheet Setup Complete!',
    'Your Events Staging sheet is now perfectly configured:\n\n' +
    '• Headers match Airtable structure\n' +
    '• Columns are properly sized\n' +
    '• Validation dropdowns added\n' +
    '• Conditional formatting for confidence scores\n\n' +
    'Ready to receive data from your Instagram scraper!',
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

/**
 * Fixed Web App endpoint for receiving data
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName('Events Staging');
    
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: 'Events Staging sheet not found'
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    // Build row with proper field mapping
    const row = [
      data.name || 'Event',                         // name
      generateSlug(data.name),                      // slug
      data.studio || '',                            // studio
      data.location || data.venue || '',            // location
      data.address || '',                           // address
      formatDate(data.date),                        // Event Date
      formatTime(data.time),                        // Time
      formatPrice(data.price),                      // price (with $)
      data.description || '',                       // Description
      data.image_url || '',                         // Image URL
      data.booking_url || data.website_url || '',   // Book Link
      data.tags || '',                              // Tags
      'Draft',                                       // Webflow status
      'No',                                          // Sync to webflow
      data.dynamic_label || '',                     // dynamic label
      data.original_caption || '',                  // original caption
      data.instagram_url || '',                     // instagram URL
      data.source || 'Instagram',                   // Source
      data.event_images || '',                      // Event Images
      data.attachment_summary || '',                // attachment summary
      data.confidence_score || '',                  // confidence_score
      data.indicators_found || '',                  // indicators_found
      new Date(),                                   // Scraped At
      'Pending',                                     // Rewrite Status
      ''                                            // Quality Score
    ];
    
    sheet.appendRow(row);
    
    console.log(`Added: ${data.name} from ${data.studio}`);
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Event added successfully',
      name: data.name
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    console.error('Error in doPost:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// Helper functions
function generateSlug(name) {
  if (!name) return '';
  return String(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

function formatDate(date) {
  if (!date) return '';
  if (String(date).match(/^\d{4}-\d{2}-\d{2}$/)) return date;
  
  try {
    const d = new Date(date);
    if (isNaN(d.getTime())) return '';
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  } catch {
    return '';
  }
}

function formatTime(time) {
  if (!time) return '';
  if (String(time).includes('AM') || String(time).includes('PM')) return time;
  
  try {
    const [hours, minutes] = String(time).split(':');
    const h = parseInt(hours);
    const ampm = h >= 12 ? 'PM' : 'AM';
    const displayHour = h % 12 || 12;
    return `${displayHour}:${minutes || '00'} ${ampm}`;
  } catch {
    return time;
  }
}

function formatPrice(price) {
  if (!price) return '';
  const priceStr = String(price);
  if (priceStr === '0' || priceStr.toLowerCase() === 'free') return 'Free';
  if (priceStr.includes('$')) return priceStr;
  return '$' + priceStr;
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🚀 Fresh Start')
    .addItem('📊 Setup Fresh Sheet', 'setupFreshSheet')
    .addToUi();
}