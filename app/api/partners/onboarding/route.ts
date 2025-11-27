import { NextResponse } from 'next/server'
import { createServiceSupabase } from '@/lib/supabase'
import type { Json } from '@/types/supabase'

export const dynamic = 'force-dynamic';


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

    // Validate user ID is provided
    if (!owner?.userId) {
      return NextResponse.json(
        { error: 'User ID is required. Please ensure you are logged in.' },
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

    const sanitisedSocialLinks = Object.fromEntries(
      Object.entries(studioProfile?.socialMedia ?? {}).filter(
        ([, value]) => typeof value === 'string' && value.trim().length > 0
      )
    )

    const profilePayload: Json = {
      tagline: studioProfile?.tagline ?? '',
      description: studioProfile?.description ?? '',
      specialties: studioProfile?.specialties ?? [],
      yearEstablished: businessInfo.yearEstablished ?? null
    }

    type StudiosInsert = {
      name: string
      email: string
      phone?: string | null
      address_line1?: string | null      // Fixed: was 'address'
      city?: string | null
      state?: string | null              // Fixed: was 'province'
      postal_code?: string | null
      country?: string | null
      website?: string | null
      description?: string | null
      profile?: Json
      social_links?: Json
      amenities?: string[]
      commission_rate?: number | null
      stripe_account_id?: string | null
      is_active?: boolean                // NEW: for approval workflow
      approval_status?: string           // NEW: for approval workflow
      onboarding_completed?: boolean     // NEW: track completion
      onboarding_completed_at?: string   // NEW: completion timestamp
    }

    type StudiosUpdate = StudiosInsert & {
      updated_at?: string
    }

    // Extract Stripe Account ID from payment payload
    const stripeAccountId = payload.payment?.accountId as string | undefined;

    const baseStudioData: StudiosInsert = {
      name: studioName,
      email: contactEmail,
      phone: businessInfo.businessPhone ?? null,
      address_line1: businessInfo.address?.street ?? null,    // Fixed: was 'address'
      city: businessInfo.address?.city ?? null,
      state: businessInfo.address?.state ?? null,             // Fixed: was 'province'
      postal_code: businessInfo.address?.zipCode ?? null,
      country: businessInfo.address?.country ?? 'CA',         // Default to Canada
      website: studioProfile?.socialMedia?.website ?? null,   // NEW: website from social
      description: studioProfile?.description ?? null,        // NEW: description
      profile: profilePayload,
      social_links: sanitisedSocialLinks as Json,
      amenities: studioProfile?.amenities ?? [],
      stripe_account_id: stripeAccountId ?? null,
      is_active: false,                                       // NEW: inactive until approved
      approval_status: 'pending',                             // NEW: requires admin approval
      onboarding_completed: true,                             // NEW: mark as completed
      onboarding_completed_at: new Date().toISOString()       // NEW: completion timestamp
    } satisfies StudiosInsert

    // Upsert studio by email (unique)
    const { data: existingStudio, error: fetchStudioError } = await (supabase as any)
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
      const studioUpdate: StudiosUpdate = {
        ...baseStudioData,
        updated_at: new Date().toISOString()
      }

      const { error: updateError } = await (supabase as any)
        .from('studios')
        .update(studioUpdate)
        .eq('id', studioId)

      if (updateError) {
        console.error('Error updating studio:', updateError)
        return NextResponse.json(
          { error: 'Failed to update existing studio', details: updateError.message },
          { status: 500 }
        )
      }
    } else {
      const studioInsert: StudiosInsert = {
        ...baseStudioData,
        commission_rate: 0.30  // 30% platform fee (70% to studio)
      }

      const { data: insertStudio, error: insertError } = await (supabase as any)
        .from('studios')
        .insert(studioInsert)
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
        await (supabase as any)
          .from('instructors')
          .select('id')
          .eq('studio_id', studioId)
          .eq('email', (owner.email ?? contactEmail).toLowerCase())
          .limit(1)

      if (existingInstructorError) {
        console.error('Error fetching instructor:', existingInstructorError)
      } else if (!existingInstructor || existingInstructor.length === 0) {
        const { error: insertInstructorError } = await (supabase as any)
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

    // Create first class if provided in payload
    let firstClassId: string | null = null
    let firstSessionId: string | null = null

    if (payload.firstClass && studioId) {
      const firstClass = payload.firstClass as {
        name: string
        categoryId: string
        description: string
        duration: number
        price: string | number
        capacity: number
        skillLevel?: string
        firstSessionDate: string
        firstSessionTime: string
      }

      // Insert class into private.studio_classes
      const classData = {
        studio_id: studioId,
        name: firstClass.name,
        description: firstClass.description,
        category_id: firstClass.categoryId || null,
        price: parseFloat(String(firstClass.price)) || 0,
        duration_minutes: parseInt(String(firstClass.duration)) || 60,
        capacity: parseInt(String(firstClass.capacity)) || 10,
        level: firstClass.skillLevel || 'all_levels',
        status: 'draft',  // Draft until studio is approved
        is_featured: false,
        is_online: false
      }

      const { data: classRecord, error: classError } = await (supabase as any)
        .from('studio_classes')
        .insert(classData)
        .select('id')
        .single()

      if (classError) {
        console.error('Error creating first class:', classError)
      } else if (classRecord?.id) {
        firstClassId = classRecord.id
        console.log('✅ First class created:', firstClassId)

        // Create first session
        const startDateTime = new Date(`${firstClass.firstSessionDate}T${firstClass.firstSessionTime}`)
        const durationMs = (parseInt(String(firstClass.duration)) || 60) * 60 * 1000
        const endDateTime = new Date(startDateTime.getTime() + durationMs)

        const sessionData = {
          class_id: firstClassId,
          start_time: startDateTime.toISOString(),
          end_time: endDateTime.toISOString(),
          available_spots: parseInt(String(firstClass.capacity)) || 10,
          is_cancelled: false
        }

        const { data: sessionRecord, error: sessionError } = await (supabase as any)
          .from('class_sessions')
          .insert(sessionData)
          .select('id')
          .single()

        if (sessionError) {
          console.error('Error creating first session:', sessionError)
        } else if (sessionRecord?.id) {
          firstSessionId = sessionRecord.id
          console.log('✅ First session created:', firstSessionId)
        }
      }
    }

    // Store raw onboarding submission for audit trail
    type OnboardingSubmissionInsert = {
      user_id?: string | null
      email: string
      business_name: string
      status?: string
      studio_id?: string | null
      submitted_data: Json
      verification_documents?: Json | null
      payment_setup?: Json | null
    }

    const submissionPayload: OnboardingSubmissionInsert = {
      user_id: owner?.userId ?? null,
      email: contactEmail,
      business_name: studioName,
      status: 'completed',
      studio_id: studioId,
      submitted_data: payload as unknown as Json,
      verification_documents: (payload.verification ?? {}) as Json,
      payment_setup: (payload.payment ?? {}) as Json
    }

    const { data: submissionRecord, error: submissionError } = await supabase
      .from('studio_onboarding_submissions')
      .insert(submissionPayload)
      .select('id')
      .single()

    if (submissionError) {
      console.error('Error saving onboarding submission:', submissionError)
      // proceed but include warning
    }

    return NextResponse.json(
      {
        message: 'Studio onboarding data stored successfully',
        studioId,
        submissionId: submissionRecord?.id ?? null,
        firstClassId: firstClassId ?? null,
        firstSessionId: firstSessionId ?? null,
        approvalStatus: 'pending',  // Remind client that approval is needed
        note: 'Your studio is pending admin approval. You will be notified once approved.'
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
