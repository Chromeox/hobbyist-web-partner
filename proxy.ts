import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import { auth } from './lib/auth';

export async function proxy(request: NextRequest) {
  // ===== ADMIN ROUTE PROTECTION =====
  // Protect /internal/admin routes - require authentication and admin role
  if (request.nextUrl.pathname.startsWith('/internal/admin')) {
    try {
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

      // User is authenticated and is admin - continue with Supabase proxy below
    } catch (error) {
      console.error('[Proxy] Admin auth error:', error);
      // On error, redirect to 404 to be safe
      return NextResponse.rewrite(new URL('/404', request.url));
    }
  }
  // ===== END ADMIN ROUTE PROTECTION =====
  // Log requests to auth routes for debugging
  if (request.nextUrl.pathname.startsWith('/auth/')) {
    console.log('[Proxy] Auth route:', {
      path: request.nextUrl.pathname,
      search: request.nextUrl.search,
      fullUrl: request.nextUrl.href
    });
  }

  // CRITICAL: Skip proxy processing for auth callback with token_hash
  // to prevent consuming one-time tokens before the callback route processes them
  const hasTokenHash = request.nextUrl.searchParams.has('token_hash');
  const isAuthCallback = request.nextUrl.pathname === '/auth/callback';

  if (isAuthCallback && hasTokenHash) {
    console.log('[Proxy] Skipping session refresh for password reset callback');
    return NextResponse.next({
      request: {
        headers: request.headers,
      },
    });
  }

  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value,
            ...options,
          });
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          });
          response.cookies.set({
            name,
            value,
            ...options,
          });
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          });
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          });
          response.cookies.set({
            name,
            value: '',
            ...options,
          });
        },
      },
    }
  );

  // Refresh session if expired - this is important for keeping user logged in
  await supabase.auth.getUser();

  return response;
}

// Apply proxy only to dashboard and auth routes
// Exclude static assets and API routes
export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder files
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|css|js)$).*)',
  ],
};