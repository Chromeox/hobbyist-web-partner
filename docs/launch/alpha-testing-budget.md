# Alpha Testing Budget Breakdown
**Financial Planning for 8-Week Launch**

---

## Total Investment Required: $2,675

### Phase 1: Alpha Testing (Weeks 1-3) = $1,175
### Phase 2: Beta Expansion (Weeks 4-8) = $1,500

---

## Phase 1: Alpha Testing Budget ($1,175)

### **1. Alpha Tester Credits: $875**

**Logic:**
- 50 alpha testers × $25 credit pack each = $1,250 face value
- Studios receive 70% payout = $875 actual cost
- Platform keeps 30% commission = $375 (offsets platform costs)
- **Net cash outflow: $875**

**Why This Approach:**
✅ Tests complete payment flow end-to-end
✅ Generates real revenue data for investors
✅ Creates studio relationships through actual transactions
✅ Motivates testers to actually use the app (paid value)
✅ Realistic usage patterns vs free testing

**Alternative Approaches (Not Recommended):**
- ❌ **Free testing with no credits**: Low engagement, no payment testing
- ❌ **$10 credits instead**: Not enough to book full class ($18-22 typical)
- ❌ **100% free for all testers**: No revenue metrics, unrealistic usage

**Implementation:**
- Option A: Create Stripe promo code `ALPHA25` (auto-applied at signup)
- Option B: Manual credit addition via Supabase database
- Recommended: Option A for scalability

---

### **2. Business Cards: $50**

**Specs:**
- Quantity: 100 cards
- Size: 3.5" × 2" (standard)
- Finish: Matte (premium, not glossy)
- Printing: Vistaprint or local printer
- Rush delivery: +$20 (optional if urgent)

**Design Costs:**
- DIY with Canva: $0 (free tier sufficient)
- Professional designer: $50-150 (not necessary for alpha)
- **Recommended: DIY = $0 design cost**

**Total:** $30 printing + $20 rush delivery = $50

**Breakdown:**
- Base price (100 cards): $25-30
- Rush shipping (2-3 days): $15-20
- Alternative: Staples same-day at $40-50

---

### **3. One-Pager Leave-Behinds: $150**

**Specs:**
- Quantity: 50 postcards
- Size: 4" × 6" (postcard format)
- Finish: Glossy (eye-catching, premium feel)
- Double-sided full color
- Printing: Vistaprint recommended

**Why Postcards > Flyers:**
✅ More premium perception
✅ Studio owners more likely to keep
✅ Stands out on desk vs paper flyer (trashed immediately)
✅ Fits in pocket/bag easily
✅ QR code scans better on cardstock

**Total:** $100 printing + $50 rush delivery = $150

**Breakdown:**
- Base price (50 postcards, 4×6, glossy): $80-100
- Rush shipping (2-3 days): $30-50
- Alternative: Local printer at $120-150

---

### **4. Miscellaneous & Contingency: $100**

**Expected Uses:**
- Parking during studio visits: $20-30
- Coffee meetings with interested studios: $30-40
- QR code setup/hosting (if paid tool): $0-20
- Emergency reprints if materials run out: $30-50
- **Contingency buffer: $50**

**Why Include Contingency:**
- Unexpected printing errors
- Need more materials faster than expected
- Studio takes you to lunch (reciprocate professionally)
- Last-minute supplies (notebooks, folders, etc.)

---

## Phase 2: Beta Expansion Budget ($1,500)

### **1. Additional Tester Credits: $625**

**Logic:**
- 25 additional testers (total 75) × $25 each = $625 face value
- Studios receive 70% = $437.50 actual cost
- Platform keeps 30% = $187.50
- **Net cash outflow: $437.50**

**But budgeting $625 for:**
- Some testers may purchase additional credits (test flow)
- Potential promos to re-engage inactive testers
- Bug bounty credits ($25 critical, $10 minor bugs)
- Referral rewards (5 credits for inviter + invitee)

**Recommended allocation:**
- $437.50: New tester gift credits
- $100: Bug bounty pool
- $50: Referral rewards
- $37.50: Re-engagement promos
- **Total: $625**

---

### **2. Paid User Acquisition Testing: $500**

**Channel Split:**

**Facebook/Instagram Ads: $300**
- Target: Vancouver, 25-40 years old
- Interests: Pottery, cooking, yoga, art classes, creative workshops
- Campaign objective: App installs (iOS)
- Budget: $10/day × 30 days = $300
- Expected: 30-60 installs at $5-10 CPA (Customer Acquisition Cost)

**Google Ads: $200**
- Keywords: "pottery classes Vancouver", "cooking classes Vancouver", "creative classes near me"
- Campaign objective: App installs
- Budget: $7/day × 28 days = $196
- Expected: 20-40 installs at $5-10 CPA

**Why Test Paid Acquisition:**
✅ Learn actual Customer Acquisition Cost (CAC)
✅ Test messaging (what resonates?)
✅ Validate channel viability before scaling
✅ Build retargeting pixel data
✅ Proof of concept for investors (paid growth works)

**Success Criteria:**
- CAC <$20 per user (target)
- 10%+ click-through rate on ads
- 30%+ install-to-signup conversion
- 60%+ signup-to-first-booking conversion

If CAC >$30: Pause paid ads, focus on organic until unit economics improve.

---

### **3. Digital Tools & Hosting: $35**

**Landing Page:**
- Domain: hobbyistapp.com ($15/year)
  - GoDaddy or Namecheap
- Hosting: Vercel/Netlify ($0, free tier sufficient for alpha)
- Alternative: Squarespace ($16/month if want easy builder)

**Analytics:**
- Mixpanel: $0 (free up to 100K events/month)
- Firebase: $0 (free Spark plan sufficient for alpha)
- Google Analytics: $0 (free)

**Email Marketing** (if needed):
- Mailchimp: $0 (free up to 500 contacts)
- SendGrid: $0 (free up to 100 emails/day)

**Total digital: $15 domain + $20 buffer = $35**

---

### **4. Contingency Buffer: $340**

**Planned Uses:**
- Additional printing if materials run out ($100)
- Emergency bug fixes (contract developer if needed) ($150)
- Extra promo credits for engagement ($50)
- Unanticipated expenses ($40)

**Why Large Buffer:**
- Alpha testing reveals unknowns
- Better to have and not need than scramble
- Peace of mind to focus on execution

---

## Budget Summary Table

| Category | Alpha (Weeks 1-3) | Beta (Weeks 4-8) | Total |
|----------|-------------------|------------------|-------|
| **Tester Credits** | $875 | $625 | $1,500 |
| **Business Cards** | $50 | $0 | $50 |
| **One-Pagers** | $150 | $0 | $150 |
| **Paid Ads** | $0 | $500 | $500 |
| **Digital Tools** | $0 | $35 | $35 |
| **Miscellaneous** | $100 | $0 | $100 |
| **Contingency** | $0 | $340 | $340 |
| **TOTAL** | **$1,175** | **$1,500** | **$2,675** |

---

## Funding Sources & Cash Flow

### **Option 1: Personal Investment (Bootstrapped)**
- Invest $2,675 from personal savings
- Maintain full ownership (100% equity)
- Risk: Personal capital at risk
- Benefit: No dilution, no investor obligations

### **Option 2: Friends & Family Round**
- Raise $10K-25K from close network
- Offer 5-10% equity
- Use $2,675 for alpha/beta, rest for scaling
- Risk: Relationship strain if fails
- Benefit: Runway for 6-12 months

### **Option 3: Self-Funding Through Revenue**
- Alpha generates ~$375 in platform commission (30% of $1,250 GMV)
- Beta generates ~$500-1,000 in commissions
- Reinvest commissions into paid ads
- Risk: Slower growth
- Benefit: Profitable from day one

### **Recommended Approach:**
**Hybrid: Personal investment for alpha + revenue reinvestment for beta**
- Fund alpha with $1,175 personal capital
- Use alpha revenue ($375 commission) to partially fund beta
- Add $1,125 personal capital for remaining beta costs
- Total personal investment: $2,300
- Revenue offset: $375
- **Net cash outflow: $1,925 over 8 weeks**

---

## Return on Investment (ROI) Projections

### **Conservative Scenario**
**Assumptions:**
- 50 active users after 8 weeks
- Avg $50 credit purchases per user in first 60 days
- 30% platform commission
- $2,675 total investment

**Revenue:**
- 50 users × $50 = $2,500 GMV (Gross Merchandise Value)
- Platform commission (30%): $750
- **ROI: -$1,925 net loss** (still building, expected)

**Break-even: 179 active users** (@ $50 avg purchase)

---

### **Moderate Scenario**
**Assumptions:**
- 200 active users after 8 weeks (realistic with paid ads)
- Avg $60 credit purchases per user (two $30 purchases)
- 30% platform commission

**Revenue:**
- 200 users × $60 = $12,000 GMV
- Platform commission (30%): $3,600
- **ROI: +$925 net profit** (35% return in 8 weeks)

**This is the target scenario.**

---

### **Aggressive Scenario**
**Assumptions:**
- 500 active users after 8 weeks (viral growth)
- Avg $75 credit purchases per user
- 30% platform commission

**Revenue:**
- 500 users × $75 = $37,500 GMV
- Platform commission (30%): $11,250
- **ROI: +$8,575 net profit** (320% return in 8 weeks)

**Unlikely but possible with strong word-of-mouth.**

---

## Budget Optimization Strategies

### **If Budget Is Tight (<$1,500 Available)**

**Priority 1: Essential ($875)**
- Alpha tester credits: $875 (non-negotiable for real testing)

**Priority 2: High Impact ($200)**
- Business cards: $50 (need for studio visits)
- One-pagers: $150 (need for leave-behinds)

**Total Minimum: $1,075**

**Cut:**
- ❌ Paid ads ($500) → Focus on organic growth
- ❌ Contingency buffer → Use revenue for emergencies
- ❌ Rush shipping → Standard delivery (save $40)

---

### **If Budget Is Very Tight (<$1,000 Available)**

**Priority 1: Absolutely Essential ($875)**
- Alpha tester credits: $875

**Priority 2: DIY Marketing ($50)**
- Print business cards at Staples: $40
- Skip professional one-pagers → Use email/PDF instead

**Total Ultra-Minimum: $925**

**Trade-offs:**
- Less professional studio outreach (email vs physical leave-behind)
- Slower growth (organic only)
- But still validates product-market fit with real users

---

## Expense Tracking Template

**Use this to track actual spend:**

| Date | Category | Item | Vendor | Budgeted | Actual | Variance | Notes |
|------|----------|------|--------|----------|--------|----------|-------|
| [Date] | Tester Credits | 25 alpha gifts | Stripe | $437.50 | $437.50 | $0 | First batch |
| [Date] | Printing | Business cards | Vistaprint | $50 | $47 | -$3 | Saved on shipping |
| [Date] | Printing | One-pagers | Vistaprint | $150 | $165 | +$15 | Upgraded paper |
| [Date] | Misc | Parking | EasyPark | $20 | $18 | -$2 | Studio visits |
| ... | ... | ... | ... | ... | ... | ... | ... |
| **TOTAL** | | | | **$2,675** | **TBD** | **TBD** | |

**Tracking Benefits:**
- Spot overspending early
- Adjust future budgets
- Investor transparency
- Tax deduction documentation

---

## Financial Milestones & Check-Ins

### **Week 1 Check-In**
- ✅ Alpha budget allocated ($1,175)?
- ✅ Credits purchased/loaded for testers?
- ✅ Printing ordered and received?
- 🔴 Over budget? → Identify cuts for beta phase

### **Week 3 Check-In**
- ✅ Alpha spend within budget?
- ✅ Generated revenue covering any costs?
- ✅ Ready to allocate beta budget ($1,500)?
- 🔴 Alpha metrics weak? → Reconsider paid ad spend

### **Week 6 Check-In**
- ✅ Beta spend on track?
- ✅ Paid ad CAC acceptable (<$20)?
- ✅ Revenue growing to offset costs?
- 🔴 CAC too high? → Pause ads, optimize organic

### **Week 8 Check-In (Final)**
- ✅ Total spend ≤ $2,675?
- ✅ Revenue generated ≥ $2,000?
- ✅ Unit economics proven (LTV > CAC)?
- 🎯 Plan next phase budget based on learnings

---

## Key Budget Principles

1. **Pay for Results, Not Hope**
   - Tester credits = real usage data ✅
   - Printing = tangible studio outreach ✅
   - Paid ads = measurable CAC ✅
   - Avoid: Consultants, agencies, PR firms (too early)

2. **DIY Everything Possible**
   - Design your own cards/one-pagers (Canva)
   - Write your own copy (you know the product best)
   - Manual credit loading (save on automation tools)
   - Personal outreach (no sales reps needed yet)

3. **Invest in Learning**
   - Small paid ad budget = learn channels
   - Bug bounty = learn product gaps
   - Tester credits = learn usage patterns
   - Every dollar should teach you something

4. **Preserve Runway**
   - Underspend if possible
   - Revenue reinvestment when feasible
   - Don't prematurely scale (wait for product-market fit)
   - Rule: 6 months runway minimum before scaling

5. **Track Everything**
   - Know where every dollar goes
   - Compare budgeted vs actual weekly
   - Adjust future budgets based on learnings
   - Financial discipline = investor confidence

---

## Conclusion

**$2,675 is a lean but sufficient budget to:**
✅ Test product-market fit with 50-75 real users
✅ Validate studio partnership model with 3-10 studios
✅ Learn customer acquisition costs across channels
✅ Generate initial revenue and testimonials
✅ Prove concept to investors or scale organically

**This is startup validation, not perfection.** Spend wisely, learn fast, adjust quickly.

---

**Next Steps:**
1. Set aside $1,175 for Week 1 alpha launch
2. Open separate business bank account (optional but recommended)
3. Track every expense in spreadsheet
4. Review budget weekly
5. Celebrate wins while being financially disciplined 🎉

*Remember: Airbnb started with air mattresses. You've got this with $2,675!*

---

*Last Updated: November 2025*
