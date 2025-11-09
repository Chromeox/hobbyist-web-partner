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

export async function GET(request: NextRequest) {
  try {
    const stripe = getStripe();
    
    const { searchParams } = new URL(request.url);
    const accountId = searchParams.get('account_id');

    if (!accountId) {
      console.error('No account ID provided in Stripe Connect completion');
      return NextResponse.redirect(
        new URL('/onboarding?error=stripe_no_account', request.url)
      );
    }

    console.log('Stripe Connect completion for account:', accountId);

    try {
      // Retrieve the account to check its status
      const account = await stripe.accounts.retrieve(accountId);

      console.log('Stripe account status:', {
        id: account.id,
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        details_submitted: account.details_submitted
      });

      // Store the account information (in production, save to database)
      const accountData = {
        stripe_account_id: account.id,
        business_name: account.business_profile?.name || 'Studio',
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        details_submitted: account.details_submitted,
        requirements_pending: account.requirements?.currently_due?.length || 0,
        connected_at: new Date().toISOString()
      };

      console.log('Stripe Connect integration successful:', accountData);

      // Check if account is ready for payments
      const isReady = account.charges_enabled && account.details_submitted;
      const status = isReady ? 'active' : 'pending';

      // Redirect back to onboarding with success data
      const successParams = new URLSearchParams({
        success: 'stripe_connected',
        account_id: account.id,
        status: status,
        business_name: accountData.business_name
      });

      return NextResponse.redirect(
        new URL(`/onboarding?${successParams.toString()}`, request.url)
      );

    } catch (stripeError) {
      console.error('Stripe account retrieval error:', stripeError);
      throw new Error('Failed to verify Stripe account');
    }

  } catch (error) {
    console.error('Stripe Connect completion error:', error);

    // Redirect with error message
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return NextResponse.redirect(
      new URL(`/onboarding?error=stripe_completion_failed&message=${encodeURIComponent(errorMessage)}`, request.url)
    );
  }
}

// Handle preflight OPTIONS requests
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
