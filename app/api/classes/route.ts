import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client with service role key for elevated privileges
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const studioId = searchParams.get('studioId');
    const instructorId = searchParams.get('instructorId');
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Build query based on filters - get class schedules with class details
    let query = supabase
      .from('class_schedules')
      .select(`
        *,
        classes (
          id,
          name,
          description,
          category,
          difficulty_level,
          price,
          duration,
          max_participants,
          equipment_needed,
          instructors (
            id,
            name,
            email
          ),
          studios (
            id,
            name,
            address
          )
        )
      `)
      .order('start_time', { ascending: true })
      .range(offset, offset + limit - 1);

    // Apply filters if provided (through the classes relationship)
    if (studioId) {
      query = query.eq('classes.studio_id', studioId);
    }
    if (instructorId) {
      query = query.eq('classes.instructor_id', instructorId);
    }

    const { data: classes, error } = await query;

    if (error) {
      console.error('Supabase query error:', error);
      return NextResponse.json({ error: 'Failed to fetch classes' }, { status: 500 });
    }

    return NextResponse.json({
      classes: classes || [],
      total: classes?.length || 0
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error fetching classes:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const scheduleData = await request.json();

    // Validate required fields for class schedule
    const required = ['class_id', 'start_time', 'end_time', 'spots_total'];
    const missing = required.filter(field => !scheduleData[field]);

    if (missing.length > 0) {
      return NextResponse.json({
        error: 'Missing required fields',
        missing: missing
      }, { status: 400 });
    }

    // Set default values
    const scheduleWithDefaults = {
      ...scheduleData,
      spots_available: scheduleData.spots_available || scheduleData.spots_total,
      is_cancelled: false
    };

    // Insert new class schedule
    const { data, error } = await supabase
      .from('class_schedules')
      .insert([scheduleWithDefaults])
      .select(`
        *,
        classes (
          id,
          name,
          description,
          instructors (name),
          studios (name)
        )
      `)
      .single();

    if (error) {
      console.error('Supabase insert error:', error);
      return NextResponse.json({ error: 'Failed to create class schedule' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Class schedule created successfully',
      schedule: data
    }, { status: 201 });

  } catch (error: any) {
    console.error('Error creating class schedule:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const scheduleId = searchParams.get('id');

    if (!scheduleId) {
      return NextResponse.json({ error: 'Schedule ID is required' }, { status: 400 });
    }

    const updateData = await request.json();

    // Update the class schedule
    const { data, error } = await supabase
      .from('class_schedules')
      .update(updateData)
      .eq('id', scheduleId)
      .select(`
        *,
        classes (
          id,
          name,
          description,
          instructors (name),
          studios (name)
        )
      `)
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to update class schedule' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Class schedule updated successfully',
      schedule: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error updating class schedule:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const scheduleId = searchParams.get('id');

    if (!scheduleId) {
      return NextResponse.json({ error: 'Schedule ID is required' }, { status: 400 });
    }

    // Mark class schedule as cancelled instead of hard delete
    const { data, error } = await supabase
      .from('class_schedules')
      .update({
        is_cancelled: true,
        cancellation_reason: 'Cancelled by studio'
      })
      .eq('id', scheduleId)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to cancel class schedule' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Class schedule cancelled successfully',
      schedule: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error cancelling class schedule:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}