# 🛠️ Airtable Setup for Manual Directory

**Step-by-step guide to set up your Events database**

## Step 1: Create New Base

1. Go to https://airtable.com
2. Click "+ Create" → "Start from scratch"
3. Name it: "Hobby Directory"
4. Rename the default table to "Events"

## Step 2: Set Up Fields

**Delete the default fields and create these:**

### Required Fields

1. **Name** (Single line text)
   - Description: "Event title"
   - Example: "Pottery Wheel Workshop"

2. **Studio** (Single line text)
   - Description: "Organizer/studio name"
   - Example: "Clay Mates Studio"

3. **Event Date** (Date)
   - Include time: No
   - Date format: Local (DD/MM/YYYY)
   - Example: "15/12/2024"

4. **Time** (Single line text)
   - Description: "Event time with AM/PM"
   - Example: "7:00 PM"

5. **Location** (Single line text)
   - Description: "Venue name"
   - Example: "Main Street Studio"

6. **Address** (Single line text)
   - Description: "Full address"
   - Example: "123 Main St, Vancouver BC"

7. **Price** (Single line text)
   - Description: "Include $ symbol"
   - Example: "$45" or "Free"

8. **Description** (Long text)
   - Rich text formatting: Yes
   - Description: "Event details and description"

9. **Category** (Single select)
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
     - Other

10. **Status** (Single select)
    - Options:
      - Draft
      - Published
      - Expired
    - Default: Draft

### Optional Fields

11. **Book Link** (URL)
    - Description: "Registration/booking URL"

12. **Image URL** (URL)
    - Description: "Event photo URL"

13. **Instagram URL** (URL)
    - Description: "Related Instagram post"

14. **Featured** (Checkbox)
    - Description: "Show on homepage"

15. **Added By** (Single line text)
    - Description: "Who added this event"
    - Example: "Manual", "Studio Form", "User Submission"

16. **Notes** (Long text)
    - Description: "Internal notes"

## Step 3: Create Views

### View 1: All Events (Default)
- Shows all records
- Sort by: Event Date (Newest first)

### View 2: Published Events
- Filter: Status = "Published"
- Sort by: Event Date (Oldest first)
- **Use this view for WhaleSync**

### View 3: This Week
- Filter: Event Date is within "next 7 days"
- Status = "Published"
- Sort by: Event Date

### View 4: Draft Events
- Filter: Status = "Draft"
- Sort by: Created time (Newest first)

### View 5: Featured Events
- Filter: Featured = True
- Status = "Published"

### View 6: By Category
- Group by: Category
- Filter: Status = "Published"
- Sort by: Event Date

## Step 4: Set Up Form View

1. Click "+ Create" next to views
2. Choose "Form"
3. Name it: "Submit Event"
4. Include these fields in form:
   - Name*
   - Studio*
   - Event Date*
   - Time*
   - Location*
   - Address*
   - Price*
   - Description*
   - Category*
   - Book Link
   - Image URL
   - Instagram URL
   - Your Email (for follow-up)

5. Customize form:
   - Title: "Submit an Event"
   - Description: "Help us grow the Vancouver hobby community by sharing events!"
   - Submit message: "Thanks! We'll review and add your event within 24 hours."

6. Copy the form URL for your website

## Step 5: Create Sample Data

**Add 3-5 test events to verify setup:**

```
Event 1:
Name: "Beginner Pottery Class"
Studio: "Clay Mates Studio"
Event Date: [Next Friday]
Time: "7:00 PM"
Location: "Clay Mates Studio"
Address: "123 Main St, Vancouver BC"
Price: "$45"
Description: "Learn the basics of wheel throwing in this 2-hour beginner-friendly class."
Category: "Arts & Crafts"
Status: "Published"

Event 2:
Name: "HIIT Boxing Workout"
Studio: "Rumble Boxing"
Event Date: [Next Saturday]
Time: "10:00 AM"
Location: "Rumble Boxing Vancouver"
Address: "456 Granville St, Vancouver BC"
Price: "$25"
Description: "High-intensity boxing workout for all fitness levels."
Category: "Fitness"
Status: "Published"
Featured: True
```

## Step 6: WhaleSync Integration

1. Go to https://whalesync.com
2. Create account
3. "New Integration"
4. Connect Airtable:
   - Select your "Hobby Directory" base
   - Choose "Events" table
   - Select "Published Events" view
5. Connect Webflow:
   - Select your site
   - Choose "Events" collection
6. Map fields (see main workflow guide)
7. Test sync with your sample data

## Step 7: Daily Workflow Setup

### Desktop Bookmark Workflow
**Create bookmarks for quick access:**
- Airtable Events table
- Instagram (key studio accounts)
- Facebook Events (Vancouver)
- Eventbrite (Vancouver)

### Mobile App Setup
1. Download Airtable app
2. Login and access your base
3. Bookmark "Events" table
4. Use for quick entries on-the-go

### Daily Routine (5-10 minutes)
1. Check 3-5 Instagram accounts
2. Add any new events to Airtable
3. Set Status = "Published" for verified events
4. Check WhaleSync sync status

## Step 8: Quality Control Template

**Before publishing, check:**
- [ ] Event name is clear and descriptive
- [ ] Date is in future
- [ ] Time includes AM/PM
- [ ] Address is complete and accurate
- [ ] Price is clear ("$45" or "Free")
- [ ] Description is engaging (2-3 sentences)
- [ ] Category is assigned
- [ ] Book link works (if provided)
- [ ] Image URL loads properly (if provided)
- [ ] Status = "Published"

## Advanced Tips

### Airtable Formulas
**Days Until Event:**
```
DATEDIF(TODAY(), {Event Date}, 'days')
```

**Event Status:**
```
IF({Event Date} < TODAY(), "Expired", 
   IF({Status} = "Published", "Live", "Draft"))
```

### Automation Ideas
- Auto-expire events after their date
- Send weekly digest of new events
- Notify when someone submits via form
- Auto-assign categories based on keywords

### Backup Strategy
- Export base monthly as CSV
- Take screenshots of views setup
- Document field configurations

---

**Your manual workflow is now ready! This setup gives you full control while keeping everything simple and reliable.** 🎉