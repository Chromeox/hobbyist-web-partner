import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';


// Lazy initialization to avoid build-time evaluation
const getSupabase = () => {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(supabaseUrl, supabaseServiceRoleKey);
};

type PricingSettingsPayload = {
  studio_id?: string | null;
  commission_rate: number;
  minimum_payout_cents: number;
  payout_frequency: 'daily' | 'weekly' | 'monthly';
};

const DEFAULT_SETTINGS: PricingSettingsPayload = {
  studio_id: null,
  commission_rate: 0.15,
  minimum_payout_cents: 2000,
  payout_frequency: 'weekly',
};

export async function GET(request: Request) {
  try {
    const supabase = getSupabase();
    const { searchParams } = new URL(request.url);
    const studioId = searchParams.get('studioId');

    let query = supabase
      .from('studio_payment_settings')
      .select(
        'studio_id, commission_rate, minimum_payout_cents, payout_frequency, updated_at'
      )
      .limit(1);

    if (studioId) {
      query = query.eq('studio_id', studioId);
    } else {
      query = query.is('studio_id', null);
    }

    const { data, error } = await query.maybeSingle();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    const settings = data ?? { ...DEFAULT_SETTINGS };

    return NextResponse.json({ settings }, { status: 200 });
  } catch (error) {
    console.error('Failed to fetch pricing settings', error);
    return NextResponse.json(
      { error: 'Failed to fetch pricing settings' },
      { status: 500 }
    );
  }
}

export async function PUT(request: Request) {
  try {
    const supabase = getSupabase();
    const payload = await request.json();
    const settings = payload?.settings as PricingSettingsPayload | undefined;
    const studioId: string | null | undefined =
      payload?.studioId ?? settings?.studio_id ?? null;

    if (!settings) {
      return NextResponse.json(
        { error: 'Missing pricing settings payload' },
        { status: 400 }
      );
    }

    const commissionRate = Number(settings.commission_rate);
    const minimumPayout = Number(settings.minimum_payout_cents);
    const frequency = settings.payout_frequency;

    if (!Number.isFinite(commissionRate) || commissionRate < 0 || commissionRate > 1) {
      return NextResponse.json(
        { error: 'commission_rate must be between 0 and 1' },
        { status: 400 }
      );
    }

    if (!Number.isFinite(minimumPayout) || minimumPayout < 0) {
      return NextResponse.json(
        { error: 'minimum_payout_cents must be zero or greater' },
        { status: 400 }
      );
    }

    if (!['daily', 'weekly', 'monthly'].includes(frequency)) {
      return NextResponse.json(
        { error: 'payout_frequency must be one of daily, weekly, monthly' },
        { status: 400 }
      );
    }

    const upsertPayload = {
      studio_id: studioId,
      commission_rate: commissionRate,
      minimum_payout_cents: Math.round(minimumPayout),
      payout_frequency: frequency,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('studio_payment_settings')
      .upsert(upsertPayload, { onConflict: 'studio_id' })
      .select(
        'studio_id, commission_rate, minimum_payout_cents, payout_frequency, updated_at'
      )
      .maybeSingle();

    if (error) {
      throw error;
    }

    return NextResponse.json(
      { settings: data ?? upsertPayload },
      { status: 200 }
    );
  } catch (error) {
    console.error('Failed to update pricing settings', error);
    const message =
      error instanceof Error ? error.message : 'Failed to update pricing settings';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
