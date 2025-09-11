/**
 * CRITICAL FIX - Replace your ENTIRE doPost function with this
 * This ensures data goes to the RIGHT columns
 */

function doPost(e) {
  try {
    // Parse incoming data
    const data = JSON.parse(e.postData.contents);
    
    // Log what we received for debugging
    console.log('Received event:', data.name, 'from', data.studio);
    
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName('Events Staging');
    
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: 'Events Staging sheet not found'
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    // CRITICAL: Build row in EXACT column order
    // The scraper is sending correct data, we just need to put it in right columns
    const row = [];
    
    // Column A: name (NOT a UUID!)
    row.push(data.name || 'Event');
    
    // Column B: slug
    row.push(generateSlug(data.name || 'event'));
    
    // Column C: studio
    row.push(data.studio || '');
    
    // Column D: location
    row.push(data.location || data.venue || '');
    
    // Column E: address (THIS IS THE ADDRESS, not date!)
    row.push(data.address || '');
    
    // Column F: Event Date (THIS IS THE DATE, not address!)
    row.push(formatDateProperly(data.date || data.Event_Date || ''));
    
    // Column G: Time
    row.push(formatTimeProperly(data.time || data.Time || ''));
    
    // Column H: price (with $)
    row.push(formatPriceProperly(data.price || ''));
    
    // Column I: Description
    row.push(data.description || '');
    
    // Column J: Image URL
    row.push(data.image_url || data.imageUrl || '');
    
    // Column K: Book Link
    row.push(data.booking_url || data.bookingUrl || data.website_url || '');
    
    // Column L: Tags
    row.push(data.tags || '');
    
    // Column M: Webflow status
    row.push('Draft');
    
    // Column N: Sync to webflow
    row.push('No');
    
    // Column O: dynamic label
    row.push(data.dynamic_label || '');
    
    // Column P: original caption
    row.push(data.original_caption || '');
    
    // Column Q: instagram URL
    row.push(data.instagram_url || '');
    
    // Column R: Source
    row.push(data.source || 'Instagram');
    
    // Column S: Event Images
    row.push(data.event_images || '');
    
    // Column T: attachment summary
    row.push(data.attachment_summary || '');
    
    // Column U: confidence_score
    row.push(data.confidence_score || '');
    
    // Column V: indicators_found
    row.push(data.indicators_found || '');
    
    // Column W: Scraped At
    row.push(new Date());
    
    // Column X: Rewrite Status
    row.push('Pending');
    
    // Column Y: Quality Score
    row.push('');
    
    // Append the properly ordered row
    sheet.appendRow(row);
    
    console.log('Successfully added:', data.name);
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Event added with correct column mapping',
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

// Helper functions with better formatting
function generateSlug(name) {
  if (!name || typeof name !== 'string') return 'event';
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

function formatDateProperly(dateValue) {
  if (!dateValue) return '';
  
  // Check if it's already in YYYY-MM-DD format
  if (String(dateValue).match(/^\d{4}-\d{2}-\d{2}$/)) {
    return dateValue;
  }
  
  // Try to parse and format
  try {
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) return '';
    
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    
    // Only return if year is reasonable (2024-2026)
    if (year >= 2024 && year <= 2026) {
      return `${year}-${month}-${day}`;
    }
  } catch (e) {
    console.error('Date parsing error:', e);
  }
  
  return '';
}

function formatTimeProperly(timeValue) {
  if (!timeValue) return '';
  
  const timeStr = String(timeValue);
  
  // Already formatted
  if (timeStr.includes('AM') || timeStr.includes('PM')) {
    return timeStr;
  }
  
  // Convert 24hr to 12hr format
  if (timeStr.includes(':')) {
    try {
      const [hours, minutes] = timeStr.split(':');
      const h = parseInt(hours);
      if (!isNaN(h)) {
        const ampm = h >= 12 ? 'PM' : 'AM';
        const displayHour = h % 12 || 12;
        return `${displayHour}:${minutes || '00'} ${ampm}`;
      }
    } catch (e) {
      console.error('Time parsing error:', e);
    }
  }
  
  return timeStr;
}

function formatPriceProperly(priceValue) {
  if (!priceValue) return '';
  
  const priceStr = String(priceValue).trim();
  
  // Handle free events
  if (priceStr === '0' || priceStr.toLowerCase() === 'free') {
    return 'Free';
  }
  
  // Already has $
  if (priceStr.includes('$')) {
    return priceStr;
  }
  
  // Add $ to numeric values
  if (/^\d+/.test(priceStr)) {
    return '$' + priceStr;
  }
  
  return priceStr;
}

// ============= FIX EXISTING BAD DATA =============

function fixExistingBadData() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    SpreadsheetApp.getUi().alert('No data to fix');
    return;
  }
  
  let fixed = 0;
  
  // Process each data row (skip header)
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    let needsFix = false;
    
    // Check if name is a UUID
    if (row[0] && String(row[0]).match(/^[0-9a-f]{8}-/)) {
      // Fix based on what's in row[5] (which might have the studio name)
      if (String(row[5]).includes('2935 Main')) {
        sheet.getRange(i + 1, 1).setValue('Boxing Class');
        sheet.getRange(i + 1, 3).setValue('Rumble Boxing');
        sheet.getRange(i + 1, 4).setValue('Rumble Boxing Mount Pleasant');
      } else if (String(row[5]).includes('3071 Main')) {
        sheet.getRange(i + 1, 1).setValue('Pottery Workshop');
        sheet.getRange(i + 1, 3).setValue('Claymates Studio');
        sheet.getRange(i + 1, 4).setValue('Claymates Ceramic Studio');
      } else {
        sheet.getRange(i + 1, 1).setValue('Workshop');
      }
      needsFix = true;
    }
    
    // Check if Event Date column has an address
    if (row[5] && String(row[5]).includes('Main St')) {
      // Move address to correct column
      sheet.getRange(i + 1, 5).setValue(row[5]); // Put address in address column
      sheet.getRange(i + 1, 6).setValue(row[2]);  // Put date in date column
      needsFix = true;
    }
    
    // Check if Time column has a date
    if (row[6] && String(row[6]).includes('2025')) {
      sheet.getRange(i + 1, 6).setValue(row[6]);  // Move date to date column
      sheet.getRange(i + 1, 7).setValue(row[3]);  // Move time to time column
      needsFix = true;
    }
    
    // Add $ to price if missing
    if (row[7] && !String(row[7]).includes('$') && row[7] !== 'Free') {
      sheet.getRange(i + 1, 8).setValue('$' + row[7]);
      needsFix = true;
    }
    
    if (needsFix) fixed++;
  }
  
  SpreadsheetApp.getUi().alert(`Fixed ${fixed} rows with scrambled data`);
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🚨 CRITICAL FIX')
    .addItem('🔧 Fix Scrambled Data', 'fixExistingBadData')
    .addToUi();
}