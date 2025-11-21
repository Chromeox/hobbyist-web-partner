import type { Class, ClassFormData } from '@/types/class-management';

type Optional<T> = T | null | undefined;

type DbUserProfile = {
  first_name?: string | null;
  last_name?: string | null;
  email?: string | null;
};

type DbInstructor = {
  id?: string | null;
  name?: string | null;
  email?: string | null;
  user_profiles?: Optional<DbUserProfile>;
};

type DbCategory = {
  id?: string | null;
  name?: string | null;
  slug?: string | null;
};

type DbRecurringSettings = {
  enabled?: boolean | null;
  pattern?: 'weekly' | 'biweekly' | 'monthly' | null;
  days_of_week?: Optional<number[]>;
  daysOfWeek?: Optional<number[]>;
  end_date?: string | null;
  endDate?: string | null;
};

type DbClassRecord = {
  id?: string | null;
  name?: string | null;
  title?: string | null;
  description?: string | null;
  instructor_id?: string | null;
  instructorId?: string | null;
  instructors?: Optional<DbInstructor>;
  instructor?: Optional<DbInstructor>;
  category_id?: string | null;
  categories?: Optional<DbCategory>;
  category?: Optional<DbCategory>;
  difficulty_level?: string | null;
  level?: string | null;
  duration_minutes?: number | null;
  duration?: number | null;
  max_participants?: number | null;
  capacity?: number | null;
  price?: number | null;
  credit_cost?: number | null;
  creditCost?: number | null;
  tags?: Optional<string[]>;
  image_url?: string | null;
  image?: string | null;
  location?: string | null;
  status?: string | null;
  rating?: number | null;
  total_bookings?: number | null;
  totalBookings?: number | null;
  created_at?: string | null;
  updated_at?: string | null;
  materials?: Optional<string[]>;
  prerequisites?: Optional<string[]>;
  cancellation_policy?: string | null;
  cancellationPolicy?: string | null;
  recurring_settings?: Optional<DbRecurringSettings>;
  recurring?: Optional<DbRecurringSettings>;
};

export const DEFAULT_CANCELLATION_POLICY = '24 hours before class starts';

const LEVEL_FALLBACK: Class['level'] = 'beginner';

const STATUS_MAP: Record<string, Class['status']> = {
  active: 'active',
  published: 'active',
  inactive: 'inactive',
  archived: 'inactive',
  cancelled: 'inactive',
  draft: 'draft',
};

const coerceLevel = (raw?: string | null): Class['level'] => {
  if (!raw) return LEVEL_FALLBACK;
  const normalised = raw.toLowerCase();
  if (normalised === 'beginner' || normalised === 'intermediate' || normalised === 'advanced') {
    return normalised;
  }
  return LEVEL_FALLBACK;
};

export const determineCreditCost = (price: number, existing?: number | null): number => {
  if (typeof existing === 'number' && existing > 0) return existing;
  if (!Number.isFinite(price) || price <= 0) return 1;
  return Math.max(1, Math.round(price / 20));
};

const parseRecurring = (input?: Optional<DbRecurringSettings>): ClassFormData['recurring'] => {
  if (!input) {
    return {
      enabled: false,
      pattern: 'weekly',
      daysOfWeek: [],
      endDate: undefined,
    };
  }

  const pattern = input.pattern ?? (input as any).pattern ?? 'weekly';
  const days = input.daysOfWeek ?? input.days_of_week ?? [];
  const normalisedPattern: 'weekly' | 'biweekly' | 'monthly' =
    pattern === 'biweekly' || pattern === 'monthly' ? pattern : 'weekly';

  return {
    enabled: Boolean(input.enabled),
    pattern: normalisedPattern,
    daysOfWeek: Array.isArray(days) ? days.filter((d) => Number.isInteger(d)) : [],
    endDate: input.endDate ?? input.end_date ?? undefined,
  };
};

const formatInstructorName = (instructor?: Optional<DbInstructor>) => {
  if (!instructor) return '';
  if (instructor.name) return instructor.name;

  const profile = instructor.user_profiles;
  const first = profile?.first_name?.trim() ?? '';
  const last = profile?.last_name?.trim() ?? '';
  const combined = `${first} ${last}`.trim();
  if (combined) return combined;

  return instructor.email ?? '';
};

export const mapDbClassToUiClass = (record: DbClassRecord): Class => {
  const id = record.id ?? '';
  const name = record.name ?? record.title ?? 'Untitled Class';
  const description = record.description ?? '';
  const instructorRelation = record.instructors ?? record.instructor;
  const instructorId = record.instructor_id ?? record.instructorId ?? instructorRelation?.id ?? '';
  const instructorEmail =
    instructorRelation?.email ??
    instructorRelation?.user_profiles?.email ??
    undefined;
  const instructorName = formatInstructorName(instructorRelation) || 'Unassigned Instructor';
  const categoryRelation = record.categories ?? record.category;
  const categoryName = categoryRelation?.name ?? 'General';
  const categoryId = record.category_id ?? categoryRelation?.id ?? undefined;

  const price = Number(record.price ?? 0);
  const creditCost = determineCreditCost(price, record.credit_cost ?? record.creditCost);

  return {
    id,
    name,
    description,
    instructor: instructorName,
    instructorId,
    instructorEmail,
    category: categoryName,
    categoryId,
    level: coerceLevel(record.difficulty_level ?? record.level ?? undefined),
    duration: Number(record.duration_minutes ?? record.duration ?? 60),
    capacity: Number(record.max_participants ?? record.capacity ?? 0),
    price,
    creditCost,
    image: record.image_url ?? record.image ?? undefined,
    tags: Array.isArray(record.tags) ? record.tags : [],
    location: record.location ?? 'Studio',
    status:
      STATUS_MAP[
        (record.status ?? 'draft').toString().toLowerCase()
      ] ?? 'draft',
    materials: Array.isArray(record.materials) ? record.materials : undefined,
    prerequisites: Array.isArray(record.prerequisites) ? record.prerequisites : undefined,
    cancellationPolicy: record.cancellation_policy ?? record.cancellationPolicy ?? undefined,
    recurring: parseRecurring(record.recurring_settings ?? record.recurring),
    rating: Number(record.rating ?? 0),
    totalBookings: Number(record.total_bookings ?? record.totalBookings ?? 0),
    createdAt: record.created_at ?? new Date().toISOString(),
    updatedAt: record.updated_at ?? new Date().toISOString(),
    nextSession: undefined,
  };
};

export const mapClassToFormData = (cls: Class): ClassFormData => ({
  id: cls.id,
  name: cls.name,
  description: cls.description,
  instructor: cls.instructor,
  instructorId: cls.instructorId,
  instructorEmail: cls.instructorEmail,
  category: cls.category,
  categoryId: cls.categoryId,
  level: cls.level,
  duration: cls.duration,
  capacity: cls.capacity,
  price: cls.price,
  creditCost: cls.creditCost,
  image: cls.image,
  tags: cls.tags ?? [],
  location: cls.location,
  status: cls.status,
  recurring: cls.recurring ?? {
    enabled: false,
    pattern: 'weekly',
    daysOfWeek: [],
    endDate: undefined,
  },
  materials: cls.materials ?? [],
  prerequisites: cls.prerequisites ?? [],
  cancellationPolicy: cls.cancellationPolicy ?? DEFAULT_CANCELLATION_POLICY,
  wheelchairAccessible: (cls as any).wheelchairAccessible ?? false,
});

export type ClassUpsertPayload = {
  id?: string;
  instructor_id: string;
  category_id: string;
  name: string;
  description: string;
  difficulty_level: 'beginner' | 'intermediate' | 'advanced';
  duration_minutes: number;
  max_participants: number;
  price: number;
  credit_cost: number;
  tags: string[];
  image_url?: string;
  location?: string;
  status: 'draft' | 'published' | 'cancelled' | 'completed';
  materials?: string[];
  prerequisites?: string[];
  cancellation_policy?: string;
  recurring_settings?: ClassFormData['recurring'];
  created_at?: string;
  updated_at?: string;
  studio_id?: string;
};

export const mapFormDataToUpsertPayload = (
  form: ClassFormData,
  categoryId: string
): ClassUpsertPayload => ({
  id: form.id,
  instructor_id: form.instructorId,
  category_id: categoryId,
  name: form.name,
  description: form.description,
  difficulty_level: form.level,
  duration_minutes: form.duration,
  max_participants: form.capacity,
  price: form.price,
  credit_cost: form.creditCost,
  tags: form.tags,
  image_url: form.image,
  location: form.location,
  status: form.status === 'active' ? 'published' : form.status === 'inactive' ? 'cancelled' : 'draft',
  materials: form.materials && form.materials.length > 0 ? form.materials : undefined,
  prerequisites: form.prerequisites && form.prerequisites.length > 0 ? form.prerequisites : undefined,
  cancellation_policy: form.cancellationPolicy,
  recurring_settings: form.recurring,
});
