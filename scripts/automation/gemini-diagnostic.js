/**
 * Diagnostic Version - Shows exactly what's happening
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
    
    SpreadsheetApp.getUi().alert('Sheet "Events Staging" not found. Check the Execution log for details.');
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
  
  if (captionCol !== -1) {
    const statusCol = headers.indexOf('Rewrite Status');
    
    dataRows.forEach((row, i) => {
      if (row[captionCol] && row[captionCol].toString().trim() !== '') {
        eventsWithCaptions++;
        if (statusCol !== -1 && row[statusCol] === 'Completed') {
          eventsAlreadyDone++;
        }
        
        // Show first event details
        if (eventsWithCaptions === 1) {
          console.log('First event with caption:');
          console.log(' - Row:', i + 2);
          console.log(' - Name:', row[headers.indexOf('name')] || 'N/A');
          console.log(' - Caption:', row[captionCol].toString().substring(0, 50) + '...');
          console.log(' - Status:', statusCol !== -1 ? row[statusCol] : 'No status column');
        }
      }
    });
  }
  
  console.log(`Events with captions: ${eventsWithCaptions}`);
  console.log(`Events already completed: ${eventsAlreadyDone}`);
  console.log(`Events to process: ${eventsWithCaptions - eventsAlreadyDone}`);
  
  // 8. Show summary
  const summary = `
DIAGNOSTIC SUMMARY
==================
✓ Spreadsheet found
✓ Sheets found: ${sheets.length}
${stagingSheet ? '✓' : '❌'} Events Staging sheet found
${missingColumns.length === 0 ? '✓' : '❌'} All required columns present
${missingColumns.length > 0 ? 'Missing: ' + missingColumns.join(', ') : ''}

Data Status:
- Total rows: ${dataRows.length}
- Events with captions: ${eventsWithCaptions}
- Already processed: ${eventsAlreadyDone}
- Ready to process: ${eventsWithCaptions - eventsAlreadyDone}

${eventsWithCaptions - eventsAlreadyDone > 0 ? 
  '✅ Ready to process events!' : 
  '⚠️ No unprocessed events found'}
`;
  
  console.log(summary);
  SpreadsheetApp.getUi().alert('Diagnostic Results', summary, SpreadsheetApp.getUi().ButtonSet.OK);
  
  return {
    hasSheet: !!stagingSheet,
    hasData: eventsWithCaptions > 0,
    needsProcessing: eventsWithCaptions - eventsAlreadyDone > 0,
    headers: headers
  };
}

/**
 * Test processing with detailed logging
 */
function testRewriteWithLogging() {
  console.log('=== TEST REWRITE START ===');
  
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  console.log('1. Got spreadsheet');
  
  const stagingSheet = sheet.getSheetByName('Events Staging');
  if (!stagingSheet) {
    console.log('ERROR: Events Staging sheet not found');
    
    // Try first sheet instead
    const firstSheet = sheet.getSheets()[0];
    console.log('Using first sheet instead:', firstSheet.getName());
    
    const ui = SpreadsheetApp.getUi();
    const response = ui.alert(
      'Sheet Not Found',
      `"Events Staging" sheet not found. Use "${firstSheet.getName()}" instead?`,
      ui.ButtonSet.YES_NO
    );
    
    if (response !== ui.Button.YES) {
      return;
    }
    
    // Use first sheet
    processSheetWithLogging(firstSheet);
  } else {
    processSheetWithLogging(stagingSheet);
  }
}

function processSheetWithLogging(sheet) {
  console.log('2. Processing sheet:', sheet.getName());
  
  const data = sheet.getDataRange().getValues();
  console.log('3. Got data, rows:', data.length);
  
  const headers = data[0];
  console.log('4. Headers:', headers);
  
  // Find columns (try variations)
  const findColumn = (names) => {
    for (const name of names) {
      const index = headers.indexOf(name);
      if (index !== -1) {
        console.log(`Found column "${name}" at index ${index}`);
        return index;
      }
    }
    console.log(`Column not found, tried: ${names.join(', ')}`);
    return -1;
  };
  
  const cols = {
    name: findColumn(['name', 'Name', 'Event Name', 'title']),
    originalCaption: findColumn(['original caption', 'Original Caption', 'Caption', 'original_caption']),
    description: findColumn(['Description', 'description', 'Event Description']),
    venue: findColumn(['location', 'Location', 'venue', 'Venue', 'studio']),
    date: findColumn(['Event Date', 'Date', 'date', 'event_date']),
    time: findColumn(['Time', 'time', 'Event Time']),
    price: findColumn(['price', 'Price', 'cost', 'Cost'])
  };
  
  console.log('5. Column indices:', cols);
  
  // Check if we have minimum required columns
  if (cols.originalCaption === -1) {
    SpreadsheetApp.getUi().alert('Cannot find "original caption" column. Please check your headers.');
    return;
  }
  
  // Find first row with caption
  let foundRow = -1;
  for (let i = 1; i < data.length; i++) {
    const caption = data[i][cols.originalCaption];
    if (caption && caption.toString().trim() !== '') {
      foundRow = i;
      console.log(`6. Found first event with caption at row ${i + 1}`);
      console.log('   Caption:', caption.toString().substring(0, 100));
      break;
    }
  }
  
  if (foundRow === -1) {
    SpreadsheetApp.getUi().alert('No events with captions found to process.');
    return;
  }
  
  // Process this one event
  const row = data[foundRow];
  const eventData = {
    name: cols.name !== -1 ? row[cols.name] : 'Event',
    originalCaption: row[cols.originalCaption].toString(),
    venue: cols.venue !== -1 ? row[cols.venue] : '',
    date: cols.date !== -1 ? row[cols.date] : '',
    time: cols.time !== -1 ? row[cols.time] : '',
    price: cols.price !== -1 ? row[cols.price] : ''
  };
  
  console.log('7. Event data prepared:', eventData);
  
  // Test API call
  try {
    console.log('8. Calling Gemini API...');
    const result = testGeminiCall(eventData);
    console.log('9. API Response:', result);
    
    // Update sheet if we have description column
    if (cols.description !== -1 && result) {
      sheet.getRange(foundRow + 1, cols.description + 1).setValue(result);
      console.log('10. Updated sheet with new description');
      SpreadsheetApp.getUi().alert('Success!', 'Description updated:\n\n' + result.substring(0, 200) + '...', SpreadsheetApp.getUi().ButtonSet.OK);
    } else {
      SpreadsheetApp.getUi().alert('Success!', 'Generated description:\n\n' + result.substring(0, 200) + '...', SpreadsheetApp.getUi().ButtonSet.OK);
    }
    
  } catch (error) {
    console.log('ERROR:', error.toString());
    SpreadsheetApp.getUi().alert('Error', error.toString(), SpreadsheetApp.getUi().ButtonSet.OK);
  }
}

function testGeminiCall(eventData) {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY not found');
  }
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
  
  const prompt = `Rewrite this event caption for a website:
Caption: "${eventData.originalCaption}"
Event: ${eventData.name}
Write 2-3 professional sentences.`;
  
  const payload = {
    contents: [{
      parts: [{ text: prompt }]
    }]
  };
  
  const response = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  });
  
  const result = JSON.parse(response.getContentText());
  
  if (result.error) {
    throw new Error(result.error.message);
  }
  
  return result.candidates[0].content.parts[0].text.trim();
}

// Simple menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔍 Gemini Diagnostic')
    .addItem('📊 Run Diagnostic', 'diagnoseSheet')
    .addItem('🧪 Test Rewrite with Logging', 'testRewriteWithLogging')
    .addToUi();
}