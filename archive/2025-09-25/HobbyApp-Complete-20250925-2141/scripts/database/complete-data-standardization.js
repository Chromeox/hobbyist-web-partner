/**
 * Complete Data Standardization for Google Sheets
 * Ensures all columns match Airtable requirements exactly
 */

// ============= AIRTABLE FIELD STRUCTURE =============
const AIRTABLE_COLUMNS = [
  'name',              // Event name (e.g., "Pottery Workshop")
  'slug',              // URL slug (e.g., "pottery-workshop")
  'studio',            // Organization name
  'location',          // Venue name
  'address',           // Full address with postal code
  'Event Date',        // Date in YYYY-MM-DD format
  'Time',              // Time in HH:MM AM/PM format
  'price',             // Price with "$" (e.g., "$75")
  'Description',       // Event description (AI rewritten)
  'Image URL',         // Main event image
  'Book Link',         // Registration/booking URL
  'Tags',              // Comma-separated tags
  'Webflow status',    // "Published" or "Draft"
  'Sync to webflow',   // "Yes" or "No"
  'dynamic label',     // "New", "This Week", etc.
  'original caption',  // Original Instagram caption
  'instagram URL',     // Link to Instagram post
  'Source',            // "Instagram", "Manual", etc.
  'Event Images',      // Additional images (comma-separated URLs)
  'attachment summary' // Summary of attachments
];

// ============= SETUP CORRECT HEADERS =============

function setupCorrectHeaders() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  // Clear existing headers and set correct ones
  const headerRange = sheet.getRange(1, 1, 1, AIRTABLE_COLUMNS.length);
  headerRange.setValues([AIRTABLE_COLUMNS]);
  
  // Format header row
  headerRange.setBackground('#4285f4');
  headerRange.setFontColor('#ffffff');
  headerRange.setFontWeight('bold');
  
  console.log('Headers updated to match Airtable structure');
}

// ============= FIX ALL DATA ISSUES =============

function fixAllDataIssues() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  // Find current column positions
  const cols = {};
  AIRTABLE_COLUMNS.forEach(colName => {
    cols[colName] = headers.indexOf(colName);
  });
  
  let fixedCount = 0;
  const fixedData = [];
  
  // Process each row (skip header)
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const fixedRow = [];
    
    // Build correctly ordered row
    AIRTABLE_COLUMNS.forEach((colName, index) => {
      let value = '';
      
      // Get current value if column exists
      if (cols[colName] !== -1) {
        value = row[cols[colName]] || '';
      }
      
      // Apply field-specific fixes
      value = fixFieldValue(colName, value, row, cols);
      
      fixedRow.push(value);
    });
    
    fixedData.push(fixedRow);
    
    // Check if we fixed anything
    if (JSON.stringify(row) !== JSON.stringify(fixedRow)) {
      fixedCount++;
    }
  }
  
  // Write all fixed data back
  if (fixedData.length > 0) {
    const dataRange = sheet.getRange(2, 1, fixedData.length, AIRTABLE_COLUMNS.length);
    dataRange.setValues(fixedData);
  }
  
  // Format columns
  formatColumns(sheet);
  
  const message = `Data Standardization Complete!\n\nFixed ${fixedCount} rows\nAll columns now match Airtable structure\nPrices formatted with "$"\nDates in YYYY-MM-DD format`;
  
  SpreadsheetApp.getUi().alert(message);
  console.log(message);
}

// ============= FIELD-SPECIFIC FIXES =============

function fixFieldValue(fieldName, value, fullRow, cols) {
  const strValue = String(value || '');
  
  switch(fieldName) {
    case 'name':
      // Fix if name contains date or UUID
      if (strValue.includes('GMT') || strValue.match(/^[0-9a-f]{8}-/)) {
        // Try to get from caption
        const caption = fullRow[cols['original caption']] || '';
        return generateEventName(caption);
      }
      return strValue || 'Workshop';
      
    case 'slug':
      // Generate slug from name
      const name = fullRow[cols['name']] || 'event';
      return generateSlug(name);
      
    case 'studio':
      // Fix if studio contains date
      if (strValue.includes('GMT')) {
        const caption = fullRow[cols['original caption']] || '';
        return detectStudio(caption);
      }
      return strValue;
      
    case 'location':
      // Fix if location contains date
      if (strValue.includes('GMT') || strValue.includes('1899')) {
        const studio = fullRow[cols['studio']] || '';
        return generateLocation(studio);
      }
      return strValue;
      
    case 'address':
      // Ensure proper address format
      if (strValue.includes('GMT') || !strValue) {
        const studio = fullRow[cols['studio']] || '';
        return generateAddress(studio);
      }
      return strValue;
      
    case 'Event Date':
      // Format date properly (YYYY-MM-DD)
      return formatDate(strValue);
      
    case 'Time':
      // Format time properly (HH:MM AM/PM)
      return formatTime(strValue);
      
    case 'price':
      // Add "$" if missing
      if (strValue && !strValue.includes('$')) {
        if (strValue === '0' || strValue.toLowerCase() === 'free') {
          return 'Free';
        }
        return '$' + strValue;
      }
      return strValue || '';
      
    case 'Tags':
      // Clean and format tags
      return cleanTags(strValue);
      
    case 'Webflow status':
      return strValue || 'Draft';
      
    case 'Sync to webflow':
      return strValue || 'No';
      
    case 'Source':
      return strValue || 'Instagram';
      
    default:
      return strValue;
  }
}

// ============= HELPER FUNCTIONS =============

function generateEventName(caption) {
  const captionLower = caption.toLowerCase();
  
  if (captionLower.includes('boxing') || captionLower.includes('rumble')) {
    return 'Boxing Class';
  } else if (captionLower.includes('pottery') || captionLower.includes('clay')) {
    return 'Pottery Workshop';
  } else if (captionLower.includes('yoga')) {
    return 'Yoga Class';
  } else if (captionLower.includes('fitness') || captionLower.includes('workout')) {
    return 'Fitness Class';
  } else if (captionLower.includes('dance')) {
    return 'Dance Class';
  } else if (captionLower.includes('art')) {
    return 'Art Workshop';
  } else if (captionLower.includes('cooking') || captionLower.includes('culinary')) {
    return 'Cooking Class';
  } else if (captionLower.includes('kids') || captionLower.includes('children')) {
    return 'Kids Workshop';
  } else if (captionLower.includes('workshop')) {
    return 'Workshop';
  } else if (captionLower.includes('class')) {
    return 'Class';
  }
  
  return 'Event';
}

function detectStudio(caption) {
  const captionLower = caption.toLowerCase();
  
  if (captionLower.includes('rumble')) return 'Rumble Boxing';
  if (captionLower.includes('claymates')) return 'Claymates Studio';
  if (captionLower.includes('f45')) return 'F45 Training';
  if (captionLower.includes('yyoga')) return 'YYoga';
  
  return 'Studio';
}

function generateLocation(studio) {
  const studioLower = studio.toLowerCase();
  
  if (studioLower.includes('rumble')) return 'Rumble Boxing Mount Pleasant';
  if (studioLower.includes('claymates')) return 'Claymates Ceramic Studio';
  if (studioLower.includes('f45')) return 'F45 Training Vancouver';
  
  return 'Vancouver, BC';
}

function generateAddress(studio) {
  const studioLower = studio.toLowerCase();
  
  if (studioLower.includes('rumble')) return '2935 Main St, Vancouver, BC V5T 3G5';
  if (studioLower.includes('claymates')) return '3071 Main St, Vancouver, BC V5V 3P1';
  
  return 'Vancouver, BC';
}

function formatDate(dateValue) {
  if (!dateValue) return '';
  
  // If already in correct format
  if (String(dateValue).match(/^\d{4}-\d{2}-\d{2}$/)) {
    return dateValue;
  }
  
  try {
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) return '';
    
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  } catch {
    return '';
  }
}

function formatTime(timeValue) {
  if (!timeValue) return '';
  
  // If already has AM/PM
  if (String(timeValue).match(/\d{1,2}:\d{2}\s*(AM|PM)/i)) {
    return timeValue;
  }
  
  try {
    const time = new Date(timeValue);
    if (isNaN(time.getTime())) return timeValue;
    
    let hours = time.getHours();
    const minutes = time.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    
    hours = hours % 12 || 12;
    
    return `${hours}:${minutes} ${ampm}`;
  } catch {
    return timeValue;
  }
}

function cleanTags(tags) {
  if (!tags) return '';
  
  return String(tags)
    .split(',')
    .map(tag => tag.trim().toLowerCase())
    .filter(tag => tag.length > 0)
    .join(', ');
}

function generateSlug(name) {
  return String(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

// ============= FORMAT COLUMNS =============

function formatColumns(sheet) {
  // Set column widths
  sheet.setColumnWidth(1, 200);  // name
  sheet.setColumnWidth(2, 150);  // slug
  sheet.setColumnWidth(3, 150);  // studio
  sheet.setColumnWidth(4, 200);  // location
  sheet.setColumnWidth(5, 250);  // address
  sheet.setColumnWidth(6, 100);  // Event Date
  sheet.setColumnWidth(7, 80);   // Time
  sheet.setColumnWidth(8, 60);   // price
  sheet.setColumnWidth(9, 300);  // Description
  sheet.setColumnWidth(16, 400); // original caption
  
  // Format price column
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    const priceRange = sheet.getRange(2, 8, lastRow - 1, 1);
    priceRange.setNumberFormat('$#,##0');
  }
}

// ============= VALIDATION CHECK =============

function validateData() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const issues = [];
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const rowNum = i + 1;
    
    // Check for common issues
    if (!row[0] || String(row[0]).includes('GMT')) {
      issues.push(`Row ${rowNum}: Invalid name`);
    }
    if (row[5] && !String(row[5]).match(/^\d{4}-\d{2}-\d{2}$/)) {
      issues.push(`Row ${rowNum}: Date not in YYYY-MM-DD format`);
    }
    if (row[7] && !String(row[7]).includes('$') && row[7] !== 'Free') {
      issues.push(`Row ${rowNum}: Price missing "$"`);
    }
  }
  
  if (issues.length > 0) {
    console.log('Validation issues found:');
    issues.forEach(issue => console.log(issue));
  } else {
    console.log('✅ All data validated successfully!');
  }
  
  return issues;
}

// ============= MENU =============

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('📊 Standardize Data')
    .addItem('🔧 Fix All Data Issues', 'fixAllDataIssues')
    .addItem('📋 Setup Correct Headers', 'setupCorrectHeaders')
    .addItem('✅ Validate Data', 'validateData')
    .addToUi();
}