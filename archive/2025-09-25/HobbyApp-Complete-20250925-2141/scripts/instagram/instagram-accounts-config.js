/**
 * Instagram Account Configuration with Rotation Batches
 * Organized to avoid rate limits while maximizing event discovery
 */

// BATCH 1: Morning Run (6 AM) - 20 accounts
// Focus: Run clubs & morning fitness (post about evening/weekend events)
const BATCH_MORNING = [
  // Run Clubs (high priority - weekly schedules)
  { handle: '@novemberprojectyvr', name: 'November Project', website: 'november-project.com/vancouver', address: 'Various locations', price: 'Free' },
  { handle: '@vanrunco', name: 'Van Run Co', website: 'vanrun.co', address: 'West End', price: 'Free' },
  { handle: '@eastvanruncruw', name: 'East Van Run Crew', website: 'eastvanruncrew.com', address: 'East Vancouver', price: 'Free' },
  { handle: '@parkrun_canada', name: 'parkrun Canada', website: 'parkrun.ca', address: 'Various parks', price: 'Free' },
  { handle: '@rundergroundyvr', name: 'Run Underground YVR', address: 'Downtown parkades', price: 'Free' },
  
  // Existing accounts in scraper
  { handle: '@rumbleboxingmp', name: 'Rumble Boxing', website: 'rumbleboxing.com', address: '2935 Main St, Vancouver, BC V5T 3G5', price: '35' },
  { handle: '@claymates.studio', name: 'Claymates Studio', website: 'claymates.ca', address: '3071 Main St, Vancouver, BC V5V 3P1', price: '45' },
  { handle: '@yyoga', name: 'YYoga', website: 'yyoga.ca', address: 'Vancouver, BC', price: '25' },
  { handle: '@harbordance', name: 'Harbour Dance', website: 'harbourdance.com', address: '927 Granville St, Vancouver, BC', price: '20' },
  { handle: '@dirtykitchenvancouver', name: 'Dirty Kitchen', website: 'dirtykitchen.ca', address: 'Vancouver, BC', price: '65' },
  
  // Morning fitness studios
  { handle: '@f45_vancouver', name: 'F45 Training', website: 'f45training.com/vancouver', address: 'Various locations', price: '35' },
  { handle: '@spinco_yaletown', name: 'Spin Society', website: 'spinsociety.ca', address: 'Yaletown', price: '32' },
  { handle: '@lagreewest', name: 'Lagree West', website: 'lagreewest.com', address: 'West Vancouver', price: '40' },
  { handle: '@eastsideboxing', name: 'Eastside Boxing', website: 'eastsideboxing.com', address: 'East Vancouver', price: '25' },
  { handle: '@choprayogacenter', name: 'Chopra Yoga', website: 'choprayoga.com', address: 'Vancouver', price: '20' },
  
  // Social fitness
  { handle: '@thesweatsocial', name: 'The Sweat Social', address: 'Various', price: '20' },
  { handle: '@604fitnessclub', name: '604 Fitness Club', address: 'Vancouver', price: 'Free' },
  { handle: '@vancouversportsocialclub', name: 'Vancouver Sport & Social', website: 'vancouversportsclub.ca', address: 'Various', price: '60' },
  { handle: '@wanderwomenbc', name: 'Wander Women BC', address: 'Various trails', price: '15' },
  { handle: '@velovancouver', name: 'Velo Vancouver', address: 'Various', price: 'Free' }
];

// BATCH 2: Afternoon Run (2 PM) - 20 accounts
// Focus: Arts, crafts, creative workshops (evening/weekend classes)
const BATCH_AFTERNOON = [
  // Painting & Drawing
  { handle: '@paintnitevancouver', name: 'Paint Nite', website: 'paintnite.com/vancouver', address: 'Various bars/restaurants', price: '45' },
  { handle: '@4catsvancouver', name: '4 Cats Arts Studio', website: '4cats.com', address: 'Various locations', price: '25' },
  { handle: '@rawcanvas', name: 'Raw Canvas', website: 'rawcanvas.com', address: 'Mobile', price: '35' },
  { handle: '@lifedrawingvancouver', name: 'Life Drawing Vancouver', website: 'lifedrawingvancouver.com', address: 'Various studios', price: '20' },
  { handle: '@watercolourwest', name: 'Watercolour West', website: 'watercolourwest.com', address: 'West Vancouver', price: '30' },
  
  // Pottery & Ceramics
  { handle: '@303ceramicsstudio', name: '303 Ceramics', website: '303ceramics.com', address: 'Mount Pleasant', price: '40' },
  { handle: '@mudmonkeypottery', name: 'Mud Monkey Pottery', website: 'mudmonkeypottery.ca', address: 'East Van', price: '35' },
  { handle: '@thepotteryworkshopvancouver', name: 'The Pottery Workshop', website: 'potteryworkshop.ca', address: 'Vancouver', price: '40' },
  
  // Photography
  { handle: '@kerrisdalecameras', name: 'Kerrisdale Cameras', website: 'kerrisdalecameras.com', address: 'Kerrisdale', price: '60' },
  { handle: '@thelabvancouver', name: 'The Lab Vancouver', website: 'thelabvancouver.com', address: 'East Van', price: '45' },
  { handle: '@vancouverphotoworkshops', name: 'Vancouver Photo Workshops', website: 'vancouverphotoworkshops.com', address: 'Various', price: '75' },
  { handle: '@beau_photo', name: 'Beau Photo', website: 'beauphoto.com', address: 'Vancouver', price: '50' },
  
  // Makers & Crafts
  { handle: '@makevancouver', name: 'MakeVancouver', website: 'makevancouver.com', address: 'Vancouver', price: '30' },
  { handle: '@makerlabs', name: 'MakerLabs', website: 'makerlabs.com', address: 'Vancouver', price: '45' },
  { handle: '@blacksheepyarnshop', name: 'Black Sheep Yarn', website: 'blacksheepyarn.com', address: 'Vancouver', price: '25' },
  
  // Performing Arts
  { handle: '@theimprovcentre', name: 'The Improv Centre', website: 'theimprovcentre.ca', address: 'Granville Island', price: '20' },
  { handle: '@artsumbrella', name: 'Arts Umbrella', website: 'artsumbrella.com', address: 'Granville Island', price: '30' },
  
  // Music
  { handle: '@tomleemusicvancouver', name: 'Tom Lee Music', website: 'tomleemusic.ca', address: 'Various', price: '40' },
  { handle: '@nimbusschoolofrecording', name: 'Nimbus Recording', website: 'nimbusrecording.com', address: 'Vancouver', price: '60' },
  
  // Dance
  { handle: '@vancouvertapdanceproject', name: 'Vancouver Tap Dance', address: 'Vancouver', price: '25' }
];

// BATCH 3: Evening Run (6 PM) - 20 accounts
// Focus: Culinary, wellness, evening activities
const BATCH_EVENING = [
  // Cooking & Culinary
  { handle: '@thestockmarketvancouver', name: 'The Stock Market', website: 'thestockmarket.ca', address: 'Vancouver', price: '75' },
  { handle: '@wellseasonedvancouver', name: 'Well Seasoned', website: 'wellseasoned.ca', address: 'Vancouver', price: '85' },
  { handle: '@pacificinstituteculinaryarts', name: 'Pacific Institute', website: 'picachef.com', address: 'Vancouver', price: '95' },
  { handle: '@cookculture_vancouver', name: 'Cook Culture', website: 'cookculture.com', address: 'Vancouver', price: '70' },
  { handle: '@beaucoupbakery', name: 'Beaucoup Bakery', website: 'beaucoupbakery.com', address: 'Vancouver', price: '45' },
  { handle: '@eastvanroasters', name: 'East Van Roasters', website: 'eastvanroasters.com', address: 'East Van', price: '30' },
  
  // Wine & Spirits
  { handle: '@vancouverurbanwinery', name: 'Vancouver Urban Winery', website: 'vancouverurbanwinery.com', address: 'Vancouver', price: '40' },
  { handle: '@oddsociety', name: 'Odd Society Spirits', website: 'oddsocietyspirits.com', address: 'East Van', price: '35' },
  
  // Wellness & Meditation
  { handle: '@momentmeditation', name: 'Moment Meditation', website: 'momentmeditation.com', address: 'Mount Pleasant', price: '20' },
  { handle: '@floathousevancouver', name: 'Float House', website: 'floathouse.ca', address: 'Various', price: '75' },
  { handle: '@vancouversaltcave', name: 'Vancouver Salt Cave', website: 'vancouversaltcave.com', address: 'Vancouver', price: '45' },
  { handle: '@theheartspace.ca', name: 'The Heart Space', website: 'theheartspace.ca', address: 'Vancouver', price: '30' },
  
  // Additional Yoga Studios
  { handle: '@oneyogaforthepeople', name: 'One Yoga', website: 'oneyoga.ca', address: 'Various', price: '20' },
  { handle: '@mokshayogavancouver', name: 'Moksha Yoga', website: 'mokshayoga.ca', address: 'Various', price: '22' },
  
  // Outdoor & Adventure
  { handle: '@mec_vancouver', name: 'MEC Vancouver', website: 'mec.ca', address: 'Vancouver', price: '30' },
  { handle: '@alpenclubcanada', name: 'Alpine Club', website: 'alpineclubofcanada.ca', address: 'Various', price: '25' },
  
  // Tech & Gaming
  { handle: '@vanhack', name: 'VanHack', website: 'vanhack.ca', address: 'Vancouver', price: 'Free' },
  { handle: '@stormcrowvancouver', name: 'Storm Crow', website: 'stormcrowtavern.com', address: 'Commercial Drive', price: 'Free' },
  
  // Film
  { handle: '@cinemazoo', name: 'Cinemazoo', website: 'cinemazoo.com', address: 'Vancouver', price: '50' },
  { handle: '@viffest', name: 'VIFF', website: 'viff.org', address: 'Various', price: '15' }
];

// CONFIGURATION
const SCRAPER_CONFIG = {
  // Timing between actions (milliseconds)
  RATE_LIMITS: {
    BETWEEN_ACCOUNTS: 8000,  // 8 seconds between accounts
    BETWEEN_POSTS: 3000,     // 3 seconds between posts
    BETWEEN_BATCHES: 1800000 // 30 minutes between batches
  },
  
  // How many posts to check per account
  POSTS_PER_ACCOUNT: 2,
  
  // Schedule (24-hour format)
  SCHEDULE: {
    MORNING: '06:00',
    AFTERNOON: '14:00',
    EVENING: '18:00'
  },
  
  // Safety limits
  MAX_ACCOUNTS_PER_RUN: 20,
  MAX_ACTIONS_PER_HOUR: 180, // Stay under Instagram's 200/hour limit
  
  // Event detection sensitivity
  MIN_CONFIDENCE: 0.3, // Lower = more events captured
  
  // Proxy configuration (for future use with Data Impulse)
  USE_PROXY: false,
  PROXY_CONFIG: {
    // Save for SluthbotVX or high-volume needs
    provider: 'dataimpulse',
    rotate_on_failure: true
  }
};

// HELPER FUNCTIONS
function getCurrentBatch() {
  const hour = new Date().getHours();
  
  if (hour >= 6 && hour < 14) {
    return { name: 'MORNING', accounts: BATCH_MORNING };
  } else if (hour >= 14 && hour < 18) {
    return { name: 'AFTERNOON', accounts: BATCH_AFTERNOON };
  } else {
    return { name: 'EVENING', accounts: BATCH_EVENING };
  }
}

function getAccountsByCategory(category) {
  const allAccounts = [...BATCH_MORNING, ...BATCH_AFTERNOON, ...BATCH_EVENING];
  return allAccounts.filter(acc => 
    acc.name.toLowerCase().includes(category.toLowerCase()) ||
    acc.handle.includes(category.toLowerCase())
  );
}

// Export configuration
module.exports = {
  BATCH_MORNING,
  BATCH_AFTERNOON,
  BATCH_EVENING,
  SCRAPER_CONFIG,
  getCurrentBatch,
  getAccountsByCategory,
  
  // All accounts (60 total)
  ALL_ACCOUNTS: [...BATCH_MORNING, ...BATCH_AFTERNOON, ...BATCH_EVENING]
};