# Option 3: Magic Link Authentication (Passwordless)

## The Approach

Instead of password reset, use **passwordless magic links**:
- User enters email
- Receives one-time login link
- Clicks link → auto-logged in
- Can optionally set password in account settings

## Benefits

✅ **Simpler UX**: One less thing to remember
✅ **More Secure**: No passwords to steal/leak
✅ **Less Code**: No password reset flow needed
✅ **Modern Pattern**: Used by Slack, Notion, Medium, etc.

## Implementation

### 1. Update ForgotPasswordForm Component

Change the form to send magic link instead of password reset:

```typescript
// In components/auth/ForgotPasswordForm.tsx
const { error } = await supabase.auth.signInWithOtp({
  email: state.email,
  options: {
    emailRedirectTo: `${window.location.origin}/dashboard`,
  }
})
```

### 2. Update Email Template

**Supabase Dashboard → Authentication → Email Templates → Magic Link**

```html
<h2>Sign in to Your Account</h2>
<p>Click this link to sign in:</p>
<p><a href="{{ .ConfirmationURL }}">Sign In</a></p>
<p>This link expires in 1 hour.</p>
```

### 3. Update UI Copy

Change "Forgot Password?" to "Sign in with Email Link"

### 4. Optional: Add Password Setting in Dashboard

If users want to set a password later:

```typescript
// In dashboard settings
const { error } = await supabase.auth.updateUser({
  password: newPassword
})
```

## User Flow

```
1. User clicks "Sign in with Email Link"
   ↓
2. Enters email address
   ↓
3. Receives magic link email
   ↓
4. Clicks link in email
   ↓
5. Redirected to dashboard (logged in)
   ↓
6. [Optional] Can set password in settings
```

## Code Changes Needed

### forgotPasswordForm → MagicLinkForm

```typescript
'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'

export function MagicLinkForm() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/dashboard`,
      }
    })

    if (error) {
      alert(error.message)
    } else {
      setSent(true)
    }
    setLoading(false)
  }

  if (sent) {
    return <div>Check your email for the login link!</div>
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Enter your email"
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Sending...' : 'Send Magic Link'}
      </button>
    </form>
  )
}
```

### Update Sign In Page

Add magic link option alongside password:

```typescript
<div className="space-y-4">
  <button onClick={() => signInWithPassword()}>
    Sign in with Password
  </button>
  <button onClick={() => signInWithMagicLink()}>
    Sign in with Email Link
  </button>
</div>
```

## Migration Strategy

### Phase 1: Add Magic Link Option
- Keep password auth
- Add magic link as alternative
- See which users prefer

### Phase 2: Make It Primary
- Default to magic link
- Password as secondary option
- Gather feedback

### Phase 3: Simplify (Optional)
- Remove password auth entirely
- Pure magic link flow
- Cleaner codebase

## Real-World Examples

- **Slack**: Primary auth method
- **Notion**: "Continue with Email"
- **Medium**: One-tap email login
- **Linear**: Magic link for team invites

## Why This Solves Your Problem

- ❌ No more password reset debugging
- ❌ No more token consumption issues
- ❌ No more middleware conflicts
- ✅ Works out of the box with Supabase
- ✅ Better UX (proven pattern)
- ✅ Less code to maintain

---

**Implementation Time**: ~30 minutes
**User Experience**: Superior to password reset
**Maintenance**: Minimal
