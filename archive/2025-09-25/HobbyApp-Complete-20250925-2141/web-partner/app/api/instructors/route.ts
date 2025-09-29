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
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Build query with related data
    let query = supabase
      .from('instructors')
      .select(`
        *,
        studios (
          id,
          name,
          address
        )
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (studioId) {
      query = query.eq('studio_id', studioId);
    }
    if (status) {
      query = query.eq('status', status);
    }

    const { data: instructors, error } = await query;

    if (error) {
      console.error('Supabase query error:', error);
      return NextResponse.json({ error: 'Failed to fetch instructors' }, { status: 500 });
    }

    // Get instructor stats
    const { data: stats } = await supabase
      .from('instructors')
      .select('status')
      .then(({ data }) => {
        if (!data) return { data: {} };
        const statusCounts = data.reduce((acc: any, instructor: any) => {
          acc[instructor.status] = (acc[instructor.status] || 0) + 1;
          return acc;
        }, {});
        return { data: statusCounts };
      });

    return NextResponse.json({
      instructors: instructors || [],
      total: instructors?.length || 0,
      stats: stats || {}
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error fetching instructors:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const instructorData = await request.json();

    // Validate required fields
    const required = ['first_name', 'last_name', 'email'];
    const missing = required.filter(field => !instructorData[field]);

    if (missing.length > 0) {
      return NextResponse.json({
        error: 'Missing required fields',
        missing: missing
      }, { status: 400 });
    }

    // Check if email already exists
    const { data: existingInstructor } = await supabase
      .from('instructors')
      .select('id')
      .eq('email', instructorData.email)
      .single();

    if (existingInstructor) {
      return NextResponse.json({ error: 'Email already exists' }, { status: 400 });
    }

    // Set default values
    const instructorWithDefaults = {
      ...instructorData,
      status: instructorData.status || 'pending',
      created_at: new Date().toISOString()
    };

    // Insert new instructor
    const { data, error } = await supabase
      .from('instructors')
      .insert([instructorWithDefaults])
      .select()
      .single();

    if (error) {
      console.error('Supabase insert error:', error);
      return NextResponse.json({ error: 'Failed to create instructor' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Instructor created successfully',
      instructor: data
    }, { status: 201 });

  } catch (error: any) {
    console.error('Error creating instructor:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const instructorId = searchParams.get('id');

    if (!instructorId) {
      return NextResponse.json({ error: 'Instructor ID is required' }, { status: 400 });
    }

    const updateData = await request.json();

    // Validate status if being updated
    if (updateData.status && !['pending', 'approved', 'rejected', 'suspended'].includes(updateData.status)) {
      return NextResponse.json({ error: 'Invalid instructor status' }, { status: 400 });
    }

    // Update the instructor
    const { data, error } = await supabase
      .from('instructors')
      .update(updateData)
      .eq('id', instructorId)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to update instructor' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Instructor updated successfully',
      instructor: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error updating instructor:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const instructorId = searchParams.get('id');

    if (!instructorId) {
      return NextResponse.json({ error: 'Instructor ID is required' }, { status: 400 });
    }

    // Check if instructor has active class schedules
    const { data: activeClasses } = await supabase
      .from('class_schedules')
      .select(`
        id,
        classes!inner (
          instructor_id
        )
      `)
      .eq('classes.instructor_id', instructorId)
      .gte('start_time', new Date().toISOString());

    if (activeClasses && activeClasses.length > 0) {
      return NextResponse.json({
        error: 'Cannot delete instructor with active classes',
        activeClasses: activeClasses.length
      }, { status: 400 });
    }

    // Instead of hard delete, mark as suspended
    const { data, error } = await supabase
      .from('instructors')
      .update({ status: 'suspended' })
      .eq('id', instructorId)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to suspend instructor' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Instructor suspended successfully',
      instructor: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error suspending instructor:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}