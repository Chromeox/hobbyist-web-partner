import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'

const MS_IN_DAY = 86_400_000

export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    const studioId = searchParams.get('studioId')
    const rangeDays = Math.max(parseInt(searchParams.get('rangeDays') || '90', 10), 1)
    const limit = Math.min(parseInt(searchParams.get('limit') || '200', 10), 500)

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const rangeStart = new Date(Date.now() - rangeDays * MS_IN_DAY).toISOString()

    const [{ data: events, error: eventsError }, { data: integrations, error: integrationsError }] = await Promise.all([
      supabase
        .from('v_studio_imported_events_recent' as any)
        .select(
          'id, studio_id, integration_id, provider, title, description, start_time, end_time, all_day, instructor_name, instructor_email, location, room, category, skill_level, max_participants, current_participants, price, material_fee, migration_status, mapped_class_id, mapped_schedule_id, raw_data'
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

    return NextResponse.json({
      studioId,
      generatedAt: new Date().toISOString(),
      range: {
        start: rangeStart,
        end: new Date().toISOString(),
        days: rangeDays
      },
      importedEvents: (events as unknown as Record<string, unknown>[] | null) ?? [],
      integrations: {
        calendar: integrations ?? []
      }
    })
  } catch (error) {
    console.error('Error fetching intelligence data:', error)
    return NextResponse.json(
      { error: { code: 'intelligence_error', message: 'Failed to load intelligence data' } },
      { status: 500 }
    )
  }
}
