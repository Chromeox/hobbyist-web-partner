import { NextResponse } from 'next/server';
import { createServiceSupabase } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabase = createServiceSupabase();
    const { data, error } = await supabase
      .from('categories')
      .select('id, name, slug, is_active')
      .eq('is_active', true)
      .order('name', { ascending: true });

    if (error) {
      throw error;
    }

    return NextResponse.json({
      categories: (data ?? []).map((category: any) => ({
        id: category.id,
        name: category.name,
        slug: category.slug,
        isActive: category.is_active,
      })),
    });
  } catch (error) {
    console.error('Failed to fetch categories', error);
    return NextResponse.json(
      { error: 'Failed to fetch categories' },
      { status: 500 }
    );
  }
}
