/**
 * App Store Server API Service
 *
 * Provides access to Apple's App Store Server API for:
 * - In-App Purchase verification
 * - Subscription status checking
 * - Transaction history
 * - Refund handling
 * - Server notifications (App Store Server Notifications V2)
 *
 * @see https://developer.apple.com/documentation/appstoreserverapi
 */

import { SignJWT, importPKCS8 } from 'jose';

const KEY_ID = process.env.APP_STORE_SERVER_KEY_ID;
const ISSUER_ID = process.env.APP_STORE_SERVER_ISSUER_ID;
const BUNDLE_ID = process.env.APP_STORE_SERVER_BUNDLE_ID;
const PRIVATE_KEY = process.env.APP_STORE_SERVER_PRIVATE_KEY;
const SHARED_SECRET = process.env.APP_STORE_SHARED_SECRET;

// Production and Sandbox URLs
const PRODUCTION_URL = 'https://api.storekit.itunes.apple.com';
const SANDBOX_URL = 'https://api.storekit-sandbox.itunes.apple.com';

// Legacy receipt verification URLs (for older receipts)
const LEGACY_PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const LEGACY_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

type Environment = 'production' | 'sandbox';

/**
 * Generate a JWT token for App Store Server API authentication
 * Note: App Store Server API uses a different JWT format than App Store Connect API
 */
async function generateToken(): Promise<string> {
  if (!KEY_ID || !ISSUER_ID || !BUNDLE_ID || !PRIVATE_KEY) {
    throw new Error('App Store Server API credentials not configured');
  }

  const key = await importPKCS8(PRIVATE_KEY, 'ES256');

  const now = Math.floor(Date.now() / 1000);
  const token = await new SignJWT({
    bid: BUNDLE_ID, // Bundle ID claim required for Server API
  })
    .setProtectedHeader({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })
    .setIssuer(ISSUER_ID)
    .setIssuedAt(now)
    .setExpirationTime(now + 60 * 60) // 1 hour (max allowed)
    .setAudience('appstoreconnect-v1')
    .sign(key);

  return token;
}

/**
 * Make an authenticated request to the App Store Server API
 */
async function apiRequest<T>(
  endpoint: string,
  environment: Environment = 'production',
  options: RequestInit = {}
): Promise<T> {
  const token = await generateToken();
  const baseUrl = environment === 'production' ? PRODUCTION_URL : SANDBOX_URL;

  const response = await fetch(`${baseUrl}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Unknown error' }));
    throw new Error(`App Store Server API error: ${response.status} - ${JSON.stringify(error)}`);
  }

  return response.json();
}

// =============================================================================
// Transaction & Subscription Types
// =============================================================================

interface TransactionInfo {
  transactionId: string;
  originalTransactionId: string;
  bundleId: string;
  productId: string;
  purchaseDate: number;
  originalPurchaseDate: number;
  quantity: number;
  type: 'Auto-Renewable Subscription' | 'Non-Consumable' | 'Consumable' | 'Non-Renewing Subscription';
  inAppOwnershipType: 'PURCHASED' | 'FAMILY_SHARED';
  signedDate: number;
  environment: 'Production' | 'Sandbox';
  transactionReason?: 'PURCHASE' | 'RENEWAL';
  storefront: string;
  storefrontId: string;
  price?: number;
  currency?: string;
}

interface SubscriptionStatus {
  environment: 'Production' | 'Sandbox';
  bundleId: string;
  appAppleId: number;
  data: SubscriptionGroupStatus[];
}

interface SubscriptionGroupStatus {
  subscriptionGroupIdentifier: string;
  lastTransactions: LastTransaction[];
}

interface LastTransaction {
  originalTransactionId: string;
  status: 1 | 2 | 3 | 4 | 5; // 1=Active, 2=Expired, 3=Billing Retry, 4=Grace Period, 5=Revoked
  signedTransactionInfo: string;
  signedRenewalInfo: string;
}

interface TransactionHistoryResponse {
  signedTransactions: string[];
  revision: string;
  bundleId: string;
  environment: 'Production' | 'Sandbox';
  hasMore: boolean;
}

// =============================================================================
// Core API Functions
// =============================================================================

/**
 * Get subscription status for a customer
 * @param transactionId - Any transaction ID from the customer's subscription
 */
export async function getSubscriptionStatus(
  transactionId: string,
  environment: Environment = 'production'
): Promise<SubscriptionStatus> {
  return apiRequest<SubscriptionStatus>(
    `/inApps/v1/subscriptions/${transactionId}`,
    environment
  );
}

/**
 * Get all subscription statuses for a customer by their original transaction ID
 */
export async function getAllSubscriptionStatuses(
  originalTransactionId: string,
  environment: Environment = 'production'
): Promise<SubscriptionStatus> {
  return apiRequest<SubscriptionStatus>(
    `/inApps/v1/subscriptions/${originalTransactionId}`,
    environment
  );
}

/**
 * Get transaction history for a customer
 * @param transactionId - Any transaction ID from the customer
 * @param revision - Optional revision token for pagination
 */
export async function getTransactionHistory(
  transactionId: string,
  environment: Environment = 'production',
  revision?: string
): Promise<TransactionHistoryResponse> {
  const params = new URLSearchParams();
  if (revision) params.set('revision', revision);

  const query = params.toString() ? `?${params.toString()}` : '';
  return apiRequest<TransactionHistoryResponse>(
    `/inApps/v1/history/${transactionId}${query}`,
    environment
  );
}

/**
 * Get information about a specific transaction
 */
export async function getTransactionInfo(
  transactionId: string,
  environment: Environment = 'production'
): Promise<{ signedTransactionInfo: string }> {
  return apiRequest<{ signedTransactionInfo: string }>(
    `/inApps/v1/transactions/${transactionId}`,
    environment
  );
}

/**
 * Look up order by order ID (from receipt)
 */
export async function lookUpOrderId(
  orderId: string,
  environment: Environment = 'production'
): Promise<{ signedTransactions: string[] }> {
  return apiRequest<{ signedTransactions: string[] }>(
    `/inApps/v1/lookup/${orderId}`,
    environment
  );
}

// =============================================================================
// Refund Functions
// =============================================================================

interface RefundHistoryResponse {
  signedTransactions: string[];
  revision: string;
  hasMore: boolean;
}

/**
 * Get refund history for a customer
 */
export async function getRefundHistory(
  transactionId: string,
  environment: Environment = 'production',
  revision?: string
): Promise<RefundHistoryResponse> {
  const params = new URLSearchParams();
  if (revision) params.set('revision', revision);

  const query = params.toString() ? `?${params.toString()}` : '';
  return apiRequest<RefundHistoryResponse>(
    `/inApps/v2/refund/lookup/${transactionId}${query}`,
    environment
  );
}

/**
 * Request a consumption info request (for consumables refund investigation)
 */
export async function sendConsumptionInfo(
  transactionId: string,
  consumptionData: {
    customerConsented: boolean;
    consumptionStatus: 0 | 1 | 2 | 3 | 4; // 0=Undeclared, 1=Not Consumed, 2=Partially Consumed, 3=Fully Consumed, 4=Unknown
    platform: 0 | 1 | 2 | 3; // 0=Undeclared, 1=Apple, 2=Non-Apple, 3=Both
    sampleContentProvided: boolean;
    deliveryStatus: 0 | 1 | 2 | 3 | 4 | 5; // Delivery statuses
    appAccountToken?: string;
    accountTenure?: number;
    playTime?: number;
    lifetimeDollarsRefunded?: number;
    lifetimeDollarsPurchased?: number;
    userStatus?: 0 | 1 | 2 | 3 | 4;
  },
  environment: Environment = 'production'
): Promise<void> {
  await apiRequest(
    `/inApps/v1/transactions/consumption/${transactionId}`,
    environment,
    {
      method: 'PUT',
      body: JSON.stringify(consumptionData),
    }
  );
}

// =============================================================================
// Legacy Receipt Verification (for older apps)
// =============================================================================

interface LegacyReceiptResponse {
  status: number;
  environment: 'Production' | 'Sandbox';
  receipt?: {
    bundle_id: string;
    application_version: string;
    in_app: Array<{
      product_id: string;
      transaction_id: string;
      original_transaction_id: string;
      purchase_date_ms: string;
      expires_date_ms?: string;
    }>;
  };
  latest_receipt_info?: Array<{
    product_id: string;
    transaction_id: string;
    original_transaction_id: string;
    purchase_date_ms: string;
    expires_date_ms?: string;
    is_trial_period: string;
    is_in_intro_offer_period: string;
  }>;
  pending_renewal_info?: Array<{
    auto_renew_product_id: string;
    auto_renew_status: '0' | '1';
    expiration_intent?: string;
    is_in_billing_retry_period?: string;
  }>;
}

/**
 * Verify a receipt using the legacy verifyReceipt endpoint
 * Note: Use the new App Store Server API when possible
 *
 * @param receiptData - Base64 encoded receipt data
 * @param excludeOldTransactions - If true, only return latest transaction
 */
export async function verifyReceiptLegacy(
  receiptData: string,
  excludeOldTransactions = true
): Promise<LegacyReceiptResponse> {
  if (!SHARED_SECRET) {
    throw new Error('APP_STORE_SHARED_SECRET not configured');
  }

  // Try production first
  let response = await fetch(LEGACY_PRODUCTION_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      'receipt-data': receiptData,
      'password': SHARED_SECRET,
      'exclude-old-transactions': excludeOldTransactions,
    }),
  });

  let result: LegacyReceiptResponse = await response.json();

  // Status 21007 means it's a sandbox receipt
  if (result.status === 21007) {
    response = await fetch(LEGACY_SANDBOX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': SHARED_SECRET,
        'exclude-old-transactions': excludeOldTransactions,
      }),
    });
    result = await response.json();
  }

  return result;
}

// =============================================================================
// Notification Types (for handling App Store Server Notifications V2)
// =============================================================================

export type NotificationType =
  | 'CONSUMPTION_REQUEST'
  | 'DID_CHANGE_RENEWAL_PREF'
  | 'DID_CHANGE_RENEWAL_STATUS'
  | 'DID_FAIL_TO_RENEW'
  | 'DID_RENEW'
  | 'EXPIRED'
  | 'GRACE_PERIOD_EXPIRED'
  | 'OFFER_REDEEMED'
  | 'PRICE_INCREASE'
  | 'REFUND'
  | 'REFUND_DECLINED'
  | 'REFUND_REVERSED'
  | 'RENEWAL_EXTENDED'
  | 'RENEWAL_EXTENSION'
  | 'REVOKE'
  | 'SUBSCRIBED'
  | 'TEST';

export interface ServerNotificationV2 {
  notificationType: NotificationType;
  subtype?: string;
  notificationUUID: string;
  data: {
    appAppleId: number;
    bundleId: string;
    bundleVersion: string;
    environment: 'Production' | 'Sandbox';
    signedTransactionInfo: string;
    signedRenewalInfo?: string;
  };
  version: string;
  signedDate: number;
}

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Check if App Store Server API is configured
 */
export function isConfigured(): boolean {
  return !!(KEY_ID && ISSUER_ID && BUNDLE_ID && PRIVATE_KEY);
}

/**
 * Check if legacy receipt verification is configured
 */
export function isLegacyConfigured(): boolean {
  return !!SHARED_SECRET;
}

/**
 * Parse subscription status code to human-readable string
 */
export function parseSubscriptionStatus(status: 1 | 2 | 3 | 4 | 5): string {
  const statuses: Record<number, string> = {
    1: 'Active',
    2: 'Expired',
    3: 'Billing Retry Period',
    4: 'Grace Period',
    5: 'Revoked',
  };
  return statuses[status] || 'Unknown';
}

/**
 * Test the API connection
 */
export async function testConnection(): Promise<{
  success: boolean;
  message: string;
  configured: {
    serverApi: boolean;
    legacyReceipt: boolean;
  };
}> {
  const configured = {
    serverApi: isConfigured(),
    legacyReceipt: isLegacyConfigured(),
  };

  if (!configured.serverApi && !configured.legacyReceipt) {
    return {
      success: false,
      message: 'App Store Server API credentials not configured',
      configured,
    };
  }

  // We can't test without a real transaction ID, so just verify config
  return {
    success: true,
    message: `Configured: Server API=${configured.serverApi}, Legacy Receipt=${configured.legacyReceipt}`,
    configured,
  };
}

// Export types
export type {
  TransactionInfo,
  SubscriptionStatus,
  SubscriptionGroupStatus,
  LastTransaction,
  TransactionHistoryResponse,
  RefundHistoryResponse,
  LegacyReceiptResponse,
};
