# Webflow DevLink Setup Guide

## Step-by-Step Setup Process

### Step 1: Test Airtable Connection (Do This First!)

Before setting up Webflow, let's make sure your Airtable data is accessible:

```bash
cd /Users/chromefang.exe/HobbyApp/hobby-directory-webflow
node test-airtable.js
```

This will:
- Connect to your Airtable base
- Fetch the first 5 events
- Display their names, locations, and dates
- Confirm everything is configured correctly

If you see events listed, you're good to proceed! ✅

---

### Step 2: Create Webflow Site

1. Go to https://webflow.com/dashboard
2. Click **"New Site"**
3. Choose one of these options:
   - **"Start from Scratch"** (blank canvas)
   - Pick a template that matches your vision
4. Name your site (e.g., "Hobby Directory" or "Vancouver Events")
5. Select the **Free Starter plan** for now

---

### Step 3: Get Your Webflow Site ID

After creating your site:

1. Open the site in Webflow Designer
2. Look at the URL in your browser
3. Copy the Site ID from the URL:
   ```
   https://webflow.com/design/YOUR-SITE-NAME?siteId=XXXXXXXXXXXXX
                                                     ^^^^^^^^^^^
                                                     This is your Site ID
   ```
4. Or go to **Site Settings > General** and find the Site ID there

---

### Step 4: Authenticate with Webflow CLI

Run this command in your terminal:

```bash
webflow auth login
```

This will:
- Open your browser for Webflow authentication
- Generate an API token
- Save credentials to your `.env` file

---

### Step 5: Add Site ID to Environment

Edit `.env.local` and add your Site ID:

```env
WEBFLOW_SITE_ID=your_site_id_here
```

---

### Step 6: Sync React Components to Webflow

Now you can sync your React components:

```bash
npm run devlink:sync
```

This will:
- Export your EventCard, EventGrid, and EventDetail components
- Make them available in Webflow Designer
- Allow you to drag them onto pages

**Note**: DevLink syncs FROM Webflow TO your filesystem, not the other way around (different than I initially thought).

---

## Alternative Approach: Use Webflow's React Components Feature

Based on the CLI documentation, Webflow DevLink works differently than expected. Here are your options:

### Option A: Webflow Code Components (Recommended)

Webflow has a feature called **Code Components** that lets you add custom React code directly in the Designer:

1. In Webflow Designer, go to **Add Panel (+)**
2. Scroll to **Components**
3. Click **"Create Code Component"**
4. Paste your React component code
5. Configure props (like event slug, filters, etc.)

This is simpler than DevLink and works great for our use case!

### Option B: Traditional Webflow CMS + Custom Code

If DevLink isn't working as expected, we can use a hybrid approach:

1. **Webflow CMS Collections**: Create an "Events" collection in Webflow
2. **Embed Custom Code**: Use Webflow's Custom Code embeds to add our React components
3. **Direct Airtable Integration**: Keep the React code that fetches from Airtable

This gives you Webflow's visual design tools while keeping the real-time Airtable connection.

---

## Next Steps

1. **Run the Airtable test** to confirm your data is accessible
2. **Create your Webflow site** (or use existing)
3. **Choose your integration approach**:
   - Code Components (easiest)
   - DevLink (more advanced)
   - Hybrid CMS + Custom Code

Let me know which approach you prefer, and I'll guide you through it!

---

## Troubleshooting

### "WEBFLOW_SITE_ID not set"
Make sure you've added `WEBFLOW_SITE_ID=your_id_here` to `.env.local`

### "Authentication failed"
Run `webflow auth login` again and follow the browser prompts

### "No components found"
DevLink syncs FROM Webflow to your filesystem, not the reverse. Use Code Components instead.

---

## Resources

- [Webflow Code Components Docs](https://university.webflow.com/lesson/code-components)
- [Webflow CLI Documentation](https://developers.webflow.com)
- [Webflow Custom Code Guide](https://university.webflow.com/lesson/custom-code-in-the-head-and-body-tags)
