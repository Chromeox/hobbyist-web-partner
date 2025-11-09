import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';

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

  // Update account status in database
  // In production, you would update your database with the new account status
  const accountData = {
    stripe_account_id: account.id,
    charges_enabled: account.charges_enabled,
    payouts_enabled: account.payouts_enabled,
    details_submitted: account.details_submitted,
    requirements_pending: account.requirements?.currently_due?.length || 0,
    updated_at: new Date().toISOString()
  };

  // TODO: Update database record
  console.log('Account data to update:', accountData);
}

async function handleAccountDeauthorized(deauthorization: any) {
  console.log('Account deauthorized:', deauthorization.account);

  // Mark account as disconnected in database
  // TODO: Update database to mark account as disconnected
}

async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  console.log('Payment succeeded:', {
    id: paymentIntent.id,
    amount: paymentIntent.amount,
    currency: paymentIntent.currency,
    customer: paymentIntent.customer
  });

  // Record successful payment in database
  const paymentData = {
    stripe_payment_intent_id: paymentIntent.id,
    amount: paymentIntent.amount,
    currency: paymentIntent.currency,
    status: 'succeeded',
    customer_id: paymentIntent.customer,
    created_at: new Date(paymentIntent.created * 1000).toISOString()
  };

  // TODO: Save payment record to database
  console.log('Payment data to save:', paymentData);
}

async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent) {
  console.log('Payment failed:', {
    id: paymentIntent.id,
    amount: paymentIntent.amount,
    last_payment_error: paymentIntent.last_payment_error
  });

  // Record failed payment and potentially notify customer
  // TODO: Update database and send notification
}

async function handleTransferCreated(transfer: Stripe.Transfer) {
  console.log('Transfer created:', {
    id: transfer.id,
    amount: transfer.amount,
    destination: transfer.destination,
    description: transfer.description
  });

  // Record transfer to studio account
  const transferData = {
    stripe_transfer_id: transfer.id,
    amount: transfer.amount,
    destination_account: transfer.destination,
    description: transfer.description,
    created_at: new Date(transfer.created * 1000).toISOString()
  };

  // TODO: Save transfer record to database
  console.log('Transfer data to save:', transferData);
}

async function handlePayoutPaid(payout: Stripe.Payout) {
  console.log('Payout paid:', {
    id: payout.id,
    amount: payout.amount,
    arrival_date: payout.arrival_date,
    bank_account: payout.destination
  });

  // Update payout status in database
  // TODO: Mark payout as completed in database
}

async function handlePayoutFailed(payout: Stripe.Payout) {
  console.log('Payout failed:', {
    id: payout.id,
    amount: payout.amount,
    failure_code: payout.failure_code,
    failure_message: payout.failure_message
  });

  // Notify studio of failed payout
  // TODO: Update database and send notification
}
