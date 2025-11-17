import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';


export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');

    // Handle OAuth errors
    if (error) {
      console.error('Square OAuth error:', error);
      const errorMessage = encodeURIComponent(`Square OAuth error: ${error}`);
      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?error=square_auth_failed&message=${errorMessage}`, request.url)
      );
    }

    // Validate authorization code (expires after 5 minutes per Square docs)
    if (!code) {
      console.error('No authorization code received from Square');
      const errorMessage = encodeURIComponent('No authorization code received from Square. The authorization may have expired (codes expire after 5 minutes).');
      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?error=missing_auth_code&message=${errorMessage}`, request.url)
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

    // Exchange authorization code for access token using Square API
    try {
      const tokenExchangePayload = {
        client_id: process.env.SQUARE_APPLICATION_ID,
        client_secret: process.env.SQUARE_APPLICATION_SECRET,
        code: code,
        grant_type: 'authorization_code'
      };

      const squareApiUrl = process.env.SQUARE_ENVIRONMENT === 'production'
        ? 'https://connect.squareup.com'
        : 'https://connect.squareupsandbox.com';

      const tokenResponse = await fetch(`${squareApiUrl}/oauth2/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Square-Version': '2023-10-18'
        },
        body: JSON.stringify(tokenExchangePayload)
      });

      if (!tokenResponse.ok) {
        const errorData = await tokenResponse.text();
        console.error('Square API token exchange failed:', errorData);
        throw new Error(`Square API error: ${tokenResponse.status} - ${errorData}`);
      }

      const tokenData = await tokenResponse.json();
      console.log('Square token exchange successful:', {
        expires_at: tokenData.expires_at,
        merchant_id: tokenData.merchant_id
      });

      // Get merchant information
      const merchantResponse = await fetch(`${squareApiUrl}/v2/merchants/${tokenData.merchant_id}`, {
        headers: {
          'Authorization': `Bearer ${tokenData.access_token}`,
          'Square-Version': '2023-10-18'
        }
      });

      type SquareMerchantProfile = { business_name?: string; country?: string };
      let merchantInfo: SquareMerchantProfile = {};
      if (merchantResponse.ok) {
        const merchantData = await merchantResponse.json();
        merchantInfo = merchantData.merchant;
      }

      // Store integration data (in production, save to database)
      const integrationData = {
        provider: 'square',
        status: 'connected',
        merchant_name: merchantInfo.business_name ?? 'Square Merchant',
        location_name: merchantInfo.country ?? 'Unknown',
        connected_at: new Date().toISOString(),
        merchant_id: tokenData.merchant_id,
        expires_at: tokenData.expires_at
      };

      console.log('Square integration successful');

      // Redirect back to dashboard with success and integration data
      const successParams = new URLSearchParams({
        success: 'square_connected',
        integration_id: 'temp-integration-id',
        merchant_name: integrationData.merchant_name,
        location_name: integrationData.location_name
      });

      return NextResponse.redirect(
        new URL(`/dashboard/intelligence?${successParams.toString()}`, request.url)
      );

    } catch (tokenError) {
      console.error('Token exchange error:', tokenError);
      throw new Error('Failed to exchange authorization code for tokens');
    }

  } catch (error) {
    console.error('Square OAuth callback error:', error);

    // Redirect with error message
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return NextResponse.redirect(
      new URL(`/dashboard/intelligence?error=square_connection_failed&message=${encodeURIComponent(errorMessage)}`, request.url)
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
