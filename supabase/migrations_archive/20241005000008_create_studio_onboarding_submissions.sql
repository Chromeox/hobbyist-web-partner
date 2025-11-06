CREATE TABLE IF NOT EXISTS public.studio_onboarding_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    email TEXT NOT NULL,
    business_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    studio_id UUID REFERENCES public.studios(id),
    submitted_data JSONB NOT NULL,
    verification_documents JSONB DEFAULT '{}'::jsonb,
    payment_setup JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_studio_onboarding_email ON public.studio_onboarding_submissions (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_studio_onboarding_status ON public.studio_onboarding_submissions (status);

ALTER TABLE public.studio_onboarding_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Submitter can view own onboarding submissions" ON public.studio_onboarding_submissions;
CREATE POLICY "Submitter can view own onboarding submissions"
ON public.studio_onboarding_submissions
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Submitter can update pending submissions" ON public.studio_onboarding_submissions;
CREATE POLICY "Submitter can update pending submissions"
ON public.studio_onboarding_submissions
FOR UPDATE
USING (auth.uid() = user_id AND status = 'pending')
WITH CHECK (auth.uid() = user_id AND status = 'pending');

DROP POLICY IF EXISTS "Service role full access to onboarding submissions" ON public.studio_onboarding_submissions;
CREATE POLICY "Service role full access to onboarding submissions"
ON public.studio_onboarding_submissions
FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');
