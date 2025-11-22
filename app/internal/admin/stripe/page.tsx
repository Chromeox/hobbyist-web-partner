/**
 * Stripe Connect Management - Admin Portal
 *
 * Monitor and manage all Stripe Connected Accounts
 * - View all studio/instructor Stripe accounts
 * - Track onboarding completion status
 * - Monitor verification requirements
 * - View account capabilities
 * - Refresh account status from Stripe API
 */

'use client';

import React, { useState, useEffect } from 'react';
import {
  CreditCard,
  CheckCircle,
  Clock,
  AlertCircle,
  RefreshCw,
  ExternalLink,
  Shield,
  Building2,
  User,
  DollarSign,
  ChevronRight,
} from 'lucide-react';

interface StripeAccount {
  id: string;
  studioId: string;
  studioName: string;
  accountType: 'studio' | 'instructor';
  stripeAccountId: string;
  onboardingComplete: boolean;
  verificationStatus: 'verified' | 'pending' | 'unverified' | 'restricted';
  capabilities: {
    card_payments: string;
    transfers: string;
  };
  requirements: {
    currently_due: string[];
    eventually_due: string[];
    past_due: string[];
  };
  payoutsEnabled: boolean;
  chargesEnabled: boolean;
  createdAt: Date;
  lastUpdated: Date;
}

interface ConnectMetrics {
  total: number;
  active: number;
  pending: number;
  issues: number;
}

export default function StripeConnectPage() {
  const [accounts, setAccounts] = useState<StripeAccount[]>([]);
  const [metrics, setMetrics] = useState<ConnectMetrics>({
    total: 0,
    active: 0,
    pending: 0,
    issues: 0,
  });
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'active' | 'pending' | 'issues'>('all');
  const [expandedAccount, setExpandedAccount] = useState<string | null>(null);

  useEffect(() => {
    loadAccounts();
  }, []);

  const loadAccounts = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/internal/admin/stripe/accounts');
      if (response.ok) {
        const data = await response.json();
        setAccounts(data.accounts || []);
        calculateMetrics(data.accounts || []);
      }
    } catch (error) {
      console.error('Failed to load Stripe accounts:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateMetrics = (accountList: StripeAccount[]) => {
    const total = accountList.length;
    const active = accountList.filter(
      (acc) => acc.onboardingComplete && acc.verificationStatus === 'verified'
    ).length;
    const pending = accountList.filter(
      (acc) => !acc.onboardingComplete || acc.verificationStatus === 'pending'
    ).length;
    const issues = accountList.filter(
      (acc) =>
        acc.verificationStatus === 'restricted' ||
        acc.requirements.past_due.length > 0 ||
        !acc.payoutsEnabled
    ).length;

    setMetrics({ total, active, pending, issues });
  };

  const refreshAccountStatus = async (accountId: string) => {
    setRefreshing(true);
    try {
      const response = await fetch(
        `/api/internal/admin/stripe/accounts/${accountId}/refresh`,
        { method: 'POST' }
      );
      if (response.ok) {
        await loadAccounts();
      }
    } catch (error) {
      console.error('Failed to refresh account:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const refreshAllAccounts = async () => {
    setRefreshing(true);
    try {
      const response = await fetch('/api/internal/admin/stripe/accounts/refresh-all', {
        method: 'POST',
      });
      if (response.ok) {
        await loadAccounts();
      }
    } catch (error) {
      console.error('Failed to refresh all accounts:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const getFilteredAccounts = () => {
    switch (filter) {
      case 'active':
        return accounts.filter(
          (acc) => acc.onboardingComplete && acc.verificationStatus === 'verified'
        );
      case 'pending':
        return accounts.filter(
          (acc) => !acc.onboardingComplete || acc.verificationStatus === 'pending'
        );
      case 'issues':
        return accounts.filter(
          (acc) =>
            acc.verificationStatus === 'restricted' ||
            acc.requirements.past_due.length > 0 ||
            !acc.payoutsEnabled
        );
      default:
        return accounts;
    }
  };

  const getStatusBadge = (account: StripeAccount) => {
    if (account.verificationStatus === 'verified' && account.onboardingComplete) {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          <CheckCircle className="h-3 w-3 mr-1" />
          Active
        </span>
      );
    }

    if (account.requirements.past_due.length > 0 || account.verificationStatus === 'restricted') {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
          <AlertCircle className="h-3 w-3 mr-1" />
          Issues
        </span>
      );
    }

    return (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
        <Clock className="h-3 w-3 mr-1" />
        Pending
      </span>
    );
  };

  const getCapabilityStatus = (status: string) => {
    switch (status) {
      case 'active':
        return <span className="text-green-600 font-medium">Active</span>;
      case 'pending':
        return <span className="text-yellow-600 font-medium">Pending</span>;
      case 'inactive':
        return <span className="text-red-600 font-medium">Inactive</span>;
      default:
        return <span className="text-gray-500 font-medium">Unknown</span>;
    }
  };

  const filteredAccounts = getFilteredAccounts();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Stripe Connect</h1>
          <p className="text-gray-600 mt-1">Manage Stripe Connected Accounts for payouts</p>
        </div>
        <button
          onClick={refreshAllAccounts}
          disabled={refreshing}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          Refresh All
        </button>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <button
          onClick={() => setFilter('all')}
          className={`bg-white rounded-lg shadow p-6 text-left transition-all ${
            filter === 'all' ? 'ring-2 ring-blue-500' : 'hover:shadow-lg'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <CreditCard className="h-8 w-8 text-blue-600" />
          </div>
          <p className="text-sm text-gray-600">Total Accounts</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{metrics.total}</p>
        </button>

        <button
          onClick={() => setFilter('active')}
          className={`bg-white rounded-lg shadow p-6 text-left transition-all ${
            filter === 'active' ? 'ring-2 ring-green-500' : 'hover:shadow-lg'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <p className="text-sm text-gray-600">Active</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{metrics.active}</p>
        </button>

        <button
          onClick={() => setFilter('pending')}
          className={`bg-white rounded-lg shadow p-6 text-left transition-all ${
            filter === 'pending' ? 'ring-2 ring-yellow-500' : 'hover:shadow-lg'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
          <p className="text-sm text-gray-600">Pending Verification</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{metrics.pending}</p>
        </button>

        <button
          onClick={() => setFilter('issues')}
          className={`bg-white rounded-lg shadow p-6 text-left transition-all ${
            filter === 'issues' ? 'ring-2 ring-red-500' : 'hover:shadow-lg'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <AlertCircle className="h-8 w-8 text-red-600" />
          </div>
          <p className="text-sm text-gray-600">Issues</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{metrics.issues}</p>
        </button>
      </div>

      {/* Accounts List */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">
            Connected Accounts
            {filter !== 'all' && (
              <span className="ml-2 text-sm font-normal text-gray-500">
                ({filteredAccounts.length} {filter})
              </span>
            )}
          </h2>
        </div>

        {filteredAccounts.length === 0 ? (
          <div className="text-center py-12">
            <CreditCard className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500">
              {accounts.length === 0
                ? 'No Stripe accounts connected yet'
                : `No ${filter} accounts found`}
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {filteredAccounts.map((account) => (
              <div key={account.id} className="p-6 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4 flex-1">
                    <div className="flex-shrink-0">
                      {account.accountType === 'studio' ? (
                        <Building2 className="h-10 w-10 text-gray-400" />
                      ) : (
                        <User className="h-10 w-10 text-gray-400" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2">
                        <h3 className="text-sm font-medium text-gray-900 truncate">
                          {account.studioName}
                        </h3>
                        {getStatusBadge(account)}
                      </div>
                      <div className="mt-1 flex items-center space-x-4 text-sm text-gray-500">
                        <span className="font-mono text-xs">{account.stripeAccountId}</span>
                        <span>•</span>
                        <span className="capitalize">{account.accountType}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => refreshAccountStatus(account.id)}
                      disabled={refreshing}
                      className="p-2 text-gray-400 hover:text-gray-600 disabled:opacity-50"
                      title="Refresh Status"
                    >
                      <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
                    </button>
                    <button
                      onClick={() =>
                        setExpandedAccount(expandedAccount === account.id ? null : account.id)
                      }
                      className="p-2 text-gray-400 hover:text-gray-600"
                    >
                      <ChevronRight
                        className={`h-5 w-5 transition-transform ${
                          expandedAccount === account.id ? 'rotate-90' : ''
                        }`}
                      />
                    </button>
                  </div>
                </div>

                {/* Expanded Details */}
                {expandedAccount === account.id && (
                  <div className="mt-4 pt-4 border-t border-gray-200 space-y-4">
                    {/* Capabilities */}
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-2">Capabilities</h4>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm text-gray-600">Card Payments</span>
                          {getCapabilityStatus(account.capabilities.card_payments)}
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm text-gray-600">Transfers</span>
                          {getCapabilityStatus(account.capabilities.transfers)}
                        </div>
                      </div>
                    </div>

                    {/* Verification Requirements */}
                    {(account.requirements.currently_due.length > 0 ||
                      account.requirements.past_due.length > 0) && (
                      <div>
                        <h4 className="text-sm font-medium text-gray-900 mb-2">
                          Verification Requirements
                        </h4>
                        <div className="space-y-2">
                          {account.requirements.past_due.length > 0 && (
                            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                              <p className="text-sm font-medium text-red-900 mb-1">
                                Past Due ({account.requirements.past_due.length})
                              </p>
                              <ul className="text-xs text-red-700 list-disc list-inside">
                                {account.requirements.past_due.map((req, idx) => (
                                  <li key={idx}>{req}</li>
                                ))}
                              </ul>
                            </div>
                          )}
                          {account.requirements.currently_due.length > 0 && (
                            <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                              <p className="text-sm font-medium text-yellow-900 mb-1">
                                Currently Due ({account.requirements.currently_due.length})
                              </p>
                              <ul className="text-xs text-yellow-700 list-disc list-inside">
                                {account.requirements.currently_due.map((req, idx) => (
                                  <li key={idx}>{req}</li>
                                ))}
                              </ul>
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    {/* Account Status */}
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-2">Account Status</h4>
                      <div className="grid grid-cols-3 gap-4">
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <p className="text-xs text-gray-600 mb-1">Payouts</p>
                          <p className={`text-sm font-medium ${account.payoutsEnabled ? 'text-green-600' : 'text-red-600'}`}>
                            {account.payoutsEnabled ? 'Enabled' : 'Disabled'}
                          </p>
                        </div>
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <p className="text-xs text-gray-600 mb-1">Charges</p>
                          <p className={`text-sm font-medium ${account.chargesEnabled ? 'text-green-600' : 'text-red-600'}`}>
                            {account.chargesEnabled ? 'Enabled' : 'Disabled'}
                          </p>
                        </div>
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <p className="text-xs text-gray-600 mb-1">Verification</p>
                          <p className="text-sm font-medium capitalize">{account.verificationStatus}</p>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center space-x-3 pt-2">
                      {!account.onboardingComplete && (
                        <a
                          href={`/api/stripe/connect/onboard/${account.studioId}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm"
                        >
                          <ExternalLink className="h-4 w-4 mr-2" />
                          Complete Onboarding
                        </a>
                      )}
                      <a
                        href={`https://dashboard.stripe.com/connect/accounts/${account.stripeAccountId}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm"
                      >
                        <Shield className="h-4 w-4 mr-2" />
                        View in Stripe
                      </a>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
