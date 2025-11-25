import { NextRequest, NextResponse } from 'next/server';
import { createServiceClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

// Apple's App Store validation endpoints
const APPLE_PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Your App's bundle ID - matches App Store Connect product IDs
const APP_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || 'com.hobbyist.bookingapp';

// Rate limiting configuration
const RATE_LIMIT_WINDOW_MS = 60000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 10;

// In-memory rate limit store (resets on cold start - acceptable for serverless)
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

// ============================================
// Types
// ============================================

interface AppleReceiptRequest {
  receiptData: string;        // Base64 encoded receipt
  transactionId: string;      // StoreKit transaction ID
  productId: string;          // Product identifier
  userId: string;             // Supabase user ID
}

interface AppleValidationResponse {
  status: number;
  environment?: string;
  receipt?: {
    bundle_id: string;
    in_app: Array<{
      product_id: string;
      transaction_id: string;
      original_transaction_id: string;
      purchase_date_ms: string;
      quantity: string;
    }>;
  };
}

// ============================================
// Main Handler
// ============================================

export async function POST(request: NextRequest) {
  const requestIp = request.headers.get('x-forwarded-for') || 'unknown';
  const startTime = Date.now();

  try {
    // Parse request body
    const body: AppleReceiptRequest = await request.json();
    const { receiptData, transactionId, productId, userId } = body;

    // Validate required fields
    if (!receiptData || !transactionId || !productId || !userId) {
      return NextResponse.json(
        {
          error: 'Missing required fields',
          required: ['receiptData', 'transactionId', 'productId', 'userId'],
        },
        { status: 400 }
      );
    }

    // Rate limiting check
    const rateLimitResult = checkRateLimit(userId);
    if (!rateLimitResult.allowed) {
      console.log(`Rate limit exceeded for user: ${userId}`);
      return NextResponse.json(
        {
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000),
        },
        { status: 429 }
      );
    }

    // Initialize Supabase service client
    const supabase = createServiceClient();

    // Get credit pack details from database
    const { data: creditPack, error: packError } = await supabase
      .from('credit_packs')
      .select('id, name, credit_amount, bonus_credits, apple_product_id')
      .eq('apple_product_id', productId)
      .eq('is_active', true)
      .single();

    if (packError || !creditPack) {
      console.error('Credit pack not found:', productId, packError);
      await logValidation(supabase, {
        userId,
        transactionId,
        productId,
        result: 'error',
        errorMessage: 'Credit pack not found for product ID',
        requestIp,
      });
      return NextResponse.json(
        { error: 'Invalid product ID', productId },
        { status: 400 }
      );
    }

    // Calculate total credits (base + bonus)
    const totalCredits = (creditPack.credit_amount || 0) + (creditPack.bonus_credits || 0);

    // Validate receipt with Apple
    console.log(`Validating receipt for transaction: ${transactionId}, product: ${productId}`);
    const validationResult = await validateWithApple(receiptData);

    // Log validation attempt
    await logValidation(supabase, {
      userId,
      transactionId,
      productId,
      result: validationResult.valid ? 'valid' : 'invalid',
      statusCode: validationResult.status,
      environment: validationResult.environment,
      errorMessage: validationResult.error,
      requestIp,
      responseData: validationResult.rawResponse,
    });

    // Handle validation failure
    if (!validationResult.valid) {
      console.error('Receipt validation failed:', validationResult.error);
      return NextResponse.json(
        {
          success: false,
          error: 'Receipt validation failed',
          reason: validationResult.error,
          appleStatus: validationResult.status,
        },
        { status: 400 }
      );
    }

    // Verify the transaction exists in the validated receipt
    const receiptTransaction = findTransactionInReceipt(
      validationResult.receipt!,
      transactionId,
      productId
    );

    if (!receiptTransaction) {
      console.error('Transaction not found in receipt:', transactionId);
      return NextResponse.json(
        {
          success: false,
          error: 'Transaction not found in validated receipt',
          transactionId,
        },
        { status: 400 }
      );
    }

    // Verify bundle ID matches our app
    if (validationResult.receipt?.bundle_id !== APP_BUNDLE_ID) {
      console.error('Bundle ID mismatch:', validationResult.receipt?.bundle_id, 'expected:', APP_BUNDLE_ID);
      return NextResponse.json(
        {
          success: false,
          error: 'Receipt bundle ID does not match app',
        },
        { status: 400 }
      );
    }

    // Grant credits using idempotent RPC function
    console.log(`Granting ${totalCredits} credits to user: ${userId}`);
    const { data: grantResult, error: grantError } = await supabase.rpc(
      'grant_credits_idempotent',
      {
        p_user_id: userId,
        p_apple_transaction_id: transactionId,
        p_apple_product_id: productId,
        p_credit_amount: totalCredits,
        p_pack_name: creditPack.name,
        p_receipt_data: receiptData.substring(0, 500), // Store truncated for audit
        p_environment: validationResult.environment || 'production',
      }
    );

    if (grantError) {
      console.error('Failed to grant credits:', grantError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to grant credits',
          details: grantError.message,
        },
        { status: 500 }
      );
    }

    const processingTime = Date.now() - startTime;
    console.log(`✅ Purchase validated successfully in ${processingTime}ms:`, {
      transactionId,
      productId,
      userId,
      credits: totalCredits,
      idempotent: grantResult.idempotent,
    });

    // Return success response
    return NextResponse.json({
      success: true,
      message: grantResult.message,
      transactionId: grantResult.transaction_id,
      creditsGranted: grantResult.credits_granted,
      balanceAfter: grantResult.balance_after,
      idempotent: grantResult.idempotent,
      environment: validationResult.environment,
      processingTimeMs: processingTime,
    });

  } catch (error: any) {
    console.error('Unexpected error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        details: error.message,
      },
      { status: 500 }
    );
  }
}

// ============================================
// Apple Receipt Validation
// ============================================

async function validateWithApple(receiptData: string): Promise<{
  valid: boolean;
  status: number;
  environment?: string;
  receipt?: AppleValidationResponse['receipt'];
  error?: string;
  rawResponse?: object;
}> {
  // Apple shared secret from environment
  const sharedSecret = process.env.APPLE_SHARED_SECRET;

  if (!sharedSecret) {
    console.warn('APPLE_SHARED_SECRET not set - validation may fail for subscriptions');
  }

  const requestBody: Record<string, any> = {
    'receipt-data': receiptData,
    'exclude-old-transactions': true,
  };

  // Only include password if we have a shared secret
  if (sharedSecret) {
    requestBody['password'] = sharedSecret;
  }

  try {
    // Try production first
    let response = await fetch(APPLE_PRODUCTION_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
    });

    let result: AppleValidationResponse = await response.json();

    // Status 21007 means receipt is from sandbox - retry with sandbox URL
    if (result.status === 21007) {
      console.log('Receipt is from sandbox, retrying with sandbox URL');
      response = await fetch(APPLE_SANDBOX_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody),
      });
      result = await response.json();
    }

    // Interpret Apple's status codes
    const statusMessages: Record<number, string> = {
      0: 'Valid receipt',
      21000: 'App Store could not read receipt',
      21002: 'Receipt data was malformed',
      21003: 'Receipt could not be authenticated',
      21004: 'Shared secret does not match',
      21005: 'Receipt server temporarily unavailable',
      21006: 'Receipt is valid but subscription has expired',
      21007: 'Receipt is from sandbox (handled)',
      21008: 'Receipt is from production (handled)',
      21009: 'Internal data access error',
      21010: 'User account not found',
    };

    if (result.status !== 0) {
      return {
        valid: false,
        status: result.status,
        error: statusMessages[result.status] || `Unknown status: ${result.status}`,
        rawResponse: result,
      };
    }

    return {
      valid: true,
      status: result.status,
      environment: result.environment,
      receipt: result.receipt,
      rawResponse: result,
    };

  } catch (error: any) {
    console.error('Apple validation request failed:', error);
    return {
      valid: false,
      status: -1,
      error: `Network error: ${error.message}`,
    };
  }
}

// ============================================
// Find Transaction in Receipt
// ============================================

function findTransactionInReceipt(
  receipt: AppleValidationResponse['receipt'],
  transactionId: string,
  productId: string
): object | null {
  if (!receipt?.in_app) return null;

  // Look for matching transaction in in_app array
  const transaction = receipt.in_app.find(
    (txn) => txn.transaction_id === transactionId && txn.product_id === productId
  );

  return transaction || null;
}

// ============================================
// Rate Limiting
// ============================================

function checkRateLimit(userId: string): { allowed: boolean; resetTime: number } {
  const now = Date.now();
  const userLimit = rateLimitStore.get(userId);

  if (!userLimit || now > userLimit.resetTime) {
    // First request or window expired - allow and start new window
    rateLimitStore.set(userId, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW_MS,
    });
    return { allowed: true, resetTime: now + RATE_LIMIT_WINDOW_MS };
  }

  if (userLimit.count >= RATE_LIMIT_MAX_REQUESTS) {
    // Rate limit exceeded
    return { allowed: false, resetTime: userLimit.resetTime };
  }

  // Increment count and allow
  userLimit.count++;
  return { allowed: true, resetTime: userLimit.resetTime };
}

// ============================================
// Validation Logging
// ============================================

async function logValidation(
  supabase: ReturnType<typeof createServiceClient>,
  params: {
    userId: string;
    transactionId: string;
    productId: string;
    result: 'valid' | 'invalid' | 'error';
    statusCode?: number;
    environment?: string;
    errorMessage?: string;
    requestIp?: string;
    responseData?: object;
  }
) {
  try {
    await supabase.rpc('log_receipt_validation', {
      p_user_id: params.userId,
      p_apple_transaction_id: params.transactionId,
      p_apple_product_id: params.productId,
      p_validation_result: params.result,
      p_apple_status_code: params.statusCode || null,
      p_environment: params.environment || null,
      p_error_message: params.errorMessage || null,
      p_request_ip: params.requestIp || null,
      p_response_data: params.responseData ? JSON.stringify(params.responseData) : null,
    });
  } catch (error) {
    // Don't fail the request if logging fails
    console.error('Failed to log validation:', error);
  }
}
