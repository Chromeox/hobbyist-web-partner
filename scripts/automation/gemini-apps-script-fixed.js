/**
 * Fixed Gemini AI Integration for Event Description Rewriting
 * Updated with better error handling and correct API format
 */

// ============= GEMINI CONFIGURATION =============

const GEMINI_CONFIG = {
  MODEL: 'gemini-1.5-flash', // Updated to current model
  MAX_TOKENS: 500,
  TEMPERATURE: 0.7,
  BATCH_SIZE: 5,
  RETRY_ATTEMPTS: 3
};

// ============= TEST CONNECTION FIRST =============

/**
 * Test Gemini connection with detailed debugging
 */
function testGeminiConnection() {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    SpreadsheetApp.getUi().alert('❌ Please add GEMINI_API_KEY to Script Properties first!');
    return false;
  }
  
  // Try the updated endpoint
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
  
  const payload = {
    contents: [{
      parts: [{
        text: "Say 'Gemini API Connected Successfully!' if you can read this."
      }]
    }]
  };
  
  const options = {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };
  
  try {
    const response = UrlFetchApp.fetch(url, options);
    const responseText = response.getContentText();
    console.log('Raw response:', responseText);
    
    const result = JSON.parse(responseText);
    
    // Check for error in response
    if (result.error) {
      SpreadsheetApp.getUi().alert('❌ API Error: ' + result.error.message);
      return false;
    }
    
    // Extract the text from the response
    if (result.candidates && result.candidates[0] && 
        result.candidates[0].content && result.candidates[0].content.parts) {
      const message = result.candidates[0].content.parts[0].text;
      SpreadsheetApp.getUi().alert('✅ ' + message);
      console.log('Gemini test successful:', message);
      return true;
    } else {
      SpreadsheetApp.getUi().alert('❌ Unexpected response format. Check logs.');
      console.log('Unexpected response structure:', result);
      return false;
    }
    
  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Connection failed: ' + error.toString());
    console.error('Gemini test failed:', error);
    return false;
  }
}

// ============= SIMPLIFIED REWRITE FUNCTION =============

/**
 * Simplified rewrite function with better error handling
 */
function rewriteWithGemini(eventData) {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY not found in Script Properties');
  }
  
  // Use the working model
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
  
  // Simplified prompt without complex JSON requirement
  const prompt = `Rewrite this Instagram event caption into a professional event description for a website.

Original: "${eventData.originalCaption}"

Event: ${eventData.name} at ${eventData.venue}
Date: ${eventData.date}
Time: ${eventData.time}
Price: ${eventData.price}

Create a 2-3 sentence description that:
- Removes hashtags and emojis
- Sounds professional but friendly
- Includes what people will learn or experience
- Ends with a call to action

Just write the description text, nothing else.`;
  
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
  
  try {
    const response = UrlFetchApp.fetch(url, options);
    const responseText = response.getContentText();
    const result = JSON.parse(responseText);
    
    // Log for debugging
    console.log('Gemini response:', JSON.stringify(result).substring(0, 500));
    
    // Check for API errors
    if (result.error) {
      throw new Error('API Error: ' + result.error.message);
    }
    
    // Extract the generated text
    if (result.candidates && result.candidates[0] && 
        result.candidates[0].content && result.candidates[0].content.parts) {
      const generatedText = result.candidates[0].content.parts[0].text;
      
      // Return simplified format
      return {
        description: generatedText.trim(),
        title: eventData.name, // Keep original title for now
        tags: eventData.tags   // Keep original tags for now
      };
    } else {
      console.error('Unexpected response structure:', result);
      throw new Error('Invalid response structure from Gemini');
    }
    
  } catch (error) {
    console.error('Gemini API error:', error);
    throw error;
  }
}

// ============= MAIN REWRITING FUNCTION =============

/**
 * Main function to rewrite event descriptions
 */
function rewriteEventDescriptions() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('❌ Events Staging sheet not found!');
    return;
  }
  
  // Get data
  const data = stagingSheet.getDataRange().getValues();
  const headers = data[0];
  const events = data.slice(1);
  
  // Find column indices
  const cols = {
    name: headers.indexOf('name'),
    originalCaption: headers.indexOf('original caption'),
    description: headers.indexOf('Description'),
    tags: headers.indexOf('Tags'),
    venue: headers.indexOf('location'),
    date: headers.indexOf('Event Date'),
    time: headers.indexOf('Time'),
    price: headers.indexOf('price'),
    rewriteStatus: headers.indexOf('Rewrite Status')
  };
  
  // Add Rewrite Status column if missing
  if (cols.rewriteStatus === -1) {
    cols.rewriteStatus = headers.length;
    stagingSheet.getRange(1, cols.rewriteStatus + 1).setValue('Rewrite Status');
  }
  
  let rewrittenCount = 0;
  let errorCount = 0;
  
  // Process only first few events for testing
  const maxEvents = Math.min(3, events.length); // Test with just 3 events first
  
  for (let i = 0; i < maxEvents; i++) {
    const row = events[i];
    const rowIndex = i + 2; // +2 for header and 0-index
    
    // Skip if already rewritten
    if (row[cols.rewriteStatus] === 'Completed') {
      continue;
    }
    
    // Skip if no original caption
    if (!row[cols.originalCaption]) {
      continue;
    }
    
    try {
      // Prepare event data
      const eventData = {
        name: row[cols.name] || 'Event',
        originalCaption: row[cols.originalCaption],
        venue: row[cols.venue] || 'Venue',
        date: row[cols.date] || 'TBD',
        time: row[cols.time] || 'TBD',
        price: row[cols.price] || 'TBD',
        tags: row[cols.tags] || ''
      };
      
      console.log(`Processing row ${rowIndex}:`, eventData.name);
      
      // Generate rewritten description
      const rewritten = rewriteWithGemini(eventData);
      
      if (rewritten && rewritten.description) {
        // Update sheet
        stagingSheet.getRange(rowIndex, cols.description + 1).setValue(rewritten.description);
        
        // Mark as completed
        stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Completed');
        rewrittenCount++;
        
        console.log(`✓ Row ${rowIndex} rewritten successfully`);
      } else {
        throw new Error('No rewritten content received');
      }
      
    } catch (error) {
      console.error(`Error rewriting row ${rowIndex}:`, error.toString());
      stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Error: ' + error.toString().substring(0, 50));
      errorCount++;
    }
    
    // Rate limiting
    Utilities.sleep(2000); // 2 seconds between requests
  }
  
  // Show summary
  SpreadsheetApp.getUi().alert(
    `✅ Rewriting Complete!\n\n` +
    `Successfully rewritten: ${rewrittenCount}\n` +
    `Errors: ${errorCount}\n\n` +
    `Check the Description column for enhanced content.`
  );
}

// ============= SIMPLE TEST FUNCTION =============

/**
 * Test with a single hardcoded example
 */
function testSimpleRewrite() {
  const testEvent = {
    name: 'Pottery Workshop',
    originalCaption: 'Join us Saturday for pottery! Learn wheel throwing. DM to book #pottery #vancouver',
    venue: 'Claymates Studio',
    date: '2025-09-15',
    time: '2:00 PM',
    price: '$85',
    tags: 'pottery, workshop'
  };
  
  try {
    console.log('Testing with:', testEvent);
    const result = rewriteWithGemini(testEvent);
    
    SpreadsheetApp.getUi().alert(
      'Test Result:\n\n' +
      'Original: ' + testEvent.originalCaption + '\n\n' +
      'Rewritten: ' + result.description
    );
    
    console.log('Success! Result:', result);
  } catch (error) {
    SpreadsheetApp.getUi().alert('Error: ' + error.toString());
    console.error('Test failed:', error);
  }
}

// ============= DEBUG FUNCTION =============

/**
 * Debug function to check API key and settings
 */
function debugSetup() {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  const info = `
Debug Information:
------------------
API Key Present: ${apiKey ? 'Yes' : 'No'}
API Key Length: ${apiKey ? apiKey.length : 0}
API Key Starts With: ${apiKey ? apiKey.substring(0, 10) + '...' : 'N/A'}
Model: ${GEMINI_CONFIG.MODEL}
  `;
  
  SpreadsheetApp.getUi().alert('Debug Info', info, SpreadsheetApp.getUi().ButtonSet.OK);
  console.log(info);
}

// ============= MENU SETUP =============

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  
  ui.createMenu('🤖 Gemini AI')
    .addItem('🧪 Test Connection', 'testGeminiConnection')
    .addItem('📝 Test Simple Rewrite', 'testSimpleRewrite')
    .addItem('✨ Rewrite Event Descriptions', 'rewriteEventDescriptions')
    .addSeparator()
    .addItem('🔍 Debug Setup', 'debugSetup')
    .addToUi();
}