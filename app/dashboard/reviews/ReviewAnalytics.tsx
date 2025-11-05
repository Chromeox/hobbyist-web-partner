'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import {
  TrendingUp,
  TrendingDown,
  Star,
  MessageCircle,
  ThumbsUp,
  Reply,
  Calendar,
  BarChart3,
  PieChart,
  Activity,
  Users,
  Clock,
  Target,
  Award,
  Filter,
  Download,
  RefreshCw
} from 'lucide-react';
import RatingStars from './RatingStars';

interface ReviewAnalyticsData {
  totalReviews: number;
  averageRating: number;
  ratingDistribution: Record<number, number>;
  responseRate: number;
  responseTime: number; // average response time in hours
  sentimentScore: number; // -1 to 1 scale
  trendingKeywords: Array<{
    word: string;
    count: number;
    sentiment: 'positive' | 'neutral' | 'negative';
  }>;
  timeSeriesData: Array<{
    date: string;
    reviews: number;
    rating: number;
    responses: number;
  }>;
  classBreakdown: Array<{
    classId: string;
    className: string;
    reviewCount: number;
    averageRating: number;
    totalBookings: number;
  }>;
  instructorBreakdown: Array<{
    instructorId: string;
    instructorName: string;
    reviewCount: number;
    averageRating: number;
    responseRate: number;
  }>;
  competitorComparison?: {
    industryAverage: number;
    percentile: number;
  };
}

interface DateRange {
  label: string;
  value: string;
  days: number;
}

const DATE_RANGES: DateRange[] = [
  { label: 'Last 7 days', value: '7d', days: 7 },
  { label: 'Last 30 days', value: '30d', days: 30 },
  { label: 'Last 90 days', value: '90d', days: 90 },
  { label: 'Last 6 months', value: '180d', days: 180 },
  { label: 'Last year', value: '365d', days: 365 },
  { label: 'All time', value: 'all', days: 0 }
];

const ReviewAnalytics: React.FC = () => {
  const [analyticsData, setAnalyticsData] = useState<ReviewAnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedRange, setSelectedRange] = useState<string>('30d');
  const [selectedMetric, setSelectedMetric] = useState<'reviews' | 'rating' | 'responses'>('reviews');

  // Load analytics data
  useEffect(() => {
    loadAnalytics();
  }, [selectedRange]);

  const loadAnalytics = async () => {
    setLoading(true);
    try {
      // Mock data for development - replace with actual API call
      const mockData: ReviewAnalyticsData = {
        totalReviews: 156,
        averageRating: 4.6,
        ratingDistribution: {
          5: 89,
          4: 42,
          3: 18,
          2: 5,
          1: 2
        },
        responseRate: 78.2,
        responseTime: 4.5,
        sentimentScore: 0.73,
        trendingKeywords: [
          { word: 'amazing', count: 45, sentiment: 'positive' },
          { word: 'professional', count: 38, sentiment: 'positive' },
          { word: 'clean', count: 32, sentiment: 'positive' },
          { word: 'challenging', count: 28, sentiment: 'positive' },
          { word: 'friendly', count: 25, sentiment: 'positive' },
          { word: 'crowded', count: 12, sentiment: 'negative' },
          { word: 'expensive', count: 8, sentiment: 'negative' },
          { word: 'difficult', count: 15, sentiment: 'neutral' }
        ],
        timeSeriesData: Array.from({ length: 30 }, (_, i) => {
          const date = new Date();
          date.setDate(date.getDate() - (29 - i));
          return {
            date: date.toISOString().split('T')[0],
            reviews: Math.floor(Math.random() * 8) + 1,
            rating: 4.0 + Math.random() * 1.0,
            responses: Math.floor(Math.random() * 6)
          };
        }),
        classBreakdown: [
          { classId: '1', className: 'Morning Yoga Flow', reviewCount: 45, averageRating: 4.8, totalBookings: 120 },
          { classId: '2', className: 'HIIT Training', reviewCount: 32, averageRating: 4.5, totalBookings: 89 },
          { classId: '3', className: 'Pottery Basics', reviewCount: 28, averageRating: 4.3, totalBookings: 67 },
          { classId: '4', className: 'Advanced Pilates', reviewCount: 25, averageRating: 4.7, totalBookings: 78 },
          { classId: '5', className: 'Beginner Dance', reviewCount: 26, averageRating: 4.4, totalBookings: 95 }
        ],
        instructorBreakdown: [
          { instructorId: '1', instructorName: 'Lisa Chen', reviewCount: 67, averageRating: 4.8, responseRate: 89.5 },
          { instructorId: '2', instructorName: 'Mike Rodriguez', reviewCount: 45, averageRating: 4.5, responseRate: 73.3 },
          { instructorId: '3', instructorName: 'Emma Thompson', reviewCount: 44, averageRating: 4.4, responseRate: 68.2 }
        ],
        competitorComparison: {
          industryAverage: 4.2,
          percentile: 85
        }
      };

      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      setAnalyticsData(mockData);
    } catch (error) {
      console.error('Failed to load analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate trends and changes
  const trends = useMemo(() => {
    if (!analyticsData) return null;

    // Mock trend calculations - in real app, compare with previous period
    return {
      reviewsChange: +12.5,
      ratingChange: +0.2,
      responseRateChange: +5.8,
      sentimentChange: +8.3
    };
  }, [analyticsData]);

  // Prepare chart data
  const chartData = useMemo(() => {
    if (!analyticsData) return null;

    const { timeSeriesData } = analyticsData;
    
    return {
      dates: timeSeriesData.map(d => d.date),
      reviews: timeSeriesData.map(d => d.reviews),
      ratings: timeSeriesData.map(d => d.rating),
      responses: timeSeriesData.map(d => d.responses)
    };
  }, [analyticsData, selectedMetric]);

  // Format numbers
  const formatNumber = (num: number, decimal: number = 1): string => {
    return num.toFixed(decimal);
  };

  const formatPercentage = (num: number): string => {
    return `${num.toFixed(1)}%`;
  };

  // Generate rating distribution chart data
  const getRatingChartData = () => {
    if (!analyticsData) return [];
    
    const { ratingDistribution } = analyticsData;
    return Array.from({ length: 5 }, (_, i) => {
      const rating = 5 - i;
      const count = ratingDistribution[rating] || 0;
      const percentage = (count / analyticsData.totalReviews) * 100;
      return { rating, count, percentage };
    });
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading analytics...</p>
        </div>
      </div>
    );
  }

  if (!analyticsData) {
    return (
      <div className="text-center py-12">
        <BarChart3 className="mx-auto h-12 w-12 text-gray-400" />
        <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-white">
          No analytics data available
        </h3>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Analytics will appear here once you have review data.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Review Analytics
          </h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">
            Insights and trends from your customer reviews
          </p>
        </div>
        
        <div className="flex items-center gap-4">
          {/* Date Range Selector */}
          <select
            value={selectedRange}
            onChange={(e) => setSelectedRange(e.target.value)}
            className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
          >
            {DATE_RANGES.map(range => (
              <option key={range.value} value={range.value}>
                {range.label}
              </option>
            ))}
          </select>

          <button
            onClick={loadAnalytics}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <RefreshCw size={20} />
            Refresh
          </button>

          <button className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
            <Download size={20} />
            Export
          </button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Total Reviews</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {analyticsData.totalReviews.toLocaleString()}
              </p>
              {trends && (
                <div className="flex items-center mt-2">
                  {trends.reviewsChange >= 0 ? (
                    <TrendingUp className="text-green-500" size={16} />
                  ) : (
                    <TrendingDown className="text-red-500" size={16} />
                  )}
                  <span className={`ml-1 text-sm ${
                    trends.reviewsChange >= 0 ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {formatPercentage(Math.abs(trends.reviewsChange))}
                  </span>
                </div>
              )}
            </div>
            <MessageCircle className="text-blue-600" size={32} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Average Rating</p>
              <div className="flex items-center gap-2">
                <p className="text-3xl font-bold text-gray-900 dark:text-white">
                  {formatNumber(analyticsData.averageRating)}
                </p>
                <Star className="text-yellow-400" size={24} fill="currentColor" />
              </div>
              <div className="flex items-center mt-2">
                <RatingStars rating={analyticsData.averageRating} size="sm" />
                {trends && (
                  <div className="flex items-center ml-2">
                    {trends.ratingChange >= 0 ? (
                      <TrendingUp className="text-green-500" size={16} />
                    ) : (
                      <TrendingDown className="text-red-500" size={16} />
                    )}
                    <span className={`ml-1 text-sm ${
                      trends.ratingChange >= 0 ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {formatNumber(Math.abs(trends.ratingChange))}
                    </span>
                  </div>
                )}
              </div>
            </div>
            <Award className="text-yellow-600" size={32} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Response Rate</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {formatPercentage(analyticsData.responseRate)}
              </p>
              {trends && (
                <div className="flex items-center mt-2">
                  {trends.responseRateChange >= 0 ? (
                    <TrendingUp className="text-green-500" size={16} />
                  ) : (
                    <TrendingDown className="text-red-500" size={16} />
                  )}
                  <span className={`ml-1 text-sm ${
                    trends.responseRateChange >= 0 ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {formatPercentage(Math.abs(trends.responseRateChange))}
                  </span>
                </div>
              )}
            </div>
            <Reply className="text-blue-600" size={32} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Avg Response Time</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {formatNumber(analyticsData.responseTime)}h
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
                Target: &lt; 24h
              </p>
            </div>
            <Clock className="text-orange-600" size={32} />
          </div>
        </motion.div>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Rating Distribution */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Rating Distribution
            </h3>
            <PieChart className="text-gray-400" size={24} />
          </div>
          
          <div className="space-y-4">
            {getRatingChartData().map(item => (
              <div key={item.rating} className="flex items-center gap-4">
                <div className="flex items-center gap-2 w-20">
                  <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    {item.rating}
                  </span>
                  <Star className="text-yellow-400" size={16} fill="currentColor" />
                </div>
                <div className="flex-1">
                  <div className="bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full transition-all duration-500"
                      style={{ width: `${item.percentage}%` }}
                    />
                  </div>
                </div>
                <div className="flex items-center gap-2 w-20 justify-end">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {item.count}
                  </span>
                  <span className="text-sm text-gray-500 dark:text-gray-500">
                    ({formatPercentage(item.percentage)})
                  </span>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Sentiment Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Sentiment Analysis
            </h3>
            <Activity className="text-gray-400" size={24} />
          </div>
          
          <div className="text-center mb-6">
            <div className="inline-flex items-center justify-center w-24 h-24 rounded-full bg-gradient-to-br from-green-400 to-blue-500 text-white text-2xl font-bold mb-4">
              {formatNumber(analyticsData.sentimentScore * 100, 0)}%
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Overall Sentiment Score
            </p>
            {trends && (
              <div className="flex items-center justify-center mt-2">
                {trends.sentimentChange >= 0 ? (
                  <TrendingUp className="text-green-500" size={16} />
                ) : (
                  <TrendingDown className="text-red-500" size={16} />
                )}
                <span className={`ml-1 text-sm ${
                  trends.sentimentChange >= 0 ? 'text-green-600' : 'text-red-600'
                }`}>
                  {formatPercentage(Math.abs(trends.sentimentChange))}
                </span>
              </div>
            )}
          </div>

          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-green-600">Positive</span>
              <span className="text-green-600">{formatPercentage(70)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-500 dark:text-gray-400">Neutral</span>
              <span className="text-gray-500 dark:text-gray-400">{formatPercentage(23)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-red-600">Negative</span>
              <span className="text-red-600">{formatPercentage(7)}</span>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Trending Keywords */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
      >
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            Trending Keywords
          </h3>
          <Target className="text-gray-400" size={24} />
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-3">
          {analyticsData.trendingKeywords.map((keyword, index) => (
            <div
              key={keyword.word}
              className={`p-3 rounded-lg text-center ${
                keyword.sentiment === 'positive'
                  ? 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-300'
                  : keyword.sentiment === 'negative'
                  ? 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-300'
                  : 'bg-gray-50 dark:bg-gray-700 text-gray-800 dark:text-gray-300'
              }`}
            >
              <p className="font-medium text-sm">{keyword.word}</p>
              <p className="text-xs opacity-75 mt-1">{keyword.count}</p>
            </div>
          ))}
        </div>
      </motion.div>

      {/* Performance Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Classes */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Top Reviewed Classes
            </h3>
            <BarChart3 className="text-gray-400" size={24} />
          </div>
          
          <div className="space-y-4">
            {analyticsData.classBreakdown.map((classData, index) => (
              <div key={classData.classId} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-blue-600 dark:text-blue-400">
                      #{index + 1}
                    </span>
                    <h4 className="font-medium text-gray-900 dark:text-white">
                      {classData.className}
                    </h4>
                  </div>
                  <div className="flex items-center gap-4 mt-2">
                    <RatingStars rating={classData.averageRating} size="sm" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {classData.reviewCount} reviews
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-gray-900 dark:text-white">
                    {formatNumber(classData.averageRating)}
                  </p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {formatPercentage((classData.reviewCount / classData.totalBookings) * 100)} rate
                  </p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Instructor Performance */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Instructor Performance
            </h3>
            <Users className="text-gray-400" size={24} />
          </div>
          
          <div className="space-y-4">
            {analyticsData.instructorBreakdown.map((instructor, index) => (
              <div key={instructor.instructorId} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-blue-600 dark:text-blue-400">
                      #{index + 1}
                    </span>
                    <h4 className="font-medium text-gray-900 dark:text-white">
                      {instructor.instructorName}
                    </h4>
                  </div>
                  <div className="flex items-center gap-4 mt-2">
                    <RatingStars rating={instructor.averageRating} size="sm" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {instructor.reviewCount} reviews
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-gray-900 dark:text-white">
                    {formatNumber(instructor.averageRating)}
                  </p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {formatPercentage(instructor.responseRate)} response
                  </p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Industry Comparison */}
      {analyticsData.competitorComparison && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.9 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Industry Comparison
            </h3>
            <Target className="text-gray-400" size={24} />
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Your Rating</p>
              <p className="text-3xl font-bold text-blue-600">
                {formatNumber(analyticsData.averageRating)}
              </p>
              <RatingStars rating={analyticsData.averageRating} size="sm" />
            </div>
            
            <div className="text-center">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Industry Average</p>
              <p className="text-3xl font-bold text-gray-600">
                {formatNumber(analyticsData.competitorComparison.industryAverage)}
              </p>
              <RatingStars rating={analyticsData.competitorComparison.industryAverage} size="sm" />
            </div>
            
            <div className="text-center">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Your Percentile</p>
              <p className="text-3xl font-bold text-green-600">
                {analyticsData.competitorComparison.percentile}th
              </p>
              <p className="text-sm text-green-600 mt-2">Top performer</p>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  );
};

export default ReviewAnalytics;