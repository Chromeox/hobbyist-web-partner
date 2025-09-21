import { NextRequest, NextResponse } from 'next/server';

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

    console.log('Square OAuth callback successful - authorization code received:', code.substring(0, 10) + '...');

    // For now, simulate successful token exchange
    // TODO: Implement actual token exchange with Square API
    try {
      // Simulate token exchange (replace with actual Square API call)
      const simulatedTokens = {
        access_token: 'EAAA14hlI0D5c0D-II1Ua2gUSHq7S5Gv4QYicD1Z1qeK28j8li5RR2siB4k9mLi0',
        refresh_token: 'EQAA1zYQFoTvbio7gXaFRhwat_2IukNFivpmcnShWCt9QNgZ0aR8fDJNse0J25bB',
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
      };

      // Store integration data in localStorage (temporary solution)
      const integrationData = {
        provider: 'square',
        status: 'connected',
        merchant_name: 'Hobbyist Partner Portal',
        location_name: 'Canada',
        connected_at: new Date().toISOString(),
        tokens: simulatedTokens
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