import * as jwt from 'jsonwebtoken';

// Apple Push Notification Service (APNs) configuration
const APNS_KEY_ID = process.env.APNS_KEY_ID;
const APNS_TEAM_ID = process.env.APNS_TEAM_ID;
const APNS_BUNDLE_ID = process.env.APNS_BUNDLE_ID || 'com.hobbi.app';
const APNS_PRIVATE_KEY = process.env.APNS_PRIVATE_KEY; // The .p8 file contents

// APNs endpoints
const APNS_HOST_PRODUCTION = 'api.push.apple.com';
const APNS_HOST_SANDBOX = 'api.sandbox.push.apple.com';

// Types
export interface PushNotificationPayload {
  title: string;
  body: string;
  subtitle?: string;
  badge?: number;
  sound?: string | { critical?: boolean; name?: string; volume?: number };
  data?: Record<string, unknown>;
  category?: string;
  threadId?: string;
  targetContentId?: string;
  interruptionLevel?: 'passive' | 'active' | 'time-sensitive' | 'critical';
  relevanceScore?: number;
}

export interface SendPushOptions {
  deviceToken: string;
  payload: PushNotificationPayload;
  expiration?: number; // Unix timestamp
  priority?: 5 | 10; // 5 for content-available, 10 for alerts
  collapseId?: string;
  sandbox?: boolean;
}

export interface PushResult {
  success: boolean;
  apnsId?: string;
  error?: string;
  invalidToken?: boolean;
}

/**
 * Generate JWT token for APNs authentication
 */
function generateAPNsToken(): string | null {
  if (!APNS_PRIVATE_KEY || !APNS_KEY_ID || !APNS_TEAM_ID) {
    console.warn('APNs credentials not configured');
    return null;
  }

  try {
    const token = jwt.sign(
      {
        iss: APNS_TEAM_ID,
        iat: Math.floor(Date.now() / 1000),
      },
      APNS_PRIVATE_KEY,
      {
        algorithm: 'ES256',
        header: {
          alg: 'ES256',
          kid: APNS_KEY_ID,
        },
      }
    );

    return token;
  } catch (error) {
    console.error('Failed to generate APNs token:', error);
    return null;
  }
}

/**
 * Build APNs payload from our simplified format
 */
function buildAPNsPayload(payload: PushNotificationPayload): Record<string, unknown> {
  const aps: Record<string, unknown> = {
    alert: {
      title: payload.title,
      body: payload.body,
      ...(payload.subtitle && { subtitle: payload.subtitle }),
    },
  };

  if (payload.badge !== undefined) {
    aps.badge = payload.badge;
  }

  if (payload.sound) {
    aps.sound = payload.sound;
  }

  if (payload.category) {
    aps.category = payload.category;
  }

  if (payload.threadId) {
    aps['thread-id'] = payload.threadId;
  }

  if (payload.targetContentId) {
    aps['target-content-id'] = payload.targetContentId;
  }

  if (payload.interruptionLevel) {
    aps['interruption-level'] = payload.interruptionLevel;
  }

  if (payload.relevanceScore !== undefined) {
    aps['relevance-score'] = payload.relevanceScore;
  }

  return {
    aps,
    ...payload.data,
  };
}

/**
 * Send a push notification to a single device
 */
export async function sendPushNotification(options: SendPushOptions): Promise<PushResult> {
  const token = generateAPNsToken();

  if (!token) {
    return { success: false, error: 'APNs not configured' };
  }

  const host = options.sandbox ? APNS_HOST_SANDBOX : APNS_HOST_PRODUCTION;
  const url = `https://${host}/3/device/${options.deviceToken}`;

  const apnsPayload = buildAPNsPayload(options.payload);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'authorization': `bearer ${token}`,
        'apns-topic': APNS_BUNDLE_ID!,
        'apns-push-type': 'alert',
        'apns-priority': String(options.priority || 10),
        ...(options.expiration && { 'apns-expiration': String(options.expiration) }),
        ...(options.collapseId && { 'apns-collapse-id': options.collapseId }),
        'content-type': 'application/json',
      },
      body: JSON.stringify(apnsPayload),
    });

    const apnsId = response.headers.get('apns-id');

    if (response.ok) {
      return {
        success: true,
        apnsId: apnsId || undefined,
      };
    }

    // Handle error response
    const errorBody = await response.json().catch(() => ({}));
    const reason = (errorBody as { reason?: string }).reason || 'Unknown error';

    // Check if token is invalid (device unregistered, etc.)
    const invalidToken = [
      'BadDeviceToken',
      'Unregistered',
      'DeviceTokenNotForTopic',
    ].includes(reason);

    return {
      success: false,
      error: reason,
      invalidToken,
    };
  } catch (error) {
    console.error('APNs request failed:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Network error',
    };
  }
}

/**
 * Send push notifications to multiple devices
 */
export async function sendBulkPushNotifications(
  deviceTokens: string[],
  payload: PushNotificationPayload,
  options?: {
    sandbox?: boolean;
    batchSize?: number;
  }
): Promise<Map<string, PushResult>> {
  const results = new Map<string, PushResult>();
  const batchSize = options?.batchSize || 100;

  // Process in batches to avoid overwhelming APNs
  for (let i = 0; i < deviceTokens.length; i += batchSize) {
    const batch = deviceTokens.slice(i, i + batchSize);

    const batchPromises = batch.map(async (token) => {
      const result = await sendPushNotification({
        deviceToken: token,
        payload,
        sandbox: options?.sandbox,
      });
      return { token, result };
    });

    const batchResults = await Promise.all(batchPromises);

    for (const { token, result } of batchResults) {
      results.set(token, result);
    }

    // Small delay between batches
    if (i + batchSize < deviceTokens.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  return results;
}

// ============================================
// Pre-built Push Notification Templates
// ============================================

/**
 * Send booking confirmation push
 */
export async function sendBookingConfirmationPush(
  deviceToken: string,
  booking: {
    className: string;
    date: string;
    time: string;
    bookingId: string;
  },
  sandbox = false
): Promise<PushResult> {
  return sendPushNotification({
    deviceToken,
    sandbox,
    payload: {
      title: 'Booking Confirmed!',
      body: `Your spot in ${booking.className} on ${booking.date} at ${booking.time} is reserved.`,
      sound: 'default',
      category: 'BOOKING_CONFIRMATION',
      data: {
        type: 'booking_confirmation',
        bookingId: booking.bookingId,
      },
    },
  });
}

/**
 * Send waitlist promotion push (time-sensitive)
 */
export async function sendWaitlistPromotionPush(
  deviceToken: string,
  waitlist: {
    className: string;
    date: string;
    time: string;
    expiresIn: string;
    waitlistId: string;
  },
  sandbox = false
): Promise<PushResult> {
  return sendPushNotification({
    deviceToken,
    sandbox,
    priority: 10,
    payload: {
      title: 'A Spot Opened Up!',
      body: `${waitlist.className} on ${waitlist.date} - Confirm within ${waitlist.expiresIn}`,
      sound: { name: 'default', critical: false, volume: 1.0 },
      category: 'WAITLIST_PROMOTION',
      interruptionLevel: 'time-sensitive',
      data: {
        type: 'waitlist_promotion',
        waitlistId: waitlist.waitlistId,
      },
    },
  });
}

/**
 * Send class reminder push
 */
export async function sendClassReminderPush(
  deviceToken: string,
  reminder: {
    className: string;
    startsIn: string;
    location: string;
    bookingId: string;
  },
  sandbox = false
): Promise<PushResult> {
  return sendPushNotification({
    deviceToken,
    sandbox,
    payload: {
      title: `${reminder.className} starts in ${reminder.startsIn}`,
      body: `Don't forget your gear! Location: ${reminder.location}`,
      sound: 'default',
      category: 'CLASS_REMINDER',
      threadId: 'reminders',
      data: {
        type: 'class_reminder',
        bookingId: reminder.bookingId,
      },
    },
  });
}

/**
 * Send class cancellation push
 */
export async function sendClassCancellationPush(
  deviceToken: string,
  cancellation: {
    className: string;
    date: string;
    reason?: string;
    creditsRefunded?: number;
  },
  sandbox = false
): Promise<PushResult> {
  let body = `${cancellation.className} on ${cancellation.date} has been cancelled.`;
  if (cancellation.creditsRefunded) {
    body += ` ${cancellation.creditsRefunded} credits refunded.`;
  }
  if (cancellation.reason) {
    body += ` Reason: ${cancellation.reason}`;
  }

  return sendPushNotification({
    deviceToken,
    sandbox,
    payload: {
      title: 'Class Cancelled',
      body,
      sound: 'default',
      category: 'CLASS_CANCELLATION',
      data: {
        type: 'class_cancellation',
      },
    },
  });
}

/**
 * Send payment success push
 */
export async function sendPaymentSuccessPush(
  deviceToken: string,
  payment: {
    amount: string;
    description: string;
  },
  sandbox = false
): Promise<PushResult> {
  return sendPushNotification({
    deviceToken,
    sandbox,
    payload: {
      title: 'Payment Successful',
      body: `${payment.amount} charged for ${payment.description}`,
      sound: 'default',
      category: 'PAYMENT',
      data: {
        type: 'payment_success',
      },
    },
  });
}

/**
 * Send new message push
 */
export async function sendNewMessagePush(
  deviceToken: string,
  message: {
    senderName: string;
    preview: string;
    conversationId: string;
  },
  sandbox = false
): Promise<PushResult> {
  return sendPushNotification({
    deviceToken,
    sandbox,
    payload: {
      title: message.senderName,
      body: message.preview.length > 100 ? `${message.preview.slice(0, 100)}...` : message.preview,
      sound: 'default',
      category: 'MESSAGE',
      threadId: `conversation-${message.conversationId}`,
      data: {
        type: 'new_message',
        conversationId: message.conversationId,
      },
    },
  });
}

/**
 * Send silent/background push for data sync
 */
export async function sendSilentPush(
  deviceToken: string,
  data: Record<string, unknown>,
  sandbox = false
): Promise<PushResult> {
  const token = generateAPNsToken();

  if (!token) {
    return { success: false, error: 'APNs not configured' };
  }

  const host = sandbox ? APNS_HOST_SANDBOX : APNS_HOST_PRODUCTION;
  const url = `https://${host}/3/device/${deviceToken}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'authorization': `bearer ${token}`,
        'apns-topic': APNS_BUNDLE_ID!,
        'apns-push-type': 'background',
        'apns-priority': '5',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        aps: {
          'content-available': 1,
        },
        ...data,
      }),
    });

    if (response.ok) {
      return { success: true };
    }

    const errorBody = await response.json().catch(() => ({}));
    return {
      success: false,
      error: (errorBody as { reason?: string }).reason || 'Unknown error',
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Network error',
    };
  }
}

// ============================================
// Utility Functions
// ============================================

/**
 * Check if APNs is properly configured
 */
export function getAPNsStatus(): {
  configured: boolean;
  bundleId?: string;
} {
  return {
    configured: !!(APNS_KEY_ID && APNS_TEAM_ID && APNS_PRIVATE_KEY && APNS_BUNDLE_ID),
    bundleId: APNS_BUNDLE_ID,
  };
}

/**
 * Validate device token format
 */
export function isValidDeviceToken(token: string): boolean {
  // APNs device tokens are 64 hex characters
  return /^[a-fA-F0-9]{64}$/.test(token);
}

export default {
  sendPushNotification,
  sendBulkPushNotifications,
  sendBookingConfirmationPush,
  sendWaitlistPromotionPush,
  sendClassReminderPush,
  sendClassCancellationPush,
  sendPaymentSuccessPush,
  sendNewMessagePush,
  sendSilentPush,
  getAPNsStatus,
  isValidDeviceToken,
};
