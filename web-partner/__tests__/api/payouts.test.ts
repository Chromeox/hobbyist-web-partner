import { POST as payoutsPost } from '../../app/api/payouts/route';
import { POST as webhooksPost } from '../../app/api/stripe-webhooks/route';
import { NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// --- Mocking External Dependencies ---
// Jest's `jest.mock` is used to replace actual implementations of Supabase and Stripe
// with mock versions. This allows us to test our API routes in isolation,
// without making real network requests or interacting with live services.

jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => ({
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          order: jest.fn(() => ({
            lte: jest.fn(() => ({
              single: jest.fn(() => ({ data: {}, error: null })),
              limit: jest.fn(() => ({ data: [], error: null })),
            })),
          })),
        })),
        in: jest.fn(() => ({ data: [], error: null })),
      })),
      update: jest.fn(() => ({
        eq: jest.fn(() => ({
          in: jest.fn(() => ({ data: {}, error: null })),
        })),
      })),
      insert: jest.fn(() => ({
        data: {}, error: null
      })),
    })),
  })),
}));

jest.mock('stripe', () => {
  const mockTransfers = {
    create: jest.fn(() => ({
      id: 'transfer_test_id'
    })),
  };
  const mockWebhooks = {
    constructEvent: jest.fn(),
  };
  return jest.fn(() => ({
    transfers: mockTransfers,
    webhooks: mockWebhooks,
  }));
});

// Cast the mocked clients to their expected types for type safety in tests.
const mockSupabase = createClient(
  'mock-url',
  'mock-anon-key',
  {} as any
);
const mockStripe = new Stripe('mock-key');

// --- Payouts API Tests ---
describe('Payouts API', () => {
  // Before each test, clear all mock calls to ensure test isolation.
  beforeEach(() => {
    jest.clearAllMocks();
    // Set mock environment variables that the API route depends on.
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'test_url';
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test_anon_key';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'test_service_key';
    process.env.STRIPE_SECRET_KEY = 'test_stripe_key';
    process.env.STRIPE_WEBHOOK_SECRET = 'test_webhook_secret';
  });

  // Test case: Successfully processes payouts for completed bookings.
  it('should process payouts for completed bookings', async () => {
    // Mock Supabase to return sample booking data.
    (mockSupabase.from as jest.Mock).mockReturnValue({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          eq: jest.fn(() => ({
            lte: jest.fn(() => ({
              data: [
                { id: 'b1', amount: 100, instructor_id: 'inst1', instructors: { stripe_account_id: 'acct_1' } },
                { id: 'b2', amount: 200, instructor_id: 'inst1', instructors: { stripe_account_id: 'acct_1' } },
              ],
              error: null,
            })),
          })),
        })),
      })),
      insert: jest.fn(() => ({
        data: {},
        error: null
      })),
      update: jest.fn(() => ({
        in: jest.fn(() => ({
          data: {},
          error: null
        })),
      })),
    });

    // Create a mock Next.js request object.
    const mockRequest = new NextRequest('http://localhost/api/payouts', {
      method: 'POST',
    });

    // Call the API route handler.
    const response = await payoutsPost(mockRequest);
    const data = await response.json();

    // Assertions:
    expect(response.status).toBe(200);
    expect(data.message).toBe('Payout process completed');
    // Verify that Stripe's transfer creation function was called correctly.
    expect(mockStripe.transfers.create).toHaveBeenCalledTimes(1);
    expect(mockStripe.transfers.create).toHaveBeenCalledWith({
      amount: Math.round(300 * 0.85 * 100), // Total amount (100+200) * (1-commission) * 100 (for cents)
      currency: 'usd',
      destination: 'acct_1',
      metadata: {
        instructor_id: 'inst1',
        booking_ids: 'b1,b2',
      },
    });
    // Verify Supabase database interactions.
    expect(mockSupabase.from('payout_history').insert).toHaveBeenCalledTimes(1);
    expect(mockSupabase.from('bookings').update).toHaveBeenCalledTimes(1);
  });

  // Test case: Handles scenarios where there are no new bookings to payout.
  it('should handle no new bookings to payout', async () => {
    // Mock Supabase to return an empty array for bookings.
    (mockSupabase.from as jest.Mock).mockReturnValue({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          eq: jest.fn(() => ({
            lte: jest.fn(() => ({
              data: [],
              error: null,
            })),
          })),
        })),
      })),
    });

    const mockRequest = new NextRequest('http://localhost/api/payouts', {
      method: 'POST',
    });

    const response = await payoutsPost(mockRequest);
    const data = await response.json();

    // Assertions:
    expect(response.status).toBe(200);
    expect(data.message).toBe('No new bookings to payout');
    // Ensure Stripe transfer was not attempted.
    expect(mockStripe.transfers.create).not.toHaveBeenCalled();
  });

  // Test case: Handles errors that occur during the fetching of bookings from Supabase.
  it('should handle errors during booking fetch', async () => {
    // Mock Supabase to return an error when fetching bookings.
    (mockSupabase.from as jest.Mock).mockReturnValue({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          eq: jest.fn(() => ({
            lte: jest.fn(() => ({
              data: null,
              error: {
                message: 'DB Error'
              },
            })),
          })),
        })),
      })),
    });

    const mockRequest = new NextRequest('http://localhost/api/payouts', {
      method: 'POST',
    });

    const response = await payoutsPost(mockRequest);
    const data = await response.json();

    // Assertions:
    expect(response.status).toBe(500);
    expect(data.error).toBe('Failed to fetch bookings');
  });
});

// --- Stripe Webhooks API Tests ---
describe('Stripe Webhooks API', () => {
  // Before each test, clear all mock calls and set environment variables.
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'test_url';
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test_anon_key';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'test_service_key';
    process.env.STRIPE_SECRET_KEY = 'test_stripe_key';
    process.env.STRIPE_WEBHOOK_SECRET = 'test_webhook_secret';
  });

  // Test case: Successfully handles a 'payment_intent.succeeded' webhook event.
  it('should handle payment_intent.succeeded event', async () => {
    // Mock a Stripe event object.
    const mockEvent = {
      id: 'evt_test',
      type: 'payment_intent.succeeded',
      data: {
        object: {
          id: 'pi_test_succeeded'
        }
      },
    };
    // Mock Stripe's webhook construction to return our mock event.
    (mockStripe.webhooks.constructEvent as jest.Mock).mockReturnValue(mockEvent);

    // Create a mock Next.js request with necessary headers and body.
    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'test_sig'
      },
      body: '{"id":"evt_test","type":"payment_intent.succeeded","data":{"object":{"id":"pi_test_succeeded"}}}',
    });

    // Call the webhook API route handler.
    const response = await webhooksPost(mockRequest);
    // Assertions:
    expect(response.status).toBe(200);
    // Verify Supabase database update for payment status.
    expect(mockSupabase.from('payments').update).toHaveBeenCalledWith({
      status: 'succeeded'
    });
    expect(mockSupabase.from('payments').update().eq).toHaveBeenCalledWith('stripe_pi_id', 'pi_test_succeeded');
  });

  // Test case: Successfully handles a 'charge.refunded' webhook event.
  it('should handle charge.refunded event', async () => {
    const mockEvent = {
      id: 'evt_test',
      type: 'charge.refunded',
      data: {
        object: {
          id: 'ch_test_refunded'
        }
      },
    };
    (mockStripe.webhooks.constructEvent as jest.Mock).mockReturnValue(mockEvent);

    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'test_sig'
      },
      body: '{"id":"evt_test","type":"charge.refunded","data":{"object":{"id":"ch_test_refunded"}}}',
    });

    const response = await webhooksPost(mockRequest);
    expect(response.status).toBe(200);
    expect(mockSupabase.from('payments').update).toHaveBeenCalledWith({
      status: 'refunded'
    });
    expect(mockSupabase.from('payments').update().eq).toHaveBeenCalledWith('stripe_charge_id', 'ch_test_refunded');
  });

  // Test case: Successfully handles a 'charge.dispute.created' webhook event.
  it('should handle charge.dispute.created event', async () => {
    const mockEvent = {
      id: 'evt_test',
      type: 'charge.dispute.created',
      data: {
        object: {
          id: 'dp_test_created',
          charge: 'ch_test_disputed'
        }
      },
    };
    (mockStripe.webhooks.constructEvent as jest.Mock).mockReturnValue(mockEvent);

    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'test_sig'
      },
      body: '{"id":"evt_test","type":"charge.dispute.created","data":{"object":{"id":"dp_test_created","charge":"ch_test_disputed"}}}',
    });

    const response = await webhooksPost(mockRequest);
    expect(response.status).toBe(200);
    expect(mockSupabase.from('payments').update).toHaveBeenCalledWith({
      status: 'disputed'
    });
    expect(mockSupabase.from('payments').update().eq).toHaveBeenCalledWith('stripe_charge_id', 'ch_test_disputed');
  });

  // Test case: Returns a 400 response for an invalid webhook signature.
  it('should return 400 for invalid webhook signature', async () => {
    // Mock Stripe's webhook construction to throw an error (simulating invalid signature).
    (mockStripe.webhooks.constructEvent as jest.Mock).mockImplementation(() => {
      throw new Error('Invalid signature');
    });

    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'invalid_sig'
      },
      body: '{"id":"evt_test","type":"payment_intent.succeeded","data":{"object":{"id":"pi_test_succeeded"}}}',
    });

    const response = await webhooksPost(mockRequest);
    expect(response.status).toBe(400);
    const text = await response.text();
    expect(text).toContain('Webhook Error: Invalid signature');
  });
});