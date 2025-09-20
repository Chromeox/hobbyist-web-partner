import { NextRequest, NextResponse } from 'next/server';
import { SquareIntegration } from '@/lib/integrations/square-integration';
import { CalendarIntegrationManager } from '@/lib/integrations/calendar-manager';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');

    // Handle OAuth errors
    if (error) {
      console.error('Square OAuth error:', error);
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=square_auth_failed', request.url)
      );
    }

    // Validate authorization code
    if (!code) {
      console.error('No authorization code received from Square');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=missing_auth_code', request.url)
      );
    }

    // Validate state parameter (optional but recommended for security)
    if (state !== 'square_integration') {
      console.error('Invalid state parameter from Square OAuth');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=invalid_state', request.url)
      );
    }

    console.log('Exchanging Square authorization code for tokens...');

    // Exchange authorization code for tokens
    const tokens = await SquareIntegration.exchangeCodeForTokens(code);

    if (!tokens.access_token) {
      throw new Error('No access token received from Square');
    }

    // Get merchant information to identify the account
    const tempIntegration = {
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token || null,
      provider: 'square' as const,
      settings: {}
    };

    const squareIntegration = new SquareIntegration(tempIntegration as any, {
      location_id: '', // Will be set after getting merchant info
      sync_services: true,
      sync_team_members: true
    });

    const merchantInfo = await squareIntegration.getMerchantInfo();

    // Use the first location as default (studios typically have one location)
    const defaultLocation = merchantInfo.locations[0];

    if (!defaultLocation) {
      throw new Error('No locations found for Square merchant');
    }

    // Store the integration in the database
    const integrationManager = new CalendarIntegrationManager();

    // TODO: Get actual studio ID from user session
    const studioId = 'temp-studio-id'; // This will be replaced with actual session management

    const integration = await integrationManager.createIntegration(
      studioId,
      'square',
      tokens.access_token,
      tokens.refresh_token,
      {
        location_id: defaultLocation.id,
        merchant_id: merchantInfo.merchant.id,
        sync_services: true,
        sync_team_members: true
      }
    );

    console.log('Square integration created successfully:', integration.id);

    // Redirect back to dashboard with success
    return NextResponse.redirect(
      new URL('/dashboard/intelligence?success=square_connected&integration_id=' + integration.id, request.url)
    );

  } catch (error) {
    console.error('Square OAuth callback error:', error);

    // Redirect with error message
    return NextResponse.redirect(
      new URL('/dashboard/intelligence?error=square_connection_failed', request.url)
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