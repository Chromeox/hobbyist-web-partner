# Supabase Password Reset Configuration Checklist

This document contains the **critical Supabase Dashboard settings** required for the password reset flow to work.

---

## ✅ Configuration Steps

### 1. Email Template Configuration

**Location:** Supabase Dashboard → Authentication → Email Templates → "Reset Password"

**Required Template:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.5;
            color: #333333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f5ff;
        }
        .header {
            text-align: center;
            margin-bottom: 25px;
        }
        .logo {
            color: #6a4c93;
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .action-container {
            background: white;
            border-radius: 8px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin: 20px 0;
            border: 1px solid #e0d6ff;
        }
        .action-button {
            display: inline-block;
            padding: 12px 30px;
            background-color: #6a4c93;
            color: white !important;
            text-decoration: none;
            border-radius: 4px;
            font-weight: bold;
            font-size: 16px;
            margin: 15px 0;
        }
        .expiry-note {
            font-size: 13px;
            color: #666666;
            margin-top: 15px;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #999999;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">Hobbyist</div>
        <h2 style="margin: 10px 0; font-weight: 600;">Reset Your Password</h2>
    </div>

    <div class="action-container">
        <p>We received a request to reset your Hobbyist password. Click below to choose a new one:</p>

        <a href="{{ .SiteURL }}/auth/callback?token_hash={{ .TokenHash }}&type=recovery&next=/auth/reset-password" class="action-button">Reset Password</a>

        <p class="expiry-note">This link expires in 1 hour</p>
    </div>

    <p><strong>If you didn't request this:</strong> You can safely ignore this email - your password won't be changed.</p>

    <div class="footer">
        <p>2025 Hobbyist | Keep creating!</p>
    </div>
</body>
</html>
```

**⚠️ CRITICAL:** The link MUST include:
- `{{ .SiteURL }}` - Auto-populated by Supabase
- `/auth/callback` - Your callback route
- `?token_hash={{ .TokenHash }}` - The recovery token
- `&type=recovery` - Tells callback it's a password reset
- `&next=/auth/reset-password` - Where to redirect after verification

---

### 2. Redirect URLs Configuration

**Location:** Supabase Dashboard → Authentication → URL Configuration → Redirect URLs

**Add these URLs to the whitelist:**

```
https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/auth/callback
http://localhost:3000/auth/callback
```

**For your custom domain (when ready):**
```
https://your-custom-domain.com/auth/callback
```

**⚠️ IMPORTANT:**
- Must include `/auth/callback` (NOT `/auth/confirm`)
- Must be exact URL (no wildcards)
- Add both production AND development URLs

---

### 3. Site URL Configuration

**Location:** Supabase Dashboard → Authentication → URL Configuration → Site URL

**Set to:**
- **Production:** `https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app`
- **Development:** `http://localhost:3000`

**⚠️ NOTE:** Only set ONE at a time. Switch between them based on where you're testing.

---

### 4. Email Settings (Optional but Recommended)

**Location:** Supabase Dashboard → Authentication → Email Settings

**Recommended Settings:**
- **Enable Confirmations:** ✓ Yes
- **Secure Email Change:** ✓ Yes
- **Email Rate Limit:** 3 emails per hour (prevent abuse)
- **Token Expiry:** 3600 seconds (1 hour - default)

---

## 🧪 Testing the Configuration

### Step 1: Request Password Reset
1. Go to: `https://your-domain.com/auth/forgot-password`
2. Enter your email
3. Click "Send Reset Link"
4. Check your email inbox

### Step 2: Verify Email Content
Open the reset email and check:
- ✅ Link starts with your correct Site URL
- ✅ Link contains `/auth/callback`
- ✅ Link contains `token_hash=` parameter
- ✅ Link contains `type=recovery` parameter
- ✅ Link contains `next=/auth/reset-password` parameter

**Example correct link:**
```
https://your-domain.com/auth/callback?token_hash=abc123xyz&type=recovery&next=/auth/reset-password
```

### Step 3: Click Reset Link
You should see:
1. **Brief loading:** "Verifying Link..." (1-2 seconds)
2. **Reset form:** Password input fields with strength meter
3. **Success:** "Password Reset Successful!" → Redirects to dashboard

### Step 4: Check Browser Console
Open Developer Tools (F12) and look for these logs:
```
[Auth callback] Processing email magic link: { type: 'recovery' }
[Auth callback] Email magic link verification result: { success: true }
[Reset Password] Session check: { hasSession: true }
```

### Step 5: Check Supabase Logs
Go to: Supabase Dashboard → Logs → Auth Logs

Look for:
- `verifyOtp` event with `type: recovery`
- `updateUser` event (when password is changed)
- No error messages

---

## ❌ Common Issues & Solutions

### Issue: "Link Expired" Error
**Symptoms:** Form shows expired message immediately
**Causes:**
- Token already used (can only use once)
- Link older than 1 hour
- Session cookies not being set

**Solutions:**
1. Request a NEW reset link (don't reuse old ones)
2. Check Site URL matches deployment URL
3. Clear browser cookies and try again

---

### Issue: Email Link Goes to Wrong Page
**Symptoms:** Clicking email goes to 404 or signin page
**Causes:**
- Redirect URL not whitelisted
- Email template using wrong URL
- Site URL misconfigured

**Solutions:**
1. Verify Redirect URLs whitelist includes `/auth/callback`
2. Check email template uses `{{ .SiteURL }}/auth/callback`
3. Ensure Site URL matches your deployment

---

### Issue: Password Reset Button Broken in Email
**Symptoms:** Button not clickable or no href
**Causes:**
- Missing `href` attribute in template
- Wrong template variable (e.g., `{{ .ActionURL }}` instead of `{{ .ConfirmationURL }}`)

**Solutions:**
1. Use the template provided above (Step 1)
2. Verify href includes all required parameters
3. Send test email and view source code

---

### Issue: Form Flashes Then Redirects
**Symptoms:** Reset form appears briefly then disappears
**Causes:**
- Session not persisting from callback to reset page
- Cookie domain mismatch
- Browser blocking third-party cookies

**Solutions:**
1. Check callback route sets cookies properly (it does ✅)
2. Test in incognito mode (rules out extension issues)
3. Check browser doesn't block Supabase cookies

---

### Issue: "Auth Session Missing" Error
**Symptoms:** Can't update password, session error
**Causes:**
- Session expired (took too long)
- Cookies not accessible
- User opened link on different device

**Solutions:**
1. Request new reset link
2. Complete reset within 5 minutes
3. Don't switch browsers/devices

---

## 📝 Quick Reference

| Setting | Location | Value |
|---------|----------|-------|
| **Email Template** | Auth → Email Templates → Reset Password | Use template above |
| **Redirect URLs** | Auth → URL Configuration | Add `/auth/callback` URLs |
| **Site URL** | Auth → URL Configuration | Your deployment URL |
| **Token Expiry** | Auth → Email Settings | 3600 seconds (1 hour) |

---

## 🚀 After Configuration

Once you've updated all settings:

1. **Test locally first:**
   ```bash
   npm run dev
   # Test at http://localhost:3000/auth/forgot-password
   ```

2. **Deploy to Vercel:**
   ```bash
   git add .
   git commit -m "fix: complete password reset flow with strength meter"
   git push origin main
   ```

3. **Update Site URL** in Supabase to production URL

4. **Test on production:**
   - Request reset from production URL
   - Check email uses correct production link
   - Verify entire flow works end-to-end

---

## 📧 Support

If password reset still doesn't work after following this guide:

1. Check Vercel deployment logs for errors
2. Check Supabase Auth logs for failed verifications
3. Check browser console for JavaScript errors
4. Verify ALL settings match this guide exactly

---

**Last Updated:** November 10, 2025
**App Version:** v1.0 (Alpha Launch Ready)
