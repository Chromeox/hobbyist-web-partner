# Hobby Directory Design Specification
*Based on The Running Directory reference*

## Project Overview
**Goal**: Vancouver's premier creative event discovery platform
**Reference Site**: https://www.therunningdirectory.ca/
**Tech Stack**: React + TypeScript (DevLink) + Webflow + Airtable
**Target Launch**: This week (MVP)

---

## 1. Layout & Structure

### Homepage
```
┌─────────────────────────────────────┐
│  Hero Section                       │
│  - Large background image           │
│  - Main headline                    │
│  - Primary CTA button               │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Featured Upcoming Events (3-6)     │
│  - Card grid layout                 │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Browse by Category                 │
│  - Category cards with counts       │
│  - Icons for each category          │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Browse by Location (Optional)      │
│  - Vancouver neighborhoods          │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Newsletter Signup                  │
│  - Email + preference fields        │
└─────────────────────────────────────┘
```

### Navigation
- **Primary**: Find Classes | By Category | Studios | About
- **Secondary**: Location filters, date filters
- **Mobile**: Hamburger menu with modal-based filtering

---

## 2. Event Card Design

### Card Layout (Grid Display)
```
┌──────────────────────────┐
│                          │
│   Event Image (16:9)     │
│                          │
├──────────────────────────┤
│ 📅 Thu, Dec 12, 7:00 PM │
│ Pottery Wheel Basics     │
│ 📍 Claymates Studio      │
│ 💰 $75 • 🎯 Beginner     │
│                          │
│ [pottery] [evening]      │
└──────────────────────────┘
```

### Card Information
- **Event image**: High-quality photos (fallback placeholder)
- **Date/time**: Human-readable format with emoji icon
- **Event title**: Clear, descriptive
- **Location**: Studio name + neighborhood
- **Price**: Visible upfront
- **Skill level**: Beginner/Intermediate/Advanced
- **Category tags**: Clickable filters
- **Dynamic badges**: "TODAY", "FINAL SPOTS", "SOLD OUT"

### Grid Responsiveness
- **Desktop (>991px)**: 4 columns
- **Tablet (768-991px)**: 3 columns
- **Mobile (480-767px)**: 2 columns
- **Small mobile (<480px)**: 1 column

---

## 3. Filtering System

### Filter Types

#### Primary Filters (Always Visible)
1. **Category** (multi-select)
   - Pottery
   - Fitness/Boxing
   - Art/Painting
   - Dance
   - Wellness/Yoga
   - Food/Cooking
   - Maker/Crafts

2. **Date Range** (radio buttons)
   - Today
   - This Week
   - This Weekend
   - This Month
   - Custom Range

3. **Price Range** (slider or input)
   - Free
   - $0-$25
   - $25-$50
   - $50-$100
   - $100+

#### Secondary Filters (Modal/Expandable)
4. **Skill Level**
   - All Levels Welcome
   - Beginner
   - Intermediate
   - Advanced

5. **Time of Day**
   - Morning (6am-12pm)
   - Afternoon (12pm-5pm)
   - Evening (5pm-9pm)
   - Night (9pm+)

6. **Location** (Vancouver neighborhoods)
   - Mount Pleasant
   - Gastown
   - Kitsilano
   - Commercial Drive
   - Downtown
   - etc.

7. **Studio** (dropdown)
   - Claymates Ceramic Studio
   - Rumble Boxing
   - [Additional studios as added]

### Filter UI Patterns
- **Desktop**: Sidebar with all filters visible
- **Mobile**: "Filters" button opens modal with all options
- **Active filters**: Show count badge ("3 filters active")
- **Clear filters**: One-click reset button
- **URL persistence**: Filters saved in query params (shareable links)

---

## 4. Event Detail Page

### Layout Structure
```
┌─────────────────────────────────────────┐
│  Hero Image (full-width)                │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Event Title                            │
│  ⭐⭐⭐⭐⭐ (4.8) • 127 reviews          │
└─────────────────────────────────────────┘
┌────────────────┬────────────────────────┐
│  Left Column   │  Right Column (Sticky) │
│  ─────────────┤                        │
│  📅 Date/Time │  💰 $75                │
│  📍 Location  │  👥 8 spots left       │
│  ⏱️ Duration  │                        │
│  🎯 Level     │  [Book Now Button]     │
│                │                        │
│  Description   │  Studio Info Card      │
│  What to Bring │  - Logo               │
│  Cancellation  │  - Rating             │
│                │  - Quick stats        │
│  Reviews       │                        │
└────────────────┴────────────────────────┘
```

### Key Elements

#### Event Metadata (Left Column)
- **Date & Time**: Day of week, date, time range
- **Location**: Studio name, full address, map link
- **Duration**: "2 hours" or "90 minutes"
- **Skill Level**: With icon/badge
- **What to Bring**: Bulleted list
- **What's Included**: Materials, tools, etc.
- **Cancellation Policy**: Clear, concise
- **Instructor**: Name, bio, photo (if available)

#### Booking Sidebar (Right Column - Sticky)
- **Price**: Large, prominent
- **Availability**: "8 spots left" or "Sold Out"
- **CTA Button**: "Book Now" or "Join Waitlist"
- **Trust signals**: "Free cancellation until 24hrs"
- **Studio Card**: Mini profile with rating

#### Social Proof
- **Reviews Section**: Star rating, text reviews, photos
- **Share Buttons**: Facebook, Twitter, Email, Copy Link

---

## 5. Visual Design System

### Color Palette (Adapt to your brand)
Based on creative/wellness vibe:
- **Primary**: Warm terracotta (#E07A5F) - pottery/art theme
- **Secondary**: Deep teal (#3D5A80) - calm/wellness
- **Accent**: Coral (#F2CC8F) - energy/creativity
- **Neutral Dark**: Charcoal (#2C3E50)
- **Neutral Light**: Warm white (#FAF9F6)
- **Success**: Green (#2ECC71) - available spots
- **Warning**: Orange (#F39C12) - final spots
- **Error**: Red (#E74C3C) - sold out

### Typography
- **Headings**: Bebas Neue or similar condensed sans-serif (bold, impactful)
- **Body**: Inter or similar modern sans-serif (readable, clean)
- **Monospace**: Inconsolata for tags/metadata (technical feel)

**Font Sizes**:
- H1 (Hero): 64px / 3.5rem
- H2 (Section): 48px / 2.5rem
- H3 (Card Title): 24px / 1.25rem
- Body: 16px / 1rem
- Small: 14px / 0.875rem

### Spacing System
Use 8px base unit:
- Micro: 4px (0.25rem)
- Small: 8px (0.5rem)
- Medium: 16px (1rem)
- Large: 24px (1.5rem)
- XL: 32px (2rem)
- XXL: 48px (3rem)

### Component Styles

#### Buttons
- **Primary**: Solid color, rounded corners (8px), hover lift effect
- **Secondary**: Outlined, same hover
- **Text**: No background, underline on hover

#### Cards
- **Shadow**: Subtle box-shadow (0 2px 8px rgba(0,0,0,0.1))
- **Hover**: Lift effect (translate -2px + deeper shadow)
- **Border Radius**: 12px (modern, friendly)

#### Tags/Badges
- **Pill shape**: Full border-radius
- **Small padding**: 4px 12px
- **Subtle background**: Light tint of category color
- **Hover**: Darken on hover (clickable filters)

---

## 6. Key Features & Functionality

### Core Features (MVP)
1. ✅ **Event Browsing**: Grid view with infinite scroll or pagination
2. ✅ **Filtering**: Category, date, price, location
3. ✅ **Search**: Text search by event name or studio
4. ✅ **Event Details**: Full information page
5. ✅ **Booking CTA**: Link to external booking (studio website or platform)
6. ✅ **Mobile Responsive**: Full mobile optimization
7. ✅ **Newsletter Signup**: Email capture with preferences

### Nice-to-Have (Post-MVP)
- 🔜 User accounts (save favorites, view history)
- 🔜 Direct booking/payment (Stripe integration)
- 🔜 Calendar view (month/week grid)
- 🔜 Map view (Google Maps integration)
- 🔜 Reviews & ratings (user-generated)
- 🔜 Studio profiles (dedicated pages)
- 🔜 Social sharing (Open Graph tags)
- 🔜 Email reminders (24hrs before class)

---

## 7. Mobile Responsiveness

### Breakpoints
```css
/* Mobile First Approach */
$mobile: 480px;
$tablet: 768px;
$desktop: 992px;
$wide: 1200px;
```

### Mobile Optimizations
- **Hero**: Reduce height, larger text for readability
- **Navigation**: Hamburger menu, full-screen overlay
- **Filters**: Modal-based (not sidebar)
- **Cards**: 1-2 column grid
- **Event Detail**: Single column, sticky booking bar at bottom
- **Images**: Lazy loading, optimized sizes

### Touch Targets
- Minimum 44x44px for all interactive elements
- Adequate spacing between clickable items
- Swipe gestures for image galleries

---

## 8. CTA & Conversion Patterns

### Primary CTAs
1. **"Book Now"**: Main event detail action
2. **"View Details"**: Card click-through
3. **"Sign Up for Newsletter"**: Email capture
4. **"View All Events"**: Category browsing

### CTA Hierarchy
- **High contrast**: Primary actions use bold colors
- **Above fold**: Main CTA visible without scrolling
- **Repeat CTA**: Multiple "Book Now" on long detail pages
- **Sticky CTA**: Mobile bottom bar for booking

### Trust Signals
- **Free cancellation**: Reduce booking friction
- **Spots remaining**: Create urgency ("Only 3 left!")
- **Reviews**: Social proof near CTA
- **Studio verification**: Badge/checkmark

---

## 9. Content Organization & Taxonomy

### Categories (Primary)
```
pottery/         → Claymates, wheel throwing, hand building
fitness/         → Rumble Boxing, yoga, barre
art/             → Painting, drawing, printmaking
dance/           → Ballet, hip-hop, salsa
wellness/        → Meditation, breathwork, sound healing
food/            → Cooking classes, wine tasting, baking
maker/           → Woodworking, jewelry, candle making
```

### Tags (Secondary)
- **Skill level**: beginner, intermediate, advanced, all-levels
- **Time**: morning, afternoon, evening, weekend
- **Duration**: quick (< 1hr), standard (1-2hrs), intensive (2+hrs)
- **Type**: workshop, class, drop-in, series
- **Special**: date-night, kids-welcome, BYOB, wheelchair-accessible

### URL Structure
```
/events                     → All events listing
/events/pottery             → Category page
/events/pottery/[slug]      → Event detail page
/studios                    → Studio directory
/studios/[slug]             → Studio profile
/about                      → About the directory
```

---

## 10. Unique Features for Hobby Directory

### Dynamic Badge System
Real-time contextual badges on event cards:
- **"TODAY"**: Events happening today (orange badge)
- **"TOMORROW"**: Next day events (yellow badge)
- **"FINAL SPOTS"**: < 20% capacity remaining (red badge)
- **"JUST ADDED"**: Events added in last 7 days (green badge)
- **"POPULAR"**: High booking rate (fire emoji 🔥)
- **"SOLD OUT"**: No availability (gray, non-clickable)

### Event Recommendations
"If you liked this, you might also like..."
- Same category, different date
- Same studio, different class type
- Similar price point
- Similar skill level

### Studio Showcase
Highlight featured studios on homepage:
- Studio logo
- Rating (⭐ 4.8/5)
- Number of classes offered
- Quick link to profile

### Category Landing Pages
Each category gets a dedicated page:
- Hero image for that category (e.g., hands on pottery wheel)
- Intro text about the category in Vancouver
- Filtered event list
- Featured studios in this category

---

## 11. Airtable → React Data Mapping

### Airtable Fields → React Component Props

#### Events Table
```typescript
interface Event {
  id: string;                    // Airtable record ID
  slug: string;                  // URL-friendly identifier
  name: string;                  // Event title
  description: string;           // Full description
  ai_rewritten_description?: string; // LLM-enhanced version

  // Date/Time
  event_date: string;            // ISO 8601 date
  meeting_time: string;          // Human-readable time
  duration_minutes?: number;     // Event length

  // Location
  location: string;              // Studio name
  address: string;               // Full address
  neighborhood?: string;         // Vancouver area

  // Pricing
  price: number;                 // Numeric price
  currency: string;              // "CAD"

  // Media
  image_url: string;             // Primary image
  gallery_urls?: string[];       // Additional images

  // Classification
  tags: string[];                // Category tags
  skill_level: 'beginner' | 'intermediate' | 'advanced' | 'all-levels';
  category: string;              // Primary category

  // Metadata
  status: 'active' | 'pending' | 'archived';
  sync_to_webflow: boolean;      // Filter flag
  spots_remaining?: number;      // Availability
  total_capacity?: number;       // Max attendees

  // Links
  booking_url?: string;          // External booking link
  instagram_post_url?: string;   // Source post

  // Dynamic
  dynamic_label?: string;        // "FINAL SPOTS", etc.
  priority: number;              // Sort order
}
```

#### Studios Table
```typescript
interface Studio {
  id: string;
  slug: string;
  name: string;
  description: string;
  logo_url?: string;
  cover_image_url?: string;

  // Location
  address: string;
  neighborhood: string;
  latitude?: number;
  longitude?: number;

  // Contact
  website_url?: string;
  instagram_handle?: string;
  email?: string;
  phone?: string;

  // Metadata
  rating?: number;              // 1-5 stars
  review_count?: number;
  categories: string[];         // What they offer

  // Stats (computed)
  total_events?: number;        // Count of active events
  next_event_date?: string;     // Earliest upcoming
}
```

---

## 12. React Component Architecture

### Component Hierarchy
```
<App>
  <Navigation />
  <HomePage>
    <Hero />
    <FeaturedEvents>
      <EventCard />
      <EventCard />
      <EventCard />
    </FeaturedEvents>
    <CategoryGrid>
      <CategoryCard />
    </CategoryGrid>
    <NewsletterSignup />
  </HomePage>

  <EventsPage>
    <FilterSidebar />
    <EventGrid>
      <EventCard />
    </EventGrid>
  </EventsPage>

  <EventDetailPage>
    <EventHero />
    <EventInfo />
    <BookingSidebar />
    <Reviews />
  </EventDetailPage>

  <StudioPage>
    <StudioHeader />
    <StudioEvents>
      <EventCard />
    </StudioEvents>
  </StudioPage>
</App>
```

### Key Components to Build

#### 1. EventCard.tsx
Reusable card for grid displays
```typescript
interface EventCardProps {
  event: Event;
  variant?: 'compact' | 'standard' | 'featured';
  showStudio?: boolean;
}
```

#### 2. EventGrid.tsx
Grid container with filtering/sorting
```typescript
interface EventGridProps {
  filters: FilterState;
  sortBy?: 'date' | 'price' | 'popularity';
  layout?: 'grid' | 'list';
}
```

#### 3. FilterSidebar.tsx
Complete filtering UI
```typescript
interface FilterSidebarProps {
  categories: string[];
  priceRange: [number, number];
  locations: string[];
  onFilterChange: (filters: FilterState) => void;
}
```

#### 4. EventDetail.tsx
Full event page
```typescript
interface EventDetailProps {
  slug: string; // Fetches event by slug
}
```

#### 5. BookingSidebar.tsx
Sticky booking widget
```typescript
interface BookingSidebarProps {
  event: Event;
  onBookClick: () => void;
}
```

---

## 13. Webflow DevLink Integration Plan

### Step 1: Create Webflow Pages
In Webflow Designer, create page structure:
- Homepage (/)
- Events listing (/events)
- Event detail template (/events/[slug])
- Studio directory (/studios)
- About (/about)

### Step 2: Install DevLink
```bash
npm install @webflow/devlink
npx @webflow/devlink init
```

### Step 3: Build React Components
Create components in `/src/components/`:
- Fetch data from Airtable API
- Implement filtering/search logic
- Handle loading/error states
- Add caching layer (React Query or SWR)

### Step 4: Import to Webflow
Use DevLink CLI to sync components:
```bash
npx @webflow/devlink sync
```
Components appear in Webflow Designer as custom elements.

### Step 5: Style in Webflow
Design visual styling in Webflow Designer:
- Typography styles
- Color palette
- Spacing/layout
- Responsive breakpoints
- Interactions/animations

### Step 6: Deploy
Publish from Webflow to production domain.

---

## 14. Airtable API Integration

### API Setup
```typescript
// src/lib/airtable.ts
import Airtable from 'airtable';

const base = new Airtable({
  apiKey: process.env.AIRTABLE_API_KEY
}).base(process.env.AIRTABLE_BASE_ID);

export const fetchActiveEvents = async (filters?: FilterState) => {
  const records = await base('Events')
    .select({
      filterByFormula: `AND(
        {status} = 'active',
        {sync_to_webflow} = TRUE(),
        IS_AFTER({event_date}, TODAY())
      )`,
      sort: [{ field: 'priority', direction: 'desc' }]
    })
    .all();

  return records.map(r => ({
    id: r.id,
    ...r.fields
  }));
};
```

### Caching Strategy
Use SWR for client-side caching:
```typescript
import useSWR from 'swr';

const { data: events, error } = useSWR(
  ['/events', filters],
  () => fetchActiveEvents(filters),
  {
    revalidateOnFocus: false,
    revalidateOnReconnect: false,
    refreshInterval: 300000 // 5 min
  }
);
```

### Rate Limit Handling
Airtable free tier: 5 requests/second
- Implement request throttling
- Use batch operations where possible
- Cache aggressively on client
- Consider Redis for server-side cache

---

## 15. SEO & Performance

### Meta Tags (per page)
```html
<title>Pottery Classes in Vancouver | Hobby Directory</title>
<meta name="description" content="Discover creative pottery classes, workshops, and events in Vancouver. From wheel throwing to hand building." />
<meta property="og:image" content="/og-image-pottery.jpg" />
```

### Structured Data (JSON-LD)
```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "Pottery Wheel Basics",
  "startDate": "2025-01-15T19:00:00-08:00",
  "location": {
    "@type": "Place",
    "name": "Claymates Ceramic Studio",
    "address": "Vancouver, BC"
  },
  "offers": {
    "@type": "Offer",
    "price": "75",
    "priceCurrency": "CAD"
  }
}
```

### Performance Optimizations
- **Image optimization**: WebP format, lazy loading
- **Code splitting**: Route-based chunking
- **CDN**: Webflow's built-in CDN
- **Minimize API calls**: Aggressive caching
- **Preload critical data**: SSR or static generation for homepage

### Lighthouse Goals
- Performance: 90+
- Accessibility: 95+
- Best Practices: 95+
- SEO: 100

---

## 16. Analytics & Monitoring

### Track Key Metrics
1. **Event views**: Most popular events
2. **Filter usage**: What users search for
3. **Booking clicks**: Conversion tracking
4. **Newsletter signups**: Email capture rate
5. **Bounce rate**: Per category/page
6. **Mobile vs Desktop**: Usage patterns

### Tools
- **Google Analytics 4**: Page views, user flow
- **Hotjar**: Heatmaps, session recordings
- **Vercel Analytics**: Performance monitoring (if custom Next.js)
- **Airtable Dashboard**: Internal metrics (scraper success rate, review stats)

---

## 17. MVP Checklist

### Must-Have for This Week
- [ ] Webflow project created
- [ ] Homepage designed (hero + featured events)
- [ ] Events listing page (/events)
- [ ] Event detail page template
- [ ] React EventGrid component (fetches from Airtable)
- [ ] React EventDetail component
- [ ] Basic filtering (category, date)
- [ ] Mobile responsive design
- [ ] DevLink integration working
- [ ] 10-20 real events populated in Airtable
- [ ] Test: scraper → Airtable → approve → shows on site
- [ ] Domain connected (hobby.directory or staging)

### Nice-to-Have (If Time Permits)
- [ ] Newsletter signup functional
- [ ] Search bar
- [ ] Map view
- [ ] Studio directory page
- [ ] Advanced filters (price, location, skill level)
- [ ] Image optimization
- [ ] SEO meta tags

### Post-MVP (Next Iteration)
- [ ] User accounts
- [ ] Direct booking/payments
- [ ] Reviews & ratings
- [ ] Email notifications
- [ ] Social sharing
- [ ] Analytics dashboard
- [ ] Studio partner portal

---

## 18. Technical Implementation Notes

### Environment Variables
```env
# Airtable
AIRTABLE_API_KEY=keyXXXXXXXXXXXXXX
AIRTABLE_BASE_ID=appXXXXXXXXXXXXXX

# Webflow (if using API)
WEBFLOW_API_KEY=xxxxx
WEBFLOW_SITE_ID=xxxxx

# Optional
GOOGLE_MAPS_API_KEY=xxxxx
STRIPE_PUBLIC_KEY=pk_test_xxxxx
```

### Folder Structure
```
/hobby-directory-webflow
├── src/
│   ├── components/
│   │   ├── EventCard.tsx
│   │   ├── EventGrid.tsx
│   │   ├── EventDetail.tsx
│   │   ├── FilterSidebar.tsx
│   │   ├── BookingSidebar.tsx
│   │   └── Navigation.tsx
│   ├── lib/
│   │   ├── airtable.ts       # API client
│   │   ├── types.ts          # TypeScript interfaces
│   │   └── utils.ts          # Helper functions
│   ├── hooks/
│   │   ├── useEvents.ts      # SWR hook for events
│   │   └── useFilters.ts     # Filter state management
│   └── pages/                # If using Next.js routing
├── public/
│   ├── images/
│   └── favicon.ico
├── .env.local
├── package.json
└── tsconfig.json
```

### Dependencies
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "airtable": "^0.12.0",
    "swr": "^2.2.0",
    "date-fns": "^2.30.0",
    "@webflow/devlink": "latest"
  }
}
```

---

## 19. Testing Plan

### Manual Testing Checklist
- [ ] Homepage loads correctly
- [ ] Featured events display real data
- [ ] Clicking event card navigates to detail page
- [ ] Event detail page shows all information
- [ ] "Book Now" CTA links to correct URL
- [ ] Filters update event list in real-time
- [ ] Mobile menu works on small screens
- [ ] Images load properly (no broken links)
- [ ] Newsletter signup submits successfully
- [ ] 404 page shows for invalid event slugs

### Cross-Browser Testing
- [ ] Chrome (desktop + mobile)
- [ ] Safari (desktop + mobile)
- [ ] Firefox
- [ ] Edge

### Data Flow Testing
1. **Scraper Test**: Run scraper, verify events land in Airtable
2. **Approval Test**: Mark event as active, verify it appears on site within 5 min
3. **Update Test**: Change event details, verify changes reflect on site
4. **Delete Test**: Archive event, verify it disappears from site

---

## 20. Launch Day Checklist

### Pre-Launch
- [ ] All pages designed and functional
- [ ] 20+ real events populated
- [ ] Mobile responsiveness verified
- [ ] Domain connected (custom or Webflow subdomain)
- [ ] SSL certificate active
- [ ] Google Analytics installed
- [ ] Error tracking set up (Sentry or similar)
- [ ] Test all links and CTAs
- [ ] Spellcheck all content

### Launch Day
- [ ] Announce on social media
- [ ] Email 10 friends for feedback
- [ ] Monitor analytics for issues
- [ ] Have scraper running automatically
- [ ] Check for broken images/links
- [ ] Respond to feedback quickly

### Post-Launch (Week 1)
- [ ] Collect user feedback
- [ ] Fix critical bugs immediately
- [ ] Add studios as they request inclusion
- [ ] Refine filters based on usage data
- [ ] Plan next iteration features

---

## Summary

This specification mirrors The Running Directory's proven UX patterns while adapting to creative hobby events in Vancouver. The DevLink + React approach gives you more control and flexibility than pure Webflow CMS, while maintaining the ease of Webflow's design tools.

**Next Steps**:
1. Set up Webflow project
2. Build React components with Airtable integration
3. Design in Webflow Designer
4. Test data flow end-to-end
5. Soft launch to friends for feedback

**Timeline**: With focused effort, MVP launch achievable in 3-5 days.
