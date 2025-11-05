# Calendar Integration Setup Guide

## 🔒 Manual Database Schema Deployment Required

The calendar integration system is now fully implemented but requires manual database schema deployment to function properly.

### Step 1: Deploy Calendar Schema to Supabase

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp
   - Navigate to: SQL Editor

2. **Execute Schema Migration**
   - Copy the contents of: `/supabase/migrations/09_calendar_integration_schema.sql`
   - Paste into SQL Editor
   - Click "Run" to execute

3. **Verify Deployment**
   - Check that these tables are created:
     - `calendar_integrations`
     - `imported_events`
     - `workshop_materials`
     - `studio_inventory`
     - `workshop_templates`
     - `studio_expenses`

### Step 2: Configure OAuth Applications

#### Calendly OAuth Setup
1. Go to: https://calendly.com/integrations/api_webhooks
2. Create new OAuth application
3. Set redirect URI: `http://localhost:3002/api/auth/calendly/callback`
4. Update `.env.local`:
   ```
   CALENDLY_CLIENT_ID=your_actual_client_id
   CALENDLY_CLIENT_SECRET=your_actual_client_secret
   ```

#### Square OAuth Setup
1. Go to: https://developer.squareup.com/apps
2. Create new application (use Sandbox for development)
3. Configure OAuth redirect URI: `http://localhost:3002/api/auth/square/callback`
4. Update `.env.local`:
   ```
   SQUARE_APPLICATION_ID=your_actual_app_id
   SQUARE_APPLICATION_SECRET=your_actual_app_secret
   SQUARE_ENVIRONMENT=sandbox
   ```

## 🚀 Integration Features

### ✅ Completed Components

1. **Database Schema** (`09_calendar_integration_schema.sql`)
   - Complete calendar integration tables with RLS policies
   - Support for multiple providers (Google, Calendly, Square, etc.)
   - Workshop templates and material tracking
   - Studio inventory and expense management

2. **Integration Classes**
   - `CalendlyIntegration.ts` - Full Calendly API v2 integration
   - `SquareIntegration.ts` - Complete Square Bookings API integration
   - `CalendarIntegrationManager.ts` - Unified provider management

3. **OAuth Flow**
   - Initiation routes: `/api/auth/calendly` and `/api/auth/square`
   - Callback handlers: `/api/auth/calendly/callback` and `/api/auth/square/callback`
   - Secure state parameter validation
   - Token storage and refresh handling

4. **UI Integration**
   - Updated Calendar Setup UI with real OAuth buttons
   - Provider selection in onboarding flow
   - Status indicators and error handling

### 🔄 OAuth Workflow

1. **User Clicks Connect**
   - User selects Calendly or Square from setup UI
   - Redirected to `/api/auth/[provider]`

2. **OAuth Initiation**
   - System generates secure state parameter
   - Redirects to provider's OAuth authorization URL
   - User authorizes application

3. **Callback Processing**
   - Provider redirects back to callback route
   - System exchanges authorization code for tokens
   - Integration stored in database with encrypted tokens

4. **Data Import**
   - System fetches events/bookings from provider API
   - Intelligent workshop detection and categorization
   - Data stored in `imported_events` table for review

## 🧪 Testing the Integration

### Prerequisites
1. Schema deployed to Supabase
2. OAuth applications configured
3. Environment variables updated

### Test Workflow
1. Start development server: `npm run dev`
2. Navigate to onboarding flow
3. Select "Import My Calendar"
4. Choose Calendly or Square provider
5. Complete OAuth authorization
6. Verify integration appears in dashboard

### Expected Behavior
- Successful OAuth redirect to provider
- Authorization completion redirects back to dashboard
- Integration visible in Studio Intelligence
- Events/bookings imported and categorized

## 🎯 Integration Capabilities

### Calendly Features
- Import scheduled events and event types
- Webhook support for real-time updates
- Invitee information and booking details
- Automatic workshop categorization

### Square Features
- Import bookings and appointments
- Service catalog integration
- Team member and location mapping
- Customer information synchronization

### Intelligence Features
- Workshop performance analytics
- Peak time identification
- Revenue optimization suggestions
- Material cost tracking
- Instructor scheduling insights

## 🔐 Security Features

- **Encrypted Token Storage**: Access/refresh tokens encrypted in database
- **RLS Policies**: Row-level security for multi-tenant access
- **State Parameter Validation**: CSRF protection in OAuth flow
- **Scope Limiting**: Minimal required permissions requested

## 📊 Next Steps

1. **Deploy Schema**: Complete manual Supabase deployment
2. **Configure OAuth**: Set up actual Calendly and Square applications
3. **Test Integration**: Verify end-to-end workflow
4. **Monitor Performance**: Track import success rates and errors
5. **Expand Providers**: Add Google Calendar and other integrations

---

*Integration Status: Ready for deployment - Manual schema deployment required*