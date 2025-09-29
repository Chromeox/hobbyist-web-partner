# 🚀 API-Based Airtable Setup Guide

**Automated setup using the standard Airtable API**

## Overview

Instead of manually creating fields and adding sample data, this script automates the process using the standard Airtable API. This works with **any Airtable plan** and is much simpler than the Metadata API.

## What This Script Does

✅ **Validates** your base structure  
✅ **Checks** existing data  
✅ **Adds** sample events automatically  
✅ **Generates** field setup template  
✅ **Provides** setup instructions  

## Quick Start

### 1. Prerequisites

```bash
# Install dependencies
cd scripts/automation
npm install airtable dotenv
```

### 2. Manual Base Creation (Required)

**You still need to create the base manually:**

1. Go to https://airtable.com
2. Click "+ Create" → "Start from scratch" 
3. Name it: **"Hobby Directory"**
4. Rename default table to: **"Events"**
5. Get your Base ID from the URL (starts with `app`)

### 3. Configure Environment

```bash
# Copy template
cp env.airtable.template .env.airtable

# Edit with your credentials
nano .env.airtable
```

**Add your details:**
```env
AIRTABLE_TOKEN=pat12345...  # Your Personal Access Token
AIRTABLE_BASE_ID=app123...  # Your Base ID
AIRTABLE_TABLE_NAME=Events
```

### 4. Run Auto-Setup

```bash
# Basic setup (recommended)
node airtable-auto-setup.js

# Generate template only
node airtable-auto-setup.js --template-only

# Force add data even if base has content
node airtable-auto-setup.js --force
```

## What vs. Manual Setup

| Task | Manual Setup | API Setup |
|------|-------------|----------|
| **Create Base** | ✋ Manual | ✋ Manual |
| **Create Table** | ✋ Manual | ✋ Manual |
| **Create Fields** | ✋ Manual (16 fields) | 🤖 Instructions provided |
| **Add Sample Data** | ✋ Manual (5 events) | 🤖 Automated |
| **Create Views** | ✋ Manual | ✋ Manual |
| **Field Validation** | ❌ None | ✅ Automated |
| **Documentation** | ✋ Manual reference | 🤖 Generated template |

## Field Structure (Auto-Generated)

The script expects these fields in your Airtable table:

### Required Fields
1. **Name** (Single line text)
2. **Studio** (Single line text)
3. **Event Date** (Date)
4. **Time** (Single line text)
5. **Location** (Single line text)
6. **Address** (Single line text)
7. **Price** (Single line text)
8. **Description** (Long text)
9. **Category** (Single select: Fitness, Arts & Crafts, Culinary, etc.)
10. **Status** (Single select: Draft, Published, Expired)

### Optional Fields
11. **Book Link** (URL)
12. **Image URL** (URL)
13. **Instagram URL** (URL)
14. **Featured** (Checkbox)
15. **Added By** (Single line text)
16. **Notes** (Long text)

## Sample Data Generated

The script adds 5 sample events:

1. **Beginner Pottery Wheel Class** (Arts & Crafts)
2. **HIIT Boxing Workout** (Fitness) 
3. **Sourdough Bread Workshop** (Culinary)
4. **Yoga & Meditation Session** (Wellness)
5. **Digital Photography Basics** (Photography)

## Workflow Options

### Option A: API-Assisted Setup (Recommended)

1. **Create base manually** (2 minutes)
2. **Run auto-setup script** (1 minute)
3. **Create fields as instructed** (5 minutes)
4. **Run script again** to add sample data (1 minute)
5. **Create views manually** (3 minutes)

**Total: ~12 minutes**

### Option B: Fully Manual Setup

1. **Create base manually** (2 minutes)
2. **Create 16 fields manually** (15 minutes)
3. **Add sample data manually** (10 minutes)
4. **Create views manually** (3 minutes)

**Total: ~30 minutes**

## Error Handling

The script provides helpful error messages:

### Missing Base
```
❌ Error: NOT_FOUND
📝 Setup Instructions:
1. Go to https://airtable.com
2. Create a new base called "Hobby Directory"
3. Rename the default table to "Events"
4. Set your AIRTABLE_BASE_ID in .env.airtable
5. Run this script again
```

### Missing Fields
```
❌ Error: UNKNOWN_FIELD_NAME
📝 Field Setup Required:
Some fields are missing. Please create these fields...
[Detailed field setup instructions shown]
```

### Authentication Issues
```
❌ API key error
🔑 Authentication Issue:
1. Check your AIRTABLE_TOKEN in .env.airtable
2. Ensure token has read/write permissions
3. Verify base scope is set correctly
```

## CLI Options

```bash
# Show help
node airtable-auto-setup.js --help

# Normal setup (stops if data exists)
node airtable-auto-setup.js

# Force add sample data anyway
node airtable-auto-setup.js --force

# Generate field template without adding data
node airtable-auto-setup.js --template-only
```

## Generated Files

- **`airtable-field-setup-template.json`** - Complete field definitions
- **Console output** - Step-by-step setup instructions
- **Validation results** - Structure and data verification

## Integration with WhaleSync

After running the auto-setup:

1. **Sample data is ready** for WhaleSync testing
2. **Field structure matches** your manual setup guide
3. **"Published Events" view** can be created for sync filtering
4. **No additional configuration** needed

## Limitations

❌ **Cannot create fields** (requires manual setup or Enterprise API)  
❌ **Cannot create views** (requires manual setup)  
❌ **Cannot create forms** (requires manual setup)  

✅ **Can validate structure** (automated)  
✅ **Can add sample data** (automated)  
✅ **Can check existing data** (automated)  
✅ **Can generate templates** (automated)  

## Why Not Full Metadata API?

The Airtable Metadata API can create fields/tables programmatically, but:

- **Requires Business/Enterprise plan** ($20+/month)
- **Needs developer token** (additional setup)
- **Can't delete fields/tables** (permanent changes)
- **Limited modification** capabilities
- **More complex authentication**

Our approach works with **free Airtable plans** and is much simpler.

## Next Steps After Setup

1. **Verify sample data** in your Airtable base
2. **Create views** (Published Events, Draft Events, etc.)
3. **Set up WhaleSync** connection to Webflow
4. **Test the full pipeline** with sample data
5. **Start adding real events** manually or via forms

---

**This API-assisted approach saves ~60% of setup time while working with any Airtable plan!** 🎉