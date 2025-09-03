# 🚀 HobbyistSwiftUI Pricing System Setup Guide

## ✅ Current Status

All code and configuration files have been created and are ready for deployment. Here's what's been completed:

### ✅ Completed Items
- **Database Migration**: `20240821_flexible_pricing_v2.sql` ready to deploy
- **Edge Functions**: All 4 functions created (stripe-products-setup, purchase-credits, credit-webhooks, payments)
- **iOS Implementation**: Complete Apple Pay and IAP service integration
- **UI Components**: All pricing views and purchase flows implemented
- **Scripts**: Automated setup and verification scripts created
- **Environment File**: Template created at `.env.local`

### ⚠️ Pending Setup Steps

## 📋 Step-by-Step Setup Instructions

### Step 1: Reset Database Password (Required)
1. Visit: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database
2. Click "Reset Database Password"
3. Save the new password securely

### Step 2: Get Your API Keys
1. **Supabase Keys**: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api
   - Copy the `anon` public key
   - Copy the `service_role` secret key (keep this secure!)
   
2. **Stripe Keys**: https://dashboard.stripe.com/apikeys
   - Copy your Secret Key (starts with `sk_`)
   - Copy your Publishable Key (starts with `pk_`)

### Step 3: Update Environment Variables
Edit `.env.local` file and replace placeholder values:
```bash
# Replace these with your actual keys
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ... (your anon key)
SUPABASE_SERVICE_ROLE_KEY=eyJ... (your service role key)
STRIPE_SECRET_KEY=sk_live_... (or sk_test_ for testing)
STRIPE_PUBLISHABLE_KEY=pk_live_... (or pk_test_ for testing)
```

### Step 4: Run the Setup Script
```bash
cd /Users/chromefang.exe/HobbyistSwiftUI
./setup-pricing-system.sh
```

This script will:
- Deploy the database migration (you'll enter your password)
- Deploy edge functions
- Create Stripe products
- Verify the setup

### Step 5: Configure Apple Pay (App Store Connect)

1. Visit [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "In-App Purchases" section
4. Add these products with exact IDs:

#### Credit Packages (Consumable):
- `com.hobbyist.app.credits.starter` - $25 CAD
- `com.hobbyist.app.credits.explorer` - $55 CAD
- `com.hobbyist.app.credits.regular` - $95 CAD
- `com.hobbyist.app.credits.enthusiast` - $170 CAD
- `com.hobbyist.app.credits.power` - $300 CAD

#### Subscriptions (Auto-Renewable):
- `com.hobbyist.app.subscription.casual` - $39/month
- `com.hobbyist.app.subscription.active` - $69/month
- `com.hobbyist.app.subscription.premium` - $119/month
- `com.hobbyist.app.subscription.elite` - $179/month

#### Insurance (Auto-Renewable):
- `com.hobbyist.app.insurance.basic` - $3/month
- `com.hobbyist.app.insurance.plus` - $5/month
- `com.hobbyist.app.insurance.premium` - $8/month

5. Create Subscription Groups:
   - Main Subscriptions: Group ID `21483657`
   - Insurance Plans: Group ID `21483658`

6. Generate Shared Secret for receipt validation

## 🧪 Testing the System

### Test Database Migration
```bash
# Check if tables were created
supabase db dump --data-only | grep credit_packs
```

### Test Edge Functions
```bash
# Test Stripe products creation (requires service role key)
curl -X POST https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1/stripe-products-setup \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "create"}'
```

### Test in iOS Simulator
1. Open Xcode
2. Build and run the app
3. Navigate to Pricing section
4. Try purchasing a credit package
5. Verify credits are added to account

## 🔍 Verification Commands

Run the verification script to check your setup:
```bash
./verify-setup.sh
```

## 📊 Database Tables Created

The migration creates these tables:
- `credit_packs` - Credit package definitions
- `subscription_plans` - Monthly subscription tiers
- `class_tiers` - Credit requirements per class type
- `credit_insurance_plans` - Insurance options
- `user_insurance_subscriptions` - User insurance status
- `credit_rollover_history` - Rollover tracking
- `dynamic_pricing_rules` - Peak/off-peak pricing
- `squads` & `squad_members` - Social features
- `promotional_campaigns` - Promo codes
- `retention_metrics` - User engagement tracking

## 🎯 Key Features Enabled

### For Users:
- **5 Credit Packages**: $25-$300 CAD
- **4 Subscription Tiers**: $39-$179/month
- **Credit Insurance**: $3-$8/month (prevents expiration)
- **Winter Bonus**: 20% extra credits (Nov-Feb)
- **Squad Features**: Group accountability
- **Smart Rollover**: Based on loyalty (25%-100%)

### For Studios:
- **70-75% Commission**: Better than ClassPass (50-60%)
- **Automated Payouts**: Weekly settlements
- **Real-time Analytics**: Track bookings and revenue

## 🚨 Important URLs

- **Supabase Dashboard**: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp
- **Database Password Reset**: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database
- **API Keys**: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api
- **Edge Functions Logs**: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/functions
- **Stripe Dashboard**: https://dashboard.stripe.com
- **App Store Connect**: https://appstoreconnect.apple.com

## 🛠️ Troubleshooting

### Migration Fails
- Ensure you have the correct database password
- Check if you're connected to the internet
- Try running with debug: `supabase db push --debug`

### Edge Functions Not Deploying
- Make sure you're logged in: `supabase login`
- Check function logs in Supabase dashboard
- Verify service role key has proper permissions

### Stripe Products Not Creating
- Verify Stripe API keys are correct
- Check if keys are for the right environment (test vs live)
- Look for errors in edge function logs

### Apple Pay Not Working
- Ensure bundle ID matches: `com.hobbyist.app`
- Verify products are approved in App Store Connect
- Check entitlements in Xcode project

## 📞 Support

If you encounter issues:
1. Check the verification script: `./verify-setup.sh`
2. Review edge function logs in Supabase dashboard
3. Check Stripe webhook logs for payment issues
4. Verify all API keys are correctly set

## 🎉 Success Checklist

- [ ] Database password reset
- [ ] Migration deployed successfully
- [ ] Edge functions deployed
- [ ] Stripe products created
- [ ] Apple Pay products configured
- [ ] Environment variables updated
- [ ] Test purchase completed
- [ ] Credits added to account

Once all items are checked, your Vancouver-based pricing system is fully operational!