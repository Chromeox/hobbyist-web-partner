import { POST as payoutsPost } from '../../app/api/payouts/route';
import { POST as webhooksPost } from '../../app/api/stripe-webhooks/route';
import { NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// --- Mocking External Dependencies ---
// Jest's `jest.mock` is used to replace actual implementations of Supabase and Stripe
// with mock versions. This allows us to test our API routes in isolation,
// without making real network requests or interacting with live services.

jest.mock('@supabase/supabase-js', () => {
  const mockFrom = jest.fn();
  const supabaseClientMock = { from: mockFrom } as any;
  return {
    createClient: jest.fn(() => supabaseClientMock),
    __mock: { mockFrom, supabaseClientMock },
  };
});

const {
  __mock: { mockFrom },
} = jest.requireMock('@supabase/supabase-js') as {
  __mock: {
    mockFrom: jest.Mock;
  };
};

jest.mock('stripe', () => {
  const mockTransfers = {
    create: jest.fn(() => ({
      id: 'transfer_test_id',
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

// Utility builders to simulate the chained Supabase query interfaces our handlers expect.
const createBookingsSelectChain = (result: any) => {
  const lte = jest.fn(async () => result);
  const secondEq = jest.fn(() => ({ lte }));
  const firstEq = jest.fn(() => ({ eq: secondEq, lte }));
  return { eq: firstEq };
};

const createBookingsUpdateChain = (result: any) => {
  const inFn = jest.fn(async () => result);
  const update = jest.fn(() => ({ in: inFn }));
  return { update, inFn };
};

const createInsertMock = (result: any) => jest.fn(async () => result);

const createPaymentsUpdateChain = (result: any) => {
  const eq = jest.fn(async () => result);
  const update = jest.fn(() => ({ eq }));
  return { update, eq };
};

// Cast the mocked clients to their expected types for type safety in tests.
const mockStripe = new Stripe('mock-key') as any;

// --- Payouts API Tests ---
describe('Payouts API', () => {
  // Before each test, clear all mock calls to ensure test isolation.
  beforeEach(() => {
    jest.clearAllMocks();
    mockFrom.mockReset();
    // Set mock environment variables that the API route depends on.
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'test_url';
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test_anon_key';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'test_service_key';
    process.env.STRIPE_SECRET_KEY = 'test_stripe_key';
    process.env.STRIPE_WEBHOOK_SECRET = 'test_webhook_secret';
  });

  // Test case: Successfully processes payouts for completed bookings.
  it('should process payouts for completed bookings', async () => {
    const bookingsResult = {
      data: [
        {
          id: 'b1',
          amount: 100,
          instructor_id: 'inst1',
          instructors: { stripe_account_id: 'acct_1' },
        },
        {
          id: 'b2',
          amount: 200,
          instructor_id: 'inst1',
          instructors: { stripe_account_id: 'acct_1' },
        },
      ],
      error: null,
    };

    const bookingsSelectChain = createBookingsSelectChain(bookingsResult);
    const bookingsSelect = jest.fn(() => bookingsSelectChain);
    const bookingsUpdateChain = createBookingsUpdateChain({
      data: {},
      error: null,
    });
    const payoutInsert = createInsertMock({ data: {}, error: null });
    const paymentsUpdateChain = createPaymentsUpdateChain({
      data: {},
      error: null,
    });

    mockFrom.mockImplementation((table: string) => {
      switch (table) {
        case 'bookings':
          return {
            select: bookingsSelect,
            update: bookingsUpdateChain.update,
          };
        case 'payout_history':
          return {
            insert: payoutInsert,
          };
        case 'payments':
          return {
            update: paymentsUpdateChain.update,
          };
        default:
          throw new Error(`Unexpected table ${table}`);
      }
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
    expect(payoutInsert).toHaveBeenCalledTimes(1);
    expect(bookingsUpdateChain.update).toHaveBeenCalledTimes(1);
    expect(bookingsUpdateChain.inFn).toHaveBeenCalledWith('id', ['b1', 'b2']);
  });

  // Test case: Handles scenarios where there are no new bookings to payout.
  it('should handle no new bookings to payout', async () => {
    const bookingsSelect = jest.fn(() =>
      createBookingsSelectChain({
        data: [],
        error: null,
      })
    );

    mockFrom.mockImplementation((table: string) => {
      switch (table) {
        case 'bookings':
          return { select: bookingsSelect };
        case 'payments':
          return {
            update: createPaymentsUpdateChain({ data: {}, error: null }).update,
          };
        case 'payout_history':
          return { insert: createInsertMock({ data: {}, error: null }) };
        default:
          return {};
      }
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
    const bookingsSelect = jest.fn(() =>
      createBookingsSelectChain({
        data: null,
        error: {
          message: 'DB Error',
        },
      })
    );

    mockFrom.mockImplementation((table: string) => {
      if (table === 'bookings') {
        return { select: bookingsSelect };
      }
      return {};
    });

    const mockRequest = new NextRequest('http://localhost/api/payouts', {
      method: 'POST',
    });

    const response = await payoutsPost(mockRequest);
    const data = await response.json();

    // Assertions:
    expect(response.status).toBe(500);
    expect(data.error).toBe('Failed to fetch bookings for payout');
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

    const paymentsUpdateChain = createPaymentsUpdateChain({ data: {}, error: null });

    mockFrom.mockImplementation((table: string) => {
      if (table === 'payments') {
        return { update: paymentsUpdateChain.update };
      }
      return {};
    });

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
    expect(paymentsUpdateChain.update).toHaveBeenCalledWith({
      status: 'succeeded',
    });
    expect(paymentsUpdateChain.eq).toHaveBeenCalledWith('stripe_pi_id', 'pi_test_succeeded');
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

    const paymentsUpdateChain = createPaymentsUpdateChain({ data: {}, error: null });

    mockFrom.mockImplementation((table: string) => {
      if (table === 'payments') {
        return { update: paymentsUpdateChain.update };
      }
      return {};
    });

    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'test_sig'
      },
      body: '{"id":"evt_test","type":"charge.refunded","data":{"object":{"id":"ch_test_refunded"}}}',
    });

    const response = await webhooksPost(mockRequest);
    expect(response.status).toBe(200);
    expect(paymentsUpdateChain.update).toHaveBeenCalledWith({
      status: 'refunded',
    });
    expect(paymentsUpdateChain.eq).toHaveBeenCalledWith('stripe_charge_id', 'ch_test_refunded');
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

    const paymentsUpdateChain = createPaymentsUpdateChain({ data: {}, error: null });

    mockFrom.mockImplementation((table: string) => {
      if (table === 'payments') {
        return { update: paymentsUpdateChain.update };
      }
      return {};
    });

    const mockRequest = new NextRequest('http://localhost/api/stripe-webhooks', {
      method: 'POST',
      headers: {
        'stripe-signature': 'test_sig'
      },
      body: '{"id":"evt_test","type":"charge.dispute.created","data":{"object":{"id":"dp_test_created","charge":"ch_test_disputed"}}}',
    });

    const response = await webhooksPost(mockRequest);
    expect(response.status).toBe(200);
    expect(paymentsUpdateChain.update).toHaveBeenCalledWith({
      status: 'disputed',
    });
    expect(paymentsUpdateChain.eq).toHaveBeenCalledWith('stripe_charge_id', 'ch_test_disputed');
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
