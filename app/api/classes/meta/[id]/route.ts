import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { mapDbClassToUiClass, mapFormDataToUpsertPayload } from '@/lib/utils/class-mappers';
import type { ClassFormData } from '@/types/class-management';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

const CLASS_SELECT = `
  *,
  categories (
    id,
    name,
    slug
  ),
  instructors (
    id,
    email,
    user_profiles (
      first_name,
      last_name
    )
  )
`;

const slugify = (input: string) =>
  input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '') || 'category';

const validateFormData = (form: ClassFormData): string | null => {
  if (!form.name.trim()) return 'Class name is required';
  if (!form.description.trim()) return 'Description is required';
  if (!form.instructorId) return 'Instructor is required';
  if (!form.category && !form.categoryId) return 'Category is required';
  if (!form.location.trim()) return 'Location is required';
  if (form.duration < 15) return 'Duration must be at least 15 minutes';
  if (form.capacity < 1) return 'Capacity must be at least 1';
  if (form.price < 0) return 'Price cannot be negative';
  if (form.creditCost < 1) return 'Credit cost must be at least 1';
  return null;
};

const resolveCategoryId = async (form: ClassFormData): Promise<string> => {
  if (form.categoryId && !form.categoryId.startsWith('fallback-')) {
    const { data, error } = await supabase
      .from('categories')
      .select('id')
      .eq('id', form.categoryId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (data?.id) {
      return data.id;
    }
  }

  const name = (form.category ?? '').trim();
  if (!name) {
    throw new Error('Category name is required');
  }

  const baseSlug = slugify(name);
  let attempt = 0;
  let slug = baseSlug;

  while (true) {
    const { data, error } = await supabase
      .from('categories')
      .select('id, name')
      .eq('slug', slug)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (!data) {
      break;
    }

    if (data.name?.toLowerCase() === name.toLowerCase()) {
      return data.id;
    }

    attempt += 1;
    slug = `${baseSlug}-${attempt}`;
  }

  const { data, error } = await supabase
    .from('categories')
    .insert({
      name,
      slug,
      is_active: true,
    })
    .select('id')
    .single();

  if (error) {
    throw error;
  }

  return data.id;
};

export async function PUT(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;

  if (!id) {
    return NextResponse.json({ error: 'Class ID is required' }, { status: 400 });
  }

  try {
    const payload = await request.json();
    const form: ClassFormData | undefined = payload?.class;
    const studioId: string | null = payload?.studioId ?? null;

    if (!form) {
      return NextResponse.json(
        { error: 'Missing class payload' },
        { status: 400 }
      );
    }

    const validationError = validateFormData(form);
    if (validationError) {
      return NextResponse.json({ error: validationError }, { status: 400 });
    }

    const categoryId = await resolveCategoryId(form);
    const upsertPayload = mapFormDataToUpsertPayload({ ...form, id }, categoryId);
    upsertPayload.updated_at = new Date().toISOString();
    delete upsertPayload.id;

    if (studioId) {
      upsertPayload.studio_id = studioId;
    }

    const { data, error } = await supabase
      .from('classes')
      .update(upsertPayload)
      .eq('id', id)
      .select(CLASS_SELECT)
      .single();

    if (error) {
      throw error;
    }

    const mapped = mapDbClassToUiClass(data);

    return NextResponse.json({ class: mapped }, { status: 200 });
  } catch (error) {
    console.error('Failed to update class metadata', error);
    const message =
      error instanceof Error ? error.message : 'Failed to update class';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;

  if (!id) {
    return NextResponse.json({ error: 'Class ID is required' }, { status: 400 });
  }

  try {
    const now = new Date().toISOString();

    const { data: futureSessions, error: scheduleError } = await supabase
      .from('class_schedules')
      .select('id')
      .eq('class_id', id)
      .eq('is_cancelled', false)
      .gte('start_time', now)
      .limit(1);

    if (scheduleError) {
      throw scheduleError;
    }

    if (futureSessions && futureSessions.length > 0) {
      return NextResponse.json(
        {
          error:
            'Cannot delete class with upcoming sessions. Cancel or reassign those sessions first.',
        },
        { status: 409 }
      );
    }

    const { data: existing, error: lookupError } = await supabase
      .from('classes')
      .select(CLASS_SELECT)
      .eq('id', id)
      .maybeSingle();

    if (lookupError) {
      throw lookupError;
    }

    if (!existing) {
      return NextResponse.json({ error: 'Class not found' }, { status: 404 });
    }

    const { error } = await supabase.from('classes').delete().eq('id', id);

    if (error) {
      throw error;
    }

    const mapped = mapDbClassToUiClass(existing);

    return NextResponse.json({ class: mapped }, { status: 200 });
  } catch (error) {
    console.error('Failed to delete class', error);
    const message =
      error instanceof Error ? error.message : 'Failed to delete class';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
