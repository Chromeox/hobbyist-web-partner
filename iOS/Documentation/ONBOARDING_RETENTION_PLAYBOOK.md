# Onboarding & Retention Playbook

## 🚀 The First 3 Days (77% Risk Zone)

### Day 0: Sign-Up Success
**Goal**: Immediate value demonstration within 5 minutes

#### Magic Moment Creation
```swift
1. Welcome animation (3 seconds)
2. Three quick questions:
   - "What interests you?" (Fitness/Creative/Culinary/Wellness)
   - "When do you prefer classes?" (Morning/Lunch/Evening/Weekend)
   - "What's your experience?" (Beginner/Some/Regular)
3. Instant personalized recommendation
4. "Your first class is FREE - book now!"
5. Show class happening TODAY within 2km
```

#### Friction Eliminators
- **No credit card for first class**
- **No app download required** (web booking)
- **Social login** (Google/Apple - 2 taps)
- **Skip profile completion** (do later)

### Day 1: First Class Booking
**Goal**: Book within 24 hours (50% do, 50% don't)

#### Smart Nudge Sequence
```
Hour 2:  "Sarah just booked pottery - 2 spots left!"
Hour 6:  "Your free class expires in 48 hours"
Hour 12: "⭐ Popular: Sunset yoga tonight 6pm"
Hour 18: Friend referral: "Emma joined! Book together?"
Hour 24: "Last chance for free class today"
```

#### Booking Accelerators
- **One-tap booking** (no forms)
- **Auto-suggest nearest location**
- **Calendar integration** (add instantly)
- **Friend finder** (who's going?)

### Day 2: Pre-Class Engagement
**Goal**: Increase show-up rate to 85%

#### Anticipation Building
```
Morning:   "Excited for [Class] today? Here's what to bring..."
Afternoon: "Meet your instructor: [Name] - 4.9⭐ rating"
T-2 hours: "Leave in 30 min to arrive on time (traffic: light)"
T-1 hour:  "Sarah and 2 others are heading there now!"
T-30 min:  "Instructor tip: Beginners should..."
```

### Day 3: Post-Class Hook
**Goal**: Second booking within 72 hours

#### Momentum Capture
```
Immediately: "How was [Class]? ⭐⭐⭐⭐⭐"
Hour 1:     "Unlock 25 credits for $30 (40% off!)"
Hour 3:     "Instructor Emma recommended these classes for you..."
Day 3:      "You're 1 class away from Explorer badge!"
```

## 📱 21-Day Habit Formation Program

### Week 1: Discovery Phase
**Theme**: Try Everything

#### Daily Challenges
```
Day 1: Book your first class ✅
Day 2: Explore 3 different categories
Day 3: Add 2 classes to favorites
Day 4: Invite a friend (both get 5 credits)
Day 5: Complete your profile
Day 6: Book a weekend class
Day 7: Share your experience (unlock badge)
```

#### Rewards
- Complete 5/7 tasks = 10 bonus credits
- Perfect week = "Explorer" badge
- Friend joins = 5 credits each

### Week 2: Social Phase
**Theme**: Find Your Tribe

#### Squad Formation
```python
def match_squad(user):
    return Squad(
        size=3-5,
        interests=user.interests,
        schedule=user.availability,
        experience=user.level,
        location=within_5km
    )
```

#### Squad Challenges
- Book class together (2x credits)
- Complete squad streak (3 days)
- Try instructor's recommendation
- Group photo challenge
- Squad chat activation

### Week 3: Commitment Phase
**Theme**: Lock In Your Routine

#### Habit Anchoring
```
Monday:    "Make it Mindful Monday" (meditation/yoga)
Tuesday:   "Try-it Tuesday" (new class type)
Wednesday: "Workout Wednesday" (fitness focus)
Thursday:  "Thirsty Thursday" (social classes)
Friday:    "Fun Friday" (creative/arts)
Saturday:  "Squad Saturday" (group booking)
Sunday:    "Self-care Sunday" (wellness)
```

## 🎮 Gamification & Rewards System

### Achievement Badges

#### Exploration Badges
```
🌟 First Steps: Complete first class
🗺️ Explorer: Try 5 different class types
🌎 Adventurer: Visit 10 different studios
🚀 Pioneer: First to try new class
🎨 Renaissance: Master 3+ categories
```

#### Social Badges
```
👥 Social Butterfly: Bring 3 friends
💪 Squad Goals: 10 classes with squad
🤝 Connector: 25 friend connections
📣 Influencer: 10 referrals joined
👑 Community Leader: 50 classes attended
```

#### Commitment Badges
```
🔥 Week Streak: 7 days in row
⚡ Power User: 20 classes/month
💎 Loyalty Legend: 6 months active
🏆 Centurion: 100 total classes
🌈 Year Member: 12 months active
```

### Credit Rewards Calendar

#### Weekly Bonuses
```
Monday booking = 2 bonus credits
Off-peak class = 1 bonus credit
Friend referral = 5 credits each
Perfect week = 10 credits
Squad streak = 3 credits/person
```

#### Monthly Challenges
```
January:   "New Year New You" - 30 classes = 50 credits
February:  "Love Month" - Bring partner = Double credits
March:     "Spring Training" - Complete program = 40 credits
April:     "Earth Month" - Eco classes = 2x credits
May:       "Mother's Day" - Gift mom = 30 credits
June:      "Summer Body" - 3-month plan = 25% bonus
```

## 💡 Credit Insurance Program

### Addressing Credit Anxiety
**Problem**: 67% fear losing unused credits
**Solution**: Optional insurance removes fear

#### Insurance Tiers
```
Basic ($3/month):
- Credits rollover 1 extra month
- Emergency pause (once/year)

Plus ($5/month):
- Unlimited rollover
- Gift unused credits
- Pause anytime (up to 3 months)
- Credit refund (once/year)

Premium ($8/month):
- Everything in Plus
- Convert credits to gift cards
- Priority booking
- Exclusive instructor sessions
```

### Smart Rollover System

#### Loyalty-Based Rollover
```python
def calculate_rollover(user):
    months_active = user.months_as_member
    
    if months_active < 3:
        return credits * 0.25  # 25% rollover
    elif months_active < 6:
        return credits * 0.50  # 50% rollover
    elif months_active < 12:
        return credits * 0.75  # 75% rollover
    else:
        return credits * 1.00  # 100% rollover
```

## 🏃‍♀️ Retention Interventions

### Churn Risk Indicators

#### Early Warning System
```python
risk_score = calculate_risk(
    days_since_last_class > 14: +30,
    credits_expiring_soon: +25,
    no_future_bookings: +20,
    declined_payment: +15,
    low_app_opens: +10
)

if risk_score > 50:
    trigger_intervention()
```

### Intervention Playbook

#### Level 1: Gentle Re-engagement (Risk: Low)
```
Day 7 inactive:  "Miss you! Here's what's new..."
Day 10:          "Sarah from pottery asked about you"
Day 14:          "5 bonus credits - come back!"
```

#### Level 2: Personalized Outreach (Risk: Medium)
```
Email from instructor: "Haven't seen you in yoga..."
Squad message: "We miss you! Join us Thursday?"
Exclusive offer: "Private session 50% off"
```

#### Level 3: Save Interventions (Risk: High)
```
Pause option: "Take a break, keep your credits"
Downgrade offer: "Switch to lighter plan?"
Exit interview: "Help us improve - 20 credits"
Win-back: "Come back - 1 month free"
```

## 👥 Squad Goals Feature

### Social Accountability System

#### Squad Formation
```
Optimal size: 3-5 members
Matching criteria:
- Schedule compatibility (60% weight)
- Interest alignment (25% weight)  
- Experience level (10% weight)
- Location proximity (5% weight)
```

#### Squad Features
- **Shared calendar**: See squad bookings
- **Group chat**: In-app messaging
- **Squad challenges**: Weekly goals
- **Leaderboard**: Friendly competition
- **Pool credits**: Shared booking power

#### Squad Rewards
```
3-person streak: 5 credits each
5-person class: 10 credits each
Squad of month: 50 credits split
Squad referral: 15 credits each
```

## 📊 Curated Journey Paths

### Pre-Built Monthly Programs

#### "Stress Buster" Journey
```
Week 1: Gentle Yoga → Meditation Basics
Week 2: Breathwork → Restorative Yoga
Week 3: Mindful Pottery → Nature Walk
Week 4: Massage → Sound Bath
Reward: Complete = 20 bonus credits
```

#### "Creative Explorer" Journey
```
Week 1: Watercolor Basics → Photography Walk
Week 2: Pottery Wheel → Creative Writing
Week 3: Jewelry Making → Painting
Week 4: Music Jamming → Final Gallery
Reward: Showcase work = Featured artist
```

#### "Fitness Evolution" Journey
```
Week 1: Yoga Flow → Gentle Pilates
Week 2: Barre Basic → Spin Class
Week 3: HIIT Training → Boxing
Week 4: Dance Cardio → Celebration
Reward: All complete = Fitness badge + 30 credits
```

## 🌦️ Seasonal Retention Programs

### Winter Warrior Program (Nov-Mar)

#### Weather-Proof Engagement
```
Benefits:
- 20% more credits (same price)
- Indoor class priority
- "Cozy Classes" (hot yoga, warm pottery studios)
- Weather cancellation protection
- Vitamin D tracking integration
- SAD lamp class spaces
```

#### Winter Challenges
- "Hibernation Fighter": 3 classes/week
- "Snow Day Special": Double credits on snow days
- "Winter Blues Buster": Wellness focus
- "Comfort Creator": Cooking/crafts emphasis

### Summer Flex Program (Jun-Sep)

#### Outdoor Integration
```
Features:
- Outdoor class priority
- Beach/park locations
- Flexible cancellation
- Vacation pause (keep credits)
- Tourist-friendly options
- Festival partnerships
```

## 📱 Smart Notification Strategy

### Behavioral Trigger Matrix

#### Optimal Timing
```python
def best_notification_time(user):
    if user.morning_person:
        return "7:00 AM"
    elif user.lunch_breaker:
        return "11:30 AM"
    elif user.after_worker:
        return "5:30 PM"
    else:
        return based_on_past_bookings()
```

#### Message Personalization
```
Fitness enthusiast: "Burn 500 calories tonight!"
Social butterfly: "5 friends attending yoga"
Deal seeker: "Flash sale: 50% off pottery"
Explorer: "New class alert: Sushi making"
Routine lover: "Your Thursday spin awaits"
```

## 🎯 Retention KPIs & Targets

### Key Metrics Dashboard

#### Daily Metrics
```
DAU/MAU ratio: Target 25% (industry: 15%)
Bookings per day: Target 500+
Class attendance: Target 85%
Same-day bookings: Target 30%
```

#### Weekly Metrics
```
W1 retention: Target 50% (industry: 23%)
Credits utilized: Target 60%
Squad formation: Target 40% of users
Friend invites: Target 1.5 per user
```

#### Monthly Metrics
```
M1 retention: Target 60% (industry: 47%)
M3 retention: Target 40% (industry: 24%)
M6 retention: Target 30% (industry: 15%)
LTV:CAC ratio: Target 3:1
```

## 💪 Overcoming Specific Objections

### Objection Response Framework

#### "I won't use it enough"
```
Response chain:
1. Show average user saves $50/month
2. Offer pause feature (no credit loss)
3. Start with pay-as-you-go (no subscription)
4. Money-back guarantee first month
5. Calculator: "How many classes to break even?"
```

#### "Credits are confusing"
```
Visual solutions:
- Simple slider: Classes ↔ Credits ↔ Dollars
- Real examples: "Yoga = 1 credit = $2"
- Credit calculator in booking flow
- Monthly statement in dollars saved
```

#### "I'm not fit/skilled enough"
```
Confidence builders:
- "Absolute Beginners" badge for classes
- Private intro sessions available
- Anonymous booking option
- Body-positive instructor filter
- "No judgment zone" studio partners
```

## 🚦 Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Core onboarding flow
- Basic gamification
- Email/push setup
- Squad matching algorithm

### Phase 2: Engagement (Weeks 3-4)
- Journey paths launch
- Advanced notifications
- Social features
- Insurance program

### Phase 3: Optimization (Weeks 5-8)
- A/B test everything
- Personalization engine
- Seasonal programs
- Referral optimization

### Phase 4: Scale (Weeks 9-12)
- Corporate partnerships
- Advanced analytics
- AI recommendations
- Platform expansion

## ✅ Success Checklist

### Week 1 Launch Requirements
- [ ] Free first class flow
- [ ] 21-day challenge setup
- [ ] Basic badges system
- [ ] Squad matching MVP
- [ ] Smart notifications
- [ ] Pause/insurance options

### Month 1 Milestones
- [ ] 250 active users
- [ ] 50% W1 retention
- [ ] 30% squad formation
- [ ] 75% credit utilization
- [ ] 4.5+ app rating

### Month 3 Goals
- [ ] 1,000 active users
- [ ] 40% M3 retention
- [ ] 3:1 LTV:CAC
- [ ] 50 studio partners
- [ ] Break-even unit economics

This playbook provides a comprehensive framework for conquering the 77% three-day abandonment rate and building sustainable user engagement through innovative retention strategies tailored to the Vancouver market.