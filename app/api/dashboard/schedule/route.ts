import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { resolveDashboardPeriod } from '@/lib/utils/dateRange'

export const dynamic = 'force-dynamic';


type ScheduleRow = {
  schedule_id: string
  start_time: string
  end_time: string
  is_cancelled: boolean | null
  cancellation_reason: string | null
  class_name: string
  category: string | null
  instructor_name: string | null
  capacity: number | null
  spots_available: number | null
  enrolled: number | null
  occupancy_percent: number | null
}

const toNumber = (value: number | null | undefined): number => (value ?? 0)

export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    const studioId = searchParams.get('studioId')
    const date = searchParams.get('date')
    const limit = parseInt(searchParams.get('limit') || '25', 10)

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const resolved = resolveDashboardPeriod('today', {
      startDate: date,
      endDate: date
    })

    const { data, error } = await supabase
      .from('v_studio_day_schedule' as any)
      .select(
        'schedule_id, start_time, end_time, is_cancelled, cancellation_reason, class_name, category, instructor_name, capacity, spots_available, enrolled, occupancy_percent'
      )
      .eq('studio_id', studioId)
      .gte('start_time', resolved.current.start)
      .lte('start_time', resolved.current.end)
      .order('start_time', { ascending: true })
      .limit(limit)

    if (error) {
      throw error
    }

    const rows = (data as unknown as ScheduleRow[] | null) ?? []

    const schedules = rows.map(row => {
      const capacity = toNumber(row.capacity)
      const spotsAvailable = toNumber(row.spots_available)
      const enrolled = row.enrolled ?? Math.max(capacity - spotsAvailable, 0)
      const occupancyPercent =
        row.occupancy_percent ?? (capacity > 0 ? Math.round((enrolled / capacity) * 100) : 0)

      return {
        scheduleId: row.schedule_id,
        className: row.class_name,
        category: row.category,
        instructorName: row.instructor_name,
        startTime: row.start_time,
        endTime: row.end_time,
        capacity,
        enrolled,
        spotsAvailable,
        occupancyPercent,
        isCancelled: row.is_cancelled ?? false,
        cancellationReason: row.cancellation_reason,
        waitlistCount: 0
      }
    })

    const totalClasses = schedules.length
    const totalSeats = schedules.reduce((sum, schedule) => sum + schedule.capacity, 0)
    const seatsBooked = schedules.reduce((sum, schedule) => sum + schedule.enrolled, 0)
    const occupancyPercent = totalSeats > 0 ? Math.round((seatsBooked / totalSeats) * 100) : 0

    return NextResponse.json({
      dateRange: resolved.current,
      summary: {
        totalClasses,
        totalSeats,
        seatsBooked,
        occupancyPercent
      },
      schedules
    })
  } catch (error) {
    console.error('Error fetching schedule overview:', error)
    return NextResponse.json(
      { error: { code: 'schedule_error', message: 'Failed to load schedule overview' } },
      { status: 500 }
    )
  }
}
