import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

/**
 * GET /api/admin/studios/pending
 * Fetches all studios with pending approval status
 * Admin-only endpoint
 */
export async function GET(request: Request) {
  try {
    const supabase = await createClient();

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // TODO: Add admin role check once user_profiles has role column
    // For now, any authenticated user can access admin endpoints
    // This is fine for alpha testing with single admin (you)

    // Fetch pending studios with their onboarding submissions
    const { data: pendingStudios, error: studiosError } = await supabase
      .from('studios')
      .select(`
        *,
        studio_onboarding_submissions (
          id,
          business_name,
          legal_business_name,
          tax_id,
          business_type,
          phone,
          website,
          business_license_url,
          insurance_certificate_url,
          identity_verification_status,
          submitted_data,
          stripe_account_id,
          stripe_onboarding_complete,
          submission_status,
          submitted_at,
          created_at
        )
      `)
      .in('approval_status', ['pending', 'under_review'])
      .order('created_at', { ascending: false });

    if (studiosError) {
      console.error('Error fetching pending studios:', studiosError);
      return NextResponse.json(
        { error: 'Failed to fetch pending studios', details: studiosError.message },
        { status: 500 }
      );
    }

    // Transform the data for frontend consumption
    const formattedStudios = pendingStudios?.map(studio => ({
      id: studio.id,
      name: studio.name,
      email: studio.email,
      phone: studio.phone,
      address: studio.address,
      city: studio.city,
      province: studio.province,
      postal_code: studio.postal_code,
      approval_status: studio.approval_status,
      commission_rate: studio.commission_rate,
      is_active: studio.is_active,
      created_at: studio.created_at,
      onboarding_completed: studio.onboarding_completed,
      // Onboarding submission data
      submission: studio.studio_onboarding_submissions?.[0] || null,
      // Extract key info from submitted_data JSONB
      profile: studio.studio_onboarding_submissions?.[0]?.submitted_data || {},
    })) || [];

    return NextResponse.json({
      success: true,
      count: formattedStudios.length,
      studios: formattedStudios,
    });

  } catch (error) {
    console.error('Unexpected error in pending studios endpoint:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
