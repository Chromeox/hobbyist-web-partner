'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Calendar,
  Plus,
  Settings,
  AlertTriangle,
  CheckCircle,
  Clock,
  ExternalLink,
  RefreshCw,
  Upload,
  Download,
  Eye,
  MapPin
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CalendarIntegrationManager } from '@/lib/integrations/calendar-manager';
import type {
  CalendarIntegration,
  CalendarProvider,
  ImportedEvent,
  ImportResult
} from '@/types/calendar-integration';

interface CalendarIntegrationHubProps {
  studioId: string;
}

const PROVIDER_INFO: Record<CalendarProvider, {
  name: string;
  description: string;
  icon: string;
  color: string;
  features: string[];
}> = {
  google: {
    name: 'Google Calendar',
    description: 'Sync with Google Calendar and Google Workspace',
    icon: '📅',
    color: 'bg-blue-100 text-blue-800',
    features: ['Two-way sync', 'Real-time updates', 'Attendee management'],
  },
  outlook: {
    name: 'Microsoft Outlook',
    description: 'Integrate with Outlook and Office 365 calendars',
    icon: '📧',
    color: 'bg-indigo-100 text-indigo-800',
    features: ['Office 365 sync', 'Teams integration', 'Business calendars'],
  },
  apple: {
    name: 'Apple Calendar',
    description: 'Sync with iCloud Calendar across Apple devices',
    icon: '🍎',
    color: 'bg-red-100 text-red-800',
    features: ['iCloud sync', 'Multi-device support'],
  },
  mindbody: {
    name: 'Mindbody',
    description: 'Import classes and appointments from Mindbody',
    icon: '💪',
    color: 'bg-green-100 text-green-800',
    features: ['Class schedules', 'Client bookings', 'Staff assignments'],
  },
  acuity: {
    name: 'Acuity Scheduling',
    description: 'Sync appointment bookings and availability',
    icon: '⏰',
    color: 'bg-purple-100 text-purple-800',
    features: ['Appointment sync', 'Availability blocks', 'Client management'],
  },
  calendly: {
    name: 'Calendly',
    description: 'Import scheduled events and bookings',
    icon: '📆',
    color: 'bg-orange-100 text-orange-800',
    features: ['Event import', 'Booking sync', 'Meeting types'],
  },
  square: {
    name: 'Square Appointments',
    description: 'Sync with Square\'s appointment booking system',
    icon: '□',
    color: 'bg-gray-100 text-gray-800',
    features: ['Appointment sync', 'Payment integration', 'Customer data'],
  },
};

export function CalendarIntegrationHub({ studioId }: CalendarIntegrationHubProps) {
  const [integrations, setIntegrations] = useState<CalendarIntegration[]>([]);
  const [pendingEvents, setPendingEvents] = useState<ImportedEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState<string | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [syncStats, setSyncStats] = useState<any>(null);

  const integrationManager = new CalendarIntegrationManager();

  useEffect(() => {
    fetchIntegrations();
    fetchPendingEvents();
    fetchSyncStats();
  }, [studioId]);

  const fetchIntegrations = async () => {
    try {
      const data = await integrationManager.getStudioIntegrations(studioId);
      setIntegrations(data);
    } catch (error) {
      console.error('Failed to fetch integrations:', error);
    }
  };

  const fetchPendingEvents = async () => {
    try {
      const events = await integrationManager.getEventsNeedingReview(studioId);
      setPendingEvents(events);
    } catch (error) {
      console.error('Failed to fetch pending events:', error);
    }
  };

  const fetchSyncStats = async () => {
    try {
      const stats = await integrationManager.getSyncStats(studioId);
      setSyncStats(stats);
    } catch (error) {
      console.error('Failed to fetch sync stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleImportEvents = async (integrationId: string) => {
    setImporting(integrationId);
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

      const result = await integrationManager.importEvents(
        integrationId,
        thirtyDaysAgo,
        thirtyDaysFromNow
      );

      await fetchPendingEvents();
      await fetchSyncStats();

      // Show success message
      console.log('Import result:', result);
    } catch (error) {
      console.error('Import failed:', error);
    } finally {
      setImporting(null);
    }
  };

  const handleSyncAll = async () => {
    setImporting('all');
    try {
      const results = await integrationManager.syncAllIntegrations(studioId);
      await fetchPendingEvents();
      await fetchSyncStats();
      console.log('Sync results:', results);
    } catch (error) {
      console.error('Sync all failed:', error);
    } finally {
      setImporting(null);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error':
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      case 'paused':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      default:
        return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const getProviderIcon = (provider: CalendarProvider) => {
    return PROVIDER_INFO[provider]?.icon || '📅';
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-6">
                <div className="h-20 bg-gray-200 rounded"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Calendar Integration</h1>
          <p className="text-gray-600">Import and sync from your existing booking systems</p>
        </div>
        <div className="flex gap-2">
          <Button
            onClick={handleSyncAll}
            disabled={importing === 'all' || integrations.length === 0}
            variant="outline"
          >
            {importing === 'all' ? (
              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4 mr-2" />
            )}
            Sync All
          </Button>
          <Button onClick={() => setShowAddModal(true)} variant="creative">
            <Plus className="h-4 w-4 mr-2" />
            Add Integration
          </Button>
        </div>
      </div>

      {/* Sync Stats */}
      {syncStats && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Active Integrations</p>
                  <p className="text-2xl font-bold">{syncStats.active_integrations}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Pending Review</p>
                  <p className="text-2xl font-bold">{syncStats.pending_reviews}</p>
                </div>
                <Eye className="h-8 w-8 text-yellow-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Events Imported</p>
                  <p className="text-2xl font-bold">{syncStats.total_imported}</p>
                </div>
                <Download className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Last Sync</p>
                  <p className="text-sm font-bold">
                    {syncStats.last_sync
                      ? new Date(syncStats.last_sync).toLocaleDateString()
                      : 'Never'
                    }
                  </p>
                </div>
                <Clock className="h-8 w-8 text-gray-500" />
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Connected Integrations */}
      {integrations.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Connected Integrations</CardTitle>
            <CardDescription>Manage your connected calendar and booking systems</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {integrations.map((integration, index) => (
                <motion.div
                  key={integration.id}
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: index * 0.1 }}
                  className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-center space-x-4">
                    <div className="text-2xl">{getProviderIcon(integration.provider)}</div>
                    <div>
                      <div className="flex items-center space-x-2">
                        <h3 className="font-medium">{PROVIDER_INFO[integration.provider]?.name}</h3>
                        {getStatusIcon(integration.sync_status)}
                        <Badge
                          variant={integration.sync_status === 'active' ? 'default' : 'destructive'}
                          className="text-xs"
                        >
                          {integration.sync_status}
                        </Badge>
                      </div>
                      <p className="text-sm text-gray-600">
                        {integration.sync_direction === 'bidirectional' && 'Two-way sync'}
                        {integration.sync_direction === 'import_only' && 'Import only'}
                        {integration.sync_direction === 'export_only' && 'Export only'}
                        {integration.last_sync_at && (
                          <> • Last sync: {new Date(integration.last_sync_at).toLocaleDateString()}</>
                        )}
                      </p>
                      {integration.error_message && (
                        <p className="text-sm text-red-600 mt-1">{integration.error_message}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleImportEvents(integration.id)}
                      disabled={importing === integration.id}
                    >
                      {importing === integration.id ? (
                        <RefreshCw className="h-4 w-4 animate-spin" />
                      ) : (
                        <Download className="h-4 w-4" />
                      )}
                    </Button>
                    <Button size="sm" variant="outline">
                      <Settings className="h-4 w-4" />
                    </Button>
                  </div>
                </motion.div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Pending Events Review */}
      {pendingEvents.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Events Needing Review</CardTitle>
            <CardDescription>
              Review and approve imported events before adding to your schedule
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {pendingEvents.slice(0, 5).map((event, index) => (
                <motion.div
                  key={event.id}
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: index * 0.1 }}
                  className="flex items-center justify-between p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
                >
                  <div className="flex items-center space-x-4">
                    <div className="text-2xl">{getProviderIcon(event.provider)}</div>
                    <div>
                      <h4 className="font-medium text-gray-900">{event.title}</h4>
                      <div className="flex items-center space-x-4 text-sm text-gray-600">
                        <span>
                          {new Date(event.start_time).toLocaleDateString()} at{' '}
                          {new Date(event.start_time).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                        {event.category && (
                          <Badge variant={event.category as any} className="text-xs">
                            {event.category}
                          </Badge>
                        )}
                        {event.location && (
                          <span className="flex items-center">
                            <MapPin className="h-3 w-3 mr-1" />
                            {event.location}
                          </span>
                        )}
                      </div>
                      {event.instructor_name && (
                        <p className="text-sm text-gray-600">Instructor: {event.instructor_name}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button size="sm" variant="outline">
                      Review
                    </Button>
                    <Button size="sm" variant="creative">
                      Approve
                    </Button>
                  </div>
                </motion.div>
              ))}
              {pendingEvents.length > 5 && (
                <div className="text-center pt-4">
                  <Button variant="outline">
                    View All {pendingEvents.length} Events
                  </Button>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Available Integrations */}
      {integrations.length === 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Available Integrations</CardTitle>
            <CardDescription>Connect your existing booking systems to get started</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(PROVIDER_INFO).map(([provider, info]) => (
                <motion.div
                  key={provider}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className="p-4 border rounded-lg hover:shadow-md transition-all cursor-pointer"
                  onClick={() => {
                    // Handle provider selection
                    console.log('Selected provider:', provider);
                  }}
                >
                  <div className="flex items-start space-x-3">
                    <div className="text-2xl">{info.icon}</div>
                    <div className="flex-1">
                      <h3 className="font-medium text-gray-900">{info.name}</h3>
                      <p className="text-sm text-gray-600 mt-1">{info.description}</p>
                      <div className="flex flex-wrap gap-1 mt-2">
                        {info.features.map((feature) => (
                          <Badge key={feature} variant="secondary" className="text-xs">
                            {feature}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  </div>
                  <Button className="w-full mt-3" size="sm" variant="outline">
                    <Plus className="h-4 w-4 mr-2" />
                    Connect
                  </Button>
                </motion.div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </motion.div>
  );
}
