/**
 * Rate Limiting Utility
 * Simple in-memory rate limiter to prevent abuse
 *
 * Usage:
 *   const limiter = new RateLimiter({ maxAttempts: 3, windowMs: 15 * 60 * 1000 })
 *   const result = await limiter.check('user-identifier')
 *   if (!result.allowed) {
 *     // Show error with result.retryAfter seconds
 *   }
 */

interface RateLimitConfig {
  maxAttempts: number
  windowMs: number
  blockDurationMs?: number
}

interface RateLimitEntry {
  count: number
  firstAttemptAt: number
  blockedUntil?: number
}

export class RateLimiter {
  private attempts = new Map<string, RateLimitEntry>()
  private config: RateLimitConfig

  constructor(config: RateLimitConfig) {
    this.config = config

    // Cleanup old entries every 5 minutes
    setInterval(() => this.cleanup(), 5 * 60 * 1000)
  }

  /**
   * Check if an identifier is allowed to proceed
   */
  async check(identifier: string): Promise<{
    allowed: boolean
    remainingAttempts?: number
    retryAfter?: number
  }> {
    const now = Date.now()
    const entry = this.attempts.get(identifier)

    // No previous attempts - allow and track
    if (!entry) {
      this.attempts.set(identifier, {
        count: 1,
        firstAttemptAt: now
      })
      return {
        allowed: true,
        remainingAttempts: this.config.maxAttempts - 1
      }
    }

    // Check if currently blocked
    if (entry.blockedUntil && now < entry.blockedUntil) {
      return {
        allowed: false,
        retryAfter: Math.ceil((entry.blockedUntil - now) / 1000)
      }
    }

    // Check if window has expired - reset counter
    if (now - entry.firstAttemptAt > this.config.windowMs) {
      this.attempts.set(identifier, {
        count: 1,
        firstAttemptAt: now
      })
      return {
        allowed: true,
        remainingAttempts: this.config.maxAttempts - 1
      }
    }

    // Increment attempt counter
    entry.count++
    this.attempts.set(identifier, entry)

    // Check if max attempts exceeded
    if (entry.count > this.config.maxAttempts) {
      const blockDuration = this.config.blockDurationMs || this.config.windowMs
      entry.blockedUntil = now + blockDuration
      this.attempts.set(identifier, entry)

      return {
        allowed: false,
        retryAfter: Math.ceil(blockDuration / 1000)
      }
    }

    // Still within limits
    return {
      allowed: true,
      remainingAttempts: this.config.maxAttempts - entry.count
    }
  }

  /**
   * Manually reset an identifier (useful for testing)
   */
  reset(identifier: string): void {
    this.attempts.delete(identifier)
  }

  /**
   * Clean up expired entries to prevent memory leaks
   */
  private cleanup(): void {
    const now = Date.now()
    const expiredKeys: string[] = []

    for (const [key, entry] of this.attempts.entries()) {
      // Remove if window expired and not blocked
      if (
        now - entry.firstAttemptAt > this.config.windowMs &&
        (!entry.blockedUntil || now > entry.blockedUntil)
      ) {
        expiredKeys.push(key)
      }
    }

    expiredKeys.forEach(key => this.attempts.delete(key))

    if (expiredKeys.length > 0) {
      console.log(`[RateLimiter] Cleaned up ${expiredKeys.length} expired entries`)
    }
  }

  /**
   * Get current stats (for debugging)
   */
  getStats(): {
    totalTracked: number
    currentlyBlocked: number
  } {
    const now = Date.now()
    let blocked = 0

    for (const entry of this.attempts.values()) {
      if (entry.blockedUntil && now < entry.blockedUntil) {
        blocked++
      }
    }

    return {
      totalTracked: this.attempts.size,
      currentlyBlocked: blocked
    }
  }
}

// Export singleton instances for common use cases
export const passwordResetRateLimiter = new RateLimiter({
  maxAttempts: 3,
  windowMs: 15 * 60 * 1000, // 15 minutes
  blockDurationMs: 60 * 60 * 1000 // 1 hour block after max attempts
})

export const authSignInRateLimiter = new RateLimiter({
  maxAttempts: 5,
  windowMs: 5 * 60 * 1000, // 5 minutes
  blockDurationMs: 15 * 60 * 1000 // 15 minute block
})
