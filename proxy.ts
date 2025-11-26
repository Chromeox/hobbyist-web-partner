/**
 * Proxy/Middleware for Next.js 16
 * Using Clerk for authentication
 *
 * In Next.js 16, proxy.ts replaces middleware.ts
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Define public routes that don't require authentication
const isPublicRoute = createRouteMatcher([
  '/',
  '/auth/signin',
  '/auth/signup',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/auth/check-email',
  '/auth/sso-callback',
  '/api/auth/(.*)',
  '/api/webhooks/(.*)',
  '/api/stripe/(.*)',
  '/api/health',
  '/legal/(.*)',
  '/privacy',
  '/offline',
]);

// Define admin routes
const isAdminRoute = createRouteMatcher(['/internal/admin(.*)']);

// Export the Clerk middleware as proxy (Next.js 16 convention)
export const proxy = clerkMiddleware(async (auth, request) => {
  const { userId, sessionClaims } = await auth();

  // Allow public routes without auth
  if (isPublicRoute(request)) {
    return NextResponse.next();
  }

  // Protect admin routes - require admin role
  if (isAdminRoute(request)) {
    if (!userId) {
      // No user - rewrite to 404 to hide admin existence
      return NextResponse.rewrite(new URL('/404', request.url));
    }

    // Check for admin role in session claims
    const userRole = sessionClaims?.metadata?.role as string | undefined;
    if (userRole !== 'admin') {
      // Not admin - rewrite to 404
      return NextResponse.rewrite(new URL('/404', request.url));
    }
  }

  // For protected routes, redirect to sign-in if not authenticated
  if (!userId) {
    const signInUrl = new URL('/auth/signin', request.url);
    signInUrl.searchParams.set('returnUrl', request.nextUrl.pathname);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
});

// Configure which routes the proxy should run on
export const config = {
  matcher: [
    // Skip Next.js internals and all static files, unless found in search params
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};
