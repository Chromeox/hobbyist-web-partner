/**
 * Diagnostic Version - Works from both Apps Script editor and Sheet menu
 */

function diagnoseSheet() {
  console.log('=== DIAGNOSTIC START ===');
  
  // 1. Check spreadsheet
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  console.log('Spreadsheet name:', spreadsheet.getName());
  
  // 2. List all sheets
  const sheets = spreadsheet.getSheets();
  console.log('Available sheets:');
  sheets.forEach(sheet => {
    console.log(' - "' + sheet.getName() + '"');
  });
  
  // 3. Try to find Events Staging
  const stagingSheet = spreadsheet.getSheetByName('Events Staging');
  if (!stagingSheet) {
    console.log('❌ ERROR: "Events Staging" sheet not found!');
    console.log('Looking for alternative names...');
    
    // Try common variations
    const variations = ['Events staging', 'events staging', 'Event Staging', 'Staging', 'Events'];
    for (const name of variations) {
      const sheet = spreadsheet.getSheetByName(name);
      if (sheet) {
        console.log('Found sheet with name:', name);
        break;
      }
    }
    
    // Don't use UI alert if running from editor
    console.log('DIAGNOSTIC COMPLETE - Check execution log for details');
    return;
  }
  
  console.log('✓ Found Events Staging sheet');
  
  // 4. Check headers
  const data = stagingSheet.getDataRange().getValues();
  const headers = data[0];
  console.log('Headers found:', headers);
  
  // 5. Check for required columns
  const requiredColumns = ['name', 'original caption', 'Description', 'location', 'Event Date', 'Time', 'price'];
  const missingColumns = [];
  
  requiredColumns.forEach(col => {
    const index = headers.indexOf(col);
    if (index === -1) {
      missingColumns.push(col);
      console.log(`❌ Missing column: "${col}"`);
    } else {
      console.log(`✓ Found column: "${col}" at index ${index}`);
    }
  });
  
  // 6. Check data rows
  const dataRows = data.slice(1);
  console.log(`Total data rows: ${dataRows.length}`);
  
  // 7. Check for events with captions
  const captionCol = headers.indexOf('original caption');
  let eventsWithCaptions = 0;
  let eventsAlreadyDone = 0;
  let sampleEvents = [];
  
  if (captionCol !== -1) {
    const statusCol = headers.indexOf('Rewrite Status');
    
    dataRows.forEach((row, i) => {
      if (row[captionCol] && row[captionCol].toString().trim() !== '') {
        eventsWithCaptions++;
        if (statusCol !== -1 && row[statusCol] === 'Completed') {
          eventsAlreadyDone++;
        }
        
        // Collect first 3 events for sample
        if (sampleEvents.length < 3) {
          sampleEvents.push({
            row: i + 2,
            name: row[headers.indexOf('name')] || 'N/A',
            caption: row[captionCol].toString().substring(0, 50) + '...',
            status: statusCol !== -1 ? row[statusCol] || 'Not processed' : 'No status column'
          });
        }
      }
    });
  }
  
  console.log(`Events with captions: ${eventsWithCaptions}`);
  console.log(`Events already completed: ${eventsAlreadyDone}`);
  console.log(`Events to process: ${eventsWithCaptions - eventsAlreadyDone}`);
  
  // Show sample events
  if (sampleEvents.length > 0) {
    console.log('\nSample events:');
    sampleEvents.forEach(event => {
      console.log(`Row ${event.row}: ${event.name}`);
      console.log(`  Caption: ${event.caption}`);
      console.log(`  Status: ${event.status}`);
    });
  }
  
  // 8. Show summary
  const summary = `
=================================
DIAGNOSTIC SUMMARY
=================================
✓ Spreadsheet: ${spreadsheet.getName()}
✓ Total sheets: ${sheets.length}
${stagingSheet ? '✓' : '❌'} Events Staging sheet: ${stagingSheet ? 'Found' : 'NOT FOUND'}

Column Check:
${missingColumns.length === 0 ? '✓ All required columns present' : '❌ Missing columns: ' + missingColumns.join(', ')}

Data Status:
- Total rows: ${dataRows.length}
- Events with captions: ${eventsWithCaptions}
- Already processed: ${eventsAlreadyDone}
- Ready to process: ${eventsWithCaptions - eventsAlreadyDone}

${eventsWithCaptions - eventsAlreadyDone > 0 ? 
  '✅ READY: ' + (eventsWithCaptions - eventsAlreadyDone) + ' events can be processed!' : 
  '⚠️ No unprocessed events found'}
=================================
`;
  
  console.log(summary);
  
  // Try to show alert only if UI is available
  try {
    SpreadsheetApp.getUi().alert('Diagnostic Results', summary, SpreadsheetApp.getUi().ButtonSet.OK);
  } catch (e) {
    console.log('Note: Run from Sheet menu to see popup. Results are in execution log.');
  }
  
  return {
    hasSheet: !!stagingSheet,
    hasData: eventsWithCaptions > 0,
    needsProcessing: eventsWithCaptions - eventsAlreadyDone > 0,
    headers: headers
  };
}

/**
 * Simple test that works from editor
 */
function testFromEditor() {
  console.log('=== RUNNING TEST FROM EDITOR ===');
  
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const firstSheet = sheet.getSheets()[0];
  
  console.log('Using sheet:', firstSheet.getName());
  
  const data = firstSheet.getDataRange().getValues();
  console.log('Total rows:', data.length);
  console.log('Headers:', data[0]);
  
  // Look for caption column
  const headers = data[0];
  let captionCol = -1;
  
  // Try different variations
  const captionVariations = ['original caption', 'Original Caption', 'Caption', 'original_caption', 'caption'];
  for (const variant of captionVariations) {
    const index = headers.indexOf(variant);
    if (index !== -1) {
      captionCol = index;
      console.log('Found caption column:', variant, 'at index', index);
      break;
    }
  }
  
  if (captionCol === -1) {
    console.log('ERROR: No caption column found');
    console.log('Available columns:', headers);
    return;
  }
  
  // Find first row with caption
  for (let i = 1; i < Math.min(5, data.length); i++) {
    const caption = data[i][captionCol];
    if (caption && caption.toString().trim()) {
      console.log(`\nFound event at row ${i + 1}:`);
      console.log('Caption:', caption.toString().substring(0, 100));
      
      // Test Gemini on this
      testGeminiSimple(caption.toString());
      break;
    }
  }
}

/**
 * Simple Gemini test
 */
function testGeminiSimple(caption) {
  console.log('\n=== TESTING GEMINI ===');
  
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    console.log('ERROR: No API key found in Script Properties');
    return;
  }
  
  console.log('API key found, length:', apiKey.length);
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
  
  const prompt = `Rewrite this Instagram caption for a website in 2 sentences: "${caption}"`;
  
  const payload = {
    contents: [{
      parts: [{ text: prompt }]
    }]
  };
  
  try {
    console.log('Calling Gemini API...');
    const response = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    });
    
    const result = JSON.parse(response.getContentText());
    
    if (result.error) {
      console.log('API ERROR:', result.error.message);
      return;
    }
    
    if (result.candidates && result.candidates[0]) {
      const rewritten = result.candidates[0].content.parts[0].text;
      console.log('\n✅ SUCCESS! Gemini rewrote the caption:');
      console.log(rewritten);
    } else {
      console.log('Unexpected response:', JSON.stringify(result).substring(0, 200));
    }
    
  } catch (error) {
    console.log('ERROR calling API:', error.toString());
  }
}

/**
 * Fix sheet headers if needed
 */
function fixHeaders() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging') || sheet.getSheets()[0];
  
  console.log('Checking headers in:', stagingSheet.getName());
  
  const headers = stagingSheet.getRange(1, 1, 1, stagingSheet.getLastColumn()).getValues()[0];
  console.log('Current headers:', headers);
  
  // Standard headers that should exist
  const standardHeaders = [
    'name',
    'slug', 
    'studio',
    'location',
    'address',
    'Event Date',
    'Time',
    'price',
    'Description',
    'Image URL',
    'Book Link',
    'Tags',
    'Webflow status',
    'Sync to webflow',
    'dynamic label',
    'original caption',
    'instagram URL',
    'Source',
    'Event Images',
    'attachment summary',
    'Rewrite Status'
  ];
  
  // Add missing headers
  let col = headers.length + 1;
  standardHeaders.forEach(header => {
    if (!headers.includes(header)) {
      console.log('Adding missing header:', header);
      stagingSheet.getRange(1, col).setValue(header);
      col++;
    }
  });
  
  console.log('Headers fixed!');
}

// Menu that works from sheet
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔍 Diagnostic')
    .addItem('📊 Run Full Diagnostic', 'diagnoseSheet')
    .addItem('🧪 Test from Editor', 'testFromEditor')
    .addItem('🔧 Fix Headers', 'fixHeaders')
    .addToUi();
}