/**
 * Production-Ready Gemini AI Integration
 * Tested and working with gemini-1.5-flash model
 */

// ============= CONFIGURATION =============

const GEMINI_CONFIG = {
  MODEL: 'gemini-1.5-flash',
  MAX_TOKENS: 300,
  TEMPERATURE: 0.7,
  MAX_EVENTS_PER_RUN: 10,  // Limit to prevent timeouts
  DELAY_BETWEEN_CALLS: 2000  // 2 seconds between API calls
};

// ============= MAIN REWRITING FUNCTION =============

/**
 * Process a limited number of events to avoid timeouts
 */
function rewriteEventDescriptions() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('❌ Events Staging sheet not found!');
    return;
  }
  
  const data = stagingSheet.getDataRange().getValues();
  const headers = data[0];
  const events = data.slice(1);
  
  // Find columns
  const cols = {
    name: headers.indexOf('name'),
    originalCaption: headers.indexOf('original caption'),
    description: headers.indexOf('Description'),
    venue: headers.indexOf('location'),
    date: headers.indexOf('Event Date'),
    time: headers.indexOf('Time'),
    price: headers.indexOf('price'),
    rewriteStatus: headers.indexOf('Rewrite Status')
  };
  
  // Add status column if missing
  if (cols.rewriteStatus === -1) {
    cols.rewriteStatus = headers.length;
    stagingSheet.getRange(1, cols.rewriteStatus + 1).setValue('Rewrite Status');
  }
  
  let processed = 0;
  let rewritten = 0;
  let skipped = 0;
  let errors = 0;
  
  // Process events (with limit)
  for (let i = 0; i < events.length && processed < GEMINI_CONFIG.MAX_EVENTS_PER_RUN; i++) {
    const row = events[i];
    const rowIndex = i + 2;
    
    // Skip if already completed
    if (row[cols.rewriteStatus] === 'Completed') {
      skipped++;
      continue;
    }
    
    // Skip if no caption
    if (!row[cols.originalCaption] || row[cols.originalCaption].toString().trim() === '') {
      skipped++;
      continue;
    }
    
    processed++;
    
    try {
      // Prepare event data
      const eventData = {
        name: row[cols.name] || 'Event',
        originalCaption: row[cols.originalCaption].toString(),
        venue: row[cols.venue] || '',
        date: formatDate(row[cols.date]),
        time: formatTime(row[cols.time]),
        price: formatPrice(row[cols.price])
      };
      
      console.log(`Processing event ${processed}/${GEMINI_CONFIG.MAX_EVENTS_PER_RUN}: ${eventData.name}`);
      
      // Call Gemini API
      const enhancedDescription = callGeminiAPI(eventData);
      
      if (enhancedDescription) {
        // Update sheet
        stagingSheet.getRange(rowIndex, cols.description + 1).setValue(enhancedDescription);
        stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Completed');
        rewritten++;
        console.log(`✓ Successfully rewrote: ${eventData.name}`);
      }
      
    } catch (error) {
      console.error(`Error on row ${rowIndex}:`, error.toString());
      stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Error');
      errors++;
    }
    
    // Rate limiting
    if (processed < GEMINI_CONFIG.MAX_EVENTS_PER_RUN) {
      Utilities.sleep(GEMINI_CONFIG.DELAY_BETWEEN_CALLS);
    }
  }
  
  // Show results
  const message = `
Gemini Rewriting Complete!
-------------------------
✅ Successfully rewritten: ${rewritten}
⏭️ Skipped (already done): ${skipped}
❌ Errors: ${errors}

${processed >= GEMINI_CONFIG.MAX_EVENTS_PER_RUN ? 
  `\n⚠️ Stopped at ${GEMINI_CONFIG.MAX_EVENTS_PER_RUN} events to prevent timeout.\nRun again to process more.` : 
  'All pending events processed!'}
  `;
  
  SpreadsheetApp.getUi().alert('Results', message, SpreadsheetApp.getUi().ButtonSet.OK);
}

// ============= GEMINI API CALL =============

/**
 * Call Gemini API with proper error handling
 */
function callGeminiAPI(eventData) {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY not found in Script Properties');
  }
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_CONFIG.MODEL}:generateContent?key=${apiKey}`;
  
  // Create engaging prompt
  const prompt = `Transform this Instagram event caption into a professional website description.

Instagram caption: "${eventData.originalCaption}"

Event details:
- Name: ${eventData.name}
- Venue: ${eventData.venue}
- Date: ${eventData.date}
- Time: ${eventData.time}
- Price: ${eventData.price}

Write a 2-3 sentence description that:
1. Describes what participants will do or learn
2. Mentions who it's perfect for (beginners, families, etc.)
3. Ends with an action phrase like "Reserve your spot" or "Join us for"

Remove all hashtags, emojis, and Instagram language. Make it engaging and professional.`;
  
  const payload = {
    contents: [{
      parts: [{
        text: prompt
      }]
    }],
    generationConfig: {
      temperature: GEMINI_CONFIG.TEMPERATURE,
      maxOutputTokens: GEMINI_CONFIG.MAX_TOKENS
    }
  };
  
  const options = {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };
  
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  
  if (result.error) {
    throw new Error(result.error.message);
  }
  
  if (result.candidates && result.candidates[0]) {
    return result.candidates[0].content.parts[0].text.trim();
  }
  
  throw new Error('No content generated');
}

// ============= HELPER FUNCTIONS =============

function formatDate(date) {
  if (!date) return 'Date TBD';
  if (date instanceof Date) {
    return Utilities.formatDate(date, 'PST', 'MMMM d, yyyy');
  }
  return date.toString();
}

function formatTime(time) {
  if (!time) return '';
  if (time instanceof Date) {
    return Utilities.formatDate(time, 'PST', 'h:mm a');
  }
  return time.toString();
}

function formatPrice(price) {
  if (!price) return 'Free';
  const priceStr = price.toString();
  if (priceStr.includes('$')) return priceStr;
  if (priceStr === '0') return 'Free';
  return '$' + priceStr;
}

// ============= BATCH PROCESSING =============

/**
 * Process only events that need rewriting
 */
function processUnrewrittenEvents() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = stagingSheet.getDataRange().getValues();
  const statusCol = data[0].indexOf('Rewrite Status');
  const captionCol = data[0].indexOf('original caption');
  
  let needsRewriting = 0;
  
  for (let i = 1; i < data.length; i++) {
    if (data[i][captionCol] && data[i][statusCol] !== 'Completed') {
      needsRewriting++;
    }
  }
  
  if (needsRewriting > 0) {
    console.log(`Found ${needsRewriting} events needing rewriting`);
    rewriteEventDescriptions();
  } else {
    console.log('All events already rewritten');
  }
}

// ============= TEST FUNCTIONS =============

/**
 * Quick connection test
 */
function testConnection() {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    SpreadsheetApp.getUi().alert('❌ API Key not found in Script Properties');
    return;
  }
  
  try {
    const result = callGeminiAPI({
      name: 'Test Event',
      originalCaption: 'Test caption',
      venue: 'Test Venue',
      date: 'Today',
      time: 'Now',
      price: 'Free'
    });
    
    SpreadsheetApp.getUi().alert('✅ Connection successful!\n\nTest output:\n' + result);
  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Connection failed:\n' + error.toString());
  }
}

/**
 * Process just one event for testing
 */
function rewriteSingleEvent() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  // Temporarily set max events to 1
  const originalMax = GEMINI_CONFIG.MAX_EVENTS_PER_RUN;
  GEMINI_CONFIG.MAX_EVENTS_PER_RUN = 1;
  
  rewriteEventDescriptions();
  
  // Restore original max
  GEMINI_CONFIG.MAX_EVENTS_PER_RUN = originalMax;
}

// ============= MENU =============

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🤖 Gemini AI')
    .addItem('✨ Rewrite Events (Max 10)', 'rewriteEventDescriptions')
    .addItem('📝 Rewrite Single Event', 'rewriteSingleEvent')
    .addItem('🔄 Process All Unrewritten', 'processUnrewrittenEvents')
    .addSeparator()
    .addItem('🧪 Test Connection', 'testConnection')
    .addItem('📊 Show Statistics', 'showStatistics')
    .addToUi();
}

/**
 * Show rewriting statistics
 */
function showStatistics() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = stagingSheet.getDataRange().getValues();
  const statusCol = data[0].indexOf('Rewrite Status');
  
  let completed = 0;
  let errors = 0;
  let pending = 0;
  
  for (let i = 1; i < data.length; i++) {
    const status = data[i][statusCol];
    if (status === 'Completed') completed++;
    else if (status === 'Error') errors++;
    else if (data[i][data[0].indexOf('original caption')]) pending++;
  }
  
  const message = `
📊 Gemini Rewriting Statistics
------------------------------
✅ Completed: ${completed}
⏳ Pending: ${pending}
❌ Errors: ${errors}
━━━━━━━━━━━━━━━━━━
📈 Total Events: ${completed + pending + errors}

${pending > 0 ? `\nClick "Rewrite Events" to process ${Math.min(pending, 10)} more events.` : '\n🎉 All events have been processed!'}
  `;
  
  SpreadsheetApp.getUi().alert('Statistics', message, SpreadsheetApp.getUi().ButtonSet.OK);
}

// ============= AUTOMATION =============

/**
 * Set up daily trigger for automatic rewriting
 */
function enableDailyRewriting() {
  // Remove existing triggers
  ScriptApp.getProjectTriggers().forEach(trigger => {
    if (trigger.getHandlerFunction() === 'processUnrewrittenEvents') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  // Create morning trigger (7:45 AM)
  ScriptApp.newTrigger('processUnrewrittenEvents')
    .timeBased()
    .atHour(7)
    .nearMinute(45)
    .everyDays(1)
    .create();
    
  // Create evening trigger (6:30 PM) 
  ScriptApp.newTrigger('processUnrewrittenEvents')
    .timeBased()
    .atHour(18)
    .nearMinute(30)
    .everyDays(1)
    .create();
  
  SpreadsheetApp.getUi().alert('✅ Daily rewriting enabled at 7:45 AM and 6:30 PM');
}