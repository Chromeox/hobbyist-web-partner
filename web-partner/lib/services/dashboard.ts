interface FetchOptions {
  studioId: string
  period?: string
  startDate?: string | null
  endDate?: string | null
  limit?: number
}

const withQueries = (path: string, params: Record<string, string | number | undefined | null>) => {
  const base =
    typeof window === 'undefined'
      ? 'http://localhost'
      : window.location.origin
  const url = new URL(path, base)

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      url.searchParams.set(key, String(value))
    }
  })

  return url.toString()
}

const fetchJson = async <T>(input: string): Promise<T> => {
  const response = await fetch(input, { cache: 'no-store' })

  if (!response.ok) {
    let message = 'Request failed'
    try {
      const payload = await response.json()
      if (payload?.error?.message) {
        message = payload.error.message
      }
    } catch {
      // ignore JSON parse errors
    }
    throw new Error(message)
  }

  return response.json() as Promise<T>
}

export const dashboardService = {
  getMetrics: (options: FetchOptions) =>
    fetchJson<{
      period: { label: string; current: { start: string; end: string }; previous: { start: string; end: string } }
      kpis: Array<{ id: string; title: string; value: number; deltaPercent: number; trendDirection: 'up' | 'down' }>
      quickStats: { todaysRevenue: number; activeClasses: number }
    }>(
      withQueries('/api/dashboard/metrics', {
        studioId: options.studioId,
        period: options.period,
        startDate: options.startDate ?? undefined,
        endDate: options.endDate ?? undefined
      })
    ),

  getRevenueTrend: (options: FetchOptions) =>
    fetchJson<{
      granularity: 'day' | 'week' | 'month'
      totals: { revenue: number; bookings: number }
      series: Array<{
        label: string
        points: Array<{ bucket: string; label: string; value: number }>
      }>
    }>(
      withQueries('/api/dashboard/revenue-trend', {
        studioId: options.studioId,
        period: options.period,
        startDate: options.startDate ?? undefined,
        endDate: options.endDate ?? undefined
      })
    ),

  getPopularClasses: (options: FetchOptions) =>
    fetchJson<{
      period: { start: string; end: string }
      classes: Array<{
        scheduleId: string
        classId: string
        className: string
        startTime: string
        category: string | null
        instructorName: string | null
        bookingCount: number
        revenueContribution: number
      }>
    }>(
      withQueries('/api/dashboard/popular-classes', {
        studioId: options.studioId,
        period: options.period,
        startDate: options.startDate ?? undefined,
        endDate: options.endDate ?? undefined,
        limit: options.limit
      })
    ),

  getSchedule: (options: { studioId: string; date?: string; limit?: number }) =>
    fetchJson<{
      dateRange: { start: string; end: string }
      summary: { totalClasses: number; totalSeats: number; seatsBooked: number; occupancyPercent: number }
      schedules: Array<{
        scheduleId: string
        className: string
        category: string | null
        instructorName: string | null
        startTime: string
        endTime: string
        capacity: number
        enrolled: number
        spotsAvailable: number
        occupancyPercent: number
        isCancelled: boolean
        cancellationReason: string | null
        waitlistCount: number
      }>
    }>(
      withQueries('/api/dashboard/schedule', {
        studioId: options.studioId,
        date: options.date,
        limit: options.limit
      })
    ),

  getActivity: (options: FetchOptions) =>
    fetchJson<{
      period: { start: string; end: string }
      events: Array<{
        id: string
        type: string
        title: string
        message: string
        actor: string | null
        amount: number | null
        createdAt: string
        meta: Record<string, unknown>
      }>
    }>(
      withQueries('/api/dashboard/activity', {
        studioId: options.studioId,
        period: options.period,
        startDate: options.startDate ?? undefined,
        endDate: options.endDate ?? undefined,
        limit: options.limit
      })
    ),

  getSetupStatus: (studioId: string) =>
    fetchJson<{
      studioId: string
      calendarIntegration: Record<string, unknown> | null
      payouts: Record<string, unknown> | null
      messaging: Record<string, unknown> | null
      dismissedReminders: string[]
    }>(withQueries('/api/dashboard/setup-status', { studioId })),

  getIntelligenceData: (options: { studioId: string; rangeDays?: number; limit?: number }) =>
    fetchJson<{
      studioId: string
      generatedAt: string
      range: { start: string; end: string; days: number }
      importedEvents: Array<Record<string, unknown>>
      integrations: { calendar: Array<Record<string, unknown>> }
    }>(
      withQueries('/api/dashboard/intelligence-data', {
        studioId: options.studioId,
        rangeDays: options.rangeDays ?? undefined,
        limit: options.limit ?? undefined
      })
    )
}
