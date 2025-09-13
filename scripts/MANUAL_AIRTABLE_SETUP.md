# 🎨 Hobby Classes Directory - Manual Airtable Setup Guide

Since the API approach is having permission issues, here's a complete manual setup guide that will get you up and running in 30 minutes.

## 📋 **Manual Setup Steps**

### **Step 1: Create Base (3 minutes)**
1. Go to https://airtable.com
2. Click "Create a base" → "Start from scratch"
3. Name: "Hobby Classes Directory"
4. Delete the default "Table 1"

### **Step 2: Create Tables (20 minutes)**

#### **Table 1: Categories**
1. Click "Add a table" → Name: "Categories"
2. Add these fields:
   - `Name` (Single line text) - Primary field
   - `Description` (Long text)
   - `Color` (Single line text)
   - `Icon` (Single line text)
   - `Sort Order` (Number)

**Sample Data:**
| Name | Description | Color | Icon | Sort Order |
|------|-------------|-------|------|------------|
| Pottery & Ceramics | Clay work, wheel throwing, glazing | #8B4513 | pottery | 1 |
| Music & DJ | DJ workshops, music production | #FF6B6B | music | 2 |
| Fitness & Boxing | Boxing classes, fitness training | #4ECDC4 | boxing | 3 |
| Art & Drawing | Drawing, painting, illustration | #45B7D1 | brush | 4 |
| Comedy & Improv | Stand-up, improv, sketch comedy | #FFA07A | comedy | 5 |

#### **Table 2: Locations**
1. Click "Add a table" → Name: "Locations"
2. Add these fields:
   - `Name` (Single line text) - Primary field
   - `Neighborhood` (Single line text)
   - `Address` (Single line text)
   - `Postal Code` (Single line text)
   - `Transit` (Multiple select) - Options: SkyTrain, Bus, SeaBus

**Sample Data:**
| Name | Neighborhood | Address | Postal Code | Transit |
|------|-------------|---------|-------------|---------|
| Downtown Vancouver | Downtown | | V6B | SkyTrain, Bus |
| Kitsilano | Kitsilano | | V6K | Bus |
| Commercial Drive | East Vancouver | | V5L | SkyTrain, Bus |
| Gastown | Gastown | | V6A | SkyTrain, Bus, SeaBus |
| Mount Pleasant | Mount Pleasant | | V5T | Bus |

#### **Table 3: Studios**
1. Click "Add a table" → Name: "Studios"
2. Add these fields:
   - `Name` (Single line text) - Primary field
   - `Description` (Long text)
   - `Email` (Email)
   - `Phone` (Phone number)
   - `Website` (URL)
   - `Instagram` (Single line text)
   - `Partnership Tier` (Single select) - Options: Premium (Purple), Standard (Blue), Basic (Gray)
   - `Commission Rate` (Percent)
   - `Location` (Link to another record → Locations)

**Sample Data:**
| Name | Description | Email | Website | Instagram | Partnership Tier | Commission Rate | Location |
|------|-------------|-------|---------|-----------|------------------|-----------------|----------|
| Claymates Ceramics Studio | Premier pottery studio offering wheel throwing and glazing | hello@claymates.studio | https://claymatesceramicsstudio.com | @claymates.studio | Premium | 15% | Mount Pleasant |
| Beat Drop Academy | DJ and music production workshops | info@beatdrop.ca | | @beatdrop_van | Standard | 12% | Downtown Vancouver |
| Rumble Boxing | High-energy boxing fitness classes | vancouver@rumbleboxing.com | | @rumbleboxingmp | Premium | 18% | Kitsilano |

#### **Table 4: Classes** (Main Table)
1. Click "Add a table" → Name: "Classes"
2. Add these fields:
   - `Name` (Single line text) - Primary field
   - `Description` (Long text)
   - `Studio` (Link to another record → Studios)
   - `Category` (Link to another record → Categories)
   - `Location` (Link to another record → Locations)
   - `Date` (Date - Include time)
   - `Duration (hours)` (Number - Allow decimals)
   - `Price` (Currency - CAD)
   - `Max Students` (Number - Whole number)
   - `Current Students` (Number - Whole number)
   - `Instructor` (Single line text)
   - `Difficulty` (Single select) - Options: Beginner, Intermediate, Advanced, All Levels
   - `Status` (Single select) - Options: Active (Green), Full (Orange), Cancelled (Red), Draft (Gray)
   - `Booking URL` (URL)
   - `Image URL` (URL)
   - `Tags` (Multiple select) - Options: Beginner Friendly, Drop-in, Materials Included, Weekend, Evening
   - `Source` (Single select) - Options: Manual Entry, Web Scrape, API Import, User Submission
   - `Created` (Created time)

**Sample Data:**
| Name | Description | Studio | Category | Location | Date | Duration | Price | Max Students | Status | Booking URL |
|------|-------------|--------|----------|----------|------|----------|-------|--------------|--------|-------------|
| Beginner Pottery Workshop | Learn the basics of pottery in this hands-on workshop | Claymates Ceramics Studio | Pottery & Ceramics | Mount Pleasant | 2025-01-25 18:00 | 2 | $75 | 8 | Active | https://claymates.studio/book |

#### **Table 5: User Submissions**
1. Click "Add a table" → Name: "User Submissions"
2. Add these fields:
   - `Type` (Single select) - Options: New Class, Studio Suggestion, Update
   - `Submitter Name` (Single line text)
   - `Submitter Email` (Email)
   - `Class Name` (Single line text)
   - `Studio Name` (Single line text)
   - `Details` (Long text)
   - `Website` (URL)
   - `Status` (Single select) - Options: Pending (Yellow), Approved (Green), Rejected (Red)
   - `Review Notes` (Long text)
   - `Submitted` (Created time)

### **Step 3: Create Views (5 minutes)**

#### **Classes Table Views:**
1. **Active Classes View:**
   - Filter: Status = "Active"
   - Fields: Name, Studio, Category, Date, Price, Status
   - Sort: Date (earliest first)

2. **This Week View:**
   - Filter: Status = "Active" AND Date is within next 7 days
   - Fields: Name, Studio, Date, Duration, Price

#### **User Submissions Table Views:**
1. **Pending Review View:**
   - Filter: Status = "Pending"
   - Fields: Type, Class Name, Studio Name, Submitter Email, Submitted
   - Sort: Submitted (newest first)

### **Step 4: Set Up Relationships (2 minutes)**
The linked record fields should automatically create relationships. Verify:
- Classes → Studios (many-to-one)
- Classes → Categories (many-to-one) 
- Classes → Locations (many-to-one)
- Studios → Locations (many-to-one)

## 🎉 **You're Done!**

Your Hobby Classes Directory base is now ready with:
- ✅ 5 tables with proper relationships
- ✅ Sample Vancouver data including Claymates
- ✅ Optimized views for workflow management
- ✅ All field types configured correctly

## 📋 **Next Steps:**

1. **Copy your Base ID** from the URL (starts with `app...`)
2. **Save it safely** - you'll need it for Webflow/WhaleSync
3. **Add more sample data** to test the structure
4. **Set up Webflow CMS collections** (next phase)

## 🔧 **Pro Tips:**

- **Use Templates:** Copy the sample data format for consistency
- **Batch Import:** Use Airtable's CSV import for bulk data
- **Test Relationships:** Make sure linked records work properly
- **Backup:** Export each table as CSV before making major changes

Total Setup Time: ~30 minutes
Result: Production-ready Airtable base for 5,000+ classes!