# 🖱️ Webflow Click-by-Click Guide

## First: Create Your CMS Collection

### Step 1: Open CMS Panel
1. Click **CMS** icon in left sidebar (looks like stacked rectangles 🗂️)
2. Click blue **"+ Create New Collection"** button

### Step 2: Name Your Collection
1. Type: **Events** (plural)
2. Singular name: **Event** (auto-fills)
3. Click **"Create Collection"**

### Step 3: Add Fields (One by One)
Click **"+ Add New Field"** for each:

1. **Name Field**
   - Choose: "Plain Text"
   - Name: `Name`
   - Required: ✓ Check
   - Click "Save Field"

2. **Studio Field**
   - Choose: "Plain Text"
   - Name: `Studio`
   - Required: ✓ Check
   - Click "Save Field"

3. **Event Date Field**
   - Choose: "Date/Time"
   - Name: `Event Date`
   - Time: Leave OFF
   - Required: ✓ Check
   - Click "Save Field"

4. **Price Field**
   - Choose: "Plain Text"
   - Name: `Price`
   - Required: ✓ Check
   - Click "Save Field"

5. **Description Field**
   - Choose: "Rich Text"
   - Name: `Description`
   - Required: ✓ Check
   - Click "Save Field"

6. Continue adding remaining fields...

Click **"Save Collection"** when done

---

## Building Page 1: Homepage

### Step 1: Go to Pages
1. Click **Pages** icon in left sidebar (looks like document 📄)
2. Click on **"Home"** (already exists)

### Step 2: Add a Section
1. Click the **"+"** button (top left of canvas or press A key)
2. Navigate to: **Layout** section
3. Drag **"Section"** onto the page

### Step 3: Add Hero Content
1. With Section selected, click **"+"** again
2. Navigate to: **Basic** section
3. Drag **"Heading"** into the Section
4. Double-click heading and type: "Vancouver Creative Workshops"
5. Click **"+"** again
6. Drag **"Paragraph"** below heading
7. Type: "Find your next hobby adventure"

### Step 4: Add Today's Events (Collection List)
1. Click **"+"** button
2. Navigate to: **Components** section (scroll down)
3. Find **"Collection List"** (has grid icon)
4. Drag it below your hero section

### Step 5: Connect Collection List
1. **Purple settings panel appears** on right
2. Under "Collection" dropdown, select: **Events**
3. Click **"+ Add Filter"**
   - Field: Event Date
   - Condition: Is On or After
   - Value: Today (use calendar icon)
4. Click **"+ Add Limit"**
   - Items: 6
5. Click **"Save"**

### Step 6: Design Collection Item
1. Inside the Collection List, you'll see "Collection Item"
2. Click **"+"** to add elements inside it:
   - Add **"Image"** → Settings → Get Image From: Events → Featured Image
   - Add **"Text Block"** → Settings → Get Text From: Events → Name
   - Add **"Text Block"** → Settings → Get Text From: Events → Studio
   - Add **"Text Block"** → Settings → Get Text From: Events → Price

---

## Building Page 2: Events Directory

### Step 1: Create New Page
1. Click **Pages** icon (left sidebar)
2. Click **"+ Create New Page"** button (top of panel)
3. Page Name: **Events**
4. Page Slug: **events** (auto-fills)
5. Click **"Create"**

### Step 2: Add Page Structure
1. Click **"+"** → **Layout** → Drag **"Section"**
2. Inside Section, add **"Container"** (for max-width)
3. Inside Container, add **"Heading"**: "All Events"

### Step 3: Add Collection List
1. Click **"+"** → **Components** → **"Collection List"**
2. Drag below heading (inside Container)

### Step 4: Configure Collection List
Right panel settings:
1. Collection: **Events**
2. Sort Order: 
   - Sort By: Event Date
   - Direction: Closest to Furthest
3. Limit: 20 items
4. Pagination: Turn ON
   - Type: "Load More" or "Page Numbers"

### Step 5: Style as Grid
1. Select the **"Collection List"** (not individual items)
2. In Style panel (paintbrush icon 🎨):
   - Display: Grid
   - Columns: 3
   - Gap: 20px
3. For mobile (use device icons at top):
   - Columns: 1

### Step 6: Design Each Event Card
Inside Collection Item, structure like this:
```
Collection Item (make it a link)
├── Image (Featured Image field)
├── Div Block (for text content)
    ├── Heading (Name field)
    ├── Text (Studio field)
    ├── Text (Event Date field)
    └── Text (Price field)
```

To make whole card clickable:
1. Select **"Collection Item"**
2. Settings panel → Link Settings
3. Page: Events (Collection Page)

---

## Common "Where Is It?" Solutions

### Can't find Collection List?
- Click **"+"** button (or press A)
- Scroll down to **"Components"** section
- It's the 3rd item (grid icon)

### Can't connect to CMS fields?
- Select the element (text, image, etc.)
- Look for **purple settings** panel on right
- Click dropdown "Get ___ from Events"

### Can't see my changes?
- Click **"Publish"** button (top right, blue)
- Select your domain
- Click **"Publish to Selected Domains"**

### Collection List is empty?
1. Go to CMS panel
2. Click your Events collection
3. Click **"+ New Event"** to add test data
4. Fill required fields
5. Toggle "Save as Draft" OFF
6. Click **"Create"**

---

## Testing Your Setup

### Add Test Event:
1. CMS panel → Events → "+ New Event"
2. Fill in:
   - Name: "Pottery Workshop"
   - Studio: "Claymates Studio"
   - Event Date: (pick future date)
   - Price: "$45"
   - Description: "Learn pottery basics"
3. Save (not as draft)

### Preview:
1. Click **"Preview"** button (eye icon, top bar)
2. Navigate between pages
3. Click an event to see template page

---

## Keyboard Shortcuts

- **A** - Add element (opens + panel)
- **V** - Preview mode
- **Esc** - Deselect element
- **D** - Show/hide element borders
- **Cmd/Ctrl + S** - Save
- **Cmd/Ctrl + Shift + P** - Publish

---

## Still Stuck?

### Elements Panel Missing?
The **"+"** button might be:
- Top left of canvas
- In the left toolbar
- Press **A** key as shortcut

### Purple Settings Not Showing?
- Make sure element is selected (blue outline)
- Settings panel is on the right side
- May need to close Style panel first

### Collection Not Working?
1. Ensure CMS Collection is created first
2. Must have at least one test item
3. Items must not be drafts
4. Try refreshing the Designer

---

*Pro Tip: Webflow University has video tutorials for each of these steps. Search "Webflow CMS tutorial" if you need visual guidance!*