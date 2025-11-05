'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  X,
  Save,
  Clock,
  Tag,
  MapPin,
  User,
  Calendar,
  Image as ImageIcon,
  AlertCircle,
  CreditCard,
  BookOpen,
  Plus,
  Minus,
  Loader2,
} from 'lucide-react';
import type { ClassFormData } from '@/types/class-management';

interface InstructorOption {
  id: string;
  name: string;
}

interface CategoryOption {
  id: string;
  name: string;
}

interface ClassEditorProps {
  onClose: () => void;
  class?: ClassFormData;
  onSave: (data: ClassFormData) => Promise<void>;
  studioId: string | null;
}

const FALLBACK_CATEGORIES = [
  'Pottery & Ceramics',
  'Painting & Drawing',
  'Fiber Arts',
  'Woodworking',
  'Metalworking',
  'Jewelry Making',
  'Glass Art',
  'Sculpture',
  'Mixed Media',
  'Digital Arts',
];

const FALLBACK_LOCATIONS = [
  'Main Studio',
  'Workshop Room A',
  'Workshop Room B',
  'Kiln Room',
  'Outdoor Workspace',
  'Private Studio',
];

const NEW_CATEGORY_VALUE = '__new_category__';

export default function ClassEditor({ onClose, class: classData, onSave, studioId }: ClassEditorProps) {
  const [formData, setFormData] = useState<ClassFormData>({
    name: '',
    description: '',
    instructor: '',
    instructorId: '',
    category: FALLBACK_CATEGORIES[0] || '',
    categoryId: undefined,
    level: 'beginner',
    duration: 60,
    capacity: 8,
    price: 50,
    creditCost: 1,
    image: '',
    tags: [],
    location: FALLBACK_LOCATIONS[0] || '',
    status: 'draft',
    recurring: {
      enabled: false,
      pattern: 'weekly',
      daysOfWeek: [],
      endDate: '',
    },
    materials: [],
    prerequisites: [],
    cancellationPolicy: '24 hours before class starts',
  });

  const [newTag, setNewTag] = useState('');
  const [newMaterial, setNewMaterial] = useState('');
  const [newPrerequisite, setNewPrerequisite] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [instructors, setInstructors] = useState<InstructorOption[]>([]);
  const [categories, setCategories] = useState<CategoryOption[]>([]);
  const [loadingCatalogs, setLoadingCatalogs] = useState(true);
  const [catalogError, setCatalogError] = useState<string | null>(null);
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');

  useEffect(() => {
    if (classData) {
      setFormData({
        ...classData,
        recurring: classData.recurring || {
          enabled: false,
          pattern: 'weekly',
          daysOfWeek: [],
          endDate: '',
        },
        materials: classData.materials || [],
        prerequisites: classData.prerequisites || [],
        cancellationPolicy: classData.cancellationPolicy || '24 hours before class starts',
      });
      setIsAddingCategory(false);
      setNewCategoryName('');
      setSubmitError(null);
    }
  }, [classData]);

  useEffect(() => {
    let cancelled = false;

    const loadOptions = async () => {
      setLoadingCatalogs(true);
      setCatalogError(null);

      try {
        const instructorUrl = studioId
          ? `/api/instructors?studioId=${studioId}`
          : '/api/instructors?limit=100';

        const [instructorResp, categoryResp] = await Promise.all([
          fetch(instructorUrl),
          fetch('/api/categories'),
        ]);

        if (cancelled) return;

        if (!instructorResp.ok) {
          throw new Error('Unable to load instructors');
        }
        if (!categoryResp.ok) {
          throw new Error('Unable to load categories');
        }

        const instructorPayload = await instructorResp.json();
        const instructorItems: InstructorOption[] = Array.isArray(instructorPayload?.instructors)
          ? instructorPayload.instructors
              .map((item: any) => ({
                id: item.id ?? item.user_id ?? '',
                name:
                  item.name ||
                  `${item.first_name ?? ''} ${item.last_name ?? ''}`.trim() ||
                  item.email ||
                  'Instructor',
              }))
              .filter((item: InstructorOption) => item.id)
          : [];

        const categoryPayload = await categoryResp.json();
        const categoryItemsRaw: CategoryOption[] = Array.isArray(categoryPayload?.categories)
          ? categoryPayload.categories
              .map((item: any) => ({
                id: item.id ?? '',
                name: item.name ?? item.slug ?? 'Category',
              }))
              .filter((item: CategoryOption) => item.id)
          : [];

        const normalizedCategories =
          categoryItemsRaw.length > 0
            ? categoryItemsRaw
            : FALLBACK_CATEGORIES.map((name, index) => ({
                id: `fallback-${index}`,
                name,
              }));

        setInstructors(instructorItems);
        setCategories(normalizedCategories);

        setFormData((prev) => {
          const fallbackInstructor = instructorItems[0];
          const fallbackCategory = normalizedCategories[0];
          const fallbackCategoryId =
            fallbackCategory && !fallbackCategory.id.startsWith('fallback-')
              ? fallbackCategory.id
              : undefined;

          return {
            ...prev,
            instructor: prev.instructor || fallbackInstructor?.name || prev.instructor,
            instructorId: prev.instructorId || fallbackInstructor?.id || prev.instructorId,
            category: prev.category || fallbackCategory?.name || prev.category,
            categoryId: prev.categoryId || fallbackCategoryId,
          };
        });
      } catch (err) {
        if (cancelled) return;
        console.error(err);
        setCatalogError(err instanceof Error ? err.message : 'Failed to load reference data.');
        setInstructors([]);
        setCategories([]);
      } finally {
        if (!cancelled) {
          setLoadingCatalogs(false);
        }
      }
    };

    loadOptions();

    return () => {
      cancelled = true;
    };
  }, [studioId]);

  const statusOptions = useMemo(
    () => [
      { label: 'Active', value: 'active' },
      { label: 'Draft', value: 'draft' },
      { label: 'Inactive', value: 'inactive' },
    ],
    []
  );

  const hasInstructors = instructors.length > 0;

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) newErrors.name = 'Class name is required';
    if (!formData.description.trim()) newErrors.description = 'Description is required';
    if (!formData.category && !formData.categoryId)
      newErrors.category = 'Category is required';
    if (!formData.instructorId) newErrors.instructor = 'Instructor is required';
    if (!formData.location.trim()) newErrors.location = 'Location is required';
    if (formData.duration < 15) newErrors.duration = 'Duration must be at least 15 minutes';
    if (formData.capacity < 1) newErrors.capacity = 'Capacity must be at least 1';
    if (formData.price < 0) newErrors.price = 'Price cannot be negative';
    if (formData.creditCost < 1) newErrors.creditCost = 'Credit cost must be at least 1';

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    try {
      setSubmitError(null);
      setIsSubmitting(true);
      await onSave(formData);
      onClose();
    } catch (error) {
      console.error(error);
      setSubmitError(error instanceof Error ? error.message : 'Failed to save class');
    } finally {
      setIsSubmitting(false);
    }
  };

  const addTag = () => {
    const trimmed = newTag.trim();
    if (!trimmed || formData.tags.includes(trimmed)) return;

    setFormData((prev) => ({
      ...prev,
      tags: [...prev.tags, trimmed],
    }));
    setNewTag('');
  };

  const removeTag = (tagToRemove: string) => {
    setFormData((prev) => ({
      ...prev,
      tags: prev.tags.filter((tag) => tag !== tagToRemove),
    }));
  };

  const addMaterial = () => {
    const trimmed = newMaterial.trim();
    if (!trimmed || formData.materials?.includes(trimmed)) return;

    setFormData((prev) => ({
      ...prev,
      materials: [...(prev.materials || []), trimmed],
    }));
    setNewMaterial('');
  };

  const removeMaterial = (materialToRemove: string) => {
    setFormData((prev) => ({
      ...prev,
      materials: (prev.materials || []).filter((material) => material !== materialToRemove),
    }));
  };

  const addPrerequisite = () => {
    const trimmed = newPrerequisite.trim();
    if (!trimmed || formData.prerequisites?.includes(trimmed)) return;

    setFormData((prev) => ({
      ...prev,
      prerequisites: [...(prev.prerequisites || []), trimmed],
    }));
    setNewPrerequisite('');
  };

  const removePrerequisite = (prerequisiteToRemove: string) => {
    setFormData((prev) => ({
      ...prev,
      prerequisites: (prev.prerequisites || []).filter(
        (item) => item !== prerequisiteToRemove
      ),
    }));
  };

  const handleInstructorChange = (instructorId: string) => {
    const match = instructors.find((item) => item.id === instructorId);
    setFormData((prev) => ({
      ...prev,
      instructorId,
      instructor: match?.name || prev.instructor,
    }));
  };

  const handleCategorySelect = (value: string) => {
    if (value === NEW_CATEGORY_VALUE) {
      setIsAddingCategory(true);
      setNewCategoryName(formData.category ?? '');
      setFormData((prev) => ({
        ...prev,
        categoryId: undefined,
      }));
      return;
    }

    const match =
      categories.find((cat) => cat.id === value) ??
      categories.find((cat) => cat.name === value);

    if (match) {
      setIsAddingCategory(false);
      setNewCategoryName('');
      setFormData((prev) => ({
        ...prev,
        category: match.name,
        categoryId:
          match.id && !match.id.startsWith('fallback-') ? match.id : undefined,
      }));
      return;
    }

    setIsAddingCategory(false);
    setNewCategoryName('');
    setFormData((prev) => ({
      ...prev,
      category: value,
      categoryId: undefined,
    }));
  };

  const handleNewCategoryChange = (value: string) => {
    setNewCategoryName(value);
    setFormData((prev) => ({
      ...prev,
      category: value,
      categoryId: undefined,
    }));
  };

  const cancelNewCategory = () => {
    setIsAddingCategory(false);
    setNewCategoryName('');
  };

  const dayNames = useMemo(
    () => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    []
  );

  const locationOptions = useMemo(() => {
    const set = new Set<string>(FALLBACK_LOCATIONS);
    if (formData.location) {
      set.add(formData.location);
    }
    return Array.from(set);
  }, [formData.location]);

  const hasCurrentCategory = useMemo(() => {
    if (!formData.category) return false;
    if (formData.categoryId) {
      return categories.some((cat) => cat.id === formData.categoryId);
    }
    return categories.some(
      (cat) => cat.name.toLowerCase() === formData.category.toLowerCase()
    );
  }, [categories, formData.category, formData.categoryId]);

  const recurringState = formData.recurring ?? {
    enabled: false,
    pattern: 'weekly' as const,
    daysOfWeek: [],
    endDate: '',
  };

  const saveDisabled = isSubmitting || (!hasInstructors && !loadingCatalogs);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        className="flex h-full max-h-[90vh] w-full max-w-4xl flex-col overflow-hidden rounded-xl bg-white shadow-xl"
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4">
          <div>
            <h2 className="text-2xl font-semibold text-gray-900">
              {classData?.id ? 'Edit Class' : 'Create New Class'}
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Configure the core details, pricing, and schedule preferences for this class.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {loadingCatalogs && (
              <span className="inline-flex items-center gap-2 rounded-lg border border-blue-100 bg-blue-50 px-3 py-1 text-sm font-medium text-blue-600">
                <Loader2 className="h-4 w-4 animate-spin" />
                Syncing
              </span>
            )}
            <button
              onClick={onClose}
              className="rounded-lg p-2 text-gray-500 transition-colors hover:bg-gray-100"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        {(catalogError || submitError) && (
          <div className="px-6 pt-4">
            {catalogError && (
              <div className="mb-3 flex items-start gap-3 rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-700">
                <AlertCircle className="mt-0.5 h-4 w-4" />
                <span>{catalogError}</span>
              </div>
            )}
            {submitError && (
              <div className="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-600">
                <AlertCircle className="mt-0.5 h-4 w-4" />
                <span>{submitError}</span>
              </div>
            )}
          </div>
        )}

        <div className="flex-1 overflow-y-auto px-6 py-6">
          <div className="space-y-8">
            {/* Basic Information */}
            <div className="space-y-6">
              <div className="flex items-center gap-2">
                <BookOpen className="h-5 w-5 text-blue-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Basic Information
                </h3>
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Class Name *
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) =>
                      setFormData((prev) => ({ ...prev, name: e.target.value }))
                    }
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.name ? 'border-red-300' : 'border-gray-300'
                    }`}
                    placeholder="e.g., Beginner Pottery Wheel"
                  />
                  {errors.name && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.name}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Category *
                  </label>
                  {!isAddingCategory ? (
                    <select
                      value={formData.categoryId ?? formData.category ?? ''}
                      onChange={(e) => handleCategorySelect(e.target.value)}
                      disabled={loadingCatalogs}
                      className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        errors.category ? 'border-red-300' : 'border-gray-300'
                      }`}
                    >
                      <option value="">Select a category</option>
                      {categories.map((categoryOption) => (
                        <option
                          key={categoryOption.id}
                          value={categoryOption.id || categoryOption.name}
                        >
                          {categoryOption.name}
                        </option>
                      ))}
                      {formData.category && (!formData.categoryId || !hasCurrentCategory) && (
                        <option value={formData.category}>{formData.category}</option>
                      )}
                      <option value={NEW_CATEGORY_VALUE}>+ Add new category</option>
                    </select>
                  ) : (
                    <div className="space-y-2">
                      <input
                        type="text"
                        value={newCategoryName}
                        onChange={(e) => handleNewCategoryChange(e.target.value)}
                        placeholder="Enter a category name"
                        className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                          errors.category ? 'border-red-300' : 'border-gray-300'
                        }`}
                      />
                      <div className="flex flex-wrap gap-2 text-xs text-gray-500">
                        <span>Examples:</span>
                        {FALLBACK_CATEGORIES.slice(0, 4).map((item) => (
                          <button
                            key={item}
                            type="button"
                            onClick={() => handleNewCategoryChange(item)}
                            className="rounded-full border border-gray-200 px-3 py-1 text-gray-600 transition-colors hover:bg-gray-100"
                          >
                            {item}
                          </button>
                        ))}
                      </div>
                      <button
                        type="button"
                        onClick={cancelNewCategory}
                        className="text-sm font-medium text-blue-600 hover:text-blue-700"
                      >
                        ← Use existing category
                      </button>
                    </div>
                  )}
                  {errors.category && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.category}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Skill Level
                  </label>
                  <select
                    value={formData.level}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        level: e.target.value as ClassFormData['level'],
                      }))
                    }
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="beginner">Beginner</option>
                    <option value="intermediate">Intermediate</option>
                    <option value="advanced">Advanced</option>
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        status: e.target.value as ClassFormData['status'],
                      }))
                    }
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {statusOptions.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-gray-700">
                  Description *
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData((prev) => ({ ...prev, description: e.target.value }))
                  }
                  rows={4}
                  className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    errors.description ? 'border-red-300' : 'border-gray-300'
                  }`}
                  placeholder="Describe what students will learn and create in this class..."
                />
                {errors.description && (
                  <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                    <AlertCircle className="h-4 w-4" />
                    {errors.description}
                  </p>
                )}
              </div>
            </div>

            {/* Instructor & Location */}
            <div className="space-y-6">
              <div className="flex items-center gap-2">
                <User className="h-5 w-5 text-green-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Instructor & Location
                </h3>
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Instructor *
                  </label>
                  <select
                    value={formData.instructorId}
                    onChange={(e) => handleInstructorChange(e.target.value)}
                    disabled={!hasInstructors}
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.instructor ? 'border-red-300' : 'border-gray-300'
                    }`}
                  >
                    <option value="">
                      {loadingCatalogs ? 'Loading instructors…' : 'Select an instructor'}
                    </option>
                    {instructors.map((instructor) => (
                      <option key={instructor.id} value={instructor.id}>
                        {instructor.name}
                      </option>
                    ))}
                  </select>
                  {!hasInstructors && !loadingCatalogs && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-amber-600">
                      <AlertCircle className="h-4 w-4" />
                      Add instructors first or refresh the page.
                    </p>
                  )}
                  {errors.instructor && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.instructor}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 flex items-center gap-2 text-sm font-medium text-gray-700">
                    <MapPin className="h-4 w-4 text-gray-500" />
                    Location *
                  </label>
                  <input
                    list="class-location-options"
                    value={formData.location}
                    onChange={(e) =>
                      setFormData((prev) => ({ ...prev, location: e.target.value }))
                    }
                    className={`w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.location ? 'border-red-300' : 'border-gray-300'
                    }`}
                    placeholder="e.g., Main Studio"
                  />
                  <datalist id="class-location-options">
                    {locationOptions.map((option) => (
                      <option key={option} value={option} />
                    ))}
                  </datalist>
                  {errors.location && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.location}
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Class Details */}
            <div className="space-y-6">
              <div className="flex items-center gap-2">
                <Clock className="h-5 w-5 text-purple-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Class Details
                </h3>
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Duration (minutes) *
                  </label>
                  <input
                    type="number"
                    min={15}
                    step={15}
                    value={formData.duration}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        duration: Number.parseInt(e.target.value, 10) || 0,
                      }))
                    }
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.duration ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.duration && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.duration}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Capacity *
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={formData.capacity}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        capacity: Number.parseInt(e.target.value, 10) || 0,
                      }))
                    }
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.capacity ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.capacity && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.capacity}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Price ($) *
                  </label>
                  <input
                    type="number"
                    min={0}
                    step="0.01"
                    value={formData.price}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        price: Number.parseFloat(e.target.value) || 0,
                      }))
                    }
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.price ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.price && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.price}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 flex items-center gap-2 text-sm font-medium text-gray-700">
                    <CreditCard className="h-4 w-4 text-gray-500" />
                    Credit Cost *
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={formData.creditCost}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        creditCost: Number.parseInt(e.target.value, 10) || 1,
                      }))
                    }
                    className={`w-full rounded-lg border px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      errors.creditCost ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.creditCost && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-red-600">
                      <AlertCircle className="h-4 w-4" />
                      {errors.creditCost}
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Media */}
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <ImageIcon className="h-5 w-5 text-indigo-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Media
                </h3>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-gray-700">
                  Image URL
                </label>
                <input
                  type="url"
                  value={formData.image || ''}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      image: e.target.value,
                    }))
                  }
                  placeholder="https://example.com/class-image.jpg"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <p className="mt-1 text-xs text-gray-500">
                  Provide an external URL or leave blank to use the default class image.
                </p>
              </div>
            </div>

            {/* Tags */}
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <Tag className="h-5 w-5 text-orange-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Tags & Keywords
                </h3>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row">
                <input
                  type="text"
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      addTag();
                    }
                  }}
                  className="flex-1 rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Add tags (e.g., beginner-friendly, hands-on)"
                />
                <button
                  type="button"
                  onClick={addTag}
                  className="inline-flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700"
                >
                  <Plus className="h-4 w-4" />
                  Add Tag
                </button>
              </div>

              <div className="flex flex-wrap gap-2">
                {formData.tags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-3 py-1 text-sm text-blue-700"
                  >
                    {tag}
                    <button
                      type="button"
                      onClick={() => removeTag(tag)}
                      className="rounded-full p-0.5 text-blue-600 transition-colors hover:bg-blue-200"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
                {formData.tags.length === 0 && (
                  <p className="text-sm text-gray-500">No tags yet</p>
                )}
              </div>
            </div>

            {/* Recurring Schedule */}
            <div className="space-y-6">
              <div className="flex items-center gap-2">
                <Calendar className="h-5 w-5 text-indigo-600" />
                <h3 className="text-lg font-semibold text-gray-900">
                  Recurring Schedule (Optional)
                </h3>
              </div>

              <label className="flex items-center gap-3 text-sm text-gray-700">
                <input
                  type="checkbox"
                  checked={recurringState.enabled}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      recurring: {
                        ...recurringState,
                        enabled: e.target.checked,
                      },
                    }))
                  }
                  className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                Enable recurring schedule
              </label>

              {recurringState.enabled && (
                <div className="space-y-4 rounded-lg border border-gray-200 bg-gray-50 p-4">
                  <div>
                    <label className="mb-2 block text-sm font-medium text-gray-700">
                      Repeat Pattern
                    </label>
                    <select
                      value={recurringState.pattern}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          recurring: {
                            ...recurringState,
                            pattern: e.target.value as 'weekly' | 'biweekly' | 'monthly',
                          },
                        }))
                      }
                      className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="weekly">Weekly</option>
                      <option value="biweekly">Bi-weekly</option>
                      <option value="monthly">Monthly</option>
                    </select>
                  </div>

                  <div>
                    <label className="mb-2 block text-sm font-medium text-gray-700">
                      Days of Week
                    </label>
                    <div className="grid grid-cols-7 gap-2">
                      {dayNames.map((day, index) => {
                        const isSelected = recurringState.daysOfWeek.includes(index);
                        return (
                          <button
                            key={day}
                            type="button"
                            onClick={() =>
                              setFormData((prev) => ({
                                ...prev,
                                recurring: {
                                  ...recurringState,
                                  daysOfWeek: isSelected
                                    ? recurringState.daysOfWeek.filter((d) => d !== index)
                                    : [...recurringState.daysOfWeek, index].sort(),
                                },
                              }))
                            }
                            className={`rounded-lg border px-2 py-2 text-xs font-medium transition-colors ${
                              isSelected
                                ? 'border-indigo-600 bg-indigo-600 text-white'
                                : 'border-gray-300 bg-white text-gray-600 hover:bg-gray-100'
                            }`}
                          >
                            {day.slice(0, 3)}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div>
                    <label className="mb-2 block text-sm font-medium text-gray-700">
                      End Date (optional)
                    </label>
                    <input
                      type="date"
                      value={recurringState.endDate || ''}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          recurring: {
                            ...recurringState,
                            endDate: e.target.value,
                          },
                        }))
                      }
                      className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Materials & Prerequisites */}
            <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
              <div className="space-y-3">
                <h3 className="text-lg font-semibold text-gray-900">
                  Materials Provided
                </h3>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={newMaterial}
                    onChange={(e) => setNewMaterial(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        addMaterial();
                      }
                    }}
                    className="flex-1 rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Clay, glazes, tools"
                  />
                  <button
                    type="button"
                    onClick={addMaterial}
                    className="rounded-lg bg-green-600 p-2 text-white transition-colors hover:bg-green-700"
                  >
                    <Plus className="h-4 w-4" />
                  </button>
                </div>
                <div className="space-y-2">
                  {(formData.materials || []).map((material) => (
                    <div
                      key={material}
                      className="flex items-center justify-between rounded-lg bg-green-50 px-3 py-2 text-sm text-green-800"
                    >
                      <span>{material}</span>
                      <button
                        type="button"
                        onClick={() => removeMaterial(material)}
                        className="rounded-full p-1 text-green-600 hover:bg-green-100"
                      >
                        <Minus className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                  {(!formData.materials || formData.materials.length === 0) && (
                    <p className="text-sm text-gray-500">No materials listed yet.</p>
                  )}
                </div>
              </div>

              <div className="space-y-3">
                <h3 className="text-lg font-semibold text-gray-900">
                  Prerequisites
                </h3>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={newPrerequisite}
                    onChange={(e) => setNewPrerequisite(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        addPrerequisite();
                      }
                    }}
                    className="flex-1 rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Basic pottery experience"
                  />
                  <button
                    type="button"
                    onClick={addPrerequisite}
                    className="rounded-lg bg-purple-600 p-2 text-white transition-colors hover:bg-purple-700"
                  >
                    <Plus className="h-4 w-4" />
                  </button>
                </div>
                <div className="space-y-2">
                  {(formData.prerequisites || []).map((item) => (
                    <div
                      key={item}
                      className="flex items-center justify-between rounded-lg bg-purple-50 px-3 py-2 text-sm text-purple-800"
                    >
                      <span>{item}</span>
                      <button
                        type="button"
                        onClick={() => removePrerequisite(item)}
                        className="rounded-full p-1 text-purple-600 hover:bg-purple-100"
                      >
                        <Minus className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                  {(!formData.prerequisites || formData.prerequisites.length === 0) && (
                    <p className="text-sm text-gray-500">No prerequisites listed.</p>
                  )}
                </div>
              </div>
            </div>

            {/* Cancellation Policy */}
            <div className="space-y-3">
              <h3 className="text-lg font-semibold text-gray-900">
                Cancellation Policy
              </h3>
              <textarea
                value={formData.cancellationPolicy}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    cancellationPolicy: e.target.value,
                  }))
                }
                rows={3}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Describe your cancellation and refund policy..."
              />
            </div>
          </div>
        </div>

        <div className="sticky bottom-0 flex items-center justify-between border-t border-gray-200 bg-white px-6 py-4">
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="rounded-lg border border-gray-300 px-5 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={saveDisabled}
            className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isSubmitting ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            {classData?.id ? 'Update Class' : 'Create Class'}
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}
