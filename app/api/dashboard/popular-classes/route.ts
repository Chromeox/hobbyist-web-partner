import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { resolveDashboardPeriod, type DashboardPeriod } from '@/lib/utils/dateRange'

export const dynamic = 'force-dynamic';


type PopularClassRow = {
  schedule_id: string
  class_id: string
  class_name: string
  start_time: string
  category: string | null
  instructor_name: string | null
  booking_count: number | null
  revenue_contribution: number | null
}

const parsePeriod = (value: string | null): DashboardPeriod => {
  if (!value) return 'week'
  const allowed: DashboardPeriod[] = ['today', 'week', 'month', 'year', 'custom']
  return allowed.includes(value as DashboardPeriod) ? (value as DashboardPeriod) : 'week'
}

export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    const studioId = searchParams.get('studioId')
    const period = parsePeriod(searchParams.get('period'))
    const limit = parseInt(searchParams.get('limit') || '5', 10)
    const customStart = searchParams.get('startDate')
    const customEnd = searchParams.get('endDate')

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const resolved = resolveDashboardPeriod(period, { startDate: customStart, endDate: customEnd })

    const { data, error } = await supabase
      .from('v_studio_class_popularity' as any)
      .select(
        'schedule_id, class_id, class_name, start_time, category, instructor_name, booking_count, revenue_contribution'
      )
      .eq('studio_id', studioId)
      .gte('start_time', resolved.current.start)
      .lte('start_time', resolved.current.end)
      .order('booking_count', { ascending: false, nullsFirst: false })
      .limit(limit)

    if (error) {
      throw error
    }

    const rows = (data as unknown as PopularClassRow[] | null) ?? []

    return NextResponse.json({
      period: resolved.current,
      classes: rows.map(row => ({
        scheduleId: row.schedule_id,
        classId: row.class_id,
        className: row.class_name,
        startTime: row.start_time,
        category: row.category,
        instructorName: row.instructor_name,
        bookingCount: row.booking_count ?? 0,
        revenueContribution: row.revenue_contribution ?? 0
      }))
    })
  } catch (error) {
    console.error('Error fetching popular classes:', error)
    return NextResponse.json(
      { error: { code: 'popular_classes_error', message: 'Failed to load popular classes' } },
      { status: 500 }
    )
  }
}
