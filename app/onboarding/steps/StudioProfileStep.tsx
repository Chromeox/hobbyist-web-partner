'use client';

import React, { useState } from 'react';
import { Camera, MapPin, Clock, Star, Plus, X } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import { uploadFile, compressImage } from '@/lib/storage';
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';

interface StudioProfileStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function StudioProfileStep({ onNext, onPrevious, data }: StudioProfileStepProps) {
  const { user } = useAuth();
  const [formData, setFormData] = useState({
    tagline: data.studioProfile?.tagline || '',
    description: data.studioProfile?.description || '',
    specialties: data.studioProfile?.specialties || [],
    amenities: data.studioProfile?.amenities || [],
    photos: data.studioProfile?.photos || [],
    socialMedia: data.studioProfile?.socialMedia || {
      instagram: '',
      facebook: '',
      twitter: '',
      website: ''
    }
  });

  const [newSpecialty, setNewSpecialty] = useState('');
  const [newAmenity, setNewAmenity] = useState('');
  const [errors, setErrors] = useState<any>({});
  const [uploadingPhotos, setUploadingPhotos] = useState(false);

  const handlePhotoUpload = async (files: FileList | null) => {
    if (!files || files.length === 0 || !user) return;

    setUploadingPhotos(true);

    try {
      const uploadPromises = Array.from(files).map(async (file) => {
        // Compress image first
        const compressed = await compressImage(file, 1920, 0.85);

        // Upload to Supabase
        const result = await uploadFile(compressed, user.id, {
          bucket: 'studio-photos',
          folder: 'profile',
          maxSizeMB: 5,
          allowedTypes: ['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
        });

        if (result.error) {
          console.error('Photo upload error:', result.error);
          return null;
        }

        return result.url;
      });

      const uploadedUrls = (await Promise.all(uploadPromises)).filter(Boolean) as string[];
      setFormData(prev => ({
        ...prev,
        photos: [...prev.photos, ...uploadedUrls]
      }));
    } catch (error) {
      console.error('Photo upload exception:', error);
    } finally {
      setUploadingPhotos(false);
    }
  };

  const handleRemovePhoto = (index: number) => {
    setFormData(prev => ({
      ...prev,
      photos: prev.photos.filter((_: any, i: number) => i !== index)
    }));
  };

  const validateForm = () => {
    const newErrors: any = {};
    let isValid = true;

    if (!formData.tagline.trim()) {
      newErrors.tagline = 'Tagline is required';
      isValid = false;
    }

    if (!formData.description.trim()) {
      newErrors.description = 'Description is required';
      isValid = false;
    }

    setErrors(newErrors);
    return isValid;
  };

  const commonSpecialties = [
    'Yoga', 'Pilates', 'Barre', 'HIIT', 'Strength Training', 'Cardio',
    'Dance', 'Meditation', 'Stretching', 'Functional Fitness'
  ];

  const commonAmenities = [
    'Parking', 'Changing Rooms', 'Showers', 'Lockers', 'Water Station',
    'Equipment Rental', 'Retail Shop', 'Childcare', 'WiFi', 'Air Conditioning'
  ];

  const addSpecialty = (specialty: string) => {
    if (specialty && !formData.specialties.includes(specialty)) {
      setFormData(prev => ({
        ...prev,
        specialties: [...prev.specialties, specialty]
      }));
    }
    setNewSpecialty('');
  };

  const removeSpecialty = (specialty: string) => {
    setFormData(prev => ({
      ...prev,
      specialties: prev.specialties.filter((s: string) => s !== specialty)
    }));
  };

  const addAmenity = (amenity: string) => {
    if (amenity && !formData.amenities.includes(amenity)) {
      setFormData(prev => ({
        ...prev,
        amenities: [...prev.amenities, amenity]
      }));
    }
    setNewAmenity('');
  };

  const removeAmenity = (amenity: string) => {
    setFormData(prev => ({
      ...prev,
      amenities: prev.amenities.filter((a: string) => a !== amenity)
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) {
      onNext({ studioProfile: formData });
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Studio Profile</h2>
        <p className="text-gray-600">Create your studio profile to attract students</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Information */}
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tagline
            </label>
            <input
              type="text"
              value={formData.tagline}
              onChange={(e) => setFormData(prev => ({ ...prev, tagline: e.target.value }))}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${errors.tagline ? 'border-red-500' : 'border-gray-300'
                }`}
              placeholder="e.g., Your wellness journey starts here"
              maxLength={100}
            />
            <div className="flex justify-between mt-1">
              <p className="text-sm text-gray-500">{formData.tagline.length}/100 characters</p>
              {errors.tagline && <p className="text-sm text-red-500">{errors.tagline}</p>}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              rows={4}
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${errors.description ? 'border-red-500' : 'border-gray-300'
                }`}
              placeholder="Tell students about your studio's mission, philosophy, and what makes you unique..."
              maxLength={500}
            />
            <div className="flex justify-between mt-1">
              <p className="text-sm text-gray-500">{formData.description.length}/500 characters</p>
              {errors.description && <p className="text-sm text-red-500">{errors.description}</p>}
            </div>
          </div>
        </div>

        {/* Specialties */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Class Specialties <span className="text-gray-400 font-normal">(optional)</span>
          </label>

          {/* Selected Specialties */}
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.specialties.map((specialty: string) => (
              <span
                key={specialty}
                className="inline-flex items-center px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full"
              >
                {specialty}
                <button
                  type="button"
                  onClick={() => removeSpecialty(specialty)}
                  className="ml-2 text-blue-600 hover:text-blue-800"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))}
          </div>

          {/* Add Specialty */}
          <div className="flex gap-2 mb-3">
            <input
              type="text"
              value={newSpecialty}
              onChange={(e) => setNewSpecialty(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSpecialty(newSpecialty))}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Add a specialty..."
            />
            <button
              type="button"
              onClick={() => addSpecialty(newSpecialty)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>

          {/* Common Specialties */}
          <div className="flex flex-wrap gap-2">
            {commonSpecialties
              .filter(s => !formData.specialties.includes(s))
              .map((specialty) => (
                <button
                  key={specialty}
                  type="button"
                  onClick={() => addSpecialty(specialty)}
                  className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-full hover:bg-gray-50 transition-colors"
                >
                  + {specialty}
                </button>
              ))}
          </div>
        </div>

        {/* Amenities */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Amenities <span className="text-gray-400 font-normal">(optional)</span>
          </label>

          {/* Selected Amenities */}
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.amenities.map((amenity: string) => (
              <span
                key={amenity}
                className="inline-flex items-center px-3 py-1 bg-green-100 text-green-800 text-sm rounded-full"
              >
                {amenity}
                <button
                  type="button"
                  onClick={() => removeAmenity(amenity)}
                  className="ml-2 text-green-600 hover:text-green-800"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))}
          </div>

          {/* Add Amenity */}
          <div className="flex gap-2 mb-3">
            <input
              type="text"
              value={newAmenity}
              onChange={(e) => setNewAmenity(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addAmenity(newAmenity))}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Add an amenity..."
            />
            <button
              type="button"
              onClick={() => addAmenity(newAmenity)}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>

          {/* Common Amenities */}
          <div className="flex flex-wrap gap-2">
            {commonAmenities
              .filter(a => !formData.amenities.includes(a))
              .map((amenity) => (
                <button
                  key={amenity}
                  type="button"
                  onClick={() => addAmenity(amenity)}
                  className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-full hover:bg-gray-50 transition-colors"
                >
                  + {amenity}
                </button>
              ))}
          </div>
        </div>

        {/* Photos */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Studio Photos <span className="text-gray-400 font-normal">(optional - add later from dashboard)</span>
          </label>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {/* Uploaded Photos */}
            {formData.photos.map((photoUrl: string, index: number) => (
              <div
                key={index}
                className="relative aspect-square bg-gray-100 rounded-lg overflow-hidden group"
              >
                <img
                  src={photoUrl}
                  alt={`Studio photo ${index + 1}`}
                  className="w-full h-full object-cover"
                />
                <button
                  type="button"
                  onClick={() => handleRemovePhoto(index)}
                  className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                >
                  <X className="h-4 w-4" />
                </button>
                {index === 0 && (
                  <div className="absolute bottom-2 left-2 px-2 py-1 bg-blue-600 text-white text-xs rounded-full">
                    Main Photo
                  </div>
                )}
              </div>
            ))}

            {/* Upload Button */}
            {formData.photos.length < 6 && (
              <div className="aspect-square">
                <input
                  type="file"
                  id="studio-photos-upload"
                  accept="image/jpeg,image/png,image/jpg,image/webp"
                  multiple
                  onChange={(e) => handlePhotoUpload(e.target.files)}
                  className="hidden"
                  disabled={uploadingPhotos}
                />
                <label
                  htmlFor="studio-photos-upload"
                  className={`w-full h-full bg-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed transition-colors ${uploadingPhotos
                      ? 'border-blue-400 cursor-not-allowed'
                      : 'border-gray-300 hover:border-gray-400 cursor-pointer'
                    }`}
                >
                  <div className="text-center">
                    {uploadingPhotos ? (
                      <>
                        <div className="h-8 w-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mx-auto mb-2" />
                        <p className="text-sm text-blue-600">Uploading...</p>
                      </>
                    ) : (
                      <>
                        <Camera className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                        <p className="text-sm text-gray-500">Add Photo</p>
                      </>
                    )}
                  </div>
                </label>
              </div>
            )}
          </div>
          <p className="text-sm text-gray-500 mt-2">
            Upload high-quality photos of your studio, classes, and facilities. First photo will be your main image. ({formData.photos.length}/6 photos)
          </p>
        </div>

        {/* Social Media */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Social Media & Website (Optional)
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">Website</label>
              <input
                type="url"
                value={formData.socialMedia.website}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, website: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="https://yourstudio.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">Instagram</label>
              <input
                type="text"
                value={formData.socialMedia.instagram}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, instagram: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="@yourstudio"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">Facebook</label>
              <input
                type="text"
                value={formData.socialMedia.facebook}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, facebook: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="facebook.com/yourstudio"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">Twitter</label>
              <input
                type="text"
                value={formData.socialMedia.twitter}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, twitter: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="@yourstudio"
              />
            </div>
          </div>
        </div>

        {/* Privacy Policy Notice */}
        <div className="mt-8 pt-6 border-t border-gray-200">
          <PrivacyPolicyBanner
            variant="inline"
            context="onboarding"
          />
        </div>

        {/* Navigation Buttons */}
        <div className="mt-8 flex justify-between">
          <button
            type="button"
            onClick={onPrevious}
            className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-all"
          >
            Back
          </button>
          <button
            type="submit"
            className="px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
          >
            Continue
          </button>
        </div>
      </form>
    </div>
  );
}