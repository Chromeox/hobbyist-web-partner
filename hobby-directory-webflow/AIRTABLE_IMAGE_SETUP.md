# Airtable Image Management Setup Guide

## Step 1: Add New Fields to Classes Table

Open your Airtable base: https://airtable.com/appo3x0WjbCIhA0Lz/tblEW9fdX42oQpulK

### Field 1: Image_Source
**Type:** Single Select
**Options:**
- AI Generated (default)
- Studio Uploaded
- Manual Upload
- Instagram Embedded

**Purpose:** Track where the image came from for management

---

### Field 2: Image_URL
**Type:** URL
**Purpose:** Primary image displayed on directory site

**Default value:** Leave empty (will be populated by AI or manually)

---

### Field 3: Image_Generation_Prompt
**Type:** Long Text
**Purpose:** Store the AI prompt used to generate the image

**Example values:**
```
Pottery wheel throwing class with hands shaping clay bowl, professional studio lighting
Boxing fitness class with punching bags, energetic gym atmosphere
Ceramic hand building workshop, clay sculpting on table, creative studio
```

---

### Field 4: Instagram_Post_URL
**Type:** URL
**Purpose:** Link back to original Instagram post for attribution

**Example:** `https://instagram.com/p/ABC123def456`

---

## Step 2: Enable Airtable AI Image Generation

### Option A: Using Airtable AI (Recommended if Available)

1. **Check if you have AI features:**
   - Click on the Image_URL field
   - Look for "AI" or "Generate" options in field settings

2. **If available, configure AI generation:**
   - Field type: Attachment or URL
   - Enable "AI Generation"
   - Template: `Professional photo of {Name}, {Category} class in Vancouver, modern aesthetic`

3. **Set trigger:**
   - Automation: When new record created
   - Condition: If Image_URL is empty
   - Action: Generate AI image
   - Save to Image_URL field

### Option B: Manual AI Generation (If Airtable AI Not Available)

Use external AI image generators:

**Free Options:**
- DALL-E via OpenAI (limited free)
- Midjourney (free trial)
- Leonardo.ai (150 free images/day)
- Bing Image Creator (free, powered by DALL-E)

**Process:**
1. Copy Image_Generation_Prompt from Airtable
2. Paste into AI image generator
3. Download generated image
4. Upload to image hosting (Imgur, Cloudinary, or Airtable attachment)
5. Paste URL into Image_URL field

---

## Step 3: Generate Images for Existing Classes

For each of your 3 existing classes:

### Class 1 Example

**Current data:**
- Name: "Untitled Class"
- Category: (needs to be filled)
- Location: (needs to be filled)

**Add this data:**
```
Image_Source: AI Generated
Image_Generation_Prompt: "Creative workshop class in modern Vancouver studio, warm lighting, artistic activity"
Image_URL: [will be generated]
Instagram_Post_URL: [if you have it]
```

### Prompt Templates by Category

**Pottery:**
```
Pottery wheel throwing class, hands shaping clay bowl, professional ceramic studio lighting, warm earthy tones
```

**Fitness/Boxing:**
```
Boxing fitness class, person hitting punching bag, energetic gym atmosphere, dynamic motion, Vancouver studio
```

**Art/Painting:**
```
Painting workshop, artist with brush and canvas, creative studio space, natural light, Vancouver art space
```

**Dance:**
```
Dance class in modern studio, wooden floors, mirrors, graceful movement, warm lighting
```

**Wellness/Yoga:**
```
Yoga class in peaceful studio, mats on floor, calm atmosphere, natural light, serene Vancouver space
```

**Food/Cooking:**
```
Cooking class, hands preparing food, professional kitchen, ingredients on counter, welcoming atmosphere
```

**Maker/Crafts:**
```
Craft workshop, hands working on project, tools and materials, creative studio space, focused activity
```

---

## Step 4: Field Order Recommendations

Arrange fields in this order for best workflow:

1. Name
2. Description
3. **Image_URL** ← NEW (easy to see if image is set)
4. **Image_Source** ← NEW
5. **Image_Generation_Prompt** ← NEW (hide if not using AI)
6. Date
7. Time
8. Price
9. Status
10. Studio
11. Category
12. Location
13. Address
14. **Instagram_Post_URL** ← NEW

---

## Step 5: Create AI Generation Automation (Optional)

If you want automatic AI image generation:

### Using Airtable Automations

1. **Trigger:** When record enters view
   - View: "Pending Review" or "All Classes"
   - Condition: Image_URL is empty

2. **Action:** Generate AI image
   - Use Image_Generation_Prompt as input
   - Or auto-generate from: `Professional {Category} class: {Name}, Vancouver studio aesthetic`

3. **Action:** Update record
   - Set Image_URL with generated image
   - Set Image_Source to "AI Generated"

### Using External Service (Zapier/Make)

1. **Trigger:** New record in Airtable
2. **Filter:** Image_URL is empty
3. **Action:** Call OpenAI DALL-E API
   - Input: Image_Generation_Prompt field
4. **Action:** Upload image to hosting
5. **Action:** Update Airtable record with Image_URL

---

## Step 6: Populate Your 3 Existing Classes

### Quick Start: Manual Population

For each class, fill in these fields:

**Class 1:**
```
Name: [Give it a proper name]
Category: pottery / fitness / art (choose one)
Image_Generation_Prompt: [Use template above based on category]
Image_Source: AI Generated
Status: active (so it shows on website)
```

**Class 2:**
```
[Same process]
```

**Class 3:**
```
[Same process]
```

### Get AI Images Quickly

**Using Bing Image Creator (Free, Easy):**
1. Go to https://www.bing.com/create
2. Paste your Image_Generation_Prompt
3. Click "Create"
4. Download the best image
5. Upload to Airtable attachment field OR
6. Upload to Imgur.com and paste URL into Image_URL

**Using Leonardo.ai (Free, High Quality):**
1. Sign up at leonardo.ai (150 free images/day)
2. Paste your prompt
3. Select "Leonardo Diffusion XL" model
4. Generate
5. Download and upload to Airtable

---

## Step 7: Verify Setup

After adding fields and images, check:

- [ ] All 4 new fields exist in Classes table
- [ ] All 3 existing classes have Image_URL populated
- [ ] Image_Source is set for each class
- [ ] Images load when you open the URL
- [ ] Status is "active" for classes you want to show

---

## Tips for Best AI Images

### Prompt Best Practices

**Good prompt:**
```
Pottery wheel throwing class, close-up of hands shaping clay bowl,
professional ceramic studio lighting, warm earthy brown tones,
modern Vancouver studio aesthetic
```

**Bad prompt:**
```
pottery class
```

### Key Elements to Include

1. **Activity:** What's happening (throwing on wheel, painting, boxing)
2. **Perspective:** Close-up of hands, wide shot of studio, person doing activity
3. **Lighting:** Professional studio lighting, natural light, warm tones
4. **Mood:** Energetic, calm, creative, focused
5. **Location context:** Modern Vancouver studio, professional space

### Style Consistency

To keep all images looking cohesive, add to every prompt:
```
, professional photography, modern Vancouver studio aesthetic, warm welcoming atmosphere
```

---

## Troubleshooting

### "I don't see AI generation options"
- Airtable AI is a newer feature, may not be on all plans
- Use external AI generators (Bing, Leonardo.ai) instead
- Manually upload images to attachment field

### "AI images don't match my vision"
- Refine your prompts with more specific details
- Try different AI generators (each has different styles)
- Consider using real studio photos when available

### "Images are too large / slow to load"
- Resize before uploading (recommended: 1200px wide)
- Use image compression (TinyPNG.com)
- Or use CDN (Cloudinary free tier)

---

## Next Steps

Once you've completed this setup:

1. **Test in terminal:**
   ```bash
   cd HobbyApp/hobby-directory-webflow
   node test-airtable.js
   ```
   Should now show Image_URL for each class

2. **Verify React components** will display images correctly

3. **Ready for Webflow integration!**

---

## Questions?

Common issues and solutions:

**Q: Do I need all 4 fields?**
A: Minimum required: Image_URL. Others are optional but helpful for management.

**Q: Can I use Instagram images directly?**
A: Not recommended due to scraping restrictions. Use AI generation or request from studios.

**Q: What if a studio provides their own photos?**
A: Great! Upload to Airtable, paste URL, set Image_Source: "Studio Uploaded"

**Q: How often should I regenerate AI images?**
A: Only when changing class name/description significantly, or getting better prompts.
