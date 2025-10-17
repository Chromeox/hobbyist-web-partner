import { NextRequest, NextResponse } from 'next/server';
import { GoogleCalendarIntegration } from '@/lib/integrations/google-calendar';
import type { CalendarIntegration, GoogleCalendarSettings } from '@/types/calendar-integration';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');

    // Handle OAuth errors
    if (error) {
      console.error('Google OAuth error:', error);
      const errorMessage = encodeURIComponent(`Google OAuth error: ${error}`);
      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?error=google_auth_failed&message=${errorMessage}`, request.url)
      );
    }

    // Validate authorization code
    if (!code) {
      console.error('No authorization code received from Google');
      const errorMessage = encodeURIComponent('No authorization code received from Google');
      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?error=missing_auth_code&message=${errorMessage}`, request.url)
      );
    }

    console.log('Google OAuth callback successful - authorization code received:', code.substring(0, 10) + '...');

    try {
      // Exchange authorization code for access tokens using Google OAuth API
      console.log('Exchanging Google authorization code for tokens...');

      const tokens = await GoogleCalendarIntegration.exchangeCodeForTokens(code);

      const nowIso = new Date().toISOString();
      const defaultGoogleSettings: GoogleCalendarSettings = {
        calendar_id: 'primary',
        timezone: 'America/Vancouver',
        default_reminder_minutes: 60,
        sync_attendees: true
      };

      // Create integration instance to test connection
      const tempIntegration: CalendarIntegration = {
        id: 'temp',
        studio_id: 'temp-studio',
        provider: 'google',
        provider_account_id: undefined,
        sync_enabled: true,
        sync_direction: 'bidirectional',
        sync_status: 'active',
        last_sync_at: undefined,
        error_message: undefined,
        access_token: tokens.access_token ?? null,
        refresh_token: tokens.refresh_token ?? null,
        expires_at: tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : null,
        token_type: tokens.token_type ?? null,
        scope: typeof tokens.scope === 'string' ? tokens.scope : null,
        merchant_id: undefined,
        location_id: undefined,
        country: undefined,
        settings: defaultGoogleSettings,
        metadata: {},
        created_at: nowIso,
        updated_at: nowIso
      };

      const googleCalendar = new GoogleCalendarIntegration(tempIntegration, defaultGoogleSettings);

      // Test the connection to get account info
      const connectionTest = await googleCalendar.testConnection();

      if (!connectionTest) {
        throw new Error('Failed to connect to Google Calendar');
      }

      console.log('Google Calendar integration successful');

      // Store integration data (in production, save to database)
      const integrationData = {
        provider: 'google',
        status: 'connected',
        account_name: 'Google Calendar',
        calendar_name: 'Primary Calendar',
        connected_at: new Date().toISOString(),
        tokens: {
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          expires_at: tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : null
        }
      };

      // Redirect back to dashboard with success and integration data
      const successParams = new URLSearchParams({
        success: 'google_connected',
        integration_id: 'google-calendar-' + Date.now(),
        merchant_name: integrationData.account_name,
        location_name: integrationData.calendar_name
      });

      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?${successParams.toString()}`, request.url)
      );

    } catch (tokenError) {
      console.error('Google token exchange error:', tokenError);
      throw new Error('Failed to exchange authorization code for tokens');
    }

  } catch (error) {
    console.error('Google OAuth callback error:', error);

    // Redirect with error message
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return NextResponse.redirect(
      new URL(`/dashboard/intelligence?error=google_connection_failed&message=${encodeURIComponent(errorMessage)}`, request.url)
    );
  }
}

// Handle preflight OPTIONS requests
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
