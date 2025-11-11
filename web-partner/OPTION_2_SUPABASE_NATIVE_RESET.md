# Option 2: Supabase Native Password Reset Flow

## Quick Setup (2 minutes)

### Step 1: Update Supabase Email Template

Go to: **Supabase Dashboard → Authentication → Email Templates → Reset Password**

Replace the current template with:

```html
<h2>Reset Password</h2>
<p>Follow this link to reset the password for your account:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
<p>Or copy and paste this URL into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
```

**Key Change**: Using `{{ .ConfirmationURL }}` instead of manually building the URL.

### Step 2: Set Redirect URL in Supabase

Go to: **Supabase Dashboard → Authentication → URL Configuration**

Add to **Redirect URLs**:
```
https://your-deployment-url.vercel.app/auth/reset-password
```

**Important**: Replace `your-deployment-url` with your actual Vercel deployment URL.

### Step 3: Update Code (Minimal Changes)

The existing `/auth/reset-password` page should work as-is since it already checks for session on mount.

**How it works**:
1. User requests password reset
2. Supabase sends email with `{{ .ConfirmationURL }}`
3. Link includes access token in URL fragment: `/auth/reset-password#access_token=...`
4. Browser-side JavaScript extracts token and sets session
5. ResetPasswordForm detects valid session and shows form
6. User changes password
7. Done! ✅

### Step 4: Test

1. Go to `/auth/forgot-password`
2. Enter email
3. Check inbox
4. Click reset link
5. **Expected**: Direct to password reset form with valid session

## If This Works

✅ Delete the complex callback route logic
✅ Simplify middleware (no special cases needed)
✅ Use Supabase's battle-tested flow

## If This Doesn't Work → Option 3

We'll implement magic link authentication instead (simpler, no passwords).

---

**Time to Test**: ~2 minutes
**Complexity**: Very Low
**Success Rate**: High (proven pattern)
