/**
 * Better Auth Type Augmentation
 *
 * Extends Better Auth's default types with our custom user fields.
 * This ensures type safety across both server and client code.
 */

import type { User as BetterAuthUser } from "better-auth"

declare module "better-auth" {
  interface User extends BetterAuthUser {
    role?: string | null
    accountType?: string | null
    businessName?: string | null
    firstName?: string | null
    lastName?: string | null
  }
}

// Also export for easier imports
export {}
