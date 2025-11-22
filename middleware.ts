/**
 * Admin Portal Middleware
 *
 * Security layer for /internal/admin routes
 * - Verifies user authentication
 * - Checks for admin role
 * - Redirects unauthorized users to 404 (hides admin portal existence)
 * - Adds security headers
 */

import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

export async function middleware(request: NextRequest) {
  try {
    // Get Better Auth session
    const session = await auth.api.getSession({
      headers: request.headers,
    });

    // Check if user is authenticated
    if (!session?.user) {
      // Redirect to 404 instead of login to hide admin portal existence
      return NextResponse.rewrite(new URL('/404', request.url));
    }

    // Check if user has admin role
    if (session.user.role !== 'admin') {
      // Redirect to 404 for non-admins (not 403/unauthorized)
      return NextResponse.rewrite(new URL('/404', request.url));
    }

    // User is authenticated and is admin - allow access
    const response = NextResponse.next();

    // Add security headers
    response.headers.set('X-Robots-Tag', 'noindex, nofollow');
    response.headers.set('X-Frame-Options', 'DENY');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('Referrer-Policy', 'no-referrer');

    return response;

  } catch (error) {
    console.error('[Admin Middleware] Error:', error);
    // On error, redirect to 404 to be safe
    return NextResponse.rewrite(new URL('/404', request.url));
  }
}

export const config = {
  matcher: '/internal/admin/:path*',
};
