import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// This API route serves as a webhook endpoint for Stripe events.
// Stripe sends real-time notifications to this endpoint whenever an event occurs
// (e.g., a payment succeeds, a refund is issued, a dispute is created).

// Initialize Supabase client with service role key for database operations
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

// Stripe configuration
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

// Get webhook secret only when needed
function getWebhookSecret() {
  if (!process.env.STRIPE_WEBHOOK_SECRET) {
    throw new Error('STRIPE_WEBHOOK_SECRET environment variable is not set');
  }
  return process.env.STRIPE_WEBHOOK_SECRET;
}

export async function POST(req: Request) {
  let event: Stripe.Event;

  try {
    // Initialize Stripe and get webhook secret
    const stripe = getStripe();
    const webhookSecret = getWebhookSecret();
    
    // Read the raw request body as text.
    const buf = await req.text();
    // Get the Stripe signature from the request headers.
    const sig = req.headers.get('stripe-signature') as string;

    // Construct the Stripe event using the raw body, signature, and webhook secret.
    // This step verifies the event's authenticity.
    event = stripe.webhooks.constructEvent(buf, sig, webhookSecret);
  } catch (err: any) {
    // If verification fails, log the error and return a 400 response.
    console.error(`Webhook Error: ${err.message}`);
    return new NextResponse(`Webhook Error: ${err.message}`, { status: 400 });
  }

  // --- Handle the Event ---
  // Process different types of Stripe events based on their 'type' property.
  switch (event.type) {
    case 'payment_intent.succeeded':
      // Occurs when a PaymentIntent has successfully completed a payment.
      const paymentIntentSucceeded = event.data.object as Stripe.PaymentIntent;
      console.log(`PaymentIntent success: ${paymentIntentSucceeded.id}`);
      // Update your database: mark the corresponding order/payment as paid.
      // This is crucial for fulfilling goods/services and tracking revenue.
      await supabase.from('payments').update({ status: 'succeeded' }).eq('stripe_pi_id', paymentIntentSucceeded.id);
      break;
    case 'charge.refunded':
      // Occurs when a charge is refunded.
      const chargeRefunded = event.data.object as Stripe.Charge;
      console.log(`Charge refunded: ${chargeRefunded.id}`);
      // Update your database: mark the order/payment as refunded, adjust inventory if applicable.
      await supabase.from('payments').update({ status: 'refunded' }).eq('stripe_charge_id', chargeRefunded.id);
      break;
    case 'charge.dispute.created':
      // Occurs when a customer disputes a charge (e.g., a chargeback).
      const disputeCreated = event.data.object as Stripe.Dispute;
      console.log(`Dispute created: ${disputeCreated.id}`);
      // Take action: notify admin, put the order on hold, prepare to respond to the dispute.
      await supabase.from('payments').update({ status: 'disputed' }).eq('stripe_charge_id', disputeCreated.charge);
      break;
    // Add more cases here to handle other relevant Stripe event types (e.g., customer.created, subscription.updated).
    default:
      // Log any unhandled event types for debugging and future implementation.
      console.log(`Unhandled event type ${event.type}`);
  }

  // Return a 200 response to acknowledge receipt of the event.
  // Stripe expects a 200 response within a certain timeframe to consider the webhook successful.
  return new NextResponse('OK', { status: 200 });
}
