import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'
import { logMonitoringEvent } from '@/lib/monitoring/logflare'
import type { Database } from '@/types/supabase'

const MS_IN_DAY = 86_400_000

export async function GET(request: Request) {
  let studioId: string | null = null
  let rangeDays = 90
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    studioId = searchParams.get('studioId')
    rangeDays = Math.max(parseInt(searchParams.get('rangeDays') || '90', 10), 1)
    const limit = Math.min(parseInt(searchParams.get('limit') || '200', 10), 500)

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const rangeStart = new Date(Date.now() - rangeDays * MS_IN_DAY).toISOString()

    const [
      { data: events, error: eventsError },
      { data: integrations, error: integrationsError }
    ] = await Promise.all([
      supabase
        .from('v_studio_imported_events_recent')
        .select(
          'id, studio_id, title, description, start_time, end_time, all_day, location, category, created_at, updated_at'
        )
        .eq('studio_id', studioId)
        .gte('start_time', rangeStart)
        .order('start_time', { ascending: false })
        .limit(limit),
      supabase
        .from('calendar_integrations')
        .select('id, provider, sync_enabled, sync_status, last_sync_at, updated_at')
        .eq('studio_id', studioId)
        .order('updated_at', { ascending: false })
    ])

    if (eventsError || integrationsError) {
      throw eventsError ?? integrationsError
    }

    type ImportedEventRow = Database['public']['Views']['v_studio_imported_events_recent']['Row']
    type CalendarIntegrationRow = Database['public']['Tables']['calendar_integrations']['Row']

    const importedEvents: ImportedEventRow[] = events ?? []
    const calendarIntegrations: Array<
      Pick<
        CalendarIntegrationRow,
        'id' | 'provider' | 'sync_enabled' | 'sync_status' | 'last_sync_at' | 'updated_at'
      >
    > = (integrations ?? []).map(integration => ({
      id: integration.id,
      provider: integration.provider,
      sync_enabled: integration.sync_enabled,
      sync_status: integration.sync_status,
      last_sync_at: integration.last_sync_at,
      updated_at: integration.updated_at
    }))

    return NextResponse.json({
      studioId,
      generatedAt: new Date().toISOString(),
      range: {
        start: rangeStart,
        end: new Date().toISOString(),
        days: rangeDays
      },
      importedEvents,
      integrations: {
        calendar: calendarIntegrations
      }
    })
  } catch (error) {
    console.error('Error fetching intelligence data:', error)
    await logMonitoringEvent({
      event: 'intelligence_data_fetch_failed',
      level: 'error',
      studioId,
      message: error instanceof Error ? error.message : 'Unknown error',
      context: {
        rangeDays
      }
    })
    return NextResponse.json(
      { error: { code: 'intelligence_error', message: 'Failed to load intelligence data' } },
      { status: 500 }
    )
  }
}
