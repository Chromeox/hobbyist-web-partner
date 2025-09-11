/**
 * Fix UUID Issue in Google Sheets Web App
 * This replaces the UUID generation with proper event names
 */

// ============= WEB APP ENDPOINT (Fixed) =============

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    
    // Get the spreadsheet
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName('Events Staging');
    
    if (!sheet) {
      return ContentService
        .createTextOutput(JSON.stringify({
          success: false,
          error: 'Events Staging sheet not found'
        }))
        .setMimeType(ContentService.MimeType.JSON);
    }
    
    // Prepare row data - USE THE NAME FROM THE SCRAPER
    const row = [
      data.name || 'Untitled Event',  // ← Use actual name, not UUID!
      data.slug || generateSlug(data.name),  // Generate slug from name
      data.studio || '',
      data.location || data.venue || '',
      data.address || '',
      data.date || '',
      data.time || '',
      data.price || '',
      data.description || '',
      data.image_url || '',
      data.booking_url || data.website_url || '',
      data.tags || '',
      'Draft',  // Webflow status
      'No',     // Sync to webflow
      data.dynamic_label || '',
      data.original_caption || '',
      data.instagram_url || '',
      data.source || 'Instagram',
      data.additional_images || '',
      data.attachment_summary || '',
      '',  // Rewrite Status (empty for new events)
      data.confidence_score || '',
      data.indicators_found || '',
      new Date()  // Timestamp
    ];
    
    // Append to sheet
    sheet.appendRow(row);
    
    // Log for debugging
    console.log('Added event:', data.name || 'No name provided');
    
    return ContentService
      .createTextOutput(JSON.stringify({
        success: true,
        message: 'Event added successfully',
        name: data.name
      }))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    console.error('Error in doPost:', error);
    
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        error: error.toString()
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Generate URL-friendly slug from event name
 */
function generateSlug(name) {
  if (!name) return '';
  
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

/**
 * Test function to check current data
 */
function checkEventNames() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const nameCol = headers.indexOf('name');
  
  console.log('Checking event names in column', nameCol);
  
  // Check first 10 rows
  for (let i = 1; i < Math.min(11, data.length); i++) {
    const name = data[i][nameCol];
    console.log(`Row ${i + 1}: ${name}`);
    
    // Check if it's a UUID
    if (name && name.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
      console.log('  ^ This is a UUID! Should be replaced with actual event name');
    }
  }
}

/**
 * Fix existing UUID entries
 */
function fixExistingUUIDs() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  const nameCol = headers.indexOf('name');
  const studioCol = headers.indexOf('studio');
  const captionCol = headers.indexOf('original caption');
  
  let fixed = 0;
  
  for (let i = 1; i < data.length; i++) {
    const name = data[i][nameCol];
    
    // Check if it's a UUID
    if (name && name.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
      // Try to generate a better name
      const studio = data[i][studioCol];
      const caption = data[i][captionCol];
      
      let newName = 'Event';
      
      // Try to extract from caption or use studio name
      if (studio) {
        if (studio.toLowerCase().includes('rumble')) {
          newName = 'Boxing Class';
        } else if (studio.toLowerCase().includes('claymates')) {
          newName = 'Pottery Workshop';
        } else if (studio.toLowerCase().includes('f45')) {
          newName = 'Fitness Training';
        } else {
          newName = `Event at ${studio}`;
        }
      }
      
      // Update the name
      sheet.getRange(i + 1, nameCol + 1).setValue(newName);
      fixed++;
      
      console.log(`Fixed row ${i + 1}: ${name} → ${newName}`);
    }
  }
  
  if (fixed > 0) {
    SpreadsheetApp.getUi().alert(`Fixed ${fixed} UUID entries with proper event names`);
  } else {
    SpreadsheetApp.getUi().alert('No UUID entries found to fix');
  }
}

// Add menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔧 Fix UUIDs')
    .addItem('📊 Check Event Names', 'checkEventNames')
    .addItem('🔄 Fix UUID Names', 'fixExistingUUIDs')
    .addToUi();
}