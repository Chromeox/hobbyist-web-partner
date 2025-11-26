import { NextRequest, NextResponse } from 'next/server';
import { Webhook } from 'svix';
import { createServiceClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

// Clerk webhook event types
interface ClerkWebhookEvent {
  type: string;
  data: {
    id: string;
    email_addresses?: Array<{ email_address: string; id: string }>;
    first_name?: string | null;
    last_name?: string | null;
    image_url?: string | null;
    unsafe_metadata?: Record<string, unknown>;
    created_at?: number;
    updated_at?: number;
  };
}

/**
 * Clerk Webhook Handler
 *
 * Syncs Clerk users to Supabase profiles table
 * Events: user.created, user.updated, user.deleted
 *
 * Setup in Clerk Dashboard:
 * 1. Go to Webhooks → Create Webhook
 * 2. URL: https://web-partner.vercel.app/api/webhooks/clerk
 * 3. Events: user.created, user.updated, user.deleted
 * 4. Copy signing secret to Vercel env: CLERK_WEBHOOK_SIGNING_SECRET
 */
export async function POST(request: NextRequest) {
  try {
    // Get webhook signing secret
    const webhookSecret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;
    if (!webhookSecret) {
      console.error('CLERK_WEBHOOK_SIGNING_SECRET not configured');
      return NextResponse.json(
        { error: 'Webhook secret not configured' },
        { status: 500 }
      );
    }

    // Get raw body and headers for verification
    const body = await request.text();
    const svixId = request.headers.get('svix-id');
    const svixTimestamp = request.headers.get('svix-timestamp');
    const svixSignature = request.headers.get('svix-signature');

    if (!svixId || !svixTimestamp || !svixSignature) {
      console.error('Missing Svix headers');
      return NextResponse.json(
        { error: 'Missing webhook headers' },
        { status: 400 }
      );
    }

    // Verify webhook signature using Svix
    const wh = new Webhook(webhookSecret);
    let event: ClerkWebhookEvent;

    try {
      event = wh.verify(body, {
        'svix-id': svixId,
        'svix-timestamp': svixTimestamp,
        'svix-signature': svixSignature,
      }) as ClerkWebhookEvent;
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      return NextResponse.json(
        { error: 'Invalid webhook signature' },
        { status: 400 }
      );
    }

    // Handle the event
    const supabase = createServiceClient();

    console.log(`[Clerk Webhook] Received event: ${event.type}`, {
      userId: event.data.id,
    });

    switch (event.type) {
      case 'user.created':
        await handleUserCreated(supabase, event.data);
        break;

      case 'user.updated':
        await handleUserUpdated(supabase, event.data);
        break;

      case 'user.deleted':
        await handleUserDeleted(supabase, event.data);
        break;

      default:
        console.log(`[Clerk Webhook] Unhandled event type: ${event.type}`);
    }

    return NextResponse.json({ received: true });

  } catch (error) {
    console.error('[Clerk Webhook] Error:', error);
    return NextResponse.json(
      { error: 'Webhook handler failed' },
      { status: 500 }
    );
  }
}

/**
 * Handle user.created event
 * Creates a new profile in Supabase when a user signs up via Clerk
 */
async function handleUserCreated(
  supabase: ReturnType<typeof createServiceClient>,
  data: ClerkWebhookEvent['data']
) {
  const { id, email_addresses, first_name, last_name, image_url, unsafe_metadata } = data;

  const email = email_addresses?.[0]?.email_address || '';
  const name = [first_name, last_name].filter(Boolean).join(' ').trim() || null;
  const role = (unsafe_metadata?.role as string) || 'student';

  console.log('[Clerk Webhook] Creating user profile:', { id, email, name, role });

  // Upsert to handle edge cases (e.g., webhook retry)
  const { data: profile, error } = await supabase
    .from('profiles')
    .upsert({
      id: id,
      email: email,
      name: name,
      profile_image: image_url,
      role: role,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'id',
    })
    .select()
    .single();

  if (error) {
    console.error('[Clerk Webhook] Failed to create profile:', error);
    throw error;
  }

  console.log('[Clerk Webhook] ✅ User profile created:', profile?.id);
}

/**
 * Handle user.updated event
 * Updates profile when user info changes in Clerk
 */
async function handleUserUpdated(
  supabase: ReturnType<typeof createServiceClient>,
  data: ClerkWebhookEvent['data']
) {
  const { id, email_addresses, first_name, last_name, image_url, unsafe_metadata } = data;

  const email = email_addresses?.[0]?.email_address || '';
  const name = [first_name, last_name].filter(Boolean).join(' ').trim() || null;
  const role = (unsafe_metadata?.role as string) || undefined;

  console.log('[Clerk Webhook] Updating user profile:', { id, email, name });

  const updateData: Record<string, unknown> = {
    email: email,
    name: name,
    profile_image: image_url,
    updated_at: new Date().toISOString(),
  };

  // Only update role if it's set in metadata
  if (role) {
    updateData.role = role;
  }

  const { error } = await supabase
    .from('profiles')
    .update(updateData)
    .eq('id', id);

  if (error) {
    console.error('[Clerk Webhook] Failed to update profile:', error);
    throw error;
  }

  console.log('[Clerk Webhook] ✅ User profile updated:', id);
}

/**
 * Handle user.deleted event
 * Soft deletes or cleans up profile when user is deleted from Clerk
 */
async function handleUserDeleted(
  supabase: ReturnType<typeof createServiceClient>,
  data: ClerkWebhookEvent['data']
) {
  const { id } = data;

  console.log('[Clerk Webhook] Handling user deletion:', { id });

  // Try soft delete first (requires deleted_at column from migration)
  const { error: softDeleteError } = await supabase
    .from('profiles')
    .update({
      deleted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', id);

  // If soft delete fails (e.g., deleted_at column doesn't exist), fall back to hard delete
  if (softDeleteError) {
    console.log('[Clerk Webhook] Soft delete failed, attempting hard delete:', softDeleteError.message);

    const { error: hardDeleteError } = await supabase
      .from('profiles')
      .delete()
      .eq('id', id);

    if (hardDeleteError) {
      console.error('[Clerk Webhook] Failed to delete profile:', hardDeleteError);
      throw hardDeleteError;
    }

    console.log('[Clerk Webhook] ✅ User profile hard-deleted:', id);
    return;
  }

  console.log('[Clerk Webhook] ✅ User profile soft-deleted:', id);
}
