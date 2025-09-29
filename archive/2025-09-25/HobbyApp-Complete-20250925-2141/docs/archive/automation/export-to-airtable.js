/**
 * Export Google Sheets Events to CSV for Airtable Import
 * 
 * This script exports approved events from Google Sheets
 * to a CSV file formatted for Airtable import
 */

const fs = require('fs');
const path = require('path');

// ============= CONFIGURATION =============

const CONFIG = {
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  SHEETS_API_URL: 'https://sheets.googleapis.com/v4/spreadsheets',
  
  // Google Sheets service account key (if using API)
  // For now, we'll export manually from Sheets UI
};

// ============= AIRTABLE FIELD MAPPING =============

const AIRTABLE_FIELDS = [
  'name',           // Event name
  'slug',           // URL slug (auto-generated)
  'studio',         // Studio/Organization name
  'location',       // Venue name
  'address',        // Full address
  'Event Date',     // Date in YYYY-MM-DD format
  'Time',           // Time in HH:MM format
  'price',          // Price (number or text)
  'Description',    // Event description
  'Image URL',      // Main image URL
  'Book Link',      // Booking/registration link
  'Tags',           // Comma-separated tags
  'Webflow status', // Published/Draft
  'Sync to webflow',// Yes/No
  'dynamic label',  // Event label
  'original caption', // Original Instagram caption
  'instagram URL',  // Link to Instagram post
  'Source',         // Data source (Instagram, Manual, etc.)
  'Event Images',   // Additional image URLs
  'attachment summary' // Summary of attachments
];

// ============= CSV GENERATOR =============

class AirtableExporter {
  constructor() {
    this.events = [];
    this.outputDir = path.join(__dirname, 'airtable-exports');
  }

  /**
   * Load events from JSON file (exported from Google Sheets)
   */
  loadEventsFromJSON(filePath) {
    try {
      const data = fs.readFileSync(filePath, 'utf8');
      const jsonData = JSON.parse(data);
      this.events = jsonData.events || jsonData;
      console.log(`✅ Loaded ${this.events.length} events from JSON`);
      return true;
    } catch (error) {
      console.error('❌ Error loading JSON:', error.message);
      return false;
    }
  }

  /**
   * Transform event data to match Airtable fields
   */
  transformEvent(event) {
    return {
      'name': event.name || '',
      'slug': this.generateSlug(event.name),
      'studio': event.studio || '',
      'location': event.location || event.venue || '',
      'address': event.address || '',
      'Event Date': this.formatDate(event.date),
      'Time': this.formatTime(event.time),
      'price': event.price ? `$${event.price}` : '',
      'Description': event.description || this.cleanDescription(event.original_caption),
      'Image URL': event.image_url || '',
      'Book Link': event.booking_url || event.website_url || '',
      'Tags': event.tags || '',
      'Webflow status': 'Draft', // Start as draft
      'Sync to webflow': 'No',   // Manual approval required
      'dynamic label': this.generateLabel(event),
      'original caption': event.original_caption || '',
      'instagram URL': event.instagram_url || '',
      'Source': event.source || 'Instagram',
      'Event Images': event.additional_images || '',
      'attachment summary': event.image_url ? '1 image' : ''
    };
  }

  /**
   * Generate URL-friendly slug
   */
  generateSlug(name) {
    if (!name) return '';
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .substring(0, 50);
  }

  /**
   * Format date for Airtable (YYYY-MM-DD)
   */
  formatDate(dateStr) {
    if (!dateStr) return '';
    
    try {
      const date = new Date(dateStr);
      if (isNaN(date.getTime())) return dateStr;
      
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      
      return `${year}-${month}-${day}`;
    } catch {
      return dateStr;
    }
  }

  /**
   * Format time for Airtable (HH:MM)
   */
  formatTime(timeStr) {
    if (!timeStr) return '';
    
    // Already in HH:MM format
    if (/^\d{2}:\d{2}$/.test(timeStr)) {
      return timeStr;
    }
    
    // Convert from 12-hour format
    const match = timeStr.match(/(\d{1,2}):?(\d{2})?\s*(am|pm)/i);
    if (match) {
      let hour = parseInt(match[1]);
      const minutes = match[2] || '00';
      const ampm = match[3].toLowerCase();
      
      if (ampm === 'pm' && hour !== 12) {
        hour += 12;
      } else if (ampm === 'am' && hour === 12) {
        hour = 0;
      }
      
      return `${hour.toString().padStart(2, '0')}:${minutes}`;
    }
    
    return timeStr;
  }

  /**
   * Generate event label (e.g., "New", "This Week", etc.)
   */
  generateLabel(event) {
    if (!event.date) return '';
    
    const eventDate = new Date(event.date);
    const today = new Date();
    const daysDiff = Math.floor((eventDate - today) / (1000 * 60 * 60 * 24));
    
    if (daysDiff < 0) return 'Past';
    if (daysDiff === 0) return 'Today';
    if (daysDiff === 1) return 'Tomorrow';
    if (daysDiff <= 7) return 'This Week';
    if (daysDiff <= 14) return 'Next Week';
    
    return 'Upcoming';
  }

  /**
   * Clean description text
   */
  cleanDescription(text) {
    if (!text) return '';
    
    return text
      .replace(/#\w+/g, '')        // Remove hashtags
      .replace(/\s+/g, ' ')         // Normalize spaces
      .replace(/\n{3,}/g, '\n\n')   // Limit newlines
      .trim()
      .substring(0, 500);           // Limit length
  }

  /**
   * Convert events to CSV format
   */
  exportToCSV(filename = null) {
    if (this.events.length === 0) {
      console.log('❌ No events to export');
      return false;
    }
    
    // Create output directory
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
    
    // Generate filename
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const outputFile = filename || `airtable-import-${timestamp}.csv`;
    const outputPath = path.join(this.outputDir, outputFile);
    
    // Transform events
    const transformedEvents = this.events.map(event => this.transformEvent(event));
    
    // Create CSV header
    const header = AIRTABLE_FIELDS.join(',');
    
    // Create CSV rows
    const rows = transformedEvents.map(event => {
      return AIRTABLE_FIELDS.map(field => {
        const value = event[field] || '';
        // Escape values containing commas or quotes
        if (value.includes(',') || value.includes('"') || value.includes('\n')) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value;
      }).join(',');
    });
    
    // Combine header and rows
    const csvContent = [header, ...rows].join('\n');
    
    // Write to file
    fs.writeFileSync(outputPath, csvContent, 'utf8');
    
    console.log(`\n✅ CSV Export Complete!`);
    console.log(`📁 File: ${outputPath}`);
    console.log(`📊 Events exported: ${transformedEvents.length}`);
    console.log(`\n📋 Next Steps:`);
    console.log(`1. Open Airtable and go to your Events table`);
    console.log(`2. Click the "..." menu → "Import data" → "CSV file"`);
    console.log(`3. Upload the exported CSV file`);
    console.log(`4. Map the fields (they should auto-match)`);
    console.log(`5. Click "Import" to add the events`);
    
    return outputPath;
  }

  /**
   * Generate sample data for testing
   */
  generateSampleData() {
    this.events = [
      {
        name: 'Pottery Workshop for Beginners',
        studio: 'Claymates Studio',
        location: 'Claymates Ceramic Studio',
        address: '3071 Main St, Vancouver, BC',
        date: '2025-09-15',
        time: '18:30',
        price: '85',
        description: 'Learn the basics of wheel throwing in this beginner-friendly workshop.',
        image_url: 'https://example.com/pottery.jpg',
        tags: 'pottery, workshop, beginner-friendly',
        source: 'Instagram',
        instagram_url: 'https://instagram.com/p/abc123',
        original_caption: 'Join us for a fun pottery workshop! Perfect for beginners.'
      },
      {
        name: 'Boxing Bootcamp',
        studio: 'Rumble Boxing',
        location: 'Rumble Boxing Mount Pleasant',
        address: '2935 Main St, Vancouver, BC',
        date: '2025-09-10',
        time: '06:30',
        price: '35',
        description: 'High-intensity boxing workout to start your day.',
        image_url: 'https://example.com/boxing.jpg',
        tags: 'fitness, boxing, bootcamp',
        source: 'Instagram',
        instagram_url: 'https://instagram.com/p/def456',
        original_caption: 'Early morning boxing bootcamp! Limited spots available.'
      }
    ];
    
    console.log(`✅ Generated ${this.events.length} sample events`);
  }
}

// ============= MAIN EXECUTION =============

async function main() {
  console.log('🎯 Airtable CSV Exporter');
  console.log('========================\n');
  
  const exporter = new AirtableExporter();
  
  // Get command line arguments
  const args = process.argv.slice(2);
  
  if (args[0] === 'sample') {
    // Generate sample data for testing
    exporter.generateSampleData();
    exporter.exportToCSV('sample-events.csv');
  } else if (args[0]) {
    // Load from JSON file
    if (exporter.loadEventsFromJSON(args[0])) {
      exporter.exportToCSV();
    }
  } else {
    console.log('📝 Usage:');
    console.log('  node export-to-airtable.js <json-file>  # Export from JSON');
    console.log('  node export-to-airtable.js sample       # Generate sample CSV\n');
    
    console.log('💡 To export from Google Sheets:');
    console.log('1. Open your Google Sheet');
    console.log('2. Go to "Events Approved" tab');
    console.log('3. File → Download → Comma-separated values (.csv)');
    console.log('4. Or use the "Export for Airtable" button in the menu\n');
    
    // Generate sample for demonstration
    console.log('Generating sample CSV for demonstration...\n');
    exporter.generateSampleData();
    exporter.exportToCSV('sample-events.csv');
  }
}

// Run the exporter
main();