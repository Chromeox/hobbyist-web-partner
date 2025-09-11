/**
 * Reset Rewrite Status for Testing
 * This allows you to reprocess events
 */

function resetRewriteStatus() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const headers = stagingSheet.getRange(1, 1, 1, stagingSheet.getLastColumn()).getValues()[0];
  const statusCol = headers.indexOf('Rewrite Status');
  
  if (statusCol === -1) {
    SpreadsheetApp.getUi().alert('Rewrite Status column not found');
    return;
  }
  
  // Get all data
  const numRows = stagingSheet.getLastRow();
  if (numRows <= 1) {
    SpreadsheetApp.getUi().alert('No data rows found');
    return;
  }
  
  // Clear all status values (except header)
  const range = stagingSheet.getRange(2, statusCol + 1, numRows - 1, 1);
  range.clear();
  
  SpreadsheetApp.getUi().alert(
    'Status Reset Complete',
    `Cleared ${numRows - 1} status values.\n\nYou can now run Gemini rewriting again.`,
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

/**
 * Add sample events for testing
 */
function addSampleEvents() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const sampleEvents = [
    {
      name: 'Pottery Workshop for Beginners',
      originalCaption: '🎨 Join us this Saturday for pottery class! Perfect for beginners, learn wheel throwing basics. Limited spots available! DM to book #pottery #vancouver #workshop',
      venue: 'Claymates Studio',
      date: '2025-09-15',
      time: '2:00 PM',
      price: '85'
    },
    {
      name: 'Morning Boxing Bootcamp',
      originalCaption: 'Start your day with a killer workout! 💪 Boxing bootcamp tomorrow 6:30am. All levels welcome. First class free! #boxing #fitness #vancouver',
      venue: 'Rumble Boxing',
      date: '2025-09-10',
      time: '6:30 AM',
      price: '35'
    },
    {
      name: 'Kids Art Workshop',
      originalCaption: 'Kids art workshop this weekend! 🎨 Ages 6-12, all materials included. Create your own masterpiece! Register at link in bio #kidsart #vancouver #weekend',
      venue: 'Maker Maker Studio',
      date: '2025-09-16',
      time: '10:00 AM',
      price: '45'
    }
  ];
  
  // Get headers
  const headers = stagingSheet.getRange(1, 1, 1, stagingSheet.getLastColumn()).getValues()[0];
  
  // Find column indices
  const cols = {
    name: headers.indexOf('name'),
    originalCaption: headers.indexOf('original caption'),
    venue: headers.indexOf('location'),
    date: headers.indexOf('Event Date'),
    time: headers.indexOf('Time'),
    price: headers.indexOf('price')
  };
  
  // Add sample events
  const lastRow = stagingSheet.getLastRow();
  
  sampleEvents.forEach((event, index) => {
    const row = lastRow + index + 1;
    
    if (cols.name !== -1) stagingSheet.getRange(row, cols.name + 1).setValue(event.name);
    if (cols.originalCaption !== -1) stagingSheet.getRange(row, cols.originalCaption + 1).setValue(event.originalCaption);
    if (cols.venue !== -1) stagingSheet.getRange(row, cols.venue + 1).setValue(event.venue);
    if (cols.date !== -1) stagingSheet.getRange(row, cols.date + 1).setValue(event.date);
    if (cols.time !== -1) stagingSheet.getRange(row, cols.time + 1).setValue(event.time);
    if (cols.price !== -1) stagingSheet.getRange(row, cols.price + 1).setValue(event.price);
  });
  
  SpreadsheetApp.getUi().alert(
    'Sample Events Added',
    `Added ${sampleEvents.length} sample events.\n\nYou can now run Gemini rewriting to process them.`,
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

/**
 * Check current status
 */
function checkStatus() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) {
    console.log('Events Staging sheet not found');
    return;
  }
  
  const data = stagingSheet.getDataRange().getValues();
  const headers = data[0];
  
  const captionCol = headers.indexOf('original caption');
  const statusCol = headers.indexOf('Rewrite Status');
  const descCol = headers.indexOf('Description');
  
  let stats = {
    total: 0,
    withCaption: 0,
    completed: 0,
    pending: 0,
    withDescription: 0
  };
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    stats.total++;
    
    if (row[captionCol] && row[captionCol].toString().trim()) {
      stats.withCaption++;
      
      if (statusCol !== -1 && row[statusCol] === 'Completed') {
        stats.completed++;
      } else {
        stats.pending++;
      }
      
      if (descCol !== -1 && row[descCol] && row[descCol].toString().trim()) {
        stats.withDescription++;
      }
    }
  }
  
  const message = `
📊 Current Sheet Status
======================
Total rows: ${stats.total}
With captions: ${stats.withCaption}
✅ Completed: ${stats.completed}
⏳ Pending: ${stats.pending}
📝 Have descriptions: ${stats.withDescription}

${stats.pending > 0 ? 
  `Ready to process ${stats.pending} events!` : 
  'No events to process. Add events or reset status.'}
`;
  
  SpreadsheetApp.getUi().alert('Status Report', message, SpreadsheetApp.getUi().ButtonSet.OK);
  console.log(message);
}

// Add menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔧 Reset Tools')
    .addItem('🔄 Reset All Statuses', 'resetRewriteStatus')
    .addItem('➕ Add Sample Events', 'addSampleEvents')
    .addItem('📊 Check Status', 'checkStatus')
    .addToUi();
}