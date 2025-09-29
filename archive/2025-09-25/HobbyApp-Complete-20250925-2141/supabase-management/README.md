# Supabase Management Setup Guide

This directory contains scripts and configuration for managing your Supabase projects.

## 🚀 Quick Setup

### 1. Get Your Supabase Credentials

You'll need to get these from your Supabase Dashboard:

1. **Go to your Supabase Dashboard**: https://app.supabase.com
2. **Select your project**
3. **Navigate to Settings → API**
4. **Copy these values**:
   - `Project URL` (looks like: https://abcdefghijklmnop.supabase.co)
   - `anon public` key (safe for client-side)
   - `service_role` key (keep this secret!)
   
5. **Navigate to Settings → General**
6. **Copy the Reference ID** (this is your Project ID)

7. **For CLI access (optional but recommended)**:
   - Go to https://app.supabase.com/account/tokens
   - Click "Generate new token"
   - Name it something like "Claude Management"
   - Copy the token (you won't see it again!)

### 2. Configure Your Environment

```bash
# Copy the template
cp config/.env.template config/.env.local

# Edit with your favorite editor
nano config/.env.local
# or
code config/.env.local
```

Fill in these values:
```env
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJ...your-anon-key...
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-key...
SUPABASE_PROJECT_ID=abcdefghijklmnop

# Optional but recommended for full management
SUPABASE_ACCESS_TOKEN=sbp_...your-access-token...
```

### 3. Verify Setup

```bash
cd scripts
./supabase-setup.sh
```

This will verify your configuration and test the connection.

### 4. Test Safe Access

```bash
./claude-safe-access.sh test-connection
```

## 📋 Available Commands

### For Claude (Safe Operations)

These commands are safe for Claude to run:

```bash
# Information commands
./claude-safe-access.sh list-tables
./claude-safe-access.sh show-schema <table_name>
./claude-safe-access.sh show-migrations
./claude-safe-access.sh show-functions
./claude-safe-access.sh get-project-info

# Development commands (when in dev mode)
./claude-safe-access.sh apply-migration <file>
./claude-safe-access.sh deploy-function <name>
./claude-safe-access.sh generate-types

# Backup commands
./claude-safe-access.sh backup-schema
./claude-safe-access.sh backup-data <table_name>
```

### For You (Full Management)

```bash
# Project management
./supabase-manage.sh status
./supabase-manage.sh migrate
./supabase-manage.sh seed
./supabase-manage.sh backup

# Edge Functions
./supabase-manage.sh functions list
./supabase-manage.sh functions deploy <name>
./supabase-manage.sh functions deploy-all

# Development
./supabase-manage.sh types
./supabase-manage.sh local start
./supabase-manage.sh local stop
```

## 🔒 Security Notes

- **NEVER** commit `.env.local` to git
- **NEVER** share your `service_role` key publicly
- The `anon` key is safe for client-side code
- The `access_token` gives full project access - keep it secure!

## 📁 Directory Structure

```
supabase-management/
├── config/
│   ├── .env.template    # Template for environment variables
│   └── .env.local       # Your actual credentials (git ignored)
├── scripts/
│   ├── supabase-setup.sh      # Initial setup verification
│   ├── claude-safe-access.sh  # Safe operations for Claude
│   └── supabase-manage.sh     # Full management commands
├── backups/             # Automated backup storage
└── README.md           # This file
```

## 🤖 For Claude

Once setup is complete, Claude can help you by running the safe access commands. Claude will never have access to destructive operations or sensitive data modifications unless explicitly in development mode.

## ❓ Troubleshooting

### "Supabase CLI not installed"
```bash
brew install supabase/tap/supabase
```

### "Connection failed"
- Check your SUPABASE_URL is correct
- Verify your API keys are copied correctly
- Ensure your project is not paused in Supabase Dashboard

### "Access token required"
Some operations need the Supabase access token. Get one from:
https://app.supabase.com/account/tokens