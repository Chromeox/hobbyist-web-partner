/**
 * Analytics Web Worker
 * Handles heavy analytics calculations in background thread
 * Prevents UI blocking during complex data processing
 */

// Import statements for Web Worker
self.importScripts('https://cdn.jsdelivr.net/npm/simple-statistics@7.8.2/dist/simple-statistics.min.js');

// Message handler
self.addEventListener('message', async (event) => {
  const { type, data } = event.data;
  
  try {
    switch (type) {
      case 'CALCULATE_REVENUE_ANALYTICS':
        const revenueAnalytics = await calculateRevenueAnalytics(data);
        self.postMessage({ type: 'REVENUE_ANALYTICS_COMPLETE', data: revenueAnalytics });
        break;
      
      case 'PREDICT_BOOKING_TRENDS':
        const predictions = await predictBookingTrends(data);
        self.postMessage({ type: 'BOOKING_PREDICTIONS_COMPLETE', data: predictions });
        break;
      
      case 'ANALYZE_INSTRUCTOR_PERFORMANCE':
        const performance = await analyzeInstructorPerformance(data);
        self.postMessage({ type: 'INSTRUCTOR_ANALYSIS_COMPLETE', data: performance });
        break;
      
      case 'CALCULATE_COHORT_RETENTION':
        const retention = await calculateCohortRetention(data);
        self.postMessage({ type: 'COHORT_RETENTION_COMPLETE', data: retention });
        break;
      
      case 'OPTIMIZE_CLASS_SCHEDULE':
        const optimized = await optimizeClassSchedule(data);
        self.postMessage({ type: 'SCHEDULE_OPTIMIZATION_COMPLETE', data: optimized });
        break;
      
      case 'GENERATE_REPORT':
        const report = await generateComprehensiveReport(data);
        self.postMessage({ type: 'REPORT_GENERATED', data: report });
        break;
      
      default:
        throw new Error(`Unknown message type: ${type}`);
    }
  } catch (error) {
    self.postMessage({ 
      type: 'ERROR', 
      error: { 
        message: error.message, 
        stack: error.stack 
      } 
    });
  }
});

/**
 * Calculate comprehensive revenue analytics
 * CPU-intensive operation perfect for Web Worker
 */
async function calculateRevenueAnalytics(data) {
  const { bookings, timeRange, granularity } = data;
  
  console.log(`[Worker] Processing ${bookings.length} bookings`);
  
  // Group bookings by time period
  const groupedData = groupByTimePeriod(bookings, granularity);
  
  // Calculate metrics for each period
  const analytics = {
    periods: [],
    totals: {
      revenue: 0,
      bookings: 0,
      avgBookingValue: 0,
      creditsUsed: 0,
      cashPayments: 0
    },
    trends: {},
    forecasts: {},
    insights: []
  };
  
  // Process each period
  for (const [period, periodBookings] of Object.entries(groupedData)) {
    const periodMetrics = {
      period,
      revenue: 0,
      bookings: periodBookings.length,
      credits: 0,
      cash: 0,
      avgValue: 0,
      uniqueUsers: new Set(),
      popularClasses: {},
      peakHours: new Array(24).fill(0)
    };
    
    // Calculate metrics
    periodBookings.forEach(booking => {
      const amount = booking.amount_paid || 0;
      periodMetrics.revenue += amount;
      
      if (booking.payment_method === 'credit') {
        periodMetrics.credits += booking.credits_used || 0;
      } else if (booking.payment_method === 'cash') {
        periodMetrics.cash += amount;
      }
      
      periodMetrics.uniqueUsers.add(booking.user_id);
      
      // Track popular classes
      const className = booking.class_name || 'Unknown';
      periodMetrics.popularClasses[className] = (periodMetrics.popularClasses[className] || 0) + 1;
      
      // Track peak hours
      const hour = new Date(booking.created_at).getHours();
      periodMetrics.peakHours[hour]++;
    });
    
    periodMetrics.avgValue = periodMetrics.revenue / periodMetrics.bookings || 0;
    periodMetrics.uniqueUsers = periodMetrics.uniqueUsers.size;
    
    analytics.periods.push(periodMetrics);
    
    // Update totals
    analytics.totals.revenue += periodMetrics.revenue;
    analytics.totals.bookings += periodMetrics.bookings;
    analytics.totals.creditsUsed += periodMetrics.credits;
    analytics.totals.cashPayments += periodMetrics.cash;
  }
  
  analytics.totals.avgBookingValue = analytics.totals.revenue / analytics.totals.bookings || 0;
  
  // Calculate trends
  if (analytics.periods.length > 1) {
    const revenues = analytics.periods.map(p => p.revenue);
    const bookingCounts = analytics.periods.map(p => p.bookings);
    
    analytics.trends = {
      revenue: calculateTrend(revenues),
      bookings: calculateTrend(bookingCounts),
      avgGrowthRate: calculateGrowthRate(revenues),
      volatility: ss.standardDeviation(revenues) / ss.mean(revenues)
    };
    
    // Generate forecasts using linear regression
    analytics.forecasts = generateForecasts(analytics.periods);
  }
  
  // Generate insights
  analytics.insights = generateInsights(analytics);
  
  return analytics;
}

/**
 * Predict booking trends using time series analysis
 */
async function predictBookingTrends(data) {
  const { historicalData, horizonDays = 30 } = data;
  
  // Prepare time series data
  const timeSeries = historicalData.map((d, i) => ({
    x: i,
    y: d.bookings || 0
  }));
  
  // Calculate linear regression
  const regression = ss.linearRegression(timeSeries);
  const regressionLine = ss.linearRegressionLine(regression);
  
  // Calculate seasonal patterns (weekly)
  const seasonalPattern = detectSeasonality(historicalData, 7);
  
  // Generate predictions
  const predictions = [];
  const lastIndex = timeSeries.length - 1;
  
  for (let i = 1; i <= horizonDays; i++) {
    const trendValue = regressionLine(lastIndex + i);
    const seasonalAdjustment = seasonalPattern[i % 7] || 1;
    const predictedValue = Math.max(0, trendValue * seasonalAdjustment);
    
    predictions.push({
      day: i,
      predicted: Math.round(predictedValue),
      trendComponent: trendValue,
      seasonalComponent: seasonalAdjustment,
      confidence: {
        lower: Math.round(predictedValue * 0.8),
        upper: Math.round(predictedValue * 1.2)
      }
    });
  }
  
  // Calculate accuracy metrics on historical data
  const accuracy = calculateAccuracy(historicalData, regression);
  
  return {
    predictions,
    accuracy,
    model: {
      type: 'linear_regression_with_seasonality',
      slope: regression.m,
      intercept: regression.b,
      r_squared: accuracy.r_squared,
      seasonalPattern
    },
    insights: generateTrendInsights(predictions, historicalData)
  };
}

/**
 * Analyze instructor performance metrics
 */
async function analyzeInstructorPerformance(data) {
  const { instructors, bookings, reviews } = data;
  
  const performanceMetrics = instructors.map(instructor => {
    // Filter relevant data
    const instructorBookings = bookings.filter(b => b.instructor_id === instructor.id);
    const instructorReviews = reviews.filter(r => r.instructor_id === instructor.id);
    
    // Calculate metrics
    const totalClasses = instructorBookings.length;
    const totalStudents = new Set(instructorBookings.map(b => b.user_id)).size;
    const totalRevenue = instructorBookings.reduce((sum, b) => sum + (b.amount_paid || 0), 0);
    
    // Rating metrics
    const ratings = instructorReviews.map(r => r.rating);
    const avgRating = ratings.length > 0 ? ss.mean(ratings) : 0;
    const ratingTrend = calculateTrend(ratings);
    
    // Attendance and retention
    const attendanceRate = instructorBookings.filter(b => b.attended).length / totalClasses || 0;
    const repeatStudents = calculateRepeatRate(instructorBookings);
    
    // Capacity utilization
    const capacityUtilization = calculateCapacityUtilization(instructorBookings);
    
    // Performance score (weighted composite)
    const performanceScore = calculatePerformanceScore({
      avgRating: avgRating * 0.3,
      attendanceRate: attendanceRate * 0.2,
      repeatStudents: repeatStudents * 0.2,
      capacityUtilization: capacityUtilization * 0.15,
      totalRevenue: Math.min(totalRevenue / 10000, 1) * 0.15
    });
    
    return {
      instructorId: instructor.id,
      name: instructor.name,
      metrics: {
        totalClasses,
        totalStudents,
        totalRevenue,
        avgRating,
        ratingTrend,
        attendanceRate,
        repeatStudents,
        capacityUtilization,
        performanceScore
      },
      percentiles: {}, // Will be calculated after all metrics are computed
      recommendations: []
    };
  });
  
  // Calculate percentiles for benchmarking
  const allScores = performanceMetrics.map(p => p.metrics.performanceScore);
  performanceMetrics.forEach(pm => {
    pm.percentiles = {
      performance: calculatePercentile(pm.metrics.performanceScore, allScores),
      rating: calculatePercentile(pm.metrics.avgRating, performanceMetrics.map(p => p.metrics.avgRating)),
      revenue: calculatePercentile(pm.metrics.totalRevenue, performanceMetrics.map(p => p.metrics.totalRevenue))
    };
    
    // Generate personalized recommendations
    pm.recommendations = generateInstructorRecommendations(pm);
  });
  
  // Sort by performance
  performanceMetrics.sort((a, b) => b.metrics.performanceScore - a.metrics.performanceScore);
  
  return {
    instructors: performanceMetrics,
    summary: {
      topPerformers: performanceMetrics.slice(0, 5),
      needsImprovement: performanceMetrics.filter(p => p.metrics.performanceScore < 0.5),
      avgMetrics: calculateAverageMetrics(performanceMetrics)
    }
  };
}

/**
 * Calculate cohort retention rates
 */
async function calculateCohortRetention(data) {
  const { users, bookings, cohortSize = 'monthly' } = data;
  
  // Group users into cohorts
  const cohorts = groupUsersByCohort(users, cohortSize);
  const retentionData = {};
  
  for (const [cohortKey, cohortUsers] of Object.entries(cohorts)) {
    const cohortUserIds = cohortUsers.map(u => u.id);
    const cohortStart = new Date(cohortKey);
    
    // Track activity for each period after cohort start
    const periods = {};
    const maxPeriods = 12; // Track up to 12 periods
    
    for (let period = 0; period < maxPeriods; period++) {
      const periodStart = addPeriod(cohortStart, period, cohortSize);
      const periodEnd = addPeriod(cohortStart, period + 1, cohortSize);
      
      // Find active users in this period
      const activeUsers = new Set(
        bookings
          .filter(b => {
            const bookingDate = new Date(b.created_at);
            return cohortUserIds.includes(b.user_id) &&
                   bookingDate >= periodStart &&
                   bookingDate < periodEnd;
          })
          .map(b => b.user_id)
      );
      
      periods[`period_${period}`] = {
        activeCount: activeUsers.size,
        retentionRate: activeUsers.size / cohortUsers.length,
        churnRate: 1 - (activeUsers.size / cohortUsers.length)
      };
    }
    
    retentionData[cohortKey] = {
      cohortSize: cohortUsers.length,
      periods,
      ltv: calculateCohortLTV(cohortUserIds, bookings)
    };
  }
  
  // Calculate aggregate metrics
  const aggregateRetention = calculateAggregateRetention(retentionData);
  
  return {
    cohorts: retentionData,
    aggregate: aggregateRetention,
    insights: generateRetentionInsights(retentionData)
  };
}

/**
 * Optimize class schedule based on demand patterns
 */
async function optimizeClassSchedule(data) {
  const { currentSchedule, historicalBookings, constraints } = data;
  
  // Analyze demand patterns
  const demandAnalysis = analyzeDemandPatterns(historicalBookings);
  
  // Identify optimization opportunities
  const opportunities = [];
  
  // Check each time slot
  for (const slot of generateTimeSlots()) {
    const currentClasses = currentSchedule.filter(c => 
      isSameTimeSlot(c.start_time, slot)
    );
    
    const demand = demandAnalysis[slot.key] || 0;
    const supply = currentClasses.reduce((sum, c) => sum + c.capacity, 0);
    
    if (demand > supply * 1.2) {
      opportunities.push({
        type: 'ADD_CLASS',
        timeSlot: slot,
        reason: 'High demand',
        expectedBookings: Math.round(demand - supply),
        priority: 'high'
      });
    } else if (demand < supply * 0.5 && currentClasses.length > 0) {
      opportunities.push({
        type: 'REMOVE_CLASS',
        timeSlot: slot,
        class: currentClasses[0],
        reason: 'Low demand',
        expectedSavings: calculateSavings(currentClasses[0]),
        priority: 'medium'
      });
    }
  }
  
  // Generate optimized schedule
  const optimizedSchedule = applyOptimizations(currentSchedule, opportunities, constraints);
  
  // Calculate expected improvements
  const improvements = calculateExpectedImprovements(currentSchedule, optimizedSchedule, demandAnalysis);
  
  return {
    currentUtilization: calculateScheduleUtilization(currentSchedule, historicalBookings),
    optimizedUtilization: calculateScheduleUtilization(optimizedSchedule, demandAnalysis),
    opportunities,
    optimizedSchedule,
    improvements,
    recommendations: generateScheduleRecommendations(opportunities, improvements)
  };
}

// Helper functions

function groupByTimePeriod(data, granularity) {
  const grouped = {};
  
  data.forEach(item => {
    const date = new Date(item.created_at);
    let key;
    
    switch (granularity) {
      case 'daily':
        key = date.toISOString().split('T')[0];
        break;
      case 'weekly':
        key = getWeekKey(date);
        break;
      case 'monthly':
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        break;
      default:
        key = date.toISOString().split('T')[0];
    }
    
    if (!grouped[key]) {
      grouped[key] = [];
    }
    grouped[key].push(item);
  });
  
  return grouped;
}

function calculateTrend(values) {
  if (values.length < 2) return 'stable';
  
  const regression = ss.linearRegression(values.map((v, i) => ({ x: i, y: v })));
  const slope = regression.m;
  
  if (Math.abs(slope) < 0.01) return 'stable';
  return slope > 0 ? 'increasing' : 'decreasing';
}

function calculateGrowthRate(values) {
  if (values.length < 2) return 0;
  
  const growthRates = [];
  for (let i = 1; i < values.length; i++) {
    if (values[i - 1] !== 0) {
      growthRates.push((values[i] - values[i - 1]) / values[i - 1]);
    }
  }
  
  return growthRates.length > 0 ? ss.mean(growthRates) : 0;
}

function detectSeasonality(data, period) {
  const seasonal = new Array(period).fill(0);
  const counts = new Array(period).fill(0);
  
  data.forEach((item, index) => {
    const position = index % period;
    seasonal[position] += item.bookings || 0;
    counts[position]++;
  });
  
  // Calculate average for each position
  const avgTotal = ss.mean(data.map(d => d.bookings || 0));
  
  return seasonal.map((sum, i) => {
    const avg = sum / counts[i];
    return avgTotal > 0 ? avg / avgTotal : 1;
  });
}

function calculatePercentile(value, allValues) {
  const sorted = allValues.slice().sort((a, b) => a - b);
  const index = sorted.findIndex(v => v >= value);
  return index === -1 ? 100 : (index / sorted.length) * 100;
}

function generateInsights(analytics) {
  const insights = [];
  
  // Revenue trend insight
  if (analytics.trends.revenue === 'increasing') {
    insights.push({
      type: 'positive',
      message: `Revenue is trending up with ${(analytics.trends.avgGrowthRate * 100).toFixed(1)}% average growth`,
      priority: 'high'
    });
  } else if (analytics.trends.revenue === 'decreasing') {
    insights.push({
      type: 'warning',
      message: `Revenue is declining. Consider promotional campaigns or schedule optimization`,
      priority: 'high'
    });
  }
  
  // Peak hours insight
  const peakHours = findPeakHours(analytics.periods);
  if (peakHours.length > 0) {
    insights.push({
      type: 'info',
      message: `Peak booking hours are ${peakHours.join(', ')}. Consider adding more classes during these times`,
      priority: 'medium'
    });
  }
  
  return insights;
}

function findPeakHours(periods) {
  const hourTotals = new Array(24).fill(0);
  
  periods.forEach(period => {
    period.peakHours.forEach((count, hour) => {
      hourTotals[hour] += count;
    });
  });
  
  const avg = ss.mean(hourTotals);
  const threshold = avg * 1.5;
  
  return hourTotals
    .map((count, hour) => ({ hour, count }))
    .filter(h => h.count > threshold)
    .map(h => `${h.hour}:00`)
    .slice(0, 3);
}

function getWeekKey(date) {
  const year = date.getFullYear();
  const week = getWeekNumber(date);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

function getWeekNumber(date) {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const pastDaysOfYear = (date - firstDayOfYear) / 86400000;
  return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
}

console.log('[Analytics Worker] Ready');