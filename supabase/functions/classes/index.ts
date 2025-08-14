// Class Management Edge Function
// Handles class creation, updates, search, filtering, and instructor management

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody, getPaginationParams, hasRole, calculateDistance } from '../_shared/utils.ts';
import { Class, User, Instructor, Category } from '../_shared/types.ts';

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/classes', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'GET':
        switch (path) {
          case '/search':
            return handleSearchClasses(req);
          case '/categories':
            return handleGetCategories(req);
          case '/instructor':
            return handleGetInstructorClasses(req, authHeader);
          case '/popular':
            return handleGetPopularClasses(req);
          case '/nearby':
            return handleGetNearbyClasses(req);
          default:
            if (path.startsWith('/')) {
              const classId = path.substring(1);
              return handleGetClass(req, classId);
            }
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'POST':
        switch (path) {
          case '/create':
            return handleCreateClass(req, authHeader);
          case '/duplicate':
            return handleDuplicateClass(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'PUT':
        if (path.startsWith('/')) {
          const classId = path.substring(1);
          return handleUpdateClass(req, authHeader, classId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      case 'DELETE':
        if (path.startsWith('/')) {
          const classId = path.substring(1);
          return handleDeleteClass(req, authHeader, classId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Classes function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleSearchClasses(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const supabase = createSupabaseClient();
  
  // Extract search parameters
  const query = url.searchParams.get('q') || '';
  const category = url.searchParams.get('category');
  const location = url.searchParams.get('location');
  const priceMin = parseFloat(url.searchParams.get('price_min') || '0');
  const priceMax = parseFloat(url.searchParams.get('price_max') || '999999');
  const difficulty = url.searchParams.get('difficulty');
  const date = url.searchParams.get('date');
  const sortBy = url.searchParams.get('sort_by') || 'popularity';
  const lat = parseFloat(url.searchParams.get('lat') || '0');
  const lng = parseFloat(url.searchParams.get('lng') || '0');
  const radius = parseFloat(url.searchParams.get('radius') || '25'); // miles
  const { page, limit, offset } = getPaginationParams(url);

  try {
    let queryBuilder = supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        category:categories(*),
        reviews(rating, comment),
        bookings!inner(count)
      `)
      .eq('status', 'published')
      .gte('price', priceMin * 100) // Convert to cents
      .lte('price', priceMax * 100)
      .range(offset, offset + limit - 1);

    // Text search
    if (query) {
      queryBuilder = queryBuilder.or(`title.ilike.%${query}%,description.ilike.%${query}%,tags.cs.{${query}}`);
    }

    // Category filter
    if (category) {
      queryBuilder = queryBuilder.eq('category_id', category);
    }

    // Difficulty filter
    if (difficulty && difficulty !== 'all_levels') {
      queryBuilder = queryBuilder.eq('difficulty_level', difficulty);
    }

    // Date filter for classes with schedules
    if (date) {
      const searchDate = new Date(date);
      queryBuilder = queryBuilder.or(`schedule->>start_date.eq.${date},schedule->>type.eq.recurring`);
    }

    const { data: classes, error, count } = await queryBuilder;

    if (error) {
      return errorResponse(
        'Failed to search classes',
        'SEARCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Filter by location/proximity if coordinates provided
    let filteredClasses = classes || [];
    if (lat && lng && location !== 'online') {
      filteredClasses = filteredClasses.filter((cls) => {
        if (cls.location?.type === 'online') return location === 'online';
        if (!cls.location?.address?.lat || !cls.location?.address?.lng) return false;
        
        const distance = calculateDistance(
          lat,
          lng,
          cls.location.address.lat,
          cls.location.address.lng
        );
        
        return distance <= radius;
      });
    }

    // Sort results
    filteredClasses.sort((a, b) => {
      switch (sortBy) {
        case 'price_low':
          return a.price - b.price;
        case 'price_high':
          return b.price - a.price;
        case 'date':
          return new Date(a.schedule?.start_date || 0).getTime() - 
                 new Date(b.schedule?.start_date || 0).getTime();
        case 'rating':
          const aRating = a.reviews?.length ? 
            a.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / a.reviews.length : 0;
          const bRating = b.reviews?.length ? 
            b.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / b.reviews.length : 0;
          return bRating - aRating;
        case 'popularity':
        default:
          return (b.bookings?.length || 0) - (a.bookings?.length || 0);
      }
    });

    // Enhance classes with computed fields
    const enhancedClasses = filteredClasses.map((cls) => ({
      ...cls,
      average_rating: cls.reviews?.length ? 
        cls.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / cls.reviews.length : 0,
      total_reviews: cls.reviews?.length || 0,
      spots_remaining: cls.max_participants - cls.current_participants,
      price_formatted: (cls.price / 100).toFixed(2),
      distance: lat && lng && cls.location?.address?.lat && cls.location?.address?.lng ?
        calculateDistance(lat, lng, cls.location.address.lat, cls.location.address.lng) : null,
    }));

    return createResponse(enhancedClasses, undefined, 200);
  } catch (error) {
    console.error('Search classes error:', error);
    return errorResponse(
      'Failed to search classes',
      'SEARCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetClass(req: Request, classId: string): Promise<Response> {
  const supabase = createSupabaseClient();

  try {
    const { data: classData, error } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(
          *,
          user:user_profiles!inner(*)
        ),
        category:categories(*),
        reviews(
          *,
          user:user_profiles!inner(first_name, last_name, avatar_url)
        ),
        bookings(id, status)
      `)
      .eq('id', classId)
      .single();

    if (error) {
      return errorResponse(
        'Class not found',
        'NOT_FOUND',
        404,
        { supabase_error: error }
      );
    }

    // Calculate derived fields
    const averageRating = classData.reviews?.length ?
      classData.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / classData.reviews.length : 0;
    
    const spotsRemaining = classData.max_participants - classData.current_participants;
    
    const enhancedClass = {
      ...classData,
      average_rating: Math.round(averageRating * 10) / 10,
      total_reviews: classData.reviews?.length || 0,
      spots_remaining: spotsRemaining,
      price_formatted: (classData.price / 100).toFixed(2),
      is_full: spotsRemaining <= 0,
      reviews: classData.reviews?.slice(0, 10), // Limit reviews for performance
    };

    return createResponse(enhancedClass);
  } catch (error) {
    console.error('Get class error:', error);
    return errorResponse(
      'Failed to get class',
      'CLASS_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCreateClass(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const isInstructor = await hasRole(userId, 'instructor');
  if (!isInstructor) {
    return errorResponse('Instructor role required', 'FORBIDDEN', 403);
  }

  const body = await req.json();
  const validation = validateBody(body, [
    'title', 'description', 'price', 'duration_minutes', 
    'max_participants', 'difficulty_level', 'location', 'schedule'
  ]);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const supabase = createSupabaseClient();

  try {
    // Get instructor profile
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (instructorError || !instructor) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    }

    // Create class
    const classData = {
      ...validation.data,
      instructor_id: instructor.id,
      price: Math.round(validation.data.price * 100), // Convert to cents
      current_participants: 0,
      status: 'draft',
      images: validation.data.images || [],
      tags: validation.data.tags || [],
      requirements: validation.data.requirements || [],
      what_to_bring: validation.data.what_to_bring || [],
      cancellation_policy: validation.data.cancellation_policy || {
        refund_percentage: 100,
        hours_before_class: 24,
      },
    };

    const { data, error } = await supabase
      .from('classes')
      .insert(classData)
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        category:categories(*)
      `)
      .single();

    if (error) {
      return errorResponse(
        'Failed to create class',
        'CREATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      ...data,
      price_formatted: (data.price / 100).toFixed(2),
      message: 'Class created successfully! You can now publish it to make it visible to students.',
    }, undefined, 201);
  } catch (error) {
    console.error('Create class error:', error);
    return errorResponse(
      'Failed to create class',
      'CREATE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleUpdateClass(req: Request, authHeader?: string, classId: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const supabase = createSupabaseClient();

  try {
    // Verify ownership
    const { data: existingClass, error: fetchError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(user_id)
      `)
      .eq('id', classId)
      .single();

    if (fetchError) {
      return errorResponse('Class not found', 'NOT_FOUND', 404);
    }

    if (existingClass.instructor.user_id !== userId) {
      return errorResponse('You can only update your own classes', 'FORBIDDEN', 403);
    }

    // Prepare updates
    const updates = { ...body };
    if (updates.price) {
      updates.price = Math.round(updates.price * 100); // Convert to cents
    }
    updates.updated_at = new Date().toISOString();

    // Remove fields that shouldn't be updated directly
    delete updates.instructor_id;
    delete updates.current_participants;
    delete updates.created_at;

    const { data, error } = await supabase
      .from('classes')
      .update(updates)
      .eq('id', classId)
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        category:categories(*)
      `)
      .single();

    if (error) {
      return errorResponse(
        'Failed to update class',
        'UPDATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      ...data,
      price_formatted: (data.price / 100).toFixed(2),
    });
  } catch (error) {
    console.error('Update class error:', error);
    return errorResponse(
      'Failed to update class',
      'UPDATE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleDeleteClass(req: Request, authHeader?: string, classId: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    // Verify ownership and check for bookings
    const { data: classData, error: fetchError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(user_id),
        bookings(id, status)
      `)
      .eq('id', classId)
      .single();

    if (fetchError) {
      return errorResponse('Class not found', 'NOT_FOUND', 404);
    }

    if (classData.instructor.user_id !== userId) {
      return errorResponse('You can only delete your own classes', 'FORBIDDEN', 403);
    }

    // Check for active bookings
    const activeBookings = classData.bookings?.filter(
      (booking: any) => booking.status === 'confirmed' || booking.status === 'pending'
    );

    if (activeBookings?.length > 0) {
      return errorResponse(
        'Cannot delete class with active bookings. Please cancel or complete all bookings first.',
        'HAS_BOOKINGS',
        400,
        { active_bookings: activeBookings.length }
      );
    }

    // Soft delete by updating status
    const { error } = await supabase
      .from('classes')
      .update({ 
        status: 'cancelled',
        updated_at: new Date().toISOString() 
      })
      .eq('id', classId);

    if (error) {
      return errorResponse(
        'Failed to delete class',
        'DELETE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      message: 'Class deleted successfully',
    });
  } catch (error) {
    console.error('Delete class error:', error);
    return errorResponse(
      'Failed to delete class',
      'DELETE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetInstructorClasses(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const { page, limit, offset } = getPaginationParams(url);
  const status = url.searchParams.get('status') || 'all';
  const supabase = createSupabaseClient();

  try {
    let queryBuilder = supabase
      .from('classes')
      .select(`
        *,
        category:categories(*),
        bookings(id, status),
        reviews(rating)
      `)
      .eq('instructor_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status !== 'all') {
      queryBuilder = queryBuilder.eq('status', status);
    }

    const { data: classes, error, count } = await queryBuilder;

    if (error) {
      return errorResponse(
        'Failed to get instructor classes',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Enhance with computed fields
    const enhancedClasses = classes?.map((cls) => ({
      ...cls,
      price_formatted: (cls.price / 100).toFixed(2),
      spots_remaining: cls.max_participants - cls.current_participants,
      total_bookings: cls.bookings?.length || 0,
      confirmed_bookings: cls.bookings?.filter((b: any) => b.status === 'confirmed')?.length || 0,
      average_rating: cls.reviews?.length ?
        cls.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / cls.reviews.length : 0,
      total_reviews: cls.reviews?.length || 0,
    }));

    return createResponse(enhancedClasses, undefined, 200);
  } catch (error) {
    console.error('Get instructor classes error:', error);
    return errorResponse(
      'Failed to get instructor classes',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetCategories(req: Request): Promise<Response> {
  const supabase = createSupabaseClient();

  try {
    const { data: categories, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('order');

    if (error) {
      return errorResponse(
        'Failed to get categories',
        'CATEGORIES_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Group categories by parent
    const rootCategories = categories?.filter(cat => !cat.parent_id) || [];
    const subCategories = categories?.filter(cat => cat.parent_id) || [];

    const categoriesWithChildren = rootCategories.map(parent => ({
      ...parent,
      subcategories: subCategories.filter(sub => sub.parent_id === parent.id),
    }));

    return createResponse(categoriesWithChildren);
  } catch (error) {
    console.error('Get categories error:', error);
    return errorResponse(
      'Failed to get categories',
      'CATEGORIES_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetPopularClasses(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const { limit } = getPaginationParams(url);
  const supabase = createSupabaseClient();

  try {
    const { data: classes, error } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        category:categories(*),
        bookings(id),
        reviews(rating)
      `)
      .eq('status', 'published')
      .order('current_participants', { ascending: false })
      .limit(limit);

    if (error) {
      return errorResponse(
        'Failed to get popular classes',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    const enhancedClasses = classes?.map((cls) => ({
      ...cls,
      price_formatted: (cls.price / 100).toFixed(2),
      average_rating: cls.reviews?.length ?
        cls.reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / cls.reviews.length : 0,
      total_reviews: cls.reviews?.length || 0,
      popularity_score: cls.current_participants + (cls.bookings?.length || 0),
    }));

    return createResponse(enhancedClasses);
  } catch (error) {
    console.error('Get popular classes error:', error);
    return errorResponse(
      'Failed to get popular classes',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetNearbyClasses(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const lat = parseFloat(url.searchParams.get('lat') || '0');
  const lng = parseFloat(url.searchParams.get('lng') || '0');
  const radius = parseFloat(url.searchParams.get('radius') || '10');
  const { limit } = getPaginationParams(url);

  if (!lat || !lng) {
    return errorResponse('Latitude and longitude are required', 'MISSING_LOCATION', 400);
  }

  const supabase = createSupabaseClient();

  try {
    const { data: classes, error } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(*),
        category:categories(*)
      `)
      .eq('status', 'published')
      .neq('location->type', 'online')
      .limit(limit * 3); // Get more to filter by distance

    if (error) {
      return errorResponse(
        'Failed to get nearby classes',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Filter by distance
    const nearbyClasses = classes
      ?.filter((cls) => {
        if (!cls.location?.address?.lat || !cls.location?.address?.lng) return false;
        const distance = calculateDistance(lat, lng, cls.location.address.lat, cls.location.address.lng);
        return distance <= radius;
      })
      .map((cls) => ({
        ...cls,
        distance: calculateDistance(lat, lng, cls.location.address.lat, cls.location.address.lng),
        price_formatted: (cls.price / 100).toFixed(2),
      }))
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return createResponse(nearbyClasses);
  } catch (error) {
    console.error('Get nearby classes error:', error);
    return errorResponse(
      'Failed to get nearby classes',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleDuplicateClass(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['class_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { class_id } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Get original class and verify ownership
    const { data: originalClass, error: fetchError } = await supabase
      .from('classes')
      .select(`
        *,
        instructor:instructor_profiles!inner(user_id)
      `)
      .eq('id', class_id)
      .single();

    if (fetchError) {
      return errorResponse('Class not found', 'NOT_FOUND', 404);
    }

    if (originalClass.instructor.user_id !== userId) {
      return errorResponse('You can only duplicate your own classes', 'FORBIDDEN', 403);
    }

    // Create duplicate
    const duplicateData = {
      ...originalClass,
      title: `${originalClass.title} (Copy)`,
      status: 'draft',
      current_participants: 0,
    };

    // Remove fields that shouldn't be duplicated
    delete duplicateData.id;
    delete duplicateData.created_at;
    delete duplicateData.updated_at;
    delete duplicateData.instructor;

    const { data, error } = await supabase
      .from('classes')
      .insert(duplicateData)
      .select()
      .single();

    if (error) {
      return errorResponse(
        'Failed to duplicate class',
        'DUPLICATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      ...data,
      price_formatted: (data.price / 100).toFixed(2),
      message: 'Class duplicated successfully',
    }, undefined, 201);
  } catch (error) {
    console.error('Duplicate class error:', error);
    return errorResponse(
      'Failed to duplicate class',
      'DUPLICATE_ERROR',
      500,
      { error: error.message }
    );
  }
}