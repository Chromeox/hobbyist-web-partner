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

export async function POST(request: NextRequest) {
  try {
    const stripe = getStripe();
    
    const body = await request.json();
    const {
      businessName,
      businessEmail,
      country = 'US',
      type = 'express'
    } = body;

    // Create Stripe Express account
    const account = await stripe.accounts.create({
      type: 'express',
      country: country,
      email: businessEmail,
      business_profile: {
        name: businessName,
        support_email: businessEmail,
        product_description: 'Fitness and wellness class bookings',
      },
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
    });

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${process.env.NEXT_PUBLIC_APP_URL}/onboarding?refresh=stripe`,
      return_url: `${process.env.NEXT_PUBLIC_APP_URL}/api/stripe/connect/complete?account_id=${account.id}`,
      type: 'account_onboarding',
    });

    return NextResponse.json({
      success: true,
      account_id: account.id,
      onboarding_url: accountLink.url
    });

  } catch (error: any) {
    console.error('Stripe Connect account creation error:', error);

    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Failed to create Stripe account'
      },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const stripe = getStripe();
    
    const { searchParams } = new URL(request.url);
    const accountId = searchParams.get('account_id');

    if (!accountId) {
      return NextResponse.json(
        { error: 'Account ID is required' },
        { status: 400 }
      );
    }

    // Retrieve account details
    const account = await stripe.accounts.retrieve(accountId);

    return NextResponse.json({
      success: true,
      account: {
        id: account.id,
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        details_submitted: account.details_submitted,
        requirements: account.requirements,
        business_profile: account.business_profile,
      }
    });

  } catch (error: any) {
    console.error('Stripe account retrieval error:', error);

    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Failed to retrieve account'
      },
      { status: 500 }
    );
  }
}
