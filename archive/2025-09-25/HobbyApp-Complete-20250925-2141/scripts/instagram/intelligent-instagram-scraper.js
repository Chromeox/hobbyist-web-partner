/**
 * Intelligent Instagram Event Scraper
 * Version 2.0 - With Smart Event Detection
 * 
 * This version only creates events from posts that are actually events,
 * not every single Instagram post.
 */

const { chromium } = require('playwright');

// ============= CONFIGURATION =============

const CONFIG = {
  // Your Google Sheets Web App URL
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  
  // Browser settings
  HEADLESS: true,
  RATE_LIMIT: 2000, // ms between requests
  
  // Event detection thresholds
  MIN_EVENT_INDICATORS: 2, // Minimum indicators to consider a post an event
  MIN_CONFIDENCE_SCORE: 0.6, // Minimum confidence to auto-import
};

// ============= ACCOUNT PROFILES =============
// These help provide context for better event extraction

const ACCOUNT_PROFILES = {
  '@rumbleboxingmp': {
    name: 'Rumble Boxing Mount Pleasant',
    defaultVenue: 'Rumble Boxing Mount Pleasant', 
    defaultAddress: '2935 Main St, Vancouver, BC V5T 3G5',
    defaultStudio: 'Rumble Boxing',
    eventKeywords: ['class', 'boxing', 'workout', 'bootcamp', 'session', 'training', 'rumble', 'sweat', 'fight'],
    pricePatterns: ['drop-in', 'class pass', '$35', '$40', 'first class free'],
    typicalPrices: { min: 30, max: 45, default: 35 },
    schedule: {
      weekdays: ['6:30 AM', '12:00 PM', '5:30 PM', '6:30 PM', '7:30 PM'],
      weekends: ['9:00 AM', '10:30 AM', '12:00 PM']
    },
    websiteUrl: 'https://www.rumbleboxing.com/locations/mount-pleasant',
    bookingUrl: 'https://www.rumbleboxing.com/book'
  },
  '@claymates.studio': {
    name: 'Claymates Ceramic Studio',
    defaultVenue: 'Claymates Ceramic Studio',
    defaultAddress: '3071 Main St, Vancouver, BC V5V 3P1', 
    defaultStudio: 'Claymates Studio',
    eventKeywords: ['workshop', 'class', 'pottery', 'ceramic', 'wheel throwing', 'hand building', 'glazing', 'clay', 'studio'],
    pricePatterns: ['workshop', 'class', '$75', '$85', '$95', 'per person'],
    typicalPrices: { min: 65, max: 125, default: 85 },
    schedule: {
      weekdays: ['6:00 PM', '6:30 PM', '7:00 PM'],
      weekends: ['10:00 AM', '1:00 PM', '2:00 PM', '4:00 PM']
    },
    websiteUrl: 'https://claymatesceramicsstudio.com',
    bookingUrl: 'https://claymatesceramicsstudio.com/book'
  },
  '@pottersnook': {
    name: "Potter's Nook Studio",
    defaultVenue: "Potter's Nook",
    defaultAddress: 'Vancouver, BC',
    defaultStudio: "Potter's Nook",
    eventKeywords: ['pottery', 'ceramics', 'class', 'workshop', 'clay', 'wheel', 'handbuilding'],
    pricePatterns: ['$60', '$70', '$80', 'drop-in'],
    typicalPrices: { min: 60, max: 90, default: 70 },
    schedule: {
      weekdays: ['6:00 PM', '7:30 PM'],
      weekends: ['11:00 AM', '2:00 PM']
    }
  },
  '@f45_vancouver': {
    name: 'F45 Training Vancouver',
    defaultVenue: 'F45 Training',
    defaultAddress: 'Vancouver, BC',
    defaultStudio: 'F45 Training',
    eventKeywords: ['training', 'workout', 'hiit', 'class', 'fitness', 'challenge', 'sweat'],
    pricePatterns: ['trial', 'free', '$25', '$30'],
    typicalPrices: { min: 25, max: 35, default: 30 },
    schedule: {
      weekdays: ['6:00 AM', '7:00 AM', '12:00 PM', '5:30 PM', '6:30 PM'],
      weekends: ['8:00 AM', '9:00 AM', '10:00 AM']
    }
  },
  '@makermakervancouver': {
    name: 'Maker Maker Vancouver',
    defaultVenue: 'Maker Maker Studio',
    defaultAddress: 'Vancouver, BC',
    defaultStudio: 'Maker Maker',
    eventKeywords: ['workshop', 'craft', 'diy', 'making', 'class', 'create', 'art'],
    pricePatterns: ['$45', '$55', '$65', 'materials included'],
    typicalPrices: { min: 45, max: 75, default: 55 },
    schedule: {
      weekdays: ['6:30 PM'],
      weekends: ['11:00 AM', '2:00 PM', '4:00 PM']
    }
  },
  
  // === NEW VANCOUVER ACCOUNTS ADDED ===
  
  // Yoga & Wellness
  '@yyoga': {
    name: 'YYoga',
    defaultVenue: 'YYoga Studios',
    defaultAddress: '2110 West 4th Ave, Vancouver, BC V6K 1N6',
    defaultStudio: 'YYoga',
    eventKeywords: ['yoga', 'flow', 'class', 'meditation', 'workshop', 'retreat', 'practice'],
    pricePatterns: ['$20', '$25', '$30', 'drop-in'],
    typicalPrices: { min: 20, max: 35, default: 25 },
    schedule: {
      weekdays: ['6:00 AM', '9:00 AM', '12:00 PM', '5:30 PM', '7:30 PM'],
      weekends: ['8:00 AM', '10:00 AM', '4:00 PM']
    }
  },
  
  '@choprayogacenter': {
    name: 'Chopra Yoga Center',
    defaultVenue: 'Chopra Yoga Center',
    defaultAddress: '1409 West Pender St, Vancouver, BC V6G 2S3',
    defaultStudio: 'Chopra Yoga',
    eventKeywords: ['yoga', 'meditation', 'mindfulness', 'healing', 'workshop'],
    pricePatterns: ['$18', '$22', '$25'],
    typicalPrices: { min: 18, max: 30, default: 22 },
    schedule: {
      weekdays: ['7:00 AM', '12:15 PM', '5:45 PM'],
      weekends: ['9:00 AM', '11:00 AM']
    }
  },
  
  // Dance Studios
  '@harbordance': {
    name: 'Harbour Dance Centre',
    defaultVenue: 'Harbour Dance Centre',
    defaultAddress: '927 Granville St, Vancouver, BC V6Z 1L3',
    defaultStudio: 'Harbour Dance',
    eventKeywords: ['dance', 'class', 'hip hop', 'ballet', 'contemporary', 'workshop', 'drop-in'],
    pricePatterns: ['$18', '$20', '$22', 'drop-in'],
    typicalPrices: { min: 18, max: 25, default: 20 },
    schedule: {
      weekdays: ['10:00 AM', '6:00 PM', '7:30 PM', '9:00 PM'],
      weekends: ['11:00 AM', '1:00 PM', '3:00 PM']
    }
  },
  
  '@vancoeverdance': {
    name: 'Vancouver Dance Club',
    defaultVenue: 'Vancouver Dance Club',
    defaultAddress: 'Vancouver, BC',
    defaultStudio: 'Vancouver Dance Club',
    eventKeywords: ['salsa', 'bachata', 'dance', 'social', 'lesson', 'party'],
    pricePatterns: ['$15', '$20', 'free intro'],
    typicalPrices: { min: 15, max: 25, default: 20 },
    schedule: {
      weekdays: ['7:00 PM', '8:30 PM'],
      weekends: ['8:00 PM', '10:00 PM']
    }
  },
  
  // Fitness Studios
  '@barrefitvancouver': {
    name: 'Barre Fitness Vancouver',
    defaultVenue: 'Barre Fitness',
    defaultAddress: '1275 West 6th Ave, Vancouver, BC V6H 1A6',
    defaultStudio: 'Barre Fitness',
    eventKeywords: ['barre', 'fitness', 'class', 'workout', 'pilates', 'strength'],
    pricePatterns: ['$25', '$30', 'first class $10'],
    typicalPrices: { min: 25, max: 35, default: 30 },
    schedule: {
      weekdays: ['6:30 AM', '9:00 AM', '5:30 PM', '6:30 PM'],
      weekends: ['9:00 AM', '10:30 AM']
    }
  },
  
  '@spinco_vancouver': {
    name: 'Spin Co Vancouver',
    defaultVenue: 'Spin Co',
    defaultAddress: '555 Richards St, Vancouver, BC V6B 2Z5',
    defaultStudio: 'Spin Co',
    eventKeywords: ['spin', 'cycling', 'class', 'workout', 'cardio', 'music'],
    pricePatterns: ['$28', '$32', 'first ride $20'],
    typicalPrices: { min: 28, max: 35, default: 32 },
    schedule: {
      weekdays: ['6:00 AM', '7:00 AM', '12:00 PM', '5:30 PM', '6:30 PM'],
      weekends: ['8:30 AM', '10:00 AM', '11:30 AM']
    }
  },
  
  // Art & Craft Studios
  '@4cats_vancouver': {
    name: '4Cats Arts Studio',
    defaultVenue: '4Cats Arts Studio',
    defaultAddress: 'Multiple locations in Vancouver',
    defaultStudio: '4Cats Arts',
    eventKeywords: ['art', 'kids', 'painting', 'camp', 'workshop', 'birthday', 'class'],
    pricePatterns: ['$25', '$35', '$45'],
    typicalPrices: { min: 25, max: 50, default: 35 },
    schedule: {
      weekdays: ['3:30 PM', '4:30 PM'],
      weekends: ['10:00 AM', '1:00 PM', '3:00 PM']
    }
  },
  
  '@paintnitevancouver': {
    name: 'Paint Nite Vancouver',
    defaultVenue: 'Various Venues',
    defaultAddress: 'Vancouver, BC',
    defaultStudio: 'Paint Nite',
    eventKeywords: ['paint', 'night', 'art', 'wine', 'social', 'painting', 'party'],
    pricePatterns: ['$39', '$45', '$48'],
    typicalPrices: { min: 39, max: 55, default: 45 },
    schedule: {
      weekdays: ['7:00 PM'],
      weekends: ['2:00 PM', '7:00 PM']
    }
  },
  
  // Cooking Classes
  '@dirtykitchenvancouver': {
    name: 'Dirty Kitchen Vancouver',
    defaultVenue: 'Dirty Kitchen',
    defaultAddress: '540 Beatty St, Vancouver, BC V6B 2L3',
    defaultStudio: 'Dirty Kitchen',
    eventKeywords: ['cooking', 'class', 'culinary', 'chef', 'workshop', 'food', 'kitchen'],
    pricePatterns: ['$95', '$110', '$125'],
    typicalPrices: { min: 95, max: 150, default: 110 },
    schedule: {
      weekdays: ['6:30 PM'],
      weekends: ['11:00 AM', '3:00 PM', '6:30 PM']
    }
  },
  
  '@cookculture_vancouver': {
    name: 'Cook Culture',
    defaultVenue: 'Cook Culture',
    defaultAddress: '377 West 8th Ave, Vancouver, BC V5Y 3X4',
    defaultStudio: 'Cook Culture',
    eventKeywords: ['cooking', 'class', 'workshop', 'culinary', 'kitchen', 'chef'],
    pricePatterns: ['$75', '$85', '$95'],
    typicalPrices: { min: 75, max: 120, default: 85 },
    schedule: {
      weekdays: ['6:00 PM'],
      weekends: ['11:00 AM', '2:00 PM']
    }
  }
};

// ============= EVENT DETECTION PATTERNS =============

const EVENT_PATTERNS = {
  // Date patterns
  datePatterns: [
    /january \d{1,2}/i,
    /february \d{1,2}/i,
    /march \d{1,2}/i,
    /april \d{1,2}/i,
    /may \d{1,2}/i,
    /june \d{1,2}/i,
    /july \d{1,2}/i,
    /august \d{1,2}/i,
    /september \d{1,2}/i,
    /october \d{1,2}/i,
    /november \d{1,2}/i,
    /december \d{1,2}/i,
    /\d{1,2}\/\d{1,2}/,
    /this saturday/i,
    /this sunday/i,
    /tomorrow/i,
    /tonight/i,
    /this week/i,
    /next week/i
  ],
  
  // Time patterns
  timePatterns: [
    /\d{1,2}:\d{2}\s*(am|pm)/i,
    /\d{1,2}\s*(am|pm)/i,
    /morning class/i,
    /evening class/i,
    /afternoon/i,
    /noon/i
  ],
  
  // Price patterns
  pricePatterns: [
    /\$\d+/,
    /\d+\s*dollars/i,
    /drop[\s-]?in/i,
    /free/i,
    /by donation/i
  ],
  
  // Booking/registration patterns
  bookingPatterns: [
    /register/i,
    /book now/i,
    /sign up/i,
    /reserve/i,
    /limited spots/i,
    /spots available/i,
    /link in bio/i,
    /dm to book/i,
    /almost full/i,
    /last chance/i,
    /few spots/i
  ],
  
  // Event type keywords
  eventKeywords: [
    /workshop/i,
    /class/i,
    /session/i,
    /event/i,
    /bootcamp/i,
    /training/i,
    /meetup/i,
    /gathering/i,
    /lesson/i
  ]
};

// ============= SMART SCRAPER CLASS =============

class IntelligentInstagramScraper {
  constructor() {
    this.browser = null;
    this.eventsFound = [];
    this.postsAnalyzed = 0;
  }

  async initialize() {
    console.log('🚀 Starting Intelligent Instagram Scraper v2.0');
    this.browser = await chromium.launch({
      headless: CONFIG.HEADLESS,
      slowMo: CONFIG.HEADLESS ? 0 : 50,
    });
    console.log('✅ Browser launched');
  }

  async scrapeAccount(username) {
    const page = await this.browser.newPage();
    const profile = ACCOUNT_PROFILES[username] || this.createDefaultProfile(username);
    
    try {
      username = username.replace('@', '');
      console.log(`\n📸 Analyzing @${username} for events...`);
      
      // Navigate to Instagram
      await page.goto(`https://www.instagram.com/${username}/`, {
        waitUntil: 'networkidle',
        timeout: 30000,
      });
      
      await page.waitForTimeout(2000);
      
      // Check if page exists
      const pageTitle = await page.title();
      if (pageTitle.includes('Page Not Found')) {
        console.log(`❌ Profile @${username} not found`);
        await page.close();
        return [];
      }
      
      // Get profile info
      const profileData = await this.extractProfileData(page);
      console.log(`  ✓ Profile: ${profileData.followerCount} followers`);
      
      // Get recent posts
      const posts = await this.extractPosts(page);
      console.log(`  ✓ Found ${posts.length} recent posts to analyze`);
      
      // Analyze posts for events
      const events = await this.identifyEvents(posts, profile, profileData);
      console.log(`  ✓ Identified ${events.length} actual events from ${posts.length} posts`);
      
      await page.close();
      return events;
      
    } catch (error) {
      console.error(`❌ Error scraping @${username}:`, error.message);
      await page.close();
      return [];
    }
  }

  async extractProfileData(page) {
    return await page.evaluate(() => {
      const getTextContent = (selector) => {
        const element = document.querySelector(selector);
        return element ? element.textContent.trim() : '';
      };
      
      return {
        bio: getTextContent('div.-vDIg > span'),
        followerCount: getTextContent('[title*="followers"]') || 
                      document.querySelector('a[href*="/followers/"] span')?.textContent || '0',
        websiteUrl: document.querySelector('a[rel="me"]')?.href || '',
        isVerified: !!document.querySelector('[aria-label="Verified"]')
      };
    });
  }

  async extractPosts(page) {
    return await page.evaluate(() => {
      const posts = [];
      const postElements = document.querySelectorAll('article a[href*="/p/"]');
      
      // Get up to 12 recent posts
      for (let i = 0; i < Math.min(12, postElements.length); i++) {
        const post = postElements[i];
        const img = post.querySelector('img');
        
        if (img) {
          // Extract post date if visible
          const timeElement = post.closest('article')?.querySelector('time');
          
          posts.push({
            url: post.href,
            imageUrl: img.src,
            caption: img.alt || '',
            timestamp: timeElement?.getAttribute('datetime') || new Date().toISOString(),
            postIndex: i
          });
        }
      }
      
      return posts;
    });
  }

  async identifyEvents(posts, profile, profileData) {
    const events = [];
    const processedEvents = new Set(); // For deduplication
    
    for (const post of posts) {
      this.postsAnalyzed++;
      
      // Calculate event indicators
      const analysis = this.analyzePost(post, profile);
      
      console.log(`    Post ${post.postIndex + 1}: ${analysis.indicators} indicators, ${(analysis.confidence * 100).toFixed(0)}% confidence`);
      
      // Only process if enough indicators
      if (analysis.indicators >= CONFIG.MIN_EVENT_INDICATORS) {
        const eventData = this.extractEventData(post, profile, profileData, analysis);
        
        // Create unique key for deduplication
        const eventKey = `${eventData.date}-${eventData.time}-${eventData.venue}`.toLowerCase();
        
        if (!processedEvents.has(eventKey)) {
          processedEvents.add(eventKey);
          events.push(eventData);
          console.log(`      ✓ Event detected: ${eventData.name}`);
        } else {
          console.log(`      ⚠️ Duplicate event skipped`);
        }
      }
    }
    
    return events;
  }

  analyzePost(post, profile) {
    const caption = post.caption.toLowerCase();
    let indicators = 0;
    let confidence = 0;
    const foundIndicators = [];
    
    // Check for date patterns
    if (this.hasPattern(caption, EVENT_PATTERNS.datePatterns)) {
      indicators++;
      confidence += 0.25;
      foundIndicators.push('date');
    }
    
    // Check for time patterns
    if (this.hasPattern(caption, EVENT_PATTERNS.timePatterns)) {
      indicators++;
      confidence += 0.2;
      foundIndicators.push('time');
    }
    
    // Check for price patterns
    if (this.hasPattern(caption, EVENT_PATTERNS.pricePatterns)) {
      indicators++;
      confidence += 0.15;
      foundIndicators.push('price');
    }
    
    // Check for booking language
    if (this.hasPattern(caption, EVENT_PATTERNS.bookingPatterns)) {
      indicators++;
      confidence += 0.25;
      foundIndicators.push('booking');
    }
    
    // Check for event keywords
    if (this.hasPattern(caption, EVENT_PATTERNS.eventKeywords)) {
      indicators++;
      confidence += 0.15;
      foundIndicators.push('event-keyword');
    }
    
    // Check for profile-specific keywords
    const profileKeywords = profile.eventKeywords || [];
    if (profileKeywords.some(keyword => caption.includes(keyword))) {
      indicators++;
      confidence += 0.1;
      foundIndicators.push('profile-keyword');
    }
    
    return {
      indicators,
      confidence: Math.min(confidence, 1),
      foundIndicators
    };
  }

  hasPattern(text, patterns) {
    return patterns.some(pattern => {
      if (pattern instanceof RegExp) {
        return pattern.test(text);
      } else {
        return text.includes(pattern);
      }
    });
  }

  extractEventData(post, profile, profileData, analysis) {
    const caption = post.caption;
    
    // Extract date
    let eventDate = this.extractDate(caption, post.timestamp);
    
    // Extract time
    let eventTime = this.extractTime(caption, profile);
    
    // Extract price
    let price = this.extractPrice(caption, profile);
    
    // Generate event name
    let eventName = this.generateEventName(caption, profile, eventDate);
    
    // Clean description
    let description = this.cleanDescription(caption);
    
    // Extract tags
    let tags = this.extractTags(caption, profile);
    
    return {
      // Core event data
      name: eventName,
      studio: profile.defaultStudio || profile.name,
      location: profile.defaultVenue,
      address: profile.defaultAddress || '',
      date: eventDate,
      time: eventTime,
      price: price,
      
      // Descriptions
      original_caption: caption.substring(0, 500), // Limit length
      description: description,
      
      // Source data
      instagram_url: post.url,
      image_url: post.imageUrl,
      instagram_handle: `@${profile.name.toLowerCase().replace(/\s+/g, '')}`,
      source: 'Instagram',
      
      // Metadata
      tags: tags,
      confidence_score: analysis.confidence,
      indicators_found: analysis.foundIndicators.join(', '),
      
      // Profile data
      instagram_bio: profileData.bio,
      instagram_followers: profileData.followerCount,
      website_url: profileData.websiteUrl
    };
  }

  extractDate(caption, postTimestamp) {
    const today = new Date();
    const captionLower = caption.toLowerCase();
    
    // Check for specific date patterns
    const months = ['january', 'february', 'march', 'april', 'may', 'june',
                   'july', 'august', 'september', 'october', 'november', 'december'];
    
    for (let i = 0; i < months.length; i++) {
      const monthPattern = new RegExp(`${months[i]}\\s+(\\d{1,2})`, 'i');
      const match = caption.match(monthPattern);
      if (match) {
        const year = today.getFullYear();
        return `${year}-${(i + 1).toString().padStart(2, '0')}-${match[1].padStart(2, '0')}`;
      }
    }
    
    // Check for relative dates
    if (captionLower.includes('tomorrow')) {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.toISOString().split('T')[0];
    }
    
    if (captionLower.includes('tonight') || captionLower.includes('today')) {
      return today.toISOString().split('T')[0];
    }
    
    if (captionLower.includes('this saturday')) {
      const saturday = new Date(today);
      const daysUntilSaturday = (6 - today.getDay() + 7) % 7 || 7;
      saturday.setDate(saturday.getDate() + daysUntilSaturday);
      return saturday.toISOString().split('T')[0];
    }
    
    if (captionLower.includes('this sunday')) {
      const sunday = new Date(today);
      const daysUntilSunday = (0 - today.getDay() + 7) % 7 || 7;
      sunday.setDate(sunday.getDate() + daysUntilSunday);
      return sunday.toISOString().split('T')[0];
    }
    
    // Check for MM/DD pattern
    const datePattern = /(\d{1,2})\/(\d{1,2})/;
    const dateMatch = caption.match(datePattern);
    if (dateMatch) {
      const year = today.getFullYear();
      return `${year}-${dateMatch[1].padStart(2, '0')}-${dateMatch[2].padStart(2, '0')}`;
    }
    
    return ''; // No date found
  }

  extractTime(caption, profile) {
    // Check for specific time patterns
    const timePattern = /(\d{1,2}):?(\d{2})?\s*(am|pm)/i;
    const match = caption.match(timePattern);
    
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
    
    // Check for relative times
    const captionLower = caption.toLowerCase();
    if (captionLower.includes('morning')) {
      return profile.schedule?.weekdays?.[0] || '09:00';
    }
    if (captionLower.includes('noon')) {
      return '12:00';
    }
    if (captionLower.includes('evening')) {
      return '18:30';
    }
    
    return '';
  }

  extractPrice(caption, profile) {
    // Check for dollar amounts
    const pricePattern = /\$(\d+)/;
    const match = caption.match(pricePattern);
    
    if (match) {
      return match[1];
    }
    
    // Check for price keywords
    const captionLower = caption.toLowerCase();
    if (captionLower.includes('free')) {
      return '0';
    }
    if (captionLower.includes('donation')) {
      return 'By donation';
    }
    
    // Use profile default if available
    if (profile.typicalPrices?.default) {
      return profile.typicalPrices.default.toString();
    }
    
    return '';
  }

  generateEventName(caption, profile, date) {
    const captionLower = caption.toLowerCase();
    
    // Extract first line or sentence as potential title
    const firstLine = caption.split('\n')[0];
    const firstSentence = firstLine.split(/[.!?]/)[0];
    
    // Check for common event name patterns
    if (profile.name.includes('Rumble')) {
      if (captionLower.includes('bootcamp')) return 'Boxing Bootcamp';
      if (captionLower.includes('hiit')) return 'HIIT Boxing Class';
      if (captionLower.includes('beginner')) return 'Beginner Boxing Class';
      if (captionLower.includes('advanced')) return 'Advanced Boxing Training';
      return 'Boxing Class';
    }
    
    if (profile.name.includes('Claymates')) {
      if (captionLower.includes('wheel')) return 'Wheel Throwing Workshop';
      if (captionLower.includes('hand build')) return 'Hand Building Workshop';
      if (captionLower.includes('glazing')) return 'Glazing Workshop';
      if (captionLower.includes('beginner')) return 'Beginner Pottery Workshop';
      if (captionLower.includes('kids')) return 'Kids Pottery Class';
      return 'Pottery Workshop';
    }
    
    // Generic event name from first meaningful words
    if (firstSentence.length < 50) {
      return firstSentence;
    }
    
    return `Event at ${profile.name}`;
  }

  cleanDescription(caption) {
    // Remove hashtags
    let cleaned = caption.replace(/#\w+/g, '').trim();
    
    // Remove multiple spaces
    cleaned = cleaned.replace(/\s+/g, ' ');
    
    // Remove multiple newlines
    cleaned = cleaned.replace(/\n{3,}/g, '\n\n');
    
    // Limit length
    if (cleaned.length > 300) {
      cleaned = cleaned.substring(0, 297) + '...';
    }
    
    return cleaned;
  }

  extractTags(caption, profile) {
    const tags = new Set();
    
    // Add profile-based tags
    if (profile.name.includes('Rumble')) {
      tags.add('fitness');
      tags.add('boxing');
    }
    if (profile.name.includes('Claymates')) {
      tags.add('art');
      tags.add('pottery');
      tags.add('crafts');
    }
    
    // Extract hashtags
    const hashtags = caption.match(/#\w+/g) || [];
    hashtags.forEach(tag => {
      const cleanTag = tag.replace('#', '').toLowerCase();
      if (cleanTag.length > 2 && cleanTag.length < 20) {
        tags.add(cleanTag);
      }
    });
    
    // Add keyword-based tags
    const captionLower = caption.toLowerCase();
    if (captionLower.includes('beginner')) tags.add('beginner-friendly');
    if (captionLower.includes('advanced')) tags.add('advanced');
    if (captionLower.includes('kids')) tags.add('kids');
    if (captionLower.includes('workshop')) tags.add('workshop');
    if (captionLower.includes('class')) tags.add('class');
    
    return Array.from(tags).slice(0, 5).join(', ');
  }

  createDefaultProfile(username) {
    return {
      name: username.replace('@', ''),
      defaultVenue: username.replace('@', ''),
      defaultAddress: '',
      defaultStudio: username.replace('@', ''),
      eventKeywords: [],
      typicalPrices: { min: 0, max: 100, default: 50 }
    };
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
      console.log('✅ Browser closed');
    }
  }
}

// ============= GOOGLE SHEETS INTEGRATION =============

async function sendToGoogleSheets(eventData) {
  try {
    console.log(`\n📤 Sending to Google Sheets: ${eventData.name}`);
    console.log(`   Confidence: ${(eventData.confidence_score * 100).toFixed(0)}%`);
    console.log(`   Indicators: ${eventData.indicators_found}`);
    
    const response = await fetch(CONFIG.WEB_APP_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(eventData),
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('   ✅ Successfully added to Google Sheets');
    } else {
      console.log('   ❌ Failed to add:', result.error);
    }
    
    return result;
  } catch (error) {
    console.error('   ❌ Error sending to Sheets:', error.message);
    return { success: false, error: error.message };
  }
}

// ============= MAIN EXECUTION =============

async function main(accountsToScrape = null) {
  console.log('🎯 Intelligent Hobby Directory Scraper');
  console.log('=====================================');
  console.log(`📊 Google Sheet ID: ${CONFIG.SPREADSHEET_ID}`);
  console.log(`🔍 Event Detection Threshold: ${CONFIG.MIN_EVENT_INDICATORS} indicators`);
  console.log(`📈 Auto-import Confidence: ${(CONFIG.MIN_CONFIDENCE_SCORE * 100)}%`);
  console.log('=====================================\n');
  
  const scraper = new IntelligentInstagramScraper();
  const allEvents = [];
  let successfulSends = 0;
  
  // Use provided accounts or all profiles
  const accounts = accountsToScrape || Object.keys(ACCOUNT_PROFILES);
  console.log(`📸 Accounts to scrape: ${accounts.join(', ')}\n`);
  
  try {
    await scraper.initialize();
    
    // Process each account
    for (const username of accounts) {
      const profile = ACCOUNT_PROFILES[username] || scraper.createDefaultProfile(username);
      const events = await scraper.scrapeAccount(username);
      
      // Only send high-confidence events automatically
      for (const event of events) {
        if (event.confidence_score >= CONFIG.MIN_CONFIDENCE_SCORE) {
          allEvents.push(event);
          const result = await sendToGoogleSheets(event);
          if (result.success) {
            successfulSends++;
          }
        } else {
          console.log(`   ⚠️ Low confidence event needs manual review: ${event.name}`);
          // Could still add to a "review" sheet
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      // Rate limiting between accounts
      await new Promise(resolve => setTimeout(resolve, CONFIG.RATE_LIMIT));
    }
    
    // Summary
    console.log('\n=====================================');
    console.log('📊 INTELLIGENT SCRAPING COMPLETE');
    console.log('=====================================');
    console.log(`🔍 Posts analyzed: ${scraper.postsAnalyzed}`);
    console.log(`✅ Real events found: ${allEvents.length}`);
    console.log(`📤 Successfully sent to Sheets: ${successfulSends}`);
    console.log(`📍 View your data: https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
    // Show event summary
    if (allEvents.length > 0) {
      console.log('\n📅 Events Found:');
      allEvents.forEach(event => {
        console.log(`   - ${event.name} (${event.date || 'No date'}) - ${(event.confidence_score * 100).toFixed(0)}% confidence`);
      });
    }
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// ============= TEST SPECIFIC ACCOUNT =============

async function testAccount(username) {
  console.log(`🧪 Testing account: ${username}\n`);
  
  const scraper = new IntelligentInstagramScraper();
  
  try {
    await scraper.initialize();
    
    const events = await scraper.scrapeAccount(username);
    
    console.log('\n=====================================');
    console.log(`Found ${events.length} events`);
    
    events.forEach((event, i) => {
      console.log(`\nEvent ${i + 1}:`);
      console.log(`  Name: ${event.name}`);
      console.log(`  Date: ${event.date || 'Not found'}`);
      console.log(`  Time: ${event.time || 'Not found'}`);
      console.log(`  Price: ${event.price || 'Not found'}`);
      console.log(`  Confidence: ${(event.confidence_score * 100).toFixed(0)}%`);
      console.log(`  Indicators: ${event.indicators_found}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// ============= RUN OPTIONS =============

// Get command line arguments
const args = process.argv.slice(2);

if (args.length > 0) {
  if (args[0] === 'test') {
    // Test mode with specific account
    testAccount(args[1] || '@rumbleboxingmp');
  } else if (args[0] === 'all') {
    // Run all accounts in profiles
    main();
  } else {
    // Run specific accounts passed as arguments
    main(args);
  }
} else {
  // Default: Run main accounts only
  main(['@rumbleboxingmp', '@claymates.studio']);
}

// Usage examples:
// node intelligent-instagram-scraper.js                          # Scrape main accounts
// node intelligent-instagram-scraper.js all                      # Scrape all profiles
// node intelligent-instagram-scraper.js @pottersnook            # Scrape specific account
// node intelligent-instagram-scraper.js test @claymates.studio  # Test mode for account