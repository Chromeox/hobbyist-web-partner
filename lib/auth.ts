/**
 * Better Auth Server Configuration
 *
 * This is the main auth instance for the server-side.
 * Handles all authentication, authorization, and session management.
 *
 * Features:
 * - Email/password authentication with verification
 * - OAuth providers (Google, Apple)
 * - Session management with automatic refresh
 * - Role-based access control
 * - Organization support (studios, instructors)
 */

import { betterAuth } from "better-auth"
import { nextCookies } from "better-auth/next-js"
import { sendEmail } from "./email"

export const auth = betterAuth({
  // Database configuration (Supabase PostgreSQL)
  database: {
    provider: "postgresql",
    url: process.env.DATABASE_URL!,
  },

  // Email and password authentication
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true,
    sendVerificationEmail: async ({ user, token, url }) => {
      console.log(`Verification email for ${user.email}:`, url)

      await sendEmail({
        to: user.email,
        subject: "Verify your Hobbyist account",
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Welcome to Hobbyist!</h2>
            <p>Please verify your email address to complete your registration.</p>
            <p><a href="${url}" style="background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Verify Email</a></p>
            <p>Or copy this link: ${url}</p>
          </div>
        `
      })
    },
    sendResetPassword: async ({ user, token, url }) => {
      console.log(`Password reset for ${user.email}:`, url)

      await sendEmail({
        to: user.email,
        subject: "Reset your Hobbyist password",
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Reset Password</h2>
            <p>You requested a password reset for your Hobbyist account.</p>
            <p><a href="${url}" style="background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
            <p>If you didn't request this, please ignore this email.</p>
          </div>
        `
      })
    },
  },

  // Social OAuth providers
  socialProviders: {
    google: {
      clientId: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      redirectURI: `${process.env.BETTER_AUTH_URL}/api/auth/callback/google`,
    },
    apple: {
      clientId: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID!,
      clientSecret: process.env.APPLE_CLIENT_SECRET!,
      redirectURI: `${process.env.BETTER_AUTH_URL}/api/auth/callback/apple`,
      // For iOS native apps (uses bundle ID)
      appBundleIdentifier: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID,
    },
  },

  // Trusted origins for OAuth
  trustedOrigins: [
    process.env.BETTER_AUTH_URL!,
    "https://appleid.apple.com",
  ],

  // Session management
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24,      // Refresh after 1 day
    freshAge: 60 * 60 * 24,       // Fresh session = 1 day
    cookieCache: {
      enabled: true,              // Enable cookie caching for performance
      maxAge: 5 * 60,             // 5 minutes cache
    },
  },

  // User fields customization
  user: {
    // Add custom fields to user table
    additionalFields: {
      role: {
        type: "string",
        required: false,
        defaultValue: "student",
        // Possible values: "student", "instructor", "admin", "studio"
      },
      businessName: {
        type: "string",
        required: false,
      },
      accountType: {
        type: "string",
        required: false,
        defaultValue: "student",
        // Possible values: "student", "instructor", "studio"
      },
      firstName: {
        type: "string",
        required: false,
      },
      lastName: {
        type: "string",
        required: false,
      },
    },
  },

  // Advanced configuration
  advanced: {
    // Use Next.js cookies adapter for better session handling
    useSecureCookies: process.env.NODE_ENV === "production",
    crossSubDomainCookies: {
      enabled: false,
    },
  },
})

// Export types for TypeScript
// Full session object with both session data and user
export type Session = typeof auth.$Infer.Session

// Individual session data and user types
export type SessionData = typeof auth.$Infer.Session.session
export type User = typeof auth.$Infer.Session.user
