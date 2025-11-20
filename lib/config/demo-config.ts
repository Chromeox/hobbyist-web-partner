/**
 * Demo Configuration
 *
 * SECURITY WARNING: Demo mode should ONLY be enabled in development environments.
 * Never use demo credentials in production. Always use real user accounts.
 */

// Check if we're in development environment
const isDevelopment = process.env.NODE_ENV === 'development';

// Demo mode configuration
export const demoConfig = {
  // Only enable demo mode if explicitly set AND in development
  isDemoEnabled: isDevelopment && process.env.ENABLE_DEMO_MODE === 'true',

  // Only show credentials on login page if explicitly enabled AND in development
  showCredentials: isDevelopment && process.env.SHOW_DEMO_CREDENTIALS === 'true',

  // Demo credentials from environment variables (never hardcode!)
  demoUser: {
    email: process.env.DEMO_USER_EMAIL || '',
    password: process.env.DEMO_USER_PASSWORD || '',
  },

  // Admin test credentials from environment variables
  adminUser: {
    email: process.env.ADMIN_TEST_EMAIL || '',
    password: process.env.ADMIN_TEST_PASSWORD || '',
  },
};

/**
 * Get demo credentials safely
 * Returns null if demo mode is disabled or in production
 */
export function getDemoCredentials() {
  if (!demoConfig.isDemoEnabled) {
    console.warn('Demo mode is disabled. Use real credentials.');
    return null;
  }

  if (process.env.NODE_ENV === 'production') {
    console.error('SECURITY WARNING: Demo mode cannot be used in production!');
    return null;
  }

  return {
    demo: demoConfig.demoUser,
    admin: demoConfig.adminUser,
  };
}

/**
 * Check if demo login should be shown
 */
export function shouldShowDemoLogin(): boolean {
  return demoConfig.isDemoEnabled && demoConfig.showCredentials;
}

/**
 * Validate if an email/password combination matches demo credentials
 * Only works in development with demo mode enabled
 */
export function isDemoCredential(email: string, password: string): boolean {
  if (!demoConfig.isDemoEnabled) return false;
  if (process.env.NODE_ENV === 'production') return false;

  return (
    (email === demoConfig.demoUser.email && password === demoConfig.demoUser.password) ||
    (email === demoConfig.adminUser.email && password === demoConfig.adminUser.password)
  );
}