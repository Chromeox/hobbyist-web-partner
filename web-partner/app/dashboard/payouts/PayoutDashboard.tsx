'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { usePaymentModel } from '@/contexts/PaymentModelContext';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/lib/supabase';
import {
  DollarSign,
  TrendingUp,
  TrendingDown,
  Calendar,
  Download,
  CreditCard,
  AlertCircle,
  Clock,
  CheckCircle,
  Users,
  Activity,
  FileText,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';
import { format, subDays, startOfMonth, endOfMonth } from 'date-fns';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  Area,
  AreaChart
} from 'recharts';

// Interfaces for data structures used in the dashboard
interface PayoutSummary {
  totalEarnings: number;
  pendingPayouts: number;
  completedPayouts: number;
  nextPayoutDate: Date;
  nextPayoutAmount: number;
  totalStudents: number;
  averageClassValue: number;
  growthRate: number;
}

interface PayoutHistory {
  id: string;
  date: Date;
  amount: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  method: 'stripe' | 'bank_transfer' | 'paypal';
  transactionId?: string;
  classCount: number;
  commissionRate: number;
  netAmount: number;
}

interface EarningsBreakdown {
  venue: string;
  venueId: string;
  totalRevenue: number;
  commission: number;
  netEarnings: number;
  classCount: number;
  studentCount: number;
}

// Main PayoutDashboard component
const PayoutDashboard: React.FC = () => {
  // Hooks for authentication, payment model, and Supabase client
  const { user } = useAuth();
  const { paymentModel } = usePaymentModel(); // Assuming this context provides payment-related info
  
  // State variables for loading, date range, and fetched data
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('30');
  const [summary, setSummary] = useState<PayoutSummary | null>(null);
  const [payoutHistory, setPayoutHistory] = useState<PayoutHistory[]>([]);
  const [earningsBreakdown, setEarningsBreakdown] = useState<EarningsBreakdown[]>([]);
  const [chartData, setChartData] = useState<any[]>([]);
  const [selectedVenue, setSelectedVenue] = useState<string>('all'); // For future filtering by venue

  // Effect hook to fetch payout data when user, dateRange, or selectedVenue changes
  useEffect(() => {
    if (user) {
      fetchPayoutData();
    }
  }, [user, dateRange, selectedVenue]);

  // Function to fetch payout data from Supabase
  const fetchPayoutData = async () => {
    try {
      setLoading(true);

      // Ensure user is authenticated before fetching data
      if (!user?.id) {
        console.error('User not authenticated. Cannot fetch payout data.');
        setLoading(false);
        return;
      }

      // --- Fetch Summary Data ---
      // Queries the 'payout_summaries' table for the user's overall payout summary.
      const { data: summaryData, error: summaryError } = await supabase
        .from('payout_summaries')
        .select('*')
        .eq('user_id', user.id) // Filter by the logged-in user's ID
        .single(); // Expecting a single summary record per user

      if (summaryError) throw summaryError;
      setSummary(summaryData);

      // --- Fetch Payout History ---
      // Retrieves historical payout records for the user.
      const { data: historyData, error: historyError } = await supabase
        .from('payout_history')
        .select('*')
        .eq('user_id', user.id) // Filter by user ID
        .order('date', { ascending: false }); // Order by date, newest first

      if (historyError) throw historyError;
      setPayoutHistory(historyData);

      // --- Fetch Earnings Breakdown by Venue ---
      // Gets a breakdown of earnings, potentially filtered by venue.
      const { data: breakdownData, error: breakdownError } = await supabase
        .from('earnings_breakdown')
        .select('*')
        .eq('user_id', user.id); // Filter by user ID

      if (breakdownError) throw breakdownError;
      setEarningsBreakdown(breakdownData);

      // --- Generate Chart Data ---
      // Fetches class data to populate the earnings, classes, and students charts.
      const startDate = subDays(new Date(), parseInt(dateRange)); // Calculate start date based on selected range
      const endDate = new Date();

      const { data: classesData, error: classesError } = await supabase
        .from('classes')
        .select('created_at, total_bookings, revenue') // Select relevant columns for charting
        .eq('instructor_id', user.id) // Filter by instructor ID
        .gte('created_at', startDate.toISOString()) // Filter by date range (greater than or equal to start date)
        .lte('created_at', endDate.toISOString()) // Filter by date range (less than or equal to end date)
        .order('created_at', { ascending: true }); // Order by creation date for chart display

      if (classesError) throw classesError;

      // Process fetched class data into a format suitable for the charts
      const chart = classesData.map(cls => ({
        date: format(new Date(cls.created_at), 'MMM dd'), // Format date for X-axis
        earnings: cls.revenue || 0, // Use revenue for earnings chart
        classes: cls.total_bookings || 0, // Use total bookings for classes chart
        students: 0 // Placeholder: Actual student count per class would need a more complex query
      }));
      setChartData(chart);

    } catch (error: any) {
      // --- Error Handling ---
      // Logs the error and resets data states to empty/null.
      // In a production app, you would display a user-friendly error message in the UI.
      console.error('Error fetching payout data:', error.message);
      setSummary(null);
      setPayoutHistory([]);
      setEarningsBreakdown([]);
      setChartData([]);
    } finally {
      setLoading(false); // Always set loading to false after data fetch attempt
    }
  };

  // Helper function to determine the icon for payout status
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-500" />;
      case 'processing':
        return <Activity className="w-4 h-4 text-blue-500" />;
      case 'failed':
        return <AlertCircle className="w-4 h-4 text-red-500" />;
      default:
        return null;
    }
  };

  // Helper function to determine the color for payout status badge
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'processing': return 'bg-blue-100 text-blue-800';
      case 'failed': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  // Display a loading spinner while data is being fetched
  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Function to handle updating payment method (Stripe Connect onboarding)
  const handleUpdatePaymentMethod = async () => {
    if (!user?.id) {
      console.error('User not authenticated. Cannot create Stripe account link.');
      // In a production app, you would show a user-friendly error message here.
      return;
    }

    try {
      setLoading(true); // Show loading state during API call
      // Call your backend API route to create a Stripe Connect Account Link.
      // This API route (e.g., /api/stripe/create-account-link) would:
      // 1. Verify the authenticated user.
      // 2. Create or retrieve a Stripe Connect Account for the user.
      // 3. Create an Account Link for that Stripe Connect Account.
      // 4. Return the URL of the Account Link to the frontend.
      const response = await fetch('/api/stripe/create-account-link', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: user.id }), // Pass user ID to backend for association
      });

      const data = await response.json();

      if (response.ok && data.url) {
        // Redirect the user to the Stripe onboarding URL to complete the process.
        window.location.href = data.url;
      } else {
        console.error('Failed to create Stripe account link:', data.error || 'Unknown error');
        // Display an error message to the user if the link creation fails.
      }
    } catch (error: any) {
      console.error('Error creating Stripe account link:', error.message);
      // Display a generic error message to the user for unexpected errors.
    } finally {
      setLoading(false); // Hide loading state
    }
  };

  const totalEarnings = summary?.totalEarnings ?? 0;
  const growthRate = summary?.growthRate ?? 0;
  const pendingPayouts = summary?.pendingPayouts ?? 0;
  const nextPayoutDateDisplay = summary?.nextPayoutDate ? format(summary.nextPayoutDate, 'MMM dd, yyyy') : null;
  const totalStudents = summary?.totalStudents ?? 0;
  const averageClassValue = summary?.averageClassValue ?? 0;
  const nextPayoutAmount = summary?.nextPayoutAmount ?? 0;

  return (
    <div className="space-y-6">
      {/* Header Section: Displays page title, description, and global filters/actions */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Payout Dashboard</h2>
          <p className="text-muted-foreground mt-1">
            Track your earnings, payouts, and financial performance
          </p>
        </div>
        <div className="flex gap-2">
          {/* Date Range Selector */}
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-[180px]">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">Last 7 days</SelectItem>
              <SelectItem value="30">Last 30 days</SelectItem>
              <SelectItem value="90">Last 90 days</SelectItem>
              <SelectItem value="365">Last year</SelectItem>
            </SelectContent>
          </Select>
          {/* Export Report Button */}
          <Button variant="outline">
            <Download className="mr-2 h-4 w-4" />
            Export Report
          </Button>
        </div>
      </div>

      {/* Summary Cards: Displays key financial metrics */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {/* Total Earnings Card */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Earnings</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${totalEarnings.toLocaleString()}</div>
            <div className="flex items-center text-xs text-muted-foreground mt-1">
              {growthRate > 0 ? (
                <>
                  <ArrowUpRight className="h-3 w-3 text-green-500 mr-1" />
                  <span className="text-green-500">{growthRate}%</span>
                </>
              ) : (
                <>
                  <ArrowDownRight className="h-3 w-3 text-red-500 mr-1" />
                  <span className="text-red-500">{Math.abs(growthRate)}%</span>
                </>
              )}
              <span className="ml-1">from last month</span>
            </div>
          </CardContent>
        </Card>

        {/* Pending Payouts Card */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Payouts</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${pendingPayouts.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Next payout: {nextPayoutDateDisplay ?? 'TBD'}
            </p>
          </CardContent>
        </Card>

        {/* Total Students Card */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Students</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalStudents.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Across all venues
            </p>
          </CardContent>
        </Card>

        {/* Average Class Value Card */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Class Value</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${averageClassValue.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Per class session
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts Section: Visual representation of earnings, classes, and students data */}
      <Card>
        <CardHeader>
          <CardTitle>Earnings Overview</CardTitle>
          <CardDescription>
            Your earnings trend over the selected period
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="earnings" className="space-y-4">
            <TabsList>
              <TabsTrigger value="earnings">Earnings</TabsTrigger>
              <TabsTrigger value="classes">Classes</TabsTrigger>
              <TabsTrigger value="students">Students</TabsTrigger>
            </TabsList>
            
            <TabsContent value="earnings" className="space-y-4">
              <ResponsiveContainer width="100%" height={350}>
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorEarnings" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <CartesianGrid strokeDasharray="3 3" />
                  <Tooltip />
                  <Area
                    type="monotone"
                    dataKey="earnings"
                    stroke="#8884d8"
                    fillOpacity={1}
                    fill="url(#colorEarnings)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </TabsContent>

            <TabsContent value="classes" className="space-y-4">
              <ResponsiveContainer width="100%" height={350}>
                <BarChart data={chartData}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <CartesianGrid strokeDasharray="3 3" />
                  <Tooltip />
                  <Bar dataKey="classes" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </TabsContent>

            <TabsContent value="students" className="space-y-4">
              <ResponsiveContainer width="100%" height={350}>
                <LineChart data={chartData}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <CartesianGrid strokeDasharray="3 3" />
                  <Tooltip />
                  <Line type="monotone" dataKey="students" stroke="#82ca9d" />
                </LineChart>
              </ResponsiveContainer>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Earnings by Venue: Provides a detailed breakdown of earnings per venue */}
      <Card>
        <CardHeader>
          <CardTitle>Earnings by Venue</CardTitle>
          <CardDescription>
            Breakdown of your earnings across different venues
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {earningsBreakdown.map((venue) => (
              <div key={venue.venueId} className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-semibold">{venue.venue}</h4>
                    <Badge variant="outline">{venue.classCount} classes</Badge>
                  </div>
                  <div className="grid grid-cols-3 gap-4 text-sm">
                    <div>
                      <span className="text-muted-foreground">Revenue:</span>
                      <span className="ml-2 font-medium">${venue.totalRevenue.toLocaleString()}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Commission:</span>
                      <span className="ml-2 font-medium text-red-600">-${venue.commission.toLocaleString()}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Net:</span>
                      <span className="ml-2 font-medium text-green-600">${venue.netEarnings.toLocaleString()}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <span>{venue.studentCount} students</span>
                    <span>${(venue.totalRevenue / venue.classCount).toFixed(2)} avg/class</span>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 text-gray-400" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Payout History: Lists recent and upcoming payout transactions */}
      <Card>
        <CardHeader>
          <CardTitle>Payout History</CardTitle>
          <CardDescription>
            Your recent and upcoming payouts
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {payoutHistory.map((payout) => (
              <div key={payout.id} className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center gap-4">
                  {getStatusIcon(payout.status)}
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-semibold">${payout.amount.toLocaleString()}</span>
                      <Badge className={getStatusColor(payout.status)}>
                        {payout.status}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                      <span>{format(payout.date, 'MMM dd, yyyy')}</span>
                      <span>{payout.classCount} classes</span>
                      <span>{payout.commissionRate}% commission</span>
                      {payout.transactionId && (
                        <span className="font-mono text-xs">{payout.transactionId}</span>
                      )}
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-semibold text-green-600">
                    ${payout.netAmount.toLocaleString()}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    Net amount
                  </div>
                </div>
              </div>
            ))}
          </div>
          
          <div className="mt-4 pt-4 border-t">
            <Button variant="outline" className="w-full">
              View All Payouts
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Next Payout Card: Highlights the next scheduled payout */}
      {nextPayoutAmount > 0 && (
        <Card className="border-primary">
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>Next Payout</span>
              <Badge variant="default">
                {nextPayoutDateDisplay ?? 'TBD'}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <div className="text-3xl font-bold text-primary">
                  ${nextPayoutAmount.toLocaleString()}
                </div>
                <p className="text-sm text-muted-foreground mt-1">
                  Will be processed automatically via Stripe
                </p>
              </div>
              {/* Button to update payment method, initiating Stripe Connect onboarding */}
              <Button onClick={handleUpdatePaymentMethod}>
                <CreditCard className="mr-2 h-4 w-4" />
                Update Payment Method
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default PayoutDashboard;
