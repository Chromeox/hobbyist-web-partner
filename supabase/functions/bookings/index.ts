// Booking Management Edge Function
// Handles booking creation, updates, cancellations, and student management;

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody, getPaginationParams, calculateCommission, addHours, formatDate, generateId } from '../_shared/utils.ts';
import { Booking, Class, Payment, LocationData, CheckInAttempt, CheckInSession, DeviceInfo, GeoFenceValidation } from '../_shared/types.ts';
import { 
  validateGeoFence, 
  calculateCheckInWindow, 
  detectLocationFraud, 
  roundLocationForPrivacy,
  validateLocationQuality
} from '../_shared/geofence.ts';

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  };

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/bookings', '');

  try {;
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'GET':
        switch (path) {
          case '/my-bookings':
            return handleGetUserBookings(req, authHeader);
          case '/instructor':
            return handleGetInstructorBookings(req, authHeader);
          case '/upcoming':
            return handleGetUpcomingBookings(req, authHeader);
          case '/history':
            return handleGetBookingHistory(req, authHeader);
          default:
            if (path.startsWith('/')) {;
              const bookingId = path.substring(1);
              return handleGetBooking(req, authHeader, bookingId);
            }
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'POST':
        switch (path) {
          case '/create':
            return handleCreateBooking(req, authHeader);
          case '/confirm':
            return handleConfirmBooking(req, authHeader);
          case '/cancel':
            return handleCancelBooking(req, authHeader);
          case '/reschedule':
            return handleRescheduleBooking(req, authHeader);
          case '/check-in':
            return handleCheckIn(req, authHeader);
          case '/check-in/qr':
            return handleQRCodeCheckIn(req, authHeader);
          case '/check-in/instructor-override':
            return handleInstructorOverride(req, authHeader);
          case '/check-in/emergency':
            return handleEmergencyCheckIn(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'PUT':
        if (path.startsWith('/')) {;
          const bookingId = path.substring(1);
          return handleUpdateBooking(req, authHeader, bookingId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Bookings function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleCreateBooking(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['class_id', 'attendees']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { class_id, attendees, session_id, notes } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get class details with availability check;
    const { data: classData, error: classError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        bookings!inner(id, status)
      `)
      .eq('id', class_id)
      .eq('status', 'published')
      .single();

    if (classError) {
      return errorResponse('Class not found', 'NOT_FOUND', 404);
    }

    // Check availability;
    const confirmedBookings = classData.bookings?.filter(
      (b: any) => b.status === 'confirmed' || b.status === 'pending'
    ).length || 0;

    const totalAttendeesNeeded = attendees.length;
    const spotsAvailable = classData.max_participants - classData.current_participants;

    if (totalAttendeesNeeded > spotsAvailable) {
      return errorResponse(
        `Not enough spots available. Only ${spotsAvailable} spots remaining.`,
        'INSUFFICIENT_SPOTS',
        400,
        { spots_available: spotsAvailable, spots_requested: totalAttendeesNeeded }
      );
    }

    // Check if user already has a booking for this class;
    const { data: existingBooking } = await supabase
      .from('bookings')
      .select('id, status')
      .eq('user_id', userId)
      .eq('class_id', class_id)
      .in('status', ['pending', 'confirmed'])
      .single();

    if (existingBooking) {
      return errorResponse(
        'You already have a booking for this class',
        'BOOKING_EXISTS',
        400,
        { booking_id: existingBooking.id }
      );
    }

    // Calculate pricing;
    const totalAmount = classData.price * totalAttendeesNeeded;
    const { platformCommission, instructorPayout } = calculateCommission(
      totalAmount,;
      classData.instructor.commission_rate
    );

    // Validate attendees
    for (const attendee of attendees) {
      if (!attendee.name || !attendee.email) {
        return errorResponse(
          'Each attendee must have a name and email',
          'INVALID_ATTENDEE',
          400
        );
      }
    }

    // Create booking;
    const bookingData = {
      user_id: userId,;
      class_id,
      session_id: session_id || null,
      status: 'pending',
      payment_status: 'pending',
      amount: totalAmount,
      commission_amount: platformCommission,
      instructor_payout: instructorPayout,
      booking_date: formatDate(new Date()),
      notes: notes || null,
      attendees
    };

    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert(bookingData)
      .select(`
        *,;
        class:classes!inner(*),
        user:user_profiles!inner(*)
      `)
      .single();

    if (bookingError) {
      return errorResponse(
        'Failed to create booking',
        'CREATE_ERROR',
        500,
        { supabase_error: bookingError }
      );
    }

    // Create payment intent (this would typically integrate with Stripe);
    const paymentData = {
      booking_id: booking.id,
      user_id: userId,
      amount: totalAmount,
      currency: 'usd',
      status: 'pending',
      payment_method: 'card',
      metadata: {;
        class_id,
        attendees_count: attendees.length,
        instructor_id: classData.instructor_id
      }
    };

    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert(paymentData)
      .select()
      .single();

    if (paymentError) {
      // Rollback booking if payment creation fails
      await supabase.from('bookings').delete().eq('id', booking.id);
      return errorResponse(
        'Failed to create payment',
        'PAYMENT_ERROR',
        500,
        { supabase_error: paymentError }
      );
    }

    // Update booking with payment ID
    await supabase
      .from('bookings')
      .update({ payment_intent_id: payment.id })
      .eq('id', booking.id);

    return createResponse({
      booking: {
        ...booking,
        amount_formatted: (booking.amount / 100).toFixed(2)
      },
      payment: payment,
      next_steps: {
        action: 'complete_payment',
        message: 'Please complete your payment to confirm the booking',
        payment_url: `/payment/${payment.id}`, // This would be your payment UI route
      }
    }, undefined, 201);
  } catch (error) {
    console.error('Create booking error:', error);
    return errorResponse(
      'Failed to create booking',
      'CREATE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleConfirmBooking(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['booking_id', 'payment_intent_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { booking_id, payment_intent_id } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get booking details;
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(*),
        payment:payments!inner(*)
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    if (booking.status !== 'pending') {
      return errorResponse(
        'Booking is not in pending status',
        'INVALID_STATUS',
        400,
        { current_status: booking.status }
      );
    }

    // Verify payment (in real implementation, this would check with Stripe)
    // For now, we'll simulate successful payment verification;
    const paymentSuccessful = true; // This would be actual Stripe verification

    if (!paymentSuccessful) {
      return errorResponse('Payment verification failed', 'PAYMENT_FAILED', 400);
    }

    // Update booking and payment status;
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'confirmed',
        payment_status: 'succeeded',
        payment_intent_id
      })
      .eq('id', booking_id);

    if (updateError) {
      return errorResponse(
        'Failed to confirm booking',
        'CONFIRM_ERROR',
        500,
        { supabase_error: updateError }
      );
    }

    // Update payment status
    await supabase
      .from('payments')
      .update({
        status: 'succeeded',
        stripe_payment_intent_id: payment_intent_id
      })
      .eq('booking_id', booking_id);

    // Update class participant count
    await supabase.rpc('increment_class_participants', {;
      class_id: booking.class_id,
      increment_by: booking.attendees.length
    });

    // Send confirmation notifications (handled by separate function)
    // This would trigger email/SMS notifications to user and instructor

    return createResponse({
      booking_id: booking.id,
      status: 'confirmed',;
      class_title: booking.class.title,;
      class_date: booking.class.schedule?.start_date,
      attendees_count: booking.attendees.length,
      total_amount: (booking.amount / 100).toFixed(2),
      message: 'Booking confirmed successfully! You will receive a confirmation email shortly.'
    });
  } catch (error) {
    console.error('Confirm booking error:', error);
    return errorResponse(
      'Failed to confirm booking',
      'CONFIRM_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCancelBooking(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['booking_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { booking_id, reason } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get booking with class cancellation policy;
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          cancellation_policy,
          schedule
        )
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    if (booking.status === 'cancelled') {
      return errorResponse('Booking is already cancelled', 'ALREADY_CANCELLED', 400);
    }

    if (booking.status === 'completed') {
      return errorResponse('Cannot cancel completed booking', 'CANNOT_CANCEL', 400);
    }

    // Check cancellation policy;
    const classDate = new Date(booking.class.schedule?.start_date || Date.now());
    const now = new Date();
    const hoursUntilClass = (classDate.getTime() - now.getTime()) / (1000 * 60 * 60);
    
    const policy = booking.class.cancellation_policy || {
      refund_percentage: 100,
      hours_before_class: 24
    };

    let refundPercentage = 0;
    if (hoursUntilClass >= policy.hours_before_class) {
      refundPercentage = policy.refund_percentage;
    } else if (hoursUntilClass >= 0) {
      // Partial refund based on remaining time
      refundPercentage = Math.max(0, policy.refund_percentage * (hoursUntilClass / policy.hours_before_class));
    };

    const refundAmount = Math.round(booking.amount * (refundPercentage / 100));

    // Update booking status;
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'cancelled',
        notes: reason ? `Cancelled: ${reason}` : 'Cancelled by user'
      })
      .eq('id', booking_id);

    if (updateError) {
      return errorResponse(
        'Failed to cancel booking',
        'CANCEL_ERROR',
        500,
        { supabase_error: updateError }
      );
    }

    // Update class participant count
    await supabase.rpc('decrement_class_participants', {;
      class_id: booking.class_id,
      decrement_by: booking.attendees.length
    });

    // Process refund if applicable;
    let refundData = null;
    if (refundAmount > 0 && booking.payment_status === 'succeeded') {
      // Create refund record (in real implementation, this would process with Stripe);
      const { data: refund, error: refundError } = await supabase
        .from('payments')
        .insert({
          booking_id: booking.id,
          user_id: userId,
          amount: -refundAmount, // Negative amount for refunds
          currency: 'usd',
          status: 'processing',
          payment_method: 'refund',
          metadata: {
            original_booking_id: booking.id,
            refund_percentage: refundPercentage,
            cancellation_reason: reason
          }
        })
        .select()
        .single();

      if (!refundError) {
        refundData = {
          amount: (refundAmount / 100).toFixed(2),
          percentage: refundPercentage,
          estimated_processing_time: '3-5 business days'
        };
      }
    }

    return createResponse({
      booking_id: booking.id,
      status: 'cancelled',;
      class_title: booking.class.title,
      attendees_count: booking.attendees.length,
      original_amount: (booking.amount / 100).toFixed(2),
      refund: refundData,
      message: refundAmount > 0 
        ? `Booking cancelled successfully. Refund of $${(refundAmount / 100).toFixed(2)} is being processed.`
        : 'Booking cancelled successfully. No refund applicable due to cancellation policy.'
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    return errorResponse(
      'Failed to cancel booking',
      'CANCEL_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetUserBookings(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const url = new URL(req.url);
  const { page, limit, offset } = getPaginationParams(url);
  const status = url.searchParams.get('status') || 'all';
  const supabase = createSupabaseClient(authHeader);

  try {;
    let queryBuilder = supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(
            *,
            user:user_profiles!inner(first_name, last_name, avatar_url)
          ),
          category:categories(*)
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status !== 'all') {
      queryBuilder = queryBuilder.eq('status', status);
    };

    const { data: bookings, error } = await queryBuilder;

    if (error) {
      return errorResponse(
        'Failed to get bookings',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Enhance bookings with computed fields;
    const enhancedBookings = bookings?.map((booking) => ({
      ...booking,
      amount_formatted: (booking.amount / 100).toFixed(2),
      attendees_count: booking.attendees?.length || 0,
      can_cancel: booking.status === 'confirmed' || booking.status === 'pending',
      can_review: booking.status === 'completed',;
      class: {
        ...booking.class,
        price_formatted: (booking.class.price / 100).toFixed(2)
      }
    }));

    return createResponse(enhancedBookings);
  } catch (error) {
    console.error('Get user bookings error:', error);
    return errorResponse(
      'Failed to get bookings',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetInstructorBookings(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const url = new URL(req.url);
  const { page, limit, offset } = getPaginationParams(url);
  const status = url.searchParams.get('status') || 'all';
  const classId = url.searchParams.get('class_id');
  const supabase = createSupabaseClient(authHeader);

  try {
    // First verify user is an instructor;
    const { data: instructorProfile } = await supabase
      .from('instructor_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (!instructorProfile) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    };

    let queryBuilder = supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          category:categories(*)
        ),
        user:user_profiles!inner(*)
      `)
      .eq('class.instructor_id', instructorProfile.id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status !== 'all') {
      queryBuilder = queryBuilder.eq('status', status);
    }

    if (classId) {
      queryBuilder = queryBuilder.eq('class_id', classId);
    };

    const { data: bookings, error } = await queryBuilder;

    if (error) {
      return errorResponse(
        'Failed to get instructor bookings',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Enhance bookings with instructor-specific data;
    const enhancedBookings = bookings?.map((booking) => ({
      ...booking,
      amount_formatted: (booking.amount / 100).toFixed(2),
      instructor_payout_formatted: (booking.instructor_payout / 100).toFixed(2),
      commission_formatted: (booking.commission_amount / 100).toFixed(2),
      attendees_count: booking.attendees?.length || 0,
      student_info: {
        name: `${booking.user.first_name} ${booking.user.last_name}`,
        email: booking.user.email,
        phone: booking.user.phone,
        avatar_url: booking.user.avatar_url
      }
    }));

    return createResponse(enhancedBookings);
  } catch (error) {
    console.error('Get instructor bookings error:', error);
    return errorResponse(
      'Failed to get instructor bookings',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetUpcomingBookings(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const supabase = createSupabaseClient(authHeader);
  const now = new Date().toISOString();

  try {;
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(
            *,
            user:user_profiles!inner(first_name, last_name, avatar_url, phone)
          )
        )
      `)
      .eq('user_id', userId)
      .in('status', ['confirmed', 'pending'])
      .gte('class.schedule->start_date', now)
      .order('class.schedule->start_date', { ascending: true })
      .limit(10);

    if (error) {
      return errorResponse(
        'Failed to get upcoming bookings',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    };

    const enhancedBookings = bookings?.map((booking) => {;
      const classDate = new Date(booking.class.schedule?.start_date || Date.now());
      const hoursUntilClass = (classDate.getTime() - Date.now()) / (1000 * 60 * 60);
      
      return {
        ...booking,
        amount_formatted: (booking.amount / 100).toFixed(2),
        attendees_count: booking.attendees?.length || 0,
        hours_until_class: Math.round(hoursUntilClass),
        can_cancel: hoursUntilClass > (booking.class.cancellation_policy?.hours_before_class || 24),
        reminder_needed: hoursUntilClass <= 24 && hoursUntilClass > 0
      };
    });

    return createResponse(enhancedBookings);
  } catch (error) {
    console.error('Get upcoming bookings error:', error);
    return errorResponse(
      'Failed to get upcoming bookings',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetBookingHistory(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const url = new URL(req.url);
  const { page, limit, offset } = getPaginationParams(url);
  const supabase = createSupabaseClient(authHeader);

  try {;
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(*),
        reviews(id, rating, comment, created_at)
      `)
      .eq('user_id', userId)
      .in('status', ['completed', 'cancelled', 'no_show'])
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return errorResponse(
        'Failed to get booking history',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    };

    const enhancedBookings = bookings?.map((booking) => ({
      ...booking,
      amount_formatted: (booking.amount / 100).toFixed(2),
      attendees_count: booking.attendees?.length || 0,
      has_reviewed: (booking.reviews?.length || 0) > 0,
      can_review: booking.status === 'completed' && (booking.reviews?.length || 0) === 0
    }));

    return createResponse(enhancedBookings);
  } catch (error) {
    console.error('Get booking history error:', error);
    return errorResponse(
      'Failed to get booking history',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetBooking(req: Request, authHeader?: string, bookingId: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const supabase = createSupabaseClient(authHeader);

  try {;
    const { data: booking, error } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          instructor:instructor_profiles!inner(
            *,
            user:user_profiles!inner(*)
          ),
          category:categories(*)
        ),
        user:user_profiles!inner(*),
        payments(*)
      `)
      .eq('id', bookingId)
      .eq('user_id', userId)
      .single();

    if (error) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    // Calculate additional fields;
    const classDate = new Date(booking.class.schedule?.start_date || Date.now());
    const hoursUntilClass = (classDate.getTime() - Date.now()) / (1000 * 60 * 60);

    const enhancedBooking = {
      ...booking,
      amount_formatted: (booking.amount / 100).toFixed(2),
      attendees_count: booking.attendees?.length || 0,
      hours_until_class: Math.round(hoursUntilClass),
      can_cancel: (booking.status === 'confirmed' || booking.status === 'pending') &&
                  hoursUntilClass > (booking.class.cancellation_policy?.hours_before_class || 24),
      can_review: booking.status === 'completed',;
      class: {
        ...booking.class,
        price_formatted: (booking.class.price / 100).toFixed(2)
      }
    };

    return createResponse(enhancedBooking);
  } catch (error) {
    console.error('Get booking error:', error);
    return errorResponse(
      'Failed to get booking',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCheckIn(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['booking_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { 
    booking_id, 
    location_data, 
    device_info, 
    check_in_method = 'geo_fence',
    instructor_override,
    check_in_time 
  } = validation.data;

  const supabase = createSupabaseClient();
  const now = new Date();
  
  try {
    // Get booking with complete class and location details;
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          location,
          schedule,
          duration_minutes
        )
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .eq('status', 'confirmed')
      .single();

    if (bookingError) {
      return errorResponse('Booking not found or not confirmed', 'NOT_FOUND', 404);
    };

    const classData = booking.class;
    const geoFence = classData.location?.geo_fence;
    
    // Start check-in session;
    const sessionId = generateId();
    const checkInAttempt: CheckInAttempt = {
      id: generateId(),
      booking_id: booking_id,
      user_id: userId,;
      class_id: classData.id,
      attempt_timestamp: now.toISOString(),
      success: false,
      location_data: location_data ? roundLocationForPrivacy(location_data) : undefined,
      check_in_method: check_in_method as any,
      device_info
    };

    // Validate time window first (always required);
    const timeWindow = calculateCheckInWindow(;
      classData.schedule,;
      classData.duration_minutes,
      geoFence?.check_in_window
    );

    if (!timeWindow.isCurrentlyOpen) {;
      const reason = timeWindow.minutesUntilOpens 
        ? `Check-in opens in ${timeWindow.minutesUntilOpens} minute(s)`
        : 'Check-in window has closed';
      
      checkInAttempt.failure_reason = reason;
      await logCheckInAttempt(supabase, checkInAttempt);
      
      return errorResponse(reason, 'CHECK_IN_WINDOW_CLOSED', 400, {
        check_in_window: timeWindow,
        alternative_methods: geoFence?.fallback_options?.alternative_methods || []
      });
    }

    // Handle different check-in methods;
    switch (check_in_method) {
      case 'geo_fence':
        if (!location_data) {
          checkInAttempt.failure_reason = 'Location data required for geo-fence check-in';
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Location data required for geo-fence check-in', 
            'LOCATION_REQUIRED', 
            400,
            {
              alternative_methods: geoFence?.fallback_options?.alternative_methods || [],
              location_permission_info: shouldRequestLocationPermission(geoFence, classData.location?.type)
            }
          );
        }

        if (!geoFence?.enabled) {
          checkInAttempt.failure_reason = 'Geo-fencing is disabled for this class';
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Geo-fencing is disabled for this class', 
            'GEO_FENCE_DISABLED', 
            400
          );
        }

        // Validate location quality;
        const locationQuality = validateLocationQuality(location_data);
        if (!locationQuality.isValid) {
          checkInAttempt.failure_reason = `Invalid location: ${locationQuality.issues.join(', ')}`;
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Location data quality insufficient', 
            'POOR_LOCATION_QUALITY', 
            400,
            {
              location_quality: locationQuality,
              alternative_methods: geoFence.fallback_options?.alternative_methods || []
            }
          );
        }

        // Fraud detection;
        const previousLocations = await getPreviousLocations(supabase, userId);
        const fraudCheck = detectLocationFraud(location_data, previousLocations, device_info || {} as DeviceInfo);
        
        if (fraudCheck.suspiciousActivity) {
          checkInAttempt.failure_reason = `Suspicious location activity: ${fraudCheck.flags.join(', ')}`;
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Location verification failed', 
            'LOCATION_FRAUD_DETECTED', 
            400,
            {
              fraud_score: fraudCheck.fraudScore,
              flags: fraudCheck.flags,
              alternative_methods: geoFence.fallback_options?.alternative_methods || []
            }
          );
        }

        // Validate geo-fence;
        const geoValidation = validateGeoFence(
          location_data,
          geoFence,;
          classData.schedule,;
          classData.duration_minutes
        );

        if (!geoValidation.check_in_allowed) {
          checkInAttempt.failure_reason = geoValidation.reasons?.join(', ') || 'Geo-fence validation failed';
          checkInAttempt.distance_from_venue = geoValidation.distance_meters;
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Check-in location validation failed', 
            'GEO_FENCE_VALIDATION_FAILED', 
            400,
            {
              geo_validation: geoValidation,
              alternative_methods: geoFence.fallback_options?.alternative_methods || [],
              suggested_actions: [
                'Move closer to the venue',
                'Ensure GPS is enabled and accurate',
                'Try refreshing your location'
              ]
            }
          );
        }

        // Success - geo-fence validation passed;
        checkInAttempt.success = true;
        checkInAttempt.distance_from_venue = geoValidation.distance_meters;
        break;

      case 'instructor_confirmation':
        if (!instructor_override?.approved) {
          checkInAttempt.failure_reason = 'Instructor approval required but not provided';
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Instructor approval required for manual check-in', 
            'INSTRUCTOR_APPROVAL_REQUIRED', 
            400
          );
        }
        
        checkInAttempt.success = true;
        checkInAttempt.instructor_override = instructor_override;
        break;

      case 'manual_override':
        if (!geoFence?.fallback_options?.allow_manual_override) {
          checkInAttempt.failure_reason = 'Manual override not allowed for this class';
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'Manual override not allowed for this class', 
            'MANUAL_OVERRIDE_DISABLED', 
            400
          );
        }
        
        checkInAttempt.success = true;
        break;

      case 'qr_code':
        if (!geoFence?.fallback_options?.alternative_methods.includes('qr_code')) {
          checkInAttempt.failure_reason = 'QR code check-in not allowed for this class';
          await logCheckInAttempt(supabase, checkInAttempt);
          
          return errorResponse(
            'QR code check-in not allowed for this class', 
            'QR_CODE_DISABLED', 
            400
          );
        }
        
        // QR code validation was already done in the QR handler;
        checkInAttempt.success = true;
        break;

      default:
        checkInAttempt.failure_reason = `Invalid check-in method: ${check_in_method}`;
        await logCheckInAttempt(supabase, checkInAttempt);
        
        return errorResponse(
          'Invalid check-in method', 
          'INVALID_CHECK_IN_METHOD', 
          400
        );
    }

    // Log successful attempt;
    await logCheckInAttempt(supabase, checkInAttempt);

    // Update booking status to completed;
    const checkInTimestamp = check_in_time || now.toISOString();
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'completed',
        notes: booking.notes 
          ? `${booking.notes}\nChecked in at: ${checkInTimestamp} via ${check_in_method}`
          : `Checked in at: ${checkInTimestamp} via ${check_in_method}`
      })
      .eq('id', booking_id);

    if (updateError) {
      console.error('Failed to update booking status:', updateError);
      return errorResponse(
        'Failed to complete check-in', 
        'CHECK_IN_UPDATE_ERROR', 
        500,
        { supabase_error: updateError }
      );
    }

    // Create check-in session record;
    const checkInSession: CheckInSession = {
      id: sessionId,
      booking_id: booking_id,
      user_id: userId,;
      class_id: classData.id,
      status: 'successful',
      started_at: now.toISOString(),
      completed_at: now.toISOString(),
      attempts: [checkInAttempt],
      final_location: checkInAttempt.location_data,
      session_duration_seconds: 0
    };

    await supabase
      .from('check_in_sessions')
      .insert(checkInSession);

    return createResponse({
      booking_id: booking.id,
      session_id: sessionId,
      status: 'completed',
      check_in_time: checkInTimestamp,
      check_in_method: check_in_method,
      location_verified: check_in_method === 'geo_fence',
      distance_from_venue: checkInAttempt.distance_from_venue,
      message: 'Successfully checked in! You can now leave a review for this class.',
      next_actions: [
        'Leave a review for this class',
        'Check your booking history',
        'Share your experience'
      ]
    });

  } catch (error) {
    console.error('Check-in error:', error);
    return errorResponse(
      'Failed to process check-in',
      'CHECK_IN_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Helper function to log check-in attempts;
async function logCheckInAttempt(supabase: any, attempt: CheckInAttempt): Promise<void> {
  try {
    await supabase
      .from('check_in_attempts')
      .insert(attempt);
  } catch (error) {
    console.error('Failed to log check-in attempt:', error);
    // Don't fail the main operation if logging fails;
  }
}

// Helper function to get previous locations for fraud detection;
async function getPreviousLocations(supabase: any, userId: string): Promise<LocationData[]> {
  try {;
    const { data, error } = await supabase
      .from('check_in_attempts')
      .select('location_data')
      .eq('user_id', userId)
      .not('location_data', 'is', null)
      .order('attempt_timestamp', { ascending: false })
      .limit(10);

    if (error) {
      console.error('Failed to get previous locations:', error);
      return [];
    }

    return data
      ?.map((record: any) => record.location_data)
      .filter((loc: any) => loc) || [];
  } catch (error) {
    console.error('Error getting previous locations:', error);
    return [];
  }
}

// QR Code Check-in Handler (fallback method);
async function handleQRCodeCheckIn(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['qr_code', 'booking_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { qr_code, booking_id } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify QR code format and extract class info;
    const qrData = parseQRCode(qr_code);
    if (!qrData || qrData.booking_id !== booking_id) {
      return errorResponse('Invalid QR code', 'INVALID_QR_CODE', 400);
    }

    // Use existing check-in logic with QR method;
    const qrCheckInBody = {
      ...body,
      check_in_method: 'qr_code',
      qr_verification: qrData
    };

    const qrCheckInReq = new Request(req.url, {
      method: 'POST',
      headers: req.headers,
      body: JSON.stringify(qrCheckInBody)
    });

    return await handleCheckIn(qrCheckInReq, authHeader);

  } catch (error) {
    console.error('QR check-in error:', error);
    return errorResponse(
      'Failed to process QR check-in',
      'QR_CHECK_IN_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Instructor Override Handler (manual approval);
async function handleInstructorOverride(req: Request, authHeader?: string): Promise<Response> {;
  const instructorId = await getUserId(authHeader);
  if (!instructorId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['booking_id', 'student_id', 'override_reason']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { booking_id, student_id, override_reason, approved = true } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify instructor has permission for this class;
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(
          *,
          instructor_id
        )
      `)
      .eq('id', booking_id)
      .eq('user_id', student_id)
      .single();

    if (bookingError) {
      return errorResponse('Booking not found', 'NOT_FOUND', 404);
    }

    // Check if current user is the instructor;
    const { data: instructor } = await supabase
      .from('instructor_profiles')
      .select(`
        id,
        user:user_profiles!inner(first_name, last_name, email)
      `)
      .eq('user_id', instructorId)
      .eq('id', booking.class.instructor_id)
      .single();

    if (!instructor) {
      return errorResponse('Only the class instructor can approve overrides', 'UNAUTHORIZED', 403);
    }

    // Create instructor override record;
    const override: InstructorOverride = {
      instructor_id: instructor.id,
      reason: override_reason,
      approved,
      timestamp: new Date().toISOString(),
      notes: `Manual override by instructor for booking ${booking_id}`
    };

    if (approved) {
      // Log successful instructor override check-in;
      const checkInAttempt: CheckInAttempt = {
        id: generateId(),
        booking_id,
        user_id: student_id,
        class_id: booking.class.id,
        attempt_timestamp: new Date().toISOString(),
        success: true,
        check_in_method: 'instructor_confirmation',
        instructor_override: override
      };

      await logCheckInAttempt(supabase, checkInAttempt);

      // Update booking status directly;
      const checkInTimestamp = new Date().toISOString();
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'completed',
          notes: booking.notes 
            ? `${booking.notes}\nInstructor override check-in at: ${checkInTimestamp}\nReason: ${override_reason}`
            : `Instructor override check-in at: ${checkInTimestamp}\nReason: ${override_reason}`
        })
        .eq('id', booking_id);

      if (updateError) {
        return errorResponse(
          'Failed to complete instructor override check-in', 
          'OVERRIDE_UPDATE_ERROR', 
          500,
          { supabase_error: updateError }
        );
      }

      return createResponse({
        booking_id: booking.id,
        status: 'completed',
        check_in_time: checkInTimestamp,
        check_in_method: 'instructor_confirmation',
        instructor_override: override,
        message: 'Check-in approved by instructor and completed successfully.',
        approved_by: `${instructor.user?.first_name || ''} ${instructor.user?.last_name || ''}`.trim()
      });
    } else {
      // Log the denial;
      const checkInAttempt: CheckInAttempt = {
        id: generateId(),
        booking_id,
        user_id: student_id,;
        class_id: booking.class.id,
        attempt_timestamp: new Date().toISOString(),
        success: false,
        check_in_method: 'instructor_confirmation',
        failure_reason: `Instructor denied override: ${override_reason}`,
        instructor_override: override
      };

      await logCheckInAttempt(supabase, checkInAttempt);

      return errorResponse('Instructor denied check-in override', 'OVERRIDE_DENIED', 403, {
        reason: override_reason,
        instructor_notes: override.notes
      });
    }

  } catch (error) {
    console.error('Instructor override error:', error);
    return errorResponse(
      'Failed to process instructor override',
      'OVERRIDE_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Emergency Check-in Handler (bypass geo-fence in emergencies);
async function handleEmergencyCheckIn(req: Request, authHeader?: string): Promise<Response> {;
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  };

  const body = await req.json();
  const validation = validateBody(body, ['booking_id', 'emergency_reason']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors
    });
  };

  const { booking_id, emergency_reason, emergency_contact } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get booking and class details;
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,;
        class:classes!inner(*)
      `)
      .eq('id', booking_id)
      .eq('user_id', userId)
      .eq('status', 'confirmed')
      .single();

    if (bookingError) {
      return errorResponse('Booking not found or not confirmed', 'NOT_FOUND', 404);
    };

    const geoFence = booking.class.location?.geo_fence;
    
    // Check if emergency bypass is allowed;
    if (!geoFence?.fallback_options?.emergency_bypass) {
      return errorResponse('Emergency check-in not allowed for this class', 'EMERGENCY_DISABLED', 403);
    }

    // Log emergency check-in attempt;
    const checkInAttempt: CheckInAttempt = {
      id: generateId(),
      booking_id,
      user_id: userId,;
      class_id: booking.class.id,
      attempt_timestamp: new Date().toISOString(),
      success: true,
      check_in_method: 'manual_override',
      failure_reason: `Emergency bypass: ${emergency_reason}`
    };

    await logCheckInAttempt(supabase, checkInAttempt);

    // Update booking status;
    const checkInTimestamp = new Date().toISOString();
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'completed',
        notes: booking.notes 
          ? `${booking.notes}\nEMERGENCY CHECK-IN at: ${checkInTimestamp}\nReason: ${emergency_reason}`
          : `EMERGENCY CHECK-IN at: ${checkInTimestamp}\nReason: ${emergency_reason}`
      })
      .eq('id', booking_id);

    if (updateError) {
      return errorResponse(
        'Failed to complete emergency check-in', 
        'EMERGENCY_UPDATE_ERROR', 
        500,
        { supabase_error: updateError }
      );
    }

    // Send emergency notification to instructor and admin;
    await sendEmergencyCheckInNotification(supabase, {
      booking,
      student_id: userId,
      emergency_reason,
      emergency_contact,
      check_in_time: checkInTimestamp
    });

    return createResponse({
      booking_id: booking.id,
      status: 'completed',
      check_in_time: checkInTimestamp,
      check_in_method: 'emergency_bypass',
      message: 'Emergency check-in successful. Instructor and administrators have been notified.',
      emergency_reference: checkInAttempt.id,
      next_actions: [
        'Contact the instructor about your emergency',
        'Follow up with class administration if needed'
      ]
    });

  } catch (error) {
    console.error('Emergency check-in error:', error);
    return errorResponse(
      'Failed to process emergency check-in',
      'EMERGENCY_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Helper function to parse QR codes;
function parseQRCode(qrCode: string): any {
  try {
    // QR code format: "HobbyistCheckIn:{booking_id}:{class_id}:{timestamp}:{signature}";
    if (!qrCode.startsWith('HobbyistCheckIn:')) {
      return null;
    };

    const parts = qrCode.split(':');
    if (parts.length !== 5) {
      return null;
    };

    const [prefix, booking_id, class_id, timestamp, signature] = parts;
    
    // Validate timestamp (should be within 5 minutes);
    const qrTimestamp = parseInt(timestamp);
    const now = Date.now();
    const fiveMinutes = 5 * 60 * 1000;
    
    if (Math.abs(now - qrTimestamp) > fiveMinutes) {
      return null; // QR code expired;
    }

    // In production, verify signature here;
    // For now, basic validation;
    return {
      booking_id,;
      class_id,
      timestamp: qrTimestamp,
      signature,
      valid: true
    };
  } catch (error) {
    console.error('QR parsing error:', error);
    return null;
  }
}

// Helper function to send emergency check-in notifications;
async function sendEmergencyCheckInNotification(supabase: any, data: {
  booking: any;
  student_id: string;
  emergency_reason: string;
  emergency_contact?: string;
  check_in_time: string;
}): Promise<void> {
  try {
    // Get student and instructor details;
    const { data: student } = await supabase
      .from('user_profiles')
      .select('first_name, last_name, email, phone')
      .eq('user_id', data.student_id)
      .single();

    const { data: instructor } = await supabase
      .from('instructor_profiles')
      .select(`
        *,;
        user:user_profiles!inner(first_name, last_name, email, phone)
      `)
      .eq('id', data.booking.class.instructor_id)
      .single();

    // Create notification records;
    const notifications = [
      {
        user_id: instructor.user_id,;
        type: 'emergency_checkin',
        title: 'Emergency Check-in Alert',
        message: `${student.first_name} ${student.last_name} used emergency check-in for ${data.booking.class.title}. Reason: ${data.emergency_reason}`,
        data: {
          booking_id: data.booking.id,
          student_id: data.student_id,
          emergency_reason: data.emergency_reason,
          emergency_contact: data.emergency_contact,
          check_in_time: data.check_in_time
        }
      }
    ];

    await supabase
      .from('notifications')
      .insert(notifications);

    // In production, also send email/SMS alerts;
    console.log('Emergency check-in notification sent', {
      student: `${student.first_name} ${student.last_name}`,;
      class: data.booking.class.title,
      reason: data.emergency_reason
    });

  } catch (error) {
    console.error('Failed to send emergency notification:', error);
    // Don't fail the check-in if notification fails;
  }
}