// Credit Pack Purchase & Management Edge Function
// Handles credit pack purchases, credit balance management, and credit-based bookings

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'stripe';
import { 
  createSupabaseClient, 
  corsHeaders, 
  createResponse, 
  errorResponse, 
  getUserId, 
  validateBody, 
  retryWithBackoff 
} from '../_shared/utils.ts';
import { 
  CreditPack, 
  CreditPackPurchase, 
  UserCredits, 
  CreditTransaction,
  CreditPackPurchaseRequest,
  CreditBookingRequest 
} from '../_shared/types.ts';

// Initialize Stripe
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/credit-packs', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'GET':
        switch (path) {
          case '/available':
            return handleGetAvailablePacks(req);
          case '/balance':
            return handleGetUserBalance(req, authHeader);
          case '/transactions':
            return handleGetUserTransactions(req, authHeader);
          case '/purchases':
            return handleGetUserPurchases(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'POST':
        switch (path) {
          case '/purchase':
            return handlePurchaseCreditPack(req, authHeader);
          case '/book-with-credits':
            return handleBookWithCredits(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Credit packs function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleGetAvailablePacks(req: Request): Promise<Response> {
  const supabase = createSupabaseClient();

  try {
    const { data: packs, error } = await supabase
      .from('credit_packs')
      .select('*')
      .eq('is_active', true)
      .order('display_order');

    if (error) {
      return errorResponse('Failed to fetch credit packs', 'FETCH_ERROR', 500);
    }

    const enhancedPacks = packs?.map((pack) => ({
      ...pack,
      price_formatted: (pack.price_cents / 100).toFixed(2),
      total_credits: pack.credit_amount + pack.bonus_credits,
      value_per_credit: (pack.price_cents / (pack.credit_amount + pack.bonus_credits) / 100).toFixed(2),
      savings_percentage: pack.bonus_credits > 0 ? Math.round((pack.bonus_credits / pack.credit_amount) * 100) : 0,
    }));

    return createResponse(enhancedPacks);
  } catch (error) {
    console.error('Get available packs error:', error);
    return errorResponse('Failed to get available packs', 'FETCH_ERROR', 500);
  }
}

async function handleGetUserBalance(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    const { data: userCredits, error } = await supabase
      .from('user_credits')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') { // Not found is OK
      return errorResponse('Failed to get credit balance', 'FETCH_ERROR', 500);
    }

    const balance = userCredits || {
      user_id: userId,
      credit_balance: 0,
      total_earned: 0,
      total_spent: 0,
      last_activity_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    return createResponse(balance);
  } catch (error) {
    console.error('Get user balance error:', error);
    return errorResponse('Failed to get user balance', 'FETCH_ERROR', 500);
  }
}

async function handleGetUserTransactions(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const supabase = createSupabaseClient();

  try {
    const { data: transactions, error } = await supabase
      .from('credit_transactions')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return errorResponse('Failed to get transactions', 'FETCH_ERROR', 500);
    }

    const enhancedTransactions = transactions?.map((transaction) => ({
      ...transaction,
      amount_formatted: Math.abs(transaction.credit_amount).toString(),
      is_positive: transaction.credit_amount > 0,
      display_type: getTransactionDisplayType(transaction.transaction_type),
    }));

    return createResponse(enhancedTransactions);
  } catch (error) {
    console.error('Get user transactions error:', error);
    return errorResponse('Failed to get transactions', 'FETCH_ERROR', 500);
  }
}

async function handlePurchaseCreditPack(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['credit_pack_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { credit_pack_id, payment_method_id, save_payment_method = false } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get credit pack details
    const { data: creditPack, error: packError } = await supabase
      .from('credit_packs')
      .select('*')
      .eq('id', credit_pack_id)
      .eq('is_active', true)
      .single();

    if (packError) {
      return errorResponse('Credit pack not found', 'NOT_FOUND', 404);
    }

    // Get user profile for Stripe customer
    const { data: userProfile, error: userError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (userError) {
      return errorResponse('User profile not found', 'NOT_FOUND', 404);
    }

    // Get or create Stripe customer
    let customerId = userProfile.stripe_customer_id;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userProfile.email,
        name: `${userProfile.first_name} ${userProfile.last_name}`,
        phone: userProfile.phone,
        metadata: {
          user_id: userId,
          platform: 'hobbyist-app',
        },
      });
      
      customerId = customer.id;
      
      // Update user with Stripe customer ID
      await supabase
        .from('user_profiles')
        .update({ stripe_customer_id: customerId })
        .eq('user_id', userId);
    }

    // Create payment intent
    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: creditPack.price_cents,
      currency: 'usd',
      customer: customerId,
      metadata: {
        credit_pack_id: creditPack.id,
        user_id: userId,
        credit_amount: creditPack.credit_amount.toString(),
        bonus_credits: creditPack.bonus_credits.toString(),
        total_credits: (creditPack.credit_amount + creditPack.bonus_credits).toString(),
      },
      description: `Credit Pack Purchase: ${creditPack.name} (${creditPack.credit_amount + creditPack.bonus_credits} credits)`,
      receipt_email: userProfile.email,
    };

    // Add payment method if provided
    if (payment_method_id) {
      paymentIntentParams.payment_method = payment_method_id;
      paymentIntentParams.confirmation_method = 'manual';
      paymentIntentParams.confirm = true;
      
      if (save_payment_method) {
        paymentIntentParams.setup_future_usage = 'off_session';
      }
    }

    const paymentIntent = await retryWithBackoff(
      () => stripe.paymentIntents.create(paymentIntentParams)
    );

    // Create purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('credit_pack_purchases')
      .insert({
        user_id: userId,
        credit_pack_id: creditPack.id,
        stripe_payment_intent_id: paymentIntent.id,
        amount_paid_cents: creditPack.price_cents,
        credits_received: creditPack.credit_amount,
        bonus_credits: creditPack.bonus_credits,
        status: 'pending',
      })
      .select()
      .single();

    if (purchaseError) {
      console.error('Failed to create purchase record:', purchaseError);
    }

    const response = {
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      purchase_id: purchase?.id,
      status: paymentIntent.status,
      amount: (paymentIntent.amount / 100).toFixed(2),
      currency: paymentIntent.currency,
      credit_pack: {
        id: creditPack.id,
        name: creditPack.name,
        credit_amount: creditPack.credit_amount,
        bonus_credits: creditPack.bonus_credits,
        total_credits: creditPack.credit_amount + creditPack.bonus_credits,
      },
      requires_action: paymentIntent.status === 'requires_action',
      requires_payment_method: paymentIntent.status === 'requires_payment_method',
    };

    return createResponse(response, undefined, 201);
  } catch (error) {
    console.error('Purchase credit pack error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code, stripe_type: error.type }
      );
    }

    return errorResponse(
      'Failed to purchase credit pack',
      'PURCHASE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleBookWithCredits(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['class_id', 'attendees']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { class_id, attendees, notes } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get class details
    const { data: classData, error: classError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(*)
      `)
      .eq('id', class_id)
      .single();

    if (classError) {
      return errorResponse('Class not found', 'NOT_FOUND', 404);
    }

    if (!classData.allow_credit_payment) {
      return errorResponse('This class does not accept credit payments', 'CREDITS_NOT_ALLOWED', 400);
    }

    // Check if class has space
    if (classData.current_participants >= classData.max_participants) {
      return errorResponse('Class is full', 'CLASS_FULL', 400);
    }

    // Get user's credit balance
    const { data: userCredits, error: creditsError } = await supabase
      .from('user_credits')
      .select('credit_balance')
      .eq('user_id', userId)
      .single();

    const currentBalance = userCredits?.credit_balance || 0;
    const creditsRequired = classData.credit_cost * attendees.length;

    if (currentBalance < creditsRequired) {
      return errorResponse(
        `Insufficient credits. Required: ${creditsRequired}, Available: ${currentBalance}`,
        'INSUFFICIENT_CREDITS',
        400,
        { 
          credits_required: creditsRequired,
          credits_available: currentBalance,
          credits_needed: creditsRequired - currentBalance
        }
      );
    }

    // Calculate commission (15% flat rate)
    const pricePerAttendee = classData.price || 0; // Fallback to 0 if no price
    const totalAmount = pricePerAttendee * attendees.length;
    const { data: commissionData } = await supabase.rpc('calculate_studio_commission', {
      p_amount_cents: totalAmount
    });
    
    const commission = commissionData?.[0]?.commission_cents || Math.round(totalAmount * 0.15);
    const instructorPayout = commissionData?.[0]?.instructor_payout_cents || (totalAmount - commission);

    // Create booking record
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert({
        user_id: userId,
        class_id: class_id,
        status: 'confirmed',
        payment_status: 'succeeded',
        payment_method: 'credits',
        amount: totalAmount,
        commission_amount: commission,
        instructor_payout: instructorPayout,
        credits_used: creditsRequired,
        attendees: attendees,
        notes: notes,
      })
      .select()
      .single();

    if (bookingError) {
      return errorResponse('Failed to create booking', 'BOOKING_ERROR', 500, {
        error: bookingError.message
      });
    }

    // Spend user credits using the database function
    const { data: spendResult, error: spendError } = await supabase.rpc('spend_user_credits', {
      p_user_id: userId,
      p_credit_amount: creditsRequired,
      p_reference_type: 'class_booking',
      p_reference_id: booking.id,
      p_description: `Booking for "${classData.title}" - ${attendees.length} attendee(s)`
    });

    if (spendError || !spendResult) {
      // Rollback booking if credit spending fails
      await supabase
        .from('bookings')
        .delete()
        .eq('id', booking.id);
        
      return errorResponse('Failed to spend credits', 'CREDIT_SPEND_ERROR', 500);
    }

    // Update class participant count
    await supabase.rpc('increment_class_participants', {
      class_id: class_id,
      increment_by: attendees.length,
    });

    // Create instructor payout record for future processing
    await supabase
      .from('instructor_payouts')
      .insert({
        instructor_id: classData.instructor_id,
        amount: instructorPayout,
        currency: 'usd',
        status: 'pending',
        bookings: [booking.id],
        period_start: new Date().toISOString(),
        period_end: new Date().toISOString(),
      });

    return createResponse({
      booking_id: booking.id,
      status: 'confirmed',
      payment_method: 'credits',
      credits_used: creditsRequired,
      class_title: classData.title,
      attendees_count: attendees.length,
      confirmation_number: `HB${booking.id.slice(-8).toUpperCase()}`,
      message: 'Booking confirmed with credits!',
      remaining_credits: currentBalance - creditsRequired,
    }, undefined, 201);
  } catch (error) {
    console.error('Book with credits error:', error);
    return errorResponse(
      'Failed to book with credits',
      'BOOKING_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetUserPurchases(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '20');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const supabase = createSupabaseClient();

  try {
    const { data: purchases, error } = await supabase
      .from('credit_pack_purchases')
      .select(`
        *,
        credit_pack:credit_packs!inner(name, description)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return errorResponse('Failed to get purchases', 'FETCH_ERROR', 500);
    }

    const enhancedPurchases = purchases?.map((purchase) => ({
      ...purchase,
      amount_formatted: (purchase.amount_paid_cents / 100).toFixed(2),
      total_credits_received: purchase.credits_received + purchase.bonus_credits,
    }));

    return createResponse(enhancedPurchases);
  } catch (error) {
    console.error('Get user purchases error:', error);
    return errorResponse('Failed to get purchases', 'FETCH_ERROR', 500);
  }
}

function getTransactionDisplayType(type: string): string {
  const typeMap: Record<string, string> = {
    purchase: 'Credit Pack Purchase',
    spend: 'Class Booking',
    refund: 'Refund',
    bonus: 'Bonus Credits',
    admin_adjustment: 'Admin Adjustment',
  };
  
  return typeMap[type] || type;
}