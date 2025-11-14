# Partner Dashboard Friend Testing Checklist

## 🎯 Welcome Tester!

Thank you for helping test the HobbyApp Partner Dashboard! This is the web portal that studio owners and staff use to manage their classes, bookings, and revenue.

**Testing Time**: 20-30 minutes
**Portal URL**: http://localhost:3000 (or production URL)
**Your Role**: Pretend you're a studio owner/manager

---

## 📋 Pre-Testing Setup (5 minutes)

### What You'll Need
- [ ] **Desktop/Laptop**: Works best on Chrome, Safari, or Firefox
- [ ] **Login Credentials**: We'll provide test studio account
- [ ] **Notepad/Phone**: To jot down issues you find
- [ ] **Good Internet**: Stable WiFi or wired connection

### Test Studio Account
```
Email: [We'll provide]
Password: [We'll provide]
Studio: [Sample Vancouver Studio]
```

---

## ✅ Testing Checklist (20-25 minutes)

### STEP 1: Login & First Impressions (3 minutes)

**Actions to Test:**
- [ ] Visit the partner dashboard URL
- [ ] Enter your test studio credentials
- [ ] Click "Sign In" or "Login"
- [ ] Observe the loading experience

**What to Notice:**
- Does the login page look professional and trustworthy?
- Is the login process smooth and quick?
- Are there any error messages or confusing instructions?
- Does the dashboard load within 3-5 seconds?

**Report Issues Like:**
- "Login button didn't respond when I clicked it"
- "Page took 15 seconds to load"
- "Error message was confusing: [screenshot]"

---

### STEP 2: Dashboard Overview (5 minutes)

**Actions to Test:**
- [ ] Review the main dashboard/home page
- [ ] Look at revenue summary (if visible)
- [ ] Check upcoming classes section
- [ ] Find recent bookings/reservations
- [ ] Navigate between different dashboard sections

**What to Notice:**
- Is the layout clear and organized?
- Can you understand the revenue numbers at a glance?
- Are upcoming classes easy to see?
- Can you quickly find recent bookings?
- Is navigation intuitive (menus, buttons, links)?

**Ask Yourself:**
- "If I ran a yoga studio, could I quickly see how my business is doing?"
- "What information is missing that I'd want to see?"

**Report Issues Like:**
- "I don't understand what 'Platform Fee' means"
- "Can't find where to see my total earnings"
- "Navigation menu is confusing"

---

### STEP 3: Reservations/Bookings Management (5 minutes)

**Actions to Test:**
- [ ] Navigate to Reservations/Bookings page
- [ ] View list of upcoming bookings
- [ ] Click on a booking to see details
- [ ] Try filtering bookings (by date, status, etc.)
- [ ] Look for student/attendee information

**What to Notice:**
- Can you see who booked which classes?
- Is the booking information complete (name, class, date, payment)?
- Can you tell if someone paid with credits or cash?
- Are filters easy to use?
- Can you export or print the booking list?

**Studio Owner Perspective:**
- "Can I prepare for tomorrow's classes based on this info?"
- "Would I know who to expect at my pottery class tonight?"

**Report Issues Like:**
- "Booking details are incomplete"
- "Can't see student email addresses"
- "Filter by date doesn't work"

---

### STEP 4: Class Schedule & Management (4 minutes)

**Actions to Test:**
- [ ] Find where classes are listed
- [ ] View class details (name, instructor, schedule, price)
- [ ] Check if you can see class capacity/enrollment
- [ ] Look for past vs. upcoming classes

**What to Notice:**
- Is your class schedule accurate?
- Can you see how many spots are left in each class?
- Is pricing clearly displayed?
- Can you tell which classes are popular?

**Report Issues Like:**
- "Classes are missing from the list"
- "Can't see how many people signed up"
- "Class times are wrong"

---

### STEP 5: Revenue & Payments (5 minutes)

**Actions to Test:**
- [ ] Navigate to Revenue/Payments/Earnings section
- [ ] Review your studio's earnings summary
- [ ] Look for platform commission breakdown (30% platform / 70% you)
- [ ] Check payout schedule or history
- [ ] Find Stripe Connect status (if applicable)

**What to Notice:**
- Can you understand how much you've earned?
- Is the 30% commission clearly shown?
- Do you know when you'll get paid?
- Are there any confusing financial terms?

**Studio Owner Perspective:**
- "Can I tell if my studio is profitable?"
- "Do I trust these revenue calculations?"

**Report Issues Like:**
- "Revenue numbers don't add up"
- "Don't understand 'Platform Fee' vs 'Studio Payout'"
- "No information about when I get paid"

---

### STEP 6: Mobile Experience (3 minutes)

**Actions to Test:**
- [ ] Open dashboard on your phone or tablet
- [ ] Try navigating between sections
- [ ] Check if key info is still visible
- [ ] Test login on mobile

**What to Notice:**
- Does the layout adjust well to smaller screens?
- Can you still do essential tasks on mobile?
- Are buttons big enough to tap easily?
- Is text readable without zooming?

**Report Issues Like:**
- "Menu is hidden on mobile and I can't find it"
- "Revenue chart is too small to read"
- "Login form is cut off on phone"

---

## 🐛 What We Need You to Report

### 🚨 Critical Issues (Report Immediately)
- **Cannot login** or get locked out
- **Page crashes** or shows blank white screen
- **Revenue calculations** appear incorrect
- **Can't see bookings** or missing student information
- **Security concerns** (seeing other studios' data)

**How to Report Critical Issues:**
- Screenshot the error
- Email immediately to: support@hobbyist.app
- Subject: "URGENT - Partner Dashboard Critical Bug"

---

### ⚠️ Major Issues (Report Soon)
- **Confusing navigation** or can't find features
- **Slow loading** (pages take 10+ seconds)
- **Missing important information** (student emails, class times)
- **Broken filters** or search features
- **Mobile doesn't work** properly

---

### 💡 General Feedback & Suggestions
- **Features you wish existed** (e.g., "I want to message students")
- **Confusing terminology** (e.g., "What does 'Platform Fee' mean?")
- **Layout improvements** (e.g., "Revenue should be at the top")
- **Overall impression**: Would you actually use this to run your studio?
- **Comparison**: How does it compare to other booking systems you've used?

---

## 📝 How to Report Issues

### Option 1: Email (Easiest)
**Email**: support@hobbyist.app
**Subject**: Partner Dashboard Testing Feedback
**Include**:
1. **What you were trying to do**
   Example: "I was trying to see tomorrow's class bookings"

2. **What happened instead**
   Example: "The page showed an error message"

3. **Screenshots** (if possible)
   Example: [Screenshot of error]

4. **Your device & browser**
   Example: "MacBook Pro, Chrome browser"

---

### Option 2: Text/WhatsApp
If we provided a phone number, you can:
- Text us screenshots with brief description
- Send quick voice notes about confusing parts
- Ask clarifying questions during testing

---

### Option 3: Shared Google Doc
If we shared a feedback document:
- Add your findings to the shared doc
- Include screenshots inline
- Use the template sections we provided

---

## 💬 Great Feedback Examples

### ✅ Good Feedback
> "When I clicked on 'Reservations', the page took 12 seconds to load. It just showed a spinning circle. I'm on WiFi and other websites load fine. [Screenshot attached]"

> "The revenue section shows $150 total, but when I manually add up the bookings ($25 × 6 = $150), that matches. However, I don't understand what 'Platform Fee $45' means. Is that coming out of my $150?"

> "I love how I can see upcoming classes on the main dashboard. But I wish I could click on a class to see who's enrolled without going to a different page."

### ❌ Less Helpful Feedback
> "It's broken"
> *Too vague - what's broken? Which page?*

> "Looks good!"
> *We need specifics - what worked well? What didn't?*

---

## 🎯 Testing Scenarios

### Scenario A: Morning Studio Check
**Imagine**: It's 8am and you want to see who's coming to your 10am pottery class.

**Try This:**
1. Login to dashboard
2. Find today's classes
3. See who's enrolled in the 10am class
4. Get their names/emails to prepare materials

**Report**: Could you do this easily? What was confusing?

---

### Scenario B: End of Week Revenue Review
**Imagine**: It's Friday and you want to see how much you earned this week.

**Try This:**
1. Navigate to revenue/earnings section
2. Find this week's total revenue
3. Understand how much goes to you (70%) vs. platform (30%)
4. Check when you'll receive payment

**Report**: Could you trust these numbers? Was anything unclear?

---

### Scenario C: New Booking Notification
**Imagine**: You just got an email that someone booked your Saturday watercolor class.

**Try This:**
1. Find the Saturday watercolor class in your dashboard
2. See the new booking
3. Find the student's name and contact info
4. Confirm payment method (credits or cash)

**Report**: Was this information easy to find? What's missing?

---

## ⏰ Testing Timeline

### This Week
- **Install/access**: Whenever convenient
- **Testing time**: 20-30 minutes total
- **Multiple sessions**: Feel free to test over several days

### Feedback Deadline
- **Preferred**: Within 3-5 days
- **Final deadline**: [We'll specify]
- **Follow-up**: We may ask clarifying questions

---

## 🎁 Thank You!

### Why Your Feedback Matters
You're helping build a tool that will empower Vancouver's creative studios to:
- Manage bookings more efficiently
- Get paid fairly and transparently
- Grow their business with less admin work
- Connect with more students through our platform

### What Happens Next
1. **We fix critical bugs** immediately
2. **Incorporate your suggestions** into the next version
3. **Invite you to test updates** (if you're interested)
4. **Launch to real studios** across Vancouver!

### Questions?
- **Technical support**: support@hobbyist.app
- **General questions**: Reply to our email
- **Urgent issues**: [Phone number if provided]

---

## 🚀 Ready to Start Testing?

### Quick Start
1. **Open the partner dashboard** in your browser
2. **Login with test credentials** we provided
3. **Follow the checklist above** (20-30 minutes)
4. **Send us your feedback** via email or shared doc
5. **Be honest!** We want to know what's broken or confusing

### Most Important
**Pretend you're a real studio owner.** Would you trust this tool to manage your business? What would make you confident enough to use it every day?

---

**Thank you for helping build HobbyApp!** 🎨

*Your feedback directly shapes how Vancouver's creative studios will manage their businesses.*

---

**The HobbyApp Team**
Building tools that empower Vancouver's creative community

support@hobbyist.app | hobbyist.app
