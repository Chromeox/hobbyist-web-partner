/**
 * Complete Google Apps Script for Hobby Directory
 * Configured for your exact Airtable field structure
 * 
 * Instructions:
 * 1. Delete ALL existing code in Apps Script
 * 2. Paste this entire file
 * 3. Save and run setupHobbyDirectory
 */

// ============= INITIAL SETUP =============

function setupHobbyDirectory() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  // Create all necessary sheets
  createSheets(ss);
  
  // Set up headers and formatting with Airtable fields
  setupEventsSheetWithAirtableFields(ss);
  setupInstagramQueueSheet(ss);
  setupWebsiteQueueSheet(ss);
  setupReviewQueueSheet(ss);
  setupPublishedSheet(ss);
  setupSettingsSheet(ss);
  
  // Set up triggers
  setupTriggers();
  
  // Try to create menus and show alert
  try {
    createCustomMenus();
    SpreadsheetApp.getUi().alert('✅ Hobby Directory setup complete!');
  } catch(e) {
    console.log('Setup complete! Open spreadsheet to see menus.');
  }
}

function createSheets(ss) {
  const requiredSheets = [
    'Events Staging',
    'Instagram Queue',
    'Website Queue', 
    'Review Queue',
    'Published',
    'Settings',
    'Error Log'
  ];
  
  requiredSheets.forEach(sheetName => {
    if (!ss.getSheetByName(sheetName)) {
      ss.insertSheet(sheetName);
      console.log(`Created sheet: ${sheetName}`);
    }
  });
}

// ============= EVENTS STAGING WITH AIRTABLE FIELDS =============

function setupEventsSheetWithAirtableFields(ss) {
  const sheet = ss.getSheetByName('Events Staging');
  
  // Your exact Airtable fields + helper columns
  const headers = [
    'name',                  // A - Event name
    'slug',                  // B - URL slug (auto-generated)
    'studio',                // C - Studio/Instructor name
    'location',              // D - Venue name
    'address',               // E - Full address
    'Event Date',            // F - Date of event
    'Time',                  // G - Time of event
    'price',                 // H - Price
    'Description',           // I - Main description (rewritten)
    'Image URL',             // J - Main image
    'Book Link',             // K - Booking URL
    'Tags',                  // L - Categories/tags
    'Webflow status',        // M - Publishing status
    'Sync to webflow',       // N - Yes/No flag
    'dynamic label',         // O - Auto-generated label
    'original caption',      // P - Original description from scraping
    'instagram URL',         // Q - Link to Instagram post
    'Source',                // R - Where it came from
    'Event Images',          // S - Additional images
    'attachment summary',    // T - Summary of attachments
    'Scraped At',            // U - When we scraped it (helper)
    'Review Status',         // V - Our review status (helper)
    'Quality Score',         // W - Auto-calculated (helper)
    'Review Notes'           // X - Manual notes (helper)
  ];
  
  // Set headers
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  
  // Format headers
  const headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setBackground('#4285F4');
  headerRange.setFontColor('#FFFFFF');
  headerRange.setFontWeight('bold');
  headerRange.setWrap(true);
  
  // Set column widths
  sheet.setColumnWidth(1, 200);  // name
  sheet.setColumnWidth(2, 150);  // slug
  sheet.setColumnWidth(3, 150);  // studio
  sheet.setColumnWidth(4, 150);  // location
  sheet.setColumnWidth(5, 200);  // address
  sheet.setColumnWidth(9, 300);  // Description
  sheet.setColumnWidth(16, 300); // original caption
  
  // Add data validation for Webflow status (column M)
  const webflowStatusRange = sheet.getRange(2, 13, 999, 1);
  const webflowStatusRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Draft', 'Published', 'Archived'])
    .setAllowInvalid(false)
    .build();
  webflowStatusRange.setDataValidation(webflowStatusRule);
  
  // Add data validation for Sync to webflow (column N)
  const syncRange = sheet.getRange(2, 14, 999, 1);
  const syncRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Yes', 'No'])
    .setAllowInvalid(false)
    .build();
  syncRange.setDataValidation(syncRule);
  
  // Add data validation for Review Status (column V)
  const reviewStatusRange = sheet.getRange(2, 22, 999, 1);
  const reviewRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Scraped', 'Pending Review', 'Approved', 'Rejected'])
    .setAllowInvalid(false)
    .build();
  reviewStatusRange.setDataValidation(reviewRule);
  
  // Add data validation for Source (column R)
  const sourceRange = sheet.getRange(2, 18, 999, 1);
  const sourceRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Instagram', 'Website', 'Manual', 'Mixed'])
    .setAllowInvalid(false)
    .build();
  sourceRange.setDataValidation(sourceRule);
  
  // Conditional formatting for Review Status
  const rules = [];
  
  // Green for Approved
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenTextEqualTo('Approved')
    .setBackground('#B7E1CD')
    .setRanges([reviewStatusRange])
    .build());
  
  // Yellow for Pending Review
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenTextEqualTo('Pending Review')
    .setBackground('#FCE5CD')
    .setRanges([reviewStatusRange])
    .build());
  
  // Red for Rejected
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenTextEqualTo('Rejected')
    .setBackground('#F4C7C3')
    .setRanges([reviewStatusRange])
    .build());
  
  sheet.setConditionalFormatRules(rules);
  
  // Freeze header row
  sheet.setFrozenRows(1);
}

// ============= OTHER SHEETS SETUP =============

function setupInstagramQueueSheet(ss) {
  const sheet = ss.getSheetByName('Instagram Queue');
  
  const headers = [
    ['Event_ID', 'Instagram_Handle', 'Status', 'Bio', 'Followers', 
     'Recent_Posts', 'Website_Link', 'Is_Verified', 'Last_Scraped', 'Error']
  ];
  
  sheet.getRange('A1:J1').setValues(headers);
  sheet.getRange('A1:J1').setBackground('#EA4335').setFontColor('#FFFFFF').setFontWeight('bold');
  sheet.setFrozenRows(1);
}

function setupWebsiteQueueSheet(ss) {
  const sheet = ss.getSheetByName('Website Queue');
  
  const headers = [
    ['Event_ID', 'Website_URL', 'Status', 'Title', 'Meta_Description', 
     'OG_Image', 'JSON_LD', 'Last_Scraped', 'Error']
  ];
  
  sheet.getRange('A1:I1').setValues(headers);
  sheet.getRange('A1:I1').setBackground('#FBBC04').setFontColor('#000000').setFontWeight('bold');
  
  // Add IMPORTXML formulas in helper columns
  sheet.getRange('J1').setValue('Helper: Title');
  sheet.getRange('J2').setFormula('=IFERROR(IMPORTXML(B2,"//title"),"")');
  
  sheet.getRange('K1').setValue('Helper: Meta');
  sheet.getRange('K2').setFormula('=IFERROR(IMPORTXML(B2,"//meta[@name=\'description\']/@content"),"")');
  
  sheet.getRange('L1').setValue('Helper: OG Image');
  sheet.getRange('L2').setFormula('=IFERROR(IMPORTXML(B2,"//meta[@property=\'og:image\']/@content"),"")');
  
  sheet.setFrozenRows(1);
}

function setupReviewQueueSheet(ss) {
  const sheet = ss.getSheetByName('Review Queue');
  
  const headers = [
    ['Event_ID', 'Name', 'Date', 'Location', 'Original_Desc', 
     'Rewritten_Desc', 'Quality_Score', 'Reviewer', 'Decision', 
     'Review_Notes', 'Review_Date']
  ];
  
  sheet.getRange('A1:K1').setValues(headers);
  sheet.getRange('A1:K1').setBackground('#34A853').setFontColor('#FFFFFF').setFontWeight('bold');
  
  // Add data validation for Decision
  const decisionRange = sheet.getRange('I2:I1000');
  const decisionRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(['Approve', 'Reject', 'Edit', 'Pending'])
    .setAllowInvalid(false)
    .build();
  decisionRange.setDataValidation(decisionRule);
  
  sheet.setFrozenRows(1);
}

function setupPublishedSheet(ss) {
  const sheet = ss.getSheetByName('Published');
  
  const headers = [
    ['Event_ID', 'Name', 'Date', 'Location', 'Final_Description', 
     'Webflow_Slug', 'Webflow_ID', 'Published_Date', 'Last_Synced', 'Sync_Status']
  ];
  
  sheet.getRange('A1:J1').setValues(headers);
  sheet.getRange('A1:J1').setBackground('#9900FF').setFontColor('#FFFFFF').setFontWeight('bold');
  sheet.setFrozenRows(1);
}

function setupSettingsSheet(ss) {
  const sheet = ss.getSheetByName('Settings');
  
  const settings = [
    ['Setting', 'Value', 'Description'],
    ['Review_Time', '07:30', 'Daily review time (24hr format)'],
    ['Review_Email', Session.getActiveUser().getEmail(), 'Email for daily review'],
    ['Auto_Scrape', 'TRUE', 'Enable automatic scraping'],
    ['Scrape_Interval', '6', 'Hours between scrapes'],
    ['AI_Rewrite', 'TRUE', 'Enable AI rewriting'],
    ['AI_Model', 'gpt-4', 'AI model to use'],
    ['Webhook_URL', '', 'Webhook for AI rewriting'],
    ['Spreadsheet_ID', SpreadsheetApp.getActiveSpreadsheet().getId(), 'This spreadsheet ID'],
    ['Web_App_URL', '', 'Web App deployment URL'],
    ['Target_Accounts', '@rumbleboxingmp, @claymates.studio', 'Instagram accounts to scrape']
  ];
  
  sheet.getRange('A1:C11').setValues(settings);
  sheet.getRange('A1:C1').setBackground('#000000').setFontColor('#FFFFFF').setFontWeight('bold');
  
  const protection = sheet.protect().setDescription('Settings Protection');
  protection.setWarningOnly(true);
}

// ============= CUSTOM MENU =============

function createCustomMenus() {
  try {
    const ui = SpreadsheetApp.getUi();
    
    ui.createMenu('🎯 Hobby Directory')
      .addItem('📥 Import Instagram Data', 'importInstagramData')
      .addItem('🌐 Scrape Websites', 'scrapeWebsites')
      .addItem('🤖 Rewrite Descriptions', 'rewriteDescriptions')
      .addItem('📧 Send Review Email', 'sendReviewEmail')
      .addItem('✅ Approve All Pending', 'approveAllPending')
      .addSeparator()
      .addItem('📤 Export for Airtable', 'exportForAirtable')
      .addItem('🔄 Run Full Pipeline', 'runFullPipeline')
      .addSeparator()
      .addItem('🔧 Fix Data Validation', 'fixDataValidation')
      .addItem('⚙️ Show Settings', 'showSettings')
      .addToUi();
  } catch(e) {
    console.log('Menu will be created when spreadsheet opens');
  }
}

// ============= AUTOMATION FUNCTIONS =============

function importInstagramData() {
  try {
    const ui = SpreadsheetApp.getUi();
    const response = ui.prompt('Enter Instagram handle (without @):');
    
    if (response.getSelectedButton() == ui.Button.OK) {
      const handle = response.getResponseText();
      addToInstagramQueue(handle);
      ui.alert(`Added @${handle} to scraping queue`);
    }
  } catch(e) {
    console.log('Cannot show prompt from script editor');
  }
}

function addToInstagramQueue(handle) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Instagram Queue');
  const lastRow = sheet.getLastRow();
  
  sheet.getRange(lastRow + 1, 1, 1, 3).setValues([[
    Utilities.getUuid(),
    '@' + handle.replace('@', ''),
    'Pending'
  ]]);
}

function scrapeWebsites() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Website Queue');
  
  if (sheet.getLastRow() < 2) {
    try {
      SpreadsheetApp.getUi().alert('No websites to scrape');
    } catch(e) {
      console.log('No websites to scrape');
    }
    return;
  }
  
  const dataRange = sheet.getRange(2, 1, sheet.getLastRow() - 1, 12);
  const data = dataRange.getValues();
  
  data.forEach((row, index) => {
    if (row[1] && row[2] !== 'Complete') {
      const helperRow = sheet.getRange(index + 2, 10, 1, 3).getValues()[0];
      
      sheet.getRange(index + 2, 4).setValue(helperRow[0]); // Title
      sheet.getRange(index + 2, 5).setValue(helperRow[1]); // Meta
      sheet.getRange(index + 2, 6).setValue(helperRow[2]); // OG Image
      sheet.getRange(index + 2, 3).setValue('Complete');
      sheet.getRange(index + 2, 8).setValue(new Date());
    }
  });
  
  try {
    SpreadsheetApp.getUi().alert('✅ Website scraping complete');
  } catch(e) {
    console.log('Website scraping complete');
  }
}

function rewriteDescriptions() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const eventsSheet = ss.getSheetByName('Events Staging');
  
  const lastRow = eventsSheet.getLastRow();
  if (lastRow < 2) {
    try {
      SpreadsheetApp.getUi().alert('No events to rewrite');
    } catch(e) {
      console.log('No events to rewrite');
    }
    return;
  }
  
  const data = eventsSheet.getRange(2, 1, lastRow - 1, 24).getValues();
  let rewrittenCount = 0;
  
  data.forEach((row, index) => {
    const originalDesc = row[15];  // Column P: original caption
    const rewrittenDesc = row[8];  // Column I: Description
    const status = row[21];        // Column V: Review Status
    
    if (originalDesc && !rewrittenDesc && status === 'Scraped') {
      const rewritten = mockAIRewrite(originalDesc);
      eventsSheet.getRange(index + 2, 9).setValue(rewritten);
      eventsSheet.getRange(index + 2, 22).setValue('Pending Review');
      
      const score = calculateQualityScore(row);
      eventsSheet.getRange(index + 2, 23).setValue(score);
      
      rewrittenCount++;
    }
  });
  
  try {
    SpreadsheetApp.getUi().alert(`✅ Rewrote ${rewrittenCount} descriptions`);
  } catch(e) {
    console.log(`Rewrote ${rewrittenCount} descriptions`);
  }
}

function mockAIRewrite(text) {
  return `🎉 ${text} Join us for an amazing experience in Vancouver's creative community!`;
}

function calculateQualityScore(row) {
  let score = 0;
  
  if (row[0]) score += 20;  // name
  if (row[5]) score += 15;  // Event Date
  if (row[3]) score += 15;  // location
  if (row[8] || row[15]) score += 20;  // Description or original caption
  if (row[9]) score += 10;  // Image URL
  if (row[7]) score += 10;  // price
  if (row[10]) score += 10; // Book Link
  
  return score;
}

function approveAllPending() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  const lastRow = sheet.getLastRow();
  
  if (lastRow < 2) return;
  
  const statusColumn = sheet.getRange(2, 22, lastRow - 1, 1).getValues();
  let approvedCount = 0;
  
  statusColumn.forEach((row, index) => {
    if (row[0] === 'Pending Review') {
      sheet.getRange(index + 2, 22).setValue('Approved');
      approvedCount++;
    }
  });
  
  try {
    SpreadsheetApp.getUi().alert(`✅ Approved ${approvedCount} events`);
  } catch(e) {
    console.log(`Approved ${approvedCount} events`);
  }
}

// ============= EXPORT FUNCTION =============

function exportForAirtable() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName('Events Staging');
  
  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];
  const approvedData = allData.filter((row, index) => {
    return index > 0 && row[21] === 'Approved';
  });
  
  if (approvedData.length === 0) {
    try {
      SpreadsheetApp.getUi().alert('No approved events to export');
    } catch(e) {
      console.log('No approved events to export');
    }
    return;
  }
  
  // Only export Airtable columns (A-T, first 20 columns)
  const airtableData = approvedData.map(row => row.slice(0, 20));
  
  // Create CSV content
  const csvContent = [
    headers.slice(0, 20).join(','),
    ...airtableData.map(row => 
      row.map(cell => {
        const value = String(cell).replace(/"/g, '""');
        return value.includes(',') || value.includes('\n') ? `"${value}"` : value;
      }).join(',')
    )
  ].join('\n');
  
  // Save to Drive
  const timestamp = new Date().toISOString().split('T')[0];
  const blob = Utilities.newBlob(csvContent, 'text/csv', `airtable_import_${timestamp}.csv`);
  const file = DriveApp.createFile(blob);
  
  // Update status for exported events
  approvedData.forEach(row => {
    const rowIndex = findRowByValue(sheet, row[0], 1);
    if (rowIndex > 0) {
      sheet.getRange(rowIndex, 22).setValue('Published');
      sheet.getRange(rowIndex, 13).setValue('Published');
      sheet.getRange(rowIndex, 14).setValue('Yes');
    }
  });
  
  const html = `
    <div>
      <h3>✅ Export Complete!</h3>
      <p>${approvedData.length} events exported for Airtable</p>
      <p><a href="${file.getUrl()}" target="_blank">Download CSV File</a></p>
      <ol>
        <li>Download the CSV file</li>
        <li>Go to your Airtable base</li>
        <li>Click "Add records" → "Import CSV"</li>
        <li>Upload the file</li>
        <li>Map fields (should auto-match)</li>
        <li>Click "Import"</li>
      </ol>
    </div>
  `;
  
  try {
    const htmlOutput = HtmlService.createHtmlOutput(html)
      .setWidth(400)
      .setHeight(300);
    
    SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Export for Airtable');
  } catch(e) {
    console.log(`Export complete! File: ${file.getUrl()}`);
  }
  
  return file.getUrl();
}

// ============= HELPER FUNCTIONS =============

function generateSlug(text) {
  if (!text) return '';
  return text.toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
}

function getSettings() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Settings');
  const data = sheet.getRange(2, 1, 10, 2).getValues();
  
  const settings = {};
  data.forEach(row => {
    settings[row[0]] = row[1];
  });
  
  return settings;
}

function showSettings() {
  const settings = getSettings();
  const message = `
    Review Time: ${settings.Review_Time}
    Review Email: ${settings.Review_Email}
    Spreadsheet ID: ${settings.Spreadsheet_ID}
    Web App URL: ${settings.Web_App_URL || 'Not set'}
    Target Accounts: ${settings.Target_Accounts}
  `;
  
  try {
    SpreadsheetApp.getUi().alert('Settings', message, SpreadsheetApp.getUi().ButtonSet.OK);
  } catch(e) {
    console.log('Settings:', message);
  }
}

function findRowByValue(sheet, value, column) {
  const data = sheet.getRange(2, column, sheet.getLastRow() - 1, 1).getValues();
  
  for (let i = 0; i < data.length; i++) {
    if (data[i][0] === value) {
      return i + 2;
    }
  }
  
  return -1;
}

function fixDataValidation() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  setupEventsSheetWithAirtableFields(ss);
  
  try {
    SpreadsheetApp.getUi().alert('✅ Data validation fixed! Check dropdowns.');
  } catch(e) {
    console.log('Data validation fixed');
  }
}

// ============= EMAIL FUNCTIONS =============

function sendReviewEmail() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const eventsSheet = ss.getSheetByName('Events Staging');
  const settings = getSettings();
  
  const pending = eventsSheet.getRange(2, 1, eventsSheet.getLastRow() - 1, 24)
    .getValues()
    .filter(row => row[21] === 'Pending Review');
  
  if (pending.length === 0) {
    try {
      SpreadsheetApp.getUi().alert('No events pending review');
    } catch(e) {
      console.log('No events pending review');
    }
    return;
  }
  
  let html = `
    <h2>🎯 Hobby Directory - Daily Review</h2>
    <p>Good morning! You have ${pending.length} events to review:</p>
    <hr>
  `;
  
  pending.forEach(event => {
    html += `
      <div style="border: 1px solid #ddd; padding: 15px; margin: 15px 0; border-radius: 8px;">
        <h3>${event[0]}</h3>
        <p><strong>Date:</strong> ${event[5]} at ${event[6]}</p>
        <p><strong>Location:</strong> ${event[3]}</p>
        <div style="background: #f5f5f5; padding: 10px; margin: 10px 0;">
          <strong>Original:</strong><br>${event[15]}
        </div>
        <div style="background: #e8f5e9; padding: 10px; margin: 10px 0;">
          <strong>Rewritten:</strong><br>${event[8]}
        </div>
        <p><strong>Quality Score:</strong> ${event[22]}%</p>
        <p>
          <a href="${ss.getUrl()}" style="background: #4CAF50; color: white; padding: 8px 16px; text-decoration: none; border-radius: 4px;">
            Review in Sheet
          </a>
        </p>
      </div>
    `;
  });
  
  MailApp.sendEmail({
    to: settings.Review_Email,
    subject: `Hobby Directory Review - ${pending.length} events`,
    htmlBody: html
  });
  
  try {
    SpreadsheetApp.getUi().alert(`✅ Review email sent to ${settings.Review_Email}`);
  } catch(e) {
    console.log(`Review email sent to ${settings.Review_Email}`);
  }
}

// ============= TRIGGERS =============

function setupTriggers() {
  ScriptApp.getProjectTriggers().forEach(trigger => {
    ScriptApp.deleteTrigger(trigger);
  });
  
  ScriptApp.newTrigger('sendReviewEmail')
    .timeBased()
    .atHour(7)
    .nearMinute(30)
    .everyDays(1)
    .create();
  
  ScriptApp.newTrigger('scrapeWebsites')
    .timeBased()
    .everyHours(1)
    .create();
  
  console.log('Triggers set up successfully');
}

// ============= PIPELINE =============

function runFullPipeline() {
  try {
    SpreadsheetApp.getUi().alert('Starting full pipeline...');
  } catch(e) {
    console.log('Starting full pipeline...');
  }
  
  scrapeWebsites();
  rewriteDescriptions();
  sendReviewEmail();
  
  try {
    SpreadsheetApp.getUi().alert('✅ Pipeline complete!');
  } catch(e) {
    console.log('Pipeline complete!');
  }
}

// ============= WEB APP ENDPOINTS =============

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
    
    const row = [
      data.name || '',
      generateSlug(data.name),
      data.studio || data.instructor || '',
      data.location || data.venue || '',
      data.address || '',
      data.date || data.event_date || '',
      data.time || '',
      data.price || '',
      '',  // Description (will be filled by rewrite)
      data.image_url || '',
      data.booking_url || data.book_link || '',
      data.tags || data.category || '',
      'Draft',
      'No',
      '',  // dynamic label
      data.original_caption || data.description || '',
      data.instagram_url || '',
      data.source || 'Instagram',
      data.event_images || '',
      '',  // attachment summary
      new Date().toISOString(),
      'Scraped',
      '',  // Quality score (will be calculated)
      ''   // Review notes
    ];
    
    sheet.appendRow(row);
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Event added successfully'
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet() {
  return ContentService.createTextOutput('Hobby Directory API is running');
}

// ============= STARTUP =============

function onOpen() {
  createCustomMenus();
}