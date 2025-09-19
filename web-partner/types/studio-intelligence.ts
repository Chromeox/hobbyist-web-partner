import {
  TimeSlotRecommendation,
  RoomEfficiencyData,
  InstructorOptimization,
  CapacityRecommendation,
  StudioIntelligenceInsights
} from '@/lib/services/studio-analytics';

// Re-export for external consumption
export type {
  TimeSlotRecommendation,
  RoomEfficiencyData,
  InstructorOptimization,
  CapacityRecommendation,
  StudioIntelligenceInsights
};

// Dashboard UI specific types
export interface RecommendationCard {
  id: string;
  type: 'time_slot' | 'room_efficiency' | 'instructor' | 'capacity';
  title: string;
  description: string;
  impact: {
    revenue_potential: number;
    confidence: 'high' | 'medium' | 'low';
    timeframe: 'immediate' | 'short_term' | 'long_term';
  };
  action: {
    label: string;
    onClick: () => void;
    disabled?: boolean;
  };
  metrics: {
    primary: { label: string; value: string; trend?: 'up' | 'down' | 'stable' };
    secondary?: { label: string; value: string };
  };
}

export interface DashboardFilters {
  timeRange: '1_month' | '3_months' | '6_months';
  categories: string[];
  rooms: string[];
  instructors: string[];
  priorityLevel: 'all' | 'high' | 'medium' | 'low';
}

export interface PerformanceMetric {
  label: string;
  current: number;
  target: number;
  unit: string;
  trend: 'improving' | 'declining' | 'stable';
  color: 'green' | 'yellow' | 'red' | 'blue';
}

export interface TimeSlotHeatmapData {
  day: string;
  hour: number;
  value: number; // Success rate or utilization
  category?: string;
  count: number;
}

export interface ActionableInsight {
  insight_id: string;
  type: 'optimization' | 'opportunity' | 'warning' | 'success';
  priority: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  recommendation: string;
  effort_level: 'low' | 'medium' | 'high';
  expected_outcome: string;
  data_confidence: number; // 0-1
  created_at: string;
  status: 'new' | 'acknowledged' | 'in_progress' | 'completed' | 'dismissed';
}

// Component Props
export interface StudioIntelligenceDashboardProps {
  studioId: string;
  className?: string;
  onActionClick?: (actionType: string, data: any) => void;
  refreshInterval?: number; // seconds
}

export interface RecommendationCardProps {
  recommendation: RecommendationCard;
  compact?: boolean;
  showActions?: boolean;
}

export interface TimeSlotHeatmapProps {
  data: TimeSlotHeatmapData[];
  height?: number;
  width?: number;
  colorScheme?: 'blue' | 'green' | 'purple';
}

export interface MetricsOverviewProps {
  metrics: PerformanceMetric[];
  layout: 'grid' | 'horizontal';
}

// Analytics Configuration
export interface AnalyticsConfig {
  min_data_points: number; // Minimum events needed for reliable insights
  confidence_threshold: number; // Minimum confidence for showing recommendations
  revenue_threshold: number; // Minimum revenue impact to show opportunity
  date_range_days: number; // How far back to analyze
  update_frequency_hours: number; // How often to refresh analytics
}

// Default configurations
export const DEFAULT_ANALYTICS_CONFIG: AnalyticsConfig = {
  min_data_points: 10,
  confidence_threshold: 0.7,
  revenue_threshold: 100,
  date_range_days: 90,
  update_frequency_hours: 24
};

export const DEFAULT_DASHBOARD_FILTERS: DashboardFilters = {
  timeRange: '3_months',
  categories: [],
  rooms: [],
  instructors: [],
  priorityLevel: 'all'
};

// Success Messages for Actions
export const ACTION_SUCCESS_MESSAGES = {
  time_slot_added: 'New time slot added to workshop scheduler',
  capacity_increased: 'Class capacity updated successfully',
  instructor_schedule_updated: 'Instructor schedule optimized',
  room_optimization_applied: 'Room utilization improvement scheduled'
} as const;

// Helper function types
export type InsightGenerator = (data: any[]) => ActionableInsight[];
export type RecommendationFilter = (insight: ActionableInsight) => boolean;
export type MetricCalculator = (events: any[]) => PerformanceMetric[];

// Error types
export interface AnalyticsError {
  code: string;
  message: string;
  details?: Record<string, any>;
}

export const ANALYTICS_ERRORS = {
  INSUFFICIENT_DATA: 'insufficient_data',
  INVALID_DATE_RANGE: 'invalid_date_range',
  MISSING_CALENDAR_DATA: 'missing_calendar_data',
  CALCULATION_ERROR: 'calculation_error'
} as const;