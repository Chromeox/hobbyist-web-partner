'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import SuccessDialog from '@/components/ui/success-dialog';
import {
  Calendar,
  CheckCircle,
  Clock,
  Download,
  AlertTriangle,
  RefreshCw,
  ArrowRight,
  Zap,
  TrendingUp,
  Users,
  Settings,
  ExternalLink,
  Info
} from 'lucide-react';

interface CalendarProvider {
  id: string;
  name: string;
  icon: string;
  description: string;
  status: 'available' | 'connected' | 'pending' | 'disabled';
  features: string[];
  setupTime: string;
  authUrl?: string;
}

interface CalendarImportWidgetProps {
  className?: string;
  onImportComplete?: (provider: string) => void;
  highlightSetup?: boolean;
}

export default function CalendarImportWidget({
  className = '',
  onImportComplete,
  highlightSetup = false
}: CalendarImportWidgetProps) {
  const [importing, setImporting] = useState(false);
  const [importProgress, setImportProgress] = useState(0);
  const [connectedProviders, setConnectedProviders] = useState<Set<string>>(new Set());
  const [showSuccessDialog, setShowSuccessDialog] = useState(false);
  const [successData, setSuccessData] = useState<{
    provider: 'square' | 'google' | 'calendly';
    merchantName?: string;
    locationName?: string;
  } | null>(null);

  // Check URL for successful OAuth callback or errors
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const success = urlParams.get('success');
    const error = urlParams.get('error');
    const message = urlParams.get('message');
    const integrationId = urlParams.get('integration_id');
    const merchantName = urlParams.get('merchant_name');
    const locationName = urlParams.get('location_name');

    if (success === 'square_connected' && integrationId) {
      setConnectedProviders(prev => new Set([...prev, 'square']));

      // Show success dialog with integration data
      setSuccessData({
        provider: 'square',
        merchantName: merchantName || undefined,
        locationName: locationName || undefined
      });
      setShowSuccessDialog(true);

      // Use setTimeout to defer the callback to avoid render-phase state updates
      setTimeout(() => {
        if (onImportComplete) {
          onImportComplete('square');
        }
      }, 0);

      // Clean up URL
      window.history.replaceState({}, '', window.location.pathname);
    } else if (error) {
      // Handle OAuth errors
      let errorMessage = 'Square connection failed';

      switch (error) {
        case 'square_config_missing':
          errorMessage = 'Square OAuth configuration missing. Please check environment variables.';
          break;
        case 'square_auth_failed':
          errorMessage = 'Square authorization failed. Please try again.';
          break;
        case 'square_connection_failed':
          errorMessage = 'Failed to establish Square connection. Please check your Square Developer Dashboard configuration.';
          break;
        default:
          errorMessage = message ? decodeURIComponent(message) : 'Square connection failed';
      }

      console.error('Square OAuth error:', error, message);
      alert(`Square Integration Error: ${errorMessage}`);

      // Clean up URL
      window.history.replaceState({}, '', window.location.pathname);
    }
  }, [onImportComplete]);

  const providers: CalendarProvider[] = [
    {
      id: 'square',
      name: 'Square Appointments',
      icon: '⬜',
      description: 'Import bookings, services, and customer data from Square',
      status: connectedProviders.has('square') ? 'connected' : 'available',
      features: ['Bookings & Appointments', 'Service Catalog', 'Customer Data', 'Payment History'],
      setupTime: '2-3 minutes',
      authUrl: '/api/auth/square'
    },
    {
      id: 'google',
      name: 'Google Calendar',
      icon: '📅',
      description: 'Sync with your Google Calendar events and schedules',
      status: 'available',
      features: ['Calendar Events', 'Recurring Schedules', 'Room Bookings', 'Attendee Lists'],
      setupTime: '1-2 minutes'
    },
    {
      id: 'calendly',
      name: 'Calendly',
      icon: '📆',
      description: 'Import scheduled events and booking data from Calendly',
      status: 'disabled',
      features: ['Scheduled Events', 'Event Types', 'Invitee Data', 'Booking Links'],
      setupTime: '2-3 minutes'
    }
  ];

  const handleConnect = async (provider: CalendarProvider) => {
    if (provider.status === 'connected') return;

    if (provider.authUrl) {
      // Redirect to OAuth flow
      window.location.href = provider.authUrl;
    } else {
      // Demo/placeholder connection
      setImporting(true);
      setImportProgress(0);

      // Simulate import progress
      const interval = setInterval(() => {
        setImportProgress(prev => {
          if (prev >= 100) {
            clearInterval(interval);
            setImporting(false);
            setConnectedProviders(current => new Set([...current, provider.id]));
            if (onImportComplete) {
              onImportComplete(provider.id);
            }
            return 100;
          }
          return prev + 10;
        });
      }, 200);
    }
  };

  const getStatusBadge = (status: CalendarProvider['status']) => {
    switch (status) {
      case 'connected':
        return <Badge className="bg-green-100 text-green-800"><CheckCircle className="h-3 w-3 mr-1" />Connected</Badge>;
      case 'pending':
        return <Badge variant="secondary"><Clock className="h-3 w-3 mr-1" />Syncing</Badge>;
      case 'disabled':
        return <Badge variant="outline" className="opacity-50">Coming Soon</Badge>;
      default:
        return <Badge variant="outline">Available</Badge>;
    }
  };

  const connectedCount = connectedProviders.size;
  const hasConnections = connectedCount > 0;

  return (
    <Card className={`${className} ${highlightSetup ? 'ring-2 ring-purple-500 ring-opacity-50' : ''}`}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <Calendar className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <CardTitle className="flex items-center gap-2">
                Calendar Integration
                {highlightSetup && <Zap className="h-4 w-4 text-orange-500" />}
              </CardTitle>
              <CardDescription>
                Connect your booking systems to generate intelligent insights
              </CardDescription>
            </div>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-purple-600">{connectedCount}</div>
            <div className="text-xs text-gray-500">Connected</div>
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Benefits Banner */}
        {!hasConnections && (
          <Alert className="border-blue-200 bg-blue-50">
            <TrendingUp className="h-4 w-4" />
            <AlertTitle>Unlock Studio Intelligence</AlertTitle>
            <AlertDescription>
              Import your calendar data to get AI-powered recommendations that increase revenue by an average of 20%.
            </AlertDescription>
          </Alert>
        )}

        {/* Import Progress */}
        {importing && (
          <Alert>
            <RefreshCw className="h-4 w-4 animate-spin" />
            <AlertTitle>Importing Calendar Data</AlertTitle>
            <AlertDescription>
              <div className="mt-2">
                <div className="flex justify-between text-sm mb-1">
                  <span>Progress</span>
                  <span>{importProgress}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${importProgress}%` }}
                  />
                </div>
              </div>
            </AlertDescription>
          </Alert>
        )}

        {/* Success Message */}
        {hasConnections && (
          <Alert className="border-green-200 bg-green-50">
            <CheckCircle className="h-4 w-4" />
            <AlertTitle>Integration Active</AlertTitle>
            <AlertDescription>
              Your calendar data is being analyzed. Check the insights below for optimization recommendations.
            </AlertDescription>
          </Alert>
        )}

        {/* Square Setup Instructions */}
        {!connectedProviders.has('square') && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-start">
              <Info className="h-5 w-5 text-blue-600 mr-3 mt-0.5" />
              <div>
                <h3 className="text-sm font-medium text-blue-900">Square OAuth Setup Required</h3>
                <p className="text-sm text-blue-700 mt-1">
                  To connect Square Appointments, configure your Square Developer Dashboard:
                </p>
                <ol className="text-xs text-blue-600 mt-2 list-decimal list-inside space-y-1">
                  <li>Visit <a href="https://developer.squareup.com/apps" target="_blank" rel="noopener noreferrer" className="underline">Square Developer Dashboard</a></li>
                  <li>Select your application (ID: <code className="bg-blue-100 px-1">sandbox-sq0idb-PBgKEnc-hf0WJmkgUUFvew</code>)</li>
                  <li>Add Redirect URI: <code className="bg-blue-100 px-1">http://localhost:3002/api/auth/square/callback</code></li>
                  <li>Ensure application is using "Code Flow" for server-side applications</li>
                  <li>Save the configuration and try connecting again</li>
                </ol>
              </div>
            </div>
          </div>
        )}

        {/* Provider Cards */}
        <div className="space-y-3">
          {providers.map((provider) => (
            <div
              key={provider.id}
              className={`border rounded-lg p-4 transition-all ${
                provider.status === 'connected'
                  ? 'border-green-200 bg-green-50'
                  : provider.status === 'disabled'
                  ? 'border-gray-200 bg-gray-50 opacity-60'
                  : 'border-gray-200 hover:border-blue-300 hover:shadow-sm'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="text-2xl">{provider.icon}</div>
                  <div>
                    <div className="font-medium text-gray-900">{provider.name}</div>
                    <div className="text-sm text-gray-600">{provider.description}</div>
                  </div>
                </div>
                {getStatusBadge(provider.status)}
              </div>

              {/* Features */}
              <div className="mb-3">
                <div className="text-xs text-gray-500 mb-2">Imports:</div>
                <div className="flex flex-wrap gap-1">
                  {provider.features.map((feature, index) => (
                    <Badge key={index} variant="outline" className="text-xs">
                      {feature}
                    </Badge>
                  ))}
                </div>
              </div>

              {/* Action Button */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <Clock className="h-3 w-3" />
                  {provider.setupTime}
                </div>

                {provider.status === 'connected' ? (
                  <Button variant="outline" size="sm" disabled>
                    <CheckCircle className="h-4 w-4 mr-2" />
                    Connected
                  </Button>
                ) : provider.status === 'disabled' ? (
                  <Button variant="outline" size="sm" disabled>
                    Coming Soon
                  </Button>
                ) : (
                  <div className="flex gap-2">
                    <div className="flex flex-col gap-1">
                      <Button
                        onClick={() => handleConnect(provider)}
                        disabled={importing}
                        size="sm"
                        className="bg-purple-600 hover:bg-purple-700"
                      >
                        <ExternalLink className="h-4 w-4 mr-2" />
                        Connect
                        <ArrowRight className="h-4 w-4 ml-2" />
                      </Button>
                      {provider.id === 'square' && (
                        <div className="text-xs text-gray-500 mt-1">
                          📋 Redirect URI: <code className="bg-gray-100 px-1">http://localhost:3002/api/auth/square/callback</code>
                        </div>
                      )}
                    </div>
                    {provider.id === 'square' && (
                      <Button
                        onClick={() => {
                          setConnectedProviders(prev => new Set([...prev, 'square']));
                          setTimeout(() => {
                            if (onImportComplete) {
                              onImportComplete('square');
                            }
                          }, 100);
                        }}
                        variant="outline"
                        size="sm"
                        className="text-xs"
                      >
                        Demo Connect
                      </Button>
                    )}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Next Steps */}
        {hasConnections && (
          <div className="bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center flex-shrink-0">
                <Users className="h-4 w-4 text-purple-600" />
              </div>
              <div>
                <div className="font-medium text-gray-900 mb-1">What's Next?</div>
                <div className="text-sm text-gray-600 mb-2">
                  Your calendar data is being analyzed to generate intelligent recommendations.
                </div>
                <div className="text-xs text-gray-500">
                  • Time slot optimization • Room efficiency • Instructor scheduling • Revenue insights
                </div>
              </div>
            </div>
          </div>
        )}
      </CardContent>

      {/* Success Dialog */}
      {successData && (
        <SuccessDialog
          isOpen={showSuccessDialog}
          onClose={() => {
            setShowSuccessDialog(false);
            setSuccessData(null);
          }}
          title="Integration Successful!"
          message={`Your ${successData.provider === 'square' ? 'Square Appointments' : successData.provider} account has been successfully connected. Your calendar data is now being synchronized and analyzed for intelligent insights.`}
          provider={successData.provider}
          integrationData={{
            merchantName: successData.merchantName,
            locationName: successData.locationName,
            servicesCount: 5, // Simulated data
            appointmentsCount: 23 // Simulated data
          }}
        />
      )}
    </Card>
  );
}