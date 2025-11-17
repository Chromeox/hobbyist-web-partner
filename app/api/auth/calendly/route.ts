import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';


export async function GET(request: NextRequest) {
  try {
    const clientId = process.env.CALENDLY_CLIENT_ID;
    const redirectUri = process.env.CALENDLY_REDIRECT_URI;

    if (!clientId || !redirectUri) {
      console.error('Missing Calendly OAuth configuration');
      return NextResponse.redirect(
        new URL('/dashboard/intelligence?error=calendly_config_missing', request.url)
      );
    }

    // Generate secure state parameter
    const state = 'calendly_integration';

    // Calendly OAuth2 URL
    const authUrl = new URL('https://auth.calendly.com/oauth/authorize');
    authUrl.searchParams.set('client_id', clientId);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('redirect_uri', redirectUri);
    authUrl.searchParams.set('state', state);
    authUrl.searchParams.set('scope', 'read write');

    console.log('Redirecting to Calendly OAuth:', authUrl.toString());

    // Redirect to Calendly OAuth
    return NextResponse.redirect(authUrl.toString());

  } catch (error) {
    console.error('Calendly OAuth initiation error:', error);

    return NextResponse.redirect(
      new URL('/dashboard/intelligence?error=calendly_auth_init_failed', request.url)
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