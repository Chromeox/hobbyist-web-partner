import { NextRequest, NextResponse } from 'next/server';
import { CalendlyIntegration } from '@/lib/integrations/calendly-integration';
import { CalendarIntegrationManager } from '@/lib/integrations/calendar-manager';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');

    // Handle OAuth errors
    if (error) {
      console.error('Calendly OAuth error:', error);
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=calendly_auth_failed', request.url)
      );
    }

    // Validate authorization code
    if (!code) {
      console.error('No authorization code received from Calendly');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=missing_auth_code', request.url)
      );
    }

    // Validate state parameter (optional but recommended for security)
    if (state !== 'calendly_integration') {
      console.error('Invalid state parameter from Calendly OAuth');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=invalid_state', request.url)
      );
    }

    console.log('Exchanging Calendly authorization code for tokens...');

    // Exchange authorization code for tokens
    const tokens = await CalendlyIntegration.exchangeCodeForTokens(code);

    if (!tokens.access_token) {
      throw new Error('No access token received from Calendly');
    }

    // Get user information to identify the account
    const tempIntegration = {
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token || null,
      provider: 'calendly' as const,
      settings: {}
    };

    const calendlyIntegration = new CalendlyIntegration(tempIntegration as any, {
      timezone: 'America/Vancouver' // Default timezone
    });

    const userInfo = await calendlyIntegration.getUserInfo();

    // Store the integration in the database
    const integrationManager = new CalendarIntegrationManager();

    // TODO: Get actual studio ID from user session
    const studioId = 'temp-studio-id'; // This will be replaced with actual session management

    const integration = await integrationManager.createIntegration(
      studioId,
      'calendly',
      tokens.access_token,
      tokens.refresh_token,
      {
        organization_uri: userInfo.organization.uri,
        timezone: 'America/Vancouver'
      }
    );

    console.log('Calendly integration created successfully:', integration.id);

    // Redirect back to dashboard with success
    return NextResponse.redirect(
      new URL('/dashboard/intelligence?success=calendly_connected&integration_id=' + integration.id, request.url)
    );

  } catch (error) {
    console.error('Calendly OAuth callback error:', error);

    // Redirect with error message
    return NextResponse.redirect(
      new URL('/dashboard/intelligence?error=calendly_connection_failed', request.url)
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