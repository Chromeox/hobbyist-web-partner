/**
 * Better Auth API Route Handler
 *
 * This catch-all route handles all authentication requests:
 * - /api/auth/signin
 * - /api/auth/signup
 * - /api/auth/signout
 * - /api/auth/callback/*
 * - /api/auth/session
 * - /api/auth/verify-email
 * - /api/auth/reset-password
 * - And more...
 *
 * All authentication logic is handled by Better Auth.
 */

import { auth } from "@/lib/auth"
import { toNextJsHandler } from "better-auth/next-js"

// Export HTTP methods handled by Better Auth
export const { POST, GET } = toNextJsHandler(auth)

/**
 * Route configuration
 * - Force dynamic rendering (no static generation)
 * - This is required for authentication routes
 */
export const dynamic = "force-dynamic"
