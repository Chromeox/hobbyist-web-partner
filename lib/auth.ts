/**
 * Server-side Auth Helper (Clerk)
 *
 * Provides server-side authentication utilities for API routes.
 * Replaces Better Auth server-side functions with Clerk equivalents.
 */

import { auth as clerkAuth, currentUser } from '@clerk/nextjs/server';

/**
 * User type for server-side use
 */
export interface ServerUser {
  id: string;
  email: string;
  firstName?: string | null;
  lastName?: string | null;
  role?: string;
  imageUrl?: string | null;
}

/**
 * Session type for server-side use
 */
export interface ServerSession {
  user: ServerUser;
  userId: string;
  sessionId: string;
}

/**
 * Get the current session from Clerk
 * Use this in API routes to verify authentication
 *
 * @example
 * const session = await getServerSession();
 * if (!session?.user) {
 *   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
 * }
 */
export async function getServerSession(): Promise<ServerSession | null> {
  try {
    const { userId, sessionId } = await clerkAuth();

    if (!userId || !sessionId) {
      return null;
    }

    // Get full user details
    const user = await currentUser();

    if (!user) {
      return null;
    }

    return {
      user: {
        id: user.id,
        email: user.emailAddresses[0]?.emailAddress || '',
        firstName: user.firstName,
        lastName: user.lastName,
        role: (user.unsafeMetadata?.role as string) || 'student',
        imageUrl: user.imageUrl,
      },
      userId,
      sessionId,
    };
  } catch (error) {
    console.error('[Auth] Error getting server session:', error);
    return null;
  }
}

/**
 * Compatibility export for existing code that imports { auth } from '@/lib/auth'
 * Provides a similar API structure to Better Auth
 */
export const auth = {
  api: {
    /**
     * Get session - compatibility method for Better Auth migration
     * @deprecated Use getServerSession() directly instead
     */
    getSession: async (_options?: { headers?: Headers }): Promise<ServerSession | null> => {
      return getServerSession();
    },
  },
};

/**
 * Check if user has admin role
 */
export function isAdminUser(user: ServerUser | null | undefined): boolean {
  return user?.role === 'admin';
}

/**
 * Get user ID from auth (simpler version when you just need the ID)
 */
export async function getAuthUserId(): Promise<string | null> {
  const { userId } = await clerkAuth();
  return userId;
}

/**
 * Require authentication - throws if not authenticated
 * Use in API routes that require auth
 *
 * @example
 * const session = await requireAuth();
 * // If we get here, user is authenticated
 */
export async function requireAuth(): Promise<ServerSession> {
  const session = await getServerSession();

  if (!session) {
    throw new Error('Unauthorized');
  }

  return session;
}

/**
 * Require admin role - throws if not admin
 *
 * @example
 * const session = await requireAdmin();
 * // If we get here, user is authenticated and is admin
 */
export async function requireAdmin(): Promise<ServerSession> {
  const session = await requireAuth();

  if (!isAdminUser(session.user)) {
    throw new Error('Forbidden - Admin access required');
  }

  return session;
}
