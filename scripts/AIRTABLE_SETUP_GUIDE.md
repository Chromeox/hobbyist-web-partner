# Hobby Classes Directory - Airtable Setup Guide

## 🎯 Overview

This guide walks you through creating the optimal Airtable base structure for the Hobby Classes Directory project using automated API scripts.

## 📋 Prerequisites

### 1. Airtable Team Plan Subscription
- **Cost**: $20/month per user
- **Required for**: API access, advanced field types, external integrations
- **Upgrade at**: https://airtable.com/pricing

### 2. API Access Setup
1. Go to https://airtable.com/create/tokens
2. Click "Create token"
3. Configure token:
   - **Name**: "Hobby Directory Base Creator"
   - **Scopes**: 
     - ✅ `data.records:read`
     - ✅ `data.records:write` 
     - ✅ `schema.bases:write`
   - **Bases**: Choose "All current and future bases" (recommended)
4. Copy the generated token (starts with `pat`)

## 🚀 Quick Start

### Run the Automated Setup
```bash
cd /Users/chromefang.exe/HobbyistSwiftUI/scripts
node airtable-base-creator.js
```

The script will:
1. ✅ Create "Hobby Classes Directory" base
2. ✅ Set up 5 optimized tables with relationships
3. ✅ Populate Vancouver-specific sample data
4. ✅ Configure views for different use cases
5. ✅ Validate structure and provide summary

## 📊 Base Structure Created

### Tables Overview
| Table | Fields | Purpose |
|-------|--------|---------|
| **Classes** | 21 | Main hobby class listings |
| **Studios** | 12 | Partner studios and venues |
| **Categories** | 9 | Hobby categories with hierarchy |
| **Locations** | 8 | Vancouver neighborhoods |
| **User_Submissions** | 12 | Community suggestions |

### Key Relationships
- Classes → Studios (Many-to-One)
- Classes → Categories (Many-to-Many)  
- Classes → Locations (Many-to-One)
- Studios → Locations (Many-to-One)

## 🔧 Advanced Configuration

### Custom Field Types Used
- **Formula Fields**: Auto-calculated spots available, SEO slugs
- **Lookup Fields**: Studio info in class listings
- **Rollup Fields**: Class counts, average ratings
- **Single/Multiple Select**: Status, difficulty, tags
- **Currency**: Canadian dollar pricing
- **Date/Time**: Event scheduling with timezone
- **URL**: Registration links, websites, images
- **Email/Phone**: Studio contact information

### Optimized Views Created

#### Classes Table
- **Active Classes**: Status = Active, sorted by date
- **This Week**: Classes in next 7 days
- **Full Classes**: Tracking waitlists

#### Studios Table  
- **Partnership Management**: Tier-based studio organization
- **Commission Tracking**: Revenue and partnership metrics

#### User Submissions Table
- **Pending Review**: New submissions requiring approval
- **Approved**: Successfully added classes

## 🔄 Integration Preparation

### WhaleSync Configuration
The base is pre-configured for WhaleSync integration:

1. **Sync Direction**: Airtable → Webflow
2. **Primary Table**: Classes (for CMS collection)
3. **Key Fields Mapped**:
   - Class_Name → Name
   - Description → Rich Text
   - Image_URL → Image
   - Price_CAD → Price
   - Event_Date → Date
   - SEO_Slug → Slug

### Webflow CMS Setup
Recommended collection structure:
```
Classes Collection:
├── Name (Text)
├── Description (Rich Text) 
├── Studio (Reference to Studios)
├── Category (Multi-Reference to Categories)
├── Price (Number)
├── Event Date (Date)
├── Image (Image)
├── Registration URL (Link)
└── Slug (Text - Auto)
```

## 📊 Sample Data Included

### Categories (5 Featured)
- 🏺 Pottery & Ceramics
- 🎵 Music & DJ
- 🥊 Fitness & Boxing  
- 🎨 Art & Drawing
- 🎭 Comedy & Improv

### Vancouver Locations (5 Key Areas)
- Downtown Vancouver (SkyTrain + Bus)
- Kitsilano (Bus Routes)
- Commercial Drive (SkyTrain + Bus)
- Gastown (All Transit)
- Mount Pleasant (Bus Routes)

### Partner Studios (3 Tiers)
- **Claymates Ceramics Studio** (Premium Partner)
- **Beat Drop Academy** (Standard Partner)
- **Rumble Boxing** (Premium Partner)

## 🔍 Quality Assurance

### Automated Validation Checks
The script validates:
- ✅ All 5 tables created successfully
- ✅ Field relationships working correctly  
- ✅ Sample data populated without errors
- ✅ Views configured and accessible
- ✅ API rate limits respected

### Manual Verification Steps
1. **Visit Base**: https://airtable.com/{BASE_ID}
2. **Check Relationships**: Verify linked records display correctly
3. **Test Views**: Ensure filtering and sorting work as expected
4. **Sample Data**: Confirm Vancouver locations and studios are accurate

## 🚨 Troubleshooting

### Common Issues

#### "Authentication failed"
- Verify API token starts with `pat`
- Check token has required scopes
- Ensure Airtable Team plan is active

#### "Rate limit exceeded"  
- Script includes automatic rate limiting (5 req/sec)
- If still occurring, increase delays in script

#### "Table creation failed"
- Check workspace permissions
- Ensure sufficient base creation quota
- Try creating base manually first

#### "Field relationships broken"
- Linked record fields are created after base tables
- Re-run script if some relationships are missing

### Recovery Steps
If creation fails partway through:
1. Note the Base ID from console output
2. Delete incomplete base manually
3. Check API token permissions
4. Re-run script with fresh token

## 📈 Next Steps After Creation

### 1. Immediate Actions (Day 1)
- [ ] Explore created base structure
- [ ] Verify sample data accuracy  
- [ ] Test views and filtering
- [ ] Share base with team members

### 2. Integration Setup (Days 2-3)
- [ ] Configure WhaleSync sync from Airtable to Webflow
- [ ] Set up Webflow CMS collections matching structure
- [ ] Test bi-directional sync functionality
- [ ] Configure webhook triggers for real-time updates

### 3. Data Population (Week 1)
- [ ] Import existing class data from spreadsheets
- [ ] Add real Vancouver studio partnerships
- [ ] Populate comprehensive location data
- [ ] Create category hierarchy and tags

### 4. Production Preparation (Week 2)
- [ ] Set up user submission workflows
- [ ] Configure approval processes
- [ ] Create backup and recovery procedures
- [ ] Implement monitoring and alerting

## 💡 Pro Tips

### Optimization Strategies
- **Batch Operations**: Use batch API calls for bulk data import
- **View Filters**: Create specific views for different user roles
- **Automation**: Set up Airtable automations for data quality
- **Permissions**: Configure field-level permissions for team access

### Performance Best Practices
- **Index Strategy**: Primary fields auto-indexed for performance
- **Formula Efficiency**: Formulas designed to minimize calculation overhead
- **Relationship Design**: Efficient linking reduces data duplication
- **View Configuration**: Filtered views improve loading times

### Security Considerations
- **API Tokens**: Store securely, rotate regularly
- **Base Sharing**: Use specific permissions, not public sharing
- **Data Privacy**: Configure field visibility appropriately
- **Audit Trail**: Enable revision history for all changes

## 📞 Support Resources

### Airtable Documentation
- [API Documentation](https://airtable.com/developers/web/api/introduction)
- [Field Types Reference](https://airtable.com/developers/web/api/field-model)
- [Rate Limiting Guide](https://airtable.com/developers/web/api/rate-limits)

### Integration Guides
- [WhaleSync Setup](https://whalesync.com/docs)
- [Webflow CMS Integration](https://university.webflow.com/lesson/intro-to-cms)

### Community Support
- [Airtable Community Forum](https://community.airtable.com)
- [WhaleSync Discord](https://discord.gg/whalesync)

---

**Created by**: Hobby Directory Automation System  
**Last Updated**: 2025-09-12  
**Version**: 1.0