'use client';

import React, { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import PayoutDashboard from './PayoutDashboard';
import RevenueSharing from './RevenueSharing';
import CommissionCalculator from './CommissionCalculator';
import PayoutSchedule from './PayoutSchedule';
import FinancialReports from './FinancialReports';
import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { 
  DollarSign, 
  Calculator, 
  Percent, 
  Calendar, 
  FileText,
  TrendingUp,
  Shield,
  Info
} from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';

export default function PayoutsPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [activeTab, setActiveTab] = useState('dashboard');

  // Check if user has access to financial features
  const hasFinancialAccess = user?.role === 'admin' || user?.role === 'instructor';
  
  if (!hasFinancialAccess) {
    return (
      <div className="container mx-auto py-8">
        <Alert>
          <Shield className="h-4 w-4" />
          <AlertTitle>Access Restricted</AlertTitle>
          <AlertDescription>
            You don't have permission to access financial and payout features. 
            Please contact your administrator for access.
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div className="container mx-auto py-6 space-y-6">
      {/* Page Header */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-4xl font-bold tracking-tight">Revenue & Payouts</h1>
          <p className="text-muted-foreground mt-2">
            Manage instructor payouts, revenue sharing, and financial reporting
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-right">
            <p className="text-sm text-muted-foreground">Next Payout</p>
            <p className="text-lg font-semibold">Feb 1, 2024</p>
          </div>
          <div className="text-right">
            <p className="text-sm text-muted-foreground">Pending Amount</p>
            <p className="text-lg font-semibold text-green-600">$3,250</p>
          </div>
        </div>
      </div>

      {/* Quick Stats Alert */}
      <Alert className="border-blue-200 bg-blue-50">
        <TrendingUp className="h-4 w-4 text-blue-600" />
        <AlertTitle className="text-blue-900">Revenue Growth</AlertTitle>
        <AlertDescription className="text-blue-800">
          Your platform revenue has increased by 23.5% this month. 
          Total earnings across all instructors: <strong>$48,750</strong>
        </AlertDescription>
      </Alert>

      {/* Main Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-5 h-auto p-1">
          <TabsTrigger value="dashboard" className="flex flex-col gap-1 py-3">
            <DollarSign className="h-4 w-4" />
            <span className="text-xs">Dashboard</span>
          </TabsTrigger>
          <TabsTrigger value="revenue" className="flex flex-col gap-1 py-3">
            <Percent className="h-4 w-4" />
            <span className="text-xs">Revenue Sharing</span>
          </TabsTrigger>
          <TabsTrigger value="calculator" className="flex flex-col gap-1 py-3">
            <Calculator className="h-4 w-4" />
            <span className="text-xs">Calculator</span>
          </TabsTrigger>
          <TabsTrigger value="schedule" className="flex flex-col gap-1 py-3">
            <Calendar className="h-4 w-4" />
            <span className="text-xs">Schedule</span>
          </TabsTrigger>
          <TabsTrigger value="reports" className="flex flex-col gap-1 py-3">
            <FileText className="h-4 w-4" />
            <span className="text-xs">Reports</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="dashboard" className="space-y-6">
          <PayoutDashboard />
        </TabsContent>

        <TabsContent value="revenue" className="space-y-6">
          <RevenueSharing />
        </TabsContent>

        <TabsContent value="calculator" className="space-y-6">
          <CommissionCalculator />
        </TabsContent>

        <TabsContent value="schedule" className="space-y-6">
          <PayoutSchedule />
        </TabsContent>

        <TabsContent value="reports" className="space-y-6">
          <FinancialReports />
        </TabsContent>
      </Tabs>

      {/* Footer Info */}
      <Alert>
        <Info className="h-4 w-4" />
        <AlertTitle>Payment Processing</AlertTitle>
        <AlertDescription>
          All payouts are processed through Stripe Connect for security and compliance. 
          Instructors typically receive funds within 2-3 business days after processing. 
          For questions about payouts, contact finance@hobbyist.com
        </AlertDescription>
      </Alert>
    </div>
  );
}