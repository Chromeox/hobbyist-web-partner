'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  CreditCard, 
  TrendingUp, 
  Settings, 
  DollarSign, 
  Users, 
  Package,
  Info,
  Check,
  AlertCircle
} from 'lucide-react';

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

export default function PricingManagement() {
  const [activeTab, setActiveTab] = useState('overview');
  const [creditPacks, setCreditPacks] = useState<CreditPack[]>([]);
  const [pricingSettings, setPricingSettings] = useState<PricingSettings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPricingData();
  }, []);

  const loadPricingData = async () => {
    setLoading(true);
    try {
      // Mock data - in real implementation would call Supabase functions
      const mockCreditPacks: CreditPack[] = [
        {
          id: '1',
          name: 'Starter Pack',
          description: 'Perfect for trying out classes',
          credit_amount: 5,
          price_cents: 2500,
          bonus_credits: 0,
          is_active: true,
          display_order: 1,
          price_formatted: '25.00',
          total_credits: 5,
          savings_percentage: 0
        },
        {
          id: '2',
          name: 'Popular Pack',
          description: 'Best value for regular students',
          credit_amount: 12,
          price_cents: 5000,
          bonus_credits: 3,
          is_active: true,
          display_order: 2,
          price_formatted: '50.00',
          total_credits: 15,
          savings_percentage: 25
        },
        {
          id: '3',
          name: 'Premium Pack',
          description: 'Maximum savings for dedicated learners',
          credit_amount: 25,
          price_cents: 9000,
          bonus_credits: 10,
          is_active: true,
          display_order: 3,
          price_formatted: '90.00',
          total_credits: 35,
          savings_percentage: 40
        }
      ];

      const mockSettings: PricingSettings = {
        commission_rate: 0.15,
        minimum_payout_cents: 2000,
        payout_frequency: 'weekly'
      };

      setCreditPacks(mockCreditPacks);
      setPricingSettings(mockSettings);
    } catch (error) {
      console.error('Error loading pricing data:', error);
    } finally {
      setLoading(false);
    }
  };

  const tabs = [
    { id: 'overview', label: 'Pricing Overview', icon: DollarSign },
    { id: 'credit-packs', label: 'Credit Packs', icon: Package },
    { id: 'commission', label: 'Commission Settings', icon: Settings },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
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
          />
        )}
        {activeTab === 'commission' && (
          <CommissionSettings 
            settings={pricingSettings} 
            setSettings={setPricingSettings} 
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
            <h3 className="text-lg font-semibold text-blue-900">Simplified Credit-Based Pricing</h3>
            <p className="text-blue-800 mt-1">
              Our streamlined pricing system uses a 3-tier credit pack structure with a flat 15% commission rate. 
              Students purchase credit packs and use credits to book classes, providing predictable revenue and 
              simplified transaction processing.
            </p>
            <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-700">
              <div className="flex items-center space-x-2">
                <Check className="h-4 w-4" />
                <span>15% flat commission rate</span>
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
          <h3 className="text-lg font-semibold text-gray-900">Current Credit Packs</h3>
          <p className="text-gray-600">Active credit packs available for purchase</p>
        </div>
        <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
          {creditPacks.filter(pack => pack.is_active).map((pack) => (
            <div
              key={pack.id}
              className="border border-gray-200 rounded-lg p-4 hover:border-blue-300 transition-colors"
            >
              <div className="text-center">
                <h4 className="font-semibold text-gray-900">{pack.name}</h4>
                <p className="text-sm text-gray-600 mt-1">{pack.description}</p>
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
                {pack.savings_percentage > 0 && (
                  <div className="mt-2">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      {pack.savings_percentage}% savings
                    </span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function CreditPacksManagement({ 
  creditPacks, 
  setCreditPacks 
}: { 
  creditPacks: CreditPack[]; 
  setCreditPacks: React.Dispatch<React.SetStateAction<CreditPack[]>>; 
}) {
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Credit Pack Configuration</h3>
          <p className="text-gray-600">Current credit packs are optimized for maximum conversion and simplicity</p>
        </div>
        <div className="p-6">
          <div className="space-y-6">
            {creditPacks.map((pack, index) => (
              <div
                key={pack.id}
                className="border border-gray-200 rounded-lg p-6"
              >
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Pack Name
                    </label>
                    <input
                      type="text"
                      value={pack.name}
                      readOnly
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Base Credits
                    </label>
                    <input
                      type="number"
                      value={pack.credit_amount}
                      readOnly
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Price ($)
                    </label>
                    <input
                      type="text"
                      value={pack.price_formatted}
                      readOnly
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Bonus Credits
                    </label>
                    <input
                      type="number"
                      value={pack.bonus_credits}
                      readOnly
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                    />
                  </div>
                </div>
                <div className="mt-4">
                  <label className="block text-sm font-medium text-gray-700">
                    Description
                  </label>
                  <textarea
                    value={pack.description}
                    readOnly
                    rows={2}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                  />
                </div>
                <div className="mt-4 flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <span className="text-sm text-gray-600">
                      Total Credits: <span className="font-medium">{pack.total_credits}</span>
                    </span>
                    <span className="text-sm text-gray-600">
                      Value per Credit: <span className="font-medium">
                        ${(pack.price_cents / pack.total_credits / 100).toFixed(2)}
                      </span>
                    </span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <label className="text-sm text-gray-700">Active</label>
                    <input
                      type="checkbox"
                      checked={pack.is_active}
                      readOnly
                      className="h-4 w-4 text-blue-600 border-gray-300 rounded"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-start space-x-3">
              <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-yellow-800">Optimized Pricing Structure</h4>
                <p className="text-sm text-yellow-700 mt-1">
                  These credit packs have been optimized for conversion and simplicity. 
                  Contact support if you need to modify pricing tiers.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function CommissionSettings({ 
  settings, 
  setSettings 
}: { 
  settings: PricingSettings | null; 
  setSettings: React.Dispatch<React.SetStateAction<PricingSettings | null>>; 
}) {
  if (!settings) return null;

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Commission & Payout Settings</h3>
          <p className="text-gray-600">Simplified 15% flat rate commission structure</p>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Commission Rate
              </label>
              <div className="mt-1 relative rounded-md shadow-sm">
                <input
                  type="text"
                  value={`${(settings.commission_rate * 100).toFixed(1)}%`}
                  readOnly
                  className="block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Flat rate applied to all transactions
              </p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Minimum Payout Amount
              </label>
              <div className="mt-1 relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <span className="text-gray-500 sm:text-sm">$</span>
                </div>
                <input
                  type="text"
                  value={(settings.minimum_payout_cents / 100).toFixed(2)}
                  readOnly
                  className="block w-full pl-7 pr-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Minimum earnings before payout is initiated
              </p>
            </div>
          </div>
          <div className="mt-6">
            <label className="block text-sm font-medium text-gray-700">
              Payout Frequency
            </label>
            <select
              value={settings.payout_frequency}
              disabled
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-500"
            >
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
            </select>
            <p className="mt-1 text-sm text-gray-500">
              Automatic payout schedule for instructor earnings
            </p>
          </div>
          <div className="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h4 className="text-sm font-medium text-blue-900">How Commission Works</h4>
            <ul className="mt-2 text-sm text-blue-800 space-y-1">
              <li>• 15% platform commission on all bookings and credit pack sales</li>
              <li>• 85% goes to instructors as earnings</li>
              <li>• Automatic weekly payouts when minimum threshold is reached</li>
              <li>• Transparent reporting and real-time earnings tracking</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}