# Deployment Guide for HobbyistSwiftUI Edge Functions

This guide covers deploying and managing the HobbyistSwiftUI Supabase Edge Functions in production.

## Prerequisites

1. **Supabase CLI** installed and configured
2. **Deno** runtime installed (version 1.40+)
3. **Environment variables** configured
4. **Database schema** deployed
5. **Third-party service accounts** configured

## Environment Setup

### 1. Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# npm
npm install -g supabase

# Direct download
curl -fsSL https://raw.githubusercontent.com/supabase/cli/main/install.sh | sh
```

### 2. Initialize and Link Project

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Or initialize new project
supabase init
```

### 3. Environment Variables

Create environment variables in Supabase dashboard or use CLI:

```bash
# Required variables
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
supabase secrets set SUPABASE_JWT_SECRET=your-jwt-secret

# Stripe Configuration
supabase secrets set STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
supabase secrets set STRIPE_CONNECT_WEBHOOK_SECRET=whsec_your_connect_webhook_secret

# Email Configuration
supabase secrets set SENDGRID_API_KEY=SG.your_sendgrid_api_key
supabase secrets set SENDGRID_FROM_EMAIL=notifications@hobbyist.app
supabase secrets set SENDGRID_FROM_NAME=Hobbyist

# SMS Configuration (Optional)
supabase secrets set TWILIO_ACCOUNT_SID=your_account_sid
supabase secrets set TWILIO_AUTH_TOKEN=your_auth_token
supabase secrets set TWILIO_PHONE_NUMBER=+1234567890

# Push Notifications
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key

# Commission Settings
supabase secrets set PLATFORM_COMMISSION_PERCENTAGE=15
supabase secrets set MINIMUM_PAYOUT_AMOUNT=10.00

# Environment
supabase secrets set ENVIRONMENT=production
supabase secrets set APP_VERSION=1.0.0
```

## Database Schema

### 1. Run Migrations

```bash
# Apply all pending migrations
supabase db push

# Or apply specific migration
supabase migration up --file 20240101000000_initial_schema.sql
```

### 2. Required Tables

Ensure these tables exist in your database:

- `user_profiles`
- `instructor_profiles`
- `classes`
- `categories`
- `bookings`
- `payments`
- `instructor_payouts`
- `reviews`
- `notifications`
- `user_files`
- `webhook_events`
- `email_logs`
- `sms_logs`

### 3. Row Level Security (RLS)

Enable RLS and create policies:

```sql
-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_profiles ENABLE ROW LEVEL SECURITY;
-- ... repeat for all tables

-- Create policies (example for user_profiles)
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);
```

## Edge Functions Deployment

### 1. Deploy All Functions

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy auth
supabase functions deploy classes
supabase functions deploy bookings
supabase functions deploy payments
supabase functions deploy realtime
supabase functions deploy storage
supabase functions deploy webhooks
supabase functions deploy notifications
```

### 2. Verify Deployment

```bash
# List deployed functions
supabase functions list

# Check function logs
supabase functions logs auth
supabase functions logs --follow classes
```

### 3. Test Functions

```bash
# Test auth function
curl -X POST https://your-project.supabase.co/functions/v1/auth/profile \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"

# Test classes search
curl -X GET "https://your-project.supabase.co/functions/v1/classes/search?q=yoga" \
  -H "Authorization: Bearer <token>"
```

## Storage Setup

### 1. Create Storage Buckets

```sql
-- Public buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('avatars', 'avatars', true),
  ('class-images', 'class-images', true),
  ('public-files', 'public-files', true);

-- Private buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('private-files', 'private-files', false),
  ('instructor-documents', 'instructor-documents', false);
```

### 2. Configure Storage Policies

```sql
-- Avatar upload policy
CREATE POLICY "Users can upload avatars" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Class images policy (instructors only)
CREATE POLICY "Instructors can upload class images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'class-images' 
    AND EXISTS (
      SELECT 1 FROM instructor_profiles 
      WHERE user_id = auth.uid()
    )
  );
```

## Third-Party Service Configuration

### 1. Stripe Setup

1. Create Stripe Connect application
2. Configure webhooks in Stripe Dashboard:
   - Endpoint: `https://your-project.supabase.co/functions/v1/webhooks/stripe`
   - Events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.dispute.created`
3. Configure Connect webhooks:
   - Endpoint: `https://your-project.supabase.co/functions/v1/webhooks/stripe-connect`
   - Events: `account.updated`, `account.application.authorized`

### 2. SendGrid Setup

1. Create SendGrid API key with Mail Send permissions
2. Verify sender identity
3. Configure webhook (optional):
   - Endpoint: `https://your-project.supabase.co/functions/v1/webhooks/sendgrid`
   - Events: `delivered`, `bounce`, `dropped`

### 3. Firebase Setup (Push Notifications)

1. Create Firebase project
2. Generate service account key
3. Configure FCM server key in environment variables

## Monitoring and Logging

### 1. Function Logs

```bash
# View real-time logs
supabase functions logs --follow

# View logs for specific function
supabase functions logs auth --follow

# View logs with filters
supabase functions logs --filter="level=error"
```

### 2. Database Monitoring

```bash
# Database statistics
supabase db inspect

# Active connections
supabase db sessions
```

### 3. Set Up Alerts

Configure alerts in Supabase Dashboard:
- High error rate (>5% in 5 minutes)
- Function timeout rate (>10% in 5 minutes)
- Database connection pool exhaustion
- Storage quota exceeded

## Performance Optimization

### 1. Database Optimization

```sql
-- Add indexes for common queries
CREATE INDEX idx_classes_search ON classes USING gin(to_tsvector('english', title || ' ' || description));
CREATE INDEX idx_bookings_user_status ON bookings(user_id, status);
CREATE INDEX idx_classes_instructor_status ON classes(instructor_id, status);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read);

-- Add partial indexes for performance
CREATE INDEX idx_classes_published ON classes(created_at DESC) WHERE status = 'published';
CREATE INDEX idx_bookings_confirmed ON bookings(created_at DESC) WHERE status = 'confirmed';
```

### 2. Function Optimization

- Enable function caching where appropriate
- Use database connection pooling
- Implement proper error handling and retries
- Use batch operations for bulk updates

### 3. Storage Optimization

- Enable image transformation for automatic resizing
- Set appropriate cache headers
- Use CDN for static assets
- Implement image optimization

## Security Configuration

### 1. Function Security

```bash
# Enable function authentication
supabase functions deploy --verify-jwt auth
supabase functions deploy --verify-jwt classes
# ... repeat for all functions requiring auth
```

### 2. Database Security

```sql
-- Revoke public access
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;

-- Grant specific permissions
GRANT SELECT ON user_profiles TO authenticated;
GRANT INSERT, UPDATE ON user_profiles TO authenticated;
-- ... continue for all tables
```

### 3. API Security

- Enable rate limiting
- Configure CORS properly
- Use proper webhook signature verification
- Implement request validation
- Enable audit logging

## Backup and Recovery

### 1. Database Backups

```bash
# Manual backup
supabase db dump -f backup.sql

# Restore from backup
supabase db reset --db-url postgres://... --file backup.sql
```

### 2. Function Code Backup

- Store function code in version control
- Tag releases for rollback capability
- Maintain deployment documentation

### 3. Configuration Backup

- Export environment variables
- Document third-party service configurations
- Maintain infrastructure as code

## Rollback Procedures

### 1. Function Rollback

```bash
# Deploy previous version
git checkout previous-version
supabase functions deploy

# Or deploy specific function version
supabase functions deploy auth --import-map ./previous-version/import_map.json
```

### 2. Database Rollback

```bash
# Rollback specific migration
supabase migration down --file 20240101000000_migration.sql

# Reset to specific point
supabase db reset --db-url postgres://... --file backup-before-change.sql
```

### 3. Emergency Procedures

1. **Function Failure:**
   - Check function logs
   - Redeploy last known good version
   - Update status page if customer-facing

2. **Database Issues:**
   - Check connection pool
   - Restart database if necessary
   - Apply emergency patches

3. **External Service Outages:**
   - Enable circuit breakers
   - Switch to backup services if available
   - Communicate with users

## Health Checks and Monitoring

### 1. Function Health Checks

Create health check endpoints in each function:

```typescript
if (path === '/health') {
  return createResponse({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: Deno.env.get('APP_VERSION'),
  });
}
```

### 2. External Monitoring

Set up external monitoring with services like:
- Uptime Robot
- Pingdom
- New Relic
- DataDog

### 3. Custom Monitoring

Implement custom metrics:
- Function execution time
- Error rates by function
- Database query performance
- Third-party service response times

## Scaling Considerations

### 1. Function Scaling

- Monitor function execution time
- Optimize database queries
- Implement caching strategies
- Use edge caching where appropriate

### 2. Database Scaling

- Monitor connection pool usage
- Optimize slow queries
- Consider read replicas for heavy read workloads
- Implement database sharding if needed

### 3. Storage Scaling

- Monitor storage usage
- Implement lifecycle policies
- Use CDN for static assets
- Consider moving to dedicated storage service

## Production Checklist

- [ ] All environment variables configured
- [ ] Database schema deployed with proper RLS
- [ ] All Edge Functions deployed and tested
- [ ] Storage buckets created with proper policies
- [ ] Third-party services configured (Stripe, SendGrid, etc.)
- [ ] Webhooks configured and tested
- [ ] Monitoring and alerting set up
- [ ] Backup procedures tested
- [ ] Security policies reviewed
- [ ] Performance optimizations applied
- [ ] Health checks implemented
- [ ] Rollback procedures documented
- [ ] Team trained on operational procedures

## Troubleshooting

### Common Issues

1. **Function Timeout:**
   - Check for long-running operations
   - Optimize database queries
   - Implement proper error handling

2. **Database Connection Issues:**
   - Check connection pool settings
   - Monitor concurrent connections
   - Implement connection retry logic

3. **Third-Party Service Errors:**
   - Verify API keys and configurations
   - Check service status pages
   - Implement proper error handling and retries

4. **CORS Issues:**
   - Verify CORS headers in function responses
   - Check allowed origins configuration
   - Test with different clients

### Debug Commands

```bash
# Function logs with filters
supabase functions logs --filter="level=error" --limit=100

# Database query performance
supabase db inspect --include-slow-queries

# Test function locally
supabase functions serve auth --env-file .env.local

# Validate function code
deno check supabase/functions/auth/index.ts
```

For additional support, refer to:
- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Deno Runtime Documentation](https://deno.land/manual)
- Project-specific documentation in this repository

---

*Last updated: January 2024*
*Version: 1.0.0*