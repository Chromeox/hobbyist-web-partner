import { NextResponse } from 'next/server'
import { createServiceSupabase } from '@/lib/supabase'

type OnboardingPayload = {
  owner?: {
    name?: string
    email?: string
    accountType?: string
    businessName?: string
    userId?: string
  }
  businessInfo?: {
    legalBusinessName?: string
    businessType?: string
    taxId?: string
    businessPhone?: string
    contactEmail?: string
    address?: {
      street?: string
      city?: string
      state?: string
      zipCode?: string
      country?: string
    }
    yearEstablished?: string
  }
  studioProfile?: {
    tagline?: string
    description?: string
    specialties?: string[]
    amenities?: string[]
    photos?: string[]
    socialMedia?: Record<string, string>
  }
  verification?: Record<string, unknown>
  services?: Record<string, unknown>
  payment?: Record<string, unknown>
  [key: string]: any
}

export async function POST(request: Request) {
  const supabase = createServiceSupabase()

  if (!supabase) {
    return NextResponse.json(
      { error: 'Supabase service client not configured' },
      { status: 500 }
    )
  }

  try {
    const payload = (await request.json()) as OnboardingPayload

    const { businessInfo, studioProfile, owner } = payload

    if (!businessInfo) {
      return NextResponse.json(
        { error: 'Business information is required' },
        { status: 400 }
      )
    }

    const contactEmail =
      businessInfo.contactEmail?.trim().toLowerCase() ||
      owner?.email?.trim().toLowerCase()

    if (!contactEmail) {
      return NextResponse.json(
        { error: 'A contact email is required to create a studio' },
        { status: 400 }
      )
    }

    const studioName =
      businessInfo.legalBusinessName ||
      owner?.businessName ||
      'Pending Studio'

    // Build studio payload
    const studioPayload: Record<string, any> = {
      name: studioName,
      email: contactEmail,
      phone: businessInfo.businessPhone ?? null,
      address: businessInfo.address?.street ?? null,
      city: businessInfo.address?.city ?? null,
      province: businessInfo.address?.state ?? null,
      postal_code: businessInfo.address?.zipCode ?? null,
      profile: {
        tagline: studioProfile?.tagline ?? '',
        description: studioProfile?.description ?? '',
        specialties: studioProfile?.specialties ?? [],
        yearEstablished: businessInfo.yearEstablished ?? null
      },
      social_links: studioProfile?.socialMedia ?? {},
      amenities: studioProfile?.amenities ?? []
    }

    // Upsert studio by email (unique)
    const { data: existingStudio, error: fetchStudioError } = await supabase
      .from('studios')
      .select('id')
      .eq('email', contactEmail)
      .limit(1)

    if (fetchStudioError) {
      console.error('Error fetching existing studio:', fetchStudioError)
      return NextResponse.json(
        { error: 'Failed to look up existing studio', details: fetchStudioError.message },
        { status: 500 }
      )
    }

    let studioId: string | undefined = existingStudio?.[0]?.id

    if (studioId) {
      const { error: updateError } = await supabase
        .from('studios')
        .update({
          ...studioPayload,
          updated_at: new Date().toISOString()
        })
        .eq('id', studioId)

      if (updateError) {
        console.error('Error updating studio:', updateError)
        return NextResponse.json(
          { error: 'Failed to update existing studio', details: updateError.message },
          { status: 500 }
        )
      }
    } else {
      const { data: insertStudio, error: insertError } = await supabase
        .from('studios')
        .insert({
          ...studioPayload,
          commission_rate: 25.0
        })
        .select('id')
        .single()

      if (insertError) {
        console.error('Error creating studio:', insertError)
        return NextResponse.json(
          { error: 'Failed to create studio', details: insertError.message },
          { status: 500 }
        )
      }

      studioId = insertStudio.id
    }

    if (!studioId) {
      return NextResponse.json(
        { error: 'Studio identifier missing after upsert' },
        { status: 500 }
      )
    }

    // Upsert instructor/owner record
    if (owner?.name || owner?.email) {
      const { data: existingInstructor, error: existingInstructorError } =
        await supabase
          .from('instructors')
          .select('id')
          .eq('studio_id', studioId)
          .eq('email', (owner.email ?? contactEmail).toLowerCase())
          .limit(1)

      if (existingInstructorError) {
        console.error('Error fetching instructor:', existingInstructorError)
      } else if (!existingInstructor || existingInstructor.length === 0) {
        const { error: insertInstructorError } = await supabase
          .from('instructors')
          .insert({
            studio_id: studioId,
            name: owner.name ?? 'Studio Owner',
            email: owner.email ?? contactEmail,
            specialties: studioProfile?.specialties ?? [],
            is_active: true
          })

        if (insertInstructorError) {
          console.error('Error creating instructor:', insertInstructorError)
        }
      }
    }

    // Store raw onboarding submission for audit trail
    const submissionInsert = await supabase
      .from('studio_onboarding_submissions')
      .insert({
        user_id: owner?.userId ?? null,
        email: contactEmail,
        business_name: studioName,
        status: 'completed',
        studio_id: studioId,
        submitted_data: payload,
        verification_documents: payload.verification ?? {},
        payment_setup: payload.payment ?? {}
      })

    if (submissionInsert.error) {
      console.error('Error saving onboarding submission:', submissionInsert.error)
      // proceed but include warning
    }

    return NextResponse.json(
      {
        message: 'Studio onboarding data stored successfully',
        studioId,
        submissionId: submissionInsert.data?.[0]?.id ?? null
      },
      { status: 201 }
    )
  } catch (error: any) {
    console.error('Onboarding handler error:', error)
    return NextResponse.json(
      {
        error: 'Unexpected error handling onboarding',
        details: error?.message ?? 'Unknown error'
      },
      { status: 500 }
    )
  }
}
