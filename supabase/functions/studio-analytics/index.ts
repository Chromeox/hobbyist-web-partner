// Studio Analytics & Revenue Reporting Edge Function
// Provides revenue metrics, commission tracking, and simplified analytics for partner portal

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { 
  createSupabaseClient, 
  corsHeaders, 
  createResponse, 
  errorResponse, 
  getUserId, 
  formatDate,
  addDays
} from '../_shared/utils.ts';
import { StudioRevenueMetrics } from '../_shared/types.ts';

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/studio-analytics', '');

  try {
    const authHeader = req.headers.get('Authorization');

    if (method !== 'GET') {
      return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }

    // Route requests
    switch (path) {
      case '/revenue':
        return handleGetRevenueMetrics(req, authHeader);
      case '/commission-summary':
        return handleGetCommissionSummary(req, authHeader);
      case '/booking-trends':
        return handleGetBookingTrends(req, authHeader);
      case '/credit-pack-sales':
        return handleGetCreditPackSales(req, authHeader);
      case '/instructor-payouts':
        return handleGetInstructorPayouts(req, authHeader);
      default:
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
    }
  } catch (error) {
    console.error('Studio analytics function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleGetRevenueMetrics(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const periodDays = parseInt(url.searchParams.get('period_days') || '30');
  const startDate = url.searchParams.get('start_date');
  const endDate = url.searchParams.get('end_date');
  
  const supabase = createSupabaseClient();

  try {
    // Verify user has access to analytics (instructor or admin)
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();

    if (userError || !['instructor', 'admin'].includes(user.role)) {
      return errorResponse('Insufficient permissions', 'FORBIDDEN', 403);
    }

    // Calculate date range
    const endDateTime = endDate ? new Date(endDate) : new Date();
    const startDateTime = startDate ? new Date(startDate) : addDays(endDateTime, -periodDays);

    // Get revenue metrics from bookings
    const { data: bookingMetrics, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        amount,
        commission_amount,
        instructor_payout,
        payment_method,
        credits_used,
        status,
        payment_status,
        created_at,
        class:classes!inner(
          instructor_id,
          instructor:instructor_profiles!inner(user_id)
        )
      `)
      .gte('created_at', startDateTime.toISOString())
      .lte('created_at', endDateTime.toISOString())
      .eq('payment_status', 'succeeded');

    if (bookingError) {
      return errorResponse('Failed to fetch booking metrics', 'FETCH_ERROR', 500);
    }

    // Get credit pack sales
    const { data: creditPackSales, error: salesError } = await supabase
      .from('credit_pack_purchases')
      .select(`
        amount_paid_cents,
        credits_received,
        bonus_credits,
        status,
        created_at
      `)
      .gte('created_at', startDateTime.toISOString())
      .lte('created_at', endDateTime.toISOString())
      .eq('status', 'completed');

    if (salesError) {
      return errorResponse('Failed to fetch credit pack sales', 'FETCH_ERROR', 500);
    }

    // Calculate metrics
    const filteredBookings = user.role === 'admin' 
      ? bookingMetrics 
      : bookingMetrics?.filter(booking => booking.class.instructor.user_id === userId) || [];

    const totalRevenue = filteredBookings.reduce((sum, booking) => sum + booking.amount, 0);
    const totalCommission = filteredBookings.reduce((sum, booking) => sum + booking.commission_amount, 0);
    const totalInstructorPayouts = filteredBookings.reduce((sum, booking) => sum + booking.instructor_payout, 0);
    const totalBookings = filteredBookings.length;
    const creditBookings = filteredBookings.filter(b => b.payment_method === 'credits').length;
    const cardBookings = totalBookings - creditBookings;

    const creditPackRevenue = creditPackSales?.reduce((sum, sale) => sum + sale.amount_paid_cents, 0) || 0;
    const creditPackSalesCount = creditPackSales?.length || 0;

    const metrics: StudioRevenueMetrics = {
      total_revenue_cents: totalRevenue + creditPackRevenue,
      total_commission_cents: totalCommission + Math.round(creditPackRevenue * 0.15), // 15% on credit sales too
      total_instructor_payouts_cents: totalInstructorPayouts,
      total_bookings: totalBookings,
      credit_pack_sales: creditPackSalesCount,
      credit_bookings: creditBookings,
      card_bookings: cardBookings,
      period_start: startDateTime.toISOString(),
      period_end: endDateTime.toISOString(),
    };

    const enhancedMetrics = {
      ...metrics,
      total_revenue_formatted: ((totalRevenue + creditPackRevenue) / 100).toFixed(2),
      total_commission_formatted: ((totalCommission + Math.round(creditPackRevenue * 0.15)) / 100).toFixed(2),
      total_instructor_payouts_formatted: (totalInstructorPayouts / 100).toFixed(2),
      credit_pack_revenue_formatted: (creditPackRevenue / 100).toFixed(2),
      average_booking_value: totalBookings > 0 ? (totalRevenue / totalBookings / 100).toFixed(2) : '0.00',
      commission_rate: '15.0%',
      period_days: Math.ceil((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60 * 24)),
    };

    return createResponse(enhancedMetrics);
  } catch (error) {
    console.error('Get revenue metrics error:', error);
    return errorResponse('Failed to get revenue metrics', 'FETCH_ERROR', 500);
  }
}

async function handleGetCommissionSummary(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const groupBy = url.searchParams.get('group_by') || 'day'; // day, week, month
  const periodDays = parseInt(url.searchParams.get('period_days') || '30');
  
  const supabase = createSupabaseClient();

  try {
    // Verify permissions
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();

    if (userError || !['instructor', 'admin'].includes(user.role)) {
      return errorResponse('Insufficient permissions', 'FORBIDDEN', 403);
    }

    const endDate = new Date();
    const startDate = addDays(endDate, -periodDays);

    // Get commission data grouped by time period
    let dateFormat = 'YYYY-MM-DD';
    let truncFormat = 'day';
    
    if (groupBy === 'week') {
      truncFormat = 'week';
      dateFormat = 'YYYY-MM-DD';
    } else if (groupBy === 'month') {
      truncFormat = 'month';
      dateFormat = 'YYYY-MM';
    }

    const { data: commissionData, error } = await supabase
      .rpc('get_commission_summary', {
        p_start_date: startDate.toISOString(),
        p_end_date: endDate.toISOString(),
        p_group_by: truncFormat,
        p_instructor_id: user.role === 'instructor' ? userId : null
      });

    if (error) {
      console.error('Commission summary query error:', error);
      return errorResponse('Failed to get commission summary', 'FETCH_ERROR', 500);
    }

    const summary = commissionData?.map((item: any) => ({
      period: formatDate(new Date(item.period), dateFormat),
      total_bookings: item.booking_count || 0,
      total_revenue_cents: item.total_revenue || 0,
      total_commission_cents: item.total_commission || 0,
      total_instructor_payouts_cents: item.total_payouts || 0,
      total_revenue_formatted: ((item.total_revenue || 0) / 100).toFixed(2),
      total_commission_formatted: ((item.total_commission || 0) / 100).toFixed(2),
      commission_rate: '15.0%',
    })) || [];

    return createResponse({
      period_days: periodDays,
      group_by: groupBy,
      data: summary,
      total_periods: summary.length,
    });
  } catch (error) {
    console.error('Get commission summary error:', error);
    return errorResponse('Failed to get commission summary', 'FETCH_ERROR', 500);
  }
}

async function handleGetBookingTrends(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const periodDays = parseInt(url.searchParams.get('period_days') || '30');
  
  const supabase = createSupabaseClient();

  try {
    const endDate = new Date();
    const startDate = addDays(endDate, -periodDays);

    const { data: bookingTrends, error } = await supabase
      .from('bookings')
      .select(`
        created_at,
        payment_method,
        credits_used,
        amount,
        status,
        class:classes!inner(
          title,
          instructor:instructor_profiles!inner(user_id)
        )
      `)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString())
      .eq('payment_status', 'succeeded')
      .order('created_at', { ascending: true });

    if (error) {
      return errorResponse('Failed to fetch booking trends', 'FETCH_ERROR', 500);
    }

    // Group bookings by day and payment method
    const trends: Record<string, any> = {};
    
    bookingTrends?.forEach((booking) => {
      const date = formatDate(new Date(booking.created_at), 'YYYY-MM-DD');
      
      if (!trends[date]) {
        trends[date] = {
          date,
          total_bookings: 0,
          card_bookings: 0,
          credit_bookings: 0,
          total_revenue_cents: 0,
        };
      }
      
      trends[date].total_bookings += 1;
      trends[date].total_revenue_cents += booking.amount;
      
      if (booking.payment_method === 'credits') {
        trends[date].credit_bookings += 1;
      } else {
        trends[date].card_bookings += 1;
      }
    });

    const trendData = Object.values(trends).map((trend: any) => ({
      ...trend,
      total_revenue_formatted: (trend.total_revenue_cents / 100).toFixed(2),
    }));

    return createResponse({
      period_days: periodDays,
      data: trendData,
    });
  } catch (error) {
    console.error('Get booking trends error:', error);
    return errorResponse('Failed to get booking trends', 'FETCH_ERROR', 500);
  }
}

async function handleGetCreditPackSales(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const periodDays = parseInt(url.searchParams.get('period_days') || '30');
  
  const supabase = createSupabaseClient();

  try {
    // Verify admin permissions for credit pack sales data
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();

    if (userError || user.role !== 'admin') {
      return errorResponse('Admin permissions required', 'FORBIDDEN', 403);
    }

    const endDate = new Date();
    const startDate = addDays(endDate, -periodDays);

    const { data: creditPackSales, error } = await supabase
      .from('credit_pack_purchases')
      .select(`
        *,
        credit_pack:credit_packs!inner(name, credit_amount, bonus_credits)
      `)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString())
      .eq('status', 'completed')
      .order('created_at', { ascending: false });

    if (error) {
      return errorResponse('Failed to fetch credit pack sales', 'FETCH_ERROR', 500);
    }

    // Group sales by credit pack
    const salesByPack: Record<string, any> = {};
    let totalSales = 0;
    let totalRevenue = 0;

    creditPackSales?.forEach((sale) => {
      const packName = sale.credit_pack.name;
      
      if (!salesByPack[packName]) {
        salesByPack[packName] = {
          pack_name: packName,
          total_sales: 0,
          total_revenue_cents: 0,
          total_credits_sold: 0,
        };
      }
      
      salesByPack[packName].total_sales += 1;
      salesByPack[packName].total_revenue_cents += sale.amount_paid_cents;
      salesByPack[packName].total_credits_sold += (sale.credits_received + sale.bonus_credits);
      
      totalSales += 1;
      totalRevenue += sale.amount_paid_cents;
    });

    const salesData = Object.values(salesByPack).map((pack: any) => ({
      ...pack,
      total_revenue_formatted: (pack.total_revenue_cents / 100).toFixed(2),
    }));

    return createResponse({
      period_days: periodDays,
      total_sales: totalSales,
      total_revenue_cents: totalRevenue,
      total_revenue_formatted: (totalRevenue / 100).toFixed(2),
      sales_by_pack: salesData,
    });
  } catch (error) {
    console.error('Get credit pack sales error:', error);
    return errorResponse('Failed to get credit pack sales', 'FETCH_ERROR', 500);
  }
}

async function handleGetInstructorPayouts(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  
  const supabase = createSupabaseClient();

  try {
    // Get instructor payouts
    const { data: payouts, error } = await supabase
      .from('instructor_payouts')
      .select(`
        *,
        instructor:instructor_profiles!inner(
          business_name,
          user:user_profiles!inner(first_name, last_name, email)
        )
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return errorResponse('Failed to fetch instructor payouts', 'FETCH_ERROR', 500);
    }

    const enhancedPayouts = payouts?.map((payout) => ({
      ...payout,
      amount_formatted: (payout.amount / 100).toFixed(2),
      instructor_name: payout.instructor.business_name || 
                      `${payout.instructor.user.first_name} ${payout.instructor.user.last_name}`,
      bookings_count: payout.bookings?.length || 0,
    }));

    return createResponse(enhancedPayouts);
  } catch (error) {
    console.error('Get instructor payouts error:', error);
    return errorResponse('Failed to get instructor payouts', 'FETCH_ERROR', 500);
  }
}