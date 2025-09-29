# 🚀 Hobbyist Platform - Deployment Guide

## Prerequisites Checklist

### Required Accounts
- [x] Apple Developer Account ($99/year)
- [x] Supabase Account (Free tier works)
- [ ] Stripe Account (For payments)
- [ ] Vercel Account (For web hosting)
- [ ] Google Cloud Console (For OAuth)

### Required Tools
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install node
brew install supabase/tap/supabase
brew install cocoapods
npm install -g vercel
```

---

## 🗄️ Database Deployment

### Step 1: Configure Supabase Project

1. **Access Supabase Dashboard**
   ```
   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp
   ```

2. **Reset Database Password** (if needed)
   - Go to Settings → Database
   - Click "Reset Database Password"
   - Save the new password securely

3. **Configure Environment**
   ```bash
   cd /Users/chromefang.exe/HobbyApp
   
   # Create .env.local file
   cat > .env.local << EOF
   SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   SUPABASE_SERVICE_KEY=your-service-key-here
   SUPABASE_DB_PASSWORD=your-db-password-here
   EOF
   ```

### Step 2: Deploy Database Migrations

```bash
# Navigate to project root
cd /Users/chromefang.exe/HobbyApp

# Link to Supabase project
supabase link --project-ref mcjqvdzdhtcvbrejvrtp

# Push all migrations
supabase db push

# Verify migrations
psql $DATABASE_URL -f scripts/validate_integration.sql
```

### Step 3: Enable Real-time Subscriptions

```sql
-- Run in Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE 
  classes, bookings, instructor_reviews, 
  studio_locations, instructor_profiles;
```

### Step 4: Configure Storage Buckets

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('class-images', 'class-images', true),
  ('instructor-profiles', 'instructor-profiles', true),
  ('studio-assets', 'studio-assets', true);

-- Set CORS policy
UPDATE storage.buckets 
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'],
    file_size_limit = 5242880 -- 5MB
WHERE id IN ('class-images', 'instructor-profiles', 'studio-assets');
```

---

## 📱 iOS App Deployment

### Step 1: Configure Xcode Project

1. **Open Project**
   ```bash
   cd /Users/chromefang.exe/HobbyApp/iOS
   open HobbyistSwiftUI.xcodeproj
   ```

2. **Update Bundle Identifier**
   - Select project in navigator
   - Change Bundle ID to: `com.hobbyist.app`
   - Set Team to your Apple Developer account

3. **Configure Capabilities**
   - Enable Push Notifications
   - Enable Sign in with Apple
   - Enable Associated Domains (for deep linking)

### Step 2: Configure Certificates & Profiles

```bash
# Install Fastlane
gem install fastlane

# Initialize Fastlane
cd /Users/chromefang.exe/HobbyApp/iOS
fastlane init

# Create certificates and profiles
fastlane match development
fastlane match appstore
```

### Step 3: Update Configuration Files

1. **Update Info.plist**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.hobbyist.app</string>
       </array>
     </dict>
   </array>
   ```

2. **Configure Environment**
   ```swift
   // iOS/HobbyistSwiftUI/Config/Constants.swift
   struct Constants {
       static let supabaseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
       static let supabaseAnonKey = "your-anon-key"
       static let stripePublishableKey = "pk_live_..."
   }
   ```

### Step 4: Build and Deploy to TestFlight

```bash
# Clean build folder
xcodebuild clean -scheme HobbyistSwiftUI

# Archive for distribution
fastlane beta

# Or manually:
xcodebuild archive \
  -scheme HobbyistSwiftUI \
  -configuration Release \
  -archivePath ./build/HobbyistSwiftUI.xcarchive

# Export for TestFlight
xcodebuild -exportArchive \
  -archivePath ./build/HobbyistSwiftUI.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-app \
  -f ./build/HobbyistSwiftUI.ipa \
  -u your-apple-id@example.com \
  -p @keychain:APP_SPECIFIC_PASSWORD
```

### Step 5: TestFlight Configuration

1. **Access App Store Connect**
   ```
   https://appstoreconnect.apple.com
   ```

2. **Configure TestFlight**
   - Add internal testers (up to 100)
   - Add external testers (up to 10,000)
   - Set beta app description
   - Configure test notes

3. **Submit for Beta Review**
   - Fill out beta information
   - Submit for review (usually 24-48 hours)

---

## 💻 Web Portal Deployment

### Step 1: Prepare for Production

1. **Update Environment Variables**
   ```bash
   cd /Users/chromefang.exe/HobbyApp/web-partner
   
   # Create production env
   cat > .env.production << EOF
   NEXT_PUBLIC_SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   STRIPE_SECRET_KEY=sk_live_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   EOF
   ```

2. **Build for Production**
   ```bash
   # Install dependencies
   npm install
   
   # Run production build
   npm run build
   
   # Test production build locally
   npm run start
   ```

### Step 2: Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy to Vercel
vercel --prod

# Follow prompts:
# - Link to existing project or create new
# - Configure environment variables
# - Set production domain
```

### Step 3: Configure Custom Domain

1. **Add Domain in Vercel**
   - Go to Project Settings → Domains
   - Add: `portal.hobbyist.app`
   - Configure DNS records

2. **DNS Configuration**
   ```
   Type: CNAME
   Name: portal
   Value: cname.vercel-dns.com
   ```

### Step 4: Configure Stripe Webhooks

1. **Access Stripe Dashboard**
   ```
   https://dashboard.stripe.com/webhooks
   ```

2. **Add Webhook Endpoint**
   ```
   Endpoint URL: https://portal.hobbyist.app/api/webhooks/stripe
   
   Events to listen:
   - payment_intent.succeeded
   - payment_intent.failed
   - customer.subscription.created
   - customer.subscription.deleted
   ```

3. **Update Environment**
   ```bash
   vercel env add STRIPE_WEBHOOK_SECRET production
   ```

---

## 🔐 OAuth Configuration

### Google Sign-In Setup

1. **Create OAuth Client**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create new project or select existing
   - Enable Google Sign-In API

2. **Configure OAuth Consent Screen**
   ```
   App name: Hobbyist
   Support email: support@hobbyist.app
   Authorized domains: hobbyist.app
   ```

3. **Create Credentials**
   ```
   Application type: iOS
   Bundle ID: com.hobbyist.app
   
   Application type: Web
   Authorized redirects: 
   - https://portal.hobbyist.app/auth/callback
   - https://mcjqvdzdhtcvbrejvrtp.supabase.co/auth/v1/callback
   ```

4. **Update Supabase Auth**
   - Go to Authentication → Providers
   - Enable Google
   - Add Client ID and Secret

---

## 🏗️ CI/CD Pipeline

### GitHub Actions Configuration

1. **Create Workflow File**
   ```yaml
   # .github/workflows/deploy.yml
   name: Deploy
   
   on:
     push:
       branches: [main]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: actions/setup-node@v3
         - run: npm ci
         - run: npm test
     
     deploy-web:
       needs: test
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: amondnet/vercel-action@v25
           with:
             vercel-token: ${{ secrets.VERCEL_TOKEN }}
             vercel-org-id: ${{ secrets.ORG_ID }}
             vercel-project-id: ${{ secrets.PROJECT_ID }}
             vercel-args: '--prod'
     
     deploy-ios:
       needs: test
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v3
         - uses: maxim-lobanov/setup-xcode@v1
         - run: fastlane beta
           env:
             MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
             FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
   ```

2. **Add Secrets to GitHub**
   ```bash
   # Add required secrets in repo settings
   VERCEL_TOKEN
   SUPABASE_SERVICE_KEY
   STRIPE_SECRET_KEY
   MATCH_PASSWORD
   FASTLANE_PASSWORD
   ```

---

## 🚦 Post-Deployment Checklist

### Database Verification
- [ ] All migrations applied successfully
- [ ] RLS policies are active
- [ ] Real-time subscriptions working
- [ ] Storage buckets accessible
- [ ] Edge functions deployed

### iOS App Verification
- [ ] App builds without errors
- [ ] TestFlight build processing
- [ ] Push notifications working
- [ ] Deep links functional
- [ ] Payments processing

### Web Portal Verification
- [ ] Site accessible at production URL
- [ ] Authentication working
- [ ] API endpoints responding
- [ ] Webhooks receiving events
- [ ] Real-time updates working

### Integration Testing
- [ ] iOS → Web: Bookings appear in dashboard
- [ ] Web → iOS: New classes visible in app
- [ ] Reviews sync bidirectionally
- [ ] Payment processing end-to-end
- [ ] Image uploads working

---

## 🔥 Rollback Procedures

### Database Rollback
```bash
# Revert last migration
supabase db reset --db-url $DATABASE_URL

# Restore from backup
pg_restore -d $DATABASE_URL backup.sql
```

### iOS Rollback
```bash
# Stop TestFlight distribution
# (In App Store Connect, expire the build)

# Deploy previous version
fastlane beta version:1.0.0
```

### Web Portal Rollback
```bash
# Instant rollback in Vercel
vercel rollback

# Or redeploy specific commit
vercel --prod --force
```

---

## 📊 Monitoring & Logs

### Supabase Monitoring
```
Dashboard: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/logs/explorer
```

### Vercel Analytics
```
Dashboard: https://vercel.com/dashboard/analytics
```

### iOS Crash Reports
```
App Store Connect → TestFlight → Crashes
Xcode → Window → Organizer → Crashes
```

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Build fails on CI | Check provisioning profiles |
| Database connection timeout | Verify connection pooling |
| OAuth not working | Check redirect URLs |
| Payments failing | Verify Stripe webhooks |
| Images not loading | Check CORS settings |

### Emergency Contacts
- **Supabase Support**: support@supabase.io
- **Apple Developer**: https://developer.apple.com/contact
- **Stripe Support**: https://support.stripe.com

---

## 📝 Final Notes

1. **Always test in staging first**
2. **Keep backups before major changes**
3. **Monitor error rates after deployment**
4. **Document any manual steps taken**
5. **Update this guide with lessons learned**

---

*Deployment Guide Version: 1.0.0*
*Last Updated: 2025-09-03*
*Next Review: After first production deployment*