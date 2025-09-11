/**
 * SAFE VERSION - Fix UUID Issue with Type Checking
 * This version handles undefined/null values properly
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
  let errors = 0;
  
  for (let i = 1; i < data.length; i++) {
    try {
      const name = data[i][nameCol];
      
      // Check if it's a UUID
      if (name && typeof name === 'string' && 
          name.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
        
        // Get studio value safely
        const studio = data[i][studioCol];
        const studioStr = studio ? String(studio) : '';  // Convert to string safely
        const caption = data[i][captionCol] ? String(data[i][captionCol]) : '';
        
        let newName = 'Event';
        
        // Generate name based on studio (with safe string checking)
        if (studioStr) {
          const studioLower = studioStr.toLowerCase();
          
          if (studioLower.includes('rumble') || studioLower.includes('boxing')) {
            newName = 'Boxing Class';
          } else if (studioLower.includes('claymates') || studioLower.includes('pottery')) {
            newName = 'Pottery Workshop';
          } else if (studioLower.includes('f45') || studioLower.includes('fitness')) {
            newName = 'Fitness Training';
          } else if (studioLower.includes('yoga')) {
            newName = 'Yoga Class';
          } else if (studioLower.includes('dance')) {
            newName = 'Dance Class';
          } else {
            // Use studio name if available
            newName = `Event at ${studioStr}`;
          }
        } else if (caption) {
          // Try to extract from caption if no studio
          const captionLower = caption.toLowerCase();
          
          if (captionLower.includes('boxing')) {
            newName = 'Boxing Class';
          } else if (captionLower.includes('pottery') || captionLower.includes('ceramic')) {
            newName = 'Pottery Workshop';
          } else if (captionLower.includes('yoga')) {
            newName = 'Yoga Class';
          } else if (captionLower.includes('workout') || captionLower.includes('fitness')) {
            newName = 'Fitness Class';
          } else if (captionLower.includes('workshop')) {
            newName = 'Workshop';
          } else if (captionLower.includes('class')) {
            newName = 'Class';
          }
        }
        
        // Update the name
        sheet.getRange(i + 1, nameCol + 1).setValue(newName);
        fixed++;
        
        console.log(`Fixed row ${i + 1}: ${name} → ${newName}`);
      }
    } catch (error) {
      console.error(`Error on row ${i + 1}:`, error);
      errors++;
    }
  }
  
  const message = `Fixed ${fixed} UUID entries with proper event names.${errors > 0 ? ` (${errors} errors encountered)` : ''}`;
  SpreadsheetApp.getUi().alert(message);
  console.log(message);
}

/**
 * Also fix the doPost function to prevent future UUIDs
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    
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
    
    // Ensure we have a proper name (not UUID)
    let eventName = data.name || 'Event';
    
    // Check if name looks like a UUID and replace it
    if (eventName.match(/^[0-9a-f]{8}-[0-9a-f]{4}-/i)) {
      // Generate name from studio or use default
      const studio = String(data.studio || data.location || '');
      
      if (studio.toLowerCase().includes('rumble')) {
        eventName = 'Boxing Class';
      } else if (studio.toLowerCase().includes('claymates')) {
        eventName = 'Pottery Workshop';
      } else if (studio.toLowerCase().includes('f45')) {
        eventName = 'Fitness Training';
      } else {
        eventName = 'Workshop Event';
      }
    }
    
    // Prepare row data
    const row = [
      eventName,  // Use the cleaned name
      generateSlug(eventName),
      data.studio || '',
      data.location || data.venue || '',
      data.address || '',
      data.date || data.Event_Date || '',
      data.time || data.Time || '',
      data.price || '',
      data.description || '',
      data.image_url || data.Image_URL || '',
      data.booking_url || data.Book_Link || '',
      data.tags || data.Tags || '',
      'Draft',
      'No',
      data.dynamic_label || '',
      data.original_caption || '',
      data.instagram_url || data.instagram_URL || '',
      data.source || data.Source || 'Instagram',
      '',
      '',
      '',  // Rewrite Status
      data.confidence_score || '',
      data.indicators_found || '',
      new Date()
    ];
    
    sheet.appendRow(row);
    
    console.log('Added event:', eventName);
    
    return ContentService
      .createTextOutput(JSON.stringify({
        success: true,
        message: 'Event added successfully',
        name: eventName
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

function generateSlug(name) {
  if (!name || typeof name !== 'string') return 'event';
  
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔧 Fix UUIDs')
    .addItem('🔄 Fix UUID Names (Safe)', 'fixExistingUUIDs')
    .addToUi();
}