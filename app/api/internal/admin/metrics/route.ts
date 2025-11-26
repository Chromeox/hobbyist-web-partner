/**
 * Platform Metrics API
 *
 * Provides platform-wide analytics for admin dashboard
 * - Total revenue across all studios
 * - Total bookings
 * - Studio/instructor counts
 * - Pending approvals
 */

import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from '@/lib/auth';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase with service role for admin access
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  try {
    // Verify admin authentication (Clerk)
    const session = await getServerSession();

    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json(
        { error: 'Not found' },
        { status: 404 } // Hide existence from non-admins
      );
    }

    // Fetch platform metrics
    const [
      revenueData,
      bookingsData,
      studiosData,
      instructorsData,
    ] = await Promise.all([
      getRevenueMetrics(),
      getBookingMetrics(),
      getStudioMetrics(),
      getInstructorMetrics(),
    ]);

    const pendingApprovals = (studiosData.pending || 0) + (instructorsData.pending || 0);

    return NextResponse.json({
      revenue: revenueData,
      bookings: bookingsData,
      studios: studiosData,
      instructors: instructorsData,
      pendingApprovals,
    });

  } catch (error: any) {
    console.error('[Admin Metrics API] Error:', error);
    return NextResponse.json(
      { error: 'Failed to load metrics' },
      { status: 500 }
    );
  }
}

async function getRevenueMetrics() {
  try {
    // Get total revenue from all bookings
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('amount_paid')
      .eq('status', 'completed');

    if (error) throw error;

    const total = bookings?.reduce((sum, b) => sum + (b.amount_paid || 0), 0) || 0;
    const platformCommission = total * 0.15; // 15% platform commission

    // TODO: Calculate actual change from previous period
    const change = 12.5; // Placeholder

    return {
      total: Math.round(total * 100) / 100,
      change,
      platformCommission: Math.round(platformCommission * 100) / 100,
    };
  } catch (error) {
    console.error('Revenue metrics error:', error);
    return { total: 0, change: 0, platformCommission: 0 };
  }
}

async function getBookingMetrics() {
  try {
    const { data: allBookings, error } = await supabase
      .from('bookings')
      .select('status');

    if (error) throw error;

    const completed = allBookings?.filter(b => b.status === 'completed').length || 0;
    const upcoming = allBookings?.filter(b => b.status === 'confirmed').length || 0;
    const total = allBookings?.length || 0;

    // TODO: Calculate actual change from previous period
    const change = 8.3; // Placeholder

    return {
      total,
      change,
      completed,
      upcoming,
    };
  } catch (error) {
    console.error('Booking metrics error:', error);
    return { total: 0, change: 0, completed: 0, upcoming: 0 };
  }
}

async function getStudioMetrics() {
  try {
    const { data: studios, error } = await supabase
      .from('studios')
      .select('approval_status, is_active');

    if (error) throw error;

    const total = studios?.length || 0;
    const active = studios?.filter(s => s.is_active).length || 0;
    const pending = studios?.filter(s => s.approval_status === 'pending').length || 0;

    return {
      total,
      active,
      pending,
    };
  } catch (error) {
    console.error('Studio metrics error:', error);
    return { total: 0, active: 0, pending: 0 };
  }
}

async function getInstructorMetrics() {
  try {
    const { data: instructors, error } = await supabase
      .from('instructor_profiles')
      .select('is_active');

    if (error) {
      // Table might not exist yet
      return { total: 0, active: 0, pending: 0 };
    }

    const total = instructors?.length || 0;
    const active = instructors?.filter(i => i.is_active).length || 0;

    // Get pending instructor applications
    const { data: applications } = await supabase
      .from('instructor_applications')
      .select('status')
      .eq('status', 'pending');

    const pending = applications?.length || 0;

    return {
      total,
      active,
      pending,
    };
  } catch (error) {
    console.error('Instructor metrics error:', error);
    return { total: 0, active: 0, pending: 0 };
  }
}
