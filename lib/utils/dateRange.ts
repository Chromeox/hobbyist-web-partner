export type DashboardPeriod = 'today' | 'week' | 'month' | 'year' | 'custom'

interface DateRange {
  start: string
  end: string
}

interface ResolvedDashboardPeriod {
  current: DateRange
  previous: DateRange
  granularity: 'day' | 'week' | 'month'
}

const MS_IN_DAY = 86_400_000

const toStartOfDayUTC = (date: Date): Date => {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
}

const toEndOfDayUTC = (date: Date): Date => {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 23, 59, 59, 999))
}

const toISO = (date: Date): string => date.toISOString()

export function resolveDashboardPeriod(
  period: DashboardPeriod = 'week',
  options: { startDate?: string | null; endDate?: string | null } = {}
): ResolvedDashboardPeriod {
  const now = new Date()
  const { startDate, endDate } = options

  if (period === 'custom' || (startDate && endDate)) {
    const start = toStartOfDayUTC(new Date(startDate ?? now))
    const end = toEndOfDayUTC(new Date(endDate ?? now))
    const durationMs = end.getTime() - start.getTime()
    const previousEnd = new Date(start.getTime() - 1)
    const previousStart = new Date(previousEnd.getTime() - durationMs)

    return {
      current: { start: toISO(start), end: toISO(end) },
      previous: { start: toISO(previousStart), end: toISO(previousEnd) },
      granularity: 'day'
    }
  }

  switch (period) {
    case 'today': {
      const start = toStartOfDayUTC(now)
      const end = toEndOfDayUTC(now)
      const previousStart = new Date(start.getTime() - MS_IN_DAY)
      const previousEnd = toEndOfDayUTC(previousStart)

      return {
        current: { start: toISO(start), end: toISO(end) },
        previous: { start: toISO(previousStart), end: toISO(previousEnd) },
        granularity: 'day'
      }
    }
    case 'week': {
      const end = toEndOfDayUTC(now)
      const start = toStartOfDayUTC(new Date(end.getTime() - MS_IN_DAY * 6))
      const previousEnd = new Date(start.getTime() - 1)
      const previousStart = toStartOfDayUTC(new Date(previousEnd.getTime() - MS_IN_DAY * 6))

      return {
        current: { start: toISO(start), end: toISO(end) },
        previous: { start: toISO(previousStart), end: toISO(previousEnd) },
        granularity: 'day'
      }
    }
    case 'month': {
      const start = toStartOfDayUTC(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)))
      const end = toEndOfDayUTC(now)
      const previousMonth = now.getUTCMonth() === 0 ? 11 : now.getUTCMonth() - 1
      const previousYear = previousMonth === 11 ? now.getUTCFullYear() - 1 : now.getUTCFullYear()
      const previousStart = toStartOfDayUTC(new Date(Date.UTC(previousYear, previousMonth, 1)))
      const previousEnd = new Date(start.getTime() - 1)

      return {
        current: { start: toISO(start), end: toISO(end) },
        previous: { start: toISO(previousStart), end: toISO(previousEnd) },
        granularity: 'week'
      }
    }
    case 'year': {
      const start = toStartOfDayUTC(new Date(Date.UTC(now.getUTCFullYear(), 0, 1)))
      const end = toEndOfDayUTC(now)
      const previousStart = toStartOfDayUTC(new Date(Date.UTC(now.getUTCFullYear() - 1, 0, 1)))
      const previousEnd = new Date(start.getTime() - 1)

      return {
        current: { start: toISO(start), end: toISO(end) },
        previous: { start: toISO(previousStart), end: toISO(previousEnd) },
        granularity: 'month'
      }
    }
    default:
      return resolveDashboardPeriod('week')
  }
}
