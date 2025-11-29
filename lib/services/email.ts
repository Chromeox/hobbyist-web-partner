import sgMail from '@sendgrid/mail';

// Initialize SendGrid with API key
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
}

// Types
export interface EmailRecipient {
  email: string;
  name?: string;
}

export interface EmailTemplate {
  subject: string;
  html: string;
  text?: string;
}

export interface SendEmailOptions {
  to: EmailRecipient | EmailRecipient[];
  from?: EmailRecipient;
  subject: string;
  html: string;
  text?: string;
  replyTo?: string;
  templateId?: string;
  dynamicTemplateData?: Record<string, unknown>;
  categories?: string[];
  customArgs?: Record<string, string>;
}

export interface BulkEmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

// Default sender - update with your verified domain
const DEFAULT_SENDER: EmailRecipient = {
  email: process.env.SENDGRID_FROM_EMAIL || 'noreply@hobbiapp.com',
  name: process.env.SENDGRID_FROM_NAME || 'Hobbi'
};

/**
 * Send a single email
 */
export async function sendEmail(options: SendEmailOptions): Promise<BulkEmailResult> {
  if (!process.env.SENDGRID_API_KEY) {
    console.warn('SendGrid API key not configured - email not sent');
    return { success: false, error: 'SendGrid not configured' };
  }

  try {
    const msg = {
      to: options.to,
      from: options.from || DEFAULT_SENDER,
      subject: options.subject,
      html: options.html,
      text: options.text || stripHtml(options.html),
      replyTo: options.replyTo,
      templateId: options.templateId,
      dynamicTemplateData: options.dynamicTemplateData,
      categories: options.categories,
      customArgs: options.customArgs,
    };

    const [response] = await sgMail.send(msg);

    return {
      success: response.statusCode >= 200 && response.statusCode < 300,
      messageId: response.headers['x-message-id'] as string,
    };
  } catch (error) {
    console.error('SendGrid email error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Send emails to multiple recipients (bulk)
 */
export async function sendBulkEmails(
  recipients: EmailRecipient[],
  template: EmailTemplate,
  options?: {
    from?: EmailRecipient;
    categories?: string[];
    customArgs?: Record<string, string>;
  }
): Promise<BulkEmailResult[]> {
  if (!process.env.SENDGRID_API_KEY) {
    console.warn('SendGrid API key not configured - emails not sent');
    return recipients.map(() => ({ success: false, error: 'SendGrid not configured' }));
  }

  const messages = recipients.map(recipient => ({
    to: recipient,
    from: options?.from || DEFAULT_SENDER,
    subject: template.subject,
    html: template.html,
    text: template.text || stripHtml(template.html),
    categories: options?.categories,
    customArgs: options?.customArgs,
  }));

  try {
    // SendGrid sendMultiple for better performance on bulk sends
    await sgMail.send(messages);
    return recipients.map(() => ({ success: true }));
  } catch (error) {
    console.error('SendGrid bulk email error:', error);
    return recipients.map(() => ({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }));
  }
}

// ============================================
// Pre-built Email Templates
// ============================================

/**
 * Send booking confirmation email
 */
export async function sendBookingConfirmation(
  recipient: EmailRecipient,
  booking: {
    className: string;
    instructorName: string;
    date: string;
    time: string;
    location: string;
    studioName: string;
    creditsUsed?: number;
  }
): Promise<BulkEmailResult> {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1a1a1a; margin: 0;">Booking Confirmed!</h1>
        </div>

        <p style="color: #333; font-size: 16px;">Hi ${recipient.name || 'there'},</p>

        <p style="color: #333; font-size: 16px;">Your spot is reserved for:</p>

        <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <h2 style="margin: 0 0 12px 0; color: #1a1a1a;">${booking.className}</h2>
          <p style="margin: 8px 0; color: #666;">
            <strong>Instructor:</strong> ${booking.instructorName}
          </p>
          <p style="margin: 8px 0; color: #666;">
            <strong>Date:</strong> ${booking.date}
          </p>
          <p style="margin: 8px 0; color: #666;">
            <strong>Time:</strong> ${booking.time}
          </p>
          <p style="margin: 8px 0; color: #666;">
            <strong>Location:</strong> ${booking.location}
          </p>
          ${booking.creditsUsed ? `
          <p style="margin: 8px 0; color: #666;">
            <strong>Credits used:</strong> ${booking.creditsUsed}
          </p>
          ` : ''}
        </div>

        <p style="color: #666; font-size: 14px;">
          See you at ${booking.studioName}!
        </p>

        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">

        <p style="color: #999; font-size: 12px; text-align: center;">
          Need to cancel? Open the Hobbi app and go to your bookings.
        </p>
      </div>
    </body>
    </html>
  `;

  return sendEmail({
    to: recipient,
    subject: `Booking Confirmed: ${booking.className}`,
    html,
    categories: ['booking', 'confirmation'],
  });
}

/**
 * Send waitlist promotion notification
 */
export async function sendWaitlistPromotion(
  recipient: EmailRecipient,
  waitlist: {
    className: string;
    date: string;
    time: string;
    studioName: string;
    expiresIn: string;
    confirmUrl: string;
  }
): Promise<BulkEmailResult> {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #22c55e; margin: 0;">A Spot Opened Up!</h1>
        </div>

        <p style="color: #333; font-size: 16px;">Hi ${recipient.name || 'there'},</p>

        <p style="color: #333; font-size: 16px;">
          Great news! A spot just opened up in a class you were waiting for:
        </p>

        <div style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border-radius: 8px; padding: 20px; margin: 20px 0; border: 1px solid #86efac;">
          <h2 style="margin: 0 0 12px 0; color: #1a1a1a;">${waitlist.className}</h2>
          <p style="margin: 8px 0; color: #666;">
            <strong>Date:</strong> ${waitlist.date}
          </p>
          <p style="margin: 8px 0; color: #666;">
            <strong>Time:</strong> ${waitlist.time}
          </p>
          <p style="margin: 8px 0; color: #666;">
            <strong>Studio:</strong> ${waitlist.studioName}
          </p>
        </div>

        <div style="text-align: center; margin: 24px 0;">
          <a href="${waitlist.confirmUrl}" style="display: inline-block; background: #22c55e; color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
            Confirm My Spot
          </a>
        </div>

        <p style="color: #dc2626; font-size: 14px; text-align: center; font-weight: 500;">
          This spot expires in ${waitlist.expiresIn}. Act fast!
        </p>

        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">

        <p style="color: #999; font-size: 12px; text-align: center;">
          If you no longer want this spot, simply ignore this email.
        </p>
      </div>
    </body>
    </html>
  `;

  return sendEmail({
    to: recipient,
    subject: `A spot opened up in ${waitlist.className}!`,
    html,
    categories: ['waitlist', 'promotion'],
  });
}

/**
 * Send payment failed notification
 */
export async function sendPaymentFailed(
  recipient: EmailRecipient,
  payment: {
    amount: string;
    className?: string;
    reason?: string;
    retryUrl: string;
  }
): Promise<BulkEmailResult> {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #dc2626; margin: 0;">Payment Issue</h1>
        </div>

        <p style="color: #333; font-size: 16px;">Hi ${recipient.name || 'there'},</p>

        <p style="color: #333; font-size: 16px;">
          We weren't able to process your payment of <strong>${payment.amount}</strong>${payment.className ? ` for ${payment.className}` : ''}.
        </p>

        ${payment.reason ? `
        <p style="color: #666; font-size: 14px;">
          Reason: ${payment.reason}
        </p>
        ` : ''}

        <div style="text-align: center; margin: 24px 0;">
          <a href="${payment.retryUrl}" style="display: inline-block; background: #3b82f6; color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
            Update Payment Method
          </a>
        </div>

        <p style="color: #666; font-size: 14px;">
          If you believe this is an error, please contact your bank or try a different payment method.
        </p>
      </div>
    </body>
    </html>
  `;

  return sendEmail({
    to: recipient,
    subject: 'Action Required: Payment Issue',
    html,
    categories: ['payment', 'failed'],
  });
}

/**
 * Send payout confirmation to studio
 */
export async function sendPayoutConfirmation(
  recipient: EmailRecipient,
  payout: {
    amount: string;
    period: string;
    arrivalDate: string;
    transactionCount: number;
  }
): Promise<BulkEmailResult> {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #22c55e; margin: 0;">Payout Sent!</h1>
        </div>

        <p style="color: #333; font-size: 16px;">Hi ${recipient.name || 'there'},</p>

        <p style="color: #333; font-size: 16px;">
          Your payout has been initiated and is on its way to your bank account.
        </p>

        <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center;">
          <p style="margin: 0 0 8px 0; color: #666; font-size: 14px;">Amount</p>
          <p style="margin: 0; color: #1a1a1a; font-size: 32px; font-weight: 700;">${payout.amount}</p>
        </div>

        <div style="display: flex; justify-content: space-between; margin: 20px 0;">
          <div>
            <p style="margin: 0; color: #666; font-size: 12px;">Period</p>
            <p style="margin: 4px 0 0 0; color: #333; font-size: 14px;">${payout.period}</p>
          </div>
          <div>
            <p style="margin: 0; color: #666; font-size: 12px;">Expected Arrival</p>
            <p style="margin: 4px 0 0 0; color: #333; font-size: 14px;">${payout.arrivalDate}</p>
          </div>
          <div>
            <p style="margin: 0; color: #666; font-size: 12px;">Transactions</p>
            <p style="margin: 4px 0 0 0; color: #333; font-size: 14px;">${payout.transactionCount}</p>
          </div>
        </div>

        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">

        <p style="color: #999; font-size: 12px; text-align: center;">
          View full details in your Partner Portal dashboard.
        </p>
      </div>
    </body>
    </html>
  `;

  return sendEmail({
    to: recipient,
    subject: `Payout of ${payout.amount} is on its way`,
    html,
    categories: ['payout', 'confirmation'],
  });
}

/**
 * Send marketing campaign email
 */
export async function sendMarketingCampaign(
  recipients: EmailRecipient[],
  campaign: {
    subject: string;
    preheader?: string;
    title: string;
    body: string;
    ctaText?: string;
    ctaUrl?: string;
    studioName: string;
    unsubscribeUrl: string;
  }
): Promise<BulkEmailResult[]> {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      ${campaign.preheader ? `<span style="display: none;">${campaign.preheader}</span>` : ''}
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1a1a1a; margin: 0;">${campaign.title}</h1>
        </div>

        <div style="color: #333; font-size: 16px; line-height: 1.6;">
          ${campaign.body}
        </div>

        ${campaign.ctaText && campaign.ctaUrl ? `
        <div style="text-align: center; margin: 32px 0;">
          <a href="${campaign.ctaUrl}" style="display: inline-block; background: #3b82f6; color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
            ${campaign.ctaText}
          </a>
        </div>
        ` : ''}

        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">

        <p style="color: #999; font-size: 12px; text-align: center;">
          Sent by ${campaign.studioName} via Hobbi<br>
          <a href="${campaign.unsubscribeUrl}" style="color: #999;">Unsubscribe</a>
        </p>
      </div>
    </body>
    </html>
  `;

  return sendBulkEmails(recipients, {
    subject: campaign.subject,
    html,
  }, {
    categories: ['marketing', 'campaign'],
  });
}

// ============================================
// Utility Functions
// ============================================

/**
 * Strip HTML tags for plain text version
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Validate email address format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export default {
  sendEmail,
  sendBulkEmails,
  sendBookingConfirmation,
  sendWaitlistPromotion,
  sendPaymentFailed,
  sendPayoutConfirmation,
  sendMarketingCampaign,
  isValidEmail,
};
