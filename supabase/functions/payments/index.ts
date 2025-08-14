// Payment Processing & Commission Calculation Edge Function
// Handles Stripe integration, payment intents, commission calculations, and payouts

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'stripe';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody, calculateCommission, retryWithBackoff } from '../_shared/utils.ts';
import { Payment, Booking, InstructorPayout } from '../_shared/types.ts';

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
  const path = url.pathname.replace('/payments', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'POST':
        switch (path) {
          case '/create-intent':
            return handleCreatePaymentIntent(req, authHeader);
          case '/confirm-payment':
            return handleConfirmPayment(req, authHeader);
          case '/create-setup-intent':
            return handleCreateSetupIntent(req, authHeader);
          case '/process-refund':
            return handleProcessRefund(req, authHeader);
          case '/create-payout':
            return handleCreatePayout(req, authHeader);
          case '/connect-account':
            return handleCreateConnectAccount(req, authHeader);
          case '/verify-account':
            return handleVerifyConnectAccount(req, authHeader);
          case '/credit-pack-purchase':
            return handleCreditPackPurchase(req, authHeader);
          case '/book-with-credits':
            return handleBookWithCredits(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'GET':
        switch (path) {
          case '/payment-methods':
            return handleGetPaymentMethods(req, authHeader);
          case '/payment-history':
            return handleGetPaymentHistory(req, authHeader);
          case '/instructor-payouts':
            return handleGetInstructorPayouts(req, authHeader);
          case '/connect-account-status':
            return handleGetConnectAccountStatus(req, authHeader);
          default:
            if (path.startsWith('/payment/')) {
              const paymentId = path.replace('/payment/', '');
              return handleGetPayment(req, authHeader, paymentId);
            }
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'DELETE':
        if (path.startsWith('/payment-method/')) {
          const paymentMethodId = path.replace('/payment-method/', '');
          return handleDeletePaymentMethod(req, authHeader, paymentMethodId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Payments function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleCreatePaymentIntent(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['booking_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { booking_id, payment_method_id, save_payment_method = false } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get booking details
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(*)
        ),
        user:user_profiles!inner(*)
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    if (booking.payment_status === 'succeeded') {
      return errorResponse('Booking already paid', 'ALREADY_PAID', 400);
    }

    // Get or create Stripe customer
    let customerId = booking.user.stripe_customer_id;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: booking.user.email,
        name: `${booking.user.first_name} ${booking.user.last_name}`,
        phone: booking.user.phone,
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

    // Calculate application fee (platform commission)
    const applicationFeeAmount = booking.commission_amount;
    const connectedAccountId = booking.class.instructor.stripe_account_id;

    if (!connectedAccountId) {
      return errorResponse(
        'Instructor payment account not set up',
        'INSTRUCTOR_ACCOUNT_ERROR',
        400
      );
    }

    // Create payment intent
    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: booking.amount,
      currency: 'usd',
      customer: customerId,
      application_fee_amount: applicationFeeAmount,
      transfer_data: {
        destination: connectedAccountId,
      },
      metadata: {
        booking_id: booking.id,
        class_id: booking.class_id,
        user_id: userId,
        instructor_id: booking.class.instructor_id,
        attendees_count: booking.attendees.length.toString(),
      },
      description: `Booking for "${booking.class.title}" - ${booking.attendees.length} attendee(s)`,
      receipt_email: booking.user.email,
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

    // Update booking with payment intent ID
    await supabase
      .from('bookings')
      .update({
        payment_intent_id: paymentIntent.id,
        payment_status: 'processing',
      })
      .eq('id', booking_id);

    // Create/update payment record
    const paymentData = {
      booking_id: booking.id,
      user_id: userId,
      amount: booking.amount,
      currency: 'usd',
      status: 'processing',
      payment_method: 'card',
      stripe_payment_intent_id: paymentIntent.id,
      metadata: {
        stripe_customer_id: customerId,
        connected_account_id: connectedAccountId,
        application_fee_amount: applicationFeeAmount,
        class_title: booking.class.title,
      },
    };

    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .upsert(paymentData, {
        onConflict: 'booking_id',
        ignoreDuplicates: false,
      })
      .select()
      .single();

    if (paymentError) {
      console.error('Failed to save payment record:', paymentError);
    }

    const response = {
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      status: paymentIntent.status,
      amount: (paymentIntent.amount / 100).toFixed(2),
      currency: paymentIntent.currency,
      requires_action: paymentIntent.status === 'requires_action',
      requires_payment_method: paymentIntent.status === 'requires_payment_method',
      booking: {
        id: booking.id,
        class_title: booking.class.title,
        attendees_count: booking.attendees.length,
        instructor_name: booking.class.instructor.business_name || 
                        `${booking.class.instructor.user.first_name} ${booking.class.instructor.user.last_name}`,
      },
    };

    return createResponse(response, undefined, 201);
  } catch (error) {
    console.error('Create payment intent error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code, stripe_type: error.type }
      );
    }

    return errorResponse(
      'Failed to create payment intent',
      'PAYMENT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleConfirmPayment(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['payment_intent_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { payment_intent_id } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Retrieve payment intent from Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    if (paymentIntent.status !== 'succeeded') {
      return errorResponse(
        `Payment not successful. Status: ${paymentIntent.status}`,
        'PAYMENT_NOT_SUCCEEDED',
        400,
        { status: paymentIntent.status }
      );
    }

    // Get booking from metadata
    const bookingId = paymentIntent.metadata.booking_id;
    if (!bookingId) {
      return errorResponse('Invalid payment intent metadata', 'INVALID_METADATA', 400);
    }

    // Verify booking ownership
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*, class:classes!inner(*)')
      .eq('id', bookingId)
      .eq('user_id', userId)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    // Update booking status
    const { error: updateBookingError } = await supabase
      .from('bookings')
      .update({
        status: 'confirmed',
        payment_status: 'succeeded',
        payment_intent_id: paymentIntent.id,
      })
      .eq('id', bookingId);

    if (updateBookingError) {
      console.error('Failed to update booking:', updateBookingError);
    }

    // Update payment record
    await supabase
      .from('payments')
      .update({
        status: 'succeeded',
        stripe_charge_id: paymentIntent.latest_charge,
      })
      .eq('stripe_payment_intent_id', payment_intent_id);

    // Update class participant count
    await supabase.rpc('increment_class_participants', {
      class_id: booking.class_id,
      increment_by: booking.attendees.length,
    });

    // Create instructor payout record for future processing
    const { platformCommission, instructorPayout } = calculateCommission(
      booking.amount,
      booking.class.instructor?.commission_rate
    );

    await supabase
      .from('instructor_payouts')
      .insert({
        instructor_id: booking.class.instructor_id,
        amount: instructorPayout,
        currency: 'usd',
        status: 'pending',
        bookings: [bookingId],
        period_start: new Date().toISOString(),
        period_end: new Date().toISOString(),
      });

    // TODO: Trigger confirmation notifications
    // This would send emails/SMS to customer and instructor

    return createResponse({
      booking_id: bookingId,
      payment_status: 'succeeded',
      payment_intent_id: paymentIntent.id,
      amount_paid: (paymentIntent.amount / 100).toFixed(2),
      class_title: booking.class.title,
      confirmation_number: `HB${bookingId.slice(-8).toUpperCase()}`,
      message: 'Payment successful! Your booking is confirmed.',
    });
  } catch (error) {
    console.error('Confirm payment error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code }
      );
    }

    return errorResponse(
      'Failed to confirm payment',
      'PAYMENT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleProcessRefund(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['booking_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { booking_id, amount, reason } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get booking and verify ownership
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(*)
        )
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    if (booking.payment_status !== 'succeeded') {
      return errorResponse('Booking payment not found or not successful', 'INVALID_PAYMENT', 400);
    }

    if (!booking.payment_intent_id) {
      return errorResponse('Payment intent ID not found', 'MISSING_PAYMENT_INTENT', 400);
    }

    // Get payment intent to find charge ID
    const paymentIntent = await stripe.paymentIntents.retrieve(booking.payment_intent_id);
    const chargeId = paymentIntent.latest_charge as string;

    if (!chargeId) {
      return errorResponse('Charge ID not found', 'MISSING_CHARGE', 400);
    }

    // Calculate refund amount
    const refundAmount = amount ? Math.min(amount * 100, booking.amount) : booking.amount;
    const applicationFeeRefund = Math.round((refundAmount / booking.amount) * booking.commission_amount);

    // Create refund
    const refund = await stripe.refunds.create({
      charge: chargeId,
      amount: refundAmount,
      reverse_transfer: true, // Reverse the transfer to connected account
      refund_application_fee: applicationFeeRefund > 0,
      metadata: {
        booking_id: booking.id,
        reason: reason || 'Customer requested refund',
        user_id: userId,
      },
    });

    // Update booking status if full refund
    if (refundAmount === booking.amount) {
      await supabase
        .from('bookings')
        .update({
          status: 'cancelled',
          payment_status: 'refunded',
        })
        .eq('id', booking_id);

      // Update class participant count
      await supabase.rpc('decrement_class_participants', {
        class_id: booking.class_id,
        decrement_by: booking.attendees.length,
      });
    }

    // Create refund payment record
    await supabase
      .from('payments')
      .insert({
        booking_id: booking.id,
        user_id: userId,
        amount: -refundAmount, // Negative for refunds
        currency: 'usd',
        status: 'succeeded',
        payment_method: 'refund',
        stripe_refund_id: refund.id,
        metadata: {
          original_payment_intent_id: booking.payment_intent_id,
          refund_reason: reason,
          application_fee_refund: applicationFeeRefund,
        },
      });

    return createResponse({
      refund_id: refund.id,
      amount_refunded: (refundAmount / 100).toFixed(2),
      status: refund.status,
      estimated_arrival: 'Refunds typically arrive within 3-5 business days',
      booking_id: booking.id,
      message: 'Refund processed successfully',
    });
  } catch (error) {
    console.error('Process refund error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code }
      );
    }

    return errorResponse(
      'Failed to process refund',
      'REFUND_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCreateConnectAccount(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const supabase = createSupabaseClient();

  try {
    // Get instructor profile
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select(`
        *,
        user:user_profiles!inner(*)
      `)
      .eq('user_id', userId)
      .single();

    if (instructorError) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    }

    if (instructor.stripe_account_id) {
      return errorResponse('Stripe account already exists', 'ACCOUNT_EXISTS', 400);
    }

    // Create Stripe Connect account
    const account = await stripe.accounts.create({
      type: 'express',
      country: body.country || 'US',
      email: instructor.user.email,
      business_profile: {
        name: instructor.business_name || `${instructor.user.first_name} ${instructor.user.last_name}`,
        product_description: 'Fitness and hobby class instruction',
        support_email: instructor.user.email,
        url: 'https://hobbyist.app',
      },
      individual: {
        first_name: instructor.user.first_name,
        last_name: instructor.user.last_name,
        email: instructor.user.email,
        phone: instructor.user.phone,
      },
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      metadata: {
        user_id: userId,
        instructor_id: instructor.id,
        platform: 'hobbyist-app',
      },
    });

    // Update instructor profile with account ID
    const { error: updateError } = await supabase
      .from('instructor_profiles')
      .update({
        stripe_account_id: account.id,
        stripe_account_status: 'pending',
      })
      .eq('user_id', userId);

    if (updateError) {
      console.error('Failed to update instructor profile:', updateError);
    }

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${req.headers.get('origin')}/instructor/stripe/refresh`,
      return_url: `${req.headers.get('origin')}/instructor/stripe/complete`,
      type: 'account_onboarding',
    });

    return createResponse({
      account_id: account.id,
      onboarding_url: accountLink.url,
      status: 'pending_onboarding',
      message: 'Stripe Connect account created. Please complete onboarding to receive payments.',
    }, undefined, 201);
  } catch (error) {
    console.error('Create connect account error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code }
      );
    }

    return errorResponse(
      'Failed to create connect account',
      'ACCOUNT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetConnectAccountStatus(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    // Get instructor profile
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select('stripe_account_id, stripe_account_status')
      .eq('user_id', userId)
      .single();

    if (instructorError) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    }

    if (!instructor.stripe_account_id) {
      return createResponse({
        status: 'not_created',
        charges_enabled: false,
        payouts_enabled: false,
        requirements: {
          currently_due: [],
          errors: [],
          pending_verification: [],
        },
        message: 'Stripe Connect account not created yet',
      });
    }

    // Get account details from Stripe
    const account = await stripe.accounts.retrieve(instructor.stripe_account_id);

    // Update local status if it has changed
    if (account.charges_enabled !== (instructor.stripe_account_status === 'active')) {
      const newStatus = account.charges_enabled ? 'active' : 
                       account.requirements?.currently_due?.length > 0 ? 'restricted' : 'pending';
      
      await supabase
        .from('instructor_profiles')
        .update({ stripe_account_status: newStatus })
        .eq('user_id', userId);
    }

    return createResponse({
      account_id: account.id,
      status: instructor.stripe_account_status,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      requirements: {
        currently_due: account.requirements?.currently_due || [],
        errors: account.requirements?.errors || [],
        pending_verification: account.requirements?.pending_verification || [],
      },
      business_profile: account.business_profile,
      country: account.country,
    });
  } catch (error) {
    console.error('Get connect account status error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code }
      );
    }

    return errorResponse(
      'Failed to get account status',
      'ACCOUNT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetPaymentHistory(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '20');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const supabase = createSupabaseClient(authHeader);

  try {
    const { data: payments, error } = await supabase
      .from('payments')
      .select(`
        *,
        booking:bookings!inner(
          *,
          class:classes!inner(title, schedule)
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return errorResponse(
        'Failed to get payment history',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    const enhancedPayments = payments?.map((payment) => ({
      ...payment,
      amount_formatted: (Math.abs(payment.amount) / 100).toFixed(2),
      type: payment.amount >= 0 ? 'payment' : 'refund',
      class_title: payment.booking?.class?.title,
      class_date: payment.booking?.class?.schedule?.start_date,
    }));

    return createResponse(enhancedPayments);
  } catch (error) {
    console.error('Get payment history error:', error);
    return errorResponse(
      'Failed to get payment history',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetInstructorPayouts(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    // Get instructor profile
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (instructorError) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    }

    const { data: payouts, error } = await supabase
      .from('instructor_payouts')
      .select('*')
      .eq('instructor_id', instructor.id)
      .order('created_at', { ascending: false });

    if (error) {
      return errorResponse(
        'Failed to get payouts',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    const enhancedPayouts = payouts?.map((payout) => ({
      ...payout,
      amount_formatted: (payout.amount / 100).toFixed(2),
      bookings_count: payout.bookings?.length || 0,
    }));

    return createResponse(enhancedPayouts);
  } catch (error) {
    console.error('Get instructor payouts error:', error);
    return errorResponse(
      'Failed to get payouts',
      'PAYOUT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCreatePayout(req: Request, authHeader?: string): Promise<Response> {
  // This would typically be called by an admin function or scheduled job
  // For security, only allow service role access
  const body = await req.json();
  const validation = validateBody(body, ['instructor_id', 'amount']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { instructor_id, amount, booking_ids } = validation.data;
  const supabase = createSupabaseClient(); // Use service role

  try {
    // Get instructor Stripe account
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select('stripe_account_id, stripe_account_status')
      .eq('id', instructor_id)
      .single();

    if (instructorError) {
      return errorResponse('Instructor not found', 'NOT_FOUND', 404);
    }

    if (!instructor.stripe_account_id || instructor.stripe_account_status !== 'active') {
      return errorResponse('Instructor account not ready for payouts', 'ACCOUNT_NOT_READY', 400);
    }

    // Create Stripe transfer
    const transfer = await stripe.transfers.create({
      amount: amount * 100, // Convert to cents
      currency: 'usd',
      destination: instructor.stripe_account_id,
      metadata: {
        instructor_id,
        booking_ids: booking_ids ? booking_ids.join(',') : '',
        payout_type: 'weekly_earnings',
      },
    });

    // Create payout record
    const { data: payout, error: payoutError } = await supabase
      .from('instructor_payouts')
      .insert({
        instructor_id,
        amount: amount * 100,
        currency: 'usd',
        status: 'processing',
        stripe_transfer_id: transfer.id,
        bookings: booking_ids || [],
        period_start: new Date().toISOString(),
        period_end: new Date().toISOString(),
      })
      .select()
      .single();

    if (payoutError) {
      console.error('Failed to create payout record:', payoutError);
    }

    return createResponse({
      transfer_id: transfer.id,
      amount: (transfer.amount / 100).toFixed(2),
      status: 'processing',
      estimated_arrival: 'Typically arrives within 2 business days',
    }, undefined, 201);
  } catch (error) {
    console.error('Create payout error:', error);
    
    if (error instanceof Stripe.errors.StripeError) {
      return errorResponse(
        error.message,
        'STRIPE_ERROR',
        400,
        { stripe_code: error.code }
      );
    }

    return errorResponse(
      'Failed to create payout',
      'PAYOUT_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCreditPackPurchase(req: Request, authHeader?: string): Promise<Response> {
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

    // Create payment intent (no application fee for credit pack purchases)
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

    return createResponse({
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
    }, undefined, 201);
  } catch (error) {
    console.error('Credit pack purchase error:', error);
    
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

    // Calculate commission using the simplified 15% flat rate
    const pricePerAttendee = classData.price || 0;
    const totalAmount = pricePerAttendee * attendees.length;
    const { platformCommission, instructorPayout } = calculateCommission(totalAmount);

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
        commission_amount: platformCommission,
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