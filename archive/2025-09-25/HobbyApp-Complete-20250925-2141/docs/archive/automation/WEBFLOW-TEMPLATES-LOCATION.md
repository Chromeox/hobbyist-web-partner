# 📍 Where to Find Templates in Webflow

## Template Locations in Webflow Designer

### 1. CMS Collection Templates
**Path: CMS Panel → Events Collection → Template**
- Click the **CMS** icon (database icon) in left sidebar
- Click your **Events** collection
- Click **"Template"** or the template page that appears
- This is where you design how individual events display

### 2. Static Page Templates
**Path: Pages Panel → + New Page**
- Click **Pages** icon (document icon) in left sidebar
- Click **"+ Create New Page"** button
- Choose from:
  - Blank page
  - Pre-designed templates (if available in your plan)

### 3. Creating Your Events Pages

#### A. Events List Page (All Events)
1. Go to **Pages** panel
2. Click **"+ Create New Page"**
3. Name it: `Events` (URL: /events)
4. Add a **Collection List** element
5. Connect it to your Events collection

#### B. Individual Event Template
1. Go to **CMS** panel
2. Click **Events** collection
3. The template page auto-created will be: `Events Template`
4. This controls how each event looks when clicked

#### C. Category Pages (Optional)
1. Create static pages for each category:
   - `/events/fitness`
   - `/events/arts`
   - `/events/culinary`
2. Add filtered Collection Lists on each

## Quick Setup Steps

### Step 1: Create CMS Collection First
```
CMS Panel → + New Collection → Name: "Events"
```

### Step 2: Design Collection Template
```
CMS Panel → Events → Events Template (auto-created)
```

### Step 3: Create List Page
```
Pages Panel → + New Page → Name: "Events"
Add Collection List → Connect to Events
```

## Visual Guide

```
Webflow Designer Layout:
┌─────────────────────────────────────┐
│  Top Navigation Bar                 │
├──────┬──────────────────────────────┤
│      │                              │
│  L   │     Canvas/Design Area       │
│  E   │                              │
│  F   │   (Your page design)         │
│  T   │                              │
│      │                              │
│  S   │                              │
│  I   │                              │
│  D   │                              │
│  E   │                              │
│  B   │                              │
│  A   │                              │
│  R   │                              │
│      │                              │
└──────┴──────────────────────────────┘

Left Sidebar Icons (top to bottom):
1. 📄 Pages (static pages)
2. 🗂️ CMS (collections & templates)
3. 🎨 Style Manager
4. ⚙️ Settings
```

## Common Confusion Points

❌ **Wrong**: Looking for templates in project settings
✅ **Right**: Templates are in CMS panel for collections

❌ **Wrong**: Trying to find pre-made event templates
✅ **Right**: You create the template by designing the collection template page

❌ **Wrong**: Looking for a "Templates" menu item
✅ **Right**: Each CMS collection automatically gets a template page

## Next Steps

1. **Create Events CMS Collection** (if not done)
2. **Click into the Events Template** to design it
3. **Add elements** like:
   - Event title (bind to Name field)
   - Event date (bind to Event Date field)
   - Price (bind to Price field)
   - Book button (bind to Book Link field)

---

*Tip: The template is where you design once, and it applies to all events automatically!*