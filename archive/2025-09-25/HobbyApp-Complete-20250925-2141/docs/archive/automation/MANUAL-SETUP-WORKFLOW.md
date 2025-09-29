# 📝 Manual Lead Setup Workflow

**The Simplest Directory Automation Possible**

## Your Streamlined Stack

```
Manual Entry (You)
    ↓
Airtable (Database)
    ↓ [WhaleSync - 5min sync]
Webflow (Website)
```

**Total Tools: 3** (vs. your original 5)

## Benefits of Manual Setup

✅ **Full Control** - Curate exactly what you want
✅ **No Rate Limits** - No Instagram blocking issues
✅ **Higher Quality** - Manual verification ensures accuracy
✅ **Zero Maintenance** - No scraping scripts to break
✅ **Cost Effective** - ~$50/month total (Airtable + WhaleSync + Webflow)
✅ **Faster Setup** - Start adding events immediately

## Manual Entry Process

### 1. Set Up Your Airtable Base

**Create Events Table with these fields:**

| Field Name | Field Type | Required | Notes |
|------------|------------|----------|-------|
| **Name** | Single line text | ✅ | Event title |
| **Studio** | Single line text | ✅ | Organizer name |
| **Event Date** | Date | ✅ | When it happens |
| **Time** | Single line text | ✅ | "7:00 PM" format |
| **Location** | Single line text | ✅ | Venue name |
| **Address** | Single line text | ✅ | Full address |
| **Price** | Single line text | ✅ | "$25" or "Free" |
| **Description** | Long text | ✅ | Event details |
| **Category** | Single select | ✅ | Fitness, Arts, Culinary, etc. |
| **Book Link** | URL | ❌ | Registration URL |
| **Image URL** | URL | ❌ | Event photo |
| **Instagram URL** | URL | ❌ | Social proof |
| **Status** | Single select | ✅ | Draft/Published |
| **Featured** | Checkbox | ❌ | Homepage highlight |
| **Added By** | Single line text | ❌ | Your tracking |

### 2. Daily Lead Collection (5-10 minutes)

**Sources to Check:**
- Instagram (manually browse accounts)
- Facebook Events
- Eventbrite searches
- Studio websites
- Community boards
- Referrals from users

**Quick Entry Tips:**
- Use Airtable mobile app for on-the-go entries
- Copy/paste from event pages
- Use Airtable forms for submissions from others
- Batch similar events together

### 3. Quality Control Checklist

Before publishing, verify:
- [ ] Event date is correct and future
- [ ] Time includes AM/PM
- [ ] Address is complete
- [ ] Book link works
- [ ] Price is clear
- [ ] Category is assigned
- [ ] Description is compelling
- [ ] Status = "Published"

### 4. Airtable Views for Organization

**Create these views:**

1. **📝 Draft Events** - Status = "Draft"
2. **📅 This Week** - Event Date is this week
3. **⭐ Featured** - Featured = True
4. **🏃 Fitness** - Category = "Fitness"
5. **🎨 Arts & Crafts** - Category = "Arts & Crafts"
6. **📊 Analytics** - All events with metrics

## Automation Setup

### WhaleSync Configuration

1. **Connect Airtable:**
   - Base: Your Events base
   - Table: Events
   - View: "Published Events" (filter: Status = "Published")

2. **Connect Webflow:**
   - Site: Your directory site
   - Collection: Events CMS collection

3. **Field Mapping:**
   ```
   Airtable → Webflow
   Name → Name
   Studio → Studio
   Event Date → Event Date
   Time → Time
   Location → Location
   Address → Address
   Price → Price
   Description → Description
   Category → Category
   Book Link → Book Link
   Image URL → Featured Image
   Instagram URL → Instagram URL
   Featured → Featured
   ```

4. **Sync Settings:**
   - Direction: Airtable → Webflow (one-way)
   - Frequency: Every 5 minutes
   - Only sync: Status = "Published"

## Scaling Your Manual Process

### Week 1-2: Get Started
- Add 10-20 events manually
- Test WhaleSync sync
- Verify website display
- Get comfortable with workflow

### Week 3-4: Build Momentum
- Aim for 5 new events daily
- Create submission form for studios
- Reach out to 3-5 studios directly
- Ask friends for event suggestions

### Month 2+: Community Driven
- **Studio Partnerships:** Give studios direct Airtable access
- **User Submissions:** Airtable form on your website
- **Email Tips:** Weekly "events we found" from followers
- **Social Crowdsourcing:** Ask Instagram followers for events

## Airtable Forms for Submissions

**Create a public form:**
1. In Airtable, click "Form" view
2. Share the form link on your website
3. Include these fields:
   - Event Name*
   - Studio/Organizer*
   - Date*
   - Time*
   - Location*
   - Description*
   - Registration Link
   - Your Email (for follow-up)

**Form embed code for Webflow:**
```html
<iframe src="YOUR_AIRTABLE_FORM_URL" 
        width="100%" 
        height="500" 
        frameborder="0">
</iframe>
```

## Time Investment

- **Daily:** 5-10 minutes (find and add 1-3 events)
- **Weekly:** 30 minutes (quality review, featured events)
- **Monthly:** 1 hour (outreach, form review, analytics)

**Total: ~1 hour per week vs. maintaining scraping scripts**

## Success Metrics

**Week 1 Goals:**
- 20 events in Airtable
- WhaleSync working
- All events showing on website

**Month 1 Goals:**
- 100+ events
- 5+ studio partnerships
- User submission form live
- 1000+ website views

## Pro Tips

1. **Batch Similar Events:** Add all yoga classes at once
2. **Use Templates:** Copy similar events and edit details
3. **Mobile-First:** Use Airtable app during commute
4. **Set Reminders:** Daily calendar reminder to add events
5. **Quality over Quantity:** 3 great events > 10 mediocre ones
6. **Community Building:** Engage with studios you feature
7. **Feedback Loop:** Ask users what events they want to see

## Advanced Automation (Optional)

**Airtable Automations:**
- Auto-expire past events
- Send weekly digest emails
- Notify when form submissions come in
- Auto-categorize based on keywords

**Zapier/Make Integrations:**
- Facebook Events → Airtable
- Eventbrite → Airtable  
- Gmail → Airtable (forward event emails)

---

## The Bottom Line

**Manual = Simple, Reliable, High-Quality**

You'll have a lean, effective directory that:
- Never breaks from API changes
- Showcases exactly what you choose
- Builds real relationships with studios
- Requires minimal technical maintenance

Start manually, scale with community! 🚀