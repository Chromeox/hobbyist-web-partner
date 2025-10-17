const mockFrom = jest.fn();
const mockSupabase = {
  from: mockFrom,
};

jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => mockSupabase),
}));

let getCreditPacks = null;
let createCreditPack = null;
let updateCreditPack = null;
let deleteCreditPack = null;
let getPricingSettings = null;
let updatePricingSettings = null;

const createSelectChain = (result) => {
  const eq = jest.fn(() => result);
  const finalResult = { ...result, eq };
  const secondOrder = jest.fn(() => finalResult);
  const firstOrderResult = { order: secondOrder, eq };
  const firstOrder = jest.fn(() => firstOrderResult);
  return { order: firstOrder, eq };
};

const createSettingsSelectChain = (result) => {
  const maybeSingle = jest.fn(() => result);
  const chain = { maybeSingle };
  const eq = jest.fn(() => chain);
  const is = jest.fn(() => chain);
  const limit = jest.fn(() => ({ eq, is, maybeSingle }));
  return { limit };
};

const createInsertChain = (result) => {
  const single = jest.fn(() => result);
  const select = jest.fn(() => ({ single }));
  const insert = jest.fn(() => ({ select }));
  return { insert };
};

const createUpdateChain = (result) => {
  const single = jest.fn(() => result);
  const select = jest.fn(() => ({ single }));
  const eq = jest.fn(() => ({ select }));
  const update = jest.fn(() => ({ eq }));
  return { update };
};

const createUpsertChain = (result) => {
  const maybeSingle = jest.fn(() => result);
  const select = jest.fn(() => ({ maybeSingle }));
  const upsert = jest.fn(() => ({ select }));
  return { upsert };
};

const createDeleteChain = (result) => {
  const eq = jest.fn(() => result);
  const del = jest.fn(() => ({ eq }));
  return { delete: del };
};

const createPurchaseCountChain = (count, error = null) => ({
  select: jest.fn(() => ({
    eq: jest.fn(() => ({ count, error })),
  })),
});

process.env.NEXT_PUBLIC_SUPABASE_URL = 'test_url';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test_service_key';

const creditPackModule = require('../../app/api/credit-packs/route.ts');
getCreditPacks = creditPackModule.GET;
createCreditPack = creditPackModule.POST;

const creditPackIdModule = require('../../app/api/credit-packs/[id]/route.ts');
updateCreditPack = creditPackIdModule.PUT;
deleteCreditPack = creditPackIdModule.DELETE;

const pricingSettingsModule = require('../../app/api/pricing/settings/route.ts');
getPricingSettings = pricingSettingsModule.GET;
updatePricingSettings = pricingSettingsModule.PUT;

describe('Pricing API routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFrom.mockReset();
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'test_url';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'test_service_key';
  });

  describe('Credit pack routes', () => {
    it('returns mapped credit packs', async () => {
      const rows = [
        {
          id: 'pack_1',
          studio_id: null,
          name: 'Starter',
          description: 'Try us out',
          credit_amount: 5,
          price_cents: 2500,
          bonus_credits: 0,
          is_active: true,
          display_order: 1,
          created_at: '2025-01-01',
          updated_at: '2025-01-02',
        },
      ];

      mockFrom.mockImplementation((table) => {
        if (table === 'credit_packs') {
          return {
            select: jest.fn(() => createSelectChain({ data: rows, error: null })),
          };
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const response = await getCreditPacks(new Request('http://localhost/api/credit-packs'));
      expect(response.status).toBe(200);

      const body = await response.json();
      expect(body.creditPacks).toEqual([
        expect.objectContaining({
          id: 'pack_1',
          name: 'Starter',
          price_formatted: '25.00',
          total_credits: 5,
          savings_percentage: 0,
        }),
      ]);
      expect(mockFrom).toHaveBeenCalledWith('credit_packs');
    });

    it('creates a new credit pack', async () => {
      const insertedRow = {
        id: 'pack_new',
        studio_id: null,
        name: 'New Pack',
        description: '',
        credit_amount: 10,
        price_cents: 4000,
        bonus_credits: 2,
        is_active: true,
        display_order: 3,
        created_at: '2025-01-03',
        updated_at: '2025-01-03',
      };

      const insertChain = createInsertChain({ data: insertedRow, error: null });

      mockFrom.mockImplementation((table) => {
        if (table === 'credit_packs') {
          return insertChain;
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const payload = {
        creditPack: {
          name: 'New Pack',
          credit_amount: 10,
          price_cents: 4000,
          bonus_credits: 2,
          is_active: true,
          display_order: 3,
        },
      };

      const response = await createCreditPack(
        new Request('http://localhost/api/credit-packs', {
          method: 'POST',
          body: JSON.stringify(payload),
          headers: { 'Content-Type': 'application/json' },
        })
      );

      expect(response.status).toBe(201);
      const body = await response.json();
      expect(body.creditPack.id).toBe('pack_new');
      expect(insertChain.insert).toHaveBeenCalledWith({
        studio_id: null,
        name: 'New Pack',
        description: '',
        credit_amount: 10,
        price_cents: 4000,
        bonus_credits: 2,
        is_active: true,
        display_order: 3,
      });
    });

    it('rejects credit pack creation with invalid amount', async () => {
      const response = await createCreditPack(
        new Request('http://localhost/api/credit-packs', {
          method: 'POST',
          body: JSON.stringify({
            creditPack: {
              name: 'Broken Pack',
              credit_amount: 0,
              price_cents: 1000,
            },
          }),
          headers: { 'Content-Type': 'application/json' },
        })
      );

      expect(response.status).toBe(400);
      expect(mockFrom).not.toHaveBeenCalled();
    });

    it('updates an existing credit pack', async () => {
      const updateChain = createUpdateChain({
        data: {
          id: 'pack_1',
          studio_id: null,
          name: 'Updated Pack',
          description: 'Updated description',
          credit_amount: 12,
          price_cents: 5500,
          bonus_credits: 3,
          is_active: true,
          display_order: 2,
          created_at: '2025-01-01',
          updated_at: '2025-01-05',
        },
        error: null,
      });

      mockFrom.mockImplementation((table) => {
        if (table === 'credit_packs') {
          return updateChain;
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const response = await updateCreditPack(
        new Request('http://localhost/api/credit-packs/pack_1', {
          method: 'PUT',
          body: JSON.stringify({
            creditPack: {
              name: 'Updated Pack',
              description: 'Updated description',
              credit_amount: 12,
              price_cents: 5500,
              bonus_credits: 3,
              is_active: true,
              display_order: 2,
            },
          }),
          headers: { 'Content-Type': 'application/json' },
        }),
        { params: { id: 'pack_1' } }
      );

      expect(response.status).toBe(200);
      expect(updateChain.update).toHaveBeenCalled();
    });

    it('prevents deletion when purchases exist', async () => {
      const deleteChain = createDeleteChain({ error: null });

      mockFrom.mockImplementation((table) => {
        if (table === 'credit_pack_purchases') {
          return createPurchaseCountChain(3);
        }
        if (table === 'credit_packs') {
          return deleteChain;
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const response = await deleteCreditPack(
        new Request('http://localhost/api/credit-packs/pack_1', { method: 'DELETE' }),
        { params: { id: 'pack_1' } }
      );

      expect(response.status).toBe(409);
      expect(deleteChain.delete).not.toHaveBeenCalled();
    });
  });

  describe('Pricing settings routes', () => {
    it('returns default settings when none stored', async () => {
      mockFrom.mockImplementation((table) => {
        if (table === 'studio_payment_settings') {
          return {
            select: jest.fn(() =>
              createSettingsSelectChain({ data: null, error: { code: 'PGRST116' } })
            ),
          };
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const response = await getPricingSettings(new Request('http://localhost/api/pricing/settings'));
      expect(response.status).toBe(200);
      const body = await response.json();
      expect(body.settings).toEqual({
        studio_id: null,
        commission_rate: 0.15,
        minimum_payout_cents: 2000,
        payout_frequency: 'weekly',
      });
    });

    it('updates pricing settings', async () => {
      const saved = {
        studio_id: 'studio_123',
        commission_rate: 0.2,
        minimum_payout_cents: 5000,
        payout_frequency: 'monthly',
        updated_at: '2025-01-04',
      };

      const upsertChain = createUpsertChain({ data: saved, error: null });

      mockFrom.mockImplementation((table) => {
        if (table === 'studio_payment_settings') {
          return upsertChain;
        }
        throw new Error(`Unexpected table ${table}`);
      });

      const response = await updatePricingSettings(
        new Request('http://localhost/api/pricing/settings', {
          method: 'PUT',
          body: JSON.stringify({
            studioId: 'studio_123',
            settings: {
              commission_rate: 0.2,
              minimum_payout_cents: 5000,
              payout_frequency: 'monthly',
            },
          }),
          headers: { 'Content-Type': 'application/json' },
        })
      );

      expect(response.status).toBe(200);
      const body = await response.json();
      expect(body.settings).toEqual(saved);
      expect(upsertChain.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          studio_id: 'studio_123',
          commission_rate: 0.2,
          minimum_payout_cents: 5000,
          payout_frequency: 'monthly',
        }),
        { onConflict: 'studio_id' }
      );
    });

    it('rejects invalid commission rate', async () => {
      const response = await updatePricingSettings(
        new Request('http://localhost/api/pricing/settings', {
          method: 'PUT',
          body: JSON.stringify({
            settings: {
              commission_rate: 2,
              minimum_payout_cents: 5000,
              payout_frequency: 'weekly',
            },
          }),
          headers: { 'Content-Type': 'application/json' },
        })
      );

      expect(response.status).toBe(400);
      expect(mockFrom).not.toHaveBeenCalled();
    });
  });
});
