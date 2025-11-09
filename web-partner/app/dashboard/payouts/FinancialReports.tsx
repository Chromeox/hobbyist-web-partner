'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { DatePickerWithRange } from '@/components/ui/date-range-picker';
import { useToast } from '@/components/ui/use-toast';
import { supabase } from '@/lib/supabase';
import { format, startOfYear, endOfYear, startOfQuarter, endOfQuarter, subYears, addMonths } from 'date-fns';
import {
  FileText,
  Download,
  Send,
  Calendar,
  DollarSign,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  Clock,
  Filter,
  Printer,
  Mail,
  Shield,
  Receipt,
  CreditCard,
  Building,
  User,
  ChevronRight,
  FileSpreadsheet,
  FilePlus,
  Archive,
  Lock,
  Info,
  BarChart3,
  PieChart
} from 'lucide-react';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  Area,
  AreaChart
} from 'recharts';

interface FinancialReport {
  id: string;
  type: '1099' | 'w9' | 'earnings_statement' | 'tax_summary' | 'custom';
  year: number;
  quarter?: number;
  status: 'draft' | 'generated' | 'sent' | 'acknowledged';
  generatedAt?: Date;
  sentAt?: Date;
  acknowledgedAt?: Date;
  instructorId: string;
  instructorName: string;
  totalAmount: number;
  documentUrl?: string;
  metadata?: any;
}

interface TaxDocument {
  id: string;
  instructorId: string;
  instructorName: string;
  type: 'w9' | 'w8ben' | 'tax_id';
  status: 'pending' | 'submitted' | 'verified' | 'expired';
  submittedAt?: Date;
  verifiedAt?: Date;
  expiresAt?: Date;
  documentUrl?: string;
}

interface ReportTemplate {
  id: string;
  name: string;
  description: string;
  type: string;
  fields: string[];
  schedule?: 'monthly' | 'quarterly' | 'annually';
  recipients: string[];
}

interface FinancialSummary {
  totalPaid: number;
  totalCommissions: number;
  totalFees: number;
  netRevenue: number;
  instructorCount: number;
  documentCount: number;
  pendingDocuments: number;
}

const FinancialReports: React.FC = () => {
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [selectedReport, setSelectedReport] = useState<string>('');
  const [reports, setReports] = useState<FinancialReport[]>([]);
  const [taxDocuments, setTaxDocuments] = useState<TaxDocument[]>([]);
  const [templates, setTemplates] = useState<ReportTemplate[]>([]);
  const [summary, setSummary] = useState<FinancialSummary | null>(null);
  const [generatingReport, setGeneratingReport] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState<{ from: Date; to: Date }>({
    from: startOfYear(new Date()),
    to: endOfYear(new Date())
  });

  useEffect(() => {
    fetchReportData();
  }, [selectedYear]);

  const fetchReportData = async () => {
    try {
      setLoading(true);

      // Mock financial summary
      const mockSummary: FinancialSummary = {
        totalPaid: 486750.00,
        totalCommissions: 97350.00,
        totalFees: 14602.50,
        netRevenue: 374797.50,
        instructorCount: 47,
        documentCount: 142,
        pendingDocuments: 8
      };
      setSummary(mockSummary);

      // Mock reports
      const mockReports: FinancialReport[] = [
        {
          id: 'report_1',
          type: '1099',
          year: selectedYear,
          status: 'generated',
          generatedAt: new Date('2024-01-15'),
          instructorId: 'instructor_1',
          instructorName: 'Sarah Johnson',
          totalAmount: 45280.00,
          documentUrl: '/reports/1099_sarah_johnson_2024.pdf'
        },
        {
          id: 'report_2',
          type: '1099',
          year: selectedYear,
          status: 'sent',
          generatedAt: new Date('2024-01-15'),
          sentAt: new Date('2024-01-16'),
          instructorId: 'instructor_2',
          instructorName: 'Michael Chen',
          totalAmount: 38950.00,
          documentUrl: '/reports/1099_michael_chen_2024.pdf'
        },
        {
          id: 'report_3',
          type: 'earnings_statement',
          year: selectedYear,
          quarter: 1,
          status: 'acknowledged',
          generatedAt: new Date('2024-04-01'),
          sentAt: new Date('2024-04-02'),
          acknowledgedAt: new Date('2024-04-05'),
          instructorId: 'instructor_3',
          instructorName: 'Emily Rodriguez',
          totalAmount: 12450.00
        }
      ];
      setReports(mockReports);

      // Mock tax documents
      const mockTaxDocuments: TaxDocument[] = [
        {
          id: 'tax_1',
          instructorId: 'instructor_1',
          instructorName: 'Sarah Johnson',
          type: 'w9',
          status: 'verified',
          submittedAt: new Date('2023-11-15'),
          verifiedAt: new Date('2023-11-16'),
          expiresAt: new Date('2024-12-31')
        },
        {
          id: 'tax_2',
          instructorId: 'instructor_2',
          instructorName: 'Michael Chen',
          type: 'w9',
          status: 'verified',
          submittedAt: new Date('2023-10-20'),
          verifiedAt: new Date('2023-10-21')
        },
        {
          id: 'tax_3',
          instructorId: 'instructor_4',
          instructorName: 'David Kim',
          type: 'w9',
          status: 'pending',
          submittedAt: new Date('2024-01-10')
        }
      ];
      setTaxDocuments(mockTaxDocuments);

      // Mock report templates
      const mockTemplates: ReportTemplate[] = [
        {
          id: 'template_1',
          name: 'Annual 1099-MISC',
          description: 'Generate 1099-MISC forms for all eligible instructors',
          type: '1099',
          fields: ['tin', 'name', 'address', 'earnings'],
          schedule: 'annually',
          recipients: ['admin@hobbyist.com', 'accounting@hobbyist.com']
        },
        {
          id: 'template_2',
          name: 'Quarterly Earnings Statement',
          description: 'Quarterly breakdown of instructor earnings',
          type: 'earnings_statement',
          fields: ['name', 'classes', 'students', 'gross', 'commission', 'net'],
          schedule: 'quarterly',
          recipients: ['instructors']
        },
        {
          id: 'template_3',
          name: 'Monthly Revenue Report',
          description: 'Monthly financial summary for management',
          type: 'custom',
          fields: ['revenue', 'commissions', 'fees', 'payouts', 'net'],
          schedule: 'monthly',
          recipients: ['cfo@hobbyist.com']
        }
      ];
      setTemplates(mockTemplates);

    } catch (error) {
      console.error('Error fetching report data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateReport = async (type: string) => {
    try {
      setGeneratingReport(type);
      
      // Simulate report generation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      toast({
        title: 'Report generated successfully',
        description: `Your ${type} report has been generated and is ready for download`,
      });

      fetchReportData();
    } catch (error) {
      console.error('Error generating report:', error);
      toast({
        title: 'Generation failed',
        description: 'Could not generate the report',
        variant: 'destructive',
      });
    } finally {
      setGeneratingReport(null);
    }
  };

  const handleSendReport = async (reportId: string) => {
    try {
      // Send report via email
      const { error } = await supabase
        .from('financial_reports')
        .update({ status: 'sent', sentAt: new Date() })
        .eq('id', reportId);

      if (error) throw error;

      toast({
        title: 'Report sent',
        description: 'The report has been sent to the instructor',
      });

      fetchReportData();
    } catch (error) {
      console.error('Error sending report:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'draft':
        return <FileText className="h-4 w-4 text-gray-500" />;
      case 'generated':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'sent':
        return <Send className="h-4 w-4 text-blue-500" />;
      case 'acknowledged':
        return <Shield className="h-4 w-4 text-green-600" />;
      case 'verified':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'pending':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'expired':
        return <AlertCircle className="h-4 w-4 text-red-500" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'generated': return 'bg-green-100 text-green-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'acknowledged': return 'bg-green-100 text-green-800';
      case 'verified': return 'bg-green-100 text-green-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'expired': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const monthlyData = Array.from({ length: 12 }, (_, i) => ({
    month: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
    revenue: Math.floor(Math.random() * 20000) + 30000,
    payouts: Math.floor(Math.random() * 15000) + 25000,
    commissions: Math.floor(Math.random() * 5000) + 5000
  }));

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Financial Reports</h2>
          <p className="text-muted-foreground mt-1">
            Generate tax documents, earnings statements, and financial reports
          </p>
        </div>
        <div className="flex gap-2">
          <Select value={selectedYear.toString()} onValueChange={(value) => setSelectedYear(parseInt(value))}>
            <SelectTrigger className="w-[120px]">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[0, 1, 2].map(offset => {
                const year = new Date().getFullYear() - offset;
                return (
                  <SelectItem key={year} value={year.toString()}>
                    {year}
                  </SelectItem>
                );
              })}
            </SelectContent>
          </Select>
          <Button variant="outline">
            <Filter className="mr-2 h-4 w-4" />
            Filter
          </Button>
          <Button>
            <FilePlus className="mr-2 h-4 w-4" />
            Generate Report
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Paid Out</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">${summary.totalPaid.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground">Year to date</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Commissions</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">${summary.totalCommissions.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground">Platform revenue</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Instructors</CardTitle>
              <User className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{summary.instructorCount}</div>
              <p className="text-xs text-muted-foreground">With earnings</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Documents</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{summary.documentCount}</div>
              <p className="text-xs text-muted-foreground">
                {summary.pendingDocuments} pending
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Reports Tabs */}
      <Tabs defaultValue="tax" className="space-y-4">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="tax">Tax Documents</TabsTrigger>
          <TabsTrigger value="earnings">Earnings Statements</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
          <TabsTrigger value="templates">Templates</TabsTrigger>
          <TabsTrigger value="compliance">Compliance</TabsTrigger>
        </TabsList>

        <TabsContent value="tax" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>1099 Forms</CardTitle>
                  <CardDescription>
                    Generate and manage 1099-MISC forms for instructors
                  </CardDescription>
                </div>
                <Button 
                  onClick={() => handleGenerateReport('1099')}
                  disabled={generatingReport === '1099'}
                >
                  {generatingReport === '1099' ? (
                    <>
                      <Clock className="mr-2 h-4 w-4 animate-spin" />
                      Generating...
                    </>
                  ) : (
                    <>
                      <FileText className="mr-2 h-4 w-4" />
                      Generate All 1099s
                    </>
                  )}
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {reports.filter(r => r.type === '1099').map((report) => (
                  <div key={report.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      {getStatusIcon(report.status)}
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">{report.instructorName}</span>
                          <Badge className={getStatusColor(report.status)}>
                            {report.status}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                          <span>Total: ${report.totalAmount.toLocaleString()}</span>
                          <span>Year: {report.year}</span>
                          {report.generatedAt && (
                            <span>Generated: {format(report.generatedAt, 'MMM dd, yyyy')}</span>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      {report.documentUrl && (
                        <Button size="sm" variant="outline">
                          <Download className="mr-2 h-4 w-4" />
                          Download
                        </Button>
                      )}
                      {report.status === 'generated' && (
                        <Button size="sm" onClick={() => handleSendReport(report.id)}>
                          <Send className="mr-2 h-4 w-4" />
                          Send
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <Alert className="mt-4">
                <Info className="h-4 w-4" />
                <AlertTitle>1099 Requirements</AlertTitle>
                <AlertDescription>
                  1099-MISC forms are required for instructors who earned $600 or more during the tax year.
                  Forms must be sent to instructors by January 31st and filed with the IRS by February 28th.
                </AlertDescription>
              </Alert>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>W-9 Collection Status</CardTitle>
              <CardDescription>
                Track W-9 form collection from instructors
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {taxDocuments.map((doc) => (
                  <div key={doc.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      {getStatusIcon(doc.status)}
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">{doc.instructorName}</span>
                          <Badge className={getStatusColor(doc.status)}>
                            {doc.status}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                          <span>Type: {doc.type.toUpperCase()}</span>
                          {doc.submittedAt && (
                            <span>Submitted: {format(doc.submittedAt, 'MMM dd, yyyy')}</span>
                          )}
                          {doc.expiresAt && (
                            <span>Expires: {format(doc.expiresAt, 'MMM dd, yyyy')}</span>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      {doc.status === 'pending' && (
                        <Button size="sm" variant="outline">
                          Review
                        </Button>
                      )}
                      {doc.status === 'verified' && (
                        <Button size="sm" variant="outline">
                          <Download className="mr-2 h-4 w-4" />
                          Download
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold">Collection Progress</p>
                    <p className="text-sm text-muted-foreground mt-1">
                      {taxDocuments.filter(d => d.status === 'verified').length} of {taxDocuments.length} verified
                    </p>
                  </div>
                  <div className="text-right">
                    <Progress 
                      value={(taxDocuments.filter(d => d.status === 'verified').length / taxDocuments.length) * 100} 
                      className="w-32"
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="earnings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Earnings Statements</CardTitle>
              <CardDescription>
                Generate detailed earnings statements for instructors
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex gap-4">
                  <Select defaultValue="quarterly">
                    <SelectTrigger className="w-[180px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="monthly">Monthly</SelectItem>
                      <SelectItem value="quarterly">Quarterly</SelectItem>
                      <SelectItem value="annually">Annually</SelectItem>
                      <SelectItem value="custom">Custom Range</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button>
                    <FileSpreadsheet className="mr-2 h-4 w-4" />
                    Generate Statements
                  </Button>
                </div>

                <div className="space-y-3">
                  {reports.filter(r => r.type === 'earnings_statement').map((report) => (
                    <div key={report.id} className="flex items-center justify-between p-4 border rounded-lg">
                      <div className="flex items-center gap-4">
                        {getStatusIcon(report.status)}
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-semibold">{report.instructorName}</span>
                            <Badge variant="outline">Q{report.quarter} {report.year}</Badge>
                            <Badge className={getStatusColor(report.status)}>
                              {report.status}
                            </Badge>
                          </div>
                          <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                            <span>Earnings: ${report.totalAmount.toLocaleString()}</span>
                            {report.sentAt && (
                              <span>Sent: {format(report.sentAt, 'MMM dd, yyyy')}</span>
                            )}
                            {report.acknowledgedAt && (
                              <span className="text-green-600">
                                ✓ Acknowledged: {format(report.acknowledgedAt, 'MMM dd')}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                      
                      <Button size="sm" variant="outline">
                        <Download className="mr-2 h-4 w-4" />
                        Download
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="analytics" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Financial Analytics</CardTitle>
              <CardDescription>
                Revenue, commissions, and payout trends
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div>
                  <h4 className="text-sm font-semibold mb-4">Monthly Financial Overview</h4>
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={monthlyData}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                          <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                        </linearGradient>
                        <linearGradient id="colorPayouts" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#82ca9d" stopOpacity={0.8}/>
                          <stop offset="95%" stopColor="#82ca9d" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <XAxis dataKey="month" />
                      <YAxis />
                      <CartesianGrid strokeDasharray="3 3" />
                      <Tooltip />
                      <Legend />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        stroke="#8884d8"
                        fillOpacity={1}
                        fill="url(#colorRevenue)"
                      />
                      <Area
                        type="monotone"
                        dataKey="payouts"
                        stroke="#82ca9d"
                        fillOpacity={1}
                        fill="url(#colorPayouts)"
                      />
                      <Line type="monotone" dataKey="commissions" stroke="#ffc658" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Average Payout</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">$1,842</div>
                      <p className="text-xs text-muted-foreground">Per instructor</p>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Commission Rate</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">19.3%</div>
                      <p className="text-xs text-muted-foreground">Average rate</p>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Growth</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold text-green-600">+23.5%</div>
                      <p className="text-xs text-muted-foreground">YoY increase</p>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="templates" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Report Templates</CardTitle>
              <CardDescription>
                Manage automated report generation templates
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {templates.map((template) => (
                  <div key={template.id} className="border rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div>
                        <h4 className="font-semibold">{template.name}</h4>
                        <p className="text-sm text-muted-foreground">{template.description}</p>
                      </div>
                      <Badge variant="outline">{template.schedule}</Badge>
                    </div>
                    
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <FileText className="h-3 w-3" />
                        {template.type}
                      </span>
                      <span className="flex items-center gap-1">
                        <Mail className="h-3 w-3" />
                        {template.recipients.length} recipients
                      </span>
                      <span className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        Next: {format(addMonths(new Date(), 1), 'MMM dd')}
                      </span>
                    </div>
                    
                    <div className="flex justify-end gap-2 mt-4">
                      <Button size="sm" variant="outline">Edit</Button>
                      <Button size="sm" variant="outline">Test Run</Button>
                      <Button size="sm">Run Now</Button>
                    </div>
                  </div>
                ))}
                
                <Button variant="outline" className="w-full">
                  <FilePlus className="mr-2 h-4 w-4" />
                  Create New Template
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="compliance" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Compliance Dashboard</CardTitle>
              <CardDescription>
                Track tax compliance and regulatory requirements
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <Alert>
                  <Shield className="h-4 w-4" />
                  <AlertTitle>Compliance Status: Good</AlertTitle>
                  <AlertDescription>
                    All required tax documents are up to date. Next filing deadline: February 28, 2024.
                  </AlertDescription>
                </Alert>

                <div className="space-y-4">
                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <CheckCircle className="h-5 w-5 text-green-500" />
                      <div>
                        <p className="font-semibold">W-9 Collection</p>
                        <p className="text-sm text-muted-foreground">
                          39 of 47 instructors have submitted W-9 forms
                        </p>
                      </div>
                    </div>
                    <Progress value={83} className="w-32" />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <CheckCircle className="h-5 w-5 text-green-500" />
                      <div>
                        <p className="font-semibold">1099 Preparation</p>
                        <p className="text-sm text-muted-foreground">
                          Ready to generate for 35 eligible instructors
                        </p>
                      </div>
                    </div>
                    <Progress value={100} className="w-32" />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <Clock className="h-5 w-5 text-yellow-500" />
                      <div>
                        <p className="font-semibold">State Tax Registration</p>
                        <p className="text-sm text-muted-foreground">
                          Renewal required by March 31, 2024
                        </p>
                      </div>
                    </div>
                    <Button size="sm">Renew</Button>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <CheckCircle className="h-5 w-5 text-green-500" />
                      <div>
                        <p className="font-semibold">Backup Withholding</p>
                        <p className="text-sm text-muted-foreground">
                          No instructors subject to backup withholding
                        </p>
                      </div>
                    </div>
                    <Badge className="bg-green-100 text-green-800">Compliant</Badge>
                  </div>
                </div>

                <div className="p-4 bg-gray-50 rounded-lg">
                  <h4 className="font-semibold mb-2">Upcoming Deadlines</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span>Send 1099s to instructors</span>
                      <span className="font-medium">January 31, 2024</span>
                    </div>
                    <div className="flex justify-between">
                      <span>File 1099s with IRS</span>
                      <span className="font-medium">February 28, 2024</span>
                    </div>
                    <div className="flex justify-between">
                      <span>State tax renewal</span>
                      <span className="font-medium">March 31, 2024</span>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default FinancialReports;
