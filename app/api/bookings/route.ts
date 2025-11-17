import { NextResponse } from 'next/server';
import { createServiceSupabase } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  try {
    const supabase = createServiceSupabase();
    const { searchParams } = new URL(request.url);
    const studioId = searchParams.get('studioId');
    const classId = searchParams.get('classId');
    const userId = searchParams.get('userId');
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Build query with joins to get related data
    let query = supabase
      .from('bookings')
      .select(`
        *,
        class_schedules (
          id,
          start_time,
          end_time,
          spots_available,
          spots_total,
          classes (
            id,
            name,
            description,
            category,
            difficulty_level,
            price,
            duration,
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
        )
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters (updated for correct relationships)
    if (studioId) {
      query = query.eq('class_schedules.classes.studio_id', studioId);
    }
    if (classId) {
      query = query.eq('class_schedules.class_id', classId);
    }
    if (userId) {
      query = query.eq('user_id', userId);
    }
    if (status) {
      query = query.eq('status', status);
    }

    const { data: bookings, error } = await query;

    if (error) {
      console.error('Supabase query error:', error);
      return NextResponse.json({ error: 'Failed to fetch bookings' }, { status: 500 });
    }

    // Also get booking stats for dashboard
    const { data: stats } = await supabase
      .from('bookings')
      .select('status')
      .then(({ data }) => {
        if (!data) return { data: {} };
        const statusCounts = data.reduce((acc: any, booking: any) => {
          acc[booking.status] = (acc[booking.status] || 0) + 1;
          return acc;
        }, {});
        return { data: statusCounts };
      });

    return NextResponse.json({
      bookings: bookings || [],
      total: bookings?.length || 0,
      stats: stats || {}
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error fetching bookings:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const supabase = createServiceSupabase();
    const bookingData = await request.json();

    // Validate required fields
    const required = ['class_schedule_id', 'user_id'];
    const missing = required.filter(field => !bookingData[field]);

    if (missing.length > 0) {
      return NextResponse.json({
        error: 'Missing required fields',
        missing: missing
      }, { status: 400 });
    }

    // Check if class schedule exists and has capacity
    const { data: scheduleData, error: scheduleError } = await supabase
      .from('class_schedules')
      .select('id, spots_available, spots_total, bookings(id)')
      .eq('id', bookingData.class_schedule_id)
      .single();

    if (scheduleError || !scheduleData) {
      return NextResponse.json({ error: 'Class schedule not found' }, { status: 404 });
    }

    const currentBookings = scheduleData.bookings?.length || 0;
    if (currentBookings >= scheduleData.spots_total) {
      return NextResponse.json({ error: 'Class is full' }, { status: 400 });
    }

    // Set default status if not provided
    const bookingWithDefaults = {
      ...bookingData,
      status: bookingData.status || 'confirmed',
      booking_date: bookingData.booking_date || new Date().toISOString()
    };

    // Insert new booking
    const { data, error } = await supabase
      .from('bookings')
      .insert([bookingWithDefaults])
      .select()
      .single();

    if (error) {
      console.error('Supabase insert error:', error);
      return NextResponse.json({ error: 'Failed to create booking' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Booking created successfully',
      booking: data
    }, { status: 201 });

  } catch (error: any) {
    console.error('Error creating booking:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const supabase = createServiceSupabase();
    const { searchParams } = new URL(request.url);
    const bookingId = searchParams.get('id');

    if (!bookingId) {
      return NextResponse.json({ error: 'Booking ID is required' }, { status: 400 });
    }

    const updateData = await request.json();

    // Validate status if being updated
    if (updateData.status && !['pending', 'confirmed', 'cancelled', 'completed', 'no_show'].includes(updateData.status)) {
      return NextResponse.json({ error: 'Invalid booking status' }, { status: 400 });
    }

    // Update the booking
    const { data, error } = await supabase
      .from('bookings')
      .update(updateData)
      .eq('id', bookingId)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to update booking' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Booking updated successfully',
      booking: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error updating booking:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const supabase = createServiceSupabase();
    const { searchParams } = new URL(request.url);
    const bookingId = searchParams.get('id');

    if (!bookingId) {
      return NextResponse.json({ error: 'Booking ID is required' }, { status: 400 });
    }

    // Instead of hard delete, mark as cancelled
    const { data, error } = await supabase
      .from('bookings')
      .update({ status: 'cancelled' })
      .eq('id', bookingId)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to cancel booking' }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Booking cancelled successfully',
      booking: data
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error cancelling booking:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}