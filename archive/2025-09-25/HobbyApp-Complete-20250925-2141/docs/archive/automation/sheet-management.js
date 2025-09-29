/**
 * Google Sheets Management Script
 * For clearing test data and managing your event pipeline
 * 
 * Add this to your Google Apps Script (same place as doPost)
 */

// ============= CLEAR TEST DATA =============
function clearTestData() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  // Get all data
  const lastRow = sheet.getLastRow();
  
  if (lastRow <= 1) {
    SpreadsheetApp.getUi().alert('No data to clear (only headers present)');
    return;
  }
  
  // Archive data before clearing (optional)
  const archiveSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Archive');
  if (archiveSheet) {
    const dataToArchive = sheet.getRange(2, 1, lastRow - 1, sheet.getLastColumn()).getValues();
    const timestamp = new Date();
    
    // Add timestamp to each row
    dataToArchive.forEach(row => row.push(timestamp));
    
    // Append to archive
    if (dataToArchive.length > 0) {
      archiveSheet.getRange(
        archiveSheet.getLastRow() + 1, 
        1, 
        dataToArchive.length, 
        dataToArchive[0].length
      ).setValues(dataToArchive);
    }
  }
  
  // Clear all data except headers
  sheet.getRange(2, 1, lastRow - 1, sheet.getLastColumn()).clear();
  
  SpreadsheetApp.getUi().alert(
    '✅ Data Cleared',
    `Removed ${lastRow - 1} rows from Events Staging${archiveSheet ? '\nData archived to Archive sheet' : ''}`,
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

// ============= REMOVE DUPLICATES =============
function removeDuplicates() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const uniqueRows = [];
  const seen = new Set();
  
  // Skip header row
  uniqueRows.push(headers);
  
  // Find duplicates based on name + date + studio
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const key = `${row[0]}_${row[5]}_${row[2]}`; // name_date_studio
    
    if (!seen.has(key)) {
      seen.add(key);
      uniqueRows.push(row);
    }
  }
  
  const duplicatesRemoved = data.length - uniqueRows.length;
  
  if (duplicatesRemoved > 0) {
    // Clear sheet and write unique rows
    sheet.clear();
    sheet.getRange(1, 1, uniqueRows.length, uniqueRows[0].length).setValues(uniqueRows);
    
    // Reapply formatting to headers
    const headerRange = sheet.getRange(1, 1, 1, headers.length);
    headerRange.setBackground('#4285f4');
    headerRange.setFontColor('#ffffff');
    headerRange.setFontWeight('bold');
    
    SpreadsheetApp.getUi().alert(`✅ Removed ${duplicatesRemoved} duplicate rows`);
  } else {
    SpreadsheetApp.getUi().alert('No duplicates found');
  }
}

// ============= CLEAR OLD EVENTS =============
function clearOldEvents() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    SpreadsheetApp.getUi().alert('Events Staging sheet not found');
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const rowsToKeep = [data[0]]; // Keep headers
  let removedCount = 0;
  
  // Check each row
  for (let i = 1; i < data.length; i++) {
    const eventDate = new Date(data[i][5]); // Event Date column
    
    if (eventDate >= today || isNaN(eventDate.getTime())) {
      rowsToKeep.push(data[i]); // Keep future events and invalid dates
    } else {
      removedCount++;
    }
  }
  
  if (removedCount > 0) {
    // Clear and rewrite
    sheet.clear();
    sheet.getRange(1, 1, rowsToKeep.length, rowsToKeep[0].length).setValues(rowsToKeep);
    
    // Reformat headers
    const headerRange = sheet.getRange(1, 1, 1, data[0].length);
    headerRange.setBackground('#4285f4');
    headerRange.setFontColor('#ffffff');
    headerRange.setFontWeight('bold');
    
    SpreadsheetApp.getUi().alert(`✅ Removed ${removedCount} past events`);
  } else {
    SpreadsheetApp.getUi().alert('No old events to remove');
  }
}

// ============= CREATE ARCHIVE SHEET =============
function createArchiveSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let archiveSheet = ss.getSheetByName('Archive');
  
  if (archiveSheet) {
    SpreadsheetApp.getUi().alert('Archive sheet already exists');
    return;
  }
  
  // Create archive sheet
  archiveSheet = ss.insertSheet('Archive');
  
  // Copy headers from Events Staging
  const mainSheet = ss.getSheetByName('Events Staging');
  const headers = mainSheet.getRange(1, 1, 1, mainSheet.getLastColumn()).getValues()[0];
  headers.push('Archived At'); // Add archive timestamp
  
  // Set headers
  archiveSheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  
  // Format headers
  const headerRange = archiveSheet.getRange(1, 1, 1, headers.length);
  headerRange.setBackground('#666666');
  headerRange.setFontColor('#ffffff');
  headerRange.setFontWeight('bold');
  
  SpreadsheetApp.getUi().alert('✅ Archive sheet created');
}

// ============= DAILY SUMMARY =============
function getDailySummary() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  
  if (!sheet) {
    return 'Events Staging sheet not found';
  }
  
  const data = sheet.getDataRange().getValues();
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  let todayCount = 0;
  let weekCount = 0;
  let totalCount = data.length - 1; // Exclude header
  
  const studios = {};
  const sources = {};
  
  // Analyze data
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const scrapedAt = new Date(row[22]); // Scraped At column
    const studio = row[2]; // Studio column
    const source = row[17]; // Source column
    
    // Count by scrape date
    if (scrapedAt.toDateString() === today.toDateString()) {
      todayCount++;
    }
    
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);
    if (scrapedAt >= weekAgo) {
      weekCount++;
    }
    
    // Count by studio
    studios[studio] = (studios[studio] || 0) + 1;
    
    // Count by source
    sources[source] = (sources[source] || 0) + 1;
  }
  
  // Build summary
  let summary = '📊 EVENT PIPELINE SUMMARY\n';
  summary += '=====================================\n\n';
  summary += `📅 Today's Events: ${todayCount}\n`;
  summary += `📅 This Week: ${weekCount}\n`;
  summary += `📅 Total Events: ${totalCount}\n\n`;
  
  summary += '🏢 Top Studios:\n';
  const topStudios = Object.entries(studios)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  topStudios.forEach(([studio, count]) => {
    summary += `  • ${studio}: ${count} events\n`;
  });
  
  summary += '\n📱 Sources:\n';
  Object.entries(sources).forEach(([source, count]) => {
    summary += `  • ${source}: ${count} events\n`;
  });
  
  return summary;
}

// ============= MENU =============
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🧹 Data Management')
    .addItem('🗑️ Clear All Test Data', 'clearTestData')
    .addItem('🔄 Remove Duplicates', 'removeDuplicates')
    .addItem('📅 Clear Old Events', 'clearOldEvents')
    .addItem('📦 Create Archive Sheet', 'createArchiveSheet')
    .addSeparator()
    .addItem('📊 Show Daily Summary', 'showDailySummary')
    .addToUi();
}

function showDailySummary() {
  const summary = getDailySummary();
  SpreadsheetApp.getUi().alert('Daily Summary', summary, SpreadsheetApp.getUi().ButtonSet.OK);
}