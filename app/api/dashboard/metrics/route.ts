import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { resolveDashboardPeriod, type DashboardPeriod } from '@/lib/utils/dateRange'

type MetricsKpiRow = {
  revenue: number | null
  booking_count: number | null
  unique_schedules: number | null
  unique_instructors: number | null
}

const parsePeriod = (value: string | null): DashboardPeriod => {
  if (!value) return 'week'
  const allowed: DashboardPeriod[] = ['today', 'week', 'month', 'year', 'custom']
  return allowed.includes(value as DashboardPeriod) ? (value as DashboardPeriod) : 'week'
}

const calculateDeltaPercent = (current: number, previous: number): number => {
  if (previous === 0) {
    return current === 0 ? 0 : 100
  }
  return ((current - previous) / previous) * 100
}

const aggregateMetrics = (rows: MetricsKpiRow[] | null) => {
  return (rows ?? []).reduce(
    (acc, row) => {
      const revenue = row.revenue ?? 0
      const bookings = row.booking_count ?? 0
      const schedules = row.unique_schedules ?? 0
      const instructors = row.unique_instructors ?? 0

      return {
        revenue: acc.revenue + revenue,
        bookings: acc.bookings + bookings,
        schedules: Math.max(acc.schedules, schedules),
        instructors: Math.max(acc.instructors, instructors)
      }
    },
    { revenue: 0, bookings: 0, schedules: 0, instructors: 0 }
  )
}

export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    const studioId = searchParams.get('studioId')
    const period = parsePeriod(searchParams.get('period'))
    const customStart = searchParams.get('startDate')
    const customEnd = searchParams.get('endDate')

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const resolved = resolveDashboardPeriod(period, { startDate: customStart, endDate: customEnd })
    const metricsColumns = 'revenue, booking_count, unique_schedules, unique_instructors'

    const [currentResult, previousResult] = (await Promise.all([
      (supabase as any)
        .from('v_studio_metrics_daily')
        .select(metricsColumns)
        .eq('studio_id', studioId)
        .gte('bucket_date', resolved.current.start)
        .lte('bucket_date', resolved.current.end),
      (supabase as any)
        .from('v_studio_metrics_daily')
        .select(metricsColumns)
        .eq('studio_id', studioId)
        .gte('bucket_date', resolved.previous.start)
        .lte('bucket_date', resolved.previous.end)
    ])) as Array<{ data: MetricsKpiRow[] | null; error: any }>

    const { data: currentRows, error: currentError } = currentResult
    const { data: previousRows, error: previousError } = previousResult

    if (currentError || previousError) {
      throw currentError ?? previousError
    }

    const currentTotals = aggregateMetrics(currentRows)
    const previousTotals = aggregateMetrics(previousRows)

    const periodLabel = period === 'custom' ? 'Custom Range' : period.charAt(0).toUpperCase() + period.slice(1)

    const todayRange = resolveDashboardPeriod('today')

    const [todayMetricsResponse, todaySchedulesResponse] = await Promise.all([
      (supabase as any)
        .from('v_studio_metrics_daily')
        .select('revenue')
        .eq('studio_id', studioId)
        .gte('bucket_date', todayRange.current.start)
        .lte('bucket_date', todayRange.current.end),
      (supabase as any)
        .from('v_studio_day_schedule')
        .select('schedule_id, studio_id')
        .eq('studio_id', studioId)
        .gte('start_time', todayRange.current.start)
        .lte('start_time', todayRange.current.end)
        .eq('is_cancelled', false)
    ])

    if (todayMetricsResponse.error || todaySchedulesResponse.error) {
      throw todayMetricsResponse.error ?? todaySchedulesResponse.error
    }

    const todayMetricsRows = (todayMetricsResponse.data ?? []) as Array<{ revenue: number | null }>
    const todaySchedules = todaySchedulesResponse.data ?? []

    const todaysRevenue = todayMetricsRows.reduce((sum, row) => sum + (row.revenue ?? 0), 0)
    const activeClasses = todaySchedules.length

    const kpis = [
      {
        id: 'revenue',
        title: 'Total Revenue',
        value: currentTotals.revenue,
        deltaPercent: calculateDeltaPercent(currentTotals.revenue, previousTotals.revenue),
        trendDirection: currentTotals.revenue >= previousTotals.revenue ? 'up' : 'down'
      },
      {
        id: 'bookings',
        title: 'Total Bookings',
        value: currentTotals.bookings,
        deltaPercent: calculateDeltaPercent(currentTotals.bookings, previousTotals.bookings),
        trendDirection: currentTotals.bookings >= previousTotals.bookings ? 'up' : 'down'
      },
      {
        id: 'schedules',
        title: 'Scheduled Classes',
        value: currentTotals.schedules,
        deltaPercent: calculateDeltaPercent(currentTotals.schedules, previousTotals.schedules),
        trendDirection: currentTotals.schedules >= previousTotals.schedules ? 'up' : 'down'
      },
      {
        id: 'instructors',
        title: 'Active Instructors',
        value: currentTotals.instructors,
        deltaPercent: calculateDeltaPercent(currentTotals.instructors, previousTotals.instructors),
        trendDirection: currentTotals.instructors >= previousTotals.instructors ? 'up' : 'down'
      }
    ]

    return NextResponse.json({
      period: {
        label: periodLabel,
        current: resolved.current,
        previous: resolved.previous
      },
      kpis,
      quickStats: {
        todaysRevenue,
        activeClasses
      }
    })
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error)
    return NextResponse.json(
      { error: { code: 'dashboard_metrics_error', message: 'Failed to load dashboard metrics' } },
      { status: 500 }
    )
  }
}
