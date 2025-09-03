'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Slider } from '@/components/ui/slider';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import {
  Calculator,
  DollarSign,
  Percent,
  TrendingUp,
  TrendingDown,
  Info,
  ChevronRight,
  RefreshCw,
  Download,
  Copy,
  Check,
  AlertCircle,
  Users,
  Calendar,
  Clock,
  CreditCard,
  Receipt,
  FileText,
  PieChart
} from 'lucide-react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart as RePieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';

interface CalculationInput {
  classPrice: number;
  studentCount: number;
  classesPerMonth: number;
  commissionRate: number;
  platformFee: number;
  processingFee: number;
  taxRate: number;
}

interface CalculationResult {
  grossRevenue: number;
  commission: number;
  platformFees: number;
  processingFees: number;
  taxes: number;
  netEarnings: number;
  perClassEarnings: number;
  perStudentValue: number;
  breakEvenStudents: number;
  profitMargin: number;
}

interface ScenarioComparison {
  name: string;
  inputs: CalculationInput;
  result: CalculationResult;
  color: string;
}

const CommissionCalculator: React.FC = () => {
  const [inputs, setInputs] = useState<CalculationInput>({
    classPrice: 35,
    studentCount: 15,
    classesPerMonth: 20,
    commissionRate: 20,
    platformFee: 2.9,
    processingFee: 0.30,
    taxRate: 0
  });

  const [scenarios, setScenarios] = useState<ScenarioComparison[]>([]);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [calculationMode, setCalculationMode] = useState<'simple' | 'advanced'>('simple');
  const [copied, setCopied] = useState(false);

  const calculateResults = (input: CalculationInput): CalculationResult => {
    const classRevenue = input.classPrice * input.studentCount;
    const monthlyRevenue = classRevenue * input.classesPerMonth;
    
    const commission = monthlyRevenue * (input.commissionRate / 100);
    const platformFees = monthlyRevenue * (input.platformFee / 100) + (input.processingFee * input.classesPerMonth * input.studentCount);
    const processingFees = 0; // Already included in platform fees
    const beforeTax = monthlyRevenue - commission - platformFees;
    const taxes = beforeTax * (input.taxRate / 100);
    const netEarnings = beforeTax - taxes;
    
    const perClassEarnings = netEarnings / input.classesPerMonth;
    const perStudentValue = netEarnings / (input.studentCount * input.classesPerMonth);
    
    // Calculate break-even (where net earnings would be 0)
    const fixedCosts = commission + platformFees + taxes;
    const variableProfit = input.classPrice * (1 - input.commissionRate / 100 - input.platformFee / 100 - input.taxRate / 100);
    const breakEvenStudents = Math.ceil(fixedCosts / (variableProfit * input.classesPerMonth));
    
    const profitMargin = (netEarnings / monthlyRevenue) * 100;

    return {
      grossRevenue: monthlyRevenue,
      commission,
      platformFees,
      processingFees,
      taxes,
      netEarnings,
      perClassEarnings,
      perStudentValue,
      breakEvenStudents,
      profitMargin
    };
  };

  const result = useMemo(() => calculateResults(inputs), [inputs]);

  const handleInputChange = (field: keyof CalculationInput, value: number) => {
    setInputs(prev => ({ ...prev, [field]: value }));
  };

  const addScenario = () => {
    const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7c7c', '#8dd1e1'];
    const newScenario: ScenarioComparison = {
      name: `Scenario ${scenarios.length + 1}`,
      inputs: { ...inputs },
      result: calculateResults(inputs),
      color: colors[scenarios.length % colors.length]
    };
    setScenarios([...scenarios, newScenario]);
  };

  const copyResults = () => {
    const text = `
Commission Calculation Results:
Gross Revenue: $${result.grossRevenue.toFixed(2)}
Commission (${inputs.commissionRate}%): -$${result.commission.toFixed(2)}
Platform Fees: -$${result.platformFees.toFixed(2)}
Taxes: -$${result.taxes.toFixed(2)}
Net Earnings: $${result.netEarnings.toFixed(2)}
Per Class: $${result.perClassEarnings.toFixed(2)}
Profit Margin: ${result.profitMargin.toFixed(1)}%
    `.trim();
    
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const pieChartData = [
    { name: 'Net Earnings', value: result.netEarnings, fill: '#10b981' },
    { name: 'Commission', value: result.commission, fill: '#ef4444' },
    { name: 'Platform Fees', value: result.platformFees, fill: '#f59e0b' },
    { name: 'Taxes', value: result.taxes, fill: '#6b7280' }
  ];

  const projectionData = Array.from({ length: 12 }, (_, i) => ({
    month: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
    revenue: result.grossRevenue * (1 + (Math.random() - 0.5) * 0.2),
    earnings: result.netEarnings * (1 + (Math.random() - 0.5) * 0.2)
  }));

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Commission Calculator</h2>
          <p className="text-muted-foreground mt-1">
            Calculate your earnings after commissions and fees
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setShowAdvanced(!showAdvanced)}>
            {showAdvanced ? 'Hide' : 'Show'} Advanced
          </Button>
          <Button variant="outline" onClick={copyResults}>
            {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
            {copied ? 'Copied!' : 'Copy Results'}
          </Button>
        </div>
      </div>

      {/* Calculator Tabs */}
      <Tabs defaultValue="calculator" className="space-y-4">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="calculator">Calculator</TabsTrigger>
          <TabsTrigger value="scenarios">Scenarios</TabsTrigger>
          <TabsTrigger value="projections">Projections</TabsTrigger>
        </TabsList>

        <TabsContent value="calculator" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            {/* Input Section */}
            <Card>
              <CardHeader>
                <CardTitle>Input Parameters</CardTitle>
                <CardDescription>
                  Enter your class details to calculate earnings
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="classPrice">Class Price: ${inputs.classPrice}</Label>
                  <Slider
                    id="classPrice"
                    value={[inputs.classPrice]}
                    onValueChange={([value]) => handleInputChange('classPrice', value)}
                    max={100}
                    min={10}
                    step={5}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="studentCount">Students per Class: {inputs.studentCount}</Label>
                  <Slider
                    id="studentCount"
                    value={[inputs.studentCount]}
                    onValueChange={([value]) => handleInputChange('studentCount', value)}
                    max={50}
                    min={1}
                    step={1}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="classesPerMonth">Classes per Month: {inputs.classesPerMonth}</Label>
                  <Slider
                    id="classesPerMonth"
                    value={[inputs.classesPerMonth]}
                    onValueChange={([value]) => handleInputChange('classesPerMonth', value)}
                    max={50}
                    min={1}
                    step={1}
                  />
                </div>

                <Separator />

                <div className="space-y-2">
                  <Label htmlFor="commissionRate">Commission Rate: {inputs.commissionRate}%</Label>
                  <Slider
                    id="commissionRate"
                    value={[inputs.commissionRate]}
                    onValueChange={([value]) => handleInputChange('commissionRate', value)}
                    max={50}
                    min={5}
                    step={1}
                    className="accent-red-500"
                  />
                </div>

                {showAdvanced && (
                  <>
                    <div className="space-y-2">
                      <Label htmlFor="platformFee">Platform Fee: {inputs.platformFee}%</Label>
                      <Slider
                        id="platformFee"
                        value={[inputs.platformFee]}
                        onValueChange={([value]) => handleInputChange('platformFee', value)}
                        max={5}
                        min={0}
                        step={0.1}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="processingFee">Per Transaction Fee: ${inputs.processingFee}</Label>
                      <Input
                        id="processingFee"
                        type="number"
                        value={inputs.processingFee}
                        onChange={(e) => handleInputChange('processingFee', parseFloat(e.target.value) || 0)}
                        step={0.01}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="taxRate">Tax Rate: {inputs.taxRate}%</Label>
                      <Slider
                        id="taxRate"
                        value={[inputs.taxRate]}
                        onValueChange={([value]) => handleInputChange('taxRate', value)}
                        max={40}
                        min={0}
                        step={1}
                      />
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            {/* Results Section */}
            <div className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Calculation Results</CardTitle>
                  <CardDescription>
                    Your estimated monthly earnings breakdown
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">Gross Revenue</span>
                      <span className="text-lg font-semibold">${result.grossRevenue.toFixed(2)}</span>
                    </div>
                    
                    <div className="flex justify-between items-center text-red-600">
                      <span className="text-sm">Commission ({inputs.commissionRate}%)</span>
                      <span className="font-semibold">-${result.commission.toFixed(2)}</span>
                    </div>
                    
                    <div className="flex justify-between items-center text-orange-600">
                      <span className="text-sm">Platform Fees</span>
                      <span className="font-semibold">-${result.platformFees.toFixed(2)}</span>
                    </div>
                    
                    {result.taxes > 0 && (
                      <div className="flex justify-between items-center text-gray-600">
                        <span className="text-sm">Taxes ({inputs.taxRate}%)</span>
                        <span className="font-semibold">-${result.taxes.toFixed(2)}</span>
                      </div>
                    )}
                    
                    <Separator />
                    
                    <div className="flex justify-between items-center">
                      <span className="font-semibold">Net Earnings</span>
                      <span className="text-2xl font-bold text-green-600">
                        ${result.netEarnings.toFixed(2)}
                      </span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 pt-4">
                    <div className="text-center p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-muted-foreground">Per Class</p>
                      <p className="text-lg font-semibold">${result.perClassEarnings.toFixed(2)}</p>
                    </div>
                    <div className="text-center p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-muted-foreground">Profit Margin</p>
                      <p className="text-lg font-semibold">{result.profitMargin.toFixed(1)}%</p>
                    </div>
                  </div>

                  <Button className="w-full" onClick={addScenario}>
                    <Calculator className="mr-2 h-4 w-4" />
                    Save as Scenario
                  </Button>
                </CardContent>
              </Card>

              {/* Revenue Breakdown Pie Chart */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Revenue Distribution</CardTitle>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={200}>
                    <RePieChart>
                      <Pie
                        data={pieChartData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={(entry) => `${entry.name}: ${((entry.value / result.grossRevenue) * 100).toFixed(1)}%`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {pieChartData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.fill} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value: number) => `$${value.toFixed(2)}`} />
                    </RePieChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Key Metrics */}
          <div className="grid gap-4 md:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Per Student Value</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">${result.perStudentValue.toFixed(2)}</div>
                <p className="text-xs text-muted-foreground">Monthly per student</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Break-Even</CardTitle>
                <AlertCircle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{result.breakEvenStudents}</div>
                <p className="text-xs text-muted-foreground">Students needed</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Effective Rate</CardTitle>
                <Percent className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {(100 - result.profitMargin).toFixed(1)}%
                </div>
                <p className="text-xs text-muted-foreground">Total deductions</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Annual Projection</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  ${(result.netEarnings * 12).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">Estimated yearly</p>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="scenarios" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Scenario Comparison</CardTitle>
              <CardDescription>
                Compare different pricing and commission structures
              </CardDescription>
            </CardHeader>
            <CardContent>
              {scenarios.length === 0 ? (
                <div className="text-center py-8">
                  <Calculator className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                  <p className="text-muted-foreground">
                    No scenarios saved yet. Use the calculator to create scenarios.
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {scenarios.map((scenario, index) => (
                    <div key={index} className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-2">
                          <div 
                            className="w-3 h-3 rounded-full" 
                            style={{ backgroundColor: scenario.color }}
                          />
                          <span className="font-semibold">{scenario.name}</span>
                        </div>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setScenarios(scenarios.filter((_, i) => i !== index))}
                        >
                          Remove
                        </Button>
                      </div>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <p className="text-muted-foreground">Price/Students</p>
                          <p className="font-medium">
                            ${scenario.inputs.classPrice} × {scenario.inputs.studentCount}
                          </p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Commission</p>
                          <p className="font-medium">{scenario.inputs.commissionRate}%</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Gross Revenue</p>
                          <p className="font-medium">${scenario.result.grossRevenue.toFixed(0)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Net Earnings</p>
                          <p className="font-medium text-green-600">
                            ${scenario.result.netEarnings.toFixed(0)}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}

                  {scenarios.length > 1 && (
                    <div className="mt-6">
                      <h4 className="text-sm font-semibold mb-4">Earnings Comparison</h4>
                      <ResponsiveContainer width="100%" height={250}>
                        <BarChart data={scenarios}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="name" />
                          <YAxis />
                          <Tooltip formatter={(value: number) => `$${value.toFixed(2)}`} />
                          <Bar dataKey="result.grossRevenue" name="Gross" fill="#94a3b8" />
                          <Bar dataKey="result.netEarnings" name="Net" fill="#10b981" />
                        </BarChart>
                      </ResponsiveContainer>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="projections" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>12-Month Projection</CardTitle>
              <CardDescription>
                Estimated earnings based on current parameters
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={projectionData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip formatter={(value: number) => `$${value.toFixed(2)}`} />
                  <Legend />
                  <Line 
                    type="monotone" 
                    dataKey="revenue" 
                    stroke="#8884d8" 
                    name="Gross Revenue"
                    strokeWidth={2}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="earnings" 
                    stroke="#10b981" 
                    name="Net Earnings"
                    strokeWidth={2}
                  />
                </LineChart>
              </ResponsiveContainer>

              <div className="grid grid-cols-3 gap-4 mt-6">
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <p className="text-xs text-muted-foreground">Quarterly</p>
                  <p className="text-lg font-semibold">
                    ${(result.netEarnings * 3).toLocaleString()}
                  </p>
                </div>
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <p className="text-xs text-muted-foreground">Semi-Annual</p>
                  <p className="text-lg font-semibold">
                    ${(result.netEarnings * 6).toLocaleString()}
                  </p>
                </div>
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <p className="text-xs text-muted-foreground">Annual</p>
                  <p className="text-lg font-semibold">
                    ${(result.netEarnings * 12).toLocaleString()}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Alert>
            <Info className="h-4 w-4" />
            <AlertDescription>
              These projections assume consistent class attendance and pricing. Actual results may vary based on 
              seasonality, marketing efforts, and market conditions. Consider adding a 10-20% buffer for conservative planning.
            </AlertDescription>
          </Alert>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default CommissionCalculator;