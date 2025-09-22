# 🌐 Webflow Setup Guide for Hobby Directory

## Step 1: Create CMS Collection

### In Webflow Designer:
1. Go to **CMS** panel (left sidebar)
2. Click **+ Create New Collection**
3. Name it: `Events`
4. Add these fields:

#### Required Text Fields
- **Name** (Plain Text)
  - Name: `Name`
  - Required: Yes
  - Help text: "Event title"

- **Slug** (Slug)
  - Auto-generated from Name

- **Studio** (Plain Text)
  - Name: `Studio`
  - Required: Yes
  - Help text: "Organization name"

- **Location** (Plain Text)
  - Name: `Location`
  - Required: Yes

- **Address** (Plain Text)
  - Name: `Address`
  - Required: Yes

- **Time** (Plain Text)
  - Name: `Time`
  - Required: Yes
  - Help text: "e.g., 7:00 PM"

- **Price** (Plain Text)
  - Name: `Price`
  - Required: Yes
  - Help text: "Include $ symbol"

#### Date Field
- **Event Date** (Date/Time)
  - Name: `Event Date`
  - Required: Yes
  - Time: Disabled

#### Rich Content
- **Description** (Rich Text)
  - Name: `Description`
  - Required: Yes

#### Links & Media
- **Image** (Image)
  - Name: `Featured Image`
  - Required: No

- **Book Link** (Link)
  - Name: `Book Link`
  - Required: No
  - Open in new tab: Yes

#### Categories & Status
- **Category** (Option)
  - Name: `Category`
  - Options:
    - Fitness
    - Arts & Crafts
    - Culinary
    - Wellness
    - Outdoor
    - Photography
    - Dance
    - Music
    - Tech

- **Status** (Switch)
  - Name: `Published`
  - Default: On

- **Featured** (Switch)
  - Name: `Featured`
  - Default: Off
  - Help text: "Show on homepage"

#### Meta Fields
- **Instagram URL** (Link)
  - Name: `Instagram URL`
  - Required: No

- **Scraped Date** (Date/Time)
  - Name: `Added Date`
  - Default: Created date

---

## Step 2: Design Template Pages

### Events List Page (`/events`)

```html
<!-- Filter Bar -->
<div class="filter-bar">
  <select id="category-filter">
    <option value="">All Categories</option>
    <option value="fitness">Fitness</option>
    <option value="arts">Arts & Crafts</option>
    <!-- etc -->
  </select>
  
  <select id="date-filter">
    <option value="">All Dates</option>
    <option value="today">Today</option>
    <option value="tomorrow">Tomorrow</option>
    <option value="week">This Week</option>
  </select>
  
  <select id="price-filter">
    <option value="">Any Price</option>
    <option value="free">Free</option>
    <option value="25">Under $25</option>
    <option value="50">Under $50</option>
  </select>
</div>

<!-- Events Grid -->
<div class="events-grid">
  <!-- CMS Collection List -->
  <!-- Sort by: Event Date (closest first) -->
  <!-- Filter: Event Date is after yesterday -->
  <!-- Limit: 20 items -->
</div>
```

### Event Detail Page (`/events/[slug]`)

```html
<div class="event-hero">
  <img src="[Featured Image]" alt="[Name]">
  <div class="event-meta">
    <h1>[Name]</h1>
    <p class="studio">[Studio]</p>
    <p class="date-time">[Event Date] at [Time]</p>
    <p class="location">[Location]</p>
    <p class="price">[Price]</p>
  </div>
</div>

<div class="event-content">
  <div class="description">
    [Description - Rich Text]
  </div>
  
  <a href="[Book Link]" class="book-button" target="_blank">
    Book Now
  </a>
  
  <a href="[Instagram URL]" class="social-link">
    View on Instagram
  </a>
</div>

<!-- Related Events -->
<div class="related-events">
  <!-- Collection List: Same category, limit 3 -->
</div>
```

---

## Step 3: WhaleSync Configuration

### Prerequisites
1. Airtable account with Events table
2. Webflow site with Events CMS collection
3. WhaleSync account (free tier works)

### Setup Steps

1. **In WhaleSync Dashboard**
   - Click "Create New Sync"
   - Name: "Hobby Directory Events"

2. **Connect Airtable**
   - Select your base
   - Choose "Events" table
   - Authenticate with Airtable API key

3. **Connect Webflow**
   - Select your site
   - Choose "Events" collection
   - Authenticate with Webflow API key

4. **Field Mapping**
   ```
   Airtable → Webflow
   name → Name
   slug → Slug
   studio → Studio
   location → Location
   address → Address
   Event Date → Event Date
   Time → Time
   price → Price
   Description → Description
   Image URL → Featured Image (URL)
   Book Link → Book Link
   Tags → Category (map values)
   Webflow status → Published (map to switch)
   ```

5. **Sync Settings**
   - Direction: Airtable → Webflow (one-way)
   - Frequency: Every 5 minutes
   - Conflict resolution: Airtable wins
   - Delete behavior: Don't delete in Webflow

6. **Test Sync**
   - Add test event in Airtable
   - Click "Sync Now"
   - Verify in Webflow CMS

---

## Step 4: Webflow Interactions & Features

### Auto-hide Past Events
Add this to page custom code:
```javascript
<script>
// Hide past events
document.addEventListener('DOMContentLoaded', function() {
  const events = document.querySelectorAll('.event-item');
  const today = new Date();
  today.setHours(0,0,0,0);
  
  events.forEach(event => {
    const dateStr = event.dataset.eventDate;
    const eventDate = new Date(dateStr);
    
    if (eventDate < today) {
      event.style.display = 'none';
    }
  });
});
</script>
```

### Dynamic Filters
```javascript
// Category filter
document.getElementById('category-filter').addEventListener('change', function(e) {
  const category = e.target.value;
  const events = document.querySelectorAll('.event-item');
  
  events.forEach(event => {
    if (!category || event.dataset.category === category) {
      event.style.display = 'block';
    } else {
      event.style.display = 'none';
    }
  });
});
```

### "Happening Today" Badge
```javascript
// Add "Today" badge
document.querySelectorAll('.event-item').forEach(event => {
  const dateStr = event.dataset.eventDate;
  const eventDate = new Date(dateStr);
  const today = new Date();
  
  if (eventDate.toDateString() === today.toDateString()) {
    const badge = document.createElement('span');
    badge.className = 'today-badge';
    badge.textContent = 'TODAY';
    event.appendChild(badge);
  }
});
```

---

## Step 5: SEO & Performance

### SEO Settings (per event)
- **Title**: `[Name] - [Studio] | Vancouver Events`
- **Description**: `Join [Studio] for [Name] on [Event Date]. [Description snippet]`
- **OG Image**: Featured Image

### Performance Optimizations
1. **Lazy load images**
2. **Paginate after 20 events**
3. **Cache API responses for 5 minutes**
4. **Compress images to <200KB**

### Structured Data (JSON-LD)
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "[Name]",
  "startDate": "[Event Date]T[Time]",
  "location": {
    "@type": "Place",
    "name": "[Location]",
    "address": "[Address]"
  },
  "organizer": {
    "@type": "Organization",
    "name": "[Studio]"
  },
  "offers": {
    "@type": "Offer",
    "price": "[Price]",
    "priceCurrency": "CAD",
    "url": "[Book Link]"
  }
}
</script>
```

---

## Step 6: Launch Checklist

### Before Going Live
- [ ] Test WhaleSync with 10 events
- [ ] Verify all fields map correctly
- [ ] Check responsive design
- [ ] Test booking links open correctly
- [ ] Verify past events are hidden
- [ ] Test search/filter functionality
- [ ] Add Google Analytics
- [ ] Submit sitemap to Google
- [ ] Test page load speed (<3s)
- [ ] Add favicon and meta tags

### After Launch
- [ ] Monitor first sync cycle
- [ ] Check for broken images
- [ ] Verify daily updates work
- [ ] Set up error alerts
- [ ] Create backup export

---

## 🚀 Quick Start Commands

```bash
# Check today's events ready for Webflow
./6-view-todays-events.sh

# Export to CSV for Airtable import
./8-export-to-csv.sh

# Monitor live scraping
./2-monitor-live.sh
```

---

## 📊 Success Metrics

Week 1 Goals:
- 50+ events live on site
- All categories represented
- <5% broken links
- 95% uptime

Month 1 Goals:
- 200+ events
- 1000+ page views
- 50+ booking clicks
- SEO indexing complete

---

*Ready to launch your Vancouver Hobby Directory!*