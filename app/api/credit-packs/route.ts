import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';


const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

type DbCreditPack = {
  id: string;
  studio_id?: string | null;
  name: string;
  description?: string | null;
  credit_amount: number;
  price_cents: number;
  bonus_credits?: number | null;
  is_active: boolean;
  display_order?: number | null;
  created_at?: string;
  updated_at?: string;
};

const mapCreditPack = (pack: DbCreditPack) => {
  const bonus = pack.bonus_credits ?? 0;
  const baseCredits = pack.credit_amount ?? 0;
  const totalCredits = baseCredits + bonus;
  const priceCents = pack.price_cents ?? 0;
  const savings =
    baseCredits > 0 ? Math.round((bonus / baseCredits) * 100) : 0;

  return {
    id: pack.id,
    studio_id: pack.studio_id ?? null,
    name: pack.name,
    description: pack.description ?? '',
    credit_amount: baseCredits,
    price_cents: priceCents,
    bonus_credits: bonus,
    is_active: Boolean(pack.is_active),
    display_order: pack.display_order ?? 0,
    created_at: pack.created_at,
    updated_at: pack.updated_at,
    price_formatted: (priceCents / 100).toFixed(2),
    total_credits: totalCredits,
    savings_percentage: savings,
  };
};

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const studioId = searchParams.get('studioId');

    let query = supabase
      .from('credit_packs')
      .select(
        'id, studio_id, name, description, credit_amount, price_cents, bonus_credits, is_active, display_order, created_at, updated_at'
      )
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: true });

    if (studioId) {
      query = query.eq('studio_id', studioId);
    }

    const { data, error } = await query;

    if (error) {
      throw error;
    }

    const packs = (data ?? []).map(mapCreditPack);

    return NextResponse.json({ creditPacks: packs }, { status: 200 });
  } catch (error) {
    console.error('Failed to fetch credit packs', error);
    return NextResponse.json(
      { error: 'Failed to fetch credit packs' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const payload = await request.json();
    const pack = payload?.creditPack;

    if (!pack || typeof pack !== 'object') {
      return NextResponse.json(
        { error: 'Missing credit pack payload' },
        { status: 400 }
      );
    }

    const requiredFields: Array<keyof typeof pack> = [
      'name',
      'credit_amount',
      'price_cents',
    ];

    for (const field of requiredFields) {
      if (
        pack[field] === undefined ||
        pack[field] === null ||
        (typeof pack[field] === 'string' && !pack[field].trim())
      ) {
        const fieldName = String(field);
        return NextResponse.json(
          { error: `Missing required field: ${fieldName}` },
          { status: 400 }
        );
      }
    }

    const bonus = Number.isFinite(pack.bonus_credits)
      ? Number(pack.bonus_credits)
      : 0;

    const insertPayload = {
      studio_id: pack.studio_id ?? null,
      name: pack.name.trim(),
      description: pack.description?.trim() ?? '',
      credit_amount: Number(pack.credit_amount),
      price_cents: Number(pack.price_cents),
      bonus_credits: bonus,
      is_active: Boolean(pack.is_active ?? true),
      display_order: pack.display_order ?? null,
    };

    if (!Number.isFinite(insertPayload.credit_amount) || insertPayload.credit_amount <= 0) {
      return NextResponse.json(
        { error: 'credit_amount must be greater than zero' },
        { status: 400 }
      );
    }

    if (!Number.isFinite(insertPayload.price_cents) || insertPayload.price_cents <= 0) {
      return NextResponse.json(
        { error: 'price_cents must be greater than zero' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('credit_packs')
      .insert(insertPayload)
      .select(
        'id, studio_id, name, description, credit_amount, price_cents, bonus_credits, is_active, display_order, created_at, updated_at'
      )
      .single();

    if (error) {
      throw error;
    }

    return NextResponse.json({ creditPack: mapCreditPack(data) }, { status: 201 });
  } catch (error) {
    console.error('Failed to create credit pack', error);
    const message =
      error instanceof Error ? error.message : 'Failed to create credit pack';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
