# Hobby Classes Directory - Airtable Automation Scripts

Comprehensive API automation suite for creating and managing the optimal Airtable base structure for Vancouver's hobby classes directory.

## 🚀 Quick Start

```bash
cd /Users/chromefang.exe/HobbyApp/scripts
./setup-hobby-directory.sh
```

This single command will guide you through the complete setup process.

## 📁 Scripts Overview

| Script | Purpose | Usage |
|--------|---------|--------|
| `setup-hobby-directory.sh` | **Main orchestrator** - runs complete setup | `./setup-hobby-directory.sh` |
| `airtable-base-creator.js` | Creates base with 5 tables + sample data | `node airtable-base-creator.js` |
| `airtable-validator.js` | Validates structure and data integrity | `node airtable-validator.js` |
| `integration-helper.js` | Generates WhaleSync/Webflow configs | `node integration-helper.js` |

## 🏗️ What Gets Created

### Airtable Base Structure
- **Classes Table**: 21 fields with formulas, validation, relationships
- **Studios Table**: 12 fields with partnership tiers, commission tracking
- **Categories Table**: 9 fields with hierarchy, SEO optimization
- **Locations Table**: 8 fields with Vancouver neighborhoods, transit info
- **User_Submissions Table**: 12 fields with workflow management

### Sample Data
- 5 hobby categories (Pottery, DJ, Boxing, Art, Comedy)
- 5 Vancouver locations (Downtown, Kitsilano, Commercial Drive, etc.)
- 3 partner studios including Claymates Studio
- Pre-configured views for different use cases

### Integration Configs
- WhaleSync field mapping for Airtable → Webflow sync
- Webflow CMS collection structure
- API endpoint documentation
- Webhook configuration templates

## 🔧 Prerequisites

### Airtable Setup
1. **Upgrade to Team Plan** ($20/month)
   - Required for API access and advanced features
   - Upgrade at: https://airtable.com/pricing

2. **Generate API Token**
   - Go to: https://airtable.com/create/tokens
   - Name: "Hobby Directory Base Creator"
   - Scopes: `data.records:read`, `data.records:write`, `schema.bases:write`
   - Bases: "All current and future bases" (recommended)

### System Requirements
- Node.js 14+ (check with `node --version`)
- Terminal/command line access
- Internet connection for API calls

## 📋 Detailed Usage

### 1. Complete Automated Setup
```bash
./setup-hobby-directory.sh
```
**Best for**: First-time setup, complete automation

**What it does**:
- Checks prerequisites
- Creates base structure  
- Populates sample data
- Validates configuration
- Generates integration configs
- Provides next steps

### 2. Individual Scripts

#### Create Base Only
```bash
node airtable-base-creator.js
```
**Use when**: You want just the base creation without validation

#### Validate Existing Base
```bash
node airtable-validator.js
```
**Use when**: Testing an existing base structure, debugging issues

#### Generate Integration Configs
```bash
node integration-helper.js  
```
**Use when**: Setting up WhaleSync/Webflow after base creation

## 🔍 Validation Tests

The validator runs comprehensive checks:

### Structure Tests
- ✅ All 5 tables exist
- ✅ Required fields present
- ✅ Correct field types configured
- ✅ Relationships working properly

### Data Tests
- ✅ Sample data populated
- ✅ Field completeness check
- ✅ Formula calculations working
- ✅ Linked records functional

### Performance Tests
- ✅ Indexed fields optimized
- ✅ Formula count reasonable
- ✅ View configurations efficient

### Integration Tests  
- ✅ API endpoints accessible
- ✅ Field mappings valid
- ✅ Webhook compatibility

## 🔗 Integration Guide

### WhaleSync Setup
1. **Create WhaleSync Account**
   - Sign up at: https://whalesync.com
   - Connect Airtable using your API token
   - Connect Webflow using site token

2. **Import Configuration**
   - Use generated field mapping from `integration-config-*.json`
   - Set sync frequency to every 30 minutes
   - Enable "Active Classes" view filter

3. **Test Sync**
   - Create test record in Airtable
   - Verify appears in Webflow CMS
   - Check field mappings are correct

### Webflow CMS Setup
1. **Create Collections**
   - Use provided CMS structure from integration config
   - Set up "Hobby Classes" as main collection
   - Configure "Studios" and "Categories" as reference collections

2. **Design Templates**
   - Collection list page for class directory
   - Collection template for individual class pages
   - Category and studio profile pages

3. **Connect Dynamic Data**
   - Bind CMS fields to design elements
   - Set up filtering and sorting
   - Configure SEO fields

## 🚨 Troubleshooting

### Common Issues

#### "Authentication failed"
- **Cause**: Invalid API token or insufficient permissions
- **Solution**: Regenerate token with correct scopes

#### "Rate limit exceeded"
- **Cause**: Too many API requests too quickly
- **Solution**: Scripts include rate limiting, but wait 5 minutes and retry

#### "Table creation failed"  
- **Cause**: Insufficient permissions or base quota exceeded
- **Solution**: Check Team plan is active, verify workspace permissions

#### "Field relationships broken"
- **Cause**: Tables created in wrong order or IDs not updated
- **Solution**: Delete base and re-run complete setup

#### "Sample data incomplete"
- **Cause**: Network issues during data population
- **Solution**: Run validator to check, manually add missing data

### Recovery Steps
1. **Note Base ID** from console output if creation fails
2. **Delete incomplete base** manually in Airtable
3. **Check API token** has all required permissions
4. **Re-run setup script** with fresh start

### Getting Help
- Check `AIRTABLE_SETUP_GUIDE.md` for detailed instructions
- Review generated `integration-config-*.json` for field mappings
- Run validation script to identify specific issues
- Check Airtable API documentation for error codes

## 📊 Success Metrics

After successful setup, you should have:
- ✅ **Base Created**: 5 tables with proper relationships
- ✅ **Data Populated**: Vancouver-specific sample content
- ✅ **Validation Passed**: 90%+ tests passing
- ✅ **Integration Ready**: WhaleSync/Webflow configs generated
- ✅ **Production Ready**: Ready for real class data import

## 🔄 Maintenance

### Regular Tasks
- Run validator monthly to check data integrity
- Update sample data as Vancouver class landscape changes
- Refresh API tokens before expiration (typically 1 year)
- Monitor WhaleSync sync logs for errors

### Updates
- Scripts are versioned in `package.json`
- Check for updates to Airtable API
- Update field mappings if Webflow CMS changes
- Refresh integration configs quarterly

## 📈 Performance Optimization

### For Large Datasets (1000+ classes)
- Enable automatic sync scheduling during off-peak hours
- Use batch operations for bulk imports
- Consider view-based filtering to reduce sync payload
- Monitor API rate limits and adjust frequency

### For High Traffic Sites
- Implement caching on Webflow side
- Use CDN for image assets referenced in Airtable
- Set up monitoring for sync failures
- Consider backup/redundancy strategies

---

**Created by**: Data Synchronization and Automation Specialist  
**Last Updated**: 2025-09-12  
**Version**: 1.0.0