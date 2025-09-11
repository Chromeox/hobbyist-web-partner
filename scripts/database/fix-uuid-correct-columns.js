/**
 * Fix UUID with CORRECT Column Detection
 * This version finds the right columns regardless of order
 */

function fixUUIDsWithCorrectColumns() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  // Log headers to see what we have
  console.log('Headers found:', headers);
  
  // Find columns by multiple possible names
  function findColumn(possibleNames) {
    for (const name of possibleNames) {
      const index = headers.indexOf(name);
      if (index !== -1) {
        console.log(`Found column "${name}" at index ${index}`);
        return index;
      }
    }
    console.log(`Could not find columns: ${possibleNames.join(', ')}`);
    return -1;
  }
  
  // Look for columns with various possible names
  const nameCol = findColumn(['name', 'Name', 'Event Name']);
  const studioCol = findColumn(['studio', 'Studio', 'Organization']);
  const locationCol = findColumn(['location', 'Location', 'Venue', 'venue']);
  const captionCol = findColumn(['original caption', 'Original Caption', 'Caption', 'original_caption']);
  const dateCol = findColumn(['Event Date', 'Date', 'date', 'event_date']);
  
  console.log('Column indices:', {
    name: nameCol,
    studio: studioCol,
    location: locationCol,
    caption: captionCol,
    date: dateCol
  });
  
  if (nameCol === -1) {
    SpreadsheetApp.getUi().alert('Cannot find name column!');
    return;
  }
  
  let fixed = 0;
  let skipped = 0;
  
  // Check each row
  for (let i = 1; i < data.length; i++) {
    const currentName = data[i][nameCol];
    
    console.log(`Row ${i + 1} - Current name: "${currentName}"`);
    
    // Check if it needs fixing (UUID or date-like string)
    if (currentName && (
        currentName.toString().match(/^[0-9a-f]{8}-[0-9a-f]{4}-/i) ||  // UUID
        currentName.toString().includes('GMT') ||  // Date string
        currentName.toString().match(/^\w{3} \w{3} \d{2} \d{4}/)  // Date format
    )) {
      
      let newName = 'Event';
      
      // Try to get a better name from studio or location
      if (studioCol !== -1 && data[i][studioCol]) {
        const studio = String(data[i][studioCol]);
        console.log(`  Studio: "${studio}"`);
        
        // Don't use if studio is also a date
        if (!studio.includes('GMT') && !studio.match(/\d{4}/)) {
          const studioLower = studio.toLowerCase();
          
          if (studioLower.includes('rumble') || studioLower.includes('boxing')) {
            newName = 'Boxing Class';
          } else if (studioLower.includes('claymates') || studioLower.includes('pottery')) {
            newName = 'Pottery Workshop';
          } else if (studioLower.includes('f45') || studioLower.includes('fitness')) {
            newName = 'Fitness Training';
          } else if (studioLower.includes('yoga')) {
            newName = 'Yoga Class';
          } else if (studio.length > 2 && studio.length < 50) {
            newName = `Workshop at ${studio}`;
          }
        }
      }
      
      // If still generic, try location
      if (newName === 'Event' && locationCol !== -1 && data[i][locationCol]) {
        const location = String(data[i][locationCol]);
        console.log(`  Location: "${location}"`);
        
        if (!location.includes('GMT') && !location.match(/\d{4}/)) {
          const locationLower = location.toLowerCase();
          
          if (locationLower.includes('rumble')) {
            newName = 'Boxing Class';
          } else if (locationLower.includes('claymates')) {
            newName = 'Pottery Workshop';
          } else if (location.length > 2 && location.length < 50) {
            newName = `Event at ${location}`;
          }
        }
      }
      
      // Last resort: check caption for clues
      if (newName === 'Event' && captionCol !== -1 && data[i][captionCol]) {
        const caption = String(data[i][captionCol]).toLowerCase();
        
        if (caption.includes('boxing') || caption.includes('rumble')) {
          newName = 'Boxing Class';
        } else if (caption.includes('pottery') || caption.includes('clay')) {
          newName = 'Pottery Workshop';
        } else if (caption.includes('yoga')) {
          newName = 'Yoga Class';
        } else if (caption.includes('fitness') || caption.includes('workout')) {
          newName = 'Fitness Class';
        } else if (caption.includes('workshop')) {
          newName = 'Workshop';
        } else if (caption.includes('class')) {
          newName = 'Class';
        }
      }
      
      // Add date if we have it
      if (dateCol !== -1 && data[i][dateCol]) {
        const eventDate = data[i][dateCol];
        if (eventDate && !eventDate.toString().includes('GMT')) {
          // Date looks normal, keep the event name simple
        } else {
          // Date might be wrong too
          console.log(`  Warning: Date column has unexpected value: ${eventDate}`);
        }
      }
      
      console.log(`  Fixing: "${currentName}" → "${newName}"`);
      
      // Update the sheet
      sheet.getRange(i + 1, nameCol + 1).setValue(newName);
      fixed++;
      
    } else if (currentName) {
      console.log(`  Skipping - already has good name: "${currentName}"`);
      skipped++;
    }
  }
  
  const message = `
Fixed ${fixed} entries
Skipped ${skipped} entries (already had good names)

Check your sheet - names should now be like:
• Boxing Class
• Pottery Workshop
• Workshop
• Event

Instead of UUIDs or dates.`;
  
  SpreadsheetApp.getUi().alert('Fix Complete', message, SpreadsheetApp.getUi().ButtonSet.OK);
}

/**
 * Debug function to show what's in each column
 */
function debugColumns() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  console.log('=== COLUMN DEBUG ===');
  console.log('Headers:', headers);
  
  // Show first row of data
  if (data.length > 1) {
    console.log('\nFirst data row:');
    headers.forEach((header, index) => {
      const value = data[1][index];
      console.log(`Column ${index}: "${header}" = "${value}"`);
    });
  }
  
  // Show which columns contain what type of data
  if (data.length > 2) {
    console.log('\nSecond data row:');
    headers.forEach((header, index) => {
      const value = data[2][index];
      console.log(`Column ${index}: "${header}" = "${value}"`);
    });
  }
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔧 Fix Names')
    .addItem('🔄 Fix Names (Smart Detection)', 'fixUUIDsWithCorrectColumns')
    .addItem('🔍 Debug Columns', 'debugColumns')
    .addToUi();
}