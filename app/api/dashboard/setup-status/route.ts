import { NextResponse } from 'next/server'

import { createServiceSupabase } from '@/lib/supabase'

export const dynamic = 'force-dynamic';


export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase()
    const { searchParams } = new URL(request.url)
    const studioId = searchParams.get('studioId')

    if (!studioId) {
      return NextResponse.json(
        { error: { code: 'missing_studio_id', message: 'studioId query param is required' } },
        { status: 400 }
      )
    }

    const { data, error } = await supabase
      .from('v_studio_setup_status' as any)
      .select('calendar_integration, payouts, messaging, dismissed_reminders')
      .eq('studio_id', studioId)
      .maybeSingle()

    if (error) {
      throw error
    }

    const result = data as unknown as {
      calendar_integration: Record<string, unknown> | null
      payouts: Record<string, unknown> | null
      messaging: Record<string, unknown> | null
      dismissed_reminders: string[] | null
    } | null

    return NextResponse.json({
      studioId,
      calendarIntegration: result?.calendar_integration ?? null,
      payouts: result?.payouts ?? null,
      messaging: result?.messaging ?? null,
      dismissedReminders: result?.dismissed_reminders ?? []
    })
  } catch (error) {
    console.error('Error fetching setup status:', error)
    return NextResponse.json(
      { error: { code: 'setup_status_error', message: 'Failed to load setup status' } },
      { status: 500 }
    )
  }
}
