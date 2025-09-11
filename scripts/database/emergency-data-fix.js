/**
 * Emergency Fix for Scrambled Data
 * This fixes rows where dates ended up in name/studio columns
 */

function emergencyDataFix() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  // Find columns
  const nameCol = headers.indexOf('name');
  const studioCol = headers.indexOf('studio');
  const locationCol = headers.indexOf('location');
  const captionCol = headers.indexOf('original caption');
  
  let fixed = 0;
  
  for (let i = 1; i < data.length; i++) {
    const currentName = String(data[i][nameCol] || '');
    const caption = String(data[i][captionCol] || '').toLowerCase();
    
    // Check if name contains a date (wrong data)
    if (currentName.includes('GMT') || currentName.includes('Event at')) {
      let newName = 'Workshop';
      let newStudio = '';
      let newLocation = '';
      
      // Determine event type from caption
      if (caption.includes('boxing') || caption.includes('rumble')) {
        newName = 'Boxing Class';
        newStudio = 'Rumble Boxing';
        newLocation = 'Rumble Boxing Mount Pleasant';
      } else if (caption.includes('pottery') || caption.includes('clay') || caption.includes('ceramic')) {
        newName = 'Pottery Workshop';
        newStudio = 'Claymates Studio';
        newLocation = 'Claymates Ceramic Studio';
      } else if (caption.includes('yoga')) {
        newName = 'Yoga Class';
        newStudio = 'Yoga Studio';
        newLocation = 'Vancouver';
      } else if (caption.includes('fitness') || caption.includes('workout')) {
        newName = 'Fitness Class';
        newStudio = 'Fitness Studio';
        newLocation = 'Vancouver';
      } else if (caption.includes('art')) {
        newName = 'Art Workshop';
        newStudio = 'Art Studio';
        newLocation = 'Vancouver';
      } else if (caption.includes('kids')) {
        newName = 'Kids Workshop';
        newStudio = 'Studio';
        newLocation = 'Vancouver';
      }
      
      // Update the cells
      sheet.getRange(i + 1, nameCol + 1).setValue(newName);
      
      // Only update studio/location if they also have bad data
      if (String(data[i][studioCol] || '').includes('GMT')) {
        sheet.getRange(i + 1, studioCol + 1).setValue(newStudio);
      }
      if (String(data[i][locationCol] || '').includes('GMT')) {
        sheet.getRange(i + 1, locationCol + 1).setValue(newLocation);
      }
      
      fixed++;
      console.log(`Fixed row ${i + 1}: ${currentName} → ${newName} (${newStudio})`);
    }
  }
  
  console.log(`Fixed ${fixed} rows with scrambled data`);
  return `Fixed ${fixed} rows`;
}

/**
 * Fix the Web App to prevent future scrambling
 */
function doPost(e) {
  try {
    const rawData = e.postData.contents;
    console.log('Received data:', rawData.substring(0, 500));
    
    const data = JSON.parse(rawData);
    
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName('Events Staging');
    
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: 'Events Staging sheet not found'
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    // FIX: Map the data correctly!
    // The scraper sends: { name, studio, location, date, time, price, ... }
    // We need to put them in the RIGHT columns
    
    let eventName = data.name || 'Workshop';
    
    // Validate that name isn't a date
    if (eventName.includes('GMT') || eventName.match(/\d{4}/)) {
      // Name is corrupted, generate from caption
      const caption = (data.original_caption || '').toLowerCase();
      
      if (caption.includes('boxing')) {
        eventName = 'Boxing Class';
      } else if (caption.includes('pottery')) {
        eventName = 'Pottery Workshop';
      } else {
        eventName = 'Workshop';
      }
    }
    
    // Build row with CORRECT field mapping
    const row = [
      eventName,                                    // name (column 0)
      generateSlug(eventName),                      // slug (column 1)
      data.studio || data.defaultStudio || '',      // studio (column 2)
      data.location || data.venue || '',            // location (column 3)
      data.address || '',                           // address (column 4)
      data.date || data.Event_Date || '',           // Event Date (column 5)
      data.time || data.Time || '',                 // Time (column 6)
      data.price || '',                             // price (column 7)
      data.description || '',                       // Description (column 8)
      data.image_url || data.imageUrl || '',        // Image URL (column 9)
      data.booking_url || data.bookingUrl || '',    // Book Link (column 10)
      data.tags || '',                              // Tags (column 11)
      'Draft',                                       // Webflow status (column 12)
      'No',                                          // Sync to webflow (column 13)
      '',                                            // dynamic label (column 14)
      data.original_caption || '',                  // original caption (column 15)
      data.instagram_url || '',                     // instagram URL (column 16)
      data.source || 'Instagram',                   // Source (column 17)
      '',                                            // Event Images (column 18)
      '',                                            // attachment summary (column 19)
      new Date(),                                    // Scraped At (column 20)
      '',                                            // Review Status (column 21)
      '',                                            // Quality Score (column 22)
      '',                                            // Review Notes (column 23)
      ''                                             // Rewrite Status (column 24)
    ];
    
    sheet.appendRow(row);
    
    console.log(`Added event: ${eventName} from ${data.studio || 'Unknown'}`);
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Event added successfully',
      name: eventName
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    console.error('Error in doPost:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function generateSlug(name) {
  if (!name) return '';
  return String(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🚨 Emergency Fix')
    .addItem('🔧 Fix Scrambled Data', 'emergencyDataFix')
    .addToUi();
}