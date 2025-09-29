# 🔗 Airtable → Webflow Field Mapping Guide

## Airtable Base Structure

### Table: Events
The main table that WhaleSync will sync to Webflow

```
Airtable Fields (Current from Google Sheets):
├── name (Single line text)
├── studio (Single line text)
├── location (Single line text)
├── address (Single line text)
├── Event Date (Date)
├── Time (Single line text)
├── price (Single line text)
├── Description (Long text)
├── Image URL (URL)
├── Book Link (URL)
├── Tags (Multiple select)
├── Instagram URL (URL)
├── Webflow status (Single select: Draft/Published)
├── confidence_score (Number)
├── scraped_batch (Single line text)
└── Added Date (Created time)
```

## Webflow CMS Collection: Events

### Required Field Mappings

| Airtable Field | → | Webflow Field | Type | Notes |
|----------------|---|---------------|------|-------|
| name | → | Name | Plain Text | Required, used for title |
| studio | → | Studio | Plain Text | Organization name |
| location | → | Location | Plain Text | Venue name |
| address | → | Address | Plain Text | Full address |
| Event Date | → | Event Date | Date/Time | No time component |
| Time | → | Time | Plain Text | "7:00 PM" format |
| price | → | Price | Plain Text | Include "$" symbol |
| Description | → | Description | Rich Text | Event details |
| Image URL | → | Featured Image | Image | URL to image |
| Book Link | → | Book Link | Link | External URL |
| Tags | → | Category | Option | Map to single choice |
| Webflow status | → | _draft | Switch | Controls publishing |

### Optional Field Mappings

| Airtable Field | → | Webflow Field | Type | Purpose |
|----------------|---|---------------|------|---------|
| Instagram URL | → | Instagram URL | Link | Social proof |
| confidence_score | → | Quality Score | Number | For filtering |
| Added Date | → | Added Date | Date/Time | Sorting by newest |
| scraped_batch | → | Source Batch | Plain Text | Debugging |

## WhaleSync Configuration

### Step 1: Airtable Setup
```yaml
Base Settings:
  - Create new base: "Hobby Directory"
  - Import CSV from Google Sheets export
  - Ensure field types match above
  - Add primary view: "All Events"
  - Add filtered view: "Published Events"
```

### Step 2: Webflow Collection Setup
```yaml
Collection Name: Events
Singular Name: Event
Collection ID: (auto-generated)

Fields to Create:
  1. Name (Text) - Required ✓
  2. Slug (Slug) - Auto from Name
  3. Studio (Text) - Required ✓
  4. Location (Text) - Required ✓
  5. Address (Text) - Required ✓
  6. Event Date (Date) - Required ✓
  7. Time (Text) - Required ✓
  8. Price (Text) - Required ✓
  9. Description (Rich Text) - Required ✓
  10. Featured Image (Image)
  11. Book Link (Link)
  12. Category (Option):
      - Fitness
      - Arts & Crafts
      - Culinary
      - Wellness
      - Outdoor
      - Photography
      - Dance
      - Music
      - Tech
  13. Instagram URL (Link)
  14. Quality Score (Number)
  15. Added Date (Date)
  16. Source Batch (Text)
  17. Featured (Switch) - For homepage
```

### Step 3: WhaleSync Connection

1. **In WhaleSync Dashboard:**
   ```
   New Sync → Name: "Hobby Events"
   ```

2. **Connect Airtable:**
   ```
   - Base: Hobby Directory
   - Table: Events
   - View: Published Events (filtered)
   - API Key: (from Airtable account)
   ```

3. **Connect Webflow:**
   ```
   - Site: Your site name
   - Collection: Events
   - API Key: (from Webflow settings)
   ```

4. **Field Mapping:**
   ```
   Direction: Airtable → Webflow (one-way)
   Update Mode: Overwrite
   
   Map each field as shown in table above
   Special mappings:
   - Tags → Category (pick first value)
   - Webflow status → _draft (Published = false for Draft)
   - Image URL → Featured Image (as URL)
   ```

5. **Sync Settings:**
   ```
   Frequency: Every 5 minutes
   Conflict: Airtable wins
   Deletion: Don't delete in Webflow
   Auto-publish: Yes (if status = Published)
   ```

## Data Transformation Rules

### Price Field
```javascript
// Airtable formula to ensure $ symbol
IF(
  LEFT(price, 1) != "$",
  CONCATENATE("$", price),
  price
)
```

### Category Mapping
```javascript
// Map Instagram account types to categories
IF(
  OR(FIND("rumble", LOWER(studio)), FIND("yoga", LOWER(studio))),
  "Fitness",
  IF(
    OR(FIND("paint", LOWER(studio)), FIND("pottery", LOWER(studio))),
    "Arts & Crafts",
    IF(
      OR(FIND("cook", LOWER(studio)), FIND("bake", LOWER(studio))),
      "Culinary",
      "Wellness"
    )
  )
)
```

### Event Status
```javascript
// Auto-draft old events
IF(
  Event Date < TODAY(),
  "Draft",
  "Published"
)
```

## Testing Checklist

### Before First Sync:
- [ ] Create test event in Airtable
- [ ] All required fields filled
- [ ] Image URL is valid
- [ ] Book Link works
- [ ] Category selected
- [ ] Status set to Published

### After First Sync:
- [ ] Event appears in Webflow CMS
- [ ] All fields mapped correctly
- [ ] Image loads properly
- [ ] Slug generated correctly
- [ ] Can preview in Webflow

### Production Testing:
- [ ] Bulk import 10 events
- [ ] Check sync time (<5 min)
- [ ] Verify no duplicates
- [ ] Test filtering works
- [ ] Check mobile display

## Common Issues & Solutions

### Issue: Images not showing
**Solution**: Ensure Image URL field contains direct image links (not Instagram posts)

### Issue: Events not syncing
**Solution**: Check Webflow status field = "Published" in Airtable

### Issue: Duplicate events
**Solution**: Use Airtable Record ID as unique identifier in WhaleSync

### Issue: Category not mapping
**Solution**: Ensure Airtable values exactly match Webflow options

### Issue: Old events showing
**Solution**: Add Airtable formula to auto-draft past events

## Data Pipeline Flow

```
Instagram Scraper (10 AM daily)
    ↓
Google Sheets (temporary storage)
    ↓
CSV Export (manual/automated)
    ↓
Airtable Import (CSV upload)
    ↓
WhaleSync (5-min intervals)
    ↓
Webflow CMS (live site)
    ↓
Public Website (yoursite.com/events)
```

## Next Steps

1. **Set up Airtable base** with exact field structure
2. **Import test data** from Google Sheets
3. **Create Webflow collection** with matching fields
4. **Configure WhaleSync** with field mappings
5. **Run test sync** with 5-10 events
6. **Verify on Webflow** test domain
7. **Go live** with full dataset

---

*Pro Tip: Start with a small test batch to verify mappings before syncing hundreds of events!*