// Webhook Handlers Edge Function
// Handles Stripe webhooks, external service integrations, and system notifications

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'stripe';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, validateBody, calculateCommission } from '../_shared/utils.ts';
import { StripeWebhookEvent, WebhookEvent } from '../_shared/types.ts';

// Initialize Stripe
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!;
const STRIPE_CONNECT_WEBHOOK_SECRET = Deno.env.get('STRIPE_CONNECT_WEBHOOK_SECRET')!;

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace('/webhooks', '');

  try {
    // Route webhook requests
    switch (path) {
      case '/stripe':
        return handleStripeWebhook(req);
      case '/stripe-connect':
        return handleStripeConnectWebhook(req);
      case '/sendgrid':
        return handleSendGridWebhook(req);
      case '/apple-pay':
        return handleApplePayWebhook(req);
      case '/system':
        return handleSystemWebhook(req);
      default:
        return errorResponse('Webhook endpoint not found', 'NOT_FOUND', 404);
    }
  } catch (error) {
    console.error('Webhook function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleStripeWebhook(req: Request): Promise<Response> {
  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    return errorResponse('Missing Stripe signature', 'MISSING_SIGNATURE', 400);
  }

  const supabase = createSupabaseClient();
  let event: Stripe.Event;

  try {
    const body = await req.text();
    event = stripe.webhooks.constructEvent(body, signature, STRIPE_WEBHOOK_SECRET);
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    return errorResponse('Invalid signature', 'INVALID_SIGNATURE', 400);
  }

  try {
    // Log webhook event
    await supabase
      .from('webhook_events')
      .insert({
        id: event.id,
        type: event.type,
        data: event.data,
        created_at: new Date(event.created * 1000).toISOString(),
        processed: false,
        source: 'stripe',
      });

    console.log(`Processing Stripe webhook: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentIntentSucceeded(event, supabase);
        break;
      
      case 'payment_intent.payment_failed':
        await handlePaymentIntentFailed(event, supabase);
        break;
      
      case 'charge.dispute.created':
        await handleChargeDispute(event, supabase);
        break;
      
      case 'invoice.payment_succeeded':
        await handleInvoicePaymentSucceeded(event, supabase);
        break;
      
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event, supabase);
        break;
      
      case 'account.updated':
        await handleAccountUpdated(event, supabase);
        break;
      
      case 'payout.created':
        await handlePayoutCreated(event, supabase);
        break;
      
      case 'payout.paid':
        await handlePayoutPaid(event, supabase);
        break;
      
      case 'payout.failed':
        await handlePayoutFailed(event, supabase);
        break;
      
      default:
        console.log(`Unhandled webhook event type: ${event.type}`);
    }

    // Mark event as processed
    await supabase
      .from('webhook_events')
      .update({ processed: true, processed_at: new Date().toISOString() })
      .eq('id', event.id);

    return createResponse({ received: true, event_type: event.type });
  } catch (error) {
    console.error(`Error processing webhook ${event.type}:`, error);
    
    // Log error for debugging
    await supabase
      .from('webhook_events')
      .update({ 
        processed: true, 
        error: error.message,
        processed_at: new Date().toISOString() 
      })
      .eq('id', event.id);

    return errorResponse(
      'Webhook processing failed',
      'PROCESSING_ERROR',
      500,
      { event_type: event.type, error: error.message }
    );
  }
}

async function handlePaymentIntentSucceeded(event: Stripe.Event, supabase: any): Promise<void> {
  const paymentIntent = event.data.object as Stripe.PaymentIntent;
  const bookingId = paymentIntent.metadata.booking_id;

  if (!bookingId) {
    console.warn('Payment intent succeeded but no booking_id in metadata');
    return;
  }

  // Update booking status
  const { error: bookingError } = await supabase
    .from('bookings')
    .update({
      status: 'confirmed',
      payment_status: 'succeeded',
      payment_intent_id: paymentIntent.id,
    })
    .eq('id', bookingId);

  if (bookingError) {
    console.error('Failed to update booking status:', bookingError);
    return;
  }

  // Update payment record
  await supabase
    .from('payments')
    .update({
      status: 'succeeded',
      stripe_charge_id: paymentIntent.latest_charge,
    })
    .eq('stripe_payment_intent_id', paymentIntent.id);

  // Get booking details for notifications
  const { data: booking } = await supabase
    .from('bookings')
    .select(`
      *,
      class:classes!inner(
        title,
        instructor:instructor_profiles!inner(
          *,
          user:user_profiles!inner(*)
        )
      ),
      user:user_profiles!inner(*)
    `)
    .eq('id', bookingId)
    .single();

  if (booking) {
    // Update class participant count
    await supabase.rpc('increment_class_participants', {
      class_id: booking.class_id,
      increment_by: booking.attendees.length,
    });

    // Send confirmation notifications
    await sendBookingConfirmationEmail(booking);
    await sendInstructorNotification(booking);
    
    // Create in-app notifications
    await supabase
      .from('notifications')
      .insert([
        {
          user_id: booking.user_id,
          type: 'booking_confirmation',
          title: 'Booking Confirmed!',
          message: `Your booking for "${booking.class.title}" has been confirmed.`,
          data: { booking_id: bookingId, class_id: booking.class_id },
          read: false,
        },
        {
          user_id: booking.class.instructor.user_id,
          type: 'booking_received',
          title: 'New Booking Received',
          message: `${booking.user.first_name} ${booking.user.last_name} booked your class "${booking.class.title}".`,
          data: { booking_id: bookingId, class_id: booking.class_id },
          read: false,
        },
      ]);
  }
}

async function handlePaymentIntentFailed(event: Stripe.Event, supabase: any): Promise<void> {
  const paymentIntent = event.data.object as Stripe.PaymentIntent;
  const bookingId = paymentIntent.metadata.booking_id;

  if (!bookingId) {
    console.warn('Payment intent failed but no booking_id in metadata');
    return;
  }

  // Update booking status
  await supabase
    .from('bookings')
    .update({
      status: 'cancelled',
      payment_status: 'failed',
      notes: `Payment failed: ${paymentIntent.last_payment_error?.message || 'Unknown error'}`,
    })
    .eq('id', bookingId);

  // Update payment record
  await supabase
    .from('payments')
    .update({
      status: 'failed',
      metadata: {
        ...paymentIntent.metadata,
        failure_reason: paymentIntent.last_payment_error?.message,
        failure_code: paymentIntent.last_payment_error?.code,
      },
    })
    .eq('stripe_payment_intent_id', paymentIntent.id);

  // Get booking details for notification
  const { data: booking } = await supabase
    .from('bookings')
    .select(`
      *,
      class:classes!inner(title),
      user:user_profiles!inner(*)
    `)
    .eq('id', bookingId)
    .single();

  if (booking) {
    // Send payment failed notification
    await sendPaymentFailedEmail(booking);
    
    // Create in-app notification
    await supabase
      .from('notifications')
      .insert({
        user_id: booking.user_id,
        type: 'payment_failed',
        title: 'Payment Failed',
        message: `Your payment for "${booking.class.title}" could not be processed. Please try again.`,
        data: { booking_id: bookingId, class_id: booking.class_id },
        read: false,
      });
  }
}

async function handleChargeDispute(event: Stripe.Event, supabase: any): Promise<void> {
  const dispute = event.data.object as Stripe.Dispute;
  const chargeId = dispute.charge as string;

  // Find the booking associated with this charge
  const { data: payment } = await supabase
    .from('payments')
    .select(`
      *,
      booking:bookings!inner(
        *,
        class:classes!inner(
          title,
          instructor:instructor_profiles!inner(
            *,
            user:user_profiles!inner(*)
          )
        )
      )
    `)
    .eq('stripe_charge_id', chargeId)
    .single();

  if (!payment) {
    console.warn('Dispute created but no associated payment found');
    return;
  }

  // Create dispute record
  await supabase
    .from('disputes')
    .insert({
      stripe_dispute_id: dispute.id,
      booking_id: payment.booking_id,
      amount: dispute.amount,
      currency: dispute.currency,
      reason: dispute.reason,
      status: dispute.status,
      evidence_due_by: new Date(dispute.evidence_details.due_by * 1000).toISOString(),
      created_at: new Date(dispute.created * 1000).toISOString(),
    });

  // Notify instructor about dispute
  await supabase
    .from('notifications')
    .insert({
      user_id: payment.booking.class.instructor.user_id,
      type: 'dispute_created',
      title: 'Payment Dispute',
      message: `A dispute has been created for booking "${payment.booking.class.title}". Please provide evidence by ${new Date(dispute.evidence_details.due_by * 1000).toLocaleDateString()}.`,
      data: { 
        dispute_id: dispute.id,
        booking_id: payment.booking_id,
        amount: dispute.amount,
        reason: dispute.reason,
      },
      read: false,
    });

  // Send email notification to support team
  await sendDisputeNotificationEmail(payment.booking, dispute);
}

async function handleAccountUpdated(event: Stripe.Event, supabase: any): Promise<void> {
  const account = event.data.object as Stripe.Account;

  // Update instructor account status
  const newStatus = account.charges_enabled ? 'active' : 
                   account.requirements?.currently_due?.length > 0 ? 'restricted' : 'pending';

  const { error } = await supabase
    .from('instructor_profiles')
    .update({ stripe_account_status: newStatus })
    .eq('stripe_account_id', account.id);

  if (error) {
    console.error('Failed to update instructor account status:', error);
    return;
  }

  // Get instructor details for notification
  const { data: instructor } = await supabase
    .from('instructor_profiles')
    .select(`
      *,
      user:user_profiles!inner(*)
    `)
    .eq('stripe_account_id', account.id)
    .single();

  if (instructor) {
    let notificationMessage = '';
    let notificationType = 'account_updated';

    if (account.charges_enabled && newStatus === 'active') {
      notificationMessage = 'Your payment account is now active! You can start receiving payments from bookings.';
      notificationType = 'account_activated';
    } else if (account.requirements?.currently_due?.length > 0) {
      notificationMessage = `Your payment account requires additional information: ${account.requirements.currently_due.join(', ')}`;
      notificationType = 'account_restricted';
    }

    if (notificationMessage) {
      await supabase
        .from('notifications')
        .insert({
          user_id: instructor.user_id,
          type: notificationType,
          title: 'Payment Account Update',
          message: notificationMessage,
          data: { 
            account_id: account.id,
            charges_enabled: account.charges_enabled,
            requirements: account.requirements?.currently_due || [],
          },
          read: false,
        });
    }
  }
}

async function handlePayoutPaid(event: Stripe.Event, supabase: any): Promise<void> {
  const payout = event.data.object as Stripe.Payout;

  // Update payout status
  await supabase
    .from('instructor_payouts')
    .update({
      status: 'completed',
      processed_at: new Date().toISOString(),
    })
    .eq('stripe_payout_id', payout.id);

  // Get instructor details
  const { data: payoutRecord } = await supabase
    .from('instructor_payouts')
    .select(`
      *,
      instructor:instructor_profiles!inner(
        *,
        user:user_profiles!inner(*)
      )
    `)
    .eq('stripe_payout_id', payout.id)
    .single();

  if (payoutRecord) {
    // Send payout confirmation
    await supabase
      .from('notifications')
      .insert({
        user_id: payoutRecord.instructor.user_id,
        type: 'payout_processed',
        title: 'Payout Completed',
        message: `Your payout of $${(payoutRecord.amount / 100).toFixed(2)} has been processed and is on its way to your account.`,
        data: { 
          payout_id: payoutRecord.id,
          amount: payoutRecord.amount,
          bookings_count: payoutRecord.bookings?.length || 0,
        },
        read: false,
      });
  }
}

async function handleStripeConnectWebhook(req: Request): Promise<Response> {
  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    return errorResponse('Missing Stripe signature', 'MISSING_SIGNATURE', 400);
  }

  const supabase = createSupabaseClient();
  let event: Stripe.Event;

  try {
    const body = await req.text();
    event = stripe.webhooks.constructEvent(body, signature, STRIPE_CONNECT_WEBHOOK_SECRET);
  } catch (error) {
    console.error('Connect webhook signature verification failed:', error);
    return errorResponse('Invalid signature', 'INVALID_SIGNATURE', 400);
  }

  try {
    console.log(`Processing Stripe Connect webhook: ${event.type}`);

    switch (event.type) {
      case 'account.application.authorized':
        await handleConnectAccountAuthorized(event, supabase);
        break;
      
      case 'account.external_account.created':
        await handleExternalAccountCreated(event, supabase);
        break;
      
      case 'person.created':
        await handlePersonCreated(event, supabase);
        break;
      
      default:
        console.log(`Unhandled Connect webhook event type: ${event.type}`);
    }

    return createResponse({ received: true, event_type: event.type });
  } catch (error) {
    console.error(`Error processing Connect webhook ${event.type}:`, error);
    return errorResponse(
      'Connect webhook processing failed',
      'PROCESSING_ERROR',
      500,
      { event_type: event.type, error: error.message }
    );
  }
}

async function sendBookingConfirmationEmail(booking: any): Promise<void> {
  // This would integrate with SendGrid or similar email service
  const emailData = {
    to: booking.user.email,
    subject: `Booking Confirmed: ${booking.class.title}`,
    template: 'booking-confirmation',
    data: {
      customer_name: `${booking.user.first_name} ${booking.user.last_name}`,
      class_title: booking.class.title,
      instructor_name: `${booking.class.instructor.user.first_name} ${booking.class.instructor.user.last_name}`,
      booking_date: booking.class.schedule?.start_date,
      attendees_count: booking.attendees.length,
      total_amount: (booking.amount / 100).toFixed(2),
      confirmation_number: `HB${booking.id.slice(-8).toUpperCase()}`,
    },
  };

  console.log('Sending booking confirmation email:', emailData);
  // TODO: Integrate with actual email service
}

async function sendInstructorNotification(booking: any): Promise<void> {
  const emailData = {
    to: booking.class.instructor.user.email,
    subject: `New Booking: ${booking.class.title}`,
    template: 'instructor-booking-notification',
    data: {
      instructor_name: `${booking.class.instructor.user.first_name} ${booking.class.instructor.user.last_name}`,
      class_title: booking.class.title,
      student_name: `${booking.user.first_name} ${booking.user.last_name}`,
      booking_date: booking.class.schedule?.start_date,
      attendees_count: booking.attendees.length,
      earnings: (booking.instructor_payout / 100).toFixed(2),
    },
  };

  console.log('Sending instructor notification email:', emailData);
  // TODO: Integrate with actual email service
}

async function sendPaymentFailedEmail(booking: any): Promise<void> {
  const emailData = {
    to: booking.user.email,
    subject: `Payment Failed: ${booking.class.title}`,
    template: 'payment-failed',
    data: {
      customer_name: `${booking.user.first_name} ${booking.user.last_name}`,
      class_title: booking.class.title,
      booking_id: booking.id,
      retry_url: `https://hobbyist.app/booking/${booking.id}/retry-payment`,
    },
  };

  console.log('Sending payment failed email:', emailData);
  // TODO: Integrate with actual email service
}

async function sendDisputeNotificationEmail(booking: any, dispute: any): Promise<void> {
  const emailData = {
    to: 'support@hobbyist.app',
    subject: `Payment Dispute: ${booking.class.title}`,
    template: 'dispute-notification',
    data: {
      booking_id: booking.id,
      class_title: booking.class.title,
      instructor_name: `${booking.class.instructor.user.first_name} ${booking.class.instructor.user.last_name}`,
      student_name: `${booking.user.first_name} ${booking.user.last_name}`,
      dispute_amount: (dispute.amount / 100).toFixed(2),
      dispute_reason: dispute.reason,
      evidence_due_date: new Date(dispute.evidence_details.due_by * 1000).toLocaleDateString(),
    },
  };

  console.log('Sending dispute notification email:', emailData);
  // TODO: Integrate with actual email service
}