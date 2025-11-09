'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { motion } from 'framer-motion';
import { 
  TrendingUp, 
  Settings, 
  DollarSign, 
  Package,
  Info,
  Check,
  AlertCircle,
  Save,
  Trash2,
  Plus,
  Loader2
} from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { useUserProfile } from '@/lib/hooks/useAuth';
import LoadingState, { LoadingStates } from '@/components/ui/LoadingState';

interface CreditPack {
  id: string;
  name: string;
  description: string;
  credit_amount: number;
  price_cents: number;
  bonus_credits: number;
  is_active: boolean;
  display_order: number;
  price_formatted: string;
  total_credits: number;
  savings_percentage: number;
}

interface PricingSettings {
  commission_rate: number;
  minimum_payout_cents: number;
  payout_frequency: string;
}

type ToastFn = (options: {
  title?: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;

export default function PricingManagement() {
  const { profile, isLoading: profileLoading } = useUserProfile();
  const studioId =
    profile?.instructor?.id ??
    profile?.studio?.id ??
    profile?.business?.studio_id ??
    null;
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState('overview');
  const [creditPacks, setCreditPacks] = useState<CreditPack[]>([]);
  const [pricingSettings, setPricingSettings] = useState<PricingSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadPricingData = useCallback(async () => {
    setLoading(true);
    setError(null);

    const buildUrl = (base: string) =>
      studioId ? `${base}?studioId=${encodeURIComponent(studioId)}` : base;

    try {
      const packsResponse = await fetch(buildUrl('/api/credit-packs'), {
        method: 'GET',
        cache: 'no-store',
      });

      if (!packsResponse.ok) {
        const payload = await packsResponse.json().catch(() => ({}));
        throw new Error(
          typeof payload?.error === 'string'
            ? payload.error
            : `Failed to load credit packs (${packsResponse.status})`
        );
      }

      const packPayload = await packsResponse.json();
      const packs = Array.isArray(packPayload?.creditPacks)
        ? packPayload.creditPacks
        : [];
      setCreditPacks(packs);

      const settingsResponse = await fetch(
        buildUrl('/api/pricing/settings'),
        {
          method: 'GET',
          cache: 'no-store',
        }
      );

      if (!settingsResponse.ok) {
        const payload = await settingsResponse.json().catch(() => ({}));
        throw new Error(
          typeof payload?.error === 'string'
            ? payload.error
            : `Failed to load pricing settings (${settingsResponse.status})`
        );
      }

      const settingsPayload = await settingsResponse.json();
      const settings: PricingSettings | null =
        settingsPayload?.settings ?? null;
      setPricingSettings(
        settings ?? {
          commission_rate: 0.15,
          minimum_payout_cents: 2000,
          payout_frequency: 'weekly',
        }
      );
    } catch (error) {
      console.error('Error loading pricing data:', error);
      setError(
        error instanceof Error ? error.message : 'Unable to load pricing data.'
      );
    } finally {
      setLoading(false);
    }
  }, [studioId]);

  useEffect(() => {
    if (profileLoading) return;
    loadPricingData();
  }, [profileLoading, loadPricingData]);

  const tabs = [
    { id: 'overview', label: 'Pricing Overview', icon: DollarSign },
    { id: 'credit-packs', label: 'Credit Packs', icon: Package },
    { id: 'commission', label: 'Commission Settings', icon: Settings },
  ];

  if (loading || profileLoading) {
    return (
      <LoadingState 
        message={LoadingStates.pricing.message}
        description={LoadingStates.pricing.description}
        size="lg"
        className="h-64"
      />
    );
  }

  if (error) {
    return (
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl p-6">
          <h2 className="text-lg font-semibold">Unable to load pricing data</h2>
          <p className="mt-2 text-sm">{error}</p>
        </div>
        <button
          onClick={loadPricingData}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition-colors"
        >
          <Loader2 className="h-4 w-4" />
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Pricing Management</h1>
          <p className="text-gray-600">Manage credit packs, pricing, and commission settings</p>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => {
            const IconComponent = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <IconComponent className="h-4 w-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Tab Content */}
      <motion.div
        key={activeTab}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        {activeTab === 'overview' && (
          <PricingOverview 
            creditPacks={creditPacks} 
            settings={pricingSettings} 
          />
        )}
        {activeTab === 'credit-packs' && (
          <CreditPacksManagement 
            creditPacks={creditPacks} 
            setCreditPacks={setCreditPacks}
            studioId={studioId}
            toast={toast}
          />
        )}
        {activeTab === 'commission' && (
          <CommissionSettings 
            settings={pricingSettings} 
            setSettings={setPricingSettings}
            studioId={studioId}
            toast={toast}
          />
        )}
      </motion.div>
    </div>
  );
}

function PricingOverview({ 
  creditPacks, 
  settings 
}: { 
  creditPacks: CreditPack[]; 
  settings: PricingSettings | null; 
}) {
  const [showCreditsView, setShowCreditsView] = useState(false);
  return (
    <div className="space-y-6">
      {/* Key Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white p-6 rounded-xl shadow-sm border border-gray-200"
        >
          <div className="flex items-center">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Package className="h-6 w-6 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Active Credit Packs</p>
              <p className="text-2xl font-bold text-gray-900">
                {creditPacks.filter(pack => pack.is_active).length}
              </p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className="bg-white p-6 rounded-xl shadow-sm border border-gray-200"
        >
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <TrendingUp className="h-6 w-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Commission Rate</p>
              <p className="text-2xl font-bold text-gray-900">
                {settings ? `${(settings.commission_rate * 100).toFixed(1)}%` : 'Loading...'}
              </p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white p-6 rounded-xl shadow-sm border border-gray-200"
        >
          <div className="flex items-center">
            <div className="p-2 bg-purple-100 rounded-lg">
              <DollarSign className="h-6 w-6 text-purple-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Min Payout</p>
              <p className="text-2xl font-bold text-gray-900">
                {settings ? `$${(settings.minimum_payout_cents / 100).toFixed(2)}` : 'Loading...'}
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Pricing Model Info */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
        <div className="flex items-start space-x-3">
          <Info className="h-5 w-5 text-blue-600 mt-0.5" />
          <div>
            <h3 className="text-xl font-semibold text-blue-900">Simplified Credit-Based Pricing</h3>
            <p className="text-blue-800 mt-1">
              Our streamlined pricing system uses a 3-tier credit pack structure with a flat{' '}
              {settings ? `${(settings.commission_rate * 100).toFixed(1)}%` : 'platform-defined'}
              {' '}commission rate. Students purchase credit packs and use credits to book classes,
              providing predictable revenue and simplified transaction processing.
            </p>
            <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-700">
              <div className="flex items-center space-x-2">
                <Check className="h-4 w-4" />
                <span>
                  {settings
                    ? `${(settings.commission_rate * 100).toFixed(1)}% platform commission`
                    : 'Platform commission configurable'}
                </span>
              </div>
              <div className="flex items-center space-x-2">
                <Check className="h-4 w-4" />
                <span>3-tier credit pack system</span>
              </div>
              <div className="flex items-center space-x-2">
                <Check className="h-4 w-4" />
                <span>Automated payout processing</span>
              </div>
              <div className="flex items-center space-x-2">
                <Check className="h-4 w-4" />
                <span>Simplified transaction tracking</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Current Credit Packs Preview */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-xl font-semibold text-gray-900">Current Credit Packs</h3>
              <p className="text-gray-600">Active credit packs available for purchase</p>
            </div>
            <div className="flex items-center gap-3">
              <span className={`text-sm font-medium ${!showCreditsView ? 'text-gray-900' : 'text-gray-500'}`}>
                Pricing ($)
              </span>
              <button
                onClick={() => setShowCreditsView(!showCreditsView)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  showCreditsView ? 'bg-blue-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
                    showCreditsView ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
              <span className={`text-sm font-medium ${showCreditsView ? 'text-gray-900' : 'text-gray-500'}`}>
                Credits
              </span>
            </div>
          </div>
        </div>
        <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
          {creditPacks.filter(pack => pack.is_active).map((pack) => {
            // Calculate cost per credit for credits view
            const costPerCredit = pack.total_credits > 0 ? pack.price_cents / pack.total_credits / 100 : 0;
            
            return (
              <div
                key={pack.id}
                className="border border-gray-200 rounded-lg p-4 hover:border-blue-300 transition-colors"
              >
                <div className="text-center">
                  <h4 className="font-semibold text-gray-900">{pack.name}</h4>
                  <p className="text-sm text-gray-600 mt-1">{pack.description}</p>
                  
                  {showCreditsView ? (
                    // Credits view - show credit amount as primary
                    <>
                      <div className="mt-3">
                        <span className="text-2xl font-bold text-blue-600">
                          {pack.total_credits} Credits
                        </span>
                      </div>
                      <div className="mt-2">
                        <span className="text-lg font-medium text-gray-900">
                          ${costPerCredit.toFixed(2)} per credit
                        </span>
                      </div>
                      {pack.bonus_credits > 0 && (
                        <div className="text-sm text-green-600 mt-1">
                          Includes {pack.bonus_credits} bonus credits
                        </div>
                      )}
                      <div className="text-sm text-gray-500 mt-2">
                        Total value: ${pack.price_formatted}
                      </div>
                    </>
                  ) : (
                    // Pricing view - show dollar amount as primary (original layout)
                    <>
                      <div className="mt-3">
                        <span className="text-2xl font-bold text-gray-900">${pack.price_formatted}</span>
                      </div>
                      <div className="mt-2">
                        <span className="text-lg font-medium text-blue-600">
                          {pack.total_credits} Credits
                        </span>
                        {pack.bonus_credits > 0 && (
                          <div className="text-sm text-green-600">
                            +{pack.bonus_credits} bonus credits
                          </div>
                        )}
                      </div>
                    </>
                  )}
                  
                  {pack.savings_percentage > 0 && (
                    <div className="mt-2">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium bg-green-100 text-green-800">
                        {pack.savings_percentage}% savings
                      </span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function CreditPacksManagement({
  creditPacks,
  setCreditPacks,
  studioId,
  toast,
}: {
  creditPacks: CreditPack[];
  setCreditPacks: React.Dispatch<React.SetStateAction<CreditPack[]>>;
  studioId: string | null;
  toast: ToastFn;
}) {
  const [drafts, setDrafts] = useState<Record<string, CreditPack>>({});
  const [draftOrder, setDraftOrder] = useState<string[]>([]);
  const [dirtyIds, setDirtyIds] = useState<Set<string>>(new Set());
  const [formErrors, setFormErrors] = useState<Record<string, string | null>>({});
  const [savingId, setSavingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const ensureDerived = useCallback((pack: CreditPack): CreditPack => {
    const bonus = pack.bonus_credits ?? 0;
    const base = pack.credit_amount ?? 0;
    const priceCents = pack.price_cents ?? 0;
    return {
      ...pack,
      price_formatted:
        pack.price_formatted !== undefined
          ? pack.price_formatted
          : (priceCents / 100).toFixed(2),
      total_credits: base + bonus,
      savings_percentage: base > 0 ? Math.round((bonus / base) * 100) : 0,
    };
  }, []);

  const validatePack = useCallback((pack: CreditPack): string | null => {
    if (!pack.name.trim()) return 'Pack name is required.';
    if (pack.credit_amount <= 0)
      return 'Credit amount must be greater than zero.';
    if (pack.price_cents <= 0) return 'Price must be greater than zero.';
    if (pack.bonus_credits < 0) return 'Bonus credits cannot be negative.';
    return null;
  }, []);

  useEffect(() => {
    setDrafts((prev) => {
      const next = { ...prev };
      creditPacks.forEach((pack) => {
        next[pack.id] = ensureDerived(pack);
      });
      return next;
    });
    setDraftOrder((prev) => {
      const tempIds = prev.filter((id) => id.startsWith('temp-'));
      const baseIds = creditPacks.map((pack) => pack.id);
      return [...baseIds, ...tempIds];
    });
    setFormErrors((prev) => {
      const next: Record<string, string | null> = {};
      creditPacks.forEach((pack) => {
        next[pack.id] = prev[pack.id] ?? null;
      });
      Object.keys(prev).forEach((key) => {
        if (key.startsWith('temp-')) {
          next[key] = prev[key];
        }
      });
      return next;
    });
  }, [creditPacks, ensureDerived]);

  const combinedPacks = useMemo(
    () =>
      draftOrder
        .map((id) => drafts[id])
        .filter((pack): pack is CreditPack => Boolean(pack)),
    [draftOrder, drafts]
  );

  const updateDraft = useCallback(
    (id: string, updater: (pack: CreditPack) => CreditPack) => {
      setDrafts((prev) => {
        const current = prev[id];
        if (!current) return prev;
        const updated = ensureDerived(updater(current));
        const next = { ...prev, [id]: updated };
        setFormErrors((errors) => ({
          ...errors,
          [id]: validatePack(updated),
        }));
        return next;
      });
      setDirtyIds((prev) => {
        const next = new Set(prev);
        next.add(id);
        return next;
      });
    },
    [ensureDerived, validatePack]
  );

  const handleInputChange = (id: string, field: keyof CreditPack, value: string) => {
    updateDraft(id, (current) => {
      switch (field) {
        case 'name':
          return { ...current, name: value };
        case 'description':
          return { ...current, description: value };
        case 'credit_amount': {
          const parsed = Number(value);
          return {
            ...current,
            credit_amount: Number.isFinite(parsed) ? Math.max(0, Math.floor(parsed)) : current.credit_amount,
          };
        }
        case 'price_formatted': {
          const parsed = Number(value);
          return {
            ...current,
            price_formatted: value,
            price_cents: Number.isFinite(parsed) ? Math.round(parsed * 100) : current.price_cents,
          };
        }
        case 'bonus_credits': {
          const parsed = Number(value);
          return {
            ...current,
            bonus_credits: Number.isFinite(parsed) ? Math.max(0, Math.floor(parsed)) : current.bonus_credits,
          };
        }
        case 'display_order': {
          const parsed = Number(value);
          return {
            ...current,
            display_order: Number.isFinite(parsed) ? Math.max(0, Math.floor(parsed)) : current.display_order,
          };
        }
        default:
          return current;
      }
    });
  };

  const handleToggleActive = (id: string, checked: boolean) => {
    updateDraft(id, (current) => ({ ...current, is_active: checked }));
  };

  const handleAddPack = () => {
    const tempId = `temp-${Date.now()}`;
    const newPack: CreditPack = {
      id: tempId,
      name: 'New Credit Pack',
      description: '',
      credit_amount: 5,
      price_cents: 1000,
      bonus_credits: 0,
      is_active: true,
      display_order: creditPacks.length + 1,
      price_formatted: '10.00',
      total_credits: 5,
      savings_percentage: 0,
    };

    setDrafts((prev) => ({ ...prev, [tempId]: newPack }));
    setDraftOrder((prev) => [tempId, ...prev]);
    setDirtyIds((prev) => {
      const next = new Set(prev);
      next.add(tempId);
      return next;
    });
    setFormErrors((prev) => ({ ...prev, [tempId]: validatePack(newPack) }));
  };

  const handleReset = (id: string) => {
    if (id.startsWith('temp-')) {
      setDraftOrder((prev) => prev.filter((existing) => existing !== id));
      setDrafts((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
      setDirtyIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      setFormErrors((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
      return;
    }

    const original = creditPacks.find((pack) => pack.id === id);
    if (original) {
      setDrafts((prev) => ({ ...prev, [id]: ensureDerived(original) }));
      setDirtyIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      setFormErrors((prev) => ({ ...prev, [id]: null }));
    }
  };

  const handleSave = async (id: string) => {
    const draft = drafts[id];
    if (!draft) return;

    const validation = validatePack(draft);
    if (validation) {
      setFormErrors((prev) => ({ ...prev, [id]: validation }));
      toast({
        title: 'Please review this credit pack',
        description: validation,
        variant: 'destructive',
      });
      return;
    }

    setSavingId(id);
    setActionError(null);

    const payload = {
      creditPack: {
        name: draft.name.trim(),
        description: draft.description ?? '',
        credit_amount: draft.credit_amount,
        price_cents: draft.price_cents,
        bonus_credits: draft.bonus_credits,
        is_active: draft.is_active,
        display_order: draft.display_order,
        studio_id: studioId ?? undefined,
      },
    };

    const isTemp = id.startsWith('temp-');
    const endpoint = isTemp ? '/api/credit-packs' : `/api/credit-packs/${id}`;
    const method = isTemp ? 'POST' : 'PUT';

    try {
      const response = await fetch(endpoint, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorPayload = await response.json().catch(() => ({}));
        throw new Error(
          typeof errorPayload?.error === 'string'
            ? errorPayload.error
            : `Failed to save credit pack (${response.status})`
        );
      }

      const data = await response.json();
      const savedPack = ensureDerived(data?.creditPack);

      if (!savedPack) {
        throw new Error('Missing credit pack data in response');
      }

      if (isTemp) {
        setDraftOrder((prev) =>
          prev.map((entry) => (entry === id ? savedPack.id : entry))
        );
        setDrafts((prev) => {
          const next = { ...prev };
          delete next[id];
          next[savedPack.id] = savedPack;
          return next;
        });
        setCreditPacks((prev) => [savedPack, ...prev]);
        setFormErrors((prev) => {
          const next = { ...prev };
          delete next[id];
          next[savedPack.id] = null;
          return next;
        });
        setDirtyIds((prev) => {
          const next = new Set(prev);
          next.delete(id);
          next.delete(savedPack.id);
          return next;
        });
      } else {
        setDrafts((prev) => ({ ...prev, [id]: savedPack }));
        setCreditPacks((prev) =>
          prev.map((pack) => (pack.id === id ? savedPack : pack))
        );
        setDirtyIds((prev) => {
          const next = new Set(prev);
          next.delete(id);
          return next;
        });
        setFormErrors((prev) => ({ ...prev, [id]: null }));
      }

      toast({
        title: isTemp ? 'Credit pack created' : 'Credit pack updated',
        description: 'Changes have been saved.',
      });
    } catch (error) {
      console.error('Failed to save credit pack', error);
      const message =
        error instanceof Error ? error.message : 'Unable to save credit pack.';
      setActionError(message);
      toast({
        title: 'Save failed',
        description: message,
        variant: 'destructive',
      });
    } finally {
      setSavingId(null);
    }
  };

  const handleDelete = async (id: string) => {
    if (id.startsWith('temp-')) {
      handleReset(id);
      return;
    }

    setDeletingId(id);
    setActionError(null);

    try {
      const response = await fetch(`/api/credit-packs/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        throw new Error(
          typeof payload?.error === 'string'
            ? payload.error
            : `Failed to delete credit pack (${response.status})`
        );
      }

      setCreditPacks((prev) => prev.filter((pack) => pack.id !== id));
      setDraftOrder((prev) => prev.filter((entry) => entry !== id));
      setDrafts((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
      setDirtyIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      setFormErrors((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });

      toast({
        title: 'Credit pack removed',
        description: 'Students will no longer see this pack.',
      });
    } catch (error) {
      console.error('Failed to delete credit pack', error);
      const message =
        error instanceof Error ? error.message : 'Unable to delete credit pack.';
      setActionError(message);
      toast({
        title: 'Delete failed',
        description: message,
        variant: 'destructive',
      });
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-xl font-semibold text-gray-900">
            Credit Pack Configuration
          </h3>
          <p className="text-gray-600">
            Adjust pricing, bonuses, and availability of student credit packs.
          </p>
        </div>
        <button
          onClick={handleAddPack}
          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          Add Credit Pack
        </button>
      </div>

      {actionError && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4">
          {actionError}
        </div>
      )}

      <div className="space-y-6">
        {combinedPacks.map((pack) => {
          const isDirty = dirtyIds.has(pack.id);
          const validationError = formErrors[pack.id] ?? null;
          const isSaving = savingId === pack.id;
          const isDeleting = deletingId === pack.id;
          const perCredit =
            pack.total_credits > 0
              ? (pack.price_cents / pack.total_credits / 100).toFixed(2)
              : '0.00';

          return (
            <div
              key={pack.id}
              className="border border-gray-200 rounded-lg p-6 bg-white shadow-sm space-y-4"
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <span className="text-sm font-semibold text-gray-700">
                  {pack.id.startsWith('temp-') ? 'New Pack' : `Pack ID: ${pack.id}`}
                </span>
                {isDirty && (
                  <span className="inline-flex items-center gap-1 text-xs font-medium text-blue-700 bg-blue-100 px-2 py-1 rounded-full">
                    <AlertCircle className="h-3 w-3" />
                    Unsaved changes
                  </span>
                )}
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Pack Name
                  </label>
                  <input
                    type="text"
                    value={pack.name}
                    onChange={(event) =>
                      handleInputChange(pack.id, 'name', event.target.value)
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    placeholder="e.g. Starter Pack"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Base Credits
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={pack.credit_amount}
                    onChange={(event) =>
                      handleInputChange(
                        pack.id,
                        'credit_amount',
                        event.target.value
                      )
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Price ($)
                  </label>
                  <input
                    type="number"
                    min={1}
                    step="0.01"
                    value={pack.price_formatted}
                    onChange={(event) =>
                      handleInputChange(
                        pack.id,
                        'price_formatted',
                        event.target.value
                      )
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Bonus Credits
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={pack.bonus_credits}
                    onChange={(event) =>
                      handleInputChange(
                        pack.id,
                        'bonus_credits',
                        event.target.value
                      )
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700">
                    Description
                  </label>
                  <textarea
                    value={pack.description}
                    onChange={(event) =>
                      handleInputChange(
                        pack.id,
                        'description',
                        event.target.value
                      )
                    }
                    rows={2}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Short marketing copy for this pack"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Display Order
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={pack.display_order ?? 0}
                    onChange={(event) =>
                      handleInputChange(
                        pack.id,
                        'display_order',
                        event.target.value
                      )
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                  <span>
                    Total Credits:{' '}
                    <span className="font-medium">{pack.total_credits}</span>
                  </span>
                  <span>
                    Value per Credit:{' '}
                    <span className="font-medium">${perCredit}</span>
                  </span>
                  <span>
                    Savings:{' '}
                    <span className="font-medium">
                      {pack.savings_percentage}%
                    </span>
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <label className="text-sm text-gray-700">Active</label>
                  <input
                    type="checkbox"
                    checked={pack.is_active}
                    onChange={(event) =>
                      handleToggleActive(pack.id, event.target.checked)
                    }
                    className="h-4 w-4 text-blue-600 border-gray-300 rounded"
                  />
                </div>
              </div>

              {validationError && (
                <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 rounded-md px-3 py-2 text-sm">
                  {validationError}
                </div>
              )}

              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleSave(pack.id)}
                    disabled={isSaving || isDeleting || !isDirty || Boolean(validationError)}
                    className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-60 disabled:cursor-not-allowed hover:bg-blue-700 transition-colors"
                  >
                    {isSaving ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Saving...
                      </>
                    ) : (
                      <>
                        <Save className="h-4 w-4" />
                        Save Changes
                      </>
                    )}
                  </button>
                  <button
                    onClick={() => handleReset(pack.id)}
                    disabled={isSaving || isDeleting}
                    className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
                  >
                    Reset
                  </button>
                </div>
                <button
                  onClick={() => handleDelete(pack.id)}
                  disabled={isSaving || isDeleting}
                  className="inline-flex items-center gap-2 px-4 py-2 border border-red-200 text-red-700 rounded-lg hover:bg-red-50 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
                >
                  {isDeleting ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Removing...
                    </>
                  ) : (
                    <>
                      <Trash2 className="h-4 w-4" />
                      Remove
                    </>
                  )}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function CommissionSettings({
  settings,
  setSettings,
  studioId,
  toast,
}: {
  settings: PricingSettings | null;
  setSettings: React.Dispatch<React.SetStateAction<PricingSettings | null>>;
  studioId: string | null;
  toast: ToastFn;
}) {
  const fallback = useMemo(
    () => ({
      commission_rate: 0.15,
      minimum_payout_cents: 2000,
      payout_frequency: 'weekly',
    }),
    []
  );

  const [draft, setDraft] = useState<PricingSettings>(settings ?? fallback);
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setDraft(settings ?? fallback);
    setDirty(false);
    setError(null);
  }, [settings, fallback]);

  const handleCommissionChange = (value: string) => {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return;
    const rate = Math.min(Math.max(parsed / 100, 0), 1);
    setDraft((prev) => ({
      ...prev,
      commission_rate: rate,
    }));
    setDirty(true);
  };

  const handlePayoutChange = (value: string) => {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return;
    setDraft((prev) => ({
      ...prev,
      minimum_payout_cents: Math.max(0, Math.round(parsed * 100)),
    }));
    setDirty(true);
  };

  const handleFrequencyChange = (value: PricingSettings['payout_frequency']) => {
    setDraft((prev) => ({
      ...prev,
      payout_frequency: value,
    }));
    setDirty(true);
  };

  const handleReset = () => {
    setDraft(settings ?? fallback);
    setDirty(false);
    setError(null);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);

    try {
      const payload = {
        settings: {
          commission_rate: Number(draft.commission_rate.toFixed(4)),
          minimum_payout_cents: Math.round(draft.minimum_payout_cents),
          payout_frequency: draft.payout_frequency as
            | 'daily'
            | 'weekly'
            | 'monthly',
        },
        studioId,
      };

      const response = await fetch('/api/pricing/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorPayload = await response.json().catch(() => ({}));
        throw new Error(
          typeof errorPayload?.error === 'string'
            ? errorPayload.error
            : `Failed to update settings (${response.status})`
        );
      }

      const data = await response.json();
      const saved: PricingSettings = data?.settings ?? draft;

      setSettings(saved);
      setDraft(saved);
      setDirty(false);
      toast({
        title: 'Commission settings updated',
        description: 'Payout preferences now reflect your latest changes.',
      });
    } catch (error) {
      console.error('Failed to update pricing settings', error);
      const message =
        error instanceof Error
          ? error.message
          : 'Unable to update pricing settings.';
      setError(message);
      toast({
        title: 'Update failed',
        description: message,
        variant: 'destructive',
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-xl font-semibold text-gray-900">
            Commission & Payout Settings
          </h3>
          <p className="text-gray-600">
            Configure platform commission, payout thresholds, and cadence.
          </p>
        </div>
        <div className="p-6 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Commission Rate (%)
              </label>
              <input
                type="number"
                min={0}
                max={100}
                step={0.1}
                value={(draft.commission_rate * 100).toFixed(1)}
                onChange={(event) => handleCommissionChange(event.target.value)}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
              <p className="mt-1 text-sm text-gray-500">
                Portion retained by the platform on each transaction.
              </p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Minimum Payout Amount ($)
              </label>
              <input
                type="number"
                min={0}
                step={1}
                value={(draft.minimum_payout_cents / 100).toFixed(2)}
                onChange={(event) => handlePayoutChange(event.target.value)}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
              <p className="mt-1 text-sm text-gray-500">
                Instructors are paid once earnings exceed this threshold.
              </p>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Payout Frequency
            </label>
            <select
              value={draft.payout_frequency}
              onChange={(event) =>
                handleFrequencyChange(
                  event.target.value as PricingSettings['payout_frequency']
                )
              }
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
            </select>
            <p className="mt-1 text-sm text-gray-500">
              Automated payouts run on this cadence once thresholds are met.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={handleSave}
              disabled={saving || !dirty}
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-60 disabled:cursor-not-allowed hover:bg-blue-700 transition-colors"
            >
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Saving...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4" />
                  Save Settings
                </>
              )}
            </button>
            <button
              onClick={handleReset}
              disabled={saving || !dirty}
              className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
            >
              Reset
            </button>
          </div>

          <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h4 className="text-sm font-medium text-blue-900">
              Commission Overview
            </h4>
            <ul className="mt-2 text-sm text-blue-800 space-y-1">
              <li>
                • Platform keeps {(draft.commission_rate * 100).toFixed(1)}% of
                each booking.
              </li>
              <li>
                • Instructors are paid out when earnings exceed $
                {(draft.minimum_payout_cents / 100).toFixed(2)}.
              </li>
              <li>• Payouts currently run on a {draft.payout_frequency} cadence.</li>
              <li>• Finance reports reflect these settings immediately.</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
