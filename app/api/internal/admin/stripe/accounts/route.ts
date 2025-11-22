/**
 * Stripe Connect Accounts API - Admin Portal
 *
 * GET /api/internal/admin/stripe/accounts
 * - Returns all Stripe Connected Accounts with status
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { auth } from '@/lib/auth';
import { headers } from 'next/headers';

export async function GET() {
  try {
    // Verify admin authentication
    const session = await auth.api.getSession({ headers: await headers() });

    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const supabase = await createClient();

    // Fetch all Stripe Connect accounts from database
    const { data: accounts, error } = await supabase
      .from('stripe_connect_accounts')
      .select(`
        id,
        studio_id,
        stripe_account_id,
        onboarding_complete,
        verification_status,
        capabilities,
        requirements,
        payouts_enabled,
        charges_enabled,
        created_at,
        updated_at,
        studios!inner (
          id,
          name,
          account_type
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Failed to fetch Stripe accounts:', error);
      return NextResponse.json(
        { error: 'Failed to fetch accounts' },
        { status: 500 }
      );
    }

    // Transform data for frontend
    const transformedAccounts = (accounts || []).map((account: any) => ({
      id: account.id,
      studioId: account.studio_id,
      studioName: account.studios?.name || 'Unknown Studio',
      accountType: account.studios?.account_type || 'studio',
      stripeAccountId: account.stripe_account_id,
      onboardingComplete: account.onboarding_complete || false,
      verificationStatus: account.verification_status || 'unverified',
      capabilities: account.capabilities || {
        card_payments: 'inactive',
        transfers: 'inactive',
      },
      requirements: account.requirements || {
        currently_due: [],
        eventually_due: [],
        past_due: [],
      },
      payoutsEnabled: account.payouts_enabled || false,
      chargesEnabled: account.charges_enabled || false,
      createdAt: account.created_at,
      lastUpdated: account.updated_at,
    }));

    return NextResponse.json({
      accounts: transformedAccounts,
      total: transformedAccounts.length,
    });

  } catch (error) {
    console.error('Stripe accounts API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
