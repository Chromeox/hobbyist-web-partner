import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

const selectableColumns =
  'id, studio_id, name, description, credit_amount, price_cents, bonus_credits, is_active, display_order, created_at, updated_at';

const mapCreditPack = (pack: any) => {
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

export async function PUT(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;

  if (!id) {
    return NextResponse.json({ error: 'Credit pack ID is required' }, { status: 400 });
  }

  try {
    const payload = await request.json();
    const updates = payload?.creditPack;

    if (!updates || typeof updates !== 'object') {
      return NextResponse.json(
        { error: 'Missing credit pack payload' },
        { status: 400 }
      );
    }

    const fields: Record<string, unknown> = {};
    const assignField = (key: string, value: unknown) => {
      if (value !== undefined) {
        fields[key] = value;
      }
    };

    assignField('name', typeof updates.name === 'string' ? updates.name.trim() : undefined);
    assignField(
      'description',
      typeof updates.description === 'string' ? updates.description.trim() : undefined
    );

    if (updates.credit_amount !== undefined) {
      const amount = Number(updates.credit_amount);
      if (!Number.isFinite(amount) || amount <= 0) {
        return NextResponse.json(
          { error: 'credit_amount must be greater than zero' },
          { status: 400 }
        );
      }
      fields.credit_amount = amount;
    }

    if (updates.price_cents !== undefined) {
      const price = Number(updates.price_cents);
      if (!Number.isFinite(price) || price <= 0) {
        return NextResponse.json(
          { error: 'price_cents must be greater than zero' },
          { status: 400 }
        );
      }
      fields.price_cents = price;
    }

    if (updates.bonus_credits !== undefined) {
      const bonus = Number(updates.bonus_credits);
      if (!Number.isFinite(bonus) || bonus < 0) {
        return NextResponse.json(
          { error: 'bonus_credits must be zero or greater' },
          { status: 400 }
        );
      }
      fields.bonus_credits = bonus;
    }

    if (updates.is_active !== undefined) {
      fields.is_active = Boolean(updates.is_active);
    }

    if (updates.display_order !== undefined) {
      const order = Number(updates.display_order);
      if (!Number.isFinite(order) || order < 0) {
        return NextResponse.json(
          { error: 'display_order must be zero or greater' },
          { status: 400 }
        );
      }
      fields.display_order = order;
    }

    if (updates.studio_id !== undefined) {
      fields.studio_id = updates.studio_id;
    }

    if (Object.keys(fields).length === 0) {
      return NextResponse.json({ error: 'No valid fields to update' }, { status: 400 });
    }

    fields.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('credit_packs')
      .update(fields)
      .eq('id', id)
      .select(selectableColumns)
      .single();

    if (error) {
      throw error;
    }

    return NextResponse.json({ creditPack: mapCreditPack(data) }, { status: 200 });
  } catch (error) {
    console.error('Failed to update credit pack', error);
    const message =
      error instanceof Error ? error.message : 'Failed to update credit pack';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;

  if (!id) {
    return NextResponse.json({ error: 'Credit pack ID is required' }, { status: 400 });
  }

  try {
    const { count, error: usageError } = await supabase
      .from('credit_pack_purchases')
      .select('id', { count: 'exact', head: true })
      .eq('credit_pack_id', id);

    if (usageError) {
      throw usageError;
    }

    if (typeof count === 'number' && count > 0) {
      return NextResponse.json(
        {
          error:
            'Cannot delete credit pack with existing purchases. Deactivate the pack instead.',
        },
        { status: 409 }
      );
    }

    const { error } = await supabase.from('credit_packs').delete().eq('id', id);

    if (error) {
      throw error;
    }

    return NextResponse.json({ id }, { status: 200 });
  } catch (error) {
    console.error('Failed to delete credit pack', error);
    const message =
      error instanceof Error ? error.message : 'Failed to delete credit pack';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
