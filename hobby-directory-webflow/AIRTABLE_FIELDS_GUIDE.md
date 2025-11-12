# Airtable Fields Setup Guide
## Adding 11 Missing Fields for WhaleSync Integration

**Your Base**: https://airtable.com/appo3x0WjbCIhA0Lz/tblEW9fdX42oQpulK

---

## Current State ✅

You already have these 8 fields:
- Name, Description, Date, Price, Status
- Studio (linked to Studios table)
- Category (linked to Categories table)
- Location (linked to Locations table)

---

## Fields to Add (11 Total)

### 1. Image_URL
**Type**: URL
**Purpose**: Primary image displayed on website
**Instructions**:
1. Click the `+` icon to add new field
2. Name: `Image_URL`
3. Field type: URL
4. Leave empty for now (add later via AI generation or manual upload)

**Example**: `https://via.placeholder.com/800x450?text=Pottery+Class`

---

### 2. Slug
**Type**: Formula
**Purpose**: Auto-generate URL-friendly class names for Webflow pages
**Instructions**:
1. Click `+` to add field
2. Name: `Slug`
3. Field type: Formula
4. Formula: `LOWER(SUBSTITUTE(Name, " ", "-"))`

**How it works**:
- "Beginner Pottery Workshop" → "beginner-pottery-workshop"
- This becomes the URL: `yoursite.com/classes/beginner-pottery-workshop`

---

### 3. Featured
**Type**: Checkbox
**Purpose**: Mark classes to appear on homepage
**Instructions**:
1. Click `+` to add field
2. Name: `Featured`
3. Field type: Checkbox
4. Default: Unchecked

**Usage**: Check this box for 3-6 classes you want highlighted on homepage

---

### 4. Booking_Link
**Type**: URL
**Purpose**: External booking page (Mindbody, Eventbrite, studio website)
**Instructions**:
1. Click `+` to add field
2. Name: `Booking_Link`
3. Field type: URL
4. Leave empty if no external booking

**Example**: `https://studiobookings.com/pottery-jan-25`

---

### 5. Full_Address
**Type**: Single Line Text
**Purpose**: Complete address for Google Maps embedding
**Instructions**:
1. Click `+` to add field
2. Name: `Full_Address`
3. Field type: Single Line Text

**Example**: `123 Main St, Vancouver, BC V6A 1A1, Canada`

---

### 6. Spots_Remaining
**Type**: Number
**Purpose**: Track class availability, show "Only 3 spots left!" badges
**Instructions**:
1. Click `+` to add field
2. Name: `Spots_Remaining`
3. Field type: Number
4. Number format: Integer
5. Allow negative: No

**Example**: `8` (out of 12 total spots)

**WhaleSync automation**: This field can be updated in real-time if studios use API integration

---

### 7. Instructor_Name
**Type**: Single Line Text (or Link to Instructors table)
**Purpose**: Display instructor name on class page

**Option A - Simple Text**:
1. Click `+` to add field
2. Name: `Instructor_Name`
3. Field type: Single Line Text

**Option B - Linked Record** (if you have Instructors table):
1. Field type: Link to another record
2. Link to: Instructors table
3. Allow linking to multiple records: No

**Example**: `Sarah Johnson` or link to instructor profile

---

### 8. Duration_Minutes
**Type**: Number
**Purpose**: Show class length (90 min, 120 min, etc.)
**Instructions**:
1. Click `+` to add field
2. Name: `Duration_Minutes`
3. Field type: Number
4. Number format: Integer

**Example**: `90` (displays as "90 minutes" or "1.5 hours" on website)

---

### 9. Skill_Level
**Type**: Single Select
**Purpose**: Filter classes by difficulty, set expectations
**Instructions**:
1. Click `+` to add field
2. Name: `Skill_Level`
3. Field type: Single Select
4. Add options:
   - Beginner (color: Green)
   - Intermediate (color: Yellow)
   - Advanced (color: Orange)
   - All Levels (color: Blue)

**Default**: All Levels

---

### 10. Instagram_Post_URL
**Type**: URL
**Purpose**: Link back to original Instagram post for attribution
**Instructions**:
1. Click `+` to add field
2. Name: `Instagram_Post_URL`
3. Field type: URL

**Example**: `https://instagram.com/p/ABC123xyz`

**Integration**: Your Instagram scraper can populate this automatically

---

### 11. Image_Source
**Type**: Single Select
**Purpose**: Track where image came from for management
**Instructions**:
1. Click `+` to add field
2. Name: `Image_Source`
3. Field type: Single Select
4. Add options:
   - AI Generated (color: Purple)
   - Studio Uploaded (color: Blue)
   - Manual Upload (color: Green)
   - Instagram Embedded (color: Orange)

**Default**: AI Generated

---

## Recommended Field Order

After adding all fields, drag to reorder for best workflow:

1. Name ✅
2. Slug (NEW - auto-generates)
3. Featured (NEW - homepage checkbox)
4. Description ✅
5. Image_URL (NEW)
6. Image_Source (NEW)
7. Date ✅
8. Duration_Minutes (NEW)
9. Instructor_Name (NEW)
10. Skill_Level (NEW)
11. Price ✅
12. Spots_Remaining (NEW)
13. Status ✅
14. Studio ✅ (linked)
15. Category ✅ (linked)
16. Location ✅ (linked)
17. Full_Address (NEW)
18. Booking_Link (NEW)
19. Instagram_Post_URL (NEW)

---

## Populate Your 3 Existing Classes

Now that fields are added, fill in the data for your 3 classes:

### For "Beginner Pottery Workshop" (and others):

1. **Slug**: Will auto-generate from Name (beginner-pottery-workshop)
2. **Featured**: Check this box if you want it on homepage
3. **Image_URL**: Use AI to generate image (see AIRTABLE_IMAGE_SETUP.md)
4. **Image_Source**: Select "AI Generated"
5. **Duration_Minutes**: `120` (2 hours)
6. **Instructor_Name**: Add instructor name
7. **Skill_Level**: Select "Beginner"
8. **Spots_Remaining**: `8` (out of 12 total)
9. **Full_Address**: `[Studio's full address]`
10. **Booking_Link**: `[Studio's booking page URL if available]`
11. **Instagram_Post_URL**: Leave empty for now

---

## Create 3 Airtable Views

After fields are added, create these views for WhaleSync:

### View 1: "Active Classes" (Main Sync View)
**Purpose**: Only active, future classes appear on website

**Steps**:
1. Click "Grid view" dropdown → "Create new view"
2. Name: `Active Classes`
3. Add filters:
   - Status = "Active" (or "active" - check your exact value)
   - Date is after → "today"
4. Sort by: Date (ascending)
5. Save view

**This is the view WhaleSync will sync to Webflow**

---

### View 2: "Featured Classes" (Homepage Hero)
**Purpose**: Handpicked classes for homepage spotlight

**Steps**:
1. Create new view: `Featured Classes`
2. Add filters:
   - Featured is checked
   - Status = "Active"
   - Date is after → "today"
3. Sort by: Date (ascending)
4. Limit: 6 records (if Airtable Pro plan)

**WhaleSync can create separate sync for this view**

---

### View 3: "All Classes - Admin" (Your Management View)
**Purpose**: See everything including pending, inactive, past classes

**Steps**:
1. Create new view: `All Classes - Admin`
2. No filters (show everything)
3. Sort by: Date (descending, most recent first)
4. Include all fields

**This is your control center - not synced to Webflow**

---

## Verification Checklist

Before moving to WhaleSync setup, verify:

- [ ] All 11 new fields added to Classes table
- [ ] Slug field auto-generating from Name
- [ ] 3 classes have complete data filled in
- [ ] Image_URL populated (at minimum use placeholder: `https://via.placeholder.com/800x450?text=Class+Image`)
- [ ] Featured checkbox works
- [ ] Skill_Level options configured
- [ ] "Active Classes" view shows only active, future classes
- [ ] "Featured Classes" view shows only checked Featured classes
- [ ] "All Classes - Admin" view shows all classes

---

## Test Your Setup

Run the test script to verify fields are visible:

```bash
cd /Users/chromefang.exe/HobbyApp/hobby-directory-webflow
node test-airtable.js
```

**Expected output**:
```
✅ Successfully connected! Found 3 classes:

📅 Beginner Pottery Workshop
   Fields available: Name, Description, Date, Price, Status, Studio, Category,
   Location, Slug, Featured, Image_URL, Image_Source, Booking_Link, Full_Address,
   Spots_Remaining, Instructor_Name, Duration_Minutes, Skill_Level, Instagram_Post_URL
```

---

## Next Steps

Once all fields are added and populated:

1. ✅ Mark this task complete
2. 🔄 Move to WhaleSync setup (Phase 3)
3. 🎨 Begin Webflow CMS creation (Phase 4)

---

## Troubleshooting

**Q: Slug formula not working?**
A: Make sure formula is exactly: `LOWER(SUBSTITUTE(Name, " ", "-"))`

**Q: Can't see new fields in test script?**
A: Airtable API caches. Wait 1-2 minutes or refresh your API key.

**Q: Should I add fields to Studios/Categories/Locations tables too?**
A: Not yet! We'll address those in Phase 3 when mapping WhaleSync.

**Q: Do I need to fill in ALL fields for all classes?**
A: Minimum required: Name, Date, Price, Status, Image_URL, Slug. Others can be empty initially.

---

## Time Estimate

- Adding 11 fields: 15 minutes
- Filling data for 3 classes: 15 minutes
- Creating 3 views: 10 minutes
- **Total: 40 minutes**

Take your time - accurate data setup now saves hours of debugging later!
