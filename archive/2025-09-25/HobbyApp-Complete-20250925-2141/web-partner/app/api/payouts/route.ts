import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// This API route handles the automated payout process for instructors/studios.
// It's designed to be triggered periodically (e.g., by a cron job or an admin action).

// Initialize Supabase client with service role key for elevated privileges
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!; 
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

// Initialize Stripe client with secret key for secure API calls
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16', // Specify Stripe API version for compatibility
});

// Platform commission rate as defined in PAYMENT_LOGIC.md
const PLATFORM_COMMISSION_RATE = 0.15; 

export async function POST(request: Request) {
  try {
    // --- Authentication/Authorization (Crucial for Production) ---
    // In a real application, robust authentication and authorization
    // would be implemented here to ensure only authorized requests
    // (e.g., from an admin dashboard or a secure cron service) can trigger payouts.
    // This prevents unauthorized access to financial operations.

    // --- Fetch Bookings for Payout ---
    // Queries the 'bookings' table for all completed bookings that are pending payout.
    // It also joins with the 'instructors' table to get the Stripe account ID for each instructor.
    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
.select(`
        id,
        amount,
        instructor_id,
        payment_type,
        credit_value,
        instructors ( stripe_account_id ) // Fetches the connected Stripe account ID for the instructor
      `)
      .eq('status', 'completed') // Only consider bookings that are marked as completed
      .eq('payout_status', 'pending') // Only process bookings that haven't been paid out yet
      .lte('created_at', new Date().toISOString()); // Include all completed bookings up to the current time

    if (bookingsError) {
      console.error('Error fetching bookings for payout:', bookingsError);
      return NextResponse.json({ error: 'Failed to fetch bookings for payout' }, { status: 500 });
    }

    // If no bookings are found, return a success message indicating nothing to payout.
    if (!bookings || bookings.length === 0) {
      return NextResponse.json({ message: 'No new bookings to payout' }, { status: 200 });
    }

    // --- Aggregate Payouts by Instructor ---
    // Groups all eligible bookings by instructor to calculate their total net earnings.
    const payoutsByInstructor: { [key: string]: { amount: number; stripeAccountId: string; bookingIds: string[] } } = {};

    for (const booking of bookings) {
      const instructorId = booking.instructor_id;
      const instructorStripeAccountId = (booking.instructors as any)?.stripe_account_id; 

      // Skip bookings if instructor ID or Stripe account ID is missing (critical for payouts).
      if (!instructorId || !instructorStripeAccountId) {
        console.warn(`Skipping booking ${booking.id}: Missing instructor ID or Stripe account ID.`);
        continue;
      }

      // Calculate the base amount for payout based on payment type
      const baseBookingAmount = booking.payment_type === 'credits' ? booking.credit_value : booking.amount;

      // Calculate the net amount for the instructor after platform commission.
      const netAmount = baseBookingAmount * (1 - PLATFORM_COMMISSION_RATE);

      // Initialize or update the total payout amount and list of booking IDs for each instructor.
      if (!payoutsByInstructor[instructorId]) {
        payoutsByInstructor[instructorId] = {
          amount: 0,
          stripeAccountId: instructorStripeAccountId,
          bookingIds: [],
        };
      }
      payoutsByInstructor[instructorId].amount += netAmount;
      payoutsByInstructor[instructorId].bookingIds.push(booking.id);
    }

    const payoutResults = [];

    // --- Process Payouts for Each Instructor ---
    // Iterates through each instructor's aggregated earnings and initiates a Stripe transfer.
    for (const instructorId in payoutsByInstructor) {
      const payout = payoutsByInstructor[instructorId];
      // Stripe amounts are in cents, so convert the amount.
      const payoutAmountCents = Math.round(payout.amount * 100); 

      try {
        // Create a transfer to the instructor's connected Stripe account.
        const transfer = await stripe.transfers.create({
          amount: payoutAmountCents,
          currency: 'usd',
          destination: payout.stripeAccountId,
          metadata: { // Store relevant IDs for auditing and reconciliation
            instructor_id: instructorId,
            booking_ids: payout.bookingIds.join(','),
          },
        });

        // --- Record Payout History ---
        // Inserts a record into the 'payout_history' table for the initiated transfer.
        const { error: insertError } = await supabase.from('payout_history').insert({
          instructor_id: instructorId,
          amount: payout.amount, // Gross amount before any fees
          net_amount: payout.amount, // Net amount after platform commission
          stripe_transfer_id: transfer.id,
          status: 'completed', // Assuming immediate completion; could be 'pending' for async payouts
          payout_date: new Date().toISOString(),
          booking_ids: payout.bookingIds, // Store associated booking IDs
        });

        if (insertError) {
          console.error(`Error recording payout history for instructor ${instructorId}:`, insertError);
          // Critical: Implement robust error handling here (e.g., retry mechanism, admin alert).
        }

        // --- Update Booking Payout Status ---
        // Marks the processed bookings as 'completed' in terms of payout status.
        const { error: updateError } = await supabase
          .from('bookings')
          .update({ payout_status: 'completed' })
          .in('id', payout.bookingIds); // Update all bookings included in this payout

        if (updateError) {
          console.error(`Error updating booking payout status for instructor ${instructorId}:`, updateError);
          // Critical: Ensure data consistency if this update fails.
        }

        payoutResults.push({ instructorId, status: 'success', transferId: transfer.id });

      } catch (stripeError: any) {
        // --- Handle Stripe Payout Failures ---
        // Records failed payouts and logs the error message from Stripe.
        console.error(`Stripe payout failed for instructor ${instructorId}:`, stripeError.message);
        payoutResults.push({ instructorId, status: 'failed', error: stripeError.message });

        // Record the failed payout in history for auditing.
        await supabase.from('payout_history').insert({
          instructor_id: instructorId,
          amount: payout.amount,
          net_amount: payout.amount,
          status: 'failed',
          payout_date: new Date().toISOString(),
          booking_ids: payout.bookingIds,
          error_message: stripeError.message,
        });
      }
    }

    // Return a summary of the payout process.
    return NextResponse.json({ message: 'Payout process completed', results: payoutResults }, { status: 200 });

  } catch (error: any) {
    // --- Handle Unhandled Errors ---
    // Catches any unexpected errors during the overall payout process.
    console.error('Unhandled error during payout process:', error.message);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
