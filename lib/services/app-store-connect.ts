/**
 * App Store Connect API Service
 *
 * Provides access to Apple's App Store Connect API for:
 * - TestFlight management
 * - Sales and financial reports
 * - App metadata and version management
 *
 * @see https://developer.apple.com/documentation/appstoreconnectapi
 */

import { SignJWT, importPKCS8 } from 'jose';

const KEY_ID = process.env.APP_STORE_CONNECT_KEY_ID;
const ISSUER_ID = process.env.APP_STORE_CONNECT_ISSUER_ID;
const PRIVATE_KEY = process.env.APP_STORE_CONNECT_PRIVATE_KEY;

const API_BASE_URL = 'https://api.appstoreconnect.apple.com/v1';

interface AppStoreConnectConfig {
  keyId: string;
  issuerId: string;
  privateKey: string;
}

/**
 * Generate a JWT token for App Store Connect API authentication
 * Tokens are valid for 20 minutes max per Apple's requirements
 */
async function generateToken(config?: Partial<AppStoreConnectConfig>): Promise<string> {
  const keyId = config?.keyId || KEY_ID;
  const issuerId = config?.issuerId || ISSUER_ID;
  const privateKey = config?.privateKey || PRIVATE_KEY;

  if (!keyId || !issuerId || !privateKey) {
    throw new Error('App Store Connect API credentials not configured');
  }

  // Import the private key
  const key = await importPKCS8(privateKey, 'ES256');

  // Create JWT with 20-minute expiration (Apple's max)
  const now = Math.floor(Date.now() / 1000);
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: keyId, typ: 'JWT' })
    .setIssuer(issuerId)
    .setIssuedAt(now)
    .setExpirationTime(now + 20 * 60) // 20 minutes
    .setAudience('appstoreconnect-v1')
    .sign(key);

  return token;
}

/**
 * Make an authenticated request to the App Store Connect API
 */
async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = await generateToken();

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Unknown error' }));
    throw new Error(`App Store Connect API error: ${response.status} - ${JSON.stringify(error)}`);
  }

  return response.json();
}

// =============================================================================
// Apps & Versions
// =============================================================================

interface App {
  id: string;
  attributes: {
    bundleId: string;
    name: string;
    primaryLocale: string;
    sku: string;
  };
}

interface AppVersion {
  id: string;
  attributes: {
    versionString: string;
    appStoreState: string;
    platform: string;
    releaseType: string;
  };
}

/**
 * Get all apps in the account
 */
export async function getApps(): Promise<App[]> {
  const response = await apiRequest<{ data: App[] }>('/apps');
  return response.data;
}

/**
 * Get app by bundle ID
 */
export async function getAppByBundleId(bundleId: string): Promise<App | null> {
  const response = await apiRequest<{ data: App[] }>(
    `/apps?filter[bundleId]=${encodeURIComponent(bundleId)}`
  );
  return response.data[0] || null;
}

/**
 * Get app versions for a specific app
 */
export async function getAppVersions(appId: string): Promise<AppVersion[]> {
  const response = await apiRequest<{ data: AppVersion[] }>(
    `/apps/${appId}/appStoreVersions`
  );
  return response.data;
}

// =============================================================================
// TestFlight Beta Testing
// =============================================================================

interface BetaTester {
  id: string;
  attributes: {
    email: string;
    firstName: string;
    lastName: string;
    inviteType: string;
    state: string;
  };
}

interface BetaBuild {
  id: string;
  attributes: {
    version: string;
    uploadedDate: string;
    processingState: string;
    buildAudienceType: string;
  };
}

interface BetaGroup {
  id: string;
  attributes: {
    name: string;
    isInternalGroup: boolean;
    publicLinkEnabled: boolean;
    publicLinkLimit: number;
  };
}

/**
 * Get all beta testers for an app
 */
export async function getBetaTesters(appId: string): Promise<BetaTester[]> {
  const response = await apiRequest<{ data: BetaTester[] }>(
    `/apps/${appId}/betaTesters`
  );
  return response.data;
}

/**
 * Get all beta builds for an app
 */
export async function getBetaBuilds(appId: string): Promise<BetaBuild[]> {
  const response = await apiRequest<{ data: BetaBuild[] }>(
    `/apps/${appId}/builds?filter[processingState]=VALID&sort=-uploadedDate`
  );
  return response.data;
}

/**
 * Get beta groups for an app
 */
export async function getBetaGroups(appId: string): Promise<BetaGroup[]> {
  const response = await apiRequest<{ data: BetaGroup[] }>(
    `/apps/${appId}/betaGroups`
  );
  return response.data;
}

/**
 * Add a beta tester to a group
 */
export async function addBetaTester(
  betaGroupId: string,
  email: string,
  firstName?: string,
  lastName?: string
): Promise<BetaTester> {
  const response = await apiRequest<{ data: BetaTester }>('/betaTesters', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'betaTesters',
        attributes: {
          email,
          firstName: firstName || '',
          lastName: lastName || '',
        },
        relationships: {
          betaGroups: {
            data: [{ type: 'betaGroups', id: betaGroupId }],
          },
        },
      },
    }),
  });
  return response.data;
}

/**
 * Remove a beta tester from a group
 */
export async function removeBetaTester(
  betaGroupId: string,
  betaTesterId: string
): Promise<void> {
  await apiRequest(`/betaGroups/${betaGroupId}/relationships/betaTesters`, {
    method: 'DELETE',
    body: JSON.stringify({
      data: [{ type: 'betaTesters', id: betaTesterId }],
    }),
  });
}

// =============================================================================
// Sales & Financial Reports
// =============================================================================

interface SalesReport {
  date: string;
  appName: string;
  units: number;
  proceeds: number;
  currency: string;
}

/**
 * Download sales report (requires additional setup with Reporter tool)
 * Note: Sales reports use a different endpoint and require gzip handling
 */
export async function getSalesReportUrl(
  vendorNumber: string,
  reportDate: string, // YYYYMMDD format
  reportType: 'SALES' | 'SUBSCRIPTION' | 'SUBSCRIPTION_EVENT' = 'SALES'
): Promise<string> {
  // Sales reports use a different API endpoint
  const token = await generateToken();

  const params = new URLSearchParams({
    'filter[frequency]': 'DAILY',
    'filter[reportDate]': reportDate,
    'filter[reportSubType]': 'SUMMARY',
    'filter[reportType]': reportType,
    'filter[vendorNumber]': vendorNumber,
  });

  return `https://api.appstoreconnect.apple.com/v1/salesReports?${params.toString()}`;
}

// =============================================================================
// App Analytics (limited - full analytics requires App Analytics Reporter)
// =============================================================================

/**
 * Get app downloads data (last 30 days)
 * Note: Full analytics require the App Store Connect Analytics Reporter tool
 */
export async function getAppDownloadsPreview(appId: string): Promise<{
  totalDownloads: number;
  redownloads: number;
  updates: number;
}> {
  // App Store Connect API v1 doesn't expose detailed analytics
  // This would need the Analytics Reports API or Reporter tool
  // For now, return placeholder indicating this needs setup
  console.warn(
    'Full analytics require App Store Connect Reporter tool setup. ' +
    'See: https://developer.apple.com/documentation/appstoreconnectapi/download_sales_and_trends_reports'
  );

  return {
    totalDownloads: 0,
    redownloads: 0,
    updates: 0,
  };
}

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Check if App Store Connect API is configured
 */
export function isConfigured(): boolean {
  return !!(KEY_ID && ISSUER_ID && PRIVATE_KEY);
}

/**
 * Test the API connection
 */
export async function testConnection(): Promise<{
  success: boolean;
  message: string;
  apps?: App[];
}> {
  try {
    if (!isConfigured()) {
      return {
        success: false,
        message: 'App Store Connect API credentials not configured',
      };
    }

    const apps = await getApps();
    return {
      success: true,
      message: `Connected successfully. Found ${apps.length} app(s).`,
      apps,
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// Export types for consumers
export type {
  App,
  AppVersion,
  BetaTester,
  BetaBuild,
  BetaGroup,
  SalesReport,
};
