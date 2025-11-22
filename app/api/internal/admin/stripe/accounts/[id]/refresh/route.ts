/**
 * Refresh Single Stripe Account API - Admin Portal
 *
 * POST /api/internal/admin/stripe/accounts/[id]/refresh
 * - Refreshes status of a specific Stripe Connected Account from Stripe API
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { auth } from '@/lib/auth';
import { headers } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-11-20.acacia',
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // Verify admin authentication
    const session = await auth.api.getSession({ headers: await headers() });

    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const { id } = await params;
    const supabase = await createClient();

    // Fetch account from database
    const { data: account, error: fetchError } = await supabase
      .from('stripe_connect_accounts')
      .select('id, stripe_account_id')
      .eq('id', id)
      .single();

    if (fetchError || !account) {
      return NextResponse.json(
        { error: 'Account not found' },
        { status: 404 }
      );
    }

    // Fetch latest data from Stripe
    const stripeAccount = await stripe.accounts.retrieve(
      account.stripe_account_id
    );

    // Update database with latest information
    const { error: updateError } = await supabase
      .from('stripe_connect_accounts')
      .update({
        onboarding_complete: stripeAccount.details_submitted || false,
        verification_status: getVerificationStatus(stripeAccount),
        capabilities: {
          card_payments: stripeAccount.capabilities?.card_payments || 'inactive',
          transfers: stripeAccount.capabilities?.transfers || 'inactive',
        },
        requirements: {
          currently_due: stripeAccount.requirements?.currently_due || [],
          eventually_due: stripeAccount.requirements?.eventually_due || [],
          past_due: stripeAccount.requirements?.past_due || [],
        },
        payouts_enabled: stripeAccount.payouts_enabled || false,
        charges_enabled: stripeAccount.charges_enabled || false,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id);

    if (updateError) {
      console.error('Failed to update account:', updateError);
      return NextResponse.json(
        { error: 'Failed to update account' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      message: 'Account refreshed successfully',
      accountId: id,
    });

  } catch (error: any) {
    console.error('Refresh account error:', error);

    // Handle Stripe-specific errors
    if (error.type === 'StripeInvalidRequestError') {
      return NextResponse.json(
        { error: 'Invalid Stripe account ID' },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// Helper to determine verification status
function getVerificationStatus(account: Stripe.Account): string {
  if (account.requirements?.disabled_reason) {
    return 'restricted';
  }

  if (
    account.capabilities?.card_payments === 'active' &&
    account.capabilities?.transfers === 'active' &&
    account.details_submitted
  ) {
    return 'verified';
  }

  if (account.requirements?.currently_due && account.requirements.currently_due.length > 0) {
    return 'pending';
  }

  return 'unverified';
}
