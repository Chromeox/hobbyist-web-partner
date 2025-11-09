'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/components/ui/use-toast';
import { usePaymentModel } from '@/contexts/PaymentModelContext';
import { supabase } from '@/lib/supabase';
import { format, addDays, addWeeks, addMonths, isWeekend, nextMonday } from 'date-fns';
import { cn } from '@/lib/utils';
import {
  Calendar as CalendarIcon,
  Clock,
  CreditCard,
  AlertCircle,
  CheckCircle,
  Settings,
  Play,
  Pause,
  RefreshCw,
  DollarSign,
  Info,
  Download,
  Send,
  Building,
  User,
  FileText,
  AlertTriangle,
  ChevronRight,
  Mail,
  Phone,
  Globe
} from 'lucide-react';

interface PayoutScheduleConfig {
  id: string;
  name: string;
  frequency: 'weekly' | 'bi-weekly' | 'monthly' | 'custom';
  dayOfWeek?: number; // 0-6 for weekly
  dayOfMonth?: number; // 1-31 for monthly
  customDays?: number[]; // For custom schedules
  minimumPayout: number;
  maximumPayout?: number;
  processingTime: number; // in days
  autoApprove: boolean;
  notifyBeforePayout: boolean;
  notificationDays: number;
  paymentMethod: 'stripe' | 'bank_transfer' | 'paypal' | 'check';
  isActive: boolean;
  nextPayoutDate: Date;
  venues: string[];
}

interface ScheduledPayout {
  id: string;
  scheduleId: string;
  scheduledDate: Date;
  amount: number;
  status: 'scheduled' | 'pending_approval' | 'processing' | 'completed' | 'failed';
  instructorCount: number;
  venues: string[];
  approvedBy?: string;
  approvedAt?: Date;
  processedAt?: Date;
  notes?: string;
}

interface PaymentMethod {
  id: string;
  type: 'stripe' | 'bank_transfer' | 'paypal' | 'check';
  name: string;
  details: any;
  isDefault: boolean;
  isVerified: boolean;
  lastUsed?: Date;
}

const PayoutSchedule: React.FC = () => {
  const { paymentModel } = usePaymentModel();
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [schedules, setSchedules] = useState<PayoutScheduleConfig[]>([]);
  const [upcomingPayouts, setUpcomingPayouts] = useState<ScheduledPayout[]>([]);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [selectedSchedule, setSelectedSchedule] = useState<string>('');
  const [editMode, setEditMode] = useState(false);
  const [showCreateForm, setShowCreateForm] = useState(false);
  
  // Form state for new schedule
  const [newSchedule, setNewSchedule] = useState<Partial<PayoutScheduleConfig>>({
    name: '',
    frequency: 'monthly',
    dayOfMonth: 1,
    minimumPayout: 100,
    processingTime: 2,
    autoApprove: true,
    notifyBeforePayout: true,
    notificationDays: 3,
    paymentMethod: 'stripe',
    isActive: true
  });

  useEffect(() => {
    fetchScheduleData();
  }, []);

  const fetchScheduleData = async () => {
    try {
      setLoading(true);

      // Mock schedule data
      const mockSchedules: PayoutScheduleConfig[] = [
        {
          id: 'schedule_1',
          name: 'Monthly Standard Payout',
          frequency: 'monthly',
          dayOfMonth: 1,
          minimumPayout: 100,
          processingTime: 2,
          autoApprove: true,
          notifyBeforePayout: true,
          notificationDays: 3,
          paymentMethod: 'stripe',
          isActive: true,
          nextPayoutDate: new Date('2024-02-01'),
          venues: ['venue_1', 'venue_2']
        },
        {
          id: 'schedule_2',
          name: 'Weekly Fast Payout',
          frequency: 'weekly',
          dayOfWeek: 5, // Friday
          minimumPayout: 50,
          processingTime: 1,
          autoApprove: true,
          notifyBeforePayout: false,
          notificationDays: 1,
          paymentMethod: 'stripe',
          isActive: true,
          nextPayoutDate: addDays(new Date(), 3),
          venues: ['venue_3']
        }
      ];
      setSchedules(mockSchedules);

      // Mock upcoming payouts
      const mockPayouts: ScheduledPayout[] = [
        {
          id: 'payout_1',
          scheduleId: 'schedule_1',
          scheduledDate: new Date('2024-02-01'),
          amount: 3250.00,
          status: 'scheduled',
          instructorCount: 12,
          venues: ['venue_1', 'venue_2']
        },
        {
          id: 'payout_2',
          scheduleId: 'schedule_2',
          scheduledDate: addDays(new Date(), 3),
          amount: 850.00,
          status: 'pending_approval',
          instructorCount: 5,
          venues: ['venue_3']
        },
        {
          id: 'payout_3',
          scheduleId: 'schedule_1',
          scheduledDate: new Date('2024-01-01'),
          amount: 2950.00,
          status: 'completed',
          instructorCount: 11,
          venues: ['venue_1', 'venue_2'],
          processedAt: new Date('2024-01-03')
        }
      ];
      setUpcomingPayouts(mockPayouts);

      // Mock payment methods
      const mockPaymentMethods: PaymentMethod[] = [
        {
          id: 'method_1',
          type: 'stripe',
          name: 'Stripe Connect',
          details: { accountId: 'acct_1234567890' },
          isDefault: true,
          isVerified: true,
          lastUsed: new Date('2024-01-01')
        },
        {
          id: 'method_2',
          type: 'bank_transfer',
          name: 'Chase Business ****4567',
          details: { last4: '4567', bankName: 'Chase' },
          isDefault: false,
          isVerified: true
        }
      ];
      setPaymentMethods(mockPaymentMethods);

    } catch (error) {
      console.error('Error fetching schedule data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSchedule = async () => {
    try {
      setLoading(true);
      
      // Save to database
      const { error } = await supabase
        .from('payout_schedules')
        .insert([newSchedule]);

      if (error) throw error;

      toast({
        title: 'Schedule created',
        description: 'New payout schedule has been created successfully',
      });

      setShowCreateForm(false);
      fetchScheduleData();
    } catch (error) {
      console.error('Error creating schedule:', error);
      toast({
        title: 'Creation failed',
        description: 'Could not create payout schedule',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleToggleSchedule = async (scheduleId: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from('payout_schedules')
        .update({ isActive })
        .eq('id', scheduleId);

      if (error) throw error;

      toast({
        title: isActive ? 'Schedule activated' : 'Schedule paused',
        description: `Payout schedule has been ${isActive ? 'activated' : 'paused'}`,
      });

      fetchScheduleData();
    } catch (error) {
      console.error('Error toggling schedule:', error);
    }
  };

  const calculateNextPayoutDate = (schedule: PayoutScheduleConfig): Date => {
    const today = new Date();
    
    switch (schedule.frequency) {
      case 'weekly':
        return addWeeks(today, 1);
      case 'bi-weekly':
        return addWeeks(today, 2);
      case 'monthly':
        return addMonths(today, 1);
      default:
        return addDays(today, 30);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'scheduled':
        return <Clock className="h-4 w-4 text-blue-500" />;
      case 'pending_approval':
        return <AlertCircle className="h-4 w-4 text-yellow-500" />;
      case 'processing':
        return <RefreshCw className="h-4 w-4 text-blue-500 animate-spin" />;
      case 'completed':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'failed':
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800';
      case 'pending_approval': return 'bg-yellow-100 text-yellow-800';
      case 'processing': return 'bg-blue-100 text-blue-800';
      case 'completed': return 'bg-green-100 text-green-800';
      case 'failed': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getFrequencyLabel = (frequency: string) => {
    switch (frequency) {
      case 'weekly': return 'Every Week';
      case 'bi-weekly': return 'Every 2 Weeks';
      case 'monthly': return 'Monthly';
      case 'custom': return 'Custom Schedule';
      default: return frequency;
    }
  };

  const getDayName = (day: number) => {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[day];
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Payout Schedule</h2>
          <p className="text-muted-foreground mt-1">
            Configure automated payment schedules for instructors
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">
            <Download className="mr-2 h-4 w-4" />
            Export Schedule
          </Button>
          <Button onClick={() => setShowCreateForm(true)}>
            <CalendarIcon className="mr-2 h-4 w-4" />
            Create Schedule
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Schedules</CardTitle>
            <CalendarIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{schedules.filter(s => s.isActive).length}</div>
            <p className="text-xs text-muted-foreground">Running automatically</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Next Payout</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {upcomingPayouts.find(p => p.status === 'scheduled')?.scheduledDate
                ? format(upcomingPayouts.find(p => p.status === 'scheduled')!.scheduledDate, 'MMM dd')
                : 'None'}
            </div>
            <p className="text-xs text-muted-foreground">
              ${upcomingPayouts.find(p => p.status === 'scheduled')?.amount.toLocaleString() || '0'}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Approval</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {upcomingPayouts.filter(p => p.status === 'pending_approval').length}
            </div>
            <p className="text-xs text-muted-foreground">Require review</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Month</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">$12,850</div>
            <p className="text-xs text-muted-foreground">Total scheduled</p>
          </CardContent>
        </Card>
      </div>

      {/* Schedule Management */}
      <Tabs defaultValue="schedules" className="space-y-4">
        <TabsList>
          <TabsTrigger value="schedules">Active Schedules</TabsTrigger>
          <TabsTrigger value="upcoming">Upcoming Payouts</TabsTrigger>
          <TabsTrigger value="methods">Payment Methods</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="schedules" className="space-y-4">
          {schedules.map((schedule) => (
            <Card key={schedule.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div>
                      <CardTitle className="text-lg">{schedule.name}</CardTitle>
                      <CardDescription className="mt-1">
                        {getFrequencyLabel(schedule.frequency)} • 
                        {schedule.frequency === 'weekly' && ` Every ${getDayName(schedule.dayOfWeek || 0)}`}
                        {schedule.frequency === 'monthly' && ` Day ${schedule.dayOfMonth}`}
                      </CardDescription>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={schedule.isActive ? 'default' : 'secondary'}>
                      {schedule.isActive ? 'Active' : 'Paused'}
                    </Badge>
                    <Switch
                      checked={schedule.isActive}
                      onCheckedChange={(checked) => handleToggleSchedule(schedule.id, checked)}
                    />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Next Payout</p>
                      <p className="font-semibold">
                        {format(schedule.nextPayoutDate, 'MMM dd, yyyy')}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Minimum Amount</p>
                      <p className="font-semibold">${schedule.minimumPayout}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Processing Time</p>
                      <p className="font-semibold">{schedule.processingTime} days</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Payment Method</p>
                      <p className="font-semibold capitalize">{schedule.paymentMethod.replace('_', ' ')}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 text-sm">
                    <div className="flex items-center gap-2">
                      {schedule.autoApprove ? (
                        <CheckCircle className="h-4 w-4 text-green-500" />
                      ) : (
                        <AlertCircle className="h-4 w-4 text-yellow-500" />
                      )}
                      <span>{schedule.autoApprove ? 'Auto-approved' : 'Manual approval'}</span>
                    </div>
                    {schedule.notifyBeforePayout && (
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-blue-500" />
                        <span>Notify {schedule.notificationDays} days before</span>
                      </div>
                    )}
                    <div className="flex items-center gap-2">
                      <Building className="h-4 w-4 text-gray-500" />
                      <span>{schedule.venues.length} venues</span>
                    </div>
                  </div>

                  <div className="flex justify-end gap-2">
                    <Button variant="outline" size="sm">
                      <Settings className="mr-2 h-4 w-4" />
                      Configure
                    </Button>
                    <Button variant="outline" size="sm">
                      <Send className="mr-2 h-4 w-4" />
                      Run Now
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </TabsContent>

        <TabsContent value="upcoming" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Upcoming Payouts</CardTitle>
              <CardDescription>
                Scheduled and pending payouts for the next 30 days
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {upcomingPayouts.map((payout) => (
                  <div key={payout.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      {getStatusIcon(payout.status)}
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">
                            ${payout.amount.toLocaleString()}
                          </span>
                          <Badge className={getStatusColor(payout.status)}>
                            {payout.status.replace('_', ' ')}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                          <span>{format(payout.scheduledDate, 'MMM dd, yyyy')}</span>
                          <span>{payout.instructorCount} instructors</span>
                          <span>{payout.venues.length} venues</span>
                        </div>
                      </div>
                    </div>
                    
                    {payout.status === 'pending_approval' && (
                      <div className="flex gap-2">
                        <Button size="sm" variant="outline">Review</Button>
                        <Button size="sm">Approve</Button>
                      </div>
                    )}
                    
                    {payout.status === 'scheduled' && (
                      <Button size="sm" variant="outline">
                        View Details
                      </Button>
                    )}
                    
                    {payout.status === 'completed' && payout.processedAt && (
                      <div className="text-right">
                        <p className="text-sm text-muted-foreground">Processed</p>
                        <p className="text-sm font-medium">
                          {format(payout.processedAt, 'MMM dd, yyyy')}
                        </p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="methods" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Payment Methods</CardTitle>
              <CardDescription>
                Manage payment methods for instructor payouts
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {paymentMethods.map((method) => (
                  <div key={method.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <CreditCard className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">{method.name}</span>
                          {method.isDefault && (
                            <Badge variant="secondary">Default</Badge>
                          )}
                          {method.isVerified ? (
                            <Badge className="bg-green-100 text-green-800">Verified</Badge>
                          ) : (
                            <Badge className="bg-yellow-100 text-yellow-800">Pending</Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground mt-1">
                          {method.type.replace('_', ' ')} • 
                          {method.lastUsed && ` Last used ${format(method.lastUsed, 'MMM dd, yyyy')}`}
                        </p>
                      </div>
                    </div>
                    <Button variant="outline" size="sm">
                      Configure
                    </Button>
                  </div>
                ))}
                
                <Button variant="outline" className="w-full">
                  <CreditCard className="mr-2 h-4 w-4" />
                  Add Payment Method
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Payout Settings</CardTitle>
              <CardDescription>
                Configure global payout preferences and policies
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Auto-approve payouts under $500</Label>
                    <p className="text-sm text-muted-foreground">
                      Automatically approve small payouts without manual review
                    </p>
                  </div>
                  <Switch defaultChecked />
                </div>

                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Send payout summaries</Label>
                    <p className="text-sm text-muted-foreground">
                      Email instructors with payout details and breakdowns
                    </p>
                  </div>
                  <Switch defaultChecked />
                </div>

                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Hold payouts for disputes</Label>
                    <p className="text-sm text-muted-foreground">
                      Automatically hold payouts if there are pending disputes
                    </p>
                  </div>
                  <Switch />
                </div>

                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Currency conversion</Label>
                    <p className="text-sm text-muted-foreground">
                      Enable multi-currency payouts for international instructors
                    </p>
                  </div>
                  <Switch />
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <Label>Default Processing Time</Label>
                  <Select defaultValue="2">
                    <SelectTrigger className="mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1">1 business day</SelectItem>
                      <SelectItem value="2">2 business days</SelectItem>
                      <SelectItem value="3">3 business days</SelectItem>
                      <SelectItem value="5">5 business days</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Minimum Payout Threshold</Label>
                  <Input
                    type="number"
                    placeholder="100"
                    className="mt-1"
                    defaultValue="100"
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    Payouts below this amount will be rolled to the next cycle
                  </p>
                </div>
              </div>

              <div className="flex justify-end">
                <Button>Save Settings</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Create Schedule Form */}
      {showCreateForm && (
        <Card>
          <CardHeader>
            <CardTitle>Create New Payout Schedule</CardTitle>
            <CardDescription>
              Set up a new automated payout schedule
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Schedule Name</Label>
              <Input
                placeholder="e.g., Monthly Instructor Payouts"
                value={newSchedule.name}
                onChange={(e) => setNewSchedule({ ...newSchedule, name: e.target.value })}
                className="mt-1"
              />
            </div>

            <div>
              <Label>Frequency</Label>
              <RadioGroup
                value={newSchedule.frequency}
                onValueChange={(value) => setNewSchedule({ ...newSchedule, frequency: value as any })}
                className="mt-2"
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="weekly" id="weekly" />
                  <Label htmlFor="weekly">Weekly</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="bi-weekly" id="bi-weekly" />
                  <Label htmlFor="bi-weekly">Bi-weekly</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="monthly" id="monthly" />
                  <Label htmlFor="monthly">Monthly</Label>
                </div>
              </RadioGroup>
            </div>

            {newSchedule.frequency === 'monthly' && (
              <div>
                <Label>Day of Month</Label>
                <Select
                  value={newSchedule.dayOfMonth?.toString()}
                  onValueChange={(value) => setNewSchedule({ ...newSchedule, dayOfMonth: parseInt(value) })}
                >
                  <SelectTrigger className="mt-1">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Array.from({ length: 28 }, (_, i) => i + 1).map((day) => (
                      <SelectItem key={day} value={day.toString()}>
                        Day {day}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setShowCreateForm(false)}>
                Cancel
              </Button>
              <Button onClick={handleCreateSchedule}>
                Create Schedule
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Info Alert */}
      <Alert>
        <Info className="h-4 w-4" />
        <AlertTitle>Automated Processing</AlertTitle>
        <AlertDescription>
          Payouts are processed automatically according to your schedules. Funds are typically available 
          in instructor accounts within 1-3 business days after processing, depending on the payment method.
        </AlertDescription>
      </Alert>
    </div>
  );
};

export default PayoutSchedule;