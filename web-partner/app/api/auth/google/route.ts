import { NextRequest, NextResponse } from 'next/server';
import { GoogleCalendarIntegration } from '@/lib/integrations/google-calendar';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type'); // 'calendar' or 'auth'

    // Check if this is for calendar integration specifically
    if (type === 'calendar') {
      // Generate Google Calendar OAuth URL with calendar scopes
      const authUrl = GoogleCalendarIntegration.getAuthUrl();

      console.log('Google Calendar OAuth Configuration:');
      console.log('- Redirect URI:', process.env.GOOGLE_REDIRECT_URI);
      console.log('- Calendar Auth URL:', authUrl);

      return NextResponse.redirect(authUrl);
    }

    // Default: regular Google sign-in (handled by Supabase)
    // This will redirect to Google for authentication
    const redirectUri = new URL('/auth/callback', request.url).toString();

    // For regular Google sign-in, we let Supabase handle it
    // The frontend should call supabase.auth.signInWithOAuth('google')
    return NextResponse.json({
      message: 'Use frontend OAuth flow for Google sign-in',
      redirectUri
    });

  } catch (error) {
    console.error('Google OAuth initiation error:', error);

    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.redirect(
      new URL(`/dashboard/intelligence?error=google_auth_init_failed&message=${encodeURIComponent(errorMessage)}`, request.url)
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