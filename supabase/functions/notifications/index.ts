// Email Notifications & Communication Edge Function
// Handles email notifications, SMS, push notifications, and communication workflows

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody, formatDate, retryWithBackoff } from '../_shared/utils.ts';
import { Notification, User, Booking, Class } from '../_shared/types.ts';

// Email service configuration
const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')!;
const FROM_EMAIL = Deno.env.get('SENDGRID_FROM_EMAIL') || 'notifications@hobbyist.app';
const FROM_NAME = Deno.env.get('SENDGRID_FROM_NAME') || 'Hobbyist';

// SMS configuration (Twilio)
const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID')!;
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN')!;
const TWILIO_PHONE_NUMBER = Deno.env.get('TWILIO_PHONE_NUMBER')!;

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/notifications', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'POST':
        switch (path) {
          case '/send-email':
            return handleSendEmail(req, authHeader);
          case '/send-sms':
            return handleSendSMS(req, authHeader);
          case '/send-push':
            return handleSendPushNotification(req, authHeader);
          case '/send-bulk':
            return handleSendBulkNotifications(req, authHeader);
          case '/booking-reminder':
            return handleBookingReminder(req, authHeader);
          case '/class-update':
            return handleClassUpdateNotification(req, authHeader);
          case '/payment-reminder':
            return handlePaymentReminder(req, authHeader);
          case '/instructor-application':
            return handleInstructorApplicationNotification(req, authHeader);
          case '/system-announcement':
            return handleSystemAnnouncement(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'GET':
        switch (path) {
          case '/templates':
            return handleGetEmailTemplates(req, authHeader);
          case '/delivery-status':
            return handleGetDeliveryStatus(req, authHeader);
          case '/statistics':
            return handleGetNotificationStatistics(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Notifications function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleSendEmail(req: Request, authHeader?: string): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['to', 'subject', 'content']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { to, subject, content, template_id, template_data, reply_to, attachments } = validation.data;
  const supabase = createSupabaseClient();

  try {
    let emailContent = content;
    let emailSubject = subject;

    // Use template if provided
    if (template_id) {
      const template = await getEmailTemplate(template_id, template_data || {});
      if (template) {
        emailContent = template.html;
        emailSubject = template.subject;
      }
    }

    // Send via SendGrid
    const emailResult = await sendEmailViaSendGrid({
      to,
      subject: emailSubject,
      html: emailContent,
      from: { email: FROM_EMAIL, name: FROM_NAME },
      reply_to: reply_to || FROM_EMAIL,
      attachments: attachments || [],
    });

    // Log email to database
    const emailLog = {
      recipient: to,
      subject: emailSubject,
      template_id: template_id || null,
      status: emailResult.success ? 'sent' : 'failed',
      provider: 'sendgrid',
      provider_message_id: emailResult.messageId,
      error_message: emailResult.error || null,
      metadata: {
        template_data,
        user_agent: req.headers.get('user-agent'),
      },
    };

    await supabase
      .from('email_logs')
      .insert(emailLog);

    if (!emailResult.success) {
      return errorResponse(
        emailResult.error || 'Failed to send email',
        'EMAIL_SEND_ERROR',
        500
      );
    }

    return createResponse({
      message_id: emailResult.messageId,
      recipient: to,
      subject: emailSubject,
      status: 'sent',
      provider: 'sendgrid',
      message: 'Email sent successfully',
    }, undefined, 201);
  } catch (error) {
    console.error('Send email error:', error);
    return errorResponse(
      'Failed to send email',
      'EMAIL_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleSendSMS(req: Request, authHeader?: string): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['to', 'message']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { to, message } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Send via Twilio
    const smsResult = await sendSMSViaTwilio({
      to,
      body: message,
      from: TWILIO_PHONE_NUMBER,
    });

    // Log SMS to database
    const smsLog = {
      recipient: to,
      message,
      status: smsResult.success ? 'sent' : 'failed',
      provider: 'twilio',
      provider_message_id: smsResult.messageId,
      error_message: smsResult.error || null,
    };

    await supabase
      .from('sms_logs')
      .insert(smsLog);

    if (!smsResult.success) {
      return errorResponse(
        smsResult.error || 'Failed to send SMS',
        'SMS_SEND_ERROR',
        500
      );
    }

    return createResponse({
      message_id: smsResult.messageId,
      recipient: to,
      status: 'sent',
      provider: 'twilio',
      message: 'SMS sent successfully',
    }, undefined, 201);
  } catch (error) {
    console.error('Send SMS error:', error);
    return errorResponse(
      'Failed to send SMS',
      'SMS_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleBookingReminder(req: Request, authHeader?: string): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['booking_id', 'reminder_type']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { booking_id, reminder_type } = validation.data; // '24_hours', '2_hours', '30_minutes'
  const supabase = createSupabaseClient();

  try {
    // Get booking details
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(
            *,
            user:user_profiles!inner(*)
          )
        ),
        user:user_profiles!inner(*)
      `)
      .eq('id', booking_id)
      .eq('status', 'confirmed')
      .single();

    if (bookingError || !booking) {
      return errorResponse('Booking not found or not confirmed', 'NOT_FOUND', 404);
    }

    // Check user preferences
    const preferences = booking.user.preferences?.notifications || {};
    const results = [];

    // Send email reminder if enabled
    if (preferences.email && preferences.class_reminders) {
      const emailTemplate = await getEmailTemplate('booking-reminder', {
        customer_name: `${booking.user.first_name} ${booking.user.last_name}`,
        class_title: booking.class.title,
        class_date: formatDate(booking.class.schedule?.start_date),
        class_time: booking.class.schedule?.start_time,
        location: booking.class.location?.type === 'online' 
          ? 'Online Class' 
          : booking.class.location?.address?.street,
        instructor_name: `${booking.class.instructor.user.first_name} ${booking.class.instructor.user.last_name}`,
        attendees_count: booking.attendees.length,
        what_to_bring: booking.class.what_to_bring,
        confirmation_number: `HB${booking.id.slice(-8).toUpperCase()}`,
        reminder_type,
      });

      if (emailTemplate) {
        const emailResult = await sendEmailViaSendGrid({
          to: booking.user.email,
          subject: emailTemplate.subject,
          html: emailTemplate.html,
          from: { email: FROM_EMAIL, name: FROM_NAME },
        });

        results.push({
          type: 'email',
          status: emailResult.success ? 'sent' : 'failed',
          error: emailResult.error,
          message_id: emailResult.messageId,
        });
      }
    }

    // Send SMS reminder if enabled
    if (preferences.sms && preferences.class_reminders && booking.user.phone) {
      const smsMessage = `Reminder: Your class "${booking.class.title}" with ${booking.class.instructor.user.first_name} is ${getReminderTimeText(reminder_type)}. See you there!`;
      
      const smsResult = await sendSMSViaTwilio({
        to: booking.user.phone,
        body: smsMessage,
        from: TWILIO_PHONE_NUMBER,
      });

      results.push({
        type: 'sms',
        status: smsResult.success ? 'sent' : 'failed',
        error: smsResult.error,
        message_id: smsResult.messageId,
      });
    }

    // Send push notification if enabled
    if (preferences.push) {
      const pushResult = await sendPushNotification({
        user_id: booking.user_id,
        title: 'Class Reminder',
        body: `Your class "${booking.class.title}" is ${getReminderTimeText(reminder_type)}`,
        data: {
          booking_id: booking.id,
          class_id: booking.class_id,
          type: 'booking_reminder',
        },
      });

      results.push({
        type: 'push',
        status: pushResult.success ? 'sent' : 'failed',
        error: pushResult.error,
      });
    }

    // Create in-app notification
    await supabase
      .from('notifications')
      .insert({
        user_id: booking.user_id,
        type: 'booking_reminder',
        title: 'Class Reminder',
        message: `Your class "${booking.class.title}" is ${getReminderTimeText(reminder_type)}`,
        data: { booking_id: booking.id, class_id: booking.class_id },
        read: false,
      });

    // Log reminder
    await supabase
      .from('notification_logs')
      .insert({
        booking_id: booking.id,
        user_id: booking.user_id,
        notification_type: 'booking_reminder',
        reminder_type,
        channels_sent: results.map(r => r.type),
        success_count: results.filter(r => r.status === 'sent').length,
        failure_count: results.filter(r => r.status === 'failed').length,
      });

    return createResponse({
      booking_id: booking.id,
      reminder_type,
      notifications_sent: results.filter(r => r.status === 'sent').length,
      notifications_failed: results.filter(r => r.status === 'failed').length,
      results,
      message: 'Booking reminder sent successfully',
    });
  } catch (error) {
    console.error('Booking reminder error:', error);
    return errorResponse(
      'Failed to send booking reminder',
      'REMINDER_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleClassUpdateNotification(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['class_id', 'update_type', 'message']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { class_id, update_type, message, changes } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify instructor ownership
    const { data: classData, error: classError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(user_id),
        bookings!inner(
          *,
          user:user_profiles!inner(*)
        )
      `)
      .eq('id', class_id)
      .single();

    if (classError || classData.instructor.user_id !== userId) {
      return errorResponse('Class not found or access denied', 'FORBIDDEN', 403);
    }

    const confirmedBookings = classData.bookings.filter((b: any) => b.status === 'confirmed');
    const notificationResults = [];

    for (const booking of confirmedBookings) {
      const preferences = booking.user.preferences?.notifications || {};
      
      // Send email notification if enabled
      if (preferences.email && preferences.instructor_updates) {
        const emailTemplate = await getEmailTemplate('class-update', {
          customer_name: `${booking.user.first_name} ${booking.user.last_name}`,
          class_title: classData.title,
          instructor_name: `${classData.instructor.user.first_name} ${classData.instructor.user.last_name}`,
          update_type: update_type.replace('_', ' ').toUpperCase(),
          message,
          changes: changes || {},
          class_date: formatDate(classData.schedule?.start_date),
        });

        if (emailTemplate) {
          const emailResult = await sendEmailViaSendGrid({
            to: booking.user.email,
            subject: emailTemplate.subject,
            html: emailTemplate.html,
            from: { email: FROM_EMAIL, name: FROM_NAME },
          });

          notificationResults.push({
            user_id: booking.user_id,
            type: 'email',
            status: emailResult.success ? 'sent' : 'failed',
            error: emailResult.error,
          });
        }
      }

      // Create in-app notification
      await supabase
        .from('notifications')
        .insert({
          user_id: booking.user_id,
          type: 'class_update',
          title: `Class Update: ${classData.title}`,
          message,
          data: { 
            class_id: class_id,
            booking_id: booking.id,
            update_type,
            changes: changes || {},
          },
          read: false,
        });

      notificationResults.push({
        user_id: booking.user_id,
        type: 'in_app',
        status: 'sent',
      });
    }

    // Log class update notification
    await supabase
      .from('notification_logs')
      .insert({
        class_id: class_id,
        instructor_id: userId,
        notification_type: 'class_update',
        update_type,
        recipients_count: confirmedBookings.length,
        success_count: notificationResults.filter(r => r.status === 'sent').length,
        failure_count: notificationResults.filter(r => r.status === 'failed').length,
        metadata: { message, changes },
      });

    return createResponse({
      class_id: class_id,
      update_type,
      recipients_notified: confirmedBookings.length,
      notifications_sent: notificationResults.filter(r => r.status === 'sent').length,
      notifications_failed: notificationResults.filter(r => r.status === 'failed').length,
      message: 'Class update notifications sent successfully',
    });
  } catch (error) {
    console.error('Class update notification error:', error);
    return errorResponse(
      'Failed to send class update notifications',
      'UPDATE_NOTIFICATION_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Email service helpers
async function sendEmailViaSendGrid(emailData: {
  to: string;
  subject: string;
  html: string;
  from: { email: string; name: string };
  reply_to?: string;
  attachments?: any[];
}): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    const response = await retryWithBackoff(async () => {
      return await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SENDGRID_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          personalizations: [{
            to: [{ email: emailData.to }],
            subject: emailData.subject,
          }],
          from: emailData.from,
          reply_to: emailData.reply_to ? { email: emailData.reply_to } : undefined,
          content: [{
            type: 'text/html',
            value: emailData.html,
          }],
          attachments: emailData.attachments,
        }),
      });
    });

    if (response.ok) {
      const messageId = response.headers.get('x-message-id');
      return { success: true, messageId: messageId || undefined };
    } else {
      const errorData = await response.text();
      return { success: false, error: `SendGrid error: ${errorData}` };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function sendSMSViaTwilio(smsData: {
  to: string;
  body: string;
  from: string;
}): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    const auth = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
    
    const response = await retryWithBackoff(async () => {
      return await fetch(`https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: smsData.to,
          From: smsData.from,
          Body: smsData.body,
        }),
      });
    });

    if (response.ok) {
      const result = await response.json();
      return { success: true, messageId: result.sid };
    } else {
      const errorData = await response.text();
      return { success: false, error: `Twilio error: ${errorData}` };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function sendPushNotification(pushData: {
  user_id: string;
  title: string;
  body: string;
  data?: any;
}): Promise<{ success: boolean; error?: string }> {
  // This would integrate with Firebase Cloud Messaging or similar
  console.log('Sending push notification:', pushData);
  
  // TODO: Implement actual push notification sending
  // For now, we'll simulate success
  return { success: true };
}

async function getEmailTemplate(templateId: string, data: any): Promise<{ subject: string; html: string } | null> {
  // Email templates - in production, these would be stored in database or external service
  const templates: Record<string, (data: any) => { subject: string; html: string }> = {
    'booking-confirmation': (data) => ({
      subject: `Booking Confirmed: ${data.class_title}`,
      html: `
        <h2>Booking Confirmed!</h2>
        <p>Hi ${data.customer_name},</p>
        <p>Your booking for <strong>${data.class_title}</strong> has been confirmed!</p>
        <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
          <h3>Class Details:</h3>
          <p><strong>Instructor:</strong> ${data.instructor_name}</p>
          <p><strong>Date & Time:</strong> ${data.booking_date} at ${data.class_time || 'TBD'}</p>
          <p><strong>Attendees:</strong> ${data.attendees_count}</p>
          <p><strong>Total Paid:</strong> $${data.total_amount}</p>
          <p><strong>Confirmation #:</strong> ${data.confirmation_number}</p>
        </div>
        <p>We're excited to see you there!</p>
        <p>Best regards,<br>The Hobbyist Team</p>
      `,
    }),
    'booking-reminder': (data) => ({
      subject: `Reminder: ${data.class_title} is ${getReminderTimeText(data.reminder_type)}`,
      html: `
        <h2>Class Reminder</h2>
        <p>Hi ${data.customer_name},</p>
        <p>This is a friendly reminder that your class <strong>${data.class_title}</strong> is ${getReminderTimeText(data.reminder_type)}!</p>
        <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
          <h3>Class Details:</h3>
          <p><strong>Class:</strong> ${data.class_title}</p>
          <p><strong>Instructor:</strong> ${data.instructor_name}</p>
          <p><strong>Date & Time:</strong> ${data.class_date} at ${data.class_time}</p>
          <p><strong>Location:</strong> ${data.location}</p>
          ${data.what_to_bring ? `<p><strong>What to bring:</strong> ${data.what_to_bring.join(', ')}</p>` : ''}
        </div>
        <p>See you soon!</p>
        <p>Best regards,<br>The Hobbyist Team</p>
      `,
    }),
    'class-update': (data) => ({
      subject: `Class Update: ${data.class_title}`,
      html: `
        <h2>Class Update</h2>
        <p>Hi ${data.customer_name},</p>
        <p>${data.instructor_name} has sent an update about your upcoming class <strong>${data.class_title}</strong>:</p>
        <div style="background: #f0f8ff; padding: 20px; margin: 20px 0; border-left: 4px solid #007cba;">
          <p>${data.message}</p>
        </div>
        ${data.changes && Object.keys(data.changes).length > 0 ? `
          <div style="background: #fff3cd; padding: 20px; margin: 20px 0;">
            <h3>Changes:</h3>
            ${Object.entries(data.changes).map(([key, value]) => `<p><strong>${key}:</strong> ${value}</p>`).join('')}
          </div>
        ` : ''}
        <p>If you have any questions, please don't hesitate to reach out.</p>
        <p>Best regards,<br>The Hobbyist Team</p>
      `,
    }),
  };

  const template = templates[templateId];
  return template ? template(data) : null;
}

function getReminderTimeText(reminderType: string): string {
  switch (reminderType) {
    case '24_hours':
      return 'tomorrow';
    case '2_hours':
      return 'in 2 hours';
    case '30_minutes':
      return 'in 30 minutes';
    default:
      return 'soon';
  }
}