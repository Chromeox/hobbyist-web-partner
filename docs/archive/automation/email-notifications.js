/**
 * Email Notification System for Hobby Directory
 * Sends email updates when scrapes complete
 */

// ============= CONFIGURATION =============

const EMAIL_CONFIG = {
  YOUR_EMAIL: Session.getActiveUser().getEmail(), // Your email
  SUBJECT_PREFIX: '🎯 Hobby Directory: ',
  SEND_SUMMARY: true,
  SEND_DAILY_DIGEST: true
};

// ============= NOTIFICATION FUNCTIONS =============

/**
 * Send notification after scrape completes
 */
function sendScrapeNotification(eventCount, source) {
  const email = EMAIL_CONFIG.YOUR_EMAIL;
  const now = new Date();
  const timeStr = Utilities.formatDate(now, 'PST', 'h:mm a');
  
  const subject = `${EMAIL_CONFIG.SUBJECT_PREFIX}${eventCount} New Events Found (${timeStr})`;
  
  const body = `
Hobby Directory Scrape Complete!
================================

Time: ${timeStr}
Source: ${source || 'Instagram Scraper'}
Events Found: ${eventCount}

Review Events:
https://docs.google.com/spreadsheets/d/${SpreadsheetApp.getActiveSpreadsheet().getId()}

Next Steps:
1. Review events in "Events Staging" tab
2. Gemini will rewrite descriptions at 7:45 AM
3. Move approved events to "Events Approved" tab

---
Automated by Hobby Directory Pipeline
  `;
  
  try {
    MailApp.sendEmail(email, subject, body);
    console.log('Notification sent to:', email);
  } catch (error) {
    console.error('Failed to send email:', error);
  }
}

/**
 * Daily summary email (runs at 8 AM)
 */
function sendDailySummary() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const stagingSheet = sheet.getSheetByName('Events Staging');
  
  if (!stagingSheet) return;
  
  const data = stagingSheet.getDataRange().getValues();
  const today = new Date();
  const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
  
  // Count events by status
  let stats = {
    total: 0,
    newToday: 0,
    pending: 0,
    completed: 0,
    needsReview: 0
  };
  
  const timestampCol = data[0].indexOf('Timestamp');
  const statusCol = data[0].indexOf('Rewrite Status');
  const confidenceCol = data[0].indexOf('confidence_score');
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    stats.total++;
    
    // Check if added today
    if (timestampCol !== -1 && row[timestampCol]) {
      const rowDate = new Date(row[timestampCol]);
      if (rowDate > yesterday) {
        stats.newToday++;
      }
    }
    
    // Check status
    if (statusCol !== -1) {
      if (row[statusCol] === 'Completed') {
        stats.completed++;
      } else {
        stats.pending++;
      }
    }
    
    // Check confidence
    if (confidenceCol !== -1 && row[confidenceCol]) {
      const confidence = parseFloat(row[confidenceCol]);
      if (confidence < 0.6) {
        stats.needsReview++;
      }
    }
  }
  
  const subject = `${EMAIL_CONFIG.SUBJECT_PREFIX}Daily Summary - ${stats.newToday} New Events`;
  
  const body = `
Good Morning! Here's your Hobby Directory summary:
==================================================

📊 Today's Stats:
- New Events (24h): ${stats.newToday}
- Total in Pipeline: ${stats.total}
- Rewritten by AI: ${stats.completed}
- Pending Review: ${stats.pending}
- Low Confidence: ${stats.needsReview}

📅 Today's Schedule:
- 7:45 AM - Gemini rewrites descriptions ✓
- 10:00 AM - Morning scrape scheduled
- 6:00 PM - Evening scrape scheduled

📋 Action Items:
${stats.pending > 0 ? '• Review ' + stats.pending + ' pending events' : '• No events need review'}
${stats.needsReview > 0 ? '• Check ' + stats.needsReview + ' low-confidence events' : ''}

Review Dashboard:
https://docs.google.com/spreadsheets/d/${sheet.getId()}

---
Have a productive day!
Hobby Directory Automation
  `;
  
  MailApp.sendEmail(EMAIL_CONFIG.YOUR_EMAIL, subject, body);
  console.log('Daily summary sent');
}

/**
 * Alert for high-value events (optional)
 */
function sendHighValueAlert(eventData) {
  // Send immediate alert for high-confidence, high-value events
  if (eventData.confidence_score >= 0.8) {
    const subject = `${EMAIL_CONFIG.SUBJECT_PREFIX}⭐ High-Value Event Detected`;
    
    const body = `
High-Confidence Event Found!
============================

Event: ${eventData.name}
Studio: ${eventData.studio}
Date: ${eventData.date}
Confidence: ${(eventData.confidence_score * 100).toFixed(0)}%

This event has been auto-approved for publishing.

View Event:
https://docs.google.com/spreadsheets/d/${SpreadsheetApp.getActiveSpreadsheet().getId()}
    `;
    
    MailApp.sendEmail(EMAIL_CONFIG.YOUR_EMAIL, subject, body);
  }
}

// ============= TRIGGERS =============

/**
 * Set up automated email triggers
 */
function setupEmailNotifications() {
  // Remove existing triggers
  ScriptApp.getProjectTriggers().forEach(trigger => {
    if (trigger.getHandlerFunction() === 'sendDailySummary') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  // Daily summary at 8 AM
  ScriptApp.newTrigger('sendDailySummary')
    .timeBased()
    .atHour(8)
    .everyDays(1)
    .create();
    
  console.log('Email notifications enabled');
  
  // Test with sample notification
  sendScrapeNotification(5, 'Test');
}

/**
 * Track when new events are added
 */
function onNewEvent() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events Staging');
  const lastRow = sheet.getLastRow();
  
  // Count events added in last 5 minutes
  const data = sheet.getDataRange().getValues();
  const timestampCol = data[0].indexOf('Timestamp');
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  
  let recentEvents = 0;
  
  for (let i = Math.max(1, lastRow - 20); i < data.length; i++) {
    if (data[i][timestampCol]) {
      const eventTime = new Date(data[i][timestampCol]);
      if (eventTime > fiveMinutesAgo) {
        recentEvents++;
      }
    }
  }
  
  if (recentEvents > 0) {
    sendScrapeNotification(recentEvents, 'Instagram Scraper');
  }
}

// Menu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('📧 Notifications')
    .addItem('Enable Email Notifications', 'setupEmailNotifications')
    .addItem('Send Test Email', 'testEmailNotification')
    .addItem('Send Daily Summary Now', 'sendDailySummary')
    .addToUi();
}

function testEmailNotification() {
  sendScrapeNotification(3, 'Test Scrape');
  SpreadsheetApp.getUi().alert('Test email sent to: ' + EMAIL_CONFIG.YOUR_EMAIL);
}