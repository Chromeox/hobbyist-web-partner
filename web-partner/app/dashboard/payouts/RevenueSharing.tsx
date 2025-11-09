'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { Switch } from '@/components/ui/switch';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { useToast } from '@/components/ui/use-toast';
import { supabase } from '@/lib/supabase';
import {
  Calculator,
  Percent,
  TrendingUp,
  Building,
  Users,
  DollarSign,
  Settings,
  Info,
  AlertTriangle,
  Check,
  X,
  Edit,
  Save,
  Clock,
  Calendar,
  CreditCard,
  ChevronRight,
  HelpCircle
} from 'lucide-react';

interface CommissionStructure {
  id: string;
  name: string;
  type: 'fixed' | 'tiered' | 'dynamic' | 'custom';
  baseRate: number;
  tiers?: CommissionTier[];
  conditions?: CommissionCondition[];
  isActive: boolean;
  venues: string[];
  effectiveDate: Date;
  expiryDate?: Date;
}

interface CommissionTier {
  minAmount: number;
  maxAmount?: number;
  rate: number;
  description: string;
}

interface CommissionCondition {
  type: 'student_count' | 'class_count' | 'revenue' | 'retention';
  threshold: number;
  adjustment: number;
  operator: 'add' | 'multiply';
}

interface VenueCommission {
  venueId: string;
  venueName: string;
  commissionStructureId: string;
  currentRate: number;
  projectedEarnings: number;
  activeStudents: number;
  monthlyClasses: number;
}

const RevenueSharing: React.FC = () => {
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [selectedStructure, setSelectedStructure] = useState<string>('');
  const [structures, setStructures] = useState<CommissionStructure[]>([]);
  const [venueCommissions, setVenueCommissions] = useState<VenueCommission[]>([]);
  const [customRate, setCustomRate] = useState<number>(20);
  const [tierCount, setTierCount] = useState<number>(3);
  const [showAdvanced, setShowAdvanced] = useState(false);

  useEffect(() => {
    fetchCommissionData();
  }, []);

  const fetchCommissionData = async () => {
    try {
      setLoading(true);
      
      // Mock data for commission structures
      const mockStructures: CommissionStructure[] = [
        {
          id: 'structure_1',
          name: 'Standard 80/20',
          type: 'fixed',
          baseRate: 20,
          isActive: true,
          venues: ['venue_1', 'venue_2'],
          effectiveDate: new Date('2024-01-01'),
        },
        {
          id: 'structure_2',
          name: 'Performance-Based',
          type: 'tiered',
          baseRate: 15,
          tiers: [
            { minAmount: 0, maxAmount: 5000, rate: 15, description: 'Base tier' },
            { minAmount: 5000, maxAmount: 10000, rate: 18, description: 'Silver tier' },
            { minAmount: 10000, rate: 20, description: 'Gold tier' }
          ],
          isActive: true,
          venues: ['venue_3'],
          effectiveDate: new Date('2024-01-01'),
        },
        {
          id: 'structure_3',
          name: 'Premium Partner 70/30',
          type: 'fixed',
          baseRate: 30,
          isActive: false,
          venues: [],
          effectiveDate: new Date('2024-06-01'),
        }
      ];
      setStructures(mockStructures);
      
      // Mock venue commission data
      const mockVenueCommissions: VenueCommission[] = [
        {
          venueId: 'venue_1',
          venueName: 'Downtown Yoga Studio',
          commissionStructureId: 'structure_1',
          currentRate: 20,
          projectedEarnings: 14800,
          activeStudents: 520,
          monthlyClasses: 124
        },
        {
          venueId: 'venue_2',
          venueName: 'Westside Fitness Center',
          commissionStructureId: 'structure_1',
          currentRate: 20,
          projectedEarnings: 12200,
          activeStudents: 412,
          monthlyClasses: 98
        },
        {
          venueId: 'venue_3',
          venueName: 'Beach Wellness Hub',
          commissionStructureId: 'structure_2',
          currentRate: 18,
          projectedEarnings: 13000,
          activeStudents: 315,
          monthlyClasses: 88
        }
      ];
      setVenueCommissions(mockVenueCommissions);
      
    } catch (error) {
      console.error('Error fetching commission data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleStructureUpdate = async (structureId: string, updates: Partial<CommissionStructure>) => {
    try {
      setLoading(true);
      
      // Update structure in database
      const { error } = await supabase
        .from('commission_structures')
        .update(updates)
        .eq('id', structureId);

      if (error) throw error;

      toast({
        title: 'Commission structure updated',
        description: 'Changes will take effect immediately',
      });

      fetchCommissionData();
    } catch (error) {
      console.error('Error updating structure:', error);
      toast({
        title: 'Update failed',
        description: 'Could not update commission structure',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const calculateProjectedEarnings = (baseAmount: number, rate: number) => {
    const commission = baseAmount * (rate / 100);
    return baseAmount - commission;
  };

  const getStructureTypeIcon = (type: string) => {
    switch (type) {
      case 'fixed': return <Percent className="h-4 w-4" />;
      case 'tiered': return <TrendingUp className="h-4 w-4" />;
      case 'dynamic': return <Settings className="h-4 w-4" />;
      case 'custom': return <Calculator className="h-4 w-4" />;
      default: return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Revenue Sharing</h2>
          <p className="text-muted-foreground mt-1">
            Configure commission structures and revenue splits across venues
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setShowAdvanced(!showAdvanced)}>
            <Settings className="mr-2 h-4 w-4" />
            Advanced Settings
          </Button>
          <Button onClick={() => setEditMode(!editMode)}>
            {editMode ? (
              <>
                <Save className="mr-2 h-4 w-4" />
                Save Changes
              </>
            ) : (
              <>
                <Edit className="mr-2 h-4 w-4" />
                Edit Mode
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Commission Overview */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Average Commission</CardTitle>
            <Percent className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">19.3%</div>
            <p className="text-xs text-muted-foreground">Across all venues</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Monthly Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">$48,750</div>
            <p className="text-xs text-muted-foreground">Before commissions</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Net Earnings</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">$39,000</div>
            <p className="text-xs text-muted-foreground">After commissions</p>
          </CardContent>
        </Card>
      </div>

      {/* Commission Structures */}
      <Card>
        <CardHeader>
          <CardTitle>Commission Structures</CardTitle>
          <CardDescription>
            Manage different commission models for your venues
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="active" className="space-y-4">
            <TabsList>
              <TabsTrigger value="active">Active Structures</TabsTrigger>
              <TabsTrigger value="templates">Templates</TabsTrigger>
              <TabsTrigger value="custom">Create Custom</TabsTrigger>
            </TabsList>

            <TabsContent value="active" className="space-y-4">
              {structures.filter(s => s.isActive).map((structure) => (
                <div key={structure.id} className="border rounded-lg p-4 space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      {getStructureTypeIcon(structure.type)}
                      <div>
                        <h4 className="font-semibold">{structure.name}</h4>
                        <p className="text-sm text-muted-foreground">
                          {structure.venues.length} venues using this structure
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="outline">{structure.type}</Badge>
                      <Badge className="bg-green-100 text-green-800">Active</Badge>
                    </div>
                  </div>

                  {structure.type === 'fixed' && (
                    <div className="flex items-center justify-between bg-gray-50 rounded-lg p-3">
                      <span className="text-sm font-medium">Commission Rate</span>
                      <div className="flex items-center gap-2">
                        {editMode ? (
                          <Input
                            type="number"
                            value={structure.baseRate}
                            className="w-20"
                            onChange={(e) => {
                              const newRate = parseFloat(e.target.value);
                              handleStructureUpdate(structure.id, { baseRate: newRate });
                            }}
                          />
                        ) : (
                          <span className="text-lg font-bold">{structure.baseRate}%</span>
                        )}
                      </div>
                    </div>
                  )}

                  {structure.type === 'tiered' && structure.tiers && (
                    <div className="space-y-2">
                      {structure.tiers.map((tier, index) => (
                        <div key={index} className="flex items-center justify-between bg-gray-50 rounded-lg p-3">
                          <div className="text-sm">
                            <span className="font-medium">{tier.description}</span>
                            <span className="text-muted-foreground ml-2">
                              ${tier.minAmount.toLocaleString()} 
                              {tier.maxAmount ? ` - $${tier.maxAmount.toLocaleString()}` : '+'}
                            </span>
                          </div>
                          <Badge variant="secondary">{tier.rate}%</Badge>
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="flex items-center justify-between text-sm text-muted-foreground">
                    <span>Effective: {structure.effectiveDate.toLocaleDateString()}</span>
                    {structure.expiryDate && (
                      <span>Expires: {structure.expiryDate.toLocaleDateString()}</span>
                    )}
                  </div>
                </div>
              ))}
            </TabsContent>

            <TabsContent value="templates" className="space-y-4">
              <div className="grid gap-4 md:grid-cols-2">
                <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
                  <CardHeader>
                    <CardTitle className="text-lg">Standard 80/20</CardTitle>
                    <CardDescription>Most common revenue split</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <span className="text-2xl font-bold">20%</span>
                      <Button size="sm">Apply</Button>
                    </div>
                  </CardContent>
                </Card>

                <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
                  <CardHeader>
                    <CardTitle className="text-lg">Premium 70/30</CardTitle>
                    <CardDescription>For exclusive partnerships</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <span className="text-2xl font-bold">30%</span>
                      <Button size="sm">Apply</Button>
                    </div>
                  </CardContent>
                </Card>

                <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
                  <CardHeader>
                    <CardTitle className="text-lg">Performance Tiered</CardTitle>
                    <CardDescription>Rate increases with revenue</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <span className="text-2xl font-bold">15-25%</span>
                      <Button size="sm">Apply</Button>
                    </div>
                  </CardContent>
                </Card>

                <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
                  <CardHeader>
                    <CardTitle className="text-lg">New Partner Special</CardTitle>
                    <CardDescription>Introductory rate for 6 months</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <span className="text-2xl font-bold">10%</span>
                      <Button size="sm">Apply</Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>

            <TabsContent value="custom" className="space-y-4">
              <div className="space-y-6">
                <div>
                  <Label htmlFor="structure-name">Structure Name</Label>
                  <Input
                    id="structure-name"
                    placeholder="e.g., Custom Performance Plan"
                    className="mt-1"
                  />
                </div>

                <div>
                  <Label>Structure Type</Label>
                  <RadioGroup defaultValue="fixed" className="mt-2">
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="fixed" id="fixed" />
                      <Label htmlFor="fixed">Fixed Rate</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="tiered" id="tiered" />
                      <Label htmlFor="tiered">Tiered Based on Revenue</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="dynamic" id="dynamic" />
                      <Label htmlFor="dynamic">Dynamic with Conditions</Label>
                    </div>
                  </RadioGroup>
                </div>

                <div>
                  <Label>Base Commission Rate: {customRate}%</Label>
                  <Slider
                    value={[customRate]}
                    onValueChange={(value) => setCustomRate(value[0])}
                    max={50}
                    min={5}
                    step={1}
                    className="mt-2"
                  />
                  <div className="flex justify-between text-xs text-muted-foreground mt-1">
                    <span>5%</span>
                    <span>50%</span>
                  </div>
                </div>

                <div className="flex justify-end gap-2">
                  <Button variant="outline">Preview</Button>
                  <Button>Create Structure</Button>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Venue Commission Details */}
      <Card>
        <CardHeader>
          <CardTitle>Venue Commission Details</CardTitle>
          <CardDescription>
            Individual venue commission settings and projections
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {venueCommissions.map((venue) => (
              <div key={venue.venueId} className="border rounded-lg p-4">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <Building className="h-5 w-5 text-muted-foreground" />
                    <div>
                      <h4 className="font-semibold">{venue.venueName}</h4>
                      <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                        <span className="flex items-center gap-1">
                          <Users className="h-3 w-3" />
                          {venue.activeStudents} students
                        </span>
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {venue.monthlyClasses} classes/month
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold">{venue.currentRate}%</div>
                    <p className="text-xs text-muted-foreground">commission</p>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4 p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="text-xs text-muted-foreground">Gross Revenue</p>
                    <p className="font-semibold">
                      ${(venue.projectedEarnings / (1 - venue.currentRate / 100)).toFixed(0)}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Commission</p>
                    <p className="font-semibold text-red-600">
                      -${((venue.projectedEarnings / (1 - venue.currentRate / 100)) * (venue.currentRate / 100)).toFixed(0)}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Net Earnings</p>
                    <p className="font-semibold text-green-600">
                      ${venue.projectedEarnings.toLocaleString()}
                    </p>
                  </div>
                </div>

                {editMode && (
                  <div className="mt-4 flex items-center gap-2">
                    <Select defaultValue={venue.commissionStructureId}>
                      <SelectTrigger className="w-full">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {structures.map((structure) => (
                          <SelectItem key={structure.id} value={structure.id}>
                            {structure.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <Button size="sm">Update</Button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Advanced Settings */}
      {showAdvanced && (
        <Card>
          <CardHeader>
            <CardTitle>Advanced Commission Settings</CardTitle>
            <CardDescription>
              Configure automatic adjustments and special conditions
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Auto-adjust for high performers</Label>
                <p className="text-sm text-muted-foreground">
                  Reduce commission by 2% for instructors with 50+ monthly classes
                </p>
              </div>
              <Switch />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Volume discounts</Label>
                <p className="text-sm text-muted-foreground">
                  Apply tiered rates based on monthly revenue
                </p>
              </div>
              <Switch />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Loyalty bonus</Label>
                <p className="text-sm text-muted-foreground">
                  1% commission reduction per year of partnership (max 5%)
                </p>
              </div>
              <Switch />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Holiday rates</Label>
                <p className="text-sm text-muted-foreground">
                  Special commission rates during peak seasons
                </p>
              </div>
              <Switch />
            </div>
          </CardContent>
        </Card>
      )}

      {/* Info Alert */}
      <Alert>
        <Info className="h-4 w-4" />
        <AlertTitle>Commission Changes</AlertTitle>
        <AlertDescription>
          Any changes to commission structures will take effect at the beginning of the next billing cycle.
          Instructors will be notified automatically of any rate changes.
        </AlertDescription>
      </Alert>
    </div>
  );
};

export default RevenueSharing;