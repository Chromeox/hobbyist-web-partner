import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const applicationId = process.env.SQUARE_APPLICATION_ID;
    const environment = process.env.SQUARE_ENVIRONMENT || 'sandbox';

    if (!applicationId) {
      console.error('Missing Square OAuth configuration');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=square_config_missing', request.url)
      );
    }

    // Generate secure state parameter
    const state = 'square_integration';

    // Square OAuth2 URL (different for sandbox vs production)
    const baseUrl = environment === 'production'
      ? 'https://connect.squareup.com'
      : 'https://connect.squareupsandbox.com';

    // Construct redirect URI dynamically
    const redirectUri = new URL('/api/auth/square/callback', request.url).toString();

    const authUrl = new URL(`${baseUrl}/oauth2/authorize`);
    authUrl.searchParams.set('client_id', applicationId);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('redirect_uri', redirectUri);
    authUrl.searchParams.set('scope', 'APPOINTMENTS_READ APPOINTMENTS_WRITE CUSTOMERS_READ CUSTOMERS_WRITE PAYMENTS_READ');
    authUrl.searchParams.set('state', state);

    console.log('Redirecting to Square OAuth:', authUrl.toString());

    // Redirect to Square OAuth
    return NextResponse.redirect(authUrl.toString());

  } catch (error) {
    console.error('Square OAuth initiation error:', error);

    return NextResponse.redirect(
      new URL('/dashboard/intelligence?error=square_auth_init_failed', request.url)
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