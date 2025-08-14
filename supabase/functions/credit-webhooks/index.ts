// Credit Pack Webhook Handler
// Processes Stripe webhooks for credit pack purchases and updates user balances

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'stripe';
import { 
  createSupabaseClient, 
  corsHeaders, 
  createResponse, 
  errorResponse 
} from '../_shared/utils.ts';

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

  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
  }

  try {
    const signature = req.headers.get('stripe-signature');
    const body = await req.text();
    const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

    if (!signature || !endpointSecret) {
      return errorResponse('Missing webhook signature or secret', 'WEBHOOK_ERROR', 400);
    }

    // Verify webhook signature
    const event = stripe.webhooks.constructEvent(body, signature, endpointSecret);
    
    console.log('Processing webhook event:', event.type, event.id);

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        return await handlePaymentIntentSucceeded(event.data.object as Stripe.PaymentIntent);
      case 'payment_intent.payment_failed':
        return await handlePaymentIntentFailed(event.data.object as Stripe.PaymentIntent);
      default:
        console.log('Unhandled webhook event type:', event.type);
        return createResponse({ message: 'Webhook received but not processed' });
    }
  } catch (error) {
    console.error('Webhook error:', error);
    
    if (error instanceof Stripe.errors.StripeSignatureVerificationError) {
      return errorResponse('Invalid signature', 'INVALID_SIGNATURE', 400);
    }
    
    return errorResponse(
      'Webhook processing failed',
      'WEBHOOK_ERROR',
      500,
      { error: error.message }
    );
  }
});

async function handlePaymentIntentSucceeded(paymentIntent: Stripe.PaymentIntent): Promise<Response> {
  const supabase = createSupabaseClient(); // Use service role

  try {
    const { credit_pack_id, user_id, credit_amount, bonus_credits } = paymentIntent.metadata;

    if (!credit_pack_id || !user_id || !credit_amount) {
      console.log('Payment intent missing required metadata:', paymentIntent.metadata);
      return createResponse({ message: 'Not a credit pack purchase' });
    }

    // Find the corresponding purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('credit_pack_purchases')
      .select('*')
      .eq('stripe_payment_intent_id', paymentIntent.id)
      .eq('user_id', user_id)
      .single();

    if (purchaseError) {
      console.error('Purchase record not found:', purchaseError);
      return errorResponse('Purchase record not found', 'NOT_FOUND', 404);
    }

    if (purchase.status === 'completed') {
      console.log('Purchase already processed:', purchase.id);
      return createResponse({ message: 'Purchase already processed' });
    }

    // Calculate total credits (base + bonus)
    const totalCredits = parseInt(credit_amount) + parseInt(bonus_credits || '0');

    // Add credits to user account using the database function
    const { data: newBalance, error: creditError } = await supabase.rpc('add_user_credits', {
      p_user_id: user_id,
      p_credit_amount: totalCredits,
      p_transaction_type: 'purchase',
      p_reference_type: 'credit_pack_purchase',
      p_reference_id: purchase.id,
      p_description: `Credit pack purchase: ${totalCredits} credits`
    });

    if (creditError) {
      console.error('Failed to add user credits:', creditError);
      return errorResponse('Failed to add credits', 'CREDIT_ERROR', 500);
    }

    // Update purchase status
    const { error: updateError } = await supabase
      .from('credit_pack_purchases')
      .update({
        status: 'completed',
        updated_at: new Date().toISOString(),
      })
      .eq('id', purchase.id);

    if (updateError) {
      console.error('Failed to update purchase status:', updateError);
    }

    // Log successful processing
    console.log(`Credit pack purchase completed: ${totalCredits} credits added to user ${user_id}`);

    // TODO: Send confirmation notification to user
    // This would trigger an email/push notification confirming the credit purchase

    return createResponse({
      message: 'Credit pack purchase processed successfully',
      purchase_id: purchase.id,
      credits_added: totalCredits,
      new_balance: newBalance,
    });
  } catch (error) {
    console.error('Handle payment success error:', error);
    return errorResponse('Failed to process successful payment', 'PROCESSING_ERROR', 500);
  }
}

async function handlePaymentIntentFailed(paymentIntent: Stripe.PaymentIntent): Promise<Response> {
  const supabase = createSupabaseClient(); // Use service role

  try {
    const { credit_pack_id, user_id } = paymentIntent.metadata;

    if (!credit_pack_id || !user_id) {
      console.log('Failed payment intent missing required metadata:', paymentIntent.metadata);
      return createResponse({ message: 'Not a credit pack purchase' });
    }

    // Find the corresponding purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('credit_pack_purchases')
      .select('*')
      .eq('stripe_payment_intent_id', paymentIntent.id)
      .eq('user_id', user_id)
      .single();

    if (purchaseError) {
      console.error('Purchase record not found for failed payment:', purchaseError);
      return errorResponse('Purchase record not found', 'NOT_FOUND', 404);
    }

    // Update purchase status to failed
    const { error: updateError } = await supabase
      .from('credit_pack_purchases')
      .update({
        status: 'failed',
        updated_at: new Date().toISOString(),
      })
      .eq('id', purchase.id);

    if (updateError) {
      console.error('Failed to update purchase status:', updateError);
    }

    // Log the failure
    console.log(`Credit pack purchase failed for user ${user_id}: ${paymentIntent.last_payment_error?.message || 'Unknown error'}`);

    // TODO: Send failure notification to user
    // This would notify the user that their credit purchase failed

    return createResponse({
      message: 'Credit pack purchase failure processed',
      purchase_id: purchase.id,
      failure_reason: paymentIntent.last_payment_error?.message || 'Payment failed',
    });
  } catch (error) {
    console.error('Handle payment failure error:', error);
    return errorResponse('Failed to process payment failure', 'PROCESSING_ERROR', 500);
  }
}