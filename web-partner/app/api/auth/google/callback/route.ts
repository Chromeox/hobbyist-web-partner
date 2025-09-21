import { NextRequest, NextResponse } from 'next/server';
import { GoogleCalendarIntegration } from '@/lib/integrations/google-calendar';

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
      // For now, simulate successful token exchange (replace with actual Google API call)
      // TODO: Implement actual token exchange with Google OAuth API
      const simulatedTokens = {
        access_token: 'ya29.google_access_token_simulation',
        refresh_token: 'refresh_token_simulation',
        scope: 'https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/calendar.events',
        token_type: 'Bearer',
        expires_in: 3600
      };

      console.log('Google Calendar integration successful (simulated)');

      // Simulate integration data (replace with actual Google Calendar API calls)
      const integrationData = {
        provider: 'google',
        status: 'connected',
        account_name: 'Google Calendar',
        calendar_name: 'Primary Calendar',
        connected_at: new Date().toISOString(),
        tokens: simulatedTokens
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