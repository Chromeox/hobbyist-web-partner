'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  Filter,
  Star,
  MessageCircle,
  ThumbsUp,
  ThumbsDown,
  Flag,
  Eye,
  EyeOff,
  Calendar,
  User,
  Image as ImageIcon,
  Video,
  Tag,
  MoreVertical,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Reply,
  Edit,
  Trash2,
  Download,
  RefreshCw,
  ChevronDown,
  SortAsc,
  SortDesc
} from 'lucide-react';
import BackButton from '@/components/common/BackButton';
import RatingStars from './RatingStars';
import ReviewModal, { ReviewSubmissionData } from './ReviewModal';
import { MetricCard } from '@/components/dashboard/MetricCard';

interface Review {
  id: string;
  classId: string;
  className: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  instructorId: string;
  instructorName: string;
  rating: number;
  reviewText: string;
  verifiedBooking: boolean;
  isAnonymous: boolean;
  isApproved: boolean;
  createdAt: string;
  updatedAt: string;
  tags: string[];
  media: ReviewMedia[];
  votes: ReviewVotes;
  response?: InstructorResponse;
  moderationStatus?: 'approved' | 'rejected' | 'flagged' | 'under_review';
  moderationReason?: string;
}

interface ReviewMedia {
  id: string;
  type: 'photo' | 'video';
  url: string;
  thumbnailUrl?: string;
  name: string;
}

interface ReviewVotes {
  helpful: number;
  notHelpful: number;
  userVote?: 'helpful' | 'not_helpful' | null;
}

interface InstructorResponse {
  id: string;
  instructorId: string;
  responseText: string;
  createdAt: string;
  updatedAt: string;
}

interface FilterState {
  search: string;
  rating: number | null;
  status: 'all' | 'approved' | 'pending' | 'flagged' | 'rejected';
  hasResponse: boolean | null;
  verifiedOnly: boolean;
  dateRange: 'all' | '7d' | '30d' | '90d' | 'custom';
  sortBy: 'date' | 'rating' | 'helpful';
  sortOrder: 'asc' | 'desc';
}

const ReviewManagement: React.FC = () => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [filteredReviews, setFilteredReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReviews, setSelectedReviews] = useState<Set<string>>(new Set());
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    rating: null,
    status: 'all',
    hasResponse: null,
    verifiedOnly: false,
    dateRange: 'all',
    sortBy: 'date',
    sortOrder: 'desc'
  });

  // Modal states
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [selectedReview, setSelectedReview] = useState<Review | null>(null);
  const [responseModal, setResponseModal] = useState<{ reviewId: string; existingResponse?: string } | null>(null);
  const [showFilters, setShowFilters] = useState(false);

  // Load reviews
  useEffect(() => {
    loadReviews();
  }, []);

  const loadReviews = async () => {
    setLoading(true);
    try {
      // Mock data for development - replace with actual API call
      const mockReviews: Review[] = [
        {
          id: '1',
          classId: 'class-1',
          className: 'Morning Yoga Flow',
          userId: 'user-1',
          userName: 'Sarah Johnson',
          userAvatar: '/api/placeholder/32/32',
          instructorId: 'instructor-1',
          instructorName: 'Lisa Chen',
          rating: 5,
          reviewText: 'Amazing class! Lisa is an incredible instructor who really knows how to create a welcoming environment for all skill levels. The studio is clean and well-equipped.',
          verifiedBooking: true,
          isAnonymous: false,
          isApproved: true,
          createdAt: '2024-01-15T10:30:00Z',
          updatedAt: '2024-01-15T10:30:00Z',
          tags: ['Great instructor', 'Clean facility', 'Beginner friendly'],
          media: [
            {
              id: 'media-1',
              type: 'photo',
              url: '/api/placeholder/300/200',
              name: 'studio-photo.jpg'
            }
          ],
          votes: {
            helpful: 12,
            notHelpful: 1,
            userVote: null
          },
          response: {
            id: 'response-1',
            instructorId: 'instructor-1',
            responseText: 'Thank you so much for the kind words, Sarah! We\'re thrilled you enjoyed the class.',
            createdAt: '2024-01-16T09:00:00Z',
            updatedAt: '2024-01-16T09:00:00Z'
          }
        },
        {
          id: '2',
          classId: 'class-2',
          className: 'HIIT Training',
          userId: 'user-2',
          userName: 'Anonymous User',
          instructorId: 'instructor-2',
          instructorName: 'Mike Rodriguez',
          rating: 4,
          reviewText: 'Great workout, very challenging but the instructor was supportive throughout. Could use better ventilation in the studio.',
          verifiedBooking: true,
          isAnonymous: true,
          isApproved: true,
          createdAt: '2024-01-10T18:45:00Z',
          updatedAt: '2024-01-10T18:45:00Z',
          tags: ['Challenging workout', 'Great instructor'],
          media: [],
          votes: {
            helpful: 8,
            notHelpful: 2,
            userVote: null
          }
        },
        {
          id: '3',
          classId: 'class-3',
          className: 'Pottery Basics',
          userId: 'user-3',
          userName: 'David Kim',
          instructorId: 'instructor-3',
          instructorName: 'Emma Thompson',
          rating: 3,
          reviewText: 'The class was okay, but I felt rushed. The instructor seemed distracted and didn\'t give much individual attention.',
          verifiedBooking: false,
          isAnonymous: false,
          isApproved: false,
          createdAt: '2024-01-08T14:20:00Z',
          updatedAt: '2024-01-08T14:20:00Z',
          tags: ['Needs improvement'],
          media: [],
          votes: {
            helpful: 3,
            notHelpful: 7,
            userVote: null
          },
          moderationStatus: 'under_review',
          moderationReason: 'Flagged for potentially inappropriate content'
        }
      ];

      setReviews(mockReviews);
    } catch (error) {
      console.error('Failed to load reviews:', error);
    } finally {
      setLoading(false);
    }
  };

  // Filter and sort reviews
  const applyFilters = useCallback(() => {
    let filtered = [...reviews];

    // Search filter
    if (filters.search) {
      const searchLower = filters.search.toLowerCase();
      filtered = filtered.filter(review =>
        review.reviewText.toLowerCase().includes(searchLower) ||
        review.className.toLowerCase().includes(searchLower) ||
        review.userName.toLowerCase().includes(searchLower) ||
        review.instructorName.toLowerCase().includes(searchLower) ||
        review.tags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    }

    // Rating filter
    if (filters.rating !== null) {
      filtered = filtered.filter(review => review.rating === filters.rating);
    }

    // Status filter
    if (filters.status !== 'all') {
      switch (filters.status) {
        case 'approved':
          filtered = filtered.filter(review => review.isApproved);
          break;
        case 'pending':
          filtered = filtered.filter(review => !review.isApproved && !review.moderationStatus);
          break;
        case 'flagged':
          filtered = filtered.filter(review => review.moderationStatus === 'flagged');
          break;
        case 'rejected':
          filtered = filtered.filter(review => review.moderationStatus === 'rejected');
          break;
      }
    }

    // Response filter
    if (filters.hasResponse !== null) {
      filtered = filtered.filter(review => filters.hasResponse ? !!review.response : !review.response);
    }

    // Verified booking filter
    if (filters.verifiedOnly) {
      filtered = filtered.filter(review => review.verifiedBooking);
    }

    // Date range filter
    if (filters.dateRange !== 'all') {
      const now = new Date();
      let startDate: Date;
      
      switch (filters.dateRange) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(0);
      }
      
      filtered = filtered.filter(review => new Date(review.createdAt) >= startDate);
    }

    // Sort
    filtered.sort((a, b) => {
      let aValue: any, bValue: any;
      
      switch (filters.sortBy) {
        case 'rating':
          aValue = a.rating;
          bValue = b.rating;
          break;
        case 'helpful':
          aValue = a.votes.helpful;
          bValue = b.votes.helpful;
          break;
        default:
          aValue = new Date(a.createdAt);
          bValue = new Date(b.createdAt);
      }

      if (filters.sortOrder === 'asc') {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      }
    });

    setFilteredReviews(filtered);
  }, [reviews, filters]);

  useEffect(() => {
    applyFilters();
  }, [applyFilters]);

  // Handle review selection
  const toggleReviewSelection = useCallback((reviewId: string) => {
    setSelectedReviews(prev => {
      const newSet = new Set(prev);
      if (newSet.has(reviewId)) {
        newSet.delete(reviewId);
      } else {
        newSet.add(reviewId);
      }
      return newSet;
    });
  }, []);

  const selectAllReviews = useCallback(() => {
    setSelectedReviews(new Set(filteredReviews.map(r => r.id)));
  }, [filteredReviews]);

  const clearSelection = useCallback(() => {
    setSelectedReviews(new Set());
  }, []);

  // Handle bulk actions
  const handleBulkApprove = useCallback(async () => {
    try {
      // API call to approve selected reviews
      console.log('Approving reviews:', Array.from(selectedReviews));
      // Update local state
      setReviews(prev => prev.map(review => 
        selectedReviews.has(review.id) 
          ? { ...review, isApproved: true, moderationStatus: 'approved' }
          : review
      ));
      clearSelection();
    } catch (error) {
      console.error('Failed to approve reviews:', error);
    }
  }, [selectedReviews, clearSelection]);

  const handleBulkReject = useCallback(async () => {
    try {
      // API call to reject selected reviews
      console.log('Rejecting reviews:', Array.from(selectedReviews));
      setReviews(prev => prev.map(review => 
        selectedReviews.has(review.id) 
          ? { ...review, isApproved: false, moderationStatus: 'rejected' }
          : review
      ));
      clearSelection();
    } catch (error) {
      console.error('Failed to reject reviews:', error);
    }
  }, [selectedReviews, clearSelection]);

  // Handle individual review actions
  const handleReviewAction = useCallback(async (reviewId: string, action: string) => {
    try {
      switch (action) {
        case 'approve':
          setReviews(prev => prev.map(r => 
            r.id === reviewId ? { ...r, isApproved: true, moderationStatus: 'approved' } : r
          ));
          break;
        case 'reject':
          setReviews(prev => prev.map(r => 
            r.id === reviewId ? { ...r, isApproved: false, moderationStatus: 'rejected' } : r
          ));
          break;
        case 'flag':
          setReviews(prev => prev.map(r => 
            r.id === reviewId ? { ...r, moderationStatus: 'flagged' } : r
          ));
          break;
      }
    } catch (error) {
      console.error('Failed to update review:', error);
    }
  }, []);

  // Handle instructor response
  const handleInstructorResponse = useCallback(async (reviewId: string, responseText: string) => {
    try {
      const newResponse: InstructorResponse = {
        id: `response-${Date.now()}`,
        instructorId: 'current-instructor', // Get from auth context
        responseText,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      setReviews(prev => prev.map(r => 
        r.id === reviewId ? { ...r, response: newResponse } : r
      ));
      
      setResponseModal(null);
    } catch (error) {
      console.error('Failed to save response:', error);
    }
  }, []);

  // Format date
  const formatDate = useCallback((dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  }, []);

  // Statistics
  const stats = useMemo(() => {
    const total = reviews.length;
    const approved = reviews.filter(r => r.isApproved).length;
    const pending = reviews.filter(r => !r.isApproved && !r.moderationStatus).length;
    const averageRating = reviews.length > 0 
      ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
      : '0.0';
    const responseRate = total > 0 
      ? Math.round((reviews.filter(r => r.response).length / total) * 100)
      : 0;

    return { total, approved, pending, averageRating, responseRate };
  }, [reviews]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading reviews...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <BackButton href="/dashboard" className="mb-4" />
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Reviews & Ratings
          </h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">
            Manage customer reviews and respond to feedback
          </p>
        </div>
        <button
          onClick={() => loadReviews()}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <RefreshCw size={20} />
          Refresh
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <MetricCard
          label="Total Reviews"
          value={stats.total}
          icon={MessageCircle}
          color="blue"
        />
        <MetricCard
          label="Average Rating"
          value={stats.averageRating}
          icon={Star}
          color="yellow"
        />
        <MetricCard
          label="Approved"
          value={stats.approved}
          icon={CheckCircle}
          color="green"
        />
        <MetricCard
          label="Pending"
          value={stats.pending}
          icon={AlertTriangle}
          color="orange"
        />
        <MetricCard
          label="Response Rate"
          value={`${stats.responseRate}%`}
          icon={Reply}
          color="blue"
        />
      </div>

      {/* Filters and Search */}
      <div className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Search reviews, classes, or instructors..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                value={filters.search}
                onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
              />
            </div>
          </div>

          {/* Quick Filters */}
          <div className="flex gap-2">
            <select
              value={filters.status}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value as any }))}
              className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
            >
              <option value="all">All Status</option>
              <option value="approved">Approved</option>
              <option value="pending">Pending</option>
              <option value="flagged">Flagged</option>
              <option value="rejected">Rejected</option>
            </select>

            <select
              value={filters.rating || ''}
              onChange={(e) => setFilters(prev => ({ ...prev, rating: e.target.value ? parseInt(e.target.value) : null }))}
              className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
            >
              <option value="">All Ratings</option>
              <option value="5">5 Stars</option>
              <option value="4">4 Stars</option>
              <option value="3">3 Stars</option>
              <option value="2">2 Stars</option>
              <option value="1">1 Star</option>
            </select>

            <button
              onClick={() => setShowFilters(!showFilters)}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
            >
              <Filter size={20} />
              More Filters
              <ChevronDown className={`transition-transform ${showFilters ? 'rotate-180' : ''}`} size={16} />
            </button>
          </div>
        </div>

        {/* Advanced Filters */}
        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700"
            >
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Response Status
                  </label>
                  <select
                    value={filters.hasResponse === null ? '' : filters.hasResponse ? 'true' : 'false'}
                    onChange={(e) => setFilters(prev => ({ 
                      ...prev, 
                      hasResponse: e.target.value === '' ? null : e.target.value === 'true' 
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  >
                    <option value="">All Reviews</option>
                    <option value="true">Has Response</option>
                    <option value="false">No Response</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Date Range
                  </label>
                  <select
                    value={filters.dateRange}
                    onChange={(e) => setFilters(prev => ({ ...prev, dateRange: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  >
                    <option value="all">All Time</option>
                    <option value="7d">Last 7 Days</option>
                    <option value="30d">Last 30 Days</option>
                    <option value="90d">Last 90 Days</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Sort By
                  </label>
                  <select
                    value={filters.sortBy}
                    onChange={(e) => setFilters(prev => ({ ...prev, sortBy: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  >
                    <option value="date">Date</option>
                    <option value="rating">Rating</option>
                    <option value="helpful">Helpful Votes</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Order
                  </label>
                  <button
                    onClick={() => setFilters(prev => ({ 
                      ...prev, 
                      sortOrder: prev.sortOrder === 'asc' ? 'desc' : 'asc' 
                    }))}
                    className="w-full flex items-center justify-center gap-2 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors dark:bg-gray-700 dark:text-white"
                  >
                    {filters.sortOrder === 'asc' ? <SortAsc size={16} /> : <SortDesc size={16} />}
                    {filters.sortOrder === 'asc' ? 'Ascending' : 'Descending'}
                  </button>
                </div>
              </div>

              <div className="mt-4">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={filters.verifiedOnly}
                    onChange={(e) => setFilters(prev => ({ ...prev, verifiedOnly: e.target.checked }))}
                    className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    Show only verified bookings
                  </span>
                </label>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Bulk Actions */}
      {selectedReviews.size > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg border border-blue-200 dark:border-blue-800"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <span className="text-sm text-blue-800 dark:text-blue-300">
                {selectedReviews.size} review{selectedReviews.size !== 1 ? 's' : ''} selected
              </span>
              <div className="flex items-center gap-2">
                <button
                  onClick={handleBulkApprove}
                  className="flex items-center gap-1 px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 transition-colors"
                >
                  <CheckCircle size={16} />
                  Approve
                </button>
                <button
                  onClick={handleBulkReject}
                  className="flex items-center gap-1 px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition-colors"
                >
                  <XCircle size={16} />
                  Reject
                </button>
              </div>
            </div>
            <button
              onClick={clearSelection}
              className="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
            >
              Clear Selection
            </button>
          </div>
        </motion.div>
      )}

      {/* Reviews List */}
      <div className="space-y-4">
        {filteredReviews.length === 0 ? (
          <div className="text-center py-12">
            <MessageCircle className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-white">
              No reviews found
            </h3>
            <p className="mt-2 text-gray-600 dark:text-gray-400">
              {filters.search || filters.rating || filters.status !== 'all'
                ? 'Try adjusting your filters to see more reviews.'
                : 'Reviews will appear here once customers start leaving feedback.'
              }
            </p>
          </div>
        ) : (
          filteredReviews.map(review => (
            <motion.div
              key={review.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className={`bg-white dark:bg-gray-800 p-6 rounded-xl border-2 transition-all ${
                selectedReviews.has(review.id)
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/10'
                  : 'border-gray-200 dark:border-gray-700'
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Selection Checkbox */}
                <input
                  type="checkbox"
                  checked={selectedReviews.has(review.id)}
                  onChange={() => toggleReviewSelection(review.id)}
                  className="mt-1 w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                />

                {/* User Avatar */}
                <div className="flex-shrink-0">
                  {review.isAnonymous ? (
                    <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center">
                      <EyeOff size={16} className="text-gray-400" />
                    </div>
                  ) : review.userAvatar ? (
                    <img
                      src={review.userAvatar}
                      alt={review.userName}
                      className="w-10 h-10 rounded-full object-cover"
                    />
                  ) : (
                    <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                      <User size={16} className="text-blue-600 dark:text-blue-400" />
                    </div>
                  )}
                </div>

                {/* Review Content */}
                <div className="flex-1 min-w-0">
                  {/* Header */}
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <div className="flex items-center gap-3">
                        <h3 className="font-medium text-gray-900 dark:text-white">
                          {review.isAnonymous ? 'Anonymous User' : review.userName}
                        </h3>
                        {review.verifiedBooking && (
                          <div className="flex items-center gap-1 px-2 py-1 bg-green-100 dark:bg-green-900/30 rounded-full">
                            <CheckCircle size={12} className="text-green-600 dark:text-green-400" />
                            <span className="text-xs text-green-800 dark:text-green-300 font-medium">
                              Verified
                            </span>
                          </div>
                        )}
                        {!review.isApproved && (
                          <div className="flex items-center gap-1 px-2 py-1 bg-orange-100 dark:bg-orange-900/30 rounded-full">
                            <AlertTriangle size={12} className="text-orange-600 dark:text-orange-400" />
                            <span className="text-xs text-orange-800 dark:text-orange-300 font-medium">
                              Pending
                            </span>
                          </div>
                        )}
                        {review.moderationStatus === 'flagged' && (
                          <div className="flex items-center gap-1 px-2 py-1 bg-red-100 dark:bg-red-900/30 rounded-full">
                            <Flag size={12} className="text-red-600 dark:text-red-400" />
                            <span className="text-xs text-red-800 dark:text-red-300 font-medium">
                              Flagged
                            </span>
                          </div>
                        )}
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        {review.className} • {review.instructorName} • {formatDate(review.createdAt)}
                      </p>
                    </div>

                    {/* Actions Menu */}
                    <div className="flex items-center gap-2">
                      {!review.isApproved && (
                        <>
                          <button
                            onClick={() => handleReviewAction(review.id, 'approve')}
                            className="p-1 text-green-600 hover:bg-green-100 dark:hover:bg-green-900/30 rounded"
                            title="Approve"
                          >
                            <CheckCircle size={16} />
                          </button>
                          <button
                            onClick={() => handleReviewAction(review.id, 'reject')}
                            className="p-1 text-red-600 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                            title="Reject"
                          >
                            <XCircle size={16} />
                          </button>
                        </>
                      )}
                      
                      <button
                        onClick={() => setResponseModal({ 
                          reviewId: review.id, 
                          existingResponse: review.response?.responseText 
                        })}
                        className="p-1 text-blue-600 hover:bg-blue-100 dark:hover:bg-blue-900/30 rounded"
                        title={review.response ? 'Edit Response' : 'Add Response'}
                      >
                        <Reply size={16} />
                      </button>

                      <button
                        onClick={() => handleReviewAction(review.id, 'flag')}
                        className="p-1 text-orange-600 hover:bg-orange-100 dark:hover:bg-orange-900/30 rounded"
                        title="Flag"
                      >
                        <Flag size={16} />
                      </button>
                    </div>
                  </div>

                  {/* Rating */}
                  <div className="mb-3">
                    <RatingStars rating={review.rating} size="md" />
                  </div>

                  {/* Review Text */}
                  <p className="text-gray-800 dark:text-gray-200 mb-4 leading-relaxed">
                    {review.reviewText}
                  </p>

                  {/* Tags */}
                  {review.tags.length > 0 && (
                    <div className="flex flex-wrap gap-2 mb-4">
                      {review.tags.map(tag => (
                        <span
                          key={tag}
                          className="inline-flex items-center gap-1 px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs rounded-full"
                        >
                          <Tag size={10} />
                          {tag}
                        </span>
                      ))}
                    </div>
                  )}

                  {/* Media */}
                  {review.media.length > 0 && (
                    <div className="flex gap-2 mb-4">
                      {review.media.map(media => (
                        <div key={media.id} className="relative">
                          {media.type === 'photo' ? (
                            <img
                              src={media.url}
                              alt="Review media"
                              className="w-16 h-16 object-cover rounded-lg"
                            />
                          ) : (
                            <div className="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                              <Video size={20} className="text-gray-400" />
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Instructor Response */}
                  {review.response && (
                    <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border-l-4 border-blue-500">
                      <div className="flex items-center gap-2 mb-2">
                        <Reply size={16} className="text-blue-600 dark:text-blue-400" />
                        <span className="text-sm font-medium text-blue-800 dark:text-blue-300">
                          Instructor Response
                        </span>
                        <span className="text-xs text-blue-600 dark:text-blue-400">
                          {formatDate(review.response.createdAt)}
                        </span>
                      </div>
                      <p className="text-blue-800 dark:text-blue-300 text-sm">
                        {review.response.responseText}
                      </p>
                    </div>
                  )}

                  {/* Footer */}
                  <div className="flex items-center justify-between mt-4 pt-3 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex items-center gap-4">
                      <button className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400 hover:text-green-600 dark:hover:text-green-400">
                        <ThumbsUp size={16} />
                        {review.votes.helpful}
                      </button>
                      <button className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400">
                        <ThumbsDown size={16} />
                        {review.votes.notHelpful}
                      </button>
                    </div>
                    
                    <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
                      {review.media.length > 0 && (
                        <span className="flex items-center gap-1">
                          <ImageIcon size={12} />
                          {review.media.length}
                        </span>
                      )}
                      <span>ID: {review.id}</span>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>

      {/* Response Modal */}
      {responseModal && (
        <ResponseModal
          isOpen={!!responseModal}
          onClose={() => setResponseModal(null)}
          onSubmit={(response) => handleInstructorResponse(responseModal.reviewId, response)}
          existingResponse={responseModal.existingResponse}
        />
      )}

      {/* Review Modal */}
      {showReviewModal && (
        <ReviewModal
          isOpen={showReviewModal}
          onClose={() => {
            setShowReviewModal(false);
            setSelectedReview(null);
          }}
          onSubmit={async (data: ReviewSubmissionData) => {
            console.log('Review submission:', data);
            // Handle review submission
          }}
          classId={selectedReview?.classId || ''}
          existingReview={selectedReview ? {
            id: selectedReview.id,
            rating: selectedReview.rating,
            reviewText: selectedReview.reviewText,
            isAnonymous: selectedReview.isAnonymous,
            tags: selectedReview.tags,
            media: selectedReview.media.map((media) => ({
              id: media.id,
              type: media.type,
              url: media.url,
              thumbnailUrl: media.thumbnailUrl,
              name: media.name,
              size: 0
            })),
            verifiedBooking: selectedReview.verifiedBooking
          } : null}
        />
      )}
    </div>
  );
};

// Response Modal Component
interface ResponseModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (response: string) => void;
  existingResponse?: string;
}

const ResponseModal: React.FC<ResponseModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  existingResponse = ''
}) => {
  const [response, setResponse] = useState(existingResponse);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!response.trim()) return;
    
    setIsSubmitting(true);
    try {
      await onSubmit(response.trim());
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <motion.div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
    >
      <motion.div
        className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl w-full max-w-md"
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            {existingResponse ? 'Edit Response' : 'Respond to Review'}
          </h3>
          
          <textarea
            value={response}
            onChange={(e) => setResponse(e.target.value)}
            placeholder="Write your response..."
            rows={4}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none dark:bg-gray-700 dark:text-white"
            disabled={isSubmitting}
          />
          
          <div className="flex items-center justify-end gap-3 mt-4">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={!response.trim() || isSubmitting}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Saving...
                </>
              ) : (
                <>
                  <Reply size={16} />
                  {existingResponse ? 'Update' : 'Respond'}
                </>
              )}
            </button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
};

export default ReviewManagement;
