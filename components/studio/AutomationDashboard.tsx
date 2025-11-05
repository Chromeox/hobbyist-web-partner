'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Bot,
  Settings,
  Play,
  Pause,
  RefreshCw,
  CheckCircle,
  AlertTriangle,
  Clock,
  Zap,
  ShoppingCart,
  TrendingUp,
  MessageSquare,
  BarChart3,
  Calendar,
  DollarSign,
  Users,
  Package,
  Camera,
  Bell,
  ExternalLink,
  Edit,
  Trash2,
  Plus
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { StudioAutomationManager } from '@/lib/mcp/studio-automation';

interface AutomationWorkflow {
  id: string;
  name: string;
  description: string;
  type: 'inventory' | 'marketing' | 'financial' | 'communication' | 'analytics';
  status: 'active' | 'paused' | 'error' | 'configuring';
  frequency: 'real_time' | 'hourly' | 'daily' | 'weekly' | 'monthly';
  last_run?: string;
  next_run?: string;
  success_rate: number;
  total_runs: number;
  settings: Record<string, any>;
  dependencies: string[]; // Other workflows this depends on
}

interface AutomationResult {
  workflow_id: string;
  run_id: string;
  started_at: string;
  completed_at?: string;
  status: 'running' | 'completed' | 'failed';
  result_summary: string;
  details: Record<string, any>;
  output_links: Array<{ type: string; url: string; description: string }>;
}

interface AutomationDashboardProps {
  studioId: string;
}

const WORKFLOW_ICONS = {
  inventory: Package,
  marketing: MessageSquare,
  financial: DollarSign,
  communication: Bell,
  analytics: BarChart3,
};

const WORKFLOW_COLORS = {
  inventory: 'bg-blue-100 text-blue-800',
  marketing: 'bg-purple-100 text-purple-800',
  financial: 'bg-green-100 text-green-800',
  communication: 'bg-orange-100 text-orange-800',
  analytics: 'bg-indigo-100 text-indigo-800',
};

export function AutomationDashboard({ studioId }: AutomationDashboardProps) {
  const [workflows, setWorkflows] = useState<AutomationWorkflow[]>([]);
  const [recentResults, setRecentResults] = useState<AutomationResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedWorkflow, setSelectedWorkflow] = useState<AutomationWorkflow | null>(null);
  const [showConfigModal, setShowConfigModal] = useState(false);
  const [runningWorkflows, setRunningWorkflows] = useState<Set<string>>(new Set());

  const automationManager = new StudioAutomationManager(studioId);

  useEffect(() => {
    fetchAutomationData();
  }, [studioId]);

  const fetchAutomationData = async () => {
    setLoading(true);
    try {
      // Mock data - replace with actual API calls
      const mockWorkflows: AutomationWorkflow[] = [
        {
          id: '1',
          name: 'Smart Inventory Reordering',
          description: 'Automatically reorder materials when stock runs low',
          type: 'inventory',
          status: 'active',
          frequency: 'daily',
          last_run: '2025-09-17T08:00:00Z',
          next_run: '2025-09-18T08:00:00Z',
          success_rate: 95,
          total_runs: 47,
          settings: {
            reorder_threshold: 0.8,
            preferred_suppliers: ['Creative Clay Supply', 'Art Supplies Plus'],
            auto_approve_under: 500,
            notifications: ['email', 'dashboard']
          },
          dependencies: []
        },
        {
          id: '2',
          name: 'Student Work Social Posts',
          description: 'Create and schedule social media posts featuring student projects',
          type: 'marketing',
          status: 'active',
          frequency: 'daily',
          last_run: '2025-09-17T14:30:00Z',
          next_run: '2025-09-18T14:30:00Z',
          success_rate: 88,
          total_runs: 23,
          settings: {
            platforms: ['instagram', 'facebook'],
            post_frequency: 2,
            hashtags: ['#hobbyist', '#handmade', '#vancouver'],
            require_approval: false
          },
          dependencies: []
        },
        {
          id: '3',
          name: 'Weekly Financial Reports',
          description: 'Generate revenue, expense, and payroll reports in Google Sheets',
          type: 'financial',
          status: 'active',
          frequency: 'weekly',
          last_run: '2025-09-15T09:00:00Z',
          next_run: '2025-09-22T09:00:00Z',
          success_rate: 100,
          total_runs: 12,
          settings: {
            include_forecasts: true,
            share_with: ['owner@studio.com', 'accountant@studio.com'],
            format: 'google_sheets',
            backup_to_drive: true
          },
          dependencies: []
        },
        {
          id: '4',
          name: 'Student Retention Analysis',
          description: 'Analyze student behavior and trigger re-engagement campaigns',
          type: 'communication',
          status: 'active',
          frequency: 'weekly',
          last_run: '2025-09-16T10:00:00Z',
          next_run: '2025-09-23T10:00:00Z',
          success_rate: 92,
          total_runs: 8,
          settings: {
            churn_threshold_days: 45,
            reengagement_offers: ['20% discount', 'free trial'],
            communication_channels: ['email', 'sms'],
            exclude_vip: false
          },
          dependencies: []
        },
        {
          id: '5',
          name: 'Competitor Price Monitoring',
          description: 'Track competitor pricing and workshop availability',
          type: 'analytics',
          status: 'paused',
          frequency: 'weekly',
          last_run: '2025-09-10T16:00:00Z',
          next_run: '2025-09-24T16:00:00Z',
          success_rate: 75,
          total_runs: 6,
          settings: {
            competitors: ['Pottery Place', 'Art Studio Downtown', 'Creative Space'],
            price_alert_threshold: 10,
            availability_tracking: true,
            report_format: 'dashboard'
          },
          dependencies: []
        },
        {
          id: '6',
          name: 'Material Efficiency Tracking',
          description: 'Analyze material usage and identify cost savings',
          type: 'analytics',
          status: 'active',
          frequency: 'monthly',
          last_run: '2025-09-01T12:00:00Z',
          next_run: '2025-10-01T12:00:00Z',
          success_rate: 100,
          total_runs: 3,
          settings: {
            efficiency_targets: { pottery: 85, painting: 90, woodworking: 80 },
            waste_alerts: true,
            cost_saving_recommendations: true,
            include_supplier_analysis: true
          },
          dependencies: ['1'] // Depends on inventory workflow
        }
      ];

      const mockResults: AutomationResult[] = [
        {
          workflow_id: '1',
          run_id: 'run_001',
          started_at: '2025-09-17T08:00:00Z',
          completed_at: '2025-09-17T08:05:00Z',
          status: 'completed',
          result_summary: 'Ordered 3 materials from 2 suppliers, total cost $245.50',
          details: {
            materials_ordered: 3,
            suppliers_contacted: 2,
            total_cost: 245.50,
            estimated_delivery: '2025-09-22'
          },
          output_links: [
            {
              type: 'purchase_order',
              url: 'https://docs.google.com/spreadsheets/d/abc123',
              description: 'Purchase Order Details'
            }
          ]
        },
        {
          workflow_id: '2',
          run_id: 'run_002',
          started_at: '2025-09-17T14:30:00Z',
          completed_at: '2025-09-17T14:35:00Z',
          status: 'completed',
          result_summary: 'Posted 2 student projects to Instagram and Facebook',
          details: {
            posts_created: 2,
            platforms: ['instagram', 'facebook'],
            engagement_rate: 8.5,
            reach: 1250
          },
          output_links: [
            {
              type: 'social_post',
              url: 'https://instagram.com/p/abc123',
              description: 'Instagram Post'
            }
          ]
        },
        {
          workflow_id: '4',
          run_id: 'run_003',
          started_at: '2025-09-16T10:00:00Z',
          completed_at: '2025-09-16T10:15:00Z',
          status: 'completed',
          result_summary: 'Identified 5 at-risk students, sent 3 re-engagement emails',
          details: {
            students_analyzed: 45,
            at_risk_identified: 5,
            emails_sent: 3,
            offers_redeemed: 1
          },
          output_links: [
            {
              type: 'retention_report',
              url: 'https://docs.google.com/spreadsheets/d/def456',
              description: 'Student Retention Analysis'
            }
          ]
        }
      ];

      setWorkflows(mockWorkflows);
      setRecentResults(mockResults);
    } catch (error) {
      console.error('Failed to fetch automation data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getWorkflowStats = () => {
    const active = workflows.filter(w => w.status === 'active').length;
    const paused = workflows.filter(w => w.status === 'paused').length;
    const errors = workflows.filter(w => w.status === 'error').length;
    const avgSuccessRate = workflows.reduce((sum, w) => sum + w.success_rate, 0) / workflows.length;

    return { active, paused, errors, avgSuccessRate };
  };

  const handleRunWorkflow = async (workflowId: string) => {
    setRunningWorkflows(prev => new Set([...prev, workflowId]));

    try {
      const workflow = workflows.find(w => w.id === workflowId);
      if (!workflow) return;

      // Simulate running the workflow
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Mock successful result
      const newResult: AutomationResult = {
        workflow_id: workflowId,
        run_id: `run_${Date.now()}`,
        started_at: new Date().toISOString(),
        completed_at: new Date().toISOString(),
        status: 'completed',
        result_summary: `Manual run of ${workflow.name} completed successfully`,
        details: { manual_run: true },
        output_links: []
      };

      setRecentResults(prev => [newResult, ...prev.slice(0, 9)]);
    } catch (error) {
      console.error('Failed to run workflow:', error);
    } finally {
      setRunningWorkflows(prev => {
        const newSet = new Set(prev);
        newSet.delete(workflowId);
        return newSet;
      });
    }
  };

  const handleToggleWorkflow = async (workflowId: string) => {
    setWorkflows(prev => prev.map(w =>
      w.id === workflowId
        ? { ...w, status: w.status === 'active' ? 'paused' : 'active' }
        : w
    ));
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'paused':
        return <Pause className="h-4 w-4 text-yellow-500" />;
      case 'error':
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      default:
        return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'paused':
        return 'bg-yellow-100 text-yellow-800';
      case 'error':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-6">
                <div className="h-16 bg-gray-200 rounded"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  const stats = getWorkflowStats();

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Studio Automation</h1>
          <p className="text-gray-600">Automate your studio operations with AI-powered workflows</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchAutomationData}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
          <Button variant="creative">
            <Plus className="h-4 w-4 mr-2" />
            New Workflow
          </Button>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Active Workflows</p>
                <p className="text-2xl font-bold">{stats.active}</p>
              </div>
              <Bot className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Success Rate</p>
                <p className="text-2xl font-bold">{Math.round(stats.avgSuccessRate)}%</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Paused</p>
                <p className="text-2xl font-bold">{stats.paused}</p>
              </div>
              <Pause className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Errors</p>
                <p className="text-2xl font-bold">{stats.errors}</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Workflows Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {workflows.map((workflow, index) => {
          const Icon = WORKFLOW_ICONS[workflow.type];
          const isRunning = runningWorkflows.has(workflow.id);

          return (
            <motion.div
              key={workflow.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="hover:shadow-md transition-shadow">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-3">
                      <div className={`p-2 rounded-lg ${WORKFLOW_COLORS[workflow.type]}`}>
                        <Icon className="h-4 w-4" />
                      </div>
                      <div>
                        <CardTitle className="text-lg">{workflow.name}</CardTitle>
                        <CardDescription>{workflow.description}</CardDescription>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      {getStatusIcon(workflow.status)}
                      <Badge className={getStatusColor(workflow.status)}>
                        {workflow.status}
                      </Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {/* Workflow Details */}
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="font-medium">Frequency:</span>
                        <p className="capitalize">{workflow.frequency}</p>
                      </div>
                      <div>
                        <span className="font-medium">Success Rate:</span>
                        <p>{workflow.success_rate}% ({workflow.total_runs} runs)</p>
                      </div>
                      <div>
                        <span className="font-medium">Last Run:</span>
                        <p>
                          {workflow.last_run
                            ? new Date(workflow.last_run).toLocaleDateString()
                            : 'Never'
                          }
                        </p>
                      </div>
                      <div>
                        <span className="font-medium">Next Run:</span>
                        <p>
                          {workflow.next_run && workflow.status === 'active'
                            ? new Date(workflow.next_run).toLocaleDateString()
                            : 'Paused'
                          }
                        </p>
                      </div>
                    </div>

                    {/* Dependencies */}
                    {workflow.dependencies.length > 0 && (
                      <div>
                        <span className="text-sm font-medium">Dependencies:</span>
                        <div className="flex flex-wrap gap-1 mt-1">
                          {workflow.dependencies.map(depId => {
                            const depWorkflow = workflows.find(w => w.id === depId);
                            return (
                              <Badge key={depId} variant="outline" className="text-xs">
                                {depWorkflow?.name || `Workflow ${depId}`}
                              </Badge>
                            );
                          })}
                        </div>
                      </div>
                    )}

                    {/* Action Buttons */}
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleRunWorkflow(workflow.id)}
                        disabled={isRunning}
                        className="flex-1"
                      >
                        {isRunning ? (
                          <RefreshCw className="h-3 w-3 mr-1 animate-spin" />
                        ) : (
                          <Play className="h-3 w-3 mr-1" />
                        )}
                        {isRunning ? 'Running...' : 'Run Now'}
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleToggleWorkflow(workflow.id)}
                      >
                        {workflow.status === 'active' ? (
                          <Pause className="h-3 w-3" />
                        ) : (
                          <Play className="h-3 w-3" />
                        )}
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setSelectedWorkflow(workflow)}
                      >
                        <Settings className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          );
        })}
      </div>

      {/* Recent Results */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Automation Results</CardTitle>
          <CardDescription>Latest workflow executions and their outcomes</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {recentResults.map((result, index) => {
              const workflow = workflows.find(w => w.id === result.workflow_id);
              const Icon = workflow ? WORKFLOW_ICONS[workflow.type] : Bot;

              return (
                <motion.div
                  key={result.run_id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="flex items-center justify-between p-3 border rounded-lg"
                >
                  <div className="flex items-center space-x-3">
                    <Icon className="h-4 w-4 text-gray-500" />
                    <div>
                      <p className="font-medium">{workflow?.name || 'Unknown Workflow'}</p>
                      <p className="text-sm text-gray-600">{result.result_summary}</p>
                      <p className="text-xs text-gray-500">
                        {new Date(result.started_at).toLocaleString()}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Badge
                      variant={result.status === 'completed' ? 'secondary' : 'destructive'}
                      className="text-xs"
                    >
                      {result.status}
                    </Badge>
                    {result.output_links.length > 0 && (
                      <Button size="sm" variant="outline">
                        <ExternalLink className="h-3 w-3" />
                      </Button>
                    )}
                  </div>
                </motion.div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}