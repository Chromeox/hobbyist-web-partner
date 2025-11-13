import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { createServiceClient } from '@/lib/supabase/server';

// Force rebuild: 2025-11-13-07:02 UTC
const STRIPE_API_VERSION: Stripe.LatestApiVersion = '2025-08-27.basil';

// Initialize Stripe client only when needed
function getStripe() {
  if (!process.env.STRIPE_SECRET_KEY) {
    throw new Error('STRIPE_SECRET_KEY environment variable is not set');
  }
  return new Stripe(process.env.STRIPE_SECRET_KEY, {
    apiVersion: STRIPE_API_VERSION,
  });
}

function getEndpointSecret() {
  if (!process.env.STRIPE_WEBHOOK_SECRET) {
    throw new Error('STRIPE_WEBHOOK_SECRET environment variable is not set');
  }
  return process.env.STRIPE_WEBHOOK_SECRET;
}

// Helper to get Supabase service client for database operations
function getSupabaseServiceClient() {
  return createServiceClient();
}

export async function POST(request: NextRequest) {
  try {
    const stripe = getStripe();
    const endpointSecret = getEndpointSecret();
    
    const body = await request.text();
    const sig = request.headers.get('stripe-signature')!;

    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(body, sig, endpointSecret);
    } catch (err: any) {
      console.error('Webhook signature verification failed:', err.message);
      return NextResponse.json({ error: 'Webhook signature verification failed' }, { status: 400 });
    }

  // Handle the event
  try {
    switch (event.type) {
      case 'account.updated':
        await handleAccountUpdated(event.data.object as Stripe.Account);
        break;

      case 'account.application.deauthorized':
        await handleAccountDeauthorized(event.data.object as any);
        break;

      case 'payment_intent.succeeded':
        await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
        break;

      case 'payment_intent.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
        break;

      case 'transfer.created':
        await handleTransferCreated(event.data.object as Stripe.Transfer);
        break;

      case 'payout.paid':
        await handlePayoutPaid(event.data.object as Stripe.Payout);
        break;

      case 'payout.failed':
        await handlePayoutFailed(event.data.object as Stripe.Payout);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return NextResponse.json({ received: true });

  } catch (error) {
    console.error('Webhook handler error:', error);
    return NextResponse.json(
      { error: 'Webhook handler failed' },
      { status: 500 }
    );
  }
  } catch (err: any) {
    console.error('Stripe initialization error:', err.message);
    return NextResponse.json({ error: 'Stripe configuration error' }, { status: 500 });
  }
}

async function handleAccountUpdated(account: Stripe.Account) {
  console.log('Account updated:', {
    id: account.id,
    charges_enabled: account.charges_enabled,
    payouts_enabled: account.payouts_enabled,
    details_submitted: account.details_submitted
  });

  try {
    const supabase = getSupabaseServiceClient();

    // Update Stripe account status in database using the helper function
    const { data, error } = await supabase.rpc('upsert_stripe_account_status', {
      p_stripe_account_id: account.id,
      p_charges_enabled: account.charges_enabled || false,
      p_payouts_enabled: account.payouts_enabled || false,
      p_details_submitted: account.details_submitted || false,
      p_requirements_due: account.requirements?.currently_due || [],
      p_disabled_reason: account.requirements?.disabled_reason || null
    });

    if (error) {
      console.error('Failed to update account status:', error);
      throw error;
    }

    console.log('✅ Account status updated in database:', data);

    // Also update the studio_onboarding_submissions table
    const { error: updateError } = await supabase
      .from('studio_onboarding_submissions')
      .update({
        stripe_onboarding_complete: account.details_submitted && account.charges_enabled,
        updated_at: new Date().toISOString()
      })
      .eq('stripe_account_id', account.id);

    if (updateError) {
      console.error('Failed to update studio submission:', updateError);
    }

  } catch (error) {
    console.error('Error in handleAccountUpdated:', error);
    throw error;
  }
}

async function handleAccountDeauthorized(deauthorization: any) {
  console.log('Account deauthorized:', deauthorization.account);

  try {
    const supabase = getSupabaseServiceClient();

    // Mark account as disconnected
    const { error } = await supabase
      .from('stripe_account_statuses')
      .update({
        is_active: false,
        deauthorized_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('stripe_account_id', deauthorization.account);

    if (error) {
      console.error('Failed to mark account as deauthorized:', error);
      throw error;
    }

    console.log('✅ Account marked as deauthorized in database');

    // Also mark in studio_onboarding_submissions
    const { error: updateError } = await supabase
      .from('studio_onboarding_submissions')
      .update({
        stripe_onboarding_complete: false,
        updated_at: new Date().toISOString()
      })
      .eq('stripe_account_id', deauthorization.account);

    if (updateError) {
      console.error('Failed to update studio submission:', updateError);
    }

  } catch (error) {
    console.error('Error in handleAccountDeauthorized:', error);
    throw error;
  }
}

async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  console.log('🎯 [NEW DEPLOYMENT] Payment succeeded:', {
    id: paymentIntent.id,
    amount: paymentIntent.amount,
    currency: paymentIntent.currency,
    customer: paymentIntent.customer
  });

  try {
    const supabase = getSupabaseServiceClient();

    // Extract booking_id from metadata if available
    const bookingId = paymentIntent.metadata?.booking_id || null;
    const userId = paymentIntent.metadata?.user_id || null;

    // Record payment event using helper function (with idempotency)
    const { data, error } = await supabase.rpc('record_stripe_payment_event', {
      p_stripe_event_id: `pi_succeeded_${paymentIntent.id}`,
      p_payment_intent_id: paymentIntent.id,
      p_event_type: 'payment_intent.succeeded',
      p_amount: paymentIntent.amount,
      p_currency: paymentIntent.currency,
      p_status: 'succeeded',
      p_customer_id: typeof paymentIntent.customer === 'string' ? paymentIntent.customer : null,
      p_user_id: userId
    });

    if (error) {
      console.error('Failed to record payment event:', error);
      throw error;
    }

    console.log('✅ Payment event recorded in database');

    // Update booking status if we have a booking_id
    if (bookingId) {
      const { error: bookingError } = await supabase
        .from('bookings')
        .update({
          status: 'confirmed',
          payment_method: 'stripe',
          amount_paid: paymentIntent.amount / 100, // Convert cents to dollars
          updated_at: new Date().toISOString()
        })
        .eq('id', bookingId);

      if (bookingError) {
        console.error('Failed to update booking:', bookingError);
      } else {
        console.log('✅ Booking confirmed:', bookingId);
      }
    }

    // TODO: Send booking confirmation email/notification

  } catch (error) {
    console.error('Error in handlePaymentSucceeded:', error);
    throw error;
  }
}

async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent) {
  console.log('Payment failed:', {
    id: paymentIntent.id,
    amount: paymentIntent.amount,
    last_payment_error: paymentIntent.last_payment_error
  });

  try {
    const supabase = getSupabaseServiceClient();

    const bookingId = paymentIntent.metadata?.booking_id || null;
    const userId = paymentIntent.metadata?.user_id || null;

    // Record failed payment event
    const { data, error } = await supabase.rpc('record_stripe_payment_event', {
      p_stripe_event_id: `pi_failed_${paymentIntent.id}`,
      p_payment_intent_id: paymentIntent.id,
      p_event_type: 'payment_intent.payment_failed',
      p_amount: paymentIntent.amount,
      p_currency: paymentIntent.currency,
      p_status: 'failed',
      p_customer_id: typeof paymentIntent.customer === 'string' ? paymentIntent.customer : null,
      p_user_id: userId,
      p_error_code: paymentIntent.last_payment_error?.code || null,
      p_error_message: paymentIntent.last_payment_error?.message || null
    });

    if (error) {
      console.error('Failed to record payment failure:', error);
      throw error;
    }

    console.log('✅ Payment failure recorded in database');

    // Update booking status if applicable
    if (bookingId) {
      const { error: bookingError } = await supabase
        .from('bookings')
        .update({
          status: 'payment_failed',
          updated_at: new Date().toISOString()
        })
        .eq('id', bookingId);

      if (bookingError) {
        console.error('Failed to update booking:', bookingError);
      }
    }

    // TODO: Send payment failure notification to customer

  } catch (error) {
    console.error('Error in handlePaymentFailed:', error);
    throw error;
  }
}

async function handleTransferCreated(transfer: Stripe.Transfer) {
  console.log('Transfer created:', {
    id: transfer.id,
    amount: transfer.amount,
    destination: transfer.destination,
    description: transfer.description
  });

  try {
    const supabase = getSupabaseServiceClient();

    // Extract metadata if available
    const bookingId = transfer.metadata?.booking_id || null;
    const studioId = transfer.metadata?.studio_id || null;

    // Record transfer using helper function (with idempotency)
    const { data, error } = await supabase.rpc('record_stripe_transfer', {
      p_stripe_transfer_id: transfer.id,
      p_destination_account: typeof transfer.destination === 'string' ? transfer.destination : transfer.destination.id,
      p_amount: transfer.amount,
      p_currency: transfer.currency,
      p_description: transfer.description || null,
      p_studio_id: studioId,
      p_booking_id: bookingId
    });

    if (error) {
      console.error('Failed to record transfer:', error);
      throw error;
    }

    console.log('✅ Transfer recorded in database');

    // Update revenue_shares if we have the booking
    if (bookingId) {
      const { error: revenueError } = await supabase
        .from('revenue_shares')
        .update({
          platform_transfer_id: transfer.id,
          platform_transfer_status: 'created',
          updated_at: new Date().toISOString()
        })
        .eq('booking_id', bookingId);

      if (revenueError) {
        console.error('Failed to update revenue share:', revenueError);
      }
    }

  } catch (error) {
    console.error('Error in handleTransferCreated:', error);
    throw error;
  }
}

async function handlePayoutPaid(payout: Stripe.Payout) {
  console.log('Payout paid:', {
    id: payout.id,
    amount: payout.amount,
    arrival_date: payout.arrival_date,
    bank_account: payout.destination
  });

  try {
    const supabase = getSupabaseServiceClient();

    // Update payout status using helper function
    const { data, error } = await supabase.rpc('update_payout_status', {
      p_stripe_payout_id: payout.id,
      p_status: 'paid',
      p_arrival_date: payout.arrival_date ? new Date(payout.arrival_date * 1000).toISOString() : null
    });

    if (error) {
      console.error('Failed to update payout status:', error);
      throw error;
    }

    console.log('✅ Payout marked as paid in database');

    // TODO: Send payout confirmation notification to studio

  } catch (error) {
    console.error('Error in handlePayoutPaid:', error);
    throw error;
  }
}

async function handlePayoutFailed(payout: Stripe.Payout) {
  console.log('Payout failed:', {
    id: payout.id,
    amount: payout.amount,
    failure_code: payout.failure_code,
    failure_message: payout.failure_message
  });

  try {
    const supabase = getSupabaseServiceClient();

    // Update payout status with failure details
    const { data, error } = await supabase.rpc('update_payout_status', {
      p_stripe_payout_id: payout.id,
      p_status: 'failed',
      p_arrival_date: null,
      p_failure_code: payout.failure_code || null,
      p_failure_message: payout.failure_message || null
    });

    if (error) {
      console.error('Failed to record payout failure:', error);
      throw error;
    }

    console.log('✅ Payout failure recorded in database');

    // TODO: Send urgent notification to studio about failed payout

  } catch (error) {
    console.error('Error in handlePayoutFailed:', error);
    throw error;
  }
}
