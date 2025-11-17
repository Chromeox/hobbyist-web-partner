import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { resolveDashboardPeriod, type DashboardPeriod } from '@/lib/utils/dateRange'

export const dynamic = 'force-dynamic';


type TrendRow = {
  bucket_date: string
  revenue: number | null
  booking_count: number | null
}

type Granularity = 'day' | 'week' | 'month'

const parsePeriod = (value: string | null): DashboardPeriod => {
  if (!value) return 'week'
  const allowed: DashboardPeriod[] = ['today', 'week', 'month', 'year', 'custom']
  return allowed.includes(value as DashboardPeriod) ? (value as DashboardPeriod) : 'week'
}

const normaliseDate = (dateString: string, granularity: Granularity): Date => {
  const date = new Date(dateString)
  switch (granularity) {
    case 'day':
      return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
    case 'week': {
      const day = date.getUTCDay() // 0 (Sun) - 6 (Sat)
      const diff = day === 0 ? -6 : 1 - day // align to Monday
      const bucketDate = new Date(date)
      bucketDate.setUTCDate(bucketDate.getUTCDate() + diff)
      return new Date(Date.UTC(bucketDate.getUTCFullYear(), bucketDate.getUTCMonth(), bucketDate.getUTCDate()))
    }
    case 'month':
      return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1))
    default:
      return date
  }
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
    const granularity = resolved.granularity

    const { data, error } = await supabase
      .from('v_studio_metrics_daily' as any)
      .select('bucket_date, revenue, booking_count')
      .eq('studio_id', studioId)
      .gte('bucket_date', resolved.current.start)
      .lte('bucket_date', resolved.current.end)
      .order('bucket_date', { ascending: true })

    if (error) {
      throw error
    }

    const bucketMap: { [key: string]: { bucket: string; display: string; revenue: number; bookings: number } } = {}

    const rows = (data as any[]) ?? []

    rows.forEach((row) => {
      const bucketDate = normaliseDate(row.bucket_date, granularity)
      const key = bucketDate.toISOString()
      const label =
        granularity === 'month'
          ? bucketDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
          : bucketDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })

      const entry = bucketMap[key] ?? {
        bucket: key,
        display: label,
        revenue: 0,
        bookings: 0
      }

      entry.revenue += row.revenue ?? 0
      entry.bookings += row.booking_count ?? 0

      bucketMap[key] = entry
    })

    const points = Object.values(bucketMap) as Array<{ bucket: string; display: string; revenue: number; bookings: number }>
    points.sort((a, b) => a.bucket.localeCompare(b.bucket))

    const totalRevenue = points.reduce((sum, point) => sum + point.revenue, 0)
    const totalBookings = points.reduce((sum, point) => sum + point.bookings, 0)

    return NextResponse.json({
      granularity,
      totals: {
        revenue: totalRevenue,
        bookings: totalBookings
      },
      series: [
        {
          label: 'Revenue',
          points: points.map((point: { bucket: string; display: string; revenue: number; bookings: number }) => ({
            bucket: point.bucket,
            label: point.display,
            value: point.revenue
          }))
        },
        {
          label: 'Bookings',
          points: points.map((point: { bucket: string; display: string; revenue: number; bookings: number }) => ({
            bucket: point.bucket,
            label: point.display,
            value: point.bookings
          }))
        }
      ]
    })
  } catch (error) {
    console.error('Error fetching revenue trend:', error)
    return NextResponse.json(
      { error: { code: 'revenue_trend_error', message: 'Failed to load revenue trend data' } },
      { status: 500 }
    )
  }
}
