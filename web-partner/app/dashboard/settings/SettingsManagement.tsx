'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  Settings,
  Building2,
  CreditCard,
  Bell,
  Shield,
  Globe,
  Users,
  Calendar,
  DollarSign,
  Mail,
  Phone,
  MapPin,
  Clock,
  Star,
  Eye,
  EyeOff,
  Save,
  X,
  Check,
  AlertTriangle,
  Info,
  Crown,
  Zap,
  BarChart3,
  FileSpreadsheet,
  Square,
  Coins,
  ToggleLeft,
  ToggleRight
} from 'lucide-react';

interface StudioSettings {
  // Business Information
  studioName: string;
  legalName: string;
  description: string;
  website: string;
  email: string;
  phone: string;
  address: {
    street: string;
    city: string;
    province: string;
    zipCode: string;
    country: string;
  };
  
  // Operational Settings
  timezone: string;
  currency: string;
  businessHours: {
    [key: string]: { open: string; close: string; closed: boolean };
  };
  
  // Booking Settings
  bookingPolicy: {
    cancellationWindow: number; // hours
    refundPolicy: 'full' | 'partial' | 'none';
    waitlistEnabled: boolean;
    requirePayment: boolean;
    allowSameDay: boolean;
  };
  
  // Payment Model Settings
  paymentModel: {
    mode: 'credits' | 'cash' | 'hybrid';
    creditPacksEnabled: boolean;
    cashPaymentsEnabled: boolean;
    defaultCreditsPerClass: number;
    allowMixedPayments: boolean;
    creditExpiration: number | null; // days, null for no expiration
    commissionRate: number; // percentage
  };
  
  // Notification Settings
  notifications: {
    newBookings: boolean;
    cancellations: boolean;
    payments: boolean;
    reviews: boolean;
    lowCapacity: boolean;
    staffUpdates: boolean;
  };
  
  // Privacy Settings
  privacy: {
    showInstructor: boolean;
    showCapacity: boolean;
    allowReviews: boolean;
    publicProfile: boolean;
  };
}

interface SubscriptionPlan {
  id: string;
  name: string;
  price: number;
  interval: 'month' | 'year';
  features: string[];
  limits: {
    classes: number | 'unlimited';
    students: number | 'unlimited';
    staff: number | 'unlimited';
    storage: string;
  };
  isPopular?: boolean;
}

const subscriptionPlans: SubscriptionPlan[] = [
  {
    id: 'starter',
    name: 'Starter',
    price: 29,
    interval: 'month',
    features: [
      'Up to 10 classes per month',
      'Up to 100 students',
      '2 staff members',
      'Basic analytics',
      'Email support'
    ],
    limits: {
      classes: 10,
      students: 100,
      staff: 2,
      storage: '1GB'
    }
  },
  {
    id: 'professional',
    name: 'Professional',
    price: 79,
    interval: 'month',
    features: [
      'Up to 50 classes per month',
      'Up to 500 students',
      '10 staff members',
      'Advanced analytics',
      'Priority support',
      'Custom branding'
    ],
    limits: {
      classes: 50,
      students: 500,
      staff: 10,
      storage: '10GB'
    },
    isPopular: true
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    price: 199,
    interval: 'month',
    features: [
      'Unlimited classes',
      'Unlimited students',
      'Unlimited staff',
      'Advanced analytics & reports',
      'Priority support',
      'Custom branding',
      'API access',
      'Custom integrations'
    ],
    limits: {
      classes: 'unlimited',
      students: 'unlimited',
      staff: 'unlimited',
      storage: '100GB'
    }
  }
];

const mockSettings: StudioSettings = {
  studioName: 'Zenith Wellness Studio',
  legalName: 'Zenith Wellness LLC',
  description: 'A premium wellness studio offering yoga, pilates, and meditation classes in downtown San Francisco.',
  website: 'https://zenithwellness.com',
  email: 'contact@zenithwellness.com',
  phone: '(415) 555-0123',
  address: {
    street: '123 Wellness Ave',
    city: 'San Francisco',
    province: 'BC',
    zipCode: '94102',
    country: 'US'
  },
  timezone: 'America/Los_Angeles',
  currency: 'USD',
  businessHours: {
    monday: { open: '06:00', close: '22:00', closed: false },
    tuesday: { open: '06:00', close: '22:00', closed: false },
    wednesday: { open: '06:00', close: '22:00', closed: false },
    thursday: { open: '06:00', close: '22:00', closed: false },
    friday: { open: '06:00', close: '22:00', closed: false },
    saturday: { open: '08:00', close: '20:00', closed: false },
    sunday: { open: '08:00', close: '18:00', closed: false }
  },
  bookingPolicy: {
    cancellationWindow: 24,
    refundPolicy: 'partial',
    waitlistEnabled: true,
    requirePayment: true,
    allowSameDay: false
  },
  notifications: {
    newBookings: true,
    cancellations: true,
    payments: true,
    reviews: true,
    lowCapacity: false,
    staffUpdates: true
  },
  privacy: {
    showInstructor: true,
    showCapacity: true,
    allowReviews: true,
    publicProfile: true
  },
  paymentModel: {
    mode: 'hybrid' as const,
    creditPacksEnabled: true,
    cashPaymentsEnabled: true,
    defaultCreditsPerClass: 2,
    allowMixedPayments: true,
    creditExpiration: 365,
    commissionRate: 15
  }
};

export default function SettingsManagement() {
  const [settings, setSettings] = useState<StudioSettings>(mockSettings);
  const [activeTab, setActiveTab] = useState('general');
  const [currentPlan, setCurrentPlan] = useState('professional');
  const [showPassword, setShowPassword] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  const tabs = [
    { id: 'general', label: 'General', icon: Building2 },
    { id: 'payment', label: 'Payment Model', icon: Coins },
    { id: 'billing', label: 'Billing & Plans', icon: CreditCard },
    { id: 'bookings', label: 'Booking Policy', icon: Calendar },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'privacy', label: 'Privacy', icon: Shield },
    { id: 'integrations', label: 'Integrations', icon: Globe }
  ];

  const handleSettingsChange = (section: string, field: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [section]: {
        ...(prev[section as keyof StudioSettings] as any),
        [field]: value
      }
    }));
    setHasChanges(true);
  };

  const handleSaveSettings = async () => {
    setIsSaving(true);
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    setHasChanges(false);
    setIsSaving(false);
  };

  const handlePlanChange = (planId: string) => {
    setCurrentPlan(planId);
    // In a real app, this would trigger billing changes
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
          <p className="text-gray-600 mt-1">Manage your studio preferences and configuration</p>
        </div>
        
        {hasChanges && (
          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                setSettings(mockSettings);
                setHasChanges(false);
              }}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center"
            >
              <X className="h-4 w-4 mr-2" />
              Discard
            </button>
            
            <button
              onClick={handleSaveSettings}
              disabled={isSaving}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center disabled:opacity-50"
            >
              {isSaving ? (
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2" />
              ) : (
                <Save className="h-4 w-4 mr-2" />
              )}
              Save Changes
            </button>
          </div>
        )}
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Sidebar */}
        <div className="lg:w-64">
          <nav className="space-y-1">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center px-3 py-2 text-left rounded-lg transition-colors ${
                    activeTab === tab.id
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <Icon className={`h-5 w-5 mr-3 ${
                    activeTab === tab.id ? 'text-blue-700' : 'text-gray-500'
                  }`} />
                  {tab.label}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Content */}
        <div className="flex-1">
          <div className="bg-white rounded-xl shadow-sm border">
            {/* General Settings */}
            {activeTab === 'general' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Studio Information</h2>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Studio Name
                      </label>
                      <input
                        type="text"
                        value={settings.studioName}
                        onChange={(e) => setSettings(prev => ({ ...prev, studioName: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Legal Business Name
                      </label>
                      <input
                        type="text"
                        value={settings.legalName}
                        onChange={(e) => setSettings(prev => ({ ...prev, legalName: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Description
                      </label>
                      <textarea
                        rows={3}
                        value={settings.description}
                        onChange={(e) => setSettings(prev => ({ ...prev, description: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Website
                      </label>
                      <input
                        type="url"
                        value={settings.website}
                        onChange={(e) => setSettings(prev => ({ ...prev, website: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Email
                      </label>
                      <input
                        type="email"
                        value={settings.email}
                        onChange={(e) => setSettings(prev => ({ ...prev, email: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Phone
                      </label>
                      <input
                        type="tel"
                        value={settings.phone}
                        onChange={(e) => setSettings(prev => ({ ...prev, phone: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                  </div>
                </div>

                {/* Address */}
                <div>
                  <h3 className="text-md font-semibold text-gray-900 mb-4">Address</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Street Address
                      </label>
                      <input
                        type="text"
                        value={settings.address.street}
                        onChange={(e) => handleSettingsChange('address', 'street', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        City
                      </label>
                      <input
                        type="text"
                        value={settings.address.city}
                        onChange={(e) => handleSettingsChange('address', 'city', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Province
                      </label>
                      <input
                        type="text"
                        value={settings.address.province}
                        onChange={(e) => handleSettingsChange('address', 'province', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                  </div>
                </div>

                {/* Operational Settings */}
                <div>
                  <h3 className="text-md font-semibold text-gray-900 mb-4">Operational Settings</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Timezone
                      </label>
                      <select
                        value={settings.timezone}
                        onChange={(e) => setSettings(prev => ({ ...prev, timezone: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      >
                        <option value="America/Los_Angeles">Pacific Time</option>
                        <option value="America/Denver">Mountain Time</option>
                        <option value="America/Chicago">Central Time</option>
                        <option value="America/New_York">Eastern Time</option>
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Currency
                      </label>
                      <select
                        value={settings.currency}
                        onChange={(e) => setSettings(prev => ({ ...prev, currency: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      >
                        <option value="USD">USD ($)</option>
                        <option value="CAD">CAD ($)</option>
                        <option value="EUR">EUR (€)</option>
                        <option value="GBP">GBP (£)</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Payment Model Settings */}
            {activeTab === 'payment' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Payment Model Configuration</h2>
                  <p className="text-gray-600 mb-6">Configure how your studio accepts payments from students</p>
                  
                  {/* Payment Mode Selection */}
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-3">
                        Payment Model
                      </label>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <button
                          onClick={() => handleSettingsChange('paymentModel', 'mode', 'credits')}
                          className={`relative p-4 rounded-lg border-2 transition-all ${
                            settings.paymentModel.mode === 'credits'
                              ? 'border-blue-500 bg-blue-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <Coins className="h-8 w-8 mb-2 text-blue-600" />
                          <h3 className="font-semibold text-gray-900">Credits Only</h3>
                          <p className="text-sm text-gray-600 mt-1">
                            Students purchase credit packs and use credits for classes
                          </p>
                          {settings.paymentModel.mode === 'credits' && (
                            <Check className="absolute top-2 right-2 h-5 w-5 text-blue-600" />
                          )}
                        </button>
                        
                        <button
                          onClick={() => handleSettingsChange('paymentModel', 'mode', 'cash')}
                          className={`relative p-4 rounded-lg border-2 transition-all ${
                            settings.paymentModel.mode === 'cash'
                              ? 'border-blue-500 bg-blue-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <DollarSign className="h-8 w-8 mb-2 text-green-600" />
                          <h3 className="font-semibold text-gray-900">Cash Only</h3>
                          <p className="text-sm text-gray-600 mt-1">
                            Traditional payment per class with cash or card
                          </p>
                          {settings.paymentModel.mode === 'cash' && (
                            <Check className="absolute top-2 right-2 h-5 w-5 text-blue-600" />
                          )}
                        </button>
                        
                        <button
                          onClick={() => handleSettingsChange('paymentModel', 'mode', 'hybrid')}
                          className={`relative p-4 rounded-lg border-2 transition-all ${
                            settings.paymentModel.mode === 'hybrid'
                              ? 'border-blue-500 bg-blue-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <CreditCard className="h-8 w-8 mb-2 text-purple-600" />
                          <h3 className="font-semibold text-gray-900">Hybrid</h3>
                          <p className="text-sm text-gray-600 mt-1">
                            Accept both credits and traditional payments
                          </p>
                          {settings.paymentModel.mode === 'hybrid' && (
                            <Check className="absolute top-2 right-2 h-5 w-5 text-blue-600" />
                          )}
                        </button>
                      </div>
                    </div>

                    {/* Credit Settings - Show when credits or hybrid is selected */}
                    {(settings.paymentModel.mode === 'credits' || settings.paymentModel.mode === 'hybrid') && (
                      <div className="border-t pt-6 space-y-4">
                        <h3 className="font-medium text-gray-900 mb-4">Credit Settings</h3>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Default Credits Per Class
                          </label>
                          <input
                            type="number"
                            value={settings.paymentModel.defaultCreditsPerClass}
                            onChange={(e) => handleSettingsChange('paymentModel', 'defaultCreditsPerClass', parseInt(e.target.value))}
                            className="w-32 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                            min="1"
                            max="10"
                          />
                          <p className="text-sm text-gray-500 mt-1">
                            Standard number of credits required for most classes
                          </p>
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Credit Expiration (days)
                          </label>
                          <input
                            type="number"
                            value={settings.paymentModel.creditExpiration || ''}
                            onChange={(e) => handleSettingsChange('paymentModel', 'creditExpiration', 
                              e.target.value ? parseInt(e.target.value) : null)}
                            className="w-32 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                            placeholder="No expiration"
                          />
                          <p className="text-sm text-gray-500 mt-1">
                            Leave empty for credits that never expire
                          </p>
                        </div>
                        
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-medium text-gray-900">Enable Credit Packs</p>
                            <p className="text-sm text-gray-600">Allow bulk purchase of credits at discounted rates</p>
                          </div>
                          <label className="relative inline-flex items-center cursor-pointer">
                            <input
                              type="checkbox"
                              checked={settings.paymentModel.creditPacksEnabled}
                              onChange={(e) => handleSettingsChange('paymentModel', 'creditPacksEnabled', e.target.checked)}
                              className="sr-only peer"
                            />
                            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                          </label>
                        </div>
                      </div>
                    )}

                    {/* Hybrid Settings - Show only when hybrid is selected */}
                    {settings.paymentModel.mode === 'hybrid' && (
                      <div className="border-t pt-6 space-y-4">
                        <h3 className="font-medium text-gray-900 mb-4">Hybrid Payment Settings</h3>
                        
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-medium text-gray-900">Allow Mixed Payments</p>
                            <p className="text-sm text-gray-600">Let students combine credits with cash for a single booking</p>
                          </div>
                          <label className="relative inline-flex items-center cursor-pointer">
                            <input
                              type="checkbox"
                              checked={settings.paymentModel.allowMixedPayments}
                              onChange={(e) => handleSettingsChange('paymentModel', 'allowMixedPayments', e.target.checked)}
                              className="sr-only peer"
                            />
                            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                          </label>
                        </div>
                        
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-medium text-gray-900">Accept Cash Payments</p>
                            <p className="text-sm text-gray-600">Allow traditional per-class payments</p>
                          </div>
                          <label className="relative inline-flex items-center cursor-pointer">
                            <input
                              type="checkbox"
                              checked={settings.paymentModel.cashPaymentsEnabled}
                              onChange={(e) => handleSettingsChange('paymentModel', 'cashPaymentsEnabled', e.target.checked)}
                              className="sr-only peer"
                            />
                            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                          </label>
                        </div>
                      </div>
                    )}

                    {/* Commission Settings */}
                    <div className="border-t pt-6">
                      <h3 className="font-medium text-gray-900 mb-4">Platform Commission</h3>
                      
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Commission Rate (%)
                        </label>
                        <div className="flex items-center gap-2">
                          <input
                            type="number"
                            value={settings.paymentModel.commissionRate}
                            onChange={(e) => handleSettingsChange('paymentModel', 'commissionRate', parseFloat(e.target.value))}
                            className="w-24 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                            min="0"
                            max="30"
                            step="0.5"
                          />
                          <span className="text-gray-600">%</span>
                        </div>
                        <p className="text-sm text-gray-500 mt-1">
                          Platform fee charged on all transactions
                        </p>
                      </div>
                    </div>

                    {/* Info Box */}
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                      <div className="flex">
                        <Info className="h-5 w-5 text-blue-600 mt-0.5 mr-3" />
                        <div>
                          <h4 className="font-medium text-blue-900">Payment Model Impact</h4>
                          <p className="text-sm text-blue-700 mt-1">
                            {settings.paymentModel.mode === 'credits' && 
                              "Credit-only mode encourages bulk purchases and improves cash flow. Students buy credits upfront and spend them over time."}
                            {settings.paymentModel.mode === 'cash' && 
                              "Cash-only mode uses traditional per-class payments. Simple and familiar for most studios and students."}
                            {settings.paymentModel.mode === 'hybrid' && 
                              "Hybrid mode offers maximum flexibility. Perfect for transitioning to credits or serving diverse customer preferences."}
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Billing & Plans */}
            {activeTab === 'billing' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-2">Subscription Plans</h2>
                  <p className="text-gray-600 mb-6">Choose the plan that best fits your studio's needs</p>
                  
                  <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {subscriptionPlans.map((plan) => (
                      <div
                        key={plan.id}
                        className={`relative rounded-xl border-2 p-6 ${
                          currentPlan === plan.id
                            ? 'border-blue-500 bg-blue-50'
                            : 'border-gray-200 bg-white hover:border-gray-300'
                        }`}
                      >
                        {plan.isPopular && (
                          <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                            <span className="bg-blue-600 text-white px-3 py-1 text-sm font-medium rounded-full">
                              Most Popular
                            </span>
                          </div>
                        )}
                        
                        <div className="text-center mb-6">
                          <h3 className="text-xl font-semibold text-gray-900">{plan.name}</h3>
                          <div className="mt-2">
                            <span className="text-3xl font-bold text-gray-900">${plan.price}</span>
                            <span className="text-gray-600">/{plan.interval}</span>
                          </div>
                        </div>
                        
                        <ul className="space-y-3 mb-6">
                          {plan.features.map((feature, index) => (
                            <li key={index} className="flex items-center text-sm">
                              <Check className="h-4 w-4 text-green-600 mr-2 flex-shrink-0" />
                              {feature}
                            </li>
                          ))}
                        </ul>
                        
                        <button
                          onClick={() => handlePlanChange(plan.id)}
                          className={`w-full py-2 px-4 rounded-lg font-medium transition-colors ${
                            currentPlan === plan.id
                              ? 'bg-blue-600 text-white'
                              : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
                          }`}
                        >
                          {currentPlan === plan.id ? 'Current Plan' : 'Select Plan'}
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="border-t pt-6">
                  <h3 className="text-md font-semibold text-gray-900 mb-4">Payment Method</h3>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <CreditCard className="h-6 w-6 text-gray-600 mr-3" />
                        <div>
                          <p className="font-medium">•••• •••• •••• 4242</p>
                          <p className="text-sm text-gray-600">Expires 12/2027</p>
                        </div>
                      </div>
                      <button className="text-blue-600 hover:text-blue-700 font-medium">
                        Update
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Booking Policy */}
            {activeTab === 'bookings' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Booking Policy</h2>
                  
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Cancellation Window (hours before class)
                      </label>
                      <input
                        type="number"
                        value={settings.bookingPolicy.cancellationWindow}
                        onChange={(e) => handleSettingsChange('bookingPolicy', 'cancellationWindow', parseInt(e.target.value))}
                        className="w-full md:w-48 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                      <p className="text-sm text-gray-500 mt-1">
                        Students can cancel up to this many hours before class starts
                      </p>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Refund Policy
                      </label>
                      <select
                        value={settings.bookingPolicy.refundPolicy}
                        onChange={(e) => handleSettingsChange('bookingPolicy', 'refundPolicy', e.target.value)}
                        className="w-full md:w-48 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      >
                        <option value="full">Full Refund</option>
                        <option value="partial">Partial Refund</option>
                        <option value="none">No Refund</option>
                      </select>
                    </div>
                    
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-gray-900">Enable Waitlist</p>
                          <p className="text-sm text-gray-600">Allow students to join waitlist when classes are full</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={settings.bookingPolicy.waitlistEnabled}
                            onChange={(e) => handleSettingsChange('bookingPolicy', 'waitlistEnabled', e.target.checked)}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-gray-900">Require Payment</p>
                          <p className="text-sm text-gray-600">Require payment at time of booking</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={settings.bookingPolicy.requirePayment}
                            onChange={(e) => handleSettingsChange('bookingPolicy', 'requirePayment', e.target.checked)}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-gray-900">Allow Same-Day Booking</p>
                          <p className="text-sm text-gray-600">Allow students to book classes on the same day</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={settings.bookingPolicy.allowSameDay}
                            onChange={(e) => handleSettingsChange('bookingPolicy', 'allowSameDay', e.target.checked)}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Notifications */}
            {activeTab === 'notifications' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Notification Preferences</h2>
                  <p className="text-gray-600 mb-6">Choose which notifications you'd like to receive</p>
                  
                  <div className="space-y-4">
                    {Object.entries(settings.notifications).map(([key, value]) => (
                      <div key={key} className="flex items-center justify-between py-2">
                        <div>
                          <p className="font-medium text-gray-900">
                            {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                          </p>
                          <p className="text-sm text-gray-600">
                            {key === 'newBookings' && 'Get notified when students book classes'}
                            {key === 'cancellations' && 'Get notified when bookings are cancelled'}
                            {key === 'payments' && 'Get notified about payment activities'}
                            {key === 'reviews' && 'Get notified when students leave reviews'}
                            {key === 'lowCapacity' && 'Get notified when class capacity is low'}
                            {key === 'staffUpdates' && 'Get notified about staff-related updates'}
                          </p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={value}
                            onChange={(e) => handleSettingsChange('notifications', key, e.target.checked)}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Privacy */}
            {activeTab === 'privacy' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Privacy Settings</h2>
                  <p className="text-gray-600 mb-6">Control what information is visible to students</p>
                  
                  <div className="space-y-4">
                    {Object.entries(settings.privacy).map(([key, value]) => (
                      <div key={key} className="flex items-center justify-between py-2">
                        <div>
                          <p className="font-medium text-gray-900">
                            {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                          </p>
                          <p className="text-sm text-gray-600">
                            {key === 'showInstructor' && 'Show instructor names on class listings'}
                            {key === 'showCapacity' && 'Show current class capacity to students'}
                            {key === 'allowReviews' && 'Allow students to leave reviews and ratings'}
                            {key === 'publicProfile' && 'Make studio profile visible in public directory'}
                          </p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={value}
                            onChange={(e) => handleSettingsChange('privacy', key, e.target.checked)}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Integrations */}
            {activeTab === 'integrations' && (
              <div className="p-6 space-y-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">Integrations</h2>
                  <p className="text-gray-600 mb-6">Connect with third-party services to enhance your studio</p>
                  
                  <div className="space-y-4">
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="h-10 w-10 bg-blue-100 rounded-lg flex items-center justify-center mr-3">
                            <BarChart3 className="h-5 w-5 text-blue-600" />
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">Google Analytics</h3>
                            <p className="text-sm text-gray-600">Track website visitors and booking conversions</p>
                          </div>
                        </div>
                        <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
                          Connect
                        </button>
                      </div>
                    </div>
                    
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="h-10 w-10 bg-green-100 rounded-lg flex items-center justify-center mr-3">
                            <Mail className="h-5 w-5 text-green-600" />
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">Mailchimp</h3>
                            <p className="text-sm text-gray-600">Send automated emails and newsletters</p>
                          </div>
                        </div>
                        <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
                          Connected
                        </button>
                      </div>
                    </div>
                    
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="h-10 w-10 bg-purple-100 rounded-lg flex items-center justify-center mr-3">
                            <Zap className="h-5 w-5 text-purple-600" />
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">Zapier</h3>
                            <p className="text-sm text-gray-600">Automate workflows with thousands of apps</p>
                          </div>
                        </div>
                        <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
                          Connect
                        </button>
                      </div>
                    </div>
                    
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="h-10 w-10 bg-yellow-100 rounded-lg flex items-center justify-center mr-3">
                            <FileSpreadsheet className="h-5 w-5 text-yellow-600" />
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">Google Sheets</h3>
                            <p className="text-sm text-gray-600">Sync bookings and student data to spreadsheets</p>
                          </div>
                        </div>
                        <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
                          Connect
                        </button>
                      </div>
                    </div>
                    
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="h-10 w-10 bg-indigo-100 rounded-lg flex items-center justify-center mr-3">
                            <Square className="h-5 w-5 text-indigo-600" />
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">Square Appointments</h3>
                            <p className="text-sm text-gray-600">Sync with Square's booking and payment system</p>
                          </div>
                        </div>
                        <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
                          Connect
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}