'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import {
  Brain,
  TrendingUp,
  Clock,
  Users,
  MapPin,
  ChevronRight,
  Lightbulb,
  DollarSign,
  Zap
} from 'lucide-react';
import Link from 'next/link';

import { studioAnalyticsService } from '@/lib/services/studio-analytics';
import type { StudioIntelligenceInsights } from '@/types/studio-intelligence';
import type { ImportedEvent } from '@/types/calendar-integration';

interface StudioIntelligenceSummaryProps {
  studioId: string;
  className?: string;
}

export default function StudioIntelligenceSummary({
  studioId,
  className = ''
}: StudioIntelligenceSummaryProps) {
  const [insights, setInsights] = useState<StudioIntelligenceInsights | null>(null);
  const [loading, setLoading] = useState(true);

  // Mock data for development - replace with actual API call
  const [importedEvents] = useState<ImportedEvent[]>([
    {
      id: '1',
      integration_id: 'google-1',
      external_id: 'cal-event-1',
      provider: 'google',
      studio_id: studioId,
      title: 'Thursday Evening Pottery',
      description: 'Popular pottery wheel class',
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
      current_participants: 8,
      price: 65,
      material_fee: 15,
      migration_status: 'imported',
      raw_data: {},
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    },
    {
      id: '2',
      integration_id: 'google-1',
      external_id: 'cal-event-2',
      provider: 'google',
      studio_id: studioId,
      title: 'Monday Painting Workshop',
      description: 'Watercolor basics for beginners',
      start_time: '2024-01-16T14:00:00Z',
      end_time: '2024-01-16T16:00:00Z',
      all_day: false,
      instructor_name: 'Michael Chen',
      instructor_email: 'michael@studio.com',
      location: 'Studio B',
      room: 'Studio B',
      category: 'painting',
      skill_level: 'beginner',
      max_participants: 12,
      current_participants: 5,
      price: 55,
      material_fee: 10,
      migration_status: 'imported',
      raw_data: {},
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    }
  ]);

  useEffect(() => {
    loadInsights();
  }, [studioId]);

  const loadInsights = async () => {
    try {
      setLoading(true);
      const result = await studioAnalyticsService.generateStudioInsights(importedEvents, studioId);
      setInsights(result);
    } catch (error) {
      console.error('Failed to load insights:', error);
      // Set demo insights even if the service fails
      setInsights({
        weeklyRevenuePotential: 0,
        topPriorityAction: "Import calendar data to generate insights",
        timeSlots: [],
        roomEfficiency: [],
        instructorOptimization: [],
        capacityAdjustments: []
      });
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  const getTopRecommendation = () => {
    if (!insights) return null;

    // Find the recommendation with highest impact
    const opportunities = [
      ...insights.timeSlots.map(ts => ({
        type: 'time_slot',
        title: `Optimize ${ts.day_of_week} ${ts.hour}:00`,
        impact: ts.success_rate,
        description: ts.recommended_action
      })),
      ...insights.roomEfficiency.map(room => ({
        type: 'room',
        title: `Improve ${room.room_name} utilization`,
        impact: room.potential_revenue_increase / 1000, // Normalize to 0-1 scale
        description: `${(room.utilization_rate * 100).toFixed(0)}% utilized`
      })),
      ...insights.instructorOptimization.map(inst => ({
        type: 'instructor',
        title: `Expand ${inst.instructor_name}'s schedule`,
        impact: inst.potential_revenue_increase / 1000,
        description: `+${inst.suggested_additional_hours} hours potential`
      }))
    ];

    return opportunities.sort((a, b) => b.impact - a.impact)[0] || null;
  };

  const getRecommendationIcon = (type: string) => {
    switch (type) {
      case 'time_slot': return Clock;
      case 'room': return MapPin;
      case 'instructor': return Users;
      default: return Lightbulb;
    }
  };

  if (loading) {
    return (
      <Card className={className}>
        <CardContent className="flex items-center justify-center p-8">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600 mr-2" />
          <span className="text-gray-600">Analyzing studio data...</span>
        </CardContent>
      </Card>
    );
  }

  if (!insights) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Brain className="h-5 w-5 text-blue-600" />
            Studio Intelligence
          </CardTitle>
          <CardDescription>
            Import calendar data to generate smart recommendations
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Link href="/dashboard/intelligence">
            <Button className="w-full">
              Get Started <ChevronRight className="h-4 w-4 ml-2" />
            </Button>
          </Link>
        </CardContent>
      </Card>
    );
  }

  const topRecommendation = getTopRecommendation();
  const totalOpportunities = insights.timeSlots.length + insights.roomEfficiency.length + insights.instructorOptimization.length;

  return (
    <Card className={`hover:shadow-lg transition-all duration-300 ${className}`}>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-lg">
            <Brain className="h-5 w-5 text-blue-600" />
            Studio Intelligence
          </CardTitle>
          <Badge variant="secondary" className="bg-blue-100 text-blue-800">
            {totalOpportunities} insights
          </Badge>
        </div>
        <CardDescription>
          AI-powered recommendations to optimize your studio
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Revenue Potential */}
        <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
          <div className="flex items-center gap-2">
            <DollarSign className="h-4 w-4 text-green-600" />
            <span className="text-sm font-medium text-green-800">Revenue Potential</span>
          </div>
          <div className="text-lg font-bold text-green-600">
            {formatCurrency(insights.weeklyRevenuePotential)}/week
          </div>
        </div>

        {/* Top Priority Action */}
        {insights.topPriorityAction && (
          <div className="p-3 bg-orange-50 border border-orange-200 rounded-lg">
            <div className="flex items-start gap-2">
              <Zap className="h-4 w-4 text-orange-600 mt-0.5" />
              <div>
                <div className="text-sm font-medium text-orange-800">Priority Action</div>
                <div className="text-sm text-orange-700 mt-1">
                  {insights.topPriorityAction}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Top Recommendation */}
        {topRecommendation && (
          <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-start gap-2">
              {React.createElement(getRecommendationIcon(topRecommendation.type), {
                className: "h-4 w-4 text-blue-600 mt-0.5"
              })}
              <div className="flex-1">
                <div className="text-sm font-medium text-blue-800">
                  {topRecommendation.title}
                </div>
                <div className="text-sm text-blue-700 mt-1">
                  {topRecommendation.description}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Quick Stats Grid */}
        <div className="grid grid-cols-3 gap-3 pt-2">
          <div className="text-center">
            <div className="text-lg font-bold text-gray-900">
              {insights.timeSlots.length}
            </div>
            <div className="text-xs text-gray-600">Time Slots</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-bold text-gray-900">
              {insights.roomEfficiency.length}
            </div>
            <div className="text-xs text-gray-600">Room Ops</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-bold text-gray-900">
              {insights.instructorOptimization.length}
            </div>
            <div className="text-xs text-gray-600">Instructor</div>
          </div>
        </div>

        {/* Call to Action */}
        <Link href="/dashboard/intelligence" className="block">
          <Button className="w-full" variant="outline">
            View Full Analysis <ChevronRight className="h-4 w-4 ml-2" />
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}
