/**
 * Refresh All Stripe Accounts API - Admin Portal
 *
 * POST /api/internal/admin/stripe/accounts/refresh-all
 * - Refreshes status of all Stripe Connected Accounts from Stripe API
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { auth } from '@/lib/auth';
import { headers } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-11-20.acacia',
});

export async function POST() {
  try {
    // Verify admin authentication
    const session = await auth.api.getSession({ headers: await headers() });

    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const supabase = await createClient();

    // Fetch all Stripe account IDs
    const { data: accounts, error: fetchError } = await supabase
      .from('stripe_connect_accounts')
      .select('id, stripe_account_id');

    if (fetchError) {
      console.error('Failed to fetch accounts for refresh:', fetchError);
      return NextResponse.json(
        { error: 'Failed to fetch accounts' },
        { status: 500 }
      );
    }

    if (!accounts || accounts.length === 0) {
      return NextResponse.json({
        message: 'No accounts to refresh',
        updated: 0,
      });
    }

    // Refresh each account from Stripe API
    const updates = await Promise.allSettled(
      accounts.map(async (account) => {
        try {
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
            .eq('id', account.id);

          if (updateError) {
            console.error(`Failed to update account ${account.id}:`, updateError);
            throw updateError;
          }

          return { success: true, accountId: account.id };
        } catch (error) {
          console.error(`Failed to refresh account ${account.stripe_account_id}:`, error);
          return { success: false, accountId: account.id, error };
        }
      })
    );

    const successCount = updates.filter(
      (result) => result.status === 'fulfilled' && result.value.success
    ).length;

    return NextResponse.json({
      message: 'Accounts refreshed',
      total: accounts.length,
      updated: successCount,
      failed: accounts.length - successCount,
    });

  } catch (error) {
    console.error('Refresh all accounts error:', error);
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
