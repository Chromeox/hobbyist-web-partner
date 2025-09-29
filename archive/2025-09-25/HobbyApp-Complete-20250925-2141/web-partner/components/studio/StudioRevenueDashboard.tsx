'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  DollarSign,
  TrendingUp,
  TrendingDown,
  Users,
  Calendar,
  Package,
  Clock,
  Star,
  Filter,
  Download,
  RefreshCw
} from 'lucide-react';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDuration, calculateCapacity, getCategoryColor } from '@/lib/utils';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

interface StudioRevenueData {
  totalRevenue: number;
  monthlyGrowth: number;
  averageWorkshopPrice: number;
  totalWorkshops: number;
  totalStudents: number;
  averageCapacity: number;
  materialCosts: number;
  profitMargin: number;

  // Time series data
  revenueByMonth: Array<{ month: string; revenue: number; workshops: number }>;

  // Category breakdown
  categoryRevenue: Array<{
    category: string;
    revenue: number;
    workshops: number;
    averagePrice: number;
    capacity: number;
  }>;

  // Seasonal trends
  seasonalTrends: Array<{
    season: string;
    revenue: number;
    popularCategories: string[];
  }>;

  // Top performing workshops
  topWorkshops: Array<{
    id: string;
    name: string;
    category: string;
    revenue: number;
    bookings: number;
    rating: number;
    instructor: string;
  }>;

  // Material efficiency
  materialEfficiency: Array<{
    category: string;
    costPerWorkshop: number;
    wastePercentage: number;
    profitMargin: number;
  }>;
}

interface StudioRevenueDashboardProps {
  studioId: string;
  timeframe: '30d' | '90d' | '1y';
  onTimeframeChange: (timeframe: '30d' | '90d' | '1y') => void;
}

export function StudioRevenueDashboard({
  studioId,
  timeframe,
  onTimeframeChange
}: StudioRevenueDashboardProps) {
  const [data, setData] = useState<StudioRevenueData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  useEffect(() => {
    fetchRevenueData();
  }, [studioId, timeframe]);

  const fetchRevenueData = async () => {
    setLoading(true);
    try {
      // Mock data - replace with actual API call
      const mockData: StudioRevenueData = {
        totalRevenue: 45670,
        monthlyGrowth: 12.5,
        averageWorkshopPrice: 85,
        totalWorkshops: 156,
        totalStudents: 892,
        averageCapacity: 78,
        materialCosts: 8240,
        profitMargin: 62,
        revenueByMonth: [
          { month: 'Jan', revenue: 12500, workshops: 45 },
          { month: 'Feb', revenue: 15200, workshops: 52 },
          { month: 'Mar', revenue: 18100, workshops: 61 },
        ],
        categoryRevenue: [
          { category: 'pottery', revenue: 18500, workshops: 68, averagePrice: 95, capacity: 82 },
          { category: 'painting', revenue: 15200, workshops: 54, averagePrice: 75, capacity: 76 },
          { category: 'woodworking', revenue: 8900, workshops: 28, averagePrice: 125, capacity: 71 },
          { category: 'jewelry', revenue: 3070, workshops: 16, averagePrice: 65, capacity: 69 },
        ],
        seasonalTrends: [
          { season: 'Spring', revenue: 38200, popularCategories: ['pottery', 'painting'] },
          { season: 'Summer', revenue: 42100, popularCategories: ['woodworking', 'jewelry'] },
        ],
        topWorkshops: [
          {
            id: '1',
            name: 'Beginner Pottery Wheel',
            category: 'pottery',
            revenue: 4200,
            bookings: 48,
            rating: 4.8,
            instructor: 'Sarah Chen'
          },
          {
            id: '2',
            name: 'Watercolor Landscapes',
            category: 'painting',
            revenue: 3600,
            bookings: 42,
            rating: 4.7,
            instructor: 'Michael Torres'
          },
        ],
        materialEfficiency: [
          { category: 'pottery', costPerWorkshop: 35, wastePercentage: 8, profitMargin: 68 },
          { category: 'painting', costPerWorkshop: 25, wastePercentage: 12, profitMargin: 72 },
        ],
      };

      setData(mockData);
    } catch (error) {
      console.error('Failed to fetch revenue data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
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

  if (!data) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Failed to load revenue data</p>
        <Button onClick={fetchRevenueData} className="mt-4">
          <RefreshCw className="h-4 w-4 mr-2" />
          Retry
        </Button>
      </div>
    );
  }

  // Chart configurations
  const revenueChartData = {
    labels: data.revenueByMonth.map(d => d.month),
    datasets: [
      {
        label: 'Revenue',
        data: data.revenueByMonth.map(d => d.revenue),
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        fill: true,
        tension: 0.4,
      },
    ],
  };

  const categoryChartData = {
    labels: data.categoryRevenue.map(c => c.category.charAt(0).toUpperCase() + c.category.slice(1)),
    datasets: [
      {
        data: data.categoryRevenue.map(c => c.revenue),
        backgroundColor: [
          'rgba(245, 158, 11, 0.8)', // pottery - amber
          'rgba(59, 130, 246, 0.8)', // painting - blue
          'rgba(249, 115, 22, 0.8)', // woodworking - orange
          'rgba(168, 85, 247, 0.8)', // jewelry - purple
        ],
        borderWidth: 0,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        grid: {
          color: 'rgba(0, 0, 0, 0.1)',
        },
      },
      x: {
        grid: {
          display: false,
        },
      },
    },
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Studio Revenue Dashboard</h1>
          <p className="text-gray-600">Track your creative workshop business performance</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant={timeframe === '30d' ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTimeframeChange('30d')}
          >
            30 Days
          </Button>
          <Button
            variant={timeframe === '90d' ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTimeframeChange('90d')}
          >
            90 Days
          </Button>
          <Button
            variant={timeframe === '1y' ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTimeframeChange('1y')}
          >
            1 Year
          </Button>
          <Button variant="outline" size="sm">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.1 }}
        >
          <Card className="bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-blue-600">Total Revenue</p>
                  <p className="text-2xl font-bold text-blue-900">{formatCurrency(data.totalRevenue)}</p>
                  <div className="flex items-center mt-1">
                    <TrendingUp className="h-4 w-4 text-green-500 mr-1" />
                    <span className="text-sm text-green-600">+{data.monthlyGrowth}%</span>
                  </div>
                </div>
                <DollarSign className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.2 }}
        >
          <Card className="bg-gradient-to-br from-amber-50 to-amber-100 border-amber-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-amber-600">Total Workshops</p>
                  <p className="text-2xl font-bold text-amber-900">{data.totalWorkshops}</p>
                  <p className="text-sm text-amber-600">Avg. {formatCurrency(data.averageWorkshopPrice)}</p>
                </div>
                <Calendar className="h-8 w-8 text-amber-500" />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.3 }}
        >
          <Card className="bg-gradient-to-br from-green-50 to-green-100 border-green-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-green-600">Total Students</p>
                  <p className="text-2xl font-bold text-green-900">{data.totalStudents}</p>
                  <p className="text-sm text-green-600">{data.averageCapacity}% capacity</p>
                </div>
                <Users className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.4 }}
        >
          <Card className="bg-gradient-to-br from-purple-50 to-purple-100 border-purple-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-purple-600">Profit Margin</p>
                  <p className="text-2xl font-bold text-purple-900">{data.profitMargin}%</p>
                  <p className="text-sm text-purple-600">-{formatCurrency(data.materialCosts)} costs</p>
                </div>
                <TrendingUp className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Trend */}
        <Card>
          <CardHeader>
            <CardTitle>Revenue Trend</CardTitle>
            <CardDescription>Monthly revenue over time</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <Line data={revenueChartData} options={chartOptions} />
            </div>
          </CardContent>
        </Card>

        {/* Category Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Revenue by Category</CardTitle>
            <CardDescription>Workshop category performance</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <Doughnut data={categoryChartData} options={{ responsive: true, maintainAspectRatio: false }} />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Category Performance */}
      <Card>
        <CardHeader>
          <CardTitle>Workshop Category Performance</CardTitle>
          <CardDescription>Detailed breakdown by creative category</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {data.categoryRevenue.map((category, index) => (
              <motion.div
                key={category.category}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: index * 0.1 }}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer"
                onClick={() => setSelectedCategory(category.category)}
              >
                <div className="flex items-center space-x-4">
                  <Badge variant={category.category as any} className="min-w-fit">
                    {category.category.charAt(0).toUpperCase() + category.category.slice(1)}
                  </Badge>
                  <div>
                    <p className="font-medium text-gray-900">{category.workshops} workshops</p>
                    <p className="text-sm text-gray-600">
                      Avg. {formatCurrency(category.averagePrice)} • {category.capacity}% capacity
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-gray-900">{formatCurrency(category.revenue)}</p>
                  <div className="flex items-center text-sm text-gray-600">
                    <TrendingUp className="h-3 w-3 mr-1" />
                    {Math.round((category.revenue / data.totalRevenue) * 100)}% of total
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Top Performing Workshops */}
      <Card>
        <CardHeader>
          <CardTitle>Top Performing Workshops</CardTitle>
          <CardDescription>Your most successful creative workshops</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {data.topWorkshops.map((workshop, index) => (
              <motion.div
                key={workshop.id}
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ delay: index * 0.1 }}
                className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center space-x-4">
                  <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                    <span className="font-bold text-blue-600">#{index + 1}</span>
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{workshop.name}</p>
                    <p className="text-sm text-gray-600">
                      {workshop.instructor} • {workshop.bookings} bookings
                    </p>
                  </div>
                  <Badge variant={workshop.category as any}>
                    {workshop.category}
                  </Badge>
                </div>
                <div className="text-right flex items-center space-x-4">
                  <div className="flex items-center">
                    <Star className="h-4 w-4 text-yellow-400 fill-current mr-1" />
                    <span className="text-sm font-medium">{workshop.rating}</span>
                  </div>
                  <p className="font-bold text-gray-900">{formatCurrency(workshop.revenue)}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}