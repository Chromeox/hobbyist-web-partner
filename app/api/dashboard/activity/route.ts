import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { resolveDashboardPeriod, type DashboardPeriod } from '@/lib/utils/dateRange'

export const dynamic = 'force-dynamic';


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
    const limit = parseInt(searchParams.get('limit') || '10', 10)
    const customStart = searchParams.get('startDate')
    const customEnd = searchParams.get('endDate')

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const resolved = resolveDashboardPeriod(period, { startDate: customStart, endDate: customEnd })

    const { data, error } = await supabase.rpc('fn_get_dashboard_activity' as any, {
      p_studio_id: studioId,
      p_period_start: resolved.current.start,
      p_period_end: resolved.current.end,
      p_limit: limit
    })

    if (error) {
      throw error
    }

    const events = (data as any[] | null) ?? []

    return NextResponse.json({
      period: resolved.current,
      events: events.map((event: any) => ({
        id: event.id,
        type: event.type,
        title: event.title,
        message: event.message,
        actor: event.actor,
        amount: event.amount,
        createdAt: event.created_at,
        meta: event.meta ?? {}
      }))
    })
  } catch (error) {
    console.error('Error fetching dashboard activity:', error)
    return NextResponse.json(
      { error: { code: 'activity_error', message: 'Failed to load recent activity' } },
      { status: 500 }
    )
  }
}
