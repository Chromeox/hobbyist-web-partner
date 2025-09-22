# 🎯 Webflow Starter Plan Strategy (2 Static Pages)

## Understanding the 2-Page Limit

### ✅ What COUNTS as a page:
- Homepage (1 page)
- Static pages you create (Events list, About, Contact, etc.)

### ✅ What DOESN'T count:
- **CMS Template pages** (unlimited individual events!)
- **CMS Collection pages** (auto-generated)
- **404 page** (system page)
- **Password page** (system page)

## Optimal 2-Page Setup for Hobby Directory

### Page 1: Homepage (`/`)
**Purpose**: Landing page with today's featured events
```
Components:
├── Hero Section
│   └── "Vancouver's Creative Workshop Directory"
├── Today's Events (Collection List - filtered)
├── Categories Grid (links to filtered sections)
├── Newsletter Signup
└── Footer
```

### Page 2: Events Directory (`/events`)
**Purpose**: All events with filtering
```
Components:
├── Filter Bar (category, date, price)
├── Collection List (all events)
├── Load More button
└── Map View (optional)
```

### Unlimited: Event Template Pages (`/events/[slug]`)
**Auto-generated from CMS - doesn't count!**
```
Each event gets its own page:
- /events/pottery-workshop-jan-15
- /events/rumble-boxing-basics
- /events/paint-night-gastown
- etc. (hundreds possible!)
```

## Step-by-Step Setup Guide

### Step 1: Create CMS Collection
1. Go to **CMS** panel (left sidebar)
2. Click **"+ Create Collection"**
3. Name it: **Events**
4. Add fields (see field list below)

### Step 2: Design Homepage (Page 1/2)
1. Go to **Pages** panel
2. Click on **Home**
3. Add sections:
   ```html
   <!-- Hero Section -->
   <div class="hero">
     <h1>Vancouver Creative Workshops</h1>
     <p>Find your next hobby adventure</p>
   </div>
   
   <!-- Today's Events -->
   <div class="collection-list-wrapper">
     [Collection List - Events]
     Filter: Event Date = Today
     Limit: 6 items
   </div>
   
   <!-- Category Links -->
   <div class="categories">
     <a href="/events?category=fitness">Fitness</a>
     <a href="/events?category=arts">Arts</a>
     <a href="/events?category=culinary">Culinary</a>
   </div>
   ```

### Step 3: Create Events Page (Page 2/2)
1. **Pages** panel → **"+ Create New Page"**
2. Name: **Events** (URL: /events)
3. Add Collection List:
   ```html
   <!-- Filters (using Webflow interactions) -->
   <div class="filters">
     [Dropdown - Categories]
     [Dropdown - Dates]
     [Dropdown - Price Range]
   </div>
   
   <!-- Events Grid -->
   <div class="collection-list">
     [Collection List - Events]
     Layout: Grid (3 columns)
     Limit: 20 items
     Pagination: Load More
   </div>
   ```

### Step 4: Design Event Template (Unlimited!)
1. **CMS** panel → **Events** → **Events Template**
2. Design the individual event page:
   ```html
   <!-- Event Hero -->
   <div class="event-hero">
     [Image Field]
     <h1>[Name Field]</h1>
     <p class="studio">[Studio Field]</p>
   </div>
   
   <!-- Event Details -->
   <div class="event-details">
     <div class="info">
       📅 [Event Date]
       ⏰ [Time]
       📍 [Location]
       💰 [Price]
     </div>
     
     <div class="description">
       [Rich Text - Description]
     </div>
     
     <a href="[Book Link]" class="button">
       Book Now →
     </a>
   </div>
   
   <!-- Related Events -->
   <div class="related">
     [Collection List - Same Category]
     Limit: 3
   </div>
   ```

## CMS Collection Fields

```yaml
Events Collection:
  - Name (Text) *Required
  - Slug (Slug) *Auto-generated
  - Studio (Text) *Required
  - Location (Text) *Required
  - Address (Text) *Required
  - Event Date (Date) *Required
  - Time (Text) *Required
  - Price (Text) *Required
  - Description (Rich Text) *Required
  - Featured Image (Image)
  - Book Link (Link)
  - Category (Option) - Fitness/Arts/Culinary/etc
  - Featured (Switch) - For homepage
  - Instagram URL (Link)
  - Status (Option) - Active/Sold Out/Cancelled
```

## Working with Filters (No Code Required!)

### Option 1: URL Parameters (Simple)
- Link to `/events?category=fitness`
- Use Webflow's built-in filter options

### Option 2: Finsweet Attributes (Free)
- Add [Finsweet CMS Filter](https://finsweet.com/attributes/cms-filter)
- No coding required
- Real-time filtering

### Option 3: Multiple Collection Lists
- Add several lists on Events page
- Each filtered differently
- Show/hide with tabs

## WhaleSync Integration Points

### When WhaleSync is Connected:
1. **Airtable → Webflow Sync**
   - New events appear automatically
   - Updates sync in real-time
   - Deleted events removed

2. **Field Mapping**
   ```
   Airtable Field → Webflow Field
   name → Name
   studio → Studio
   location → Location
   event_date → Event Date
   time → Time
   price → Price
   description → Description
   image_url → Featured Image
   booking_url → Book Link
   category → Category
   ```

## Maximizing the Starter Plan

### DO:
✅ Use CMS for all event content (unlimited pages!)
✅ Keep static pages minimal and functional
✅ Use Collection Lists with filters
✅ Leverage the template page fully
✅ Use Webflow interactions for dynamic behavior

### DON'T:
❌ Create separate static pages for categories
❌ Make an About or Contact page (put in footer)
❌ Create duplicate content pages
❌ Waste pages on rarely-visited content

## URL Structure

```
yoursite.com/                    (Page 1: Homepage)
yoursite.com/events              (Page 2: All Events)
yoursite.com/events/pottery-101  (CMS: Individual event)
yoursite.com/events/yoga-basics  (CMS: Individual event)
yoursite.com/events/paint-night  (CMS: Individual event)
... hundreds more event pages ... (CMS: All free!)
```

## Next Steps

1. **Create Events CMS Collection** with all fields
2. **Design Homepage** with featured events
3. **Create Events page** with full listing
4. **Style Event Template** for individual events
5. **Connect WhaleSync** when ready
6. **Test with sample data** before going live

## Pro Tips

💡 **Homepage Strategy**: Make it dynamic with "Today's Events" and "This Week's Highlights" using Collection Lists with date filters

💡 **Events Page**: Use tabs or accordions to show different categories without multiple pages

💡 **SEO**: Each CMS event page can have unique meta descriptions and titles

💡 **Performance**: Enable lazy loading for images in Collection Lists

💡 **Mobile**: Design mobile-first since most users will browse events on phones

---

*With this setup, your 2-page limit becomes a non-issue. You'll have hundreds of event pages through CMS while keeping your static pages focused and efficient!*