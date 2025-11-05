import { ImportedEvent, WorkshopAnalytics } from '@/types/calendar-integration';

export interface TimeSlotRecommendation {
  day_of_week: string;
  hour: number;
  success_rate: number;
  avg_capacity_used: number;
  recommended_action: string;
  category_suggestion?: string;
  confidence_score: number;
}

export interface RoomEfficiencyData {
  room_name: string;
  utilization_rate: number;
  underutilized_slots: Array<{
    day: string;
    hour: number;
    opportunity_score: number;
  }>;
  recommended_category: string;
  potential_revenue_increase: number;
}

export interface InstructorOptimization {
  instructor_name: string;
  current_weekly_hours: number;
  avg_capacity_rate: number;
  suggested_additional_hours: number;
  optimal_time_slots: Array<{
    day: string;
    hour: number;
    category: string;
  }>;
  potential_revenue_increase: number;
}

export interface CapacityRecommendation {
  category: string;
  current_avg_size: number;
  recommended_size: number;
  waitlist_indicator: number;
  revenue_impact: number;
  confidence_level: 'high' | 'medium' | 'low';
}

export interface StudioIntelligenceInsights {
  timeSlots: TimeSlotRecommendation[];
  roomEfficiency: RoomEfficiencyData[];
  instructorOptimization: InstructorOptimization[];
  capacityAdjustments: CapacityRecommendation[];
  weeklyRevenuePotential: number;
  topPriorityAction: string;
}

export class StudioAnalyticsService {

  /**
   * Main method to generate comprehensive studio intelligence insights
   */
  async generateStudioInsights(
    importedEvents: ImportedEvent[],
    studioId: string
  ): Promise<StudioIntelligenceInsights> {

    // Filter events for the studio and recent data (last 3 months)
    const recentEvents = this.filterRecentEvents(importedEvents, studioId);

    if (recentEvents.length === 0) {
      return this.getEmptyInsights();
    }

    const timeSlots = this.analyzeTimeSlotSuccess(recentEvents);
    const roomEfficiency = this.analyzeRoomEfficiency(recentEvents);
    const instructorOptimization = this.analyzeInstructorCapacity(recentEvents);
    const capacityAdjustments = this.analyzeCapacityOptimization(recentEvents);

    const weeklyRevenuePotential = this.calculateRevenuePotential(
      timeSlots, roomEfficiency, instructorOptimization, capacityAdjustments
    );

    const topPriorityAction = this.determineTopPriorityAction(
      timeSlots, roomEfficiency, instructorOptimization, capacityAdjustments
    );

    return {
      timeSlots,
      roomEfficiency,
      instructorOptimization,
      capacityAdjustments,
      weeklyRevenuePotential,
      topPriorityAction
    };
  }

  /**
   * Analyze time slot success patterns
   */
  private analyzeTimeSlotSuccess(events: ImportedEvent[]): TimeSlotRecommendation[] {
    const timeSlotData = new Map<string, {
      total_classes: number;
      total_capacity: number;
      total_booked: number;
      categories: Map<string, number>;
    }>();

    // Process events to build time slot statistics
    events.forEach(event => {
      const dayHour = this.getDayHourKey(event.start_time);
      const existing = timeSlotData.get(dayHour) || {
        total_classes: 0,
        total_capacity: 0,
        total_booked: 0,
        categories: new Map()
      };

      existing.total_classes += 1;
      existing.total_capacity += event.max_participants || 0;
      existing.total_booked += event.current_participants;

      if (event.category) {
        existing.categories.set(
          event.category,
          (existing.categories.get(event.category) || 0) + 1
        );
      }

      timeSlotData.set(dayHour, existing);
    });

    // Convert to recommendations
    const recommendations: TimeSlotRecommendation[] = [];

    timeSlotData.forEach((data, dayHour) => {
      const [day, hour] = dayHour.split('-');
      const success_rate = data.total_capacity > 0 ? data.total_booked / data.total_capacity : 0;
      const avg_capacity_used = data.total_classes > 0 ? data.total_booked / data.total_classes : 0;

      // Find most popular category for this time slot
      let topCategory = '';
      let maxCount = 0;
      data.categories.forEach((count, category) => {
        if (count > maxCount) {
          maxCount = count;
          topCategory = category;
        }
      });

      let recommended_action = '';
      let confidence_score = 0.5;

      if (success_rate > 0.85 && data.total_classes >= 3) {
        recommended_action = `High-success time slot: Add more ${topCategory} classes`;
        confidence_score = 0.9;
      } else if (success_rate > 0.7 && avg_capacity_used > 8) {
        recommended_action = `Good performance: Consider increasing capacity`;
        confidence_score = 0.75;
      } else if (success_rate < 0.5 && data.total_classes >= 2) {
        recommended_action = `Low performance: Review pricing or class type`;
        confidence_score = 0.8;
      } else {
        recommended_action = `Stable time slot: Monitor trends`;
        confidence_score = 0.6;
      }

      recommendations.push({
        day_of_week: day,
        hour: parseInt(hour),
        success_rate,
        avg_capacity_used,
        recommended_action,
        category_suggestion: topCategory,
        confidence_score
      });
    });

    return recommendations.sort((a, b) => b.success_rate - a.success_rate).slice(0, 5);
  }

  /**
   * Analyze room utilization efficiency
   */
  private analyzeRoomEfficiency(events: ImportedEvent[]): RoomEfficiencyData[] {
    const roomData = new Map<string, {
      total_hours: number;
      total_possible_hours: number;
      time_slots: Set<string>;
      categories: Map<string, number>;
      revenue: number;
    }>();

    const HOURS_PER_WEEK = 12 * 7; // Assuming 12 operating hours per day

    events.forEach(event => {
      const room = event.room || 'Main Studio';
      const existing = roomData.get(room) || {
        total_hours: 0,
        total_possible_hours: HOURS_PER_WEEK,
        time_slots: new Set(),
        categories: new Map(),
        revenue: 0
      };

      const duration = this.getEventDurationHours(event.start_time, event.end_time);
      existing.total_hours += duration;
      existing.time_slots.add(this.getDayHourKey(event.start_time));

      if (event.category) {
        existing.categories.set(
          event.category,
          (existing.categories.get(event.category) || 0) + 1
        );
      }

      existing.revenue += (event.price || 0) * event.current_participants;
      roomData.set(room, existing);
    });

    const roomEfficiency: RoomEfficiencyData[] = [];

    roomData.forEach((data, roomName) => {
      const utilization_rate = data.total_hours / data.total_possible_hours;

      // Find underutilized time slots (simplified)
      const underutilized_slots = this.findUnderutilizedSlots(data.time_slots);

      // Recommend category based on what works well in other rooms
      const recommended_category = this.getMostSuccessfulCategory(events);

      // Calculate potential revenue increase
      const potential_revenue_increase = underutilized_slots.length * 200; // Estimated $200 per new class

      roomEfficiency.push({
        room_name: roomName,
        utilization_rate,
        underutilized_slots,
        recommended_category,
        potential_revenue_increase
      });
    });

    return roomEfficiency.sort((a, b) => a.utilization_rate - b.utilization_rate);
  }

  /**
   * Analyze instructor capacity and opportunities
   */
  private analyzeInstructorCapacity(events: ImportedEvent[]): InstructorOptimization[] {
    const instructorData = new Map<string, {
      weekly_hours: number;
      total_capacity: number;
      total_booked: number;
      classes_taught: number;
      time_patterns: Set<string>;
      categories: Set<string>;
      revenue: number;
    }>();

    events.forEach(event => {
      const instructor = event.instructor_name || 'Staff';
      const existing = instructorData.get(instructor) || {
        weekly_hours: 0,
        total_capacity: 0,
        total_booked: 0,
        classes_taught: 0,
        time_patterns: new Set(),
        categories: new Set(),
        revenue: 0
      };

      const duration = this.getEventDurationHours(event.start_time, event.end_time);
      existing.weekly_hours += duration;
      existing.total_capacity += event.max_participants || 0;
      existing.total_booked += event.current_participants;
      existing.classes_taught += 1;
      existing.time_patterns.add(this.getDayHourKey(event.start_time));

      if (event.category) {
        existing.categories.add(event.category);
      }

      existing.revenue += (event.price || 0) * event.current_participants;
      instructorData.set(instructor, existing);
    });

    const optimizations: InstructorOptimization[] = [];

    instructorData.forEach((data, instructorName) => {
      const avg_capacity_rate = data.total_capacity > 0 ? data.total_booked / data.total_capacity : 0;

      let suggested_additional_hours = 0;
      let potential_revenue_increase = 0;

      // High-performing instructors can teach more
      if (avg_capacity_rate > 0.8 && data.weekly_hours < 20) {
        suggested_additional_hours = Math.min(6, 20 - data.weekly_hours);
        potential_revenue_increase = suggested_additional_hours * 150; // $150 per hour average
      }

      // Find optimal time slots (simplified - avoid existing patterns)
      const optimal_time_slots = this.findOptimalNewSlots(data.time_patterns);

      optimizations.push({
        instructor_name: instructorName,
        current_weekly_hours: data.weekly_hours,
        avg_capacity_rate,
        suggested_additional_hours,
        optimal_time_slots,
        potential_revenue_increase
      });
    });

    return optimizations
      .filter(opt => opt.suggested_additional_hours > 0)
      .sort((a, b) => b.potential_revenue_increase - a.potential_revenue_increase);
  }

  /**
   * Analyze capacity optimization opportunities
   */
  private analyzeCapacityOptimization(events: ImportedEvent[]): CapacityRecommendation[] {
    const categoryData = new Map<string, {
      total_classes: number;
      total_max_capacity: number;
      total_current: number;
      avg_price: number;
      over_capacity_count: number;
    }>();

    events.forEach(event => {
      const category = event.category || 'General';
      const existing = categoryData.get(category) || {
        total_classes: 0,
        total_max_capacity: 0,
        total_current: 0,
        avg_price: 0,
        over_capacity_count: 0
      };

      existing.total_classes += 1;
      existing.total_max_capacity += event.max_participants || 0;
      existing.total_current += event.current_participants;
      existing.avg_price = (existing.avg_price + (event.price || 0)) / 2;

      // Check if class is overbooked (indicating waitlist)
      if (event.current_participants > (event.max_participants || 0)) {
        existing.over_capacity_count += 1;
      }

      categoryData.set(category, existing);
    });

    const recommendations: CapacityRecommendation[] = [];

    categoryData.forEach((data, category) => {
      const current_avg_size = data.total_classes > 0 ? data.total_max_capacity / data.total_classes : 0;
      const current_fill_rate = data.total_max_capacity > 0 ? data.total_current / data.total_max_capacity : 0;
      const waitlist_indicator = data.over_capacity_count / data.total_classes;

      let recommended_size = current_avg_size;
      let confidence_level: 'high' | 'medium' | 'low' = 'low';

      if (waitlist_indicator > 0.3 && current_fill_rate > 0.9) {
        // High demand, increase capacity
        recommended_size = Math.ceil(current_avg_size * 1.25);
        confidence_level = 'high';
      } else if (current_fill_rate < 0.6 && data.total_classes >= 3) {
        // Low demand, decrease capacity for better economics
        recommended_size = Math.floor(current_avg_size * 0.8);
        confidence_level = 'medium';
      }

      const revenue_impact = (recommended_size - current_avg_size) * data.avg_price * data.total_classes;

      if (Math.abs(recommended_size - current_avg_size) >= 1) {
        recommendations.push({
          category,
          current_avg_size,
          recommended_size,
          waitlist_indicator,
          revenue_impact,
          confidence_level
        });
      }
    });

    return recommendations.sort((a, b) => Math.abs(b.revenue_impact) - Math.abs(a.revenue_impact));
  }

  // Helper methods
  private filterRecentEvents(events: ImportedEvent[], studioId: string): ImportedEvent[] {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    return events.filter(event =>
      event.studio_id === studioId &&
      new Date(event.start_time) >= threeMonthsAgo &&
      event.migration_status === 'imported'
    );
  }

  private getDayHourKey(startTime: string): string {
    const date = new Date(startTime);
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return `${days[date.getDay()]}-${date.getHours()}`;
  }

  private getEventDurationHours(startTime: string, endTime: string): number {
    const start = new Date(startTime);
    const end = new Date(endTime);
    return (end.getTime() - start.getTime()) / (1000 * 60 * 60);
  }

  private findUnderutilizedSlots(usedSlots: Set<string>) {
    // Simplified: return common time slots that aren't being used
    const commonSlots = [
      { day: 'Monday', hour: 18, opportunity_score: 0.8 },
      { day: 'Tuesday', hour: 19, opportunity_score: 0.7 },
      { day: 'Wednesday', hour: 17, opportunity_score: 0.9 },
      { day: 'Thursday', hour: 18, opportunity_score: 0.85 },
      { day: 'Saturday', hour: 10, opportunity_score: 0.75 }
    ];

    return commonSlots.filter(slot =>
      !usedSlots.has(`${slot.day}-${slot.hour}`)
    );
  }

  private getMostSuccessfulCategory(events: ImportedEvent[]): string {
    const categorySuccess = new Map<string, number>();

    events.forEach(event => {
      if (event.category && event.max_participants && event.max_participants > 0) {
        const fillRate = event.current_participants / event.max_participants;
        categorySuccess.set(
          event.category,
          (categorySuccess.get(event.category) || 0) + fillRate
        );
      }
    });

    let bestCategory = 'pottery';
    let bestScore = 0;
    categorySuccess.forEach((score, category) => {
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  private findOptimalNewSlots(existingPatterns: Set<string>) {
    const allSlots = [
      { day: 'Monday', hour: 18, category: 'pottery' },
      { day: 'Tuesday', hour: 19, category: 'painting' },
      { day: 'Wednesday', hour: 17, category: 'pottery' },
      { day: 'Thursday', hour: 18, category: 'jewelry' },
      { day: 'Saturday', hour: 10, category: 'pottery' }
    ];

    return allSlots.filter(slot =>
      !existingPatterns.has(`${slot.day}-${slot.hour}`)
    ).slice(0, 3);
  }

  private calculateRevenuePotential(
    timeSlots: TimeSlotRecommendation[],
    roomEfficiency: RoomEfficiencyData[],
    instructorOptimization: InstructorOptimization[],
    capacityAdjustments: CapacityRecommendation[]
  ): number {
    const roomPotential = roomEfficiency.reduce((sum, room) => sum + room.potential_revenue_increase, 0);
    const instructorPotential = instructorOptimization.reduce((sum, inst) => sum + inst.potential_revenue_increase, 0);
    const capacityPotential = capacityAdjustments.reduce((sum, cap) => sum + Math.max(0, cap.revenue_impact), 0);

    return roomPotential + instructorPotential + capacityPotential;
  }

  private determineTopPriorityAction(
    timeSlots: TimeSlotRecommendation[],
    roomEfficiency: RoomEfficiencyData[],
    instructorOptimization: InstructorOptimization[],
    capacityAdjustments: CapacityRecommendation[]
  ): string {
    // Find the action with highest revenue potential
    const actions = [
      { action: timeSlots[0]?.recommended_action || '', potential: 0 },
      {
        action: roomEfficiency[0] ? `Utilize ${roomEfficiency[0].room_name} more efficiently` : '',
        potential: roomEfficiency[0]?.potential_revenue_increase || 0
      },
      {
        action: instructorOptimization[0] ? `Add ${instructorOptimization[0].suggested_additional_hours} hours for ${instructorOptimization[0].instructor_name}` : '',
        potential: instructorOptimization[0]?.potential_revenue_increase || 0
      },
      {
        action: capacityAdjustments[0] ? `Adjust ${capacityAdjustments[0].category} class size to ${capacityAdjustments[0].recommended_size}` : '',
        potential: Math.abs(capacityAdjustments[0]?.revenue_impact || 0)
      }
    ];

    const topAction = actions.reduce((max, current) =>
      current.potential > max.potential ? current : max
    );

    return topAction.action || 'Continue monitoring current performance';
  }

  private getEmptyInsights(): StudioIntelligenceInsights {
    return {
      timeSlots: [],
      roomEfficiency: [],
      instructorOptimization: [],
      capacityAdjustments: [],
      weeklyRevenuePotential: 0,
      topPriorityAction: 'Import calendar data to generate insights'
    };
  }
}

export const studioAnalyticsService = new StudioAnalyticsService();