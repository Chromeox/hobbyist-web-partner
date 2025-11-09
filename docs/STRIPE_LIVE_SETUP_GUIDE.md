# Stripe Live Setup Guide

## Current Status
✅ **Stripe SDK Integration**: Ready  
✅ **Test Keys**: Configured in Configuration.swift  
🔄 **Live Keys**: Need to be updated  
🔄 **Bank Account**: Needs connection  

## Step 1: Access Your Stripe Dashboard

1. Go to https://dashboard.stripe.com
2. **Switch to Live Mode** (toggle in top-left corner)
3. Ensure your account is activated for live payments

## Step 2: Get Live API Keys

1. In Live Mode, go to **Developers → API Keys**
2. Copy these keys:
   - **Publishable Key**: `pk_live_...` (safe to embed in app)
   - **Secret Key**: `sk_live_...` (keep secure, server-side only)

## Step 3: Update App Configuration

Update the live key in `HobbyApp/Configuration.swift`:

```swift
// Line 17: Replace with your actual live publishable key
return ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"] ?? "pk_live_YOUR_ACTUAL_KEY_HERE"
```

## Step 4: Connect Your Bank Account

### For Canadian Bank Account:

1. In Stripe Dashboard → **Settings → Payouts**
2. Click **Add bank account**
3. Enter your Canadian bank details:
   - Bank Name
   - Transit Number (5 digits)
   - Institution Number (3 digits)  
   - Account Number
4. **Verify Account**: Stripe will make small test deposits
5. **Set Payout Schedule**: 
   - Recommended: Daily automatic payouts
   - Minimum: $1 CAD

## Step 5: Complete Account Verification

### Business Information Required:
- **Business Type**: Individual or Corporation
- **Address**: Canadian address
- **Tax Information**: SIN or Business Number
- **Identity Verification**: Government ID upload

### Representative Information:
- Full legal name
- Date of birth
- Address
- Phone number

## Step 6: Configure Webhooks (Optional but Recommended)

1. Go to **Developers → Webhooks**
2. Add endpoint: `https://your-domain.com/stripe-webhooks`
3. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.dispute.created`
   - `customer.subscription.created`

## Step 7: Test Live Integration

```bash
# Run the live payment test script
./scripts/test_live_stripe.sh
```

## Step 8: Production Checklist

- [ ] Live keys configured in app
- [ ] Bank account connected and verified
- [ ] Business information complete
- [ ] Representative information verified
- [ ] Webhook endpoints configured
- [ ] Test payment processed successfully
- [ ] Payout schedule configured

## Commission Setup for Studios

For the 30% platform fee / 70% studio payout model:

1. **Stripe Connect**: Set up Express accounts for studios
2. **Revenue Sharing**: Automatic 70% transfers to studios
3. **Platform Fee**: 30% retained for platform operations

## Security Notes

- Never commit live secret keys to git
- Use environment variables for sensitive data
- Keep live and test environments separate
- Monitor transactions for suspicious activity

## Support

If you encounter issues:
- Stripe Support: https://support.stripe.com
- Email: support@stripe.com
- Phone: Available in dashboard