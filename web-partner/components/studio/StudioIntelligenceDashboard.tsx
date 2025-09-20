'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import {
  TrendingUp,
  TrendingDown,
  Clock,
  Users,
  MapPin,
  DollarSign,
  Target,
  AlertTriangle,
  CheckCircle,
  Calendar,
  BarChart3,
  Lightbulb,
  ArrowRight,
  RefreshCw
} from 'lucide-react';

import { studioAnalyticsService } from '@/lib/services/studio-analytics';
import type {
  StudioIntelligenceInsights,
  RecommendationCard,
  PerformanceMetric,
  StudioIntelligenceDashboardProps
} from '@/types/studio-intelligence';
import type { ImportedEvent } from '@/types/calendar-integration';

export default function StudioIntelligenceDashboard({
  studioId,
  className = '',
  onActionClick,
  refreshInterval = 3600
}: StudioIntelligenceDashboardProps) {
  const [insights, setInsights] = useState<StudioIntelligenceInsights | null>(null);
  const [loading, setLoading] = useState(false); // Start with false to show demo data immediately
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(new Date()); // Set initial last updated

  // Enhanced mock data for development - replace with actual API call
  const [importedEvents] = useState<ImportedEvent[]>([
    {
      id: '1',
      integration_id: 'square-1',
      external_id: 'sq-event-1',
      provider: 'square',
      studio_id: studioId,
      title: 'Beginner Pottery Wheel',
      description: 'Introduction to pottery wheel throwing for newcomers',
      start_time: '2024-01-15T18:00:00Z',
      end_time: '2024-01-15T20:00:00Z',
      all_day: false,
      instructor_name: 'Sarah Johnson',
      instructor_email: 'sarah@studio.com',
      location: 'Studio A',
      room: 'Studio A',
      category: 'pottery',
      skill_level: 'beginner',
      max_participants: 8,
      current_participants: 7,
      price: 65,
      material_fee: 15,
      migration_status: 'imported',
      raw_data: {},
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    },
    {
      id: '2',
      integration_id: 'square-1',
      external_id: 'sq-event-2',
      provider: 'square',
      studio_id: studioId,
      title: 'Advanced Glazing Workshop',
      description: 'Learn advanced glazing techniques and color mixing',
      start_time: '2024-01-16T14:00:00Z',
      end_time: '2024-01-16T17:00:00Z',
      all_day: false,
      instructor_name: 'Michael Chen',
      instructor_email: 'michael@studio.com',
      location: 'Studio B',
      room: 'Studio B',
      category: 'pottery',
      skill_level: 'advanced',
      max_participants: 6,
      current_participants: 6,
      price: 95,
      material_fee: 25,
      migration_status: 'imported',
      raw_data: {},
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    },
    {
      id: '3',
      integration_id: 'square-1',
      external_id: 'sq-event-3',
      provider: 'square',
      studio_id: studioId,
      title: 'Watercolor Basics',
      description: 'Introduction to watercolor painting techniques',
      start_time: '2024-01-17T10:00:00Z',
      end_time: '2024-01-17T12:00:00Z',
      all_day: false,
      instructor_name: 'Emma Rodriguez',
      instructor_email: 'emma@studio.com',
      location: 'Art Room',
      room: 'Art Room',
      category: 'painting',
      skill_level: 'beginner',
      max_participants: 12,
      current_participants: 10,
      price: 45,
      material_fee: 10,
      migration_status: 'imported',
      raw_data: {},
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    }
  ]);

  useEffect(() => {
    loadInsights();
    const interval = setInterval(loadInsights, refreshInterval * 1000);
    return () => clearInterval(interval);
  }, [studioId, refreshInterval]);

  const loadInsights = async () => {
    try {
      setLoading(true);
      setError(null);

      // In production, this would fetch from your API
      // const events = await fetchImportedEvents(studioId);
      const events = importedEvents;

      const result = await studioAnalyticsService.generateStudioInsights(events, studioId);
      setInsights(result);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load insights');
    } finally {
      setLoading(false);
    }
  };

  const handleAction = (actionType: string, data: any) => {
    if (onActionClick) {
      onActionClick(actionType, data);
    }
    // Here you would typically update the schedule, send API requests, etc.
    console.log('Action:', actionType, data);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'text-green-600';
    if (confidence >= 0.6) return 'text-yellow-600';
    return 'text-orange-600';
  };

  const getConfidenceBadge = (confidence: number) => {
    if (confidence >= 0.8) return <Badge variant="default" className="bg-green-100 text-green-800">High Confidence</Badge>;
    if (confidence >= 0.6) return <Badge variant="secondary">Medium Confidence</Badge>;
    return <Badge variant="outline">Low Confidence</Badge>;
  };

  if (loading) {
    return (
      <Card className={className}>
        <CardContent className="flex items-center justify-center p-8">
          <RefreshCw className="h-6 w-6 animate-spin mr-2" />
          <span>Analyzing studio data...</span>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className={className}>
        <CardContent className="p-6">
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertTitle>Error Loading Insights</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
          <Button onClick={loadInsights} className="mt-4">
            <RefreshCw className="h-4 w-4 mr-2" />
            Retry
          </Button>
        </CardContent>
      </Card>
    );
  }

  if (!insights) {
    return (
      <Card className={className}>
        <CardContent className="p-6">
          <Alert>
            <Lightbulb className="h-4 w-4" />
            <AlertTitle>No Data Available</AlertTitle>
            <AlertDescription>
              Import calendar data to generate intelligent recommendations for your studio.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header with key metrics */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-5 w-5" />
                Studio Intelligence Dashboard
              </CardTitle>
              <CardDescription>
                Smart recommendations based on your calendar data
                {lastUpdated && (
                  <span className="ml-2 text-xs">
                    Last updated: {lastUpdated.toLocaleTimeString()}
                  </span>
                )}
              </CardDescription>
            </div>
            <Button onClick={loadInsights} variant="outline" size="sm">
              <RefreshCw className="h-4 w-4 mr-2" />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {formatCurrency(insights.weeklyRevenuePotential)}
              </div>
              <div className="text-sm text-muted-foreground">Weekly Revenue Potential</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {insights.timeSlots.length + insights.roomEfficiency.length}
              </div>
              <div className="text-sm text-muted-foreground">Active Opportunities</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">
                {insights.instructorOptimization.length}
              </div>
              <div className="text-sm text-muted-foreground">Instructor Optimizations</div>
            </div>
          </div>

          {insights.topPriorityAction && (
            <Alert className="border-orange-200 bg-orange-50">
              <Target className="h-4 w-4" />
              <AlertTitle>Top Priority Action</AlertTitle>
              <AlertDescription className="mt-2">
                {insights.topPriorityAction}
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Recommendations Tabs */}
      <Tabs defaultValue="time-slots" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="time-slots" className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            Time Slots
          </TabsTrigger>
          <TabsTrigger value="rooms" className="flex items-center gap-2">
            <MapPin className="h-4 w-4" />
            Rooms
          </TabsTrigger>
          <TabsTrigger value="instructors" className="flex items-center gap-2">
            <Users className="h-4 w-4" />
            Instructors
          </TabsTrigger>
          <TabsTrigger value="capacity" className="flex items-center gap-2">
            <TrendingUp className="h-4 w-4" />
            Capacity
          </TabsTrigger>
        </TabsList>

        <TabsContent value="time-slots" className="space-y-4 mt-6">
          <div className="grid gap-4">
            {insights.timeSlots.length > 0 ? (
              insights.timeSlots.map((slot, index) => (
                <Card key={index} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <h3 className="font-semibold">
                          {slot.day_of_week} at {slot.hour}:00
                        </h3>
                        <p className="text-sm text-muted-foreground">
                          {slot.category_suggestion && `Best for: ${slot.category_suggestion}`}
                        </p>
                      </div>
                      {getConfidenceBadge(slot.confidence_score)}
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-4">
                      <div>
                        <div className="text-sm text-muted-foreground">Success Rate</div>
                        <div className="text-xl font-bold text-green-600">
                          {(slot.success_rate * 100).toFixed(1)}%
                        </div>
                        <Progress value={slot.success_rate * 100} className="mt-1" />
                      </div>
                      <div>
                        <div className="text-sm text-muted-foreground">Avg. Capacity Used</div>
                        <div className="text-xl font-bold">
                          {slot.avg_capacity_used.toFixed(1)} students
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between">
                      <p className="text-sm">{slot.recommended_action}</p>
                      <Button
                        onClick={() => handleAction('optimize_time_slot', slot)}
                        size="sm"
                        className="ml-4"
                      >
                        Apply <ArrowRight className="h-4 w-4 ml-1" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card>
                <CardContent className="p-6 text-center">
                  <Calendar className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    No time slot recommendations available. Import more calendar data for insights.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        <TabsContent value="rooms" className="space-y-4 mt-6">
          <div className="grid gap-4">
            {insights.roomEfficiency.length > 0 ? (
              insights.roomEfficiency.map((room, index) => (
                <Card key={index} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="font-semibold">{room.room_name}</h3>
                      <Badge variant={room.utilization_rate > 0.7 ? "default" : "secondary"}>
                        {(room.utilization_rate * 100).toFixed(1)}% utilized
                      </Badge>
                    </div>

                    <div className="mb-4">
                      <div className="text-sm text-muted-foreground mb-2">Room Utilization</div>
                      <Progress value={room.utilization_rate * 100} />
                    </div>

                    <div className="space-y-2 mb-4">
                      <div className="text-sm font-medium">Recommended Category: {room.recommended_category}</div>
                      <div className="text-sm text-green-600">
                        Potential Revenue: {formatCurrency(room.potential_revenue_increase)}/week
                      </div>
                    </div>

                    {room.underutilized_slots.length > 0 && (
                      <div className="mb-4">
                        <div className="text-sm font-medium mb-2">Available Time Slots:</div>
                        <div className="flex flex-wrap gap-2">
                          {room.underutilized_slots.slice(0, 3).map((slot, i) => (
                            <Badge key={i} variant="outline">
                              {slot.day} {slot.hour}:00
                            </Badge>
                          ))}
                        </div>
                      </div>
                    )}

                    <Button
                      onClick={() => handleAction('optimize_room', room)}
                      className="w-full"
                      size="sm"
                    >
                      Optimize Room Usage <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card>
                <CardContent className="p-6 text-center">
                  <MapPin className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    No room efficiency recommendations available.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        <TabsContent value="instructors" className="space-y-4 mt-6">
          <div className="grid gap-4">
            {insights.instructorOptimization.length > 0 ? (
              insights.instructorOptimization.map((instructor, index) => (
                <Card key={index} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="font-semibold">{instructor.instructor_name}</h3>
                      <Badge variant="default">
                        {(instructor.avg_capacity_rate * 100).toFixed(1)}% capacity rate
                      </Badge>
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-4">
                      <div>
                        <div className="text-sm text-muted-foreground">Current Hours/Week</div>
                        <div className="text-xl font-bold">{instructor.current_weekly_hours}</div>
                      </div>
                      <div>
                        <div className="text-sm text-muted-foreground">Suggested Additional</div>
                        <div className="text-xl font-bold text-green-600">
                          +{instructor.suggested_additional_hours} hours
                        </div>
                      </div>
                    </div>

                    <div className="mb-4">
                      <div className="text-sm text-green-600 font-medium">
                        Revenue Potential: {formatCurrency(instructor.potential_revenue_increase)}/week
                      </div>
                    </div>

                    {instructor.optimal_time_slots.length > 0 && (
                      <div className="mb-4">
                        <div className="text-sm font-medium mb-2">Optimal New Time Slots:</div>
                        <div className="flex flex-wrap gap-2">
                          {instructor.optimal_time_slots.map((slot, i) => (
                            <Badge key={i} variant="outline">
                              {slot.day} {slot.hour}:00 ({slot.category})
                            </Badge>
                          ))}
                        </div>
                      </div>
                    )}

                    <Button
                      onClick={() => handleAction('optimize_instructor', instructor)}
                      className="w-full"
                      size="sm"
                    >
                      Add Classes <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card>
                <CardContent className="p-6 text-center">
                  <Users className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    All instructors are optimally scheduled.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        <TabsContent value="capacity" className="space-y-4 mt-6">
          <div className="grid gap-4">
            {insights.capacityAdjustments.length > 0 ? (
              insights.capacityAdjustments.map((capacity, index) => (
                <Card key={index} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="font-semibold capitalize">{capacity.category} Classes</h3>
                      {getConfidenceBadge(capacity.confidence_level === 'high' ? 0.9 : capacity.confidence_level === 'medium' ? 0.7 : 0.5)}
                    </div>

                    <div className="grid grid-cols-3 gap-4 mb-4">
                      <div>
                        <div className="text-sm text-muted-foreground">Current Size</div>
                        <div className="text-xl font-bold">{capacity.current_avg_size}</div>
                      </div>
                      <div>
                        <div className="text-sm text-muted-foreground">Recommended</div>
                        <div className="text-xl font-bold text-blue-600">
                          {capacity.recommended_size}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm text-muted-foreground">Revenue Impact</div>
                        <div className={`text-xl font-bold ${capacity.revenue_impact > 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {capacity.revenue_impact > 0 ? '+' : ''}{formatCurrency(capacity.revenue_impact)}
                        </div>
                      </div>
                    </div>

                    {capacity.waitlist_indicator > 0 && (
                      <Alert className="mb-4">
                        <AlertTriangle className="h-4 w-4" />
                        <AlertDescription>
                          {(capacity.waitlist_indicator * 100).toFixed(0)}% of classes are overbooked, indicating high demand
                        </AlertDescription>
                      </Alert>
                    )}

                    <Button
                      onClick={() => handleAction('adjust_capacity', capacity)}
                      className="w-full"
                      size="sm"
                    >
                      Adjust Capacity <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card>
                <CardContent className="p-6 text-center">
                  <TrendingUp className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    Current class capacities are well-optimized.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}