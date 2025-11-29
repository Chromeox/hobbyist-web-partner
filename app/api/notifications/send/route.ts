import { NextRequest, NextResponse } from 'next/server';
import { createServiceClient } from '@/lib/supabase/server';
import emailService from '@/lib/services/email';
import smsService from '@/lib/services/sms';
import pushService from '@/lib/services/push-notifications';

// Types for notification requests
interface NotificationRecipient {
  userId?: string;
  email?: string;
  phone?: string;
  deviceToken?: string;
  name?: string;
}

interface NotificationRequest {
  type: 'email' | 'sms' | 'push' | 'all';
  recipients: NotificationRecipient[];
  template: string;
  data: Record<string, unknown>;
  options?: {
    sandbox?: boolean; // For push notifications testing
  };
}

// Template handlers
type TemplateHandler = {
  email?: (recipient: NotificationRecipient, data: Record<string, unknown>) => Promise<{ success: boolean; error?: string }>;
  sms?: (recipient: NotificationRecipient, data: Record<string, unknown>) => Promise<{ success: boolean; error?: string }>;
  push?: (recipient: NotificationRecipient, data: Record<string, unknown>, sandbox?: boolean) => Promise<{ success: boolean; error?: string }>;
};

const templateHandlers: Record<string, TemplateHandler> = {
  booking_confirmation: {
    email: async (recipient, data) => {
      if (!recipient.email) return { success: false, error: 'No email' };
      return emailService.sendBookingConfirmation(
        { email: recipient.email, name: recipient.name },
        data as {
          className: string;
          instructorName: string;
          date: string;
          time: string;
          location: string;
          studioName: string;
          creditsUsed?: number;
        }
      );
    },
    sms: async (recipient, data) => {
      if (!recipient.phone) return { success: false, error: 'No phone' };
      return smsService.sendBookingConfirmationSMS(
        recipient.phone,
        data as {
          className: string;
          date: string;
          time: string;
          studioName: string;
        }
      );
    },
    push: async (recipient, data, sandbox) => {
      if (!recipient.deviceToken) return { success: false, error: 'No device token' };
      return pushService.sendBookingConfirmationPush(
        recipient.deviceToken,
        data as {
          className: string;
          date: string;
          time: string;
          bookingId: string;
        },
        sandbox
      );
    },
  },

  waitlist_promotion: {
    email: async (recipient, data) => {
      if (!recipient.email) return { success: false, error: 'No email' };
      return emailService.sendWaitlistPromotion(
        { email: recipient.email, name: recipient.name },
        data as {
          className: string;
          date: string;
          time: string;
          studioName: string;
          expiresIn: string;
          confirmUrl: string;
        }
      );
    },
    sms: async (recipient, data) => {
      if (!recipient.phone) return { success: false, error: 'No phone' };
      return smsService.sendWaitlistPromotionSMS(
        recipient.phone,
        data as {
          className: string;
          date: string;
          time: string;
          expiresIn: string;
        }
      );
    },
    push: async (recipient, data, sandbox) => {
      if (!recipient.deviceToken) return { success: false, error: 'No device token' };
      return pushService.sendWaitlistPromotionPush(
        recipient.deviceToken,
        data as {
          className: string;
          date: string;
          time: string;
          expiresIn: string;
          waitlistId: string;
        },
        sandbox
      );
    },
  },

  class_reminder: {
    sms: async (recipient, data) => {
      if (!recipient.phone) return { success: false, error: 'No phone' };
      return smsService.sendClassReminderSMS(
        recipient.phone,
        data as {
          className: string;
          time: string;
          location: string;
        }
      );
    },
    push: async (recipient, data, sandbox) => {
      if (!recipient.deviceToken) return { success: false, error: 'No device token' };
      return pushService.sendClassReminderPush(
        recipient.deviceToken,
        data as {
          className: string;
          startsIn: string;
          location: string;
          bookingId: string;
        },
        sandbox
      );
    },
  },

  payment_failed: {
    email: async (recipient, data) => {
      if (!recipient.email) return { success: false, error: 'No email' };
      return emailService.sendPaymentFailed(
        { email: recipient.email, name: recipient.name },
        data as {
          amount: string;
          className?: string;
          reason?: string;
          retryUrl: string;
        }
      );
    },
    sms: async (recipient, data) => {
      if (!recipient.phone) return { success: false, error: 'No phone' };
      return smsService.sendPaymentFailedSMS(
        recipient.phone,
        data as { amount: string }
      );
    },
  },

  payout_confirmation: {
    email: async (recipient, data) => {
      if (!recipient.email) return { success: false, error: 'No email' };
      return emailService.sendPayoutConfirmation(
        { email: recipient.email, name: recipient.name },
        data as {
          amount: string;
          period: string;
          arrivalDate: string;
          transactionCount: number;
        }
      );
    },
  },

  new_message: {
    push: async (recipient, data, sandbox) => {
      if (!recipient.deviceToken) return { success: false, error: 'No device token' };
      return pushService.sendNewMessagePush(
        recipient.deviceToken,
        data as {
          senderName: string;
          preview: string;
          conversationId: string;
        },
        sandbox
      );
    },
  },

  class_cancellation: {
    sms: async (recipient, data) => {
      if (!recipient.phone) return { success: false, error: 'No phone' };
      return smsService.sendCancellationSMS(
        recipient.phone,
        data as {
          className: string;
          creditsRefunded?: number;
        }
      );
    },
    push: async (recipient, data, sandbox) => {
      if (!recipient.deviceToken) return { success: false, error: 'No device token' };
      return pushService.sendClassCancellationPush(
        recipient.deviceToken,
        data as {
          className: string;
          date: string;
          reason?: string;
          creditsRefunded?: number;
        },
        sandbox
      );
    },
  },
};

export async function POST(request: NextRequest) {
  try {
    const body = await request.json() as NotificationRequest;
    const { type, recipients, template, data, options } = body;

    // Validate request
    if (!type || !recipients || !template || !data) {
      return NextResponse.json(
        { error: 'Missing required fields: type, recipients, template, data' },
        { status: 400 }
      );
    }

    if (!templateHandlers[template]) {
      return NextResponse.json(
        { error: `Unknown template: ${template}` },
        { status: 400 }
      );
    }

    const handler = templateHandlers[template];
    const results: {
      email: { sent: number; failed: number; errors: string[] };
      sms: { sent: number; failed: number; errors: string[] };
      push: { sent: number; failed: number; errors: string[] };
    } = {
      email: { sent: 0, failed: 0, errors: [] },
      sms: { sent: 0, failed: 0, errors: [] },
      push: { sent: 0, failed: 0, errors: [] },
    };

    // Process each recipient
    for (const recipient of recipients) {
      // Send email if requested and handler exists
      if ((type === 'email' || type === 'all') && handler.email && recipient.email) {
        const result = await handler.email(recipient, data);
        if (result.success) {
          results.email.sent++;
        } else {
          results.email.failed++;
          if (result.error) results.email.errors.push(result.error);
        }
      }

      // Send SMS if requested and handler exists
      if ((type === 'sms' || type === 'all') && handler.sms && recipient.phone) {
        const result = await handler.sms(recipient, data);
        if (result.success) {
          results.sms.sent++;
        } else {
          results.sms.failed++;
          if (result.error) results.sms.errors.push(result.error);
        }
      }

      // Send push if requested and handler exists
      if ((type === 'push' || type === 'all') && handler.push && recipient.deviceToken) {
        const result = await handler.push(recipient, data, options?.sandbox);
        if (result.success) {
          results.push.sent++;
        } else {
          results.push.failed++;
          if (result.error) results.push.errors.push(result.error);
        }
      }
    }

    // Log notification to database for tracking
    const supabase = createServiceClient();
    await supabase.from('notification_logs').insert({
      template,
      type,
      recipient_count: recipients.length,
      results: {
        email: { sent: results.email.sent, failed: results.email.failed },
        sms: { sent: results.sms.sent, failed: results.sms.failed },
        push: { sent: results.push.sent, failed: results.push.failed },
      },
      created_at: new Date().toISOString(),
    }).catch(() => {
      // Silently fail if notification_logs table doesn't exist yet
      console.log('Notification logged (table may not exist yet)');
    });

    return NextResponse.json({
      success: true,
      results,
      summary: {
        totalRecipients: recipients.length,
        emailsSent: results.email.sent,
        smsSent: results.sms.sent,
        pushSent: results.push.sent,
      },
    });

  } catch (error) {
    console.error('Notification API error:', error);
    return NextResponse.json(
      { error: 'Failed to send notifications' },
      { status: 500 }
    );
  }
}

// GET endpoint to check notification service status
export async function GET() {
  return NextResponse.json({
    services: {
      email: {
        configured: !!process.env.SENDGRID_API_KEY,
        provider: 'SendGrid',
      },
      sms: smsService.getTwilioStatus(),
      push: pushService.getAPNsStatus(),
    },
    availableTemplates: Object.keys(templateHandlers),
  });
}
