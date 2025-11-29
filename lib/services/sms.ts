import twilio from 'twilio';

// Initialize Twilio client
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_PHONE_NUMBER;

// Create client only if credentials exist
const client = accountSid && authToken ? twilio(accountSid, authToken) : null;

// Types
export interface SMSRecipient {
  phone: string;
  name?: string;
}

export interface SendSMSOptions {
  to: string;
  message: string;
  mediaUrl?: string[];
}

export interface SMSResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Format phone number to E.164 format for Twilio
 * Assumes North American numbers if no country code
 */
function formatPhoneNumber(phone: string): string {
  // Remove all non-digit characters
  const digits = phone.replace(/\D/g, '');

  // If already has country code (11+ digits starting with 1)
  if (digits.length === 11 && digits.startsWith('1')) {
    return `+${digits}`;
  }

  // If 10 digits, assume US/Canada
  if (digits.length === 10) {
    return `+1${digits}`;
  }

  // Otherwise, return with + prefix
  return `+${digits}`;
}

/**
 * Send a single SMS message
 */
export async function sendSMS(options: SendSMSOptions): Promise<SMSResult> {
  if (!client || !fromNumber) {
    console.warn('Twilio not configured - SMS not sent');
    return { success: false, error: 'Twilio not configured' };
  }

  try {
    const message = await client.messages.create({
      body: options.message,
      to: formatPhoneNumber(options.to),
      from: fromNumber,
      mediaUrl: options.mediaUrl,
    });

    return {
      success: true,
      messageId: message.sid,
    };
  } catch (error) {
    console.error('Twilio SMS error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Send SMS to multiple recipients
 */
export async function sendBulkSMS(
  recipients: SMSRecipient[],
  message: string | ((recipient: SMSRecipient) => string)
): Promise<SMSResult[]> {
  const results: SMSResult[] = [];

  for (const recipient of recipients) {
    const messageText = typeof message === 'function' ? message(recipient) : message;
    const result = await sendSMS({
      to: recipient.phone,
      message: messageText,
    });
    results.push(result);

    // Small delay to respect Twilio rate limits
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  return results;
}

// ============================================
// Pre-built SMS Templates
// ============================================

/**
 * Send booking confirmation SMS
 */
export async function sendBookingConfirmationSMS(
  phone: string,
  booking: {
    className: string;
    date: string;
    time: string;
    studioName: string;
  }
): Promise<SMSResult> {
  const message = `Hobbi: Your spot is confirmed! ${booking.className} at ${booking.studioName} on ${booking.date} at ${booking.time}. See you there!`;

  return sendSMS({ to: phone, message });
}

/**
 * Send waitlist promotion SMS
 */
export async function sendWaitlistPromotionSMS(
  phone: string,
  waitlist: {
    className: string;
    date: string;
    time: string;
    expiresIn: string;
  }
): Promise<SMSResult> {
  const message = `Hobbi: A spot opened up in ${waitlist.className} on ${waitlist.date} at ${waitlist.time}! Reply YES within ${waitlist.expiresIn} to confirm your spot.`;

  return sendSMS({ to: phone, message });
}

/**
 * Send class reminder SMS
 */
export async function sendClassReminderSMS(
  phone: string,
  reminder: {
    className: string;
    time: string;
    location: string;
  }
): Promise<SMSResult> {
  const message = `Hobbi: Reminder - ${reminder.className} starts at ${reminder.time} at ${reminder.location}. Don't forget your gear!`;

  return sendSMS({ to: phone, message });
}

/**
 * Send cancellation confirmation SMS
 */
export async function sendCancellationSMS(
  phone: string,
  cancellation: {
    className: string;
    creditsRefunded?: number;
  }
): Promise<SMSResult> {
  let message = `Hobbi: Your booking for ${cancellation.className} has been cancelled.`;

  if (cancellation.creditsRefunded) {
    message += ` ${cancellation.creditsRefunded} credits have been refunded to your account.`;
  }

  return sendSMS({ to: phone, message });
}

/**
 * Send payment failure SMS
 */
export async function sendPaymentFailedSMS(
  phone: string,
  payment: {
    amount: string;
  }
): Promise<SMSResult> {
  const message = `Hobbi: We couldn't process your payment of ${payment.amount}. Please update your payment method in the app to complete your booking.`;

  return sendSMS({ to: phone, message });
}

/**
 * Send welcome SMS to new user
 */
export async function sendWelcomeSMS(
  phone: string,
  user: {
    name?: string;
  }
): Promise<SMSResult> {
  const greeting = user.name ? `Hi ${user.name}!` : 'Welcome!';
  const message = `${greeting} Thanks for joining Hobbi. Discover creative classes near you and start your next adventure. Text HELP for support or STOP to unsubscribe.`;

  return sendSMS({ to: phone, message });
}

/**
 * Send promotional SMS (marketing)
 */
export async function sendPromoSMS(
  phone: string,
  promo: {
    title: string;
    description: string;
    code?: string;
  }
): Promise<SMSResult> {
  let message = `Hobbi: ${promo.title} - ${promo.description}`;

  if (promo.code) {
    message += ` Use code: ${promo.code}`;
  }

  message += ' Reply STOP to unsubscribe.';

  return sendSMS({ to: phone, message });
}

// ============================================
// Utility Functions
// ============================================

/**
 * Validate phone number format
 */
export function isValidPhoneNumber(phone: string): boolean {
  const digits = phone.replace(/\D/g, '');
  // Valid if 10-15 digits
  return digits.length >= 10 && digits.length <= 15;
}

/**
 * Get Twilio configuration status
 */
export function getTwilioStatus(): {
  configured: boolean;
  phoneNumber?: string;
} {
  return {
    configured: !!(client && fromNumber),
    phoneNumber: fromNumber ? fromNumber.replace(/(\+\d{1})(\d{3})(\d{3})(\d{4})/, '$1 ($2) $3-$4') : undefined,
  };
}

export default {
  sendSMS,
  sendBulkSMS,
  sendBookingConfirmationSMS,
  sendWaitlistPromotionSMS,
  sendClassReminderSMS,
  sendCancellationSMS,
  sendPaymentFailedSMS,
  sendWelcomeSMS,
  sendPromoSMS,
  isValidPhoneNumber,
  getTwilioStatus,
};
