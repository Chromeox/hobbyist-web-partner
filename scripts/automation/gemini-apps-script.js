/**
 * Gemini AI Integration for Event Description Rewriting
 * Add this to your Google Apps Script project
 * 
 * Setup:
 * 1. Get API key from https://makersuite.google.com/app/apikey
 * 2. Add to Script Properties as GEMINI_API_KEY
 * 3. Run testGeminiConnection() to verify
 */

// ============= GEMINI CONFIGURATION =============

const GEMINI_CONFIG = {
  MODEL: 'gemini-pro',
  MAX_TOKENS: 500,
  TEMPERATURE: 0.7,  // 0.7 = creative but coherent
  BATCH_SIZE: 5,     // Process 5 events at a time
  RETRY_ATTEMPTS: 3
};

// ============= MAIN REWRITING FUNCTION =============

/**
 * Rewrite event descriptions using Gemini AI
 * Called from menu or automated trigger
 */
function rewriteEventDescriptions() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('❌ Events Staging sheet not found!');
    return;
  }
  
  // Get data (skip header)
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
  
  // Process events in batches
  for (let i = 0; i < events.length; i += GEMINI_CONFIG.BATCH_SIZE) {
    const batch = events.slice(i, i + GEMINI_CONFIG.BATCH_SIZE);
    
    for (let j = 0; j < batch.length; j++) {
      const row = batch[j];
      const rowIndex = i + j + 2; // +2 for header and 0-index
      
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
          name: row[cols.name] || '',
          originalCaption: row[cols.originalCaption],
          venue: row[cols.venue] || '',
          date: row[cols.date] || '',
          time: row[cols.time] || '',
          price: row[cols.price] || '',
          tags: row[cols.tags] || ''
        };
        
        // Generate rewritten description
        const rewritten = rewriteWithGemini(eventData);
        
        if (rewritten && rewritten.description) {
          // Update sheet
          stagingSheet.getRange(rowIndex, cols.description + 1).setValue(rewritten.description);
          
          // Update tags if improved
          if (rewritten.tags) {
            stagingSheet.getRange(rowIndex, cols.tags + 1).setValue(rewritten.tags);
          }
          
          // Update title if improved
          if (rewritten.title && rewritten.title !== eventData.name) {
            stagingSheet.getRange(rowIndex, cols.name + 1).setValue(rewritten.title);
          }
          
          // Mark as completed
          stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Completed');
          rewrittenCount++;
          
        } else {
          throw new Error('No rewritten content received');
        }
        
      } catch (error) {
        console.error(`Error rewriting row ${rowIndex}:`, error);
        stagingSheet.getRange(rowIndex, cols.rewriteStatus + 1).setValue('Error');
        errorCount++;
      }
      
      // Rate limiting (stay under 60 requests/minute)
      Utilities.sleep(1500); // 1.5 seconds between requests
    }
  }
  
  // Show summary
  SpreadsheetApp.getUi().alert(
    `✅ Rewriting Complete!\n\n` +
    `Successfully rewritten: ${rewrittenCount}\n` +
    `Errors: ${errorCount}\n\n` +
    `Check the Description column for enhanced content.`
  );
}

// ============= GEMINI API FUNCTION =============

/**
 * Call Gemini API to rewrite event description
 * @param {Object} eventData - Event information
 * @returns {Object} Rewritten content
 */
function rewriteWithGemini(eventData) {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY not found in Script Properties');
  }
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_CONFIG.MODEL}:generateContent?key=${apiKey}`;
  
  // Create the prompt
  const prompt = createRewritePrompt(eventData);
  
  const payload = {
    contents: [{
      parts: [{
        text: prompt
      }]
    }],
    generationConfig: {
      temperature: GEMINI_CONFIG.TEMPERATURE,
      maxOutputTokens: GEMINI_CONFIG.MAX_TOKENS,
      topP: 0.95,
      topK: 40
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
    const result = JSON.parse(response.getContentText());
    
    if (result.candidates && result.candidates[0]) {
      const generatedText = result.candidates[0].content.parts[0].text;
      return parseGeminiResponse(generatedText);
    } else {
      throw new Error('Invalid Gemini response');
    }
    
  } catch (error) {
    console.error('Gemini API error:', error);
    
    // Retry logic
    for (let attempt = 1; attempt <= GEMINI_CONFIG.RETRY_ATTEMPTS; attempt++) {
      Utilities.sleep(2000 * attempt); // Exponential backoff
      try {
        const response = UrlFetchApp.fetch(url, options);
        const result = JSON.parse(response.getContentText());
        if (result.candidates && result.candidates[0]) {
          const generatedText = result.candidates[0].content.parts[0].text;
          return parseGeminiResponse(generatedText);
        }
      } catch (retryError) {
        console.error(`Retry ${attempt} failed:`, retryError);
      }
    }
    
    throw error;
  }
}

// ============= PROMPT ENGINEERING =============

/**
 * Create optimized prompt for event rewriting
 */
function createRewritePrompt(eventData) {
  return `You are a professional event copywriter for a Vancouver hobby directory website. 
  
Rewrite this Instagram event caption into an engaging, clear event description.

ORIGINAL CAPTION:
"${eventData.originalCaption}"

EVENT DETAILS:
- Event Name: ${eventData.name}
- Venue: ${eventData.venue}
- Date: ${eventData.date}
- Time: ${eventData.time}
- Price: ${eventData.price}
- Current Tags: ${eventData.tags}

REQUIREMENTS:
1. Create a compelling 2-3 sentence description (50-150 words)
2. Highlight what makes this event special
3. Include a clear call-to-action
4. Remove all hashtags and Instagram-specific language
5. Make it professional but friendly
6. Emphasize the experience and benefits
7. Mention if it's beginner-friendly
8. Include practical details naturally

OUTPUT FORMAT (JSON):
{
  "title": "Improved event title if needed",
  "description": "The rewritten description",
  "tags": "relevant, tags, separated, by, commas"
}

Focus on making people excited to attend this event!`;
}

/**
 * Parse Gemini's response into structured data
 */
function parseGeminiResponse(text) {
  try {
    // Try to parse as JSON first
    const cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    return JSON.parse(cleaned);
  } catch (error) {
    // Fallback: Extract content manually
    const description = text.match(/"description"\s*:\s*"([^"]+)"/);
    const title = text.match(/"title"\s*:\s*"([^"]+)"/);
    const tags = text.match(/"tags"\s*:\s*"([^"]+)"/);
    
    return {
      description: description ? description[1] : text.trim(),
      title: title ? title[1] : null,
      tags: tags ? tags[1] : null
    };
  }
}

// ============= BATCH PROCESSING =============

/**
 * Process only events that need rewriting
 */
function rewritePendingEvents() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    console.error('Events Staging sheet not found');
    return;
  }
  
  const data = stagingSheet.getDataRange().getValues();
  const headers = data[0];
  
  // Find status column
  const statusCol = headers.indexOf('Rewrite Status');
  const captionCol = headers.indexOf('original caption');
  
  let pendingCount = 0;
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    // Check if needs rewriting
    if (row[captionCol] && (!row[statusCol] || row[statusCol] === 'Error')) {
      pendingCount++;
    }
  }
  
  if (pendingCount > 0) {
    console.log(`Found ${pendingCount} events to rewrite`);
    rewriteEventDescriptions();
  } else {
    console.log('No events need rewriting');
  }
}

// ============= TEST FUNCTIONS =============

/**
 * Test Gemini connection with a simple prompt
 */
function testGeminiConnection() {
  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  
  if (!apiKey) {
    SpreadsheetApp.getUi().alert('❌ Please add GEMINI_API_KEY to Script Properties first!');
    return false;
  }
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`;
  
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
    payload: JSON.stringify(payload)
  };
  
  try {
    const response = UrlFetchApp.fetch(url, options);
    const result = JSON.parse(response.getContentText());
    const message = result.candidates[0].content.parts[0].text;
    
    SpreadsheetApp.getUi().alert('✅ ' + message);
    console.log('Gemini test successful:', message);
    return true;
    
  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Connection failed: ' + error.toString());
    console.error('Gemini test failed:', error);
    return false;
  }
}

/**
 * Test rewriting with a sample event
 */
function testRewriteSample() {
  const sampleEvent = {
    name: 'Pottery Workshop',
    originalCaption: '🎨 Join us this Saturday for an amazing pottery workshop! Perfect for beginners. Learn wheel throwing basics. Limited spots! DM to book. #pottery #vancouver #workshop #claymates #art',
    venue: 'Claymates Studio',
    date: '2025-09-15',
    time: '14:00',
    price: '85',
    tags: 'pottery, workshop'
  };
  
  try {
    const result = rewriteWithGemini(sampleEvent);
    
    const output = `
✅ Rewrite Test Successful!

Original: "${sampleEvent.originalCaption}"

Rewritten Title: ${result.title || sampleEvent.name}

Rewritten Description: ${result.description}

Enhanced Tags: ${result.tags}
    `;
    
    SpreadsheetApp.getUi().alert(output);
    console.log('Test result:', result);
    
  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Test failed: ' + error.toString());
    console.error('Test error:', error);
  }
}

// ============= MENU SETUP =============

/**
 * Add Gemini functions to menu
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  
  ui.createMenu('🤖 Gemini AI')
    .addItem('📝 Rewrite Event Descriptions', 'rewriteEventDescriptions')
    .addItem('🔄 Process Pending Events', 'rewritePendingEvents')
    .addSeparator()
    .addItem('🧪 Test Connection', 'testGeminiConnection')
    .addItem('📋 Test Sample Rewrite', 'testRewriteSample')
    .addSeparator()
    .addItem('⚙️ Setup Instructions', 'showSetupInstructions')
    .addToUi();
}

/**
 * Show setup instructions
 */
function showSetupInstructions() {
  const instructions = `
🤖 Gemini AI Setup Instructions

1️⃣ Get your API Key:
   • Go to: https://makersuite.google.com/app/apikey
   • Click "Get API Key"
   • Copy the key (starts with AIzaSy...)

2️⃣ Add to Script Properties:
   • Click Project Settings (gear icon)
   • Scroll to Script Properties
   • Add: GEMINI_API_KEY = [your key]

3️⃣ Test Connection:
   • Run: Gemini AI → Test Connection

4️⃣ Start Rewriting:
   • Run: Gemini AI → Rewrite Event Descriptions

Free Tier Limits:
• 60 requests/minute
• 1,500 requests/day
• Perfect for ~50 events daily!
  `;
  
  SpreadsheetApp.getUi().alert('Gemini Setup', instructions, SpreadsheetApp.getUi().ButtonSet.OK);
}

// ============= AUTOMATION TRIGGERS =============

/**
 * Set up automated rewriting (runs daily at 7:45 AM)
 */
function setupAutomatedRewriting() {
  // Remove existing triggers
  ScriptApp.getProjectTriggers().forEach(trigger => {
    if (trigger.getHandlerFunction() === 'rewritePendingEvents') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  // Create new daily trigger
  ScriptApp.newTrigger('rewritePendingEvents')
    .timeBased()
    .atHour(7)
    .nearMinute(45)
    .everyDays(1)
    .create();
  
  console.log('Automated rewriting scheduled for 7:45 AM daily');
}

/**
 * Remove automated triggers
 */
function removeAutomatedRewriting() {
  ScriptApp.getProjectTriggers().forEach(trigger => {
    if (trigger.getHandlerFunction() === 'rewritePendingEvents') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  console.log('Automated rewriting disabled');
}