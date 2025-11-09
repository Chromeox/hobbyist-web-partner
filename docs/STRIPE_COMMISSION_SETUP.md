# Stripe Commission Setup - 30% Platform Fee

## Revenue Model
- **Platform Fee**: 30% (your revenue)
- **Studio Payout**: 70% (goes to studios)
- **Credit Pack Sales**: 100% to platform initially, distributed when used

## Setup Steps

### 1. Configure Express Accounts for Studios
```
1. Go to Stripe Dashboard → Connect → Accounts
2. Create Express accounts for each studio partner
3. Studios complete onboarding independently
4. Automatic payouts to their bank accounts
```

### 2. Payment Flow Configuration
```
Customer pays $100 for class:
├── Platform keeps: $30 (your commission)
├── Studio receives: $70 (automatic transfer)
└── Stripe fee: ~3% (split between both)
```

### 3. Credit Pack Revenue Distribution
```
Customer buys $50 credit pack:
├── Immediate platform revenue: $50
├── When credits used for $100 class:
    ├── Platform keeps: $30 
    └── Studio receives: $70
```

### 4. Payout Schedule
- **Platform**: Daily automatic payouts to your bank
- **Studios**: Daily automatic payouts to their banks
- **Minimum payout**: $1 CAD

## Implementation in App

The commission split is handled automatically by Stripe Connect when:
1. Customer makes payment
2. Platform fee (30%) retained
3. Transfer (70%) sent to studio's Express account

## Monitoring Revenue

Track your earnings in:
- Stripe Dashboard → Payments
- Custom analytics in partner portal
- Monthly revenue reports

## Canadian Tax Considerations

- Report platform fees (30%) as business income
- Studios receive T4A/T5018 for their 70% portion
- Keep detailed records for CRA reporting